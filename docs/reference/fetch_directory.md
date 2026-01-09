# Fetch Indiana school directory data

Downloads and processes school directory data from the Indiana
Department of Education. Returns a combined dataset with corporation,
public school, and non-public school directory information.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end. If NULL (default), uses most recent year. Valid
  values are returned by
  [`get_directory_years`](https://almartin82.github.io/inschooldata/reference/get_directory_years.md).

- tidy:

  If TRUE (default), returns data in standardized format with consistent
  column names. If FALSE, returns data closer to raw format.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from IDOE.

## Value

Data frame with directory information including:

- corporation_id: IDOE corporation ID (4 digits)

- school_id: IDOE school ID (4 digits, NA for corporations)

- corporation_name: Name of the corporation/district

- school_name: Name of the school (NA for corporations)

- address: Street address

- city: City name

- state: State abbreviation (always "IN")

- zip: ZIP code

- phone: Phone number

- grades_served: Grade range (e.g., "K-12", "9-12")

- type: "Corporation", "School", or "Non-Public School"

## Examples

``` r
if (FALSE) { # \dontrun{
# Get current school directory
dir <- fetch_directory()

# Get specific year
dir_2025 <- fetch_directory(2025)

# Get raw format
dir_raw <- fetch_directory(tidy = FALSE)

# Find a specific school
dir |>
  dplyr::filter(grepl("Arsenal", school_name, ignore.case = TRUE))
} # }
```
