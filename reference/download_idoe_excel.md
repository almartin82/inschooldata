# Download and read IDOE Excel file

Downloads an Excel file from IDOE and extracts data for the specified
year. Uses a raw data cache to avoid re-downloading large files.

## Usage

``` r
download_idoe_excel(url, file_type, end_year)
```

## Arguments

- url:

  URL of the Excel file

- file_type:

  Type of file (for caching)

- end_year:

  School year end to extract

## Value

Data frame with data for the specified year

## Details

IDOE Excel files have each year's data in a separate sheet named after
the year (e.g., "2025", "2024", "2023", etc.).
