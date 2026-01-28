# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Indiana
# assessment data.
#
# Assessment systems:
# - ILEARN (2019, 2021-2025): Indiana Learning Evaluation and Assessment Readiness Network
#   - Grades 3-8 ELA, Math, Science, Social Studies
#   - Proficiency levels: Below, Approaching, At, Above
# - ISTEP+ (2014-2018): Indiana Statewide Testing for Educational Progress-Plus
#   - Grades 3-8 and Grade 10
#   - Similar proficiency levels
# - 2020: No data (COVID-19 testing waiver)
#
# ==============================================================================


#' Fetch Indiana assessment data
#'
#' Downloads and returns assessment data from the Indiana Department of
#' Education. Includes ILEARN (2019, 2021-2025) and ISTEP+ (2014-2018) data.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year).
#'   Valid years: 2014-2019, 2021-2025 (no 2020 due to COVID testing waiver).
#' @param level Level of data to fetch: "all" (default), "state", "corporation", or "school"
#' @param tidy If TRUE (default), returns data in tidy (long) format. If FALSE,
#'   returns wide format with separate columns for each grade/proficiency level.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Data frame with assessment data. Includes proficiency counts and
#'   percentages by grade and subject.
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 ILEARN data (2023-24 school year)
#' assess_2024 <- fetch_assessment(2024)
#'
#' # Get corporation-level data only
#' corp_assess <- fetch_assessment(2024, level = "corporation")
#'
#' # Get wide format (easier for some analyses)
#' assess_wide <- fetch_assessment(2024, tidy = FALSE)
#'
#' # Get historical ISTEP+ data
#' istep_2018 <- fetch_assessment(2018)
#'
#' # Filter to math results
#' math_results <- assess_2024 |>
#'   dplyr::filter(subject == "Math", is_corporation)
#' }
fetch_assessment <- function(end_year, level = "all", tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available <- get_available_assessment_years()

  if (end_year == 2020) {
    stop(available$note)
  }

  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "),
      "\nGot: ", end_year,
      "\nNote: 2020 has no data due to COVID-19 testing waiver."
    ))
  }

  # Validate level
  level <- tolower(level)
  if (!level %in% c("all", "state", "corporation", "school")) {
    stop("level must be one of 'all', 'state', 'corporation', 'school'")
  }

  # Determine cache type
  cache_type <- if (tidy) "assessment_tidy" else "assessment_wide"
  cache_key <- paste0(cache_type, "_", level)

  # Check cache first
  if (use_cache && assessment_cache_exists(end_year, cache_key)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_assessment_cache(end_year, cache_key))
  }

  # Get raw data from IDOE
  raw <- get_raw_assessment(end_year, level)

  # Check if we got data
  if (length(raw) == 0 || all(sapply(raw, nrow) == 0)) {
    warning(paste("No assessment data available for year", end_year))
    return(if (tidy) create_empty_tidy_assessment() else create_empty_assessment_processed())
  }

  # Process to standard schema
  processed <- process_assessment(raw, end_year)

  if (nrow(processed) == 0) {
    warning(paste("No assessment data after processing for year", end_year))
    return(if (tidy) create_empty_tidy_assessment() else create_empty_assessment_processed())
  }

  # Optionally tidy
  if (tidy) {
    processed <- tidy_assessment(processed)
    processed <- id_assessment_aggs(processed)
  } else {
    processed <- id_assessment_aggs(processed)
  }

  # Cache the result
  if (use_cache) {
    write_assessment_cache(processed, end_year, cache_key)
  }

  processed
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024)).
#'   Note: 2020 is automatically excluded due to COVID-19 testing waiver.
#' @param level Level of data: "all" (default), "state", "corporation", or "school"
#' @param tidy If TRUE (default), returns tidy format.
#' @param use_cache If TRUE (default), uses cached data.
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get recent ILEARN years
#' assess_multi <- fetch_assessment_multi(2021:2024)
#'
#' # Track proficiency trends
#' assess_multi |>
#'   dplyr::filter(is_state, subject == "Math", grade == "All") |>
#'   dplyr::filter(proficiency_level == "proficient") |>
#'   dplyr::select(end_year, value)
#' }
fetch_assessment_multi <- function(end_years, level = "all", tidy = TRUE, use_cache = TRUE) {

  # Validate years
  available <- get_available_assessment_years()

  # Check for 2020
  if (2020 %in% end_years) {
    warning("2020 excluded: ", available$note)
    end_years <- end_years[end_years != 2020]
  }

  invalid_years <- end_years[!end_years %in% available$years]
  if (length(invalid_years) > 0) {
    stop(paste0(
      "Invalid years: ", paste(invalid_years, collapse = ", "),
      "\nend_year must be one of: ", paste(available$years, collapse = ", ")
    ))
  }

  if (length(end_years) == 0) {
    stop("No valid years to fetch")
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      tryCatch({
        fetch_assessment(yr, level = level, tidy = tidy, use_cache = use_cache)
      }, error = function(e) {
        warning(paste("Failed to fetch year", yr, ":", e$message))
        if (tidy) create_empty_tidy_assessment() else create_empty_assessment_processed()
      })
    }
  )

  # Filter out empty results
  results <- results[sapply(results, nrow) > 0]

  if (length(results) == 0) {
    warning("No data returned for any year")
    return(if (tidy) create_empty_tidy_assessment() else create_empty_assessment_processed())
  }

  # Combine
  dplyr::bind_rows(results)
}


