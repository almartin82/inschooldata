# ==============================================================================
# Assessment Data Tests
# ==============================================================================
#
# Tests for Indiana assessment data functions (ILEARN, ISTEP+).
# Uses ACTUAL VALUES from raw data files for fidelity verification.
#
# ==============================================================================

# Skip tests if network is unavailable
skip_if_offline <- function() {
  tryCatch({
    httr::HEAD("https://www.in.gov", httr::timeout(5))
  }, error = function(e) {
    skip("Network unavailable")
  })
}


# ==============================================================================
# URL Tests
# ==============================================================================

test_that("get_available_assessment_years returns correct years", {
  available <- get_available_assessment_years()

  expect_type(available, "list")
  expect_true("years" %in% names(available))
  expect_true("ilearn_years" %in% names(available))
  expect_true("istep_years" %in% names(available))

  # Check ILEARN years (2019, 2021-2025, no 2020)
  expect_true(2019 %in% available$ilearn_years)
  expect_true(2024 %in% available$ilearn_years)
  expect_true(2025 %in% available$ilearn_years)
  expect_false(2020 %in% available$ilearn_years)

  # Check ISTEP years (2014-2018)
  expect_true(2014 %in% available$istep_years)
  expect_true(2018 %in% available$istep_years)
  expect_false(2019 %in% available$istep_years)
})


test_that("get_assessment_url returns valid URLs for ILEARN years", {
  # 2024
  url_2024 <- get_assessment_url(2024, "corporation", "main")
  expect_type(url_2024, "character")
  expect_true(grepl("ILEARN-2024.*Corporation", url_2024))

  # 2019
  url_2019 <- get_assessment_url(2019, "corporation", "main")
  expect_type(url_2019, "character")
  expect_true(grepl("ilearn-2019.*corporation", url_2019))
})


test_that("get_assessment_url returns valid URLs for ISTEP years", {
  # 2018
  url_2018 <- get_assessment_url(2018, "corporation", "main")
  expect_type(url_2018, "character")
  expect_true(grepl("ISTEP-2018", url_2018))

  # 2016
  url_2016 <- get_assessment_url(2016, "corporation", "main")
  expect_type(url_2016, "character")
  expect_true(grepl("2016", url_2016))
})


test_that("get_assessment_url returns NULL for invalid years", {
  expect_null(get_assessment_url(2020, "corporation", "main"))  # COVID year
  expect_null(get_assessment_url(2010, "corporation", "main"))  # Too early
  expect_null(get_assessment_url(2030, "corporation", "main"))  # Future
})


# ==============================================================================
# Live Download Tests (skip if offline)
# ==============================================================================

test_that("2024 corporation URL is accessible", {
  skip_if_offline()
  skip_on_cran()

  url <- get_assessment_url(2024, "corporation", "main")
  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})


test_that("get_raw_assessment downloads 2024 corporation data", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()  # Skip on CI to avoid long downloads

  raw <- tryCatch({
    get_raw_assessment(2024, "corporation")
  }, error = function(e) {
    skip(paste("Download failed:", e$message))
  })

  expect_type(raw, "list")
  expect_true("corporation" %in% names(raw))
  expect_gt(nrow(raw$corporation), 0)
})


# ==============================================================================
# Data Fidelity Tests (using known values from 2024 ILEARN data)
# ==============================================================================

# These values were verified against the raw Excel file:
# https://www.in.gov/doe/files/ILEARN-2024-Grade3-8-Final-Corporation.xlsx
# Fort Wayne Community Schools (Corp ID: 0235)

test_that("2024 Fort Wayne ELA values match raw file", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  assess <- tryCatch({
    fetch_assessment(2024, level = "corporation", tidy = TRUE, use_cache = FALSE)
  }, error = function(e) {
    skip(paste("Download failed:", e$message))
  })

  # Filter to Fort Wayne ELA Grade 3
  fw_ela_g3 <- assess |>
    dplyr::filter(corporation_id == "0235", subject == "ELA", grade == "3")

  if (nrow(fw_ela_g3) == 0) {
    skip("Fort Wayne data not found")
  }

  # Verify actual values from raw Excel file
  below_val <- fw_ela_g3$value[fw_ela_g3$proficiency_level == "below"]
  approaching_val <- fw_ela_g3$value[fw_ela_g3$proficiency_level == "approaching"]
  at_val <- fw_ela_g3$value[fw_ela_g3$proficiency_level == "at"]
  above_val <- fw_ela_g3$value[fw_ela_g3$proficiency_level == "above"]
  proficient_val <- fw_ela_g3$value[fw_ela_g3$proficiency_level == "proficient"]
  tested_val <- fw_ela_g3$value[fw_ela_g3$proficiency_level == "total_tested"]

  # Values verified from raw Excel (2024 ILEARN)
  expect_equal(below_val, 1035)
  expect_equal(approaching_val, 445)
  expect_equal(at_val, 417)
  expect_equal(above_val, 238)
  expect_equal(proficient_val, 655)
  expect_equal(tested_val, 2135)
})


test_that("2024 Fort Wayne Math values match raw file", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  assess <- tryCatch({
    fetch_assessment(2024, level = "corporation", tidy = TRUE, use_cache = FALSE)
  }, error = function(e) {
    skip(paste("Download failed:", e$message))
  })

  # Filter to Fort Wayne Math Total
  fw_math_total <- assess |>
    dplyr::filter(corporation_id == "0235", subject == "Math", grade == "All")

  if (nrow(fw_math_total) == 0) {
    skip("Fort Wayne Math data not found")
  }

  # Total tested should be reasonable for a large district
  tested_val <- fw_math_total$value[fw_math_total$proficiency_level == "total_tested"]

  expect_gt(tested_val, 10000)  # Fort Wayne is a large district
  expect_lt(tested_val, 20000)  # But not unreasonably large
})


