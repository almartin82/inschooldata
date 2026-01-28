# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from the
# Indiana Department of Education (IDOE).
#
# Data is available from the IDOE Data Center:
# https://www.in.gov/doe/it/data-center-and-reports/
#
# Assessment systems by year:
# - ILEARN (2019, 2021-2025): Indiana Learning Evaluation and Assessment Readiness Network
#   - Grades 3-8 ELA, Math, Science, Social Studies
#   - Biology and US Government (high school)
# - No 2020 data (COVID-19 testing waiver)
# - ISTEP+ (2014-2018): Indiana Statewide Testing for Educational Progress-Plus
#   - Grades 3-8 and Grade 10 ELA, Math, Science, Social Studies
#
# ==============================================================================


#' Get available assessment years
#'
#' Returns information about available assessment data years.
#'
#' @return List with years, min_year, max_year, and note
#' @export
#' @examples
#' get_available_assessment_years()
get_available_assessment_years <- function() {
  # ILEARN: 2019, 2021-2025 (no 2020 due to COVID)
  # ISTEP+: 2014-2018
  ilearn_years <- c(2019, 2021, 2022, 2023, 2024, 2025)
  istep_years <- c(2014, 2015, 2016, 2017, 2018)

  all_years <- sort(c(ilearn_years, istep_years))

  list(
    years = all_years,
    ilearn_years = ilearn_years,
    istep_years = istep_years,
    min_year = min(all_years),
    max_year = max(all_years),
    note = "2020 assessment data not available due to COVID-19 testing waiver."
  )
}


#' Get assessment URL for a given year and file type
#'
#' Returns the URL for downloading assessment data from IDOE.
#' URL patterns vary by year and data type.
#'
#' @param end_year School year end
#' @param level Level of data: "state", "corporation", or "school"
#' @param file_type Type of file: "main", "disaggregated", or "ethnicity_gender"
#' @return URL string or NULL if not available
#' @keywords internal
get_assessment_url <- function(end_year, level = "corporation", file_type = "main") {

  base_url <- "https://www.in.gov/doe/files/"

  # Normalize inputs
  level <- tolower(level)
  file_type <- tolower(file_type)

  # Validate inputs
  if (!level %in% c("state", "corporation", "school")) {
    stop("level must be one of 'state', 'corporation', 'school'")
  }

  available <- get_available_assessment_years()
  if (!end_year %in% available$years) {
    return(NULL)
  }

  # ILEARN URLs (2019, 2021-2025)
  if (end_year %in% available$ilearn_years) {
    return(get_ilearn_url(end_year, level, file_type, base_url))
  }

  # ISTEP+ URLs (2014-2018)
  if (end_year %in% available$istep_years) {
    return(get_istep_url(end_year, level, file_type, base_url))
  }

  NULL
}


