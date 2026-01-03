# inschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/inschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/inschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/inschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/inschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/inschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/inschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/inschooldata/)** | **[Getting Started](https://almartin82.github.io/inschooldata/articles/quickstart.html)** | **[Enrollment Trends](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html)**

Fetch and analyze Indiana school enrollment data from the Indiana Department of Education (IDOE) in R or Python.

## What can you find with inschooldata?

**20 years of enrollment data (2006-2025).** 1.05 million students today. Over 290 corporations. Here are ten stories hiding in the numbers -- see the [Enrollment Trends vignette](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html) for interactive visualizations:

1. [Indiana is stable while neighbors decline](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#indiana-is-stable-while-neighbors-decline)
2. [Indianapolis Public Schools is shrinking fast](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#indianapolis-public-schools-is-shrinking-fast)
3. [Hamilton County is Indiana's growth engine](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#hamilton-county-is-indianas-growth-engine)
4. [The Hispanic population has tripled](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#the-hispanic-population-has-tripled)
5. [COVID hit Indiana kindergarten hard](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#covid-hit-indiana-kindergarten-hard)
6. [Economic disadvantage varies wildly by geography](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#economic-disadvantage-varies-wildly-by-geography)
7. [Gary Community School Corporation has collapsed](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#gary-community-school-corporation-has-collapsed)
8. [Virtual schools serve 15,000+ students](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#virtual-schools-serve-15000-students)
9. [Evansville is bucking the urban decline](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#evansville-is-bucking-the-urban-decline)
10. [Rural Indiana is consolidating](https://almartin82.github.io/inschooldata/articles/enrollment-trends.html#rural-indiana-is-consolidating)

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/inschooldata")
```

## Quick start

### R

```r
library(inschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_recent <- fetch_enr_multi(2020:2025)

# Fetch all 20 years of data
enr_all <- fetch_enr_multi(2006:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Corporation breakdown
enr_2025 %>%
  filter(is_corporation, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(corporation_name, n_students)

# Demographics by corporation
enr_2025 %>%
  filter(is_corporation, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  group_by(corporation_name, subgroup) %>%
  summarize(n = sum(n_students, na.rm = TRUE))
```

### Python

```python
import pyinschooldata as ind

# Fetch one year
enr_2025 = ind.fetch_enr(2025)

# Fetch multiple years
enr_recent = ind.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])

# State totals
state_total = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
]

# Corporation breakdown
corp_totals = enr_2025[
    (enr_2025['is_corporation'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)[['corporation_name', 'n_students']]
```

## Data availability

| Years | Source | Aggregation Levels | Demographics | Notes |
|-------|--------|-------------------|--------------|-------|
| **2006-2025** | IDOE Data Center | State, Corporation, School | Race, Gender, Special Populations | Multi-year Excel files |

### What's available

- **Levels:** State, corporation (~290), and school (~1,900)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Special populations:** Special Education, ELL, Free Lunch, Reduced Lunch
- **Grade levels:** Pre-K through Grade 12

### ID System

Indiana uses a simple 4-digit ID system:
- **Corporation ID:** 4 digits (e.g., 5385 for Indianapolis Public Schools)
- **School ID:** 4 digits within corporation

Note: Indiana calls its districts "corporations" (school corporations).

## Data source

Indiana Department of Education: [Data Center](https://www.in.gov/doe/it/data-center-and-reports/)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
