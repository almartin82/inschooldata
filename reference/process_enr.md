# Process raw IDOE enrollment data

Transforms raw IDOE data into a standardized schema combining
corporation and school data.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  List containing corporation and school data frames from get_raw_enr

- end_year:

  School year end

## Value

Processed data frame with standardized columns
