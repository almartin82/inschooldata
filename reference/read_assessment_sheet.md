# Read a single assessment sheet

Parses a single sheet from IDOE assessment Excel file. Handles the
complex multi-row header structure with merged cells.

## Usage

``` r
read_assessment_sheet(filepath, sheet_name, end_year, level)
```

## Arguments

- filepath:

  Path to Excel file

- sheet_name:

  Name of sheet to read

- end_year:

  School year end

- level:

  Data level

## Value

Data frame with assessment data

## Details

ILEARN files have this structure:

- Row 1-3: Notes

- Row 4: Grade labels (Grade 3, Grade 4, ..., Corporation Total)

- Row 5: Column headers (Below, Approaching, At, Above, Total
  Proficient, Total Tested, %)

- Row 6+: Data

Columns per grade: Below, Approaching, At, Above, Total Proficient,
Total Tested, Proficient %
