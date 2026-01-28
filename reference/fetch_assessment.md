# Fetch Indiana assessment data

Downloads and returns assessment data from the Indiana Department of
Education. Includes ILEARN (2019, 2021-2025) and ISTEP+ (2014-2018)
data.

## Usage

``` r
fetch_assessment(end_year, level = "all", tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year). Valid years:
  2014-2019, 2021-2025 (no 2020 due to COVID testing waiver).

- level:

  Level of data to fetch: "all" (default), "state", "corporation", or
  "school"

- tidy:

  If TRUE (default), returns data in tidy (long) format. If FALSE,
  returns wide format with separate columns for each grade/proficiency
  level.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with assessment data. Includes proficiency counts and
percentages by grade and subject.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 ILEARN data (2023-24 school year)
assess_2024 <- fetch_assessment(2024)

# Get corporation-level data only
corp_assess <- fetch_assessment(2024, level = "corporation")

# Get wide format (easier for some analyses)
assess_wide <- fetch_assessment(2024, tidy = FALSE)

# Get historical ISTEP+ data
istep_2018 <- fetch_assessment(2018)

# Filter to math results
math_results <- assess_2024 |>
  dplyr::filter(subject == "Math", is_corporation)
} # }
```
