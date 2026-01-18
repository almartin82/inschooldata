# Assessment Implementation Status: inschooldata

**Package:** inschooldata
**Status:** NOT IMPLEMENTED
**Last Checked:** 2026-01-12

---

## Current Status

**Assessment functions DO NOT EXIST in this package.**

The inschooldata package currently only provides enrollment data functionality:
- `fetch_enr()` - Fetch enrollment data
- `fetch_enr_multi()` - Fetch multiple years of enrollment data
- `fetch_directory()` - Fetch school directory data

No assessment functions exist:
- ❌ `fetch_assess()` - NOT IMPLEMENTED
- ❌ `get_raw_assessment()` - NOT IMPLEMENTED
- ❌ `process_assessment()` - NOT IMPLEMENTED
- ❌ `tidy_assessment()` - NOT IMPLEMENTED

---

## Research Completed

Assessment data research has been completed and documented in `EXPANSION.md`:

### Available Assessment Data

Indiana has extensive historical assessment data spanning multiple assessment systems:

| Assessment | Years Available | Grades | Data Levels | File Format |
|------------|-----------------|--------|-------------|-------------|
| **ILEARN** | 2019, 2021, 2022, 2023, 2024 | 3-8 + Biology | State, Corp, School | Excel (.xlsx) |
| **ISTEP+** | 2014-2019 | 3-10 | State, Corp, School | Excel (.xlsx) |
| **IREAD-3** | 2016, 2018, 2019, 2021, 2022, 2023 | 3 | State, Corp, School | Excel (.xlsx) |
| **I AM** | 2019, 2021, 2022, 2023 | 3-8, 10 | State, Corp, School | Excel/PDF |
| **ECA** | 2010-2015 | End-of-Course | Corp, School | Excel |

**Gap Years:** No 2020 data (COVID-19 pandemic cancelled most assessments)

### Data Source

Indiana Department of Education: [Data Center & Reports](https://www.in.gov/doe/it/data-center-and-reports/)

### File Pattern

```
https://www.in.gov/doe/files/ILEARN-{YEAR}-{SUBJECT}-{LEVEL}.xlsx
```

---

## Test Status

**No assessment tests exist.**

The test suite (`tests/testthat/`) currently contains:
- `test-directory.R` - School directory tests
- `test-enrollment.R` - Enrollment data tests
- `test-pipeline-live.R` - Live enrollment pipeline tests

**Missing:**
- ❌ `test-assessment-live.R` - ASSESSMENT TESTS NOT WRITTEN (this task)

---

## Blockers

According to `EXPANSION.md`:

**CRITICAL:** The inschooldata package is currently **FAILING R-CMD-check** according to the status dashboard. Before implementing any assessment data features, the existing enrollment code issues must be fixed.

**Status:**
- R-CMD-check: **FAILING**
- Python tests: Passing
- pkgdown: **FAILING**

---

## Next Steps

To implement assessment data for Indiana:

1. **Fix existing enrollment issues** (R-CMD-check failures)
2. **Fix pkgdown build issues**
3. **Implement assessment functions:**
   - `get_raw_assessment()` - Download ILEARN Excel files
   - `process_assessment()` - Parse and clean assessment data
   - `tidy_assessment()` - Convert to tidy format
   - `fetch_assess()` - Public API function
4. **Write comprehensive tests** (30-50+ tests following Alabama/Florida reference)
5. **Add assessment vignette** documenting usage
6. **Update README** with assessment examples

---

## Phase 1 Task Status

**Task:** Write comprehensive assessment tests (30-50+ tests)

**Result:** CANNOT COMPLETE - No assessment implementation exists to test.

**Recommendation:** This package needs assessment implementation BEFORE tests can be written. Tests require:
- `fetch_assess()` function to test
- Actual assessment data to validate
- Processing logic to verify

---

**Assessment implementation is required before test writing can proceed.**
