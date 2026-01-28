# Get assessment data for a specific corporation

Convenience function to fetch assessment data for a single corporation
(district).

## Usage

``` r
fetch_corporation_assessment(
  end_year,
  corporation_id,
  tidy = TRUE,
  use_cache = TRUE
)
```

## Arguments

- end_year:

  School year end

- corporation_id:

  4-digit corporation ID (e.g., "5385" for Indianapolis Public Schools)

- tidy:

  If TRUE (default), returns tidy format

- use_cache:

  If TRUE (default), uses cached data

## Value

Data frame filtered to specified corporation

## Examples

``` r
if (FALSE) { # \dontrun{
# Get Indianapolis Public Schools (5385) assessment data
ips_assess <- fetch_corporation_assessment(2024, "5385")

# Get Fort Wayne Community Schools (0235) data
fw_assess <- fetch_corporation_assessment(2024, "0235")
} # }
```