#' Get assessment data for a specific corporation
#'
#' Convenience function to fetch assessment data for a single corporation (district).
#'
#' @param end_year School year end
#' @param corporation_id 4-digit corporation ID (e.g., "5385" for Indianapolis Public Schools)
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified corporation
#' @export
#' @examples
#' \dontrun{
#' # Get Indianapolis Public Schools (5385) assessment data
#' ips_assess <- fetch_corporation_assessment(2024, "5385")
#'
#' # Get Fort Wayne Community Schools (0235) data
#' fw_assess <- fetch_corporation_assessment(2024, "0235")
#' }
fetch_corporation_assessment <- function(end_year, corporation_id, tidy = TRUE, use_cache = TRUE) {

  # Normalize corporation_id
  corporation_id <- sprintf("%04d", as.integer(corporation_id))

  # Fetch corporation-level data
  df <- fetch_assessment(end_year, level = "corporation", tidy = tidy, use_cache = use_cache)

  # Filter to requested corporation
  df |>
    dplyr::filter(.data$corporation_id == !!corporation_id)
}


#' Get assessment data for a specific school
#'
#' Convenience function to fetch assessment data for a single school.
#'
#' @param end_year School year end
#' @param corporation_id 4-digit corporation ID
#' @param school_id 4-digit school ID
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified school
#' @export
#' @examples
#' \dontrun{
#' # Get a specific school's assessment data
#' school_assess <- fetch_school_assessment(2024, "5385", "0010")
#' }
fetch_school_assessment <- function(end_year, corporation_id, school_id, tidy = TRUE, use_cache = TRUE) {

  # Normalize IDs
  corporation_id <- sprintf("%04d", as.integer(corporation_id))
  school_id <- sprintf("%04d", as.integer(school_id))

  # Fetch school-level data
  df <- fetch_assessment(end_year, level = "school", tidy = tidy, use_cache = use_cache)

  # Filter to requested school
  df |>
    dplyr::filter(.data$corporation_id == !!corporation_id, .data$school_id == !!school_id)
}


# ==============================================================================
# Assessment Cache Functions
# ==============================================================================


#' Get assessment cache path
#'
#' @param end_year School year end
#' @param cache_key Cache type key
#' @return Path to cache file
#' @keywords internal
get_assessment_cache_path <- function(end_year, cache_key) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_key, "_", end_year, ".rds"))
}


#' Check if assessment cache exists
#'
#' @param end_year School year end
#' @param cache_key Cache type key
#' @param max_age Maximum age in days (default 30)
#' @return TRUE if valid cache exists
#' @keywords internal
assessment_cache_exists <- function(end_year, cache_key, max_age = 30) {
  cache_path <- get_assessment_cache_path(end_year, cache_key)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read assessment data from cache
#'
#' @param end_year School year end
#' @param cache_key Cache type key
#' @return Cached data frame
#' @keywords internal
read_assessment_cache <- function(end_year, cache_key) {
  cache_path <- get_assessment_cache_path(end_year, cache_key)
  readRDS(cache_path)
}


#' Write assessment data to cache
#'
#' @param df Data frame to cache
#' @param end_year School year end
#' @param cache_key Cache type key
#' @return Invisibly returns the cache path
#' @keywords internal
write_assessment_cache <- function(df, end_year, cache_key) {
  cache_path <- get_assessment_cache_path(end_year, cache_key)
  saveRDS(df, cache_path)
  invisible(cache_path)
}
