# ==============================================================================
# Assessment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for converting wide-format assessment data
# to tidy (long) format.
#
# ==============================================================================


#' Tidy assessment data
#'
#' Converts wide-format assessment data to tidy (long) format.
#' Each row represents one grade-subject-proficiency level combination.
#'
#' @param df Data frame with processed assessment data (wide format)
#' @return Data frame in tidy format
#' @export
#' @examples
#' \dontrun{
#' # Get wide format data
#' assess <- fetch_assessment(2024, tidy = FALSE)
#'
#' # Convert to tidy
#' assess_tidy <- tidy_assessment(assess)
#' }
tidy_assessment <- function(df) {

  if (nrow(df) == 0) {
    return(create_empty_tidy_assessment())
  }

  # Identify grade columns (grade3_, grade4_, ..., total_)
  col_names <- names(df)

  # Find grade-specific columns
  grade_pattern <- "^(grade[3-8]|total)_"
  grade_cols <- grep(grade_pattern, col_names, value = TRUE, ignore.case = TRUE)

  if (length(grade_cols) == 0) {
    # No grade columns found - data might already be in different format
    return(df)
  }

  # ID columns to keep
  id_cols <- c("corporation_id", "corporation_name", "school_id", "school_name",
               "subject", "end_year", "aggregation_level", "is_state",
               "is_corporation", "is_school", "level")
  id_cols <- id_cols[id_cols %in% col_names]

  # For each row, we should only pivot columns that match that row's subject
  # This is handled by filtering based on the subject column after pivoting

  # Pivot longer
  tidy_df <- df |>
    tidyr::pivot_longer(
      cols = tidyr::all_of(grade_cols),
      names_to = "column",
      values_to = "value",
      values_transform = list(value = as.character)
    )

  # Parse column names to extract grade and metric
  tidy_df <- tidy_df |>
    dplyr::mutate(
      grade = stringr::str_extract(.data$column, "^(grade[3-8]|total)"),
      grade = dplyr::case_when(
        .data$grade == "grade3" ~ "3",
        .data$grade == "grade4" ~ "4",
        .data$grade == "grade5" ~ "5",
        .data$grade == "grade6" ~ "6",
        .data$grade == "grade7" ~ "7",
        .data$grade == "grade8" ~ "8",
        .data$grade == "total" ~ "All",
        TRUE ~ .data$grade
      ),
      metric = stringr::str_remove(.data$column, "^(grade[3-8]|total)_")
    )

  # Parse metric into subject_part and proficiency_level
  tidy_df <- tidy_df |>
    dplyr::mutate(
      # Extract proficiency level
      proficiency_level = dplyr::case_when(
        grepl("_below$|_below_", .data$metric, ignore.case = TRUE) ~ "below",
        grepl("_approaching$|_approaching_", .data$metric, ignore.case = TRUE) ~ "approaching",
        grepl("_at$|_at_", .data$metric, ignore.case = TRUE) ~ "at",
        grepl("_above$|_above_", .data$metric, ignore.case = TRUE) ~ "above",
        grepl("_proficient$|_proficient_", .data$metric, ignore.case = TRUE) ~ "proficient",
        grepl("_tested$|_tested_", .data$metric, ignore.case = TRUE) ~ "total_tested",
        grepl("_pct$|_pct_", .data$metric, ignore.case = TRUE) ~ "pct_proficient",
        TRUE ~ "other"
      ),
      # Extract subject from column name (the metric part)
      col_subject = dplyr::case_when(
        grepl("_ela_", .data$column, ignore.case = TRUE) ~ "ELA",
        grepl("_math_", .data$column, ignore.case = TRUE) ~ "Math",
        grepl("_science_", .data$column, ignore.case = TRUE) ~ "Science",
        grepl("_social_", .data$column, ignore.case = TRUE) ~ "Social Studies",
        TRUE ~ NA_character_
      )
    )

  # Filter to only keep rows where the column subject matches the row subject
  # This removes the NA rows that come from pivoting columns that don't belong to this row's subject
  if ("subject" %in% names(tidy_df)) {
    tidy_df <- tidy_df |>
      dplyr::filter(
        is.na(.data$col_subject) |
        is.na(.data$subject) |
        .data$col_subject == .data$subject
      )
  }

  # Convert value to numeric
  tidy_df <- tidy_df |>
    dplyr::mutate(
      value = safe_numeric(.data$value)
    )

  # Remove rows with NA values (from columns that don't match subject)
  tidy_df <- tidy_df |>
    dplyr::filter(!is.na(.data$value))

  # Clean up - remove intermediate columns
  tidy_df <- tidy_df |>
    dplyr::select(-dplyr::any_of(c("column", "metric", "col_subject")))

  # Remove duplicate columns (keep first instance)
  dup_cols <- duplicated(names(tidy_df))
  if (any(dup_cols)) {
    tidy_df <- tidy_df[, !dup_cols, drop = FALSE]
  }

  # Also remove the extra ID columns that came through from raw data
  tidy_df <- tidy_df |>
    dplyr::select(-dplyr::any_of(c("corp_id", "corp_name", "school_id_raw", "school_name_raw")))

  # Reorder columns
  final_cols <- c("corporation_id", "corporation_name", "school_id", "school_name",
                  "subject", "grade", "proficiency_level", "value",
                  "end_year", "aggregation_level", "is_state",
                  "is_corporation", "is_school")
  final_cols <- final_cols[final_cols %in% names(tidy_df)]

  other_cols <- setdiff(names(tidy_df), final_cols)
  tidy_df <- tidy_df[, c(final_cols, other_cols)]

  tidy_df
}


