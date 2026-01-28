# Add aggregation flags to assessment data

Identifies state, corporation, and school level rows based on IDs.

## Usage

``` r
id_assessment_aggs(df)
```

## Arguments

- df:

  Assessment data frame

## Value

Data frame with aggregation flags

## Examples

``` r
if (FALSE) { # \dontrun{
assess <- fetch_assessment(2024, tidy = FALSE)
assess <- id_assessment_aggs(assess)
} # }
```
