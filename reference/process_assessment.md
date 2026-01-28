# Process raw assessment data to standard schema

Takes raw assessment data from IDOE and processes it into a consistent
schema suitable for analysis.

## Usage

``` r
process_assessment(raw_data, end_year)
```

## Arguments

- raw_data:

  List with state, corporation, and/or school data frames

- end_year:

  School year end

## Value

Data frame with processed assessment data
