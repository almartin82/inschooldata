# Get assessment URL for a given year and file type

Returns the URL for downloading assessment data from IDOE. URL patterns
vary by year and data type.

## Usage

``` r
get_assessment_url(end_year, level = "corporation", file_type = "main")
```

## Arguments

- end_year:

  School year end

- level:

  Level of data: "state", "corporation", or "school"

- file_type:

  Type of file: "main", "disaggregated", or "ethnicity_gender"

## Value

URL string or NULL if not available
