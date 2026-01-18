# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL


#' Convert to numeric, handling suppression markers
#'
#' IDOE uses various markers for suppressed data (*, <10, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Handle NULL or empty input
  if (is.null(x) || length(x) == 0) {
    return(numeric(0))
  }

  # Convert to character if needed
  x <- as.character(x)

  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "NULL")] <- NA_character_

  # Handle any remaining non-numeric patterns
  x[grepl("^<", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get the minimum available year
#'
#' @return Integer representing earliest available year
#' @keywords internal
get_min_year <- function() {

  2006L
}


#' Get the maximum available year
#'
#' @return Integer representing most recent available year (2024)
#' @keywords internal
get_max_year <- function() {
  2024L
}


#' Get available years for Indiana enrollment data
#'
#' Returns the range of years for which enrollment data is available.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  get_min_year():get_max_year()
}


#' Validate year parameter
#'
#' @param end_year Year to validate
#' @return TRUE if valid, throws error if not
#' @keywords internal
validate_year <- function(end_year) {
  min_year <- get_min_year()
  max_year <- get_max_year()

  if (!is.numeric(end_year) || length(end_year) != 1) {
    stop("end_year must be a single numeric value")
  }

  if (end_year < min_year || end_year > max_year) {
    stop(paste0(
      "end_year must be between ", min_year, " and ", max_year, ".\n",
      "You provided: ", end_year, "\n",
      "Available years: ", min_year, "-", max_year
    ))
  }

  TRUE
}


#' Clean corporation/district name
#'
#' Standardizes corporation names by trimming whitespace and
#' handling common formatting issues.
#'
#' @param x Character vector of names
#' @return Cleaned character vector
#' @keywords internal
clean_corp_name <- function(x) {
  if (is.null(x)) return(NA_character_)
  x <- trimws(x)
  x[x == ""] <- NA_character_
  x
}


#' Clean school name
#'
#' Standardizes school names by trimming whitespace and
#' handling common formatting issues.
#'
#' @param x Character vector of names
#' @return Cleaned character vector
#' @keywords internal
clean_school_name <- function(x) {
  if (is.null(x)) return(NA_character_)
  x <- trimws(x)
  x[x == ""] <- NA_character_
  x
}


#' Standardize corporation ID
#'
#' Ensures corporation IDs are formatted consistently as 4-digit strings.
#'
#' @param x Character or numeric vector of IDs
#' @return Character vector of standardized IDs
#' @keywords internal
standardize_corp_id <- function(x) {
  if (is.null(x)) return(NA_character_)

  # Convert to character and clean
  x <- trimws(as.character(x))

  # Convert to numeric and pad with leading zeros
  numeric_x <- suppressWarnings(as.integer(x))
  result <- sprintf("%04d", numeric_x)

  # Replace malformed entries with NA
  result[is.na(numeric_x) | numeric_x < 0 | numeric_x > 9999] <- NA_character_

  result
}


#' Standardize school ID
#'
#' Ensures school IDs are formatted consistently as 4-digit strings.
#'
#' @param x Character or numeric vector of IDs
#' @return Character vector of standardized IDs
#' @keywords internal
standardize_school_id <- function(x) {
  if (is.null(x)) return(NA_character_)

  # Convert to character and clean
  x <- trimws(as.character(x))

  # Convert to numeric and pad with leading zeros
  numeric_x <- suppressWarnings(as.integer(x))
  result <- sprintf("%04d", numeric_x)

  # Replace malformed entries with NA
  result[is.na(numeric_x) | numeric_x < 0 | numeric_x > 9999] <- NA_character_

  result
}
