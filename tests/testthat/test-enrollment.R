# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("N/A")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("get_available_years returns valid range", {
  years <- get_available_years()
  expect_true(is.integer(years))
  expect_true(2006 %in% years)
  expect_true(2024 %in% years)
  expect_equal(min(years), 2006)
})

test_that("validate_year works correctly", {
  # Valid years should not error
  expect_true(validate_year(2020))
  expect_true(validate_year(2006))
  expect_true(validate_year(2024))

  # Invalid years should error
  expect_error(validate_year(2005), "end_year must be between")
  expect_error(validate_year(2030), "end_year must be between")
  expect_error(validate_year("2020"), "must be a single numeric value")
})

test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(2000), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("inschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

test_that("standardize_corp_id formats IDs correctly", {
  expect_equal(standardize_corp_id("123"), "0123")
  expect_equal(standardize_corp_id("5385"), "5385")
  expect_equal(standardize_corp_id(5385), "5385")
  expect_true(is.na(standardize_corp_id(NULL)))
})

test_that("standardize_school_id formats IDs correctly", {
  expect_equal(standardize_school_id("1"), "0001")
  expect_equal(standardize_school_id("0001"), "0001")
  expect_equal(standardize_school_id(1234), "1234")
  expect_true(is.na(standardize_school_id(NULL)))
})

test_that("get_idoe_file_urls returns all expected URLs", {
  urls <- get_idoe_file_urls()

  expect_true(is.list(urls))
  expect_true("corp_grade" %in% names(urls))
  expect_true("corp_ethnicity" %in% names(urls))
  expect_true("corp_sped_ell" %in% names(urls))
  expect_true("corp_gender" %in% names(urls))
  expect_true("school_grade" %in% names(urls))
  expect_true("school_ethnicity" %in% names(urls))
  expect_true("school_sped_ell" %in% names(urls))
  expect_true("school_gender" %in% names(urls))

  # Check URLs are properly formed
  expect_true(all(grepl("^https://www.in.gov/doe/files/", unlist(urls))))
  expect_true(all(grepl("\\.xlsx$", unlist(urls))))
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes data", {
  skip_on_cran()
  skip_if_offline()

  # Use a recent year
  result <- fetch_enr(2023, tidy = FALSE, use_cache = FALSE)

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("corporation_id" %in% names(result))
  expect_true("school_id" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("type" %in% names(result))

  # Check we have all levels
  expect_true("State" %in% result$type)
  expect_true("Corporation" %in% result$type)
  expect_true("School" %in% result$type)

  # Check ID formats (4 digits)
  corps <- result[result$type == "Corporation" & !is.na(result$corporation_id), ]
  expect_true(all(nchar(corps$corporation_id) == 4))
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Get wide data
  wide <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)

  # Tidy it
  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
})

test_that("id_enr_aggs adds correct flags", {
  skip_on_cran()
  skip_if_offline()

  # Get tidy data with aggregation flags
  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_corporation" %in% names(result))
  expect_true("is_school" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_corporation))
  expect_true(is.logical(result$is_school))

  # Check mutual exclusivity (each row is only one type)
  type_sums <- result$is_state + result$is_corporation + result$is_school
  expect_true(all(type_sums == 1))
})

test_that("fetch_enr_multi combines multiple years", {
  skip_on_cran()
  skip_if_offline()

  # Get 2 years of data
  result <- fetch_enr_multi(c(2022, 2023), tidy = TRUE, use_cache = TRUE)

  # Check both years present
  expect_true(2022 %in% result$end_year)
  expect_true(2023 %in% result$end_year)
})

test_that("earliest available year (2006) works", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2006, tidy = FALSE, use_cache = TRUE)

  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0)
  expect_equal(unique(result$end_year), 2006)
})

test_that("most recent year (2024) works", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0)
  expect_equal(unique(result$end_year), 2024)
})
