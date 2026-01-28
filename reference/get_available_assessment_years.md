# Get available assessment years

Returns information about available assessment data years.

## Usage

``` r
get_available_assessment_years()
```

## Value

List with years, min_year, max_year, and note

## Examples

``` r
get_available_assessment_years()
#> $years
#>  [1] 2014 2015 2016 2017 2018 2019 2021 2022 2023 2024 2025
#> 
#> $ilearn_years
#> [1] 2019 2021 2022 2023 2024 2025
#> 
#> $istep_years
#> [1] 2014 2015 2016 2017 2018
#> 
#> $min_year
#> [1] 2014
#> 
#> $max_year
#> [1] 2025
#> 
#> $note
#> [1] "2020 assessment data not available due to COVID-19 testing waiver."
#> 
```