#' Get ILEARN URL for a given year
#'
#' @param end_year School year end
#' @param level Level of data
#' @param file_type Type of file
#' @param base_url Base URL for IDOE files
#' @return URL string or NULL
#' @keywords internal
get_ilearn_url <- function(end_year, level, file_type, base_url) {

  # ILEARN file patterns by year
  # 2025 has different suffixes (with date stamp)
  # 2024 and earlier have simpler patterns

  # Mapping of level to URL level name
  level_map <- list(
    state = "Statewide-Summary",
    corporation = "Corporation",
    school = "School"
  )

  level_name <- level_map[[level]]

  # Build URL based on year
  if (end_year == 2025) {
    # 2025 files have date stamps
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-Statewide-Summary_20250714.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-Corporation_20250714.xlsx"))
      } else {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-School_20250714-2.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-Statewide-Summary-Disaggregated_20250714.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-Corporation-FRL-SE-ELL-Disaggregated_20250714.xlsx"))
      } else {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-School-FRL-SE-ELL-Disaggregated_20250714.xlsx"))
      }
    } else if (file_type == "ethnicity_gender") {
      if (level == "state") {
        return(NULL)  # State doesn't have ethnicity/gender file
      } else if (level == "corporation") {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-Corporation-Gender-and-Ethnicity-Disaggregated_20250714.xlsx"))
      } else {
        return(paste0(base_url, "ILEARN-2025-Grade3-8-Final-School-Gender-and-Ethnicity-Disaggregated_20250714.xlsx"))
      }
    }
  } else if (end_year >= 2021) {
    # 2021-2024 have consistent naming
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-Statewide-Summary.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-Corporation.xlsx"))
      } else {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-School.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-Statewide-Summary-Disaggregated.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-Corporation-FRL-SE-ELL-Disaggregated.xlsx"))
      } else {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-School-FRL-SE-ELL-Disaggregated.xlsx"))
      }
    } else if (file_type == "ethnicity_gender") {
      if (level == "state") {
        return(NULL)
      } else if (level == "corporation") {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-Corporation-Gender-and-Ethnicity-Disaggregated.xlsx"))
      } else {
        return(paste0(base_url, "ILEARN-", end_year, "-Grade3-8-Final-School-Gender-and-Ethnicity-Disaggregated.xlsx"))
      }
    }
  } else if (end_year == 2019) {
    # 2019 uses lowercase naming
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-statewide-summary.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-corporation.xlsx"))
      } else {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-school.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-statewide-summary-disaggregated.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx"))
      } else {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-school-frl-se-ell-disaggregated.xlsx"))
      }
    } else if (file_type == "ethnicity_gender") {
      if (level == "state") {
        return(NULL)
      } else if (level == "corporation") {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-corporation-ethnicity-and-gender-disaggregated.xlsx"))
      } else {
        return(paste0(base_url, "ilearn-2019-grade3-8-final-school-ethnicity-and-gender-disaggregated.xlsx"))
      }
    }
  }

  NULL
}


