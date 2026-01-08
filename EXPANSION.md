# Indiana School Data Expansion Research

**Last Updated:** 2026-01-04 **Theme Researched:** Graduation Rates

## Current Package Capabilities

The `inschooldata` package currently supports: - **Enrollment data**
(2006-2025) - Data levels: State, Corporation (district), School -
Subgroups: Race/ethnicity, gender, FRPL, Special Ed, ELL - Grade-level
breakdowns (PK-12)

No graduation rate functionality currently exists in the package.

------------------------------------------------------------------------

## Data Sources Found

### Source 1: State Graduation Rate Data (Annual Files)

- **Base URL:** `https://www.in.gov/doe/files/`
- **Format:** Excel (.xlsx)
- **Access:** Direct download, no authentication required
- **Update Frequency:** Annual (typically released in December/January)

#### Available Years and URLs

| Year | URL                                                                     | HTTP Status | File Size |
|------|-------------------------------------------------------------------------|-------------|-----------|
| 2024 | `2024-Indiana-State-Graduation-Rate-.xlsx`                              | 200         | 639 KB    |
| 2023 | `2023-indiana-state-graduation-rate.xlsx`                               | 200         | 628 KB    |
| 2022 | `https://media.doe.in.gov/news/2022-indiana-state-graduation-rate.xlsx` | 200         | 545 KB    |
| 2021 | `2021-Indiana-State-Graduation-Rate.xlsx`                               | 200         | 335 KB    |
| 2020 | `2020-state-grad-rate-data-20210115.xlsx`                               | 200         | 277 KB    |
| 2019 | `2019-state-grad-rate-data-20191231.xlsx`                               | 200         | 337 KB    |
| 2018 | `2018-state-grad-rate-data20190204.xlsx`                                | 200         | 334 KB    |
| 2017 | `2017-graduation-rate-04-17-2018-publication.xlsx`                      | 200         | 321 KB    |
| 2016 | `2016-graduation-rate-02-09-2017.xlsx`                                  | 200         | 380 KB    |
| 2015 | `2015graduationrate.xlsx`                                               | 200         | 415 KB    |
| 2014 | `2014gradratesdisaggnonwaiverv2.xlsx`                                   | 200         | 384 KB    |

**Note:** 2022 file is on `media.doe.in.gov` subdomain, all others on
`www.in.gov/doe/files/`

### Source 2: Federal Graduation Rate Data (Annual Files)

- **Format:** Excel (.xlsx)
- **Access:** Direct download
- **Purpose:** Uses federal ESSA methodology (slightly different from
  state rates)

| Year | URL                                                                       | HTTP Status |
|------|---------------------------------------------------------------------------|-------------|
| 2024 | `2024-Indiana-Federal-Graduation-Rate-.xlsx`                              | 200         |
| 2023 | `2023-indiana-federal-graduation-rate.xlsx`                               | 200         |
| 2022 | `https://media.doe.in.gov/news/2022-indiana-federal-graduation-rate.xlsx` | 200         |
| 2021 | `2021-Indiana-Federal-Graduation-Rate.xlsx`                               | 200         |
| 2020 | `2020-federal-grad-rate-data-20210115.xlsx`                               | 200         |
| 2019 | `2019-federal-grad-rate-data-20191231.xlsx`                               | 200         |
| 2018 | `2018-federal-grad-rate-data-20190204.xlsx`                               | 200         |

### Source 3: 5-Year Graduation Rate Data

- Limited availability (2019, 2020 confirmed)
- `2019-5-year-grad-rate.xlsx`

### Source 4: Non-Waiver Graduation Rate Data

- Included as separate sheets within State Graduation Rate files
- Tracks students who graduate without diploma waivers

------------------------------------------------------------------------

## Schema Analysis

### Sheet Structure (2024 State Graduation Rate File)

| Sheet Name                        | Description                            |
|-----------------------------------|----------------------------------------|
| `state_disagg`                    | State-level rates by demographic group |
| `State_Nonwaiver`                 | State-level non-waiver rates           |
| `Corp Disagg`                     | Corporation (district) level rates     |
| `Corp NonWaiver Disagg`           | Corporation non-waiver rates           |
| `School Pub Disagg`               | Public school rates                    |
| `School Pub NonWaiver Disagg`     | Public school non-waiver rates         |
| `School Non-Pub Disagg`           | Non-public school rates                |
| `School Non-Pub NonWaiver Disagg` | Non-public school non-waiver rates     |
| `Legend`                          | Suppression notation                   |

