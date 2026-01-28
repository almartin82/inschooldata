# Fetch assessment data for multiple years

Downloads and combines assessment data for multiple school years.

## Usage

``` r
fetch_assessment_multi(end_years, level = "all", tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_years:

  Vector of school year ends (e.g., c(2022, 2023, 2024)). Note: 2020 is
  automatically excluded due to COVID-19 testing waiver.

- level:

  Level of data: "all" (default), "state", "corporation", or "school"

- tidy:

  If TRUE (default), returns tidy format.

- use_cache:

  If TRUE (default), uses cached data.

## Value

Combined data frame with assessment data for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get recent ILEARN years
assess_multi <- fetch_assessment_multi(2021:2024)

# Track proficiency trends
assess_multi |>
  dplyr::filter(is_state, subject == "Math", grade == "All") |>
  dplyr::filter(proficiency_level == "proficient") |>
  dplyr::select(end_year, value)
} # }
```
