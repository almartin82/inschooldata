# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Indiana Department of Education (IDOE) website.
#
# Data Source: https://www.in.gov/doe/it/data-center-and-reports/
#
# The directory file contains three sheets:
# - CORP: Corporation (district) information
# - SCHL: Public school information
# - NPSCHL: Non-public school information
#
# ==============================================================================

#' Get URL for Indiana school directory
#'
#' Returns the URL for the school directory file for a given school year.
#' Note: Indiana DOE only maintains recent directory files with dated names.
#'
#' @param end_year School year end (e.g., 2025 for 2024-25 school year)
#' @return URL string
#' @keywords internal
get_directory_url <- function(end_year) {

  # Known URLs for recent years (IDOE uses dated filenames)
  # These are the most current known URLs
  known_urls <- list(
    "2026" = "https://www.in.gov/doe/files/2025-2026-school-directory-2025-10-27.xlsx",
    "2025" = "https://www.in.gov/doe/files/2024-2025-school-directory-2025-03-10.xlsx"
  )

  year_str <- as.character(end_year)

  if (year_str %in% names(known_urls)) {
    return(known_urls[[year_str]])
  }

  # For unknown years, return NULL and let the caller handle it
  NULL
}


#' Get available years for directory data
#'
#' Returns years for which school directory data is available.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' get_directory_years()
get_directory_years <- function() {
  # Currently only recent years are available
  c(2025L, 2026L)
}


#' Fetch Indiana school directory data
#'
#' Downloads and processes school directory data from the Indiana Department of
#' Education. Returns a combined dataset with corporation, public school, and
#' non-public school directory information.
#'
#' @param end_year School year end. If NULL (default), uses most recent year.
#'   Valid values are returned by \code{\link{get_directory_years}}.
#' @param tidy If TRUE (default), returns data in standardized format with
#'   consistent column names. If FALSE, returns data closer to raw format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from IDOE.
#' @return Data frame with directory information including:
#'   \itemize{
#'     \item corporation_id: IDOE corporation ID (4 digits)
#'     \item school_id: IDOE school ID (4 digits, NA for corporations)
#'     \item corporation_name: Name of the corporation/district
#'     \item school_name: Name of the school (NA for corporations)
#'     \item address: Street address
#'     \item city: City name
#'     \item state: State abbreviation (always "IN")
#'     \item zip: ZIP code
#'     \item phone: Phone number
#'     \item grades_served: Grade range (e.g., "K-12", "9-12")
#'     \item type: "Corporation", "School", or "Non-Public School"
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get current school directory
#' dir <- fetch_directory()
#'
#' # Get specific year
#' dir_2025 <- fetch_directory(2025)
#'
#' # Get raw format
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Find a specific school
#' dir |>
#'   dplyr::filter(grepl("Arsenal", school_name, ignore.case = TRUE))
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {


  # Default to most recent year
  if (is.null(end_year)) {
    end_year <- max(get_directory_years())
  }

  # Validate year
  available_years <- get_directory_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "Directory data not available for year ", end_year, ".\n",
      "Available years: ", paste(available_years, collapse = ", ")
    ))
  }

  # Determine cache type
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached directory data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from IDOE
  raw <- get_raw_directory(end_year)

  # Process to standard schema
  if (tidy) {
    processed <- process_directory(raw)
  } else {
    processed <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Download raw school directory data from IDOE
#'
#' Downloads the school directory Excel file from IDOE and reads all sheets.
#'
#' @param end_year School year end
#' @return List with corporation, school, and non-public school data frames
#' @keywords internal
get_raw_directory <- function(end_year) {

  url <- get_directory_url(end_year)

  if (is.null(url)) {
    stop(paste("No directory URL available for year", end_year))
  }

  message(paste("Downloading IDOE school directory for", end_year, "..."))

  # Check raw file cache
  raw_cache_path <- get_raw_cache_path(paste0("directory_", end_year))

  if (!file.exists(raw_cache_path) || is_raw_cache_stale(raw_cache_path)) {
    message("  Downloading directory file...")

    temp_file <- tempfile(fileext = ".xlsx")

    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(temp_file, overwrite = TRUE),
        httr::timeout(120)
      )

      if (httr::http_error(response)) {
        stop(paste("Failed to download directory - HTTP error:", httr::status_code(response)))
      }

      # Check file size
      file_info <- file.info(temp_file)
      if (file_info$size < 10000) {
        stop("Downloaded file appears too small - may be an error page")
      }

      # Copy to cache
      raw_cache_dir <- dirname(raw_cache_path)
      if (!dir.exists(raw_cache_dir)) {
        dir.create(raw_cache_dir, recursive = TRUE)
      }
      file.copy(temp_file, raw_cache_path, overwrite = TRUE)
      unlink(temp_file)

    }, error = function(e) {
      stop(paste("Failed to download directory:", e$message))
    })
  } else {
    message("  Using cached raw file...")
  }

  # Read all sheets
  tryCatch({
    message("  Reading CORP sheet...")
    corp_df <- readxl::read_excel(raw_cache_path, sheet = "CORP", col_types = "text")

    message("  Reading SCHL sheet...")
    school_df <- readxl::read_excel(raw_cache_path, sheet = "SCHL", col_types = "text")

    message("  Reading NPSCHL sheet...")
    np_school_df <- readxl::read_excel(raw_cache_path, sheet = "NPSCHL", col_types = "text")

    list(
      corporation = corp_df,
      school = school_df,
      non_public_school = np_school_df
    )

  }, error = function(e) {
    stop(paste("Failed to read directory Excel file:", e$message))
  })
}


