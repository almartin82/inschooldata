# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw assessment data into a
# standardized schema.
#
# ==============================================================================


#' Process raw assessment data to standard schema
#'
#' Takes raw assessment data from IDOE and processes it into a consistent
#' schema suitable for analysis.
#'
#' @param raw_data List with state, corporation, and/or school data frames
#' @param end_year School year end
#' @return Data frame with processed assessment data
#' @keywords internal
process_assessment <- function(raw_data, end_year) {

  # Process each level
  result <- list()

  if ("state" %in% names(raw_data) && !is.null(raw_data$state) && nrow(raw_data$state) > 0) {
    state_df <- process_assessment_level(raw_data$state, "state", end_year)
    if (nrow(state_df) > 0) {
      result$state <- state_df
    }
  }

  if ("corporation" %in% names(raw_data) && !is.null(raw_data$corporation) && nrow(raw_data$corporation) > 0) {
    corp_df <- process_assessment_level(raw_data$corporation, "corporation", end_year)
    if (nrow(corp_df) > 0) {
      result$corporation <- corp_df
    }
  }

  if ("school" %in% names(raw_data) && !is.null(raw_data$school) && nrow(raw_data$school) > 0) {
    school_df <- process_assessment_level(raw_data$school, "school", end_year)
    if (nrow(school_df) > 0) {
      result$school <- school_df
    }
  }

  if (length(result) == 0) {
    return(create_empty_assessment_processed())
  }

  # Combine all levels
  dplyr::bind_rows(result)
}


#' Process assessment data for a single level
#'
#' @param df Data frame with raw assessment data
#' @param level Data level: "state", "corporation", or "school"
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_assessment_level <- function(df, level, end_year) {

  if (nrow(df) == 0) {
    return(create_empty_assessment_processed())
  }

  # Find ID columns
  corp_id_col <- find_col(names(df), c("corp_id", "corporation_id", "idoe_corporation_id"))
  corp_name_col <- find_col(names(df), c("corp_name", "corporation_name"))
  school_id_col <- find_col(names(df), c("school_id", "schl_id", "idoe_school_id"))
  school_name_col <- find_col(names(df), c("school_name", "schl_name"))

  # Build result data frame
  result <- df

  # Standardize ID columns
  if (!is.null(corp_id_col)) {
    result$corporation_id <- standardize_corp_id(result[[corp_id_col]])
  } else {
    result$corporation_id <- NA_character_
  }

  if (!is.null(corp_name_col)) {
    result$corporation_name <- clean_corp_name(result[[corp_name_col]])
  } else {
    result$corporation_name <- NA_character_
  }

  if (!is.null(school_id_col)) {
    result$school_id <- standardize_school_id(result[[school_id_col]])
  } else {
    result$school_id <- NA_character_
  }

  if (!is.null(school_name_col)) {
    result$school_name <- clean_school_name(result[[school_name_col]])
  } else {
    result$school_name <- NA_character_
  }

  # Set level
  result$aggregation_level <- level

  # Ensure end_year exists
  if (!"end_year" %in% names(result)) {
    result$end_year <- as.integer(end_year)
  }

  # Add aggregation flags
  result$is_state <- level == "state"
  result$is_corporation <- level == "corporation"
  result$is_school <- level == "school"

  # Parse and standardize proficiency columns
  result <- parse_proficiency_columns(result)

  result
}


#' Find column by multiple possible names
#'
#' @param col_names Vector of column names
#' @param possible_names Vector of possible column names to match
#' @return First matching column name or NULL
#' @keywords internal
find_col <- function(col_names, possible_names) {
  for (name in possible_names) {
    matches <- grep(paste0("^", name, "$"), col_names, ignore.case = TRUE, value = TRUE)
    if (length(matches) > 0) {
      return(matches[1])
    }
  }
  NULL
}


#' Parse proficiency columns from wide format
#'
#' IDOE assessment files have columns like:
#' grade3_ela_below_proficiency, grade3_ela_approaching_proficiency, etc.
#'
#' This function identifies and standardizes these columns.
#'
#' @param df Data frame with assessment data
#' @return Data frame with standardized proficiency columns
#' @keywords internal
parse_proficiency_columns <- function(df) {

  # Get all column names
  col_names <- names(df)

  # Find proficiency-related columns
  prof_cols <- grep("below|approaching|at_proficiency|above|proficient|total_tested",
                    col_names, ignore.case = TRUE, value = TRUE)

  # Convert numeric columns to proper types
  for (col in prof_cols) {
    if (col %in% names(df)) {
      df[[col]] <- safe_numeric(df[[col]])
    }
  }

  df
}


#' Create empty processed assessment data frame
#'
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_assessment_processed <- function() {
  data.frame(
    corporation_id = character(0),
    corporation_name = character(0),
    school_id = character(0),
    school_name = character(0),
    subject = character(0),
    end_year = integer(0),
    aggregation_level = character(0),
    is_state = logical(0),
    is_corporation = logical(0),
    is_school = logical(0),
    stringsAsFactors = FALSE
  )
}
