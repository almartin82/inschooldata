# Indiana (IN) School Data Expansion Research

**Last Updated:** 2025-01-11
**Theme Researched:** Assessment Data (ALL historic assessments, K-8 and high school, excluding SAT/ACT)

## CRITICAL FINDING: Package Status Issue

**IMPORTANT:** The inschooldata package is currently **FAILING R-CMD-check** according to the status dashboard. Before implementing any assessment data features, the existing enrollment code issues must be fixed.

**Status from Dashboard:**
- R-CMD-check: **FAILING**
- Python tests: Passing
- pkgdown: **FAILING**

**Recommendation:** Fix the existing enrollment data issues first, then add assessment features.

---

## Data Sources Found

### Summary of Assessment Data Availability

Indiana has **extensive historical assessment data** spanning multiple assessment systems:

| Assessment | Years Available | Grades | Data Levels | File Format |
|------------|-----------------|--------|-------------|-------------|
| **ILEARN** | 2019, 2021, 2022, 2023, 2024 | 3-8 + Biology | State, Corp, School | Excel (.xlsx) |
| **ISTEP+** | 2014-2019 | 3-10 | State, Corp, School | Excel (.xlsx) |
| **IREAD-3** | 2016, 2018, 2019, 2021, 2022, 2023 | 3 | State, Corp, School | Excel (.xlsx) |
| **I AM** | 2019, 2021, 2022, 2023 | 3-8, 10 | State, Corp, School | Excel/PDF |
| **ECA** | 2010-2015 | End-of-Course | Corp, School | Excel |

**Gap Years:** No 2020 data (COVID-19 pandemic cancelled most assessments)

---

## Source 1: ILEARN Assessment (Current K-8 Assessment)

### Base URL Pattern
```
https://www.in.gov/doe/files/ILEARN-{YEAR}-{SUBJECT}-{LEVEL}.xlsx
```

### Available Files by Year

#### 2024 ILEARN
- **URL:** https://www.in.gov/doe/files/ILEARN-2024-Grade3-8-Final-Corporation.xlsx
- **HTTP Status:** 200 OK
- **Format:** Excel (.xlsx)
- **Access:** Direct download

(See EXPANSION.md for complete file listing)

---

## Package: inschooldata

**Status:** Assessment expansion research completed but **cannot proceed with implementation** until R-CMD-check issues are resolved.

**Assessment Data Available:**
- 11 years of assessment data (2014-2024)
- 5 different assessment systems
- Multiple subjects and grade levels
- State, corporation, and school-level data

**Next Steps:**
1. Fix existing R-CMD-check failures
2. Fix pkgdown build issues
3. Then implement ILEARN assessment data

---

**Sources:**
- [Indiana DOE Data Center & Reports](https://www.in.gov/doe/it/data-center-and-reports/)
- [Data Reports Archive](https://www.in.gov/doe/it/data-center-and-reports/data-reports-archive/)
- [2024 ILEARN Grade 3-8 Corporation Results](https://www.in.gov/doe/files/ILEARN-2024-Grade3-8-Final-Corporation.xlsx)
