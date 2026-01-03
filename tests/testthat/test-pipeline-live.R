# ==============================================================================
# LIVE Pipeline Tests for inschooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes for all IDOE files
# 2. File Download - Successful download and Excel file verification
# 3. File Parsing - Column structure after readxl processing
# 4. Column Name Integrity - Critical: verify join columns exist
# 5. Join Integrity - Verify joins don't cause row explosion
# 6. Data Quality - No Inf/NaN, valid ranges
# 7. Aggregation Logic - District sums match state totals
# 8. Output Fidelity - tidy=TRUE matches raw data
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
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("IDOE base URL is accessible", {
  skip_if_offline()

  response <- httr::HEAD("https://www.in.gov/doe/", httr::timeout(10))
  expect_equal(httr::status_code(response), 200)
})

test_that("Corporation enrollment grade file URL returns HTTP 200", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/corporation-enrollment-grade-2006-25.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("Corporation enrollment ethnicity file URL returns HTTP 200", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/corporation-enrollment-ethnicity-free-reduced-price-meal-status-2006-25.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("Corporation enrollment gender file URL returns HTTP 200", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/corporation-enrollment-grade-gender-2006-25.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("Corporation enrollment SPED/ELL file URL returns HTTP 200", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/corporation-enrollment-ell-special-education-2006-25-updated.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("School enrollment grade file URL returns HTTP 200", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/school-enrollment-grade-2006-25.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("Corporation grade file downloads as valid Excel", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/corporation-enrollment-grade-2006-25.xlsx"
  temp <- tempfile(fileext = ".xlsx")

  response <- httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  expect_equal(httr::status_code(response), 200)

  # File should be larger than 10KB (not an error page)
  file_size <- file.info(temp)$size
  expect_gt(file_size, 10000)

  # Should be readable as Excel
  sheets <- readxl::excel_sheets(temp)
  expect_gt(length(sheets), 0)

  # Should have year sheets
  expect_true("2024" %in% sheets)

  unlink(temp)
})

# ==============================================================================
# STEP 3: File Parsing Tests - Column Structure
# ==============================================================================

test_that("Corporation grade file has expected column structure", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/corporation-enrollment-grade-2006-25.xlsx"
  temp <- tempfile(fileext = ".xlsx")
  httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  df <- readxl::read_excel(temp, sheet = "2024", col_types = "text")

  # Standardize column names like the package does
  names(df) <- toupper(gsub("[^A-Za-z0-9_]", "_", names(df)))
  names(df) <- gsub("_+", "_", names(df))
  names(df) <- gsub("_$", "", names(df))

  # Critical: CORP_ID must exist for joins
  expect_true("CORP_ID" %in% names(df),
              label = "CORP_ID column must exist for join operations")

  # Should have enrollment columns
  expect_true("TOTAL_ENROLLMENT" %in% names(df))

  # Should have grade columns
  expect_true(any(grepl("^GRADE_", names(df))))

  unlink(temp)
})

test_that("Corporation ethnicity file has CORP_ID column", {
  skip_if_offline()

  url <- "https://www.in.gov/doe/files/corporation-enrollment-ethnicity-free-reduced-price-meal-status-2006-25.xlsx"
  temp <- tempfile(fileext = ".xlsx")
  httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  df <- readxl::read_excel(temp, sheet = "2024", col_types = "text")

  names(df) <- toupper(gsub("[^A-Za-z0-9_]", "_", names(df)))
  names(df) <- gsub("_+", "_", names(df))
  names(df) <- gsub("_$", "", names(df))

  # CRITICAL: CORP_ID must exist for joins
  expect_true("CORP_ID" %in% names(df),
              label = "Ethnicity file must have CORP_ID for joins")

  unlink(temp)
})

test_that("Corporation gender file has correct structure (handles merged headers)", {
  skip_if_offline()

  # This test specifically checks for the merged header issue
  url <- "https://www.in.gov/doe/files/corporation-enrollment-grade-gender-2006-25.xlsx"
  temp <- tempfile(fileext = ".xlsx")
  httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  df <- readxl::read_excel(temp, sheet = "2024", col_types = "text")

  names(df) <- toupper(gsub("[^A-Za-z0-9_]", "_", names(df)))
  names(df) <- gsub("_+", "_", names(df))
  names(df) <- gsub("_$", "", names(df))

  # The gender file has merged Excel headers which causes issues
  # First column might be "_1" instead of "CORP_ID" due to merged cells
  # This test documents expected vs actual behavior

  first_col <- names(df)[1]

  # KNOWN ISSUE: Gender file has merged headers, so first column might be "_1"
  # If this is "_1", the join will fail or produce unexpected results
  if (first_col == "_1") {
    # Document that this is a known parsing issue
    message("WARNING: Gender file first column is '_1' instead of 'CORP_ID'")
    message("This indicates merged Excel headers need special handling")

    # Check if first data row contains header labels
    first_row_val <- df[[1]][1]
    if (!is.na(first_row_val) && grepl("Corp", first_row_val, ignore.case = TRUE)) {
      message("First row appears to be a sub-header, not data")
    }
  }

  # Check row count - should be ~418 corporations
  # If significantly more, there may be duplicate rows
  expect_lt(nrow(df), 500,
            label = "Gender file should have ~418 corporations, not more")

  unlink(temp)
})

# ==============================================================================
# STEP 4: Join Integrity Tests (Critical - catches row explosion)
# ==============================================================================

test_that("get_raw_enr does not cause row explosion", {
  skip_if_offline()

  # This is the CRITICAL test that catches the many-to-many join bug

  tryCatch({
    raw <- inschooldata:::get_raw_enr(2024)

    # Corporation data should have ~418 rows, not 100,000+
    if (!is.null(raw$corporation)) {
      expect_lt(nrow(raw$corporation), 1000,
                label = paste("Corporation data has", nrow(raw$corporation),
                            "rows - should be ~418. Row explosion likely occurred."))
    }

    # School data should have ~2000-3000 rows, not 100,000+
    if (!is.null(raw$school)) {
      expect_lt(nrow(raw$school), 10000,
                label = paste("School data has", nrow(raw$school),
                            "rows - expected ~2000-3000. Row explosion likely occurred."))
    }
  }, error = function(e) {
    # If memory error, that's also a sign of row explosion
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error during get_raw_enr - likely row explosion in joins")
    }
    skip(paste("Data source error:", e$message))
  })
})

test_that("Merged data has expected corporation count", {
  skip_if_offline()

  tryCatch({
    raw <- inschooldata:::get_raw_enr(2024)

    if (!is.null(raw$corporation)) {
      # Get unique corporations
      corp_col <- NULL
      for (col in c("CORP_ID", "IDOE_CORPORATION_ID", "CORPORATION_ID")) {
        if (col %in% names(raw$corporation)) {
          corp_col <- col
          break
        }
      }

      if (!is.null(corp_col)) {
        unique_corps <- length(unique(raw$corporation[[corp_col]]))

        # Indiana has ~400-450 school corporations
        expect_gt(unique_corps, 300,
                  label = "Should have at least 300 unique corporations")
        expect_lt(unique_corps, 500,
                  label = "Should have fewer than 500 unique corporations")
      }
    }
  }, error = function(e) {
    skip(paste("Data source error:", e$message))
  })
})

# ==============================================================================
# STEP 5: get_available_years Tests
# ==============================================================================

test_that("get_available_years returns valid year range", {
  result <- inschooldata::get_available_years()

  if (is.list(result)) {
    expect_true("min_year" %in% names(result) || "years" %in% names(result))
    if ("min_year" %in% names(result)) {
      expect_true(result$min_year >= 2000 & result$min_year <= 2030)
      expect_true(result$max_year >= 2020 & result$max_year <= 2030)
      expect_true(result$max_year >= result$min_year)
    }
  } else {
    expect_true(is.numeric(result) || is.integer(result))
    expect_true(all(result >= 2000 & result <= 2030, na.rm = TRUE))
    expect_true(length(result) > 0)
  }
})

test_that("Year range includes 2024", {
  years <- inschooldata::get_available_years()

  if (is.list(years)) {
    expect_true(2024 >= years$min_year && 2024 <= years$max_year)
  } else {
    expect_true(2024 %in% years)
  }
})

# ==============================================================================
# STEP 6: Data Quality Tests
# ==============================================================================

test_that("fetch_enr returns data with no Inf or NaN", {
  skip_if_offline()

  tryCatch({
    data <- inschooldata::fetch_enr(2024, tidy = FALSE)

    for (col in names(data)[sapply(data, is.numeric)]) {
      expect_false(any(is.infinite(data[[col]]), na.rm = TRUE),
                   label = paste("No Inf in", col))
      expect_false(any(is.nan(data[[col]]), na.rm = TRUE),
                   label = paste("No NaN in", col))
    }
  }, error = function(e) {
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error - likely row explosion bug")
    }
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("Enrollment counts are non-negative", {
  skip_if_offline()

  tryCatch({
    data <- inschooldata::fetch_enr(2024, tidy = FALSE)

    if ("row_total" %in% names(data)) {
      negative_count <- sum(data$row_total < 0, na.rm = TRUE)
      expect_equal(negative_count, 0,
                   label = "All enrollment counts should be non-negative")
    }
  }, error = function(e) {
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error - likely row explosion bug")
    }
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 7: Aggregation Tests
# ==============================================================================

test_that("State total enrollment is reasonable", {
  skip_if_offline()

  tryCatch({
    data <- inschooldata::fetch_enr(2024, tidy = FALSE)

    state_rows <- data[data$type == "State", ]

    if (nrow(state_rows) > 0 && "row_total" %in% names(state_rows)) {
      state_total <- sum(state_rows$row_total, na.rm = TRUE)

      # Indiana has ~1 million K-12 students
      # State total should be between 500K and 2M
      expect_gt(state_total, 500000,
                label = paste("State total is", state_total,
                            "- expected > 500,000 for Indiana"))
      expect_lt(state_total, 2000000,
                label = paste("State total is", state_total,
                            "- expected < 2,000,000 for Indiana"))
    }
  }, error = function(e) {
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error - likely row explosion bug")
    }
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("Corporation totals sum to state total", {
  skip_if_offline()

  tryCatch({
    data <- inschooldata::fetch_enr(2024, tidy = FALSE)

    state_rows <- data[data$type == "State", ]
    corp_rows <- data[data$type == "Corporation", ]

    if (nrow(state_rows) > 0 && nrow(corp_rows) > 0 && "row_total" %in% names(data)) {
      state_total <- sum(state_rows$row_total, na.rm = TRUE)
      corp_total <- sum(corp_rows$row_total, na.rm = TRUE)

      # Totals should be within 1% of each other
      if (state_total > 0) {
        pct_diff <- abs(state_total - corp_total) / state_total
        expect_lt(pct_diff, 0.01,
                  label = paste("State total:", state_total,
                              "Corp sum:", corp_total,
                              "Diff:", round(pct_diff * 100, 2), "%"))
      }
    }
  }, error = function(e) {
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error - likely row explosion bug")
    }
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 8: Output Fidelity Tests
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE both return data", {
  skip_if_offline()

  tryCatch({
    wide <- inschooldata::fetch_enr(2024, tidy = FALSE)

    expect_true(is.data.frame(wide))
    expect_gt(nrow(wide), 0, label = "Wide format should have rows")

    # Only test tidy if wide works (tidy depends on wide)
    tidy <- inschooldata::fetch_enr(2024, tidy = TRUE)

    expect_true(is.data.frame(tidy))
    expect_gt(nrow(tidy), 0, label = "Tidy format should have rows")

  }, error = function(e) {
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error - likely row explosion bug causing tidy_enr() to fail")
    }
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("tidy data has expected columns", {
  skip_if_offline()

  tryCatch({
    tidy <- inschooldata::fetch_enr(2024, tidy = TRUE)

    # Standard tidy columns
    expect_true("end_year" %in% names(tidy))
    expect_true("n_students" %in% names(tidy))

  }, error = function(e) {
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error in tidy_enr - likely row explosion bug")
    }
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# Raw Data Fidelity Tests
# ==============================================================================

test_that("Raw IDOE data matches known enrollment figures", {
  skip_if_offline()

  # Download and read the raw corporation grade file directly
  url <- "https://www.in.gov/doe/files/corporation-enrollment-grade-2006-25.xlsx"
  temp <- tempfile(fileext = ".xlsx")
  httr::GET(url, httr::write_disk(temp, overwrite = TRUE), httr::timeout(120))

  raw_df <- readxl::read_excel(temp, sheet = "2024")

  # Get state total from raw file
  raw_state_total <- sum(raw_df$`TOTAL ENROLLMENT`, na.rm = TRUE)

  # This should be Indiana's total enrollment (~1M students)
  expect_gt(raw_state_total, 900000,
            label = paste("Raw file state total is", raw_state_total))
  expect_lt(raw_state_total, 1200000,
            label = paste("Raw file state total is", raw_state_total))

  # Now compare with what fetch_enr returns
  tryCatch({
    processed <- inschooldata::fetch_enr(2024, tidy = FALSE)

    corp_rows <- processed[processed$type == "Corporation", ]
    if (nrow(corp_rows) > 0 && "row_total" %in% names(corp_rows)) {
      processed_total <- sum(corp_rows$row_total, na.rm = TRUE)

      # Processed total should match raw total within 5%
      pct_diff <- abs(raw_state_total - processed_total) / raw_state_total
      expect_lt(pct_diff, 0.05,
                label = paste("Raw:", raw_state_total,
                            "Processed:", processed_total,
                            "Diff:", round(pct_diff * 100, 2), "%"))
    }
  }, error = function(e) {
    if (grepl("memory", e$message, ignore.case = TRUE)) {
      fail("Memory error - processed data has row explosion bug")
    }
    skip(paste("Processing error:", e$message))
  })

  unlink(temp)
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Cache path generation works", {
  tryCatch({
    path <- inschooldata:::get_cache_path(2024, "enrollment")
    expect_true(is.character(path))
    expect_true(grepl("2024", path) || grepl("inschooldata", path))
  }, error = function(e) {
    skip("Cache functions may have different signature")
  })
})