### Column Structure (Corporation/School Sheets)

The files use **merged Excel headers** with subgroup names spanning 3
columns: - Column 1: `Cohort Count` - Column 2: `Graduates` - Column 3:
`Graduation Rate`

**Subgroups Available:** - **Race/Ethnicity:** Asian, Black, Hispanic,
Multiracial, Native Hawaiian/Pacific Islander, White - **Economic:**
Paid Meals, Free/Reduced Price Meals - **Program:** General Education,
Special Education - **Language:** Non-English Language Learner, English
Language Learner - **Gender:** Female, Male - **Total:** Overall
graduation rate

**ID Columns:** - Corporation: `IDOE CORP ID`, `CORPORATION NAME` -
School: `IDOE CORP ID`, `CORPORATION NAME`, `IDOE SCHOOL ID`,
`SCHOOL NAME`

### Column Names by Year

| Year | ID Column      | Name Column        | Notes                           |
|------|----------------|--------------------|---------------------------------|
| 2024 | `IDOE CORP ID` | `CORPORATION NAME` | Merged headers, skip=1 required |
| 2020 | `Corp Id`      | `CORPORATION NAME` | Merged headers                  |
| 2015 | `Corp ID`      | `Corporation Name` | Clean headers, no skip needed   |

**Schema Changes Noted:** - 2015: Simple column structure with clear
headers - 2017+: Introduced merged Excel cells for demographic subgroup
headers - 2020+: Consistent 3-column pattern per subgroup
(Count/Graduates/Rate)

### Suppressed Values

- `***` = Suppressed due to small n-size (\<10)
- Values marked as suppressed should be converted to `NA`

------------------------------------------------------------------------

## State vs Federal Graduation Rates

| Metric             | State Rate       | Federal Rate                  |
|--------------------|------------------|-------------------------------|
| 2024 Overall       | 90.23%           | 88.67%                        |
| Methodology        | Indiana-specific | ESSA-compliant                |
| Cohort Definition  | State criteria   | Federal criteria              |
| “Unknown” students | Excluded         | Included as separate category |

------------------------------------------------------------------------

## ID System

- **Corporation ID:** 4-digit code (e.g., `0015`, `5385`)
- **School ID:** 4-digit code within corporation
- **Leading zeros:** Must be preserved (character type)
- **Compatibility:** IDs match those used in enrollment data

------------------------------------------------------------------------

## Time Series Heuristics

Based on 2024 data and historical trends:

| Metric                     | Expected Range          | Red Flag If           |
|----------------------------|-------------------------|-----------------------|
| State graduation rate      | 85% - 95%               | \<80% or \>98%        |
| State total cohort         | 75,000 - 90,000         | \<60,000 or \>100,000 |
| YoY rate change            | +/- 3 percentage points | \>5 pp change         |
| Corporation count          | ~290 corporations       | Sudden drop/spike     |
| Black graduation rate      | 78% - 88%               | \<70%                 |
| Hispanic graduation rate   | 83% - 90%               | \<75%                 |
| Special Ed graduation rate | 70% - 88%               | \<60%                 |
| Charter school rate        | 55% - 65%               | Major deviation       |

### Major Entities to Verify (2024 values)

| Entity                 | Type        | 2024 Cohort | 2024 Rate |
|------------------------|-------------|-------------|-----------|
| State Total            | State       | 84,142      | 90.23%    |
| Indianapolis PS (5385) | Corporation | ~2,500      | Verify    |
| Fort Wayne CS          | Corporation | ~1,800      | Verify    |

------------------------------------------------------------------------

## Known Data Issues

1.  **Merged Excel Headers:** Files from 2017+ have merged cells causing
    column name parsing issues. Must use `skip=1` and manually map
    columns.

2.  **American Indian Suppression:** Due to small n-size, American
    Indian is suppressed at corp/school level but appears in state
    totals.

3.  **Unknown Students:** Federal files include “Unknown” category
    (students whose status is undetermined). State files may exclude
    these.

