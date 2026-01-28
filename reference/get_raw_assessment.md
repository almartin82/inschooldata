# Download raw assessment data from IDOE

Downloads assessment data from IDOE for the specified year. Returns raw
data from the Excel files without processing.

## Usage

``` r
get_raw_assessment(end_year, level = "all")
```

## Arguments

- end_year:

  School year end (2014-2019, 2021-2025; no 2020 due to COVID)

- level:

  Level of data: "all" (default), "state", "corporation", or "school"

## Value

List with data frames for each level requested
