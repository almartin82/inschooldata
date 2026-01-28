# Tidy assessment data

Converts wide-format assessment data to tidy (long) format. Each row
represents one grade-subject-proficiency level combination.

## Usage

``` r
tidy_assessment(df)
```

## Arguments

- df:

  Data frame with processed assessment data (wide format)

## Value

Data frame in tidy format

## Examples

``` r
if (FALSE) { # \dontrun{
# Get wide format data
assess <- fetch_assessment(2024, tidy = FALSE)

# Convert to tidy
assess_tidy <- tidy_assessment(assess)
} # }
```