#' Get ISTEP+ URL for a given year
#'
#' @param end_year School year end
#' @param level Level of data
#' @param file_type Type of file
#' @param base_url Base URL for IDOE files
#' @return URL string or NULL
#' @keywords internal
get_istep_url <- function(end_year, level, file_type, base_url) {

  # ISTEP+ file patterns vary significantly by year
  # 2018, 2017 have more consistent naming
  # 2016, 2015, 2014 have historical prefixes

  if (end_year == 2018) {
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "ISTEP-2018-Grade3-8-Final-Statewide-Summary.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ISTEP-2018-Grade3-8-Final-Corporation.xlsx"))
      } else {
        return(paste0(base_url, "ISTEP-2018-Grade3-8-Final-School.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "ISTEP-2018-Grade3-8-Final-Statewide-Summary-Disaggregated.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "ISTEP-2018-Grade3-8-Final-Corporation-Disaggregated.xlsx"))
      } else {
        return(paste0(base_url, "ISTEP-2018-Grade3-8-Final-School-Disaggregated.xlsx"))
      }
    }
  } else if (end_year == 2017) {
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "istep-2017-grade3-8-final-statewide-summary.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "istep-2017-grade3-8-final-corporation.xlsx"))
      } else {
        return(paste0(base_url, "istep-2017-grade3-8-final-school.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "istep-2017-grade3-8-final-statewide-summary-disaggregated.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "istep-2017-grade3-8-final-corporation-disaggregated.xlsx"))
      } else {
        return(paste0(base_url, "istep-2017-grade3-8-final-school-disaggregated.xlsx"))
      }
    }
  } else if (end_year == 2016) {
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "press2016istepstatewide-grades-03-08.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "press2016istepcorporation-grades-03-08.xlsx"))
      } else {
        return(paste0(base_url, "press2016istepschoolpublic-grades-03-08.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "press2016istepstatedisagg-grades-03-08.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "press2016istepcorpdisagg-grades-03-08.xlsx"))
      } else {
        return(paste0(base_url, "press2016istepschooldisagg-grades-03-08.xlsx"))
      }
    }
  } else if (end_year == 2015) {
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "press_2015_istep_statewide.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "press_2015_istep_corporation.xlsx"))
      } else {
        return(paste0(base_url, "press_2015_istep_school_public.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "2015_istep_state_disagg.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "2015_istep_corp_disagg.xlsx"))
      } else {
        return(paste0(base_url, "2015_istep_school_disagg.xlsx"))
      }
    }
  } else if (end_year == 2014) {
    if (file_type == "main") {
      if (level == "state") {
        return(paste0(base_url, "historical2014istepstatewide.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "historical2014istepcorporation.xlsx"))
      } else {
        return(paste0(base_url, "historical2014istepschoolpublic_1.xlsx"))
      }
    } else if (file_type == "disaggregated") {
      if (level == "state") {
        return(paste0(base_url, "disagg2014istepstatewide.xlsx"))
      } else if (level == "corporation") {
        return(paste0(base_url, "disagg2014istepcorp.xlsx"))
      } else {
        return(paste0(base_url, "disagg2014istepsch_1.xlsx"))
      }
    }
  }

  NULL
}


#' Download raw assessment data from IDOE
#'
#' Downloads assessment data from IDOE for the specified year.
#' Returns raw data from the Excel files without processing.
#'
#' @param end_year School year end (2014-2019, 2021-2025; no 2020 due to COVID)
#' @param level Level of data: "all" (default), "state", "corporation", or "school"
#' @return List with data frames for each level requested
#' @keywords internal
get_raw_assessment <- function(end_year, level = "all") {

  # Validate year
  available <- get_available_assessment_years()

  if (end_year == 2020) {
    stop(available$note)
  }

  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "),
      "\nGot: ", end_year
    ))
  }

  message(paste("Downloading IDOE assessment data for", end_year, "..."))

  # Determine which levels to download
  level <- tolower(level)
  if (level == "all") {
    levels_to_download <- c("state", "corporation", "school")
  } else if (level %in% c("state", "corporation", "school")) {
    levels_to_download <- level
  } else {
    stop("level must be one of 'all', 'state', 'corporation', 'school'")
  }

  # Download each level
  result <- list()

  for (lv in levels_to_download) {
    message(paste("  Downloading", lv, "level data..."))
    df <- download_assessment_file(end_year, lv)
    result[[lv]] <- df
  }

  result
}


#' Download a single assessment file
#'
#' Downloads and parses an assessment Excel file.
#'
#' @param end_year School year end
#' @param level Level: "state", "corporation", or "school"
#' @return Data frame with assessment data
#' @keywords internal
download_assessment_file <- function(end_year, level) {

  url <- get_assessment_url(end_year, level, "main")

  if (is.null(url)) {
    message(paste("  No URL defined for", end_year, level))
    return(create_empty_assessment_raw())
  }

  # Create temp file
  temp_file <- tempfile(
    pattern = paste0("in_assessment_", level, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  result <- tryCatch({
    # Download with httr
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300),
      httr::config(
        ssl_verifypeer = 0L,
        ssl_verifyhost = 0L,
        followlocation = TRUE,
        connecttimeout = 60
      )
    )

    if (httr::http_error(response)) {
      message(paste("  HTTP error for", level, ":", httr::status_code(response)))
      unlink(temp_file)
      return(create_empty_assessment_raw())
    }

    # Check file size
    file_info <- file.info(temp_file)
    if (is.na(file_info$size) || file_info$size < 1000) {
      message(paste("  Downloaded file too small for", level))
      unlink(temp_file)
      return(create_empty_assessment_raw())
    }

    # Read and parse the Excel file
    df <- read_assessment_excel(temp_file, end_year, level)

    unlink(temp_file)
    df

  }, error = function(e) {
    message(paste("  Download error for", level, ":", e$message))
    unlink(temp_file)
    create_empty_assessment_raw()
  })

  result
}