#' Add aggregation flags to assessment data
#'
#' Identifies state, corporation, and school level rows based on IDs.
#'
#' @param df Assessment data frame
#' @return Data frame with aggregation flags
#' @export
#' @examples
#' \dontrun{
#' assess <- fetch_assessment(2024, tidy = FALSE)
#' assess <- id_assessment_aggs(assess)
#' }
id_assessment_aggs <- function(df) {

  if (nrow(df) == 0) {
    return(df)
  }

  # Check if flags already exist
  if (all(c("is_state", "is_corporation", "is_school") %in% names(df))) {
    return(df)
  }

  # Set flags based on aggregation_level if it exists
  if ("aggregation_level" %in% names(df)) {
    df$is_state <- df$aggregation_level == "state"
    df$is_corporation <- df$aggregation_level == "corporation"
    df$is_school <- df$aggregation_level == "school"
    return(df)
  }

  # Otherwise, infer from ID columns
  has_corp <- "corporation_id" %in% names(df)
  has_school <- "school_id" %in% names(df)

  if (has_corp && has_school) {
    df$is_state <- is.na(df$corporation_id) | df$corporation_id == ""
    df$is_corporation <- !is.na(df$corporation_id) & df$corporation_id != "" &
      (is.na(df$school_id) | df$school_id == "")
    df$is_school <- !is.na(df$corporation_id) & df$corporation_id != "" &
      !is.na(df$school_id) & df$school_id != ""
  } else if (has_corp) {
    df$is_state <- is.na(df$corporation_id) | df$corporation_id == ""
    df$is_corporation <- !is.na(df$corporation_id) & df$corporation_id != ""
    df$is_school <- FALSE
  } else {
    df$is_state <- TRUE
    df$is_corporation <- FALSE
    df$is_school <- FALSE
  }

  df
}


#' Create empty tidy assessment data frame
#'
#' @return Empty data frame with tidy assessment columns
#' @keywords internal
create_empty_tidy_assessment <- function() {
  data.frame(
    corporation_id = character(0),
    corporation_name = character(0),
    school_id = character(0),
    school_name = character(0),
    subject = character(0),
    grade = character(0),
    proficiency_level = character(0),
    value = numeric(0),
    end_year = integer(0),
    aggregation_level = character(0),
    is_state = logical(0),
    is_corporation = logical(0),
    is_school = logical(0),
    stringsAsFactors = FALSE
  )
}
