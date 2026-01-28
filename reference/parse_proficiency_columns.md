# Parse proficiency columns from wide format

IDOE assessment files have columns like: grade3_ela_below_proficiency,
grade3_ela_approaching_proficiency, etc.

## Usage

``` r
parse_proficiency_columns(df)
```

## Arguments

- df:

  Data frame with assessment data

## Value

Data frame with standardized proficiency columns

## Details

This function identifies and standardizes these columns.