#' Read assessment data from Excel file
#'
#' Parses IDOE assessment Excel files. These files have multi-row headers
#' and multiple sheets for different subjects.
#'
#' @param filepath Path to Excel file
#' @param end_year School year end
#' @param level Data level
#' @return Data frame with assessment data
#' @keywords internal
read_assessment_excel <- function(filepath, end_year, level) {

  # Get available sheets
  sheets <- readxl::excel_sheets(filepath)
  message(paste("    Available sheets:", paste(sheets, collapse = ", ")))

  # Read each subject sheet and combine
  all_data <- list()

  # Target sheets for assessment data
  # Skip "ELA & Math" as it's a combined metric that duplicates ELA/Math data
  target_sheets <- c("ELA", "Math", "Science", "Social Studies")

  for (sheet_name in sheets) {
    # Skip non-data sheets
    if (!sheet_name %in% target_sheets) {
      next
    }

    message(paste("    Reading sheet:", sheet_name))

    df <- tryCatch({
      read_assessment_sheet(filepath, sheet_name, end_year, level)
    }, error = function(e) {
      message(paste("    Error reading sheet", sheet_name, ":", e$message))
      NULL
    })

    if (!is.null(df) && nrow(df) > 0) {
      df$subject <- clean_subject_name(sheet_name)
      all_data[[sheet_name]] <- df
    }
  }

  if (length(all_data) == 0) {
    return(create_empty_assessment_raw())
  }

  # Combine all sheets
  dplyr::bind_rows(all_data)
}


#' Read a single assessment sheet
#'
#' Parses a single sheet from IDOE assessment Excel file.
#' Handles the complex multi-row header structure with merged cells.
#'
#' ILEARN files have this structure:
#' - Row 1-3: Notes
#' - Row 4: Grade labels (Grade 3, Grade 4, ..., Corporation Total)
#' - Row 5: Column headers (Below, Approaching, At, Above, Total Proficient, Total Tested, %)
#' - Row 6+: Data
#'
#' Columns per grade: Below, Approaching, At, Above, Total Proficient, Total Tested, Proficient %
#'
#' @param filepath Path to Excel file
#' @param sheet_name Name of sheet to read
#' @param end_year School year end
#' @param level Data level
#' @return Data frame with assessment data
#' @keywords internal
read_assessment_sheet <- function(filepath, sheet_name, end_year, level) {

  # Read data skipping header rows
  df <- suppressMessages(
    readxl::read_excel(filepath, sheet = sheet_name, skip = 4, col_types = "text")
  )

  if (nrow(df) == 0) {
    return(create_empty_assessment_raw())
  }

  # Get the first row to check if it's actually a header row
  first_row <- as.character(df[1, ])
  is_header_row <- any(grepl("Corp ID|School ID|Below|Approaching|At|Above|Proficient", first_row, ignore.case = TRUE))

  if (is_header_row) {
    # First row is the column header row - skip it
    df <- df[-1, , drop = FALSE]
  }

  # Remove completely empty rows
  df <- df[rowSums(!is.na(df) & df != "") > 0, ]

  if (nrow(df) == 0) {
    return(create_empty_assessment_raw())
  }

  # Get original column names
  orig_names <- names(df)

  # Build standardized column names
  # Pattern: columns 1-2 are ID/Name, then groups of 7 per grade
  # Grade order: 3, 4, 5, 6, 7, 8, Total
  grades <- c("grade3", "grade4", "grade5", "grade6", "grade7", "grade8", "total")
  metrics <- c("below", "approaching", "at", "above", "proficient", "tested", "pct")

  subject <- clean_subject_name(sheet_name)
  subject_prefix <- tolower(gsub(" ", "_", subject))

  new_names <- character(length(orig_names))

  # First two columns are ID and Name
  if (level == "school") {
    new_names[1] <- "corp_id"
    new_names[2] <- "corp_name"
    if (length(new_names) > 2) {
      new_names[3] <- "school_id"
      new_names[4] <- "school_name"
      start_col <- 5
    } else {
      start_col <- 3
    }
  } else {
    new_names[1] <- "corp_id"
    new_names[2] <- "corp_name"
    start_col <- 3
  }

  # Assign grade/metric names to remaining columns
  col_idx <- start_col
  for (grade in grades) {
    for (metric in metrics) {
      if (col_idx <= length(new_names)) {
        new_names[col_idx] <- paste0(grade, "_", subject_prefix, "_", metric)
        col_idx <- col_idx + 1
      }
    }
  }

  # Fill any remaining columns with generic names
  while (col_idx <= length(new_names)) {
    new_names[col_idx] <- paste0("col_", col_idx)
    col_idx <- col_idx + 1
  }

  names(df) <- new_names

  # Add year and level
  df$end_year <- as.integer(end_year)
  df$level <- level

  df
}


