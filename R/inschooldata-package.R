#' inschooldata: Fetch and Process Indiana School Data
#'
#' Downloads and processes school data from the Indiana Department of Education
#' (IDOE). Provides functions for fetching enrollment data from IDOE's Data Center
#' and transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{Get available data years}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Indiana uses a simple ID system:
#' \itemize{
#'   \item Corporation IDs: 4 digits (e.g., 5385 = Indianapolis Public Schools)
#'   \item School IDs: 4 digits (unique within corporation)
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Indiana Department of Education's Data Center:
#' \itemize{
#'   \item Data Center: \url{https://www.in.gov/doe/it/data-center-and-reports/}
#'   \item INview: \url{https://inview.doe.in.gov/}
#' }
#'
#' @section Data Availability:
#' \itemize{
#'   \item Years: 2006-2025 (20 years of historical data)
#'   \item Aggregation levels: State, Corporation (District), School
#'   \item Demographics: Race/ethnicity, gender, special education, ELL, free/reduced lunch
#'   \item Grade levels: PK, K, 1-12
#' }
#'
#' @docType package
#' @name inschooldata-package
#' @aliases inschooldata
#' @keywords internal
"_PACKAGE"