4.  **URL Pattern Inconsistency:** File naming varies by year (dashes vs
    underscores, date suffixes).

5.  **Domain Migration (2022):** 2022 files hosted on `media.doe.in.gov`
    instead of `www.in.gov/doe/files/`

------------------------------------------------------------------------

## Recommended Implementation

### Priority: HIGH

### Complexity: MEDIUM

### Estimated Files to Create/Modify: 4-5

### Implementation Steps:

1.  **Create URL mapping function** (`get_grad_rate_urls()`)
    - Map years to correct URLs
    - Handle domain differences (2022)
    - Support both state and federal rate files
2.  **Create raw data download function** (`get_raw_grad()`)
    - Download Excel file for specified year
    - Cache raw files similar to enrollment
    - Support rate_type parameter (“state” or “federal”)
3.  **Create parsing function** (`process_grad()`)
    - Handle merged header cells with skip=1
    - Map subgroup columns dynamically
    - Extract cohort_count, graduates, graduation_rate
    - Handle suppressed values (`***` -\> NA)
4.  **Create tidy function** (`tidy_grad()`)
    - Transform to long format
    - Columns: end_year, type, corp_id, school_id, names, subgroup,
      cohort_count, graduates, graduation_rate
5.  **Create main fetch function** (`fetch_grad()`)
    - Similar API to
      [`fetch_enr()`](https://almartin82.github.io/inschooldata/reference/fetch_enr.md)
    - Parameters: end_year, tidy=TRUE, use_cache=TRUE, rate_type=“state”

### API Design:

``` r
# Get 2024 state graduation rates
grad_2024 <- fetch_grad(2024)

# Get federal rates
grad_federal <- fetch_grad(2024, rate_type = "federal")

# Get multiple years
grad_multi <- fetch_grad_multi(2020:2024)

# Filter to specific corporation
ips <- grad_2024 |>
  dplyr::filter(corporation_id == "5385")
```

------------------------------------------------------------------------

## Test Requirements

### Raw Data Fidelity Tests Needed:

| Year | Entity | Subgroup   | Expected Value | Source             |
|------|--------|------------|----------------|--------------------|
| 2024 | State  | Total      | 90.23%         | State disagg sheet |
| 2024 | State  | Black      | 83.88%         | State disagg sheet |
| 2024 | State  | Special Ed | 85.30%         | State disagg sheet |
| 2024 | State  | Charter    | 58.6%          | State disagg sheet |
| 2020 | State  | Total      | ~88%           | 2020 file          |
| 2015 | State  | Total      | 88.89%         | 2015 file          |

### Pipeline Tests:

1.  **URL Availability:** All 11 state + 7 federal URLs return HTTP 200
2.  **File Download:** Files are valid Excel (not HTML error pages)
3.  **File Parsing:** readxl can read all sheets
4.  **Column Structure:** Expected subgroups present
5.  **Year Coverage:** 2014-2024 all return data
6.  **Aggregation:** State total \> 0 for each year
7.  **Data Quality:** No Inf/NaN, rates in 0-1 range
8.  **Fidelity:** Specific values match raw Excel

### Data Quality Checks:

``` r
# Graduation rates must be 0-1 (or 0-100 if percentage)
expect_true(all(data$graduation_rate >= 0 & data$graduation_rate <= 1))

# Graduates cannot exceed cohort
expect_true(all(data$graduates <= data$cohort_count))

# State total cohort should be 70k-100k
state_cohort <- data |> filter(is_state, subgroup == "total") |> pull(cohort_count)
expect_true(state_cohort > 70000 & state_cohort < 100000)
```

------------------------------------------------------------------------

## Alternative Data Sources Considered

1.  **Indiana Data Hub:**
    <https://hub.mph.in.gov/dataset/high-school-graduation-rate>
    - Appears to aggregate DOE data
    - Less granular than direct DOE files
    - Would add API dependency
2.  **Accountability Dashboard:**
    <https://www.in.gov/doe/it/accountability-dashboard/graduation-rate/>
    - Interactive visualization
    - No direct download API found
    - Data appears to come from same Excel files

**Recommendation:** Use direct DOE Excel files as primary source.