#' Build column names from grade and header rows
#'
#' @param grade_row Vector with grade labels
#' @param header_row Vector with column headers
#' @param sheet_name Subject sheet name
#' @return Vector of column names
#' @keywords internal
build_assessment_column_names <- function(grade_row, header_row, sheet_name) {

  n <- length(header_row)
  new_names <- character(n)
  current_grade <- "total"

  for (i in 1:n) {
    g <- grade_row[i]
    h <- header_row[i]

    # Check if this column has a grade label
    if (!is.na(g) && g != "") {
      grade_text <- gsub("\r\n", " ", g)
      grade_text <- trimws(grade_text)

      if (grepl("^Grade\\s*\\d", grade_text, ignore.case = TRUE)) {
        current_grade <- tolower(gsub("\\s+", "", grade_text))  # e.g., "grade3"
      } else if (grepl("Total|Corporation|School|State", grade_text, ignore.case = TRUE)) {
        current_grade <- "total"
      } else {
        current_grade <- tolower(gsub("\\s+", "_", grade_text))
      }
    }

    # Build column name
    if (!is.na(h) && h != "") {
      header_text <- gsub("\r\n", " ", h)
      header_text <- clean_column_name(header_text)

      # Special handling for ID and name columns
      if (grepl("corp_id|school_id|corp_name|school_name", header_text, ignore.case = TRUE)) {
        new_names[i] <- header_text
      } else {
        new_names[i] <- paste0(current_grade, "_", header_text)
      }
    } else {
      new_names[i] <- paste0("col_", i)
    }
  }

  # Make names unique
  make.unique(new_names, sep = "_")
}


#' Clean column name
#'
#' @param name Column name to clean
#' @return Cleaned column name
#' @keywords internal
clean_column_name <- function(name) {
  name <- gsub("\r\n", " ", name)
  name <- tolower(name)
  name <- gsub("[^a-z0-9_]", "_", name)
  name <- gsub("_+", "_", name)
  name <- gsub("^_|_$", "", name)
  name
}


#' Clean subject name
#'
#' @param sheet_name Sheet name to clean
#' @return Standardized subject name
#' @keywords internal
clean_subject_name <- function(sheet_name) {
  sheet_name <- tolower(sheet_name)

  if (grepl("ela|english", sheet_name)) {
    return("ELA")
  } else if (grepl("math", sheet_name)) {
    return("Math")
  } else if (grepl("science", sheet_name)) {
    return("Science")
  } else if (grepl("social", sheet_name)) {
    return("Social Studies")
  } else if (grepl("ela.*math|combined", sheet_name)) {
    return("ELA & Math")
  }

  sheet_name
}


#' Create empty assessment raw data frame
#'
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_assessment_raw <- function() {
  data.frame(
    corp_id = character(0),
    corp_name = character(0),
    subject = character(0),
    end_year = integer(0),
    level = character(0),
    stringsAsFactors = FALSE
  )
}
