# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from the
# Indiana Department of Education (IDOE).
#
# Data is available from the IDOE Data Center:
# https://www.in.gov/doe/it/data-center-and-reports/
#
# IDOE provides Excel files with multiple years of historical data in single
# files. The package downloads these files once and caches them to avoid
# repeated downloads.
#
# Available data files (all in Excel format, covering 2006-2024):
# - Corporation Enrollment by Grade Level
# - Corporation Enrollment by Ethnicity and Free/Reduced Price Meal Status
# - Corporation Enrollment by Special Education and ELL
# - Corporation Enrollment by Grade Level and Gender
# - School Enrollment by Grade Level
# - School Enrollment by Ethnicity and Free/Reduced Price Meal Status
# - School Enrollment by Special Education and ELL
# - School Enrollment by Grade Level and Gender
#
# ==============================================================================

#' Base URL for IDOE data files
#'
#' @keywords internal
idoe_base_url <- function() {

  "https://www.in.gov/doe/files/"
}


#' Get URLs for IDOE enrollment data files
#'
#' Returns a list of URLs for the various enrollment data files.
#' IDOE uses Excel files that contain multiple years of data.
#'
#' @return Named list of file URLs
#' @keywords internal
get_idoe_file_urls <- function() {
  base <- idoe_base_url()

  list(
    # Corporation (district) level files
    corp_grade = paste0(base, "corporation-enrollment-grade-2006-25.xlsx"),
    corp_ethnicity = paste0(base, "corporation-enrollment-ethnicity-free-reduced-price-meal-status-2006-25.xlsx"),
    corp_sped_ell = paste0(base, "corporation-enrollment-ell-special-education-2006-25-updated.xlsx"),
    corp_gender = paste0(base, "corporation-enrollment-grade-gender-2006-25.xlsx"),

    # School level files
    school_grade = paste0(base, "school-enrollment-grade-2006-25.xlsx"),
    school_ethnicity = paste0(base, "school-enrollment-ethnicity-and-free-reduced-price-meal-status-2006-25-final.xlsx"),
    school_sped_ell = paste0(base, "school-enrollment-ell-special-education-2006-25-updated.xlsx"),
    school_gender = paste0(base, "school-enrollment-grade-gender-2006-25.xlsx")
  )
}


#' Download raw enrollment data from IDOE
#'
#' Downloads corporation and school enrollment data from IDOE's Data Center.
#' IDOE provides multi-year Excel files, so this function downloads the relevant
#' files and extracts data for the requested year.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with corporation and school data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  validate_year(end_year)

  message(paste("Downloading IDOE enrollment data for", end_year, "..."))

  # Download and read corporation-level data
  message("  Downloading corporation data...")
  corp_data <- download_and_merge_corp_data(end_year)

  # Download and read school-level data
  message("  Downloading school data...")
  school_data <- download_and_merge_school_data(end_year)

  list(
    corporation = corp_data,
    school = school_data
  )
}


#' Download and merge corporation-level enrollment data
#'
#' @param end_year School year end
#' @return Data frame with merged corporation data
#' @keywords internal
download_and_merge_corp_data <- function(end_year) {

  urls <- get_idoe_file_urls()

  # Download each file
  grade_df <- download_idoe_excel(urls$corp_grade, "corp_grade", end_year)
  ethnicity_df <- download_idoe_excel(urls$corp_ethnicity, "corp_ethnicity", end_year)
  sped_ell_df <- download_idoe_excel(urls$corp_sped_ell, "corp_sped_ell", end_year)
  gender_df <- download_idoe_excel(urls$corp_gender, "corp_gender", end_year)

  # Merge all data frames
  # Start with grade data as base
  result <- grade_df

  # IDOE files use CORP_ID as the corporation ID column
  # Find the correct ID column name that exists in the data
  find_corp_id_col <- function(df) {
    possible_cols <- c("CORP_ID", "IDOE_CORPORATION_ID", "CORPORATION_ID")
    for (col in possible_cols) {
      if (col %in% names(df)) return(col)
    }
    NULL
  }

  corp_id_col <- find_corp_id_col(result)

  # Merge ethnicity data
  if (!is.null(ethnicity_df) && nrow(ethnicity_df) > 0 && !is.null(corp_id_col)) {
    # Find common ID columns (CORP_ID or similar, plus YEAR)
    id_cols <- c(corp_id_col, "YEAR")
    id_cols <- id_cols[id_cols %in% names(result) & id_cols %in% names(ethnicity_df)]

    if (length(id_cols) > 0) {
      # Remove duplicate columns before merge (except ID cols)
      eth_cols <- setdiff(names(ethnicity_df), c(names(result), id_cols))
      eth_cols <- c(id_cols, eth_cols)
      if (length(eth_cols) > length(id_cols)) {
        result <- dplyr::left_join(result, ethnicity_df[, eth_cols, drop = FALSE], by = id_cols)
      }
    }
  }

  # Merge sped/ell data
  if (!is.null(sped_ell_df) && nrow(sped_ell_df) > 0 && !is.null(corp_id_col)) {
    id_cols <- c(corp_id_col, "YEAR")
    id_cols <- id_cols[id_cols %in% names(result) & id_cols %in% names(sped_ell_df)]

    if (length(id_cols) > 0) {
      sped_cols <- setdiff(names(sped_ell_df), c(names(result), id_cols))
      sped_cols <- c(id_cols, sped_cols)
      if (length(sped_cols) > length(id_cols)) {
        result <- dplyr::left_join(result, sped_ell_df[, sped_cols, drop = FALSE], by = id_cols)
      }
    }
  }

  # Merge gender data
  if (!is.null(gender_df) && nrow(gender_df) > 0 && !is.null(corp_id_col)) {
    id_cols <- c(corp_id_col, "YEAR")
    id_cols <- id_cols[id_cols %in% names(result) & id_cols %in% names(gender_df)]

    if (length(id_cols) > 0) {
      gender_cols <- setdiff(names(gender_df), c(names(result), id_cols))
      gender_cols <- c(id_cols, gender_cols)
      if (length(gender_cols) > length(id_cols)) {
        result <- dplyr::left_join(result, gender_df[, gender_cols, drop = FALSE], by = id_cols)
      }
    }
  }

  result
}


