# inschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/inschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/inschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/inschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/inschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/inschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/inschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/inschooldata/)** | **[Getting Started](https://almartin82.github.io/inschooldata/articles/quickstart.html)**

Fetch and analyze Indiana school enrollment data from the Indiana Department of Education (IDOE) in R or Python.

## What can you find with inschooldata?

**20 years of enrollment data (2006-2025).** 1.05 million students today. Over 290 corporations. Here are ten stories hiding in the numbers:

---

### 1. Indiana is stable while neighbors decline

While Illinois and Ohio lose students, Indiana has held steady at around 1.05 million for a decade. The Hoosier State is neither booming nor busting.

```r
library(inschooldata)
library(dplyr)

enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

![Indiana enrollment stability](man/figures/enrollment-stable.png)

---

### 2. Indianapolis Public Schools is shrinking fast

IPS lost 15,000 students since 2006, dropping from 35,000 to under 25,000. Charter schools and suburban flight are reshaping Indy education.

```r
enr <- fetch_enr_multi(2006:2025)

enr %>%
  filter(grepl("Indianapolis Public Schools", corporation_name, ignore.case = TRUE),
         is_corporation, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

![IPS decline](man/figures/ips-decline.png)

---

### 3. Hamilton County is Indiana's growth engine

Carmel, Fishers, Westfield, and Noblesville suburbs are booming. Hamilton County corporations added 20,000 students since 2010.

```r
enr_2025 <- fetch_enr(2025)

hamilton <- c("Carmel Clay Schools", "Hamilton Southeastern Schools",
              "Noblesville Schools", "Westfield-Washington Schools")

enr %>%
  filter(corporation_name %in% hamilton, is_corporation,
         grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  group_by(end_year) %>%
  summarize(total = sum(n_students, na.rm = TRUE))
```

---

### 4. The Hispanic population has tripled

Hispanic students went from 5% to 13% of enrollment since 2006. Northwest Indiana and Indianapolis drive this growth.

```r
enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") %>%
  select(end_year, n_students, pct)
```

![Hispanic growth](man/figures/hispanic-growth.png)

---

### 5. COVID hit Indiana kindergarten hard

Indiana lost 8,000 kindergartners between 2020 and 2021. Recovery has been slow.

```r
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "K",
         end_year %in% 2019:2025) %>%
  select(end_year, n_students)
```

---

### 6. One in four students qualifies for free lunch

Over 250,000 Indiana students receive free lunch. Economic disadvantage varies wildly by geography.

```r
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "free_lunch") %>%
  select(n_students, pct)
```

Gary, East Chicago, and Indianapolis have 80%+ rates. Carmel and Zionsville are under 5%.

---

### 7. Gary Community School Corporation has collapsed

Gary lost 20,000 students since 2006, dropping from 22,000 to under 5,000. This is one of the most dramatic declines in America.

```r
enr %>%
  filter(grepl("Gary Community School", corporation_name, ignore.case = TRUE),
         is_corporation, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

![Gary collapse](man/figures/gary-collapse.png)

---

### 8. Virtual schools serve 15,000+ students

Indiana's virtual charter schools have grown dramatically, especially after COVID. Indiana Virtual School and Indiana Connections Academy are among the largest.

```r
enr_2025 %>%
  filter(grepl("Virtual|Online|Connections|Digital", corporation_name, ignore.case = TRUE),
         grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(corporation_name, n_students) %>%
  arrange(desc(n_students))
```

---

### 9. Evansville is bucking the urban decline

While most urban districts shrink, Evansville Vanderburgh School Corp has remained stable at around 22,000 students. Southwest Indiana is different.

```r
enr %>%
  filter(grepl("Evansville Vanderburgh", corporation_name, ignore.case = TRUE),
         is_corporation, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

---

### 10. Rural Indiana is consolidating

Indiana had 320 corporations in 2006. Today it has under 300. Small rural districts continue to merge.

```r
fetch_enr_multi(c(2006, 2015, 2025)) %>%
  filter(is_corporation, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_corporations = n())
```

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
