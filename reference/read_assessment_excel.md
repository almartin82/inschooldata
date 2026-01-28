# Read assessment data from Excel file

Parses IDOE assessment Excel files. These files have multi-row headers
and multiple sheets for different subjects.

## Usage

``` r
read_assessment_excel(filepath, end_year, level)
```

## Arguments

- filepath:

  Path to Excel file

- end_year:

  School year end

- level:

  Data level

## Value

Data frame with assessment data