#' Download and merge school-level enrollment data
#'
#' @param end_year School year end
#' @return Data frame with merged school data
#' @keywords internal
download_and_merge_school_data <- function(end_year) {

  urls <- get_idoe_file_urls()

  # Download each file
  grade_df <- download_idoe_excel(urls$school_grade, "school_grade", end_year)
  ethnicity_df <- download_idoe_excel(urls$school_ethnicity, "school_ethnicity", end_year)
  sped_ell_df <- download_idoe_excel(urls$school_sped_ell, "school_sped_ell", end_year)
  gender_df <- download_idoe_excel(urls$school_gender, "school_gender", end_year)

  # Merge all data frames
  # Start with grade data as base
  result <- grade_df

  # IDOE files use CORP_ID and SCHL_ID as ID columns
  # Find the correct ID column names that exist in the data
  find_id_col <- function(df, possible_cols) {
    for (col in possible_cols) {
      if (col %in% names(df)) return(col)
    }
    NULL
  }

  corp_id_col <- find_id_col(result, c("CORP_ID", "IDOE_CORPORATION_ID", "CORPORATION_ID"))
  school_id_col <- find_id_col(result, c("SCHL_ID", "IDOE_SCHOOL_ID", "SCHOOL_ID"))

  # Build ID columns list for merging
  build_id_cols <- function(df) {
    id_cols <- c()
    if (!is.null(corp_id_col) && corp_id_col %in% names(df)) {
      id_cols <- c(id_cols, corp_id_col)
    }
    if (!is.null(school_id_col) && school_id_col %in% names(df)) {
      id_cols <- c(id_cols, school_id_col)
    }
    if ("YEAR" %in% names(df)) {
      id_cols <- c(id_cols, "YEAR")
    }
    id_cols
  }

  # Merge ethnicity data
  if (!is.null(ethnicity_df) && nrow(ethnicity_df) > 0) {
    id_cols <- build_id_cols(result)
    id_cols <- id_cols[id_cols %in% names(result) & id_cols %in% names(ethnicity_df)]

    if (length(id_cols) > 0) {
      eth_cols <- setdiff(names(ethnicity_df), c(names(result), id_cols))
      eth_cols <- c(id_cols, eth_cols)
      if (length(eth_cols) > length(id_cols)) {
        result <- dplyr::left_join(result, ethnicity_df[, eth_cols, drop = FALSE], by = id_cols)
      }
    }
  }

  # Merge sped/ell data
  if (!is.null(sped_ell_df) && nrow(sped_ell_df) > 0) {
    id_cols <- build_id_cols(result)
    id_cols <- id_cols[id_cols %in% names(result) & id_cols %in% names(sped_ell_df)]

    if (length(id_cols) > 0) {
      sped_cols <- setdiff(names(sped_ell_df), c(names(result), id_cols))
      sped_cols <- c(id_cols, sped_cols)
      if (length(sped_cols) > length(id_cols)) {
        result <- dplyr::left_join(result, sped_ell_df[, sped_cols, drop = FALSE], by = id_cols)
      }
    }
  }

  # Merge gender data
  if (!is.null(gender_df) && nrow(gender_df) > 0) {
    id_cols <- build_id_cols(result)
    id_cols <- id_cols[id_cols %in% names(result) & id_cols %in% names(gender_df)]

    if (length(id_cols) > 0) {
      gender_cols <- setdiff(names(gender_df), c(names(result), id_cols))
      gender_cols <- c(id_cols, gender_cols)
      if (length(gender_cols) > length(id_cols)) {
        result <- dplyr::left_join(result, gender_df[, gender_cols, drop = FALSE], by = id_cols)
      }
    }
  }

  result
}


