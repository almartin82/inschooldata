# inschooldata: Fetch and Process Indiana School Data

Downloads and processes school data from the Indiana Department of
Education (IDOE). Provides functions for fetching enrollment data from
IDOE's Data Center and transforming it into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/inschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/inschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/inschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/inschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/inschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/inschooldata/reference/get_available_years.md):

  Get available data years

## Cache functions

- [`cache_status`](https://almartin82.github.io/inschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/inschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Indiana uses a simple ID system:

- Corporation IDs: 4 digits (e.g., 5385 = Indianapolis Public Schools)

- School IDs: 4 digits (unique within corporation)

## Data Sources

Data is sourced from the Indiana Department of Education's Data Center:

- Data Center: <https://www.in.gov/doe/it/data-center-and-reports/>

- INview: <https://inview.doe.in.gov/>

## Data Availability

- Years: 2006-2024 (19 years of historical data)

- Aggregation levels: State, Corporation (District), School

- Demographics: Race/ethnicity, gender, special education, ELL,
  free/reduced lunch

- Grade levels: PK, K, 1-12

## See also

Useful links:

- <https://almartin82.github.io/inschooldata>

- <https://github.com/almartin82/inschooldata>

- Report bugs at <https://github.com/almartin82/inschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