#' Process raw directory data into standard format
#'
#' Transforms raw IDOE directory data into a standardized schema with
#' consistent column names.
#'
#' @param raw_data List containing corporation, school, and non_public_school data frames
#' @return Processed data frame with standardized columns
#' @keywords internal
process_directory <- function(raw_data) {

  # Process corporation data
  corp_processed <- process_corp_directory(raw_data$corporation)

  # Process public school data
  school_processed <- process_school_directory(raw_data$school)

  # Process non-public school data
  np_school_processed <- process_np_school_directory(raw_data$non_public_school)

  # Combine all
  dplyr::bind_rows(corp_processed, school_processed, np_school_processed)
}


#' Process corporation directory data
#'
#' @param df Raw corporation data frame
#' @return Processed corporation data frame
#' @keywords internal
process_corp_directory <- function(df) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  result <- data.frame(
    type = "Corporation",
    corporation_id = standardize_corp_id(df$IDOE_CORPORATION_ID),
    school_id = NA_character_,
    corporation_name = clean_corp_name(df$CORPORATION_NAME),
    school_name = NA_character_,
    address = trimws(df$ADDRESS),
    city = trimws(df$CITY),
    state = trimws(df$STATE),
    zip = trimws(df$ZIP),
    county = trimws(df$COUNTY_NAME),
    phone = clean_phone(df$PHONE),
    fax = clean_phone(df$FAX),
    grades_served = paste0(df$LOW_GRADE, "-", df$HIGH_GRADE),
    website = trimws(df$CORPORATION_HOMEPAGE),
    corporation_type = trimws(df$CORPORATION_TYPE),
    superintendent_name = paste(
      trimws(df$SUPERINTENDENT_FIRST_NAME),
      trimws(df$SUPERINTENDENT_LAST_NAME)
    ),
    superintendent_email = trimws(df$SUPERINTENDENT_EMAIL),
    nces_id = trimws(df$NCES_ID),
    stringsAsFactors = FALSE
  )

  # Clean up NA-NA grades_served
  result$grades_served <- ifelse(
    result$grades_served == "NA-NA",
    NA_character_,
    result$grades_served
  )

  result
}


#' Process public school directory data
#'
#' @param df Raw school data frame
#' @return Processed school data frame
#' @keywords internal
process_school_directory <- function(df) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  result <- data.frame(
    type = "School",
    corporation_id = standardize_corp_id(df$IDOE_CORPORATION_ID),
    school_id = standardize_school_id(df$IDOE_SCHOOL_ID),
    corporation_name = clean_corp_name(df$CORPORATION_NAME),
    school_name = clean_school_name(df$SCHOOL_NAME),
    address = trimws(df$ADDRESS),
    city = trimws(df$CITY),
    state = trimws(df$STATE),
    zip = trimws(df$ZIP),
    county = trimws(df$COUNTY_NAME),
    phone = clean_phone(df$PHONE),
    fax = clean_phone(df$FAX),
    grades_served = paste0(df$LOW_GRADE, "-", df$HIGH_GRADE),
    website = trimws(df$SCHOOL_HOMEPAGE),
    corporation_type = NA_character_,
    principal_name = paste(
      trimws(df$PRINCIPAL_FIRST_NAME),
      trimws(df$PRINCIPAL_LAST_NAME)
    ),
    principal_email = trimws(df$PRINCIPAL_EMAIL),
    locale = trimws(df$LOCALE),
    nces_id = trimws(df$NCES_ID),
    stringsAsFactors = FALSE
  )

  # Clean up NA-NA grades_served
  result$grades_served <- ifelse(
    result$grades_served == "NA-NA",
    NA_character_,
    result$grades_served
  )

  result
}


#' Process non-public school directory data
#'
#' @param df Raw non-public school data frame
#' @return Processed non-public school data frame
#' @keywords internal
process_np_school_directory <- function(df) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  result <- data.frame(
    type = "Non-Public School",
    corporation_id = NA_character_,
    school_id = standardize_school_id(df$IDOE_SCHOOL_ID),
    corporation_name = NA_character_,
    school_name = clean_school_name(df$SCHOOL_NAME),
    address = trimws(df$ADDRESS),
    city = trimws(df$CITY),
    state = trimws(df$STATE),
    zip = trimws(df$ZIP),
    county = trimws(df$COUNTY_NAME),
    phone = clean_phone(df$PHONE),
    fax = clean_phone(df$FAX),
    grades_served = paste0(df$LOW_GRADE, "-", df$HIGH_GRADE),
    website = trimws(df$SCHOOL_HOMEPAGE),
    corporation_type = NA_character_,
    principal_name = paste(
      trimws(df$PRINCIPAL_FIRST_NAME),
      trimws(df$PRINCIPAL_LAST_NAME)
    ),
    principal_email = trimws(df$PRINCIPAL_EMAIL),
    choice_flag = trimws(df$CHOICE_FLAG),
    nces_id = NA_character_,
    stringsAsFactors = FALSE
  )

  # Clean up NA-NA grades_served
  result$grades_served <- ifelse(
    result$grades_served == "NA-NA",
    NA_character_,
    result$grades_served
  )

  result
}


#' Clean phone number
#'
#' Standardizes phone numbers by removing non-digit characters except
#' parentheses and hyphens.
#'
#' @param x Character vector of phone numbers
#' @return Cleaned character vector
#' @keywords internal
clean_phone <- function(x) {
  if (is.null(x)) return(NA_character_)
  x <- trimws(x)
  x[x == ""] <- NA_character_
  x
}
