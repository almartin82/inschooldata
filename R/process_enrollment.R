# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw IDOE enrollment data into a
# clean, standardized format.
#
# Indiana Data Structure:
# - Corporation ID (IDOE_CORPORATION_ID): 4 digits
# - School ID (IDOE_SCHOOL_ID): 4 digits
# - Data is reported as of October 1st of each school year
#
# Column naming conventions in IDOE files:
# - Grade levels: GRADE_PK, GRADE_K, GRADE_1 through GRADE_12
# - Demographics: WHITE, BLACK, HISPANIC, ASIAN, etc.
# - Special populations: SPECIAL_ED, ELL (English Language Learner)
# - Free/Reduced Lunch: FREE_LUNCH, REDUCED_LUNCH
#
# ==============================================================================


#' Process raw IDOE enrollment data
#'
#' Transforms raw IDOE data into a standardized schema combining corporation
#' and school data.
#'
#' @param raw_data List containing corporation and school data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process school data
  school_processed <- process_school_enr(raw_data$school, end_year)

  # Process corporation data
  corp_processed <- process_corp_enr(raw_data$corporation, end_year)

  # Create state aggregate
  state_processed <- create_state_aggregate(corp_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, corp_processed, school_processed)

  result
}


#' Process corporation-level enrollment data
#'
#' @param df Raw corporation data frame
#' @param end_year School year end
#' @return Processed corporation data frame
#' @keywords internal
process_corp_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Corporation", n_rows),
    stringsAsFactors = FALSE
  )

  # Corporation ID
  corp_id_col <- find_col(c("^IDOE_CORPORATION_ID$", "^CORP_ID$", "^CORPORATION_ID$"))
  if (!is.null(corp_id_col)) {
    result$corporation_id <- standardize_corp_id(df[[corp_id_col]])
  } else {
    result$corporation_id <- NA_character_
  }

  # School ID is NA for corporation rows
  result$school_id <- rep(NA_character_, n_rows)

  # Corporation name
  corp_name_col <- find_col(c("^CORPORATION_NAME$", "^CORP_NAME$", "^CORPORATION$"))
  if (!is.null(corp_name_col)) {
    result$corporation_name <- clean_corp_name(df[[corp_name_col]])
  } else {
    result$corporation_name <- NA_character_
  }

  result$school_name <- rep(NA_character_, n_rows)

  # Total enrollment
  total_col <- find_col(c("^TOTAL_ENROLLMENT$", "^TOTAL$", "^ENROLLMENT$", "^TOTAL_STUDENTS$"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - ethnicity/race
  demo_map <- list(
    white = c("^WHITE$", "^WHITE_ENROLLMENT$", "^WHITE_COUNT$"),
    black = c("^BLACK$", "^BLACK_ENROLLMENT$", "^AFRICAN_AMERICAN$"),
    hispanic = c("^HISPANIC$", "^HISPANIC_ENROLLMENT$", "^LATINO$"),
    asian = c("^ASIAN$", "^ASIAN_ENROLLMENT$"),
    native_american = c("^NATIVE_AMERICAN$", "^AMERICAN_INDIAN$", "^AMER_INDIAN$"),
    pacific_islander = c("^PACIFIC_ISLANDER$", "^NATIVE_HAWAIIAN$", "^HAWAIIAN$"),
    multiracial = c("^MULTIRACIAL$", "^TWO_OR_MORE$", "^MULTI_RACIAL$", "^TWO_OR_MORE_RACES$")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Gender
  male_col <- find_col(c("^MALE$", "^MALE_ENROLLMENT$", "^MALES$"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  } else {
    result$male <- NA_integer_
  }

  female_col <- find_col(c("^FEMALE$", "^FEMALE_ENROLLMENT$", "^FEMALES$"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  } else {
    result$female <- NA_integer_
  }

  # Special populations
  special_map <- list(
    special_ed = c("^SPECIAL_ED$", "^SPECIAL_EDUCATION$", "^SPED$"),
    lep = c("^ELL$", "^ENGLISH_LANGUAGE_LEARNER$", "^LEP$", "^LIMITED_ENGLISH$"),
    free_lunch = c("^FREE_LUNCH$", "^FREE$"),
    reduced_lunch = c("^REDUCED_LUNCH$", "^REDUCED$")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Calculate economically disadvantaged (free + reduced lunch)
  if ("free_lunch" %in% names(result) && "reduced_lunch" %in% names(result)) {
    result$econ_disadv <- ifelse(
      is.na(result$free_lunch) & is.na(result$reduced_lunch),
      NA_integer_,
      rowSums(cbind(result$free_lunch, result$reduced_lunch), na.rm = TRUE)
    )
  } else if ("free_lunch" %in% names(result)) {
    result$econ_disadv <- result$free_lunch
  } else {
    result$econ_disadv <- NA_integer_
  }

  # Grade levels
  grade_map <- list(
    grade_pk = c("^GRADE_PK$", "^PRE_K$", "^PK$", "^PREK$"),
    grade_k = c("^GRADE_K$", "^KINDERGARTEN$", "^K$", "^KG$"),
    grade_01 = c("^GRADE_1$", "^GRADE_01$", "^G1$", "^GR_1$", "^GR1$"),
    grade_02 = c("^GRADE_2$", "^GRADE_02$", "^G2$", "^GR_2$", "^GR2$"),
    grade_03 = c("^GRADE_3$", "^GRADE_03$", "^G3$", "^GR_3$", "^GR3$"),
    grade_04 = c("^GRADE_4$", "^GRADE_04$", "^G4$", "^GR_4$", "^GR4$"),
    grade_05 = c("^GRADE_5$", "^GRADE_05$", "^G5$", "^GR_5$", "^GR5$"),
    grade_06 = c("^GRADE_6$", "^GRADE_06$", "^G6$", "^GR_6$", "^GR6$"),
    grade_07 = c("^GRADE_7$", "^GRADE_07$", "^G7$", "^GR_7$", "^GR7$"),
    grade_08 = c("^GRADE_8$", "^GRADE_08$", "^G8$", "^GR_8$", "^GR8$"),
    grade_09 = c("^GRADE_9$", "^GRADE_09$", "^G9$", "^GR_9$", "^GR9$"),
    grade_10 = c("^GRADE_10$", "^G10$", "^GR_10$", "^GR10$"),
    grade_11 = c("^GRADE_11$", "^G11$", "^GR_11$", "^GR11$"),
    grade_12 = c("^GRADE_12$", "^G12$", "^GR_12$", "^GR12$")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  result
}


#' Process school-level enrollment data
#'
#' @param df Raw school data frame
#' @param end_year School year end
#' @return Processed school data frame
#' @keywords internal
process_school_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("School", n_rows),
    stringsAsFactors = FALSE
  )

  # Corporation ID
  corp_id_col <- find_col(c("^IDOE_CORPORATION_ID$", "^CORP_ID$", "^CORPORATION_ID$"))
  if (!is.null(corp_id_col)) {
    result$corporation_id <- standardize_corp_id(df[[corp_id_col]])
  } else {
    result$corporation_id <- NA_character_
  }

  # School ID (IDOE uses "SCHL_ID" in their files)
  school_id_col <- find_col(c("^IDOE_SCHOOL_ID$", "^SCHOOL_ID$", "^SCHL_ID$"))
  if (!is.null(school_id_col)) {
    result$school_id <- standardize_school_id(df[[school_id_col]])
  } else {
    result$school_id <- NA_character_
  }

  # Corporation name
  corp_name_col <- find_col(c("^CORPORATION_NAME$", "^CORP_NAME$", "^CORPORATION$"))
  if (!is.null(corp_name_col)) {
    result$corporation_name <- clean_corp_name(df[[corp_name_col]])
  } else {
    result$corporation_name <- NA_character_
  }

  # School name (IDOE uses "SCHL_NAME" in their files)
  school_name_col <- find_col(c("^SCHOOL_NAME$", "^SCHOOL$", "^SCHL_NAME$"))
  if (!is.null(school_name_col)) {
    result$school_name <- clean_school_name(df[[school_name_col]])
  } else {
    result$school_name <- NA_character_
  }

  # Total enrollment
  total_col <- find_col(c("^TOTAL_ENROLLMENT$", "^TOTAL$", "^ENROLLMENT$", "^TOTAL_STUDENTS$"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - ethnicity/race
  demo_map <- list(
    white = c("^WHITE$", "^WHITE_ENROLLMENT$", "^WHITE_COUNT$"),
    black = c("^BLACK$", "^BLACK_ENROLLMENT$", "^AFRICAN_AMERICAN$"),
    hispanic = c("^HISPANIC$", "^HISPANIC_ENROLLMENT$", "^LATINO$"),
    asian = c("^ASIAN$", "^ASIAN_ENROLLMENT$"),
    native_american = c("^NATIVE_AMERICAN$", "^AMERICAN_INDIAN$", "^AMER_INDIAN$"),
    pacific_islander = c("^PACIFIC_ISLANDER$", "^NATIVE_HAWAIIAN$", "^HAWAIIAN$"),
    multiracial = c("^MULTIRACIAL$", "^TWO_OR_MORE$", "^MULTI_RACIAL$", "^TWO_OR_MORE_RACES$")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Gender
  male_col <- find_col(c("^MALE$", "^MALE_ENROLLMENT$", "^MALES$"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  } else {
    result$male <- NA_integer_
  }

  female_col <- find_col(c("^FEMALE$", "^FEMALE_ENROLLMENT$", "^FEMALES$"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  } else {
    result$female <- NA_integer_
  }

  # Special populations
  special_map <- list(
    special_ed = c("^SPECIAL_ED$", "^SPECIAL_EDUCATION$", "^SPED$"),
    lep = c("^ELL$", "^ENGLISH_LANGUAGE_LEARNER$", "^LEP$", "^LIMITED_ENGLISH$"),
    free_lunch = c("^FREE_LUNCH$", "^FREE$"),
    reduced_lunch = c("^REDUCED_LUNCH$", "^REDUCED$")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Calculate economically disadvantaged (free + reduced lunch)
  if ("free_lunch" %in% names(result) && "reduced_lunch" %in% names(result)) {
    result$econ_disadv <- ifelse(
      is.na(result$free_lunch) & is.na(result$reduced_lunch),
      NA_integer_,
      rowSums(cbind(result$free_lunch, result$reduced_lunch), na.rm = TRUE)
    )
  } else if ("free_lunch" %in% names(result)) {
    result$econ_disadv <- result$free_lunch
  } else {
    result$econ_disadv <- NA_integer_
  }

  # Grade levels
  grade_map <- list(
    grade_pk = c("^GRADE_PK$", "^PRE_K$", "^PK$", "^PREK$"),
    grade_k = c("^GRADE_K$", "^KINDERGARTEN$", "^K$", "^KG$"),
    grade_01 = c("^GRADE_1$", "^GRADE_01$", "^G1$", "^GR_1$", "^GR1$"),
    grade_02 = c("^GRADE_2$", "^GRADE_02$", "^G2$", "^GR_2$", "^GR2$"),
    grade_03 = c("^GRADE_3$", "^GRADE_03$", "^G3$", "^GR_3$", "^GR3$"),
    grade_04 = c("^GRADE_4$", "^GRADE_04$", "^G4$", "^GR_4$", "^GR4$"),
    grade_05 = c("^GRADE_5$", "^GRADE_05$", "^G5$", "^GR_5$", "^GR5$"),
    grade_06 = c("^GRADE_6$", "^GRADE_06$", "^G6$", "^GR_6$", "^GR6$"),
    grade_07 = c("^GRADE_7$", "^GRADE_07$", "^G7$", "^GR_7$", "^GR7$"),
    grade_08 = c("^GRADE_8$", "^GRADE_08$", "^G8$", "^GR_8$", "^GR8$"),
    grade_09 = c("^GRADE_9$", "^GRADE_09$", "^G9$", "^GR_9$", "^GR9$"),
    grade_10 = c("^GRADE_10$", "^G10$", "^GR_10$", "^GR10$"),
    grade_11 = c("^GRADE_11$", "^G11$", "^GR_11$", "^GR11$"),
    grade_12 = c("^GRADE_12$", "^G12$", "^GR_12$", "^GR12$")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  result
}


#' Create state-level aggregate from corporation data
#'
#' @param corp_df Processed corporation data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(corp_df, end_year) {

  if (is.null(corp_df) || nrow(corp_df) == 0) {
    # Return minimal state row
    return(data.frame(
      end_year = end_year,
      type = "State",
      corporation_id = NA_character_,
      school_id = NA_character_,
      corporation_name = NA_character_,
      school_name = NA_character_,
      stringsAsFactors = FALSE
    ))
  }

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "free_lunch", "reduced_lunch",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(corp_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    corporation_id = NA_character_,
    school_id = NA_character_,
    corporation_name = NA_character_,
    school_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(corp_df[[col]], na.rm = TRUE)
  }

  state_row
}
