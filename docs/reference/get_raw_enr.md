# Download raw enrollment data from IDOE

Downloads corporation and school enrollment data from IDOE's Data
Center. IDOE provides multi-year Excel files, so this function downloads
the relevant files and extracts data for the requested year.

## Usage

``` r
get_raw_enr(end_year)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024)

## Value

List with corporation and school data frames
