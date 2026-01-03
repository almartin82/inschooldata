## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---

# inschooldata - Indiana School Enrollment Data

## Data Source

Indiana DOE Data Center: https://www.in.gov/doe/it/data-center-and-reports/

### Available Files (2006-2025)

| File | URL Pattern |
|------|-------------|
| Corporation Enrollment by Grade | `corporation-enrollment-grade-2006-25.xlsx` |
| Corporation Enrollment by Ethnicity/FRL | `corporation-enrollment-ethnicity-free-reduced-price-meal-status-2006-25.xlsx` |
| Corporation Enrollment by SPED/ELL | `corporation-enrollment-ell-special-education-2006-25-updated.xlsx` |
| Corporation Enrollment by Gender | `corporation-enrollment-grade-gender-2006-25.xlsx` |
| School Enrollment by Grade | `school-enrollment-grade-2006-25.xlsx` |
| School Enrollment by Ethnicity/FRL | `school-enrollment-ethnicity-and-free-reduced-price-meal-status-2006-25-final.xlsx` |
| School Enrollment by SPED/ELL | `school-enrollment-ell-special-education-2006-25-updated.xlsx` |
| School Enrollment by Gender | `school-enrollment-grade-gender-2006-25.xlsx` |

Base URL: `https://www.in.gov/doe/files/`

### Known Issues (Fixed)

**Gender File Merged Excel Headers**: The gender files have merged cells in the Excel header causing `readxl` to misparse column names as `_1`, `_2` instead of `CORP_ID`, `CORP_NAME`. The package handles this by:
1. Detecting when first column is `_1` instead of `CORP_ID`
2. Renaming columns appropriately
3. Removing the sub-header row containing "Female"/"Male" labels

Without this fix, joins fall back to YEAR-only matching, causing a cartesian product (418 × 419 = 175,142 rows instead of 418).

---

# Claude Code Instructions

## Git Commits and PRs
- NEVER reference Claude, Claude Code, or AI assistance in commit messages
- NEVER reference Claude, Claude Code, or AI assistance in PR descriptions
- NEVER add Co-Authored-By lines mentioning Claude or Anthropic
- Keep commit messages focused on what changed, not how it was written

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pyinschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pyinschooldata && pytest tests/test_pyinschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pyinschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.

