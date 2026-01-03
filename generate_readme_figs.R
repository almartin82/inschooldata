#!/usr/bin/env Rscript
# Generate README figures for inschooldata

library(ggplot2)
library(dplyr)
library(scales)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")

# Get available years (handles both vector and list return types)
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
message("Fetching data...")
enr <- fetch_enr_multi((max_year - 9):max_year)
key_years <- seq(max(min_year, 2006), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)
enr_long <- fetch_enr_multi(key_years)

# 1. Enrollment stability
message("Creating enrollment stable chart...")
state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment")

p <- ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Indiana Public School Enrollment",
       subtitle = "Stable at ~1.05 million while neighbors decline",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/enrollment-stable.png", p, width = 10, height = 6, dpi = 150)

# 2. IPS decline
message("Creating IPS decline chart...")
ips <- enr_long %>%
  filter(is_corporation, grepl("Indianapolis Public", corporation_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(ips, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Indianapolis Public Schools Decline",
       subtitle = "Lost 15,000 students since 2006",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/ips-decline.png", p, width = 10, height = 6, dpi = 150)

# 3. Hispanic growth
message("Creating Hispanic growth chart...")
hispanic <- enr_long %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic")

p <- ggplot(hispanic, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["hispanic"]) +
  geom_point(size = 3, color = colors["hispanic"]) +
  labs(title = "Hispanic Student Population in Indiana",
       subtitle = "Tripled from 5% to 13% since 2006",
       x = "School Year", y = "Percent of Students") +
  theme_readme()
ggsave("man/figures/hispanic-growth.png", p, width = 10, height = 6, dpi = 150)

# 4. Gary collapse
message("Creating Gary collapse chart...")
gary <- enr_long %>%
  filter(is_corporation, grepl("Gary Community", corporation_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(gary, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Gary Community Schools Collapse",
       subtitle = "From 22,000 to under 5,000 - one of America's steepest declines",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/gary-collapse.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 4 figures in man/figures/")
