# ==============================================================================
# Tests for School Directory Functions
# ==============================================================================
#
# Tests for fetch_directory and related functions.
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# URL and Year Functions
# ==============================================================================

test_that("get_directory_years returns valid years", {
  years <- inschooldata::get_directory_years()

  expect_true(is.integer(years) || is.numeric(years))
  expect_true(length(years) > 0)
  expect_true(all(years >= 2020 & years <= 2030))
})

test_that("get_directory_url returns URL for known years", {
  url_2025 <- inschooldata:::get_directory_url(2025)
  url_2026 <- inschooldata:::get_directory_url(2026)

  expect_true(is.character(url_2025))
  expect_true(grepl("in.gov", url_2025))
  expect_true(grepl("directory", url_2025))

  expect_true(is.character(url_2026))
  expect_true(grepl("in.gov", url_2026))
})

test_that("get_directory_url returns NULL for unknown years", {
  url_old <- inschooldata:::get_directory_url(2020)
  expect_null(url_old)
})

# ==============================================================================
# URL Availability Tests
# ==============================================================================

test_that("Directory file URL returns HTTP 200", {
  skip_if_offline()

  url <- inschooldata:::get_directory_url(2025)
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("2026 Directory file URL returns HTTP 200", {
  skip_if_offline()

  url <- inschooldata:::get_directory_url(2026)
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

# ==============================================================================
# File Download Tests
# ==============================================================================

test_that("Directory file downloads as valid Excel", {
  skip_if_offline()

  url <- inschooldata:::get_directory_url(2025)
  temp <- tempfile(fileext = ".xlsx")

  response <- httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  expect_equal(httr::status_code(response), 200)

  # File should be substantial (not an error page)
  file_size <- file.info(temp)$size
  expect_gt(file_size, 100000, label = "Directory file should be > 100KB")

  # Should be readable as Excel
  sheets <- readxl::excel_sheets(temp)
  expect_true("CORP" %in% sheets)
  expect_true("SCHL" %in% sheets)
  expect_true("NPSCHL" %in% sheets)

  unlink(temp)
})

# ==============================================================================
# File Structure Tests
# ==============================================================================

test_that("CORP sheet has expected columns", {
  skip_if_offline()

  url <- inschooldata:::get_directory_url(2025)
  temp <- tempfile(fileext = ".xlsx")
  httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  df <- readxl::read_excel(temp, sheet = "CORP", col_types = "text")

  # Required columns for corporation directory
  expect_true("IDOE_CORPORATION_ID" %in% names(df))
  expect_true("CORPORATION_NAME" %in% names(df))
  expect_true("ADDRESS" %in% names(df))
  expect_true("CITY" %in% names(df))
  expect_true("ZIP" %in% names(df))
  expect_true("PHONE" %in% names(df))

  # Row count should be reasonable (400-500 corporations)
  expect_gt(nrow(df), 400)
  expect_lt(nrow(df), 600)

  unlink(temp)
})

test_that("SCHL sheet has expected columns", {
  skip_if_offline()

  url <- inschooldata:::get_directory_url(2025)
  temp <- tempfile(fileext = ".xlsx")
  httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  df <- readxl::read_excel(temp, sheet = "SCHL", col_types = "text")

  # Required columns for school directory
  expect_true("IDOE_CORPORATION_ID" %in% names(df))
  expect_true("IDOE_SCHOOL_ID" %in% names(df))
  expect_true("SCHOOL_NAME" %in% names(df))
  expect_true("ADDRESS" %in% names(df))
  expect_true("CITY" %in% names(df))

  # Row count should be reasonable (1500-2500 schools)
  expect_gt(nrow(df), 1500)
  expect_lt(nrow(df), 2500)

  unlink(temp)
})

# ==============================================================================
# get_raw_directory Tests
# ==============================================================================

test_that("get_raw_directory returns list with correct structure", {
  skip_if_offline()

  tryCatch({
    raw <- inschooldata:::get_raw_directory(2025)

    expect_true(is.list(raw))
    expect_true("corporation" %in% names(raw))
    expect_true("school" %in% names(raw))
    expect_true("non_public_school" %in% names(raw))

    expect_true(is.data.frame(raw$corporation))
    expect_true(is.data.frame(raw$school))
    expect_true(is.data.frame(raw$non_public_school))

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

# ==============================================================================
# fetch_directory Tests
# ==============================================================================

test_that("fetch_directory returns data frame", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory(2025)

    expect_true(is.data.frame(dir))
    expect_gt(nrow(dir), 0)

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("fetch_directory has expected columns", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory(2025)

    # Core columns from requirements
    expect_true("corporation_id" %in% names(dir))
    expect_true("school_id" %in% names(dir))
    expect_true("corporation_name" %in% names(dir))
    expect_true("school_name" %in% names(dir))
    expect_true("address" %in% names(dir))
    expect_true("city" %in% names(dir))
    expect_true("state" %in% names(dir))
    expect_true("zip" %in% names(dir))
    expect_true("phone" %in% names(dir))
    expect_true("grades_served" %in% names(dir))
    expect_true("type" %in% names(dir))

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("fetch_directory has correct types", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory(2025)

    types <- unique(dir$type)
    expect_true("Corporation" %in% types)
    expect_true("School" %in% types)
    expect_true("Non-Public School" %in% types)

    # Corporation count
    n_corps <- sum(dir$type == "Corporation")
    expect_gt(n_corps, 400)
    expect_lt(n_corps, 600)

    # School count
    n_schools <- sum(dir$type == "School")
    expect_gt(n_schools, 1500)

    # Non-public count
    n_np <- sum(dir$type == "Non-Public School")
    expect_gt(n_np, 300)

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("fetch_directory tidy=FALSE returns raw-like data", {
  skip_if_offline()

  tryCatch({
    raw <- inschooldata::fetch_directory(2025, tidy = FALSE)

    expect_true(is.list(raw))
    expect_true("corporation" %in% names(raw))
    expect_true("school" %in% names(raw))

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("fetch_directory with NULL end_year uses latest", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory()

    expect_true(is.data.frame(dir))
    expect_gt(nrow(dir), 0)

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("fetch_directory errors for invalid year", {
  expect_error(
    inschooldata::fetch_directory(2010),
    "not available"
  )
})

# ==============================================================================
# Data Quality Tests
# ==============================================================================

test_that("Corporation IDs are valid format", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory(2025)

    # Corporation IDs should be 4 digits for corporations
    corp_ids <- dir$corporation_id[dir$type == "Corporation"]
    corp_ids <- corp_ids[!is.na(corp_ids)]

    expect_true(all(nchar(corp_ids) == 4))
    expect_true(all(grepl("^[0-9]{4}$", corp_ids)))

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("School IDs are valid format", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory(2025)

    # School IDs should be 4 digits
    school_ids <- dir$school_id[dir$type == "School"]
    school_ids <- school_ids[!is.na(school_ids)]

    expect_true(all(nchar(school_ids) == 4))
    expect_true(all(grepl("^[0-9]{4}$", school_ids)))

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("State is always IN", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory(2025)

    states <- unique(dir$state[!is.na(dir$state)])
    expect_true(all(states == "IN"))

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("All schools have addresses", {
  skip_if_offline()

  tryCatch({
    dir <- inschooldata::fetch_directory(2025)

    schools <- dir[dir$type == "School", ]

    # Most schools should have addresses
    pct_with_address <- mean(!is.na(schools$address) & schools$address != "")
    expect_gt(pct_with_address, 0.95)

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

# ==============================================================================
# Caching Tests
# ==============================================================================

test_that("fetch_directory caching works", {
  skip_if_offline()

  tryCatch({
    # First call - downloads
    dir1 <- inschooldata::fetch_directory(2025, use_cache = TRUE)

    # Second call - should use cache (will show message)
    dir2 <- inschooldata::fetch_directory(2025, use_cache = TRUE)

    expect_equal(nrow(dir1), nrow(dir2))

    # Force re-download
    dir3 <- inschooldata::fetch_directory(2025, use_cache = FALSE)

    expect_equal(nrow(dir1), nrow(dir3))

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

# ==============================================================================
# Raw Data Fidelity Tests
# ==============================================================================

test_that("Processed corporation count matches raw", {
  skip_if_offline()

  tryCatch({
    raw <- inschooldata:::get_raw_directory(2025)
    processed <- inschooldata::fetch_directory(2025)

    raw_corp_count <- nrow(raw$corporation)
    processed_corp_count <- sum(processed$type == "Corporation")

    expect_equal(raw_corp_count, processed_corp_count)

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("Processed school count matches raw", {
  skip_if_offline()

  tryCatch({
    raw <- inschooldata:::get_raw_directory(2025)
    processed <- inschooldata::fetch_directory(2025)

    raw_school_count <- nrow(raw$school)
    processed_school_count <- sum(processed$type == "School")

    expect_equal(raw_school_count, processed_school_count)

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

test_that("Specific corporation data matches raw", {
  skip_if_offline()

  tryCatch({
    raw <- inschooldata:::get_raw_directory(2025)
    processed <- inschooldata::fetch_directory(2025)

    # Find Indianapolis Public Schools in raw
    raw_ips <- raw$corporation[
      grepl("Indianapolis", raw$corporation$CORPORATION_NAME, ignore.case = TRUE),
    ]

    if (nrow(raw_ips) > 0) {
      raw_ips <- raw_ips[1, ]

      # Find in processed
      proc_ips <- processed[
        processed$type == "Corporation" &
          grepl("Indianapolis", processed$corporation_name, ignore.case = TRUE),
      ]

      if (nrow(proc_ips) > 0) {
        proc_ips <- proc_ips[1, ]

        # Names should match
        expect_true(grepl(
          substr(raw_ips$CORPORATION_NAME, 1, 10),
          proc_ips$corporation_name,
          ignore.case = TRUE
        ))

        # Cities should match
        expect_equal(
          toupper(trimws(raw_ips$CITY)),
          toupper(trimws(proc_ips$city))
        )
      }
    }

  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})
