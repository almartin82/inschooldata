# inschooldata

An R package for fetching and analyzing Indiana public school enrollment data from the Indiana Department of Education (IDOE).

## Installation

```r
# Install from GitHub
devtools::install_github("almartin82/inschooldata")
```

## Quick Start

```r
library(inschooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# Get wide format instead of tidy
enr_wide <- fetch_enr(2024, tidy = FALSE)

# See what years are available
get_available_years()
```

## Data Availability

### Years Available

**2006-2025** (20 years of historical data)

All enrollment data is reported as of October 1st of each school year.

### Aggregation Levels

| Level | Description | Identifier |
|-------|-------------|------------|
| State | Indiana statewide totals | NA |
| Corporation | School districts/corporations | 4-digit corporation ID |
| School | Individual schools | 4-digit school ID |

### Demographics Available

| Category | Available | Years | Notes |
|----------|-----------|-------|-------|
| Total Enrollment | Yes | 2006-2025 | All students |
| White | Yes | 2006-2025 | |
| Black/African American | Yes | 2006-2025 | |
| Hispanic/Latino | Yes | 2006-2025 | |
| Asian | Yes | 2006-2025 | |
| Native American | Yes | 2006-2025 | American Indian/Alaska Native |
| Pacific Islander | Yes | 2006-2025 | Native Hawaiian/Pacific Islander |
| Multiracial | Yes | 2006-2025 | Two or more races |
| Male | Yes | 2006-2025 | |
| Female | Yes | 2006-2025 | |

### Special Populations

| Category | Available | Years | Notes |
|----------|-----------|-------|-------|
| Special Education | Yes | 2006-2025 | Students with IEPs |
| English Language Learners (ELL) | Yes | 2006-2025 | Limited English Proficient |
| Free Lunch | Yes | 2006-2025 | National School Lunch Program |
| Reduced Lunch | Yes | 2006-2025 | National School Lunch Program |
| Economically Disadvantaged | Calculated | 2006-2025 | Free + Reduced Lunch |

### Grade Levels

| Grade | Available | Notes |
|-------|-----------|-------|
| Pre-K (PK) | Yes | |
| Kindergarten (K) | Yes | |
| Grades 1-12 | Yes | Individual grade-level counts |

## Data Source

Data is downloaded from the Indiana Department of Education's Data Center:
- **Primary URL**: https://www.in.gov/doe/it/data-center-and-reports/

The IDOE provides Excel files containing multi-year historical data:
- Corporation Enrollment by Grade Level (2006-2025)
- Corporation Enrollment by Ethnicity and Free/Reduced Price Meal Status (2006-2025)
- Corporation Enrollment by Special Education and ELL (2006-2025)
- Corporation Enrollment by Grade Level and Gender (2006-2025)
- School Enrollment by Grade Level (2006-2025)
- School Enrollment by Ethnicity and Free/Reduced Price Meal Status (2006-2025)
- School Enrollment by Special Education and ELL (2006-2025)
- School Enrollment by Grade Level and Gender (2006-2025)

## ID System

Indiana uses a simple 4-digit ID system:

| ID Type | Format | Example | Description |
|---------|--------|---------|-------------|
| Corporation ID | 4 digits | 5385 | Indianapolis Public Schools |
| School ID | 4 digits | 0001 | Individual school within corporation |

Note: Corporation IDs are unique statewide. School IDs are unique within their corporation.

## Known Caveats

1. **Data as of October 1st**: All enrollment counts represent the official count date of October 1st each school year.

2. **Suppression**: Small cell sizes may be suppressed for privacy. These appear as NA in the data.

3. **Corporation Changes**: Some corporations have merged, split, or been renamed over the 20-year period. Historical data reflects the corporation structure at the time of reporting.

4. **Charter Schools**: Charter schools are included but report differently in some years. They may be listed under their own corporation or under a sponsoring corporation.

5. **Virtual Schools**: Virtual/online schools are included starting in later years of the data series.

## Examples

### State Total Over Time

```r
library(inschooldata)
library(dplyr)

# Get state totals over time
state_totals <- fetch_enr_multi(2006:2024) %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)

print(state_totals)
```

### Largest Corporations

```r
# Find largest corporations in 2024
largest_corps <- fetch_enr(2024) %>%
  filter(is_corporation, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(corporation_name, n_students)

print(largest_corps)
```

### Demographic Breakdown

```r
# Get demographic percentages for state
demographics <- fetch_enr(2024) %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  select(subgroup, n_students, pct)

print(demographics)
```

## Cache Management

The package caches downloaded data to avoid repeated downloads:

```r
# View cached files
cache_status()

# Clear all cached data
clear_cache()

# Clear specific year
clear_cache(2024)

# Force fresh download
enr <- fetch_enr(2024, use_cache = FALSE)
```

## Related Packages

This package is part of a family of state school data packages:
- [txschooldata](https://github.com/almartin82/txschooldata) - Texas
- [ilschooldata](https://github.com/almartin82/ilschooldata) - Illinois
- [nyschooldata](https://github.com/almartin82/nyschooldata) - New York
- [ohschooldata](https://github.com/almartin82/ohschooldata) - Ohio
- [paschooldata](https://github.com/almartin82/paschooldata) - Pennsylvania
- [caschooldata](https://github.com/almartin82/caschooldata) - California

## License
MIT