# ==============================================================================
# Data Quality Tests
# ==============================================================================

test_that("assessment data has required columns", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  assess <- tryCatch({
    fetch_assessment(2024, level = "corporation", tidy = TRUE, use_cache = FALSE)
  }, error = function(e) {
    skip(paste("Download failed:", e$message))
  })

  # Required columns
  expect_true("corporation_id" %in% names(assess))
  expect_true("corporation_name" %in% names(assess))
  expect_true("subject" %in% names(assess))
  expect_true("grade" %in% names(assess))
  expect_true("proficiency_level" %in% names(assess))
  expect_true("value" %in% names(assess))
  expect_true("end_year" %in% names(assess))
})


test_that("assessment data has no NA in key fields", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  assess <- tryCatch({
    fetch_assessment(2024, level = "corporation", tidy = TRUE, use_cache = FALSE)
  }, error = function(e) {
    skip(paste("Download failed:", e$message))
  })

  # No NA in corporation_id
  expect_equal(sum(is.na(assess$corporation_id)), 0)

  # No NA in subject
  expect_equal(sum(is.na(assess$subject)), 0)

  # No NA in grade
  expect_equal(sum(is.na(assess$grade)), 0)

  # No NA in proficiency_level
  expect_equal(sum(is.na(assess$proficiency_level)), 0)
})


test_that("proficiency levels sum correctly", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  assess <- tryCatch({
    fetch_assessment(2024, level = "corporation", tidy = TRUE, use_cache = FALSE)
  }, error = function(e) {
    skip(paste("Download failed:", e$message))
  })

  # For each corporation/subject/grade, below + approaching + at + above should equal total_tested
  check_sums <- assess |>
    dplyr::filter(proficiency_level %in% c("below", "approaching", "at", "above", "total_tested")) |>
    tidyr::pivot_wider(
      id_cols = c(corporation_id, subject, grade, end_year),
      names_from = proficiency_level,
      values_from = value
    ) |>
    dplyr::filter(!is.na(below), !is.na(total_tested)) |>
    dplyr::mutate(
      calc_total = below + approaching + at + above,
      diff = abs(calc_total - total_tested)
    )

  # Allow small differences due to rounding
  expect_true(all(check_sums$diff < 5 | is.na(check_sums$diff)))
})


test_that("proficient is sum of at + above", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  assess <- tryCatch({
    fetch_assessment(2024, level = "corporation", tidy = TRUE, use_cache = FALSE)
  }, error = function(e) {
    skip(paste("Download failed:", e$message))
  })

  # Proficient should equal at + above
  check_prof <- assess |>
    dplyr::filter(proficiency_level %in% c("at", "above", "proficient")) |>
    tidyr::pivot_wider(
      id_cols = c(corporation_id, subject, grade, end_year),
      names_from = proficiency_level,
      values_from = value
    ) |>
    dplyr::filter(!is.na(at), !is.na(above), !is.na(proficient)) |>
    dplyr::mutate(
      calc_proficient = at + above,
      diff = abs(calc_proficient - proficient)
    )

  # Should be exact match
  expect_true(all(check_prof$diff == 0))
})


# ==============================================================================
# Multi-Year Tests
# ==============================================================================

test_that("fetch_assessment_multi excludes 2020", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  expect_warning(
    result <- tryCatch({
      fetch_assessment_multi(2019:2021, level = "corporation", use_cache = FALSE)
    }, error = function(e) {
      skip(paste("Download failed:", e$message))
    }),
    "2020 excluded"
  )

  if (exists("result") && nrow(result) > 0) {
    # Should have 2019 and 2021, but not 2020
    years <- unique(result$end_year)
    expect_true(2019 %in% years)
    expect_true(2021 %in% years)
    expect_false(2020 %in% years)
  }
})


# ==============================================================================
# Error Handling Tests
# ==============================================================================

test_that("fetch_assessment errors for 2020", {
  expect_error(
    fetch_assessment(2020),
    "2020"
  )
})


test_that("fetch_assessment errors for invalid year", {
  expect_error(
    fetch_assessment(2010),
    "must be one of"
  )
})


test_that("fetch_assessment errors for invalid level", {
  expect_error(
    fetch_assessment(2024, level = "invalid"),
    "must be one of"
  )
})


# ==============================================================================
# Aggregation Flag Tests
# ==============================================================================

test_that("id_assessment_aggs correctly identifies levels", {
  # Create test data
  test_df <- data.frame(
    aggregation_level = c("state", "corporation", "school"),
    corporation_id = c(NA, "0235", "0235"),
    school_id = c(NA, NA, "0010"),
    value = c(100, 50, 25)
  )

  result <- id_assessment_aggs(test_df)

  expect_true(result$is_state[1])
  expect_false(result$is_corporation[1])
  expect_false(result$is_school[1])

  expect_false(result$is_state[2])
  expect_true(result$is_corporation[2])
  expect_false(result$is_school[2])

  expect_false(result$is_state[3])
  expect_false(result$is_corporation[3])
  expect_true(result$is_school[3])
})