#' Download and read IDOE Excel file
#'
#' Downloads an Excel file from IDOE and extracts data for the specified year.
#' Uses a raw data cache to avoid re-downloading large files.
#'
#' IDOE Excel files have each year's data in a separate sheet named after
#' the year (e.g., "2024", "2023", "2022", etc.).
#'
#' @param url URL of the Excel file
#' @param file_type Type of file (for caching)
#' @param end_year School year end to extract
#' @return Data frame with data for the specified year
#' @keywords internal
download_idoe_excel <- function(url, file_type, end_year) {

  # Check raw file cache first
  raw_cache_path <- get_raw_cache_path(file_type)

  if (!file.exists(raw_cache_path) || is_raw_cache_stale(raw_cache_path)) {
    # Download file
    message(paste0("    Downloading ", file_type, "..."))

    temp_file <- tempfile(fileext = ".xlsx")

    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(temp_file, overwrite = TRUE),
        httr::timeout(300)
      )

      if (httr::http_error(response)) {
        warning(paste("Failed to download", file_type, "- HTTP error:", httr::status_code(response)))
        return(data.frame())
      }

      # Check file size
      file_info <- file.info(temp_file)
      if (file_info$size < 1000) {
        warning(paste("Downloaded file appears too small for", file_type))
        return(data.frame())
      }

      # Copy to cache
      raw_cache_dir <- dirname(raw_cache_path)
      if (!dir.exists(raw_cache_dir)) {
        dir.create(raw_cache_dir, recursive = TRUE)
      }
      file.copy(temp_file, raw_cache_path, overwrite = TRUE)
      unlink(temp_file)

    }, error = function(e) {
      warning(paste("Failed to download", file_type, "-", e$message))
      return(data.frame())
    })
  }

  # Read from cache
  if (!file.exists(raw_cache_path)) {
    warning(paste("Cache file not found for", file_type))
    return(data.frame())
  }

  # Read Excel file - IDOE uses separate sheets for each year
  tryCatch({
    # Get available sheets
    available_sheets <- readxl::excel_sheets(raw_cache_path)

    # IDOE files have sheets named by year (e.g., "2024", "2023", etc.)
    year_sheet <- as.character(end_year)

    if (year_sheet %in% available_sheets) {
      # Read the sheet for the requested year
      df <- readxl::read_excel(
        raw_cache_path,
        sheet = year_sheet,
        col_types = "text"  # Read all as text, convert later
      )
    } else {
      # Fallback: try to read from default sheet and filter by YEAR column
      # (in case IDOE changes their format in the future)
      message(paste0("    Sheet '", year_sheet, "' not found in ", file_type,
                     ". Available sheets: ", paste(available_sheets, collapse = ", ")))

      df <- readxl::read_excel(
        raw_cache_path,
        col_types = "text"
      )

      # Try to filter by YEAR column if it exists
      names(df) <- toupper(gsub("[^A-Za-z0-9_]", "_", names(df)))
      names(df) <- gsub("_+", "_", names(df))
      names(df) <- gsub("_$", "", names(df))

      year_col <- grep("^YEAR$|^SCHOOL_YEAR$|^SY$", names(df), value = TRUE)
      if (length(year_col) > 0) {
        year_col <- year_col[1]
        df$parsed_year <- sapply(df[[year_col]], function(y) {
          y <- as.character(y)
          if (grepl("-", y)) {
            parts <- strsplit(y, "-")[[1]]
            as.integer(parts[length(parts)])
          } else {
            as.integer(y)
          }
        })
        df <- df[df$parsed_year == end_year, , drop = FALSE]
        df$parsed_year <- NULL
      } else {
        warning(paste("Year", end_year, "not found in", file_type))
        return(data.frame())
      }
    }

    # Standardize column names (uppercase, no spaces)
    names(df) <- toupper(gsub("[^A-Za-z0-9_]", "_", names(df)))
    names(df) <- gsub("_+", "_", names(df))
    names(df) <- gsub("_$", "", names(df))

    # Add YEAR column for downstream processing
    df$YEAR <- as.character(end_year)

    df

  }, error = function(e) {
    warning(paste("Failed to read Excel file for", file_type, "-", e$message))
    return(data.frame())
  })
}


#' Get path for raw file cache
#'
#' @param file_type Type of file
#' @return Path to raw cache file
#' @keywords internal
get_raw_cache_path <- function(file_type) {
  cache_dir <- file.path(
    rappdirs::user_cache_dir("inschooldata"),
    "raw"
  )
  file.path(cache_dir, paste0(file_type, ".xlsx"))
}


#' Check if raw cache is stale
#'
#' @param cache_path Path to cache file
#' @param max_age Maximum age in days (default 7)
#' @return TRUE if cache is stale
#' @keywords internal
is_raw_cache_stale <- function(cache_path, max_age = 7) {
  if (!file.exists(cache_path)) {
    return(TRUE)
  }

  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days > max_age
}
