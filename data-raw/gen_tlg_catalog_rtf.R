# =============================================================================
# data-raw/gen_tlg_catalog_rtf.R
#
# Regenerate the example RTF files used in
# vignettes/articles/tlg-catalog.Rmd to a KNOWN folder, so you can open them
# in Word / LibreOffice and take screenshots for the article.
#
# Run from the repo root (with the dev package installed):
#     Rscript data-raw/gen_tlg_catalog_rtf.R
#
# Output: ./output/tlg/*.rtf  (the output/ directory is git-ignored).
# =============================================================================

library(rtfreporter)
library(rtables)
library(tern)
library(gtsummary)
library(tfrmt)
library(dplyr)
library(tidyr)

out_dir <- file.path("output", "tlg")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

adsl <- random.cdisc.data::cadsl
adae <- random.cdisc.data::cadae

make_header <- function(table_no, title2) {
  rtf_header(rows = list(
    c(l = "Hoge Co. Limited",   r = "CONFIDENTIAL"),
    c(l = "Protocol: RTF-101",  r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}"),
    c(c = paste0("Table ", table_no, "  ", title2))
  ))
}
make_footer <- function(source_object, built_with) {
  rtf_footer(c(l = paste0(
    "Source object: ", source_object, " (", built_with, "), ",
    "converted to RTF by rtfreporter.  ",
    "CDISC pilot data (random.cdisc.data); layout after the pharmaverse ",
    "TLG examples.")))
}
demog_title <- list(c("Demographic and Baseline Characteristics",
                      "Safety Analysis Set"))

.write <- function(doc, file) {
  path <- file.path(out_dir, file)
  generate_rtfreport(doc, path, overwrite = TRUE)
  message("wrote ", path)
}

# ---- 1a. Demographics (tern + rtables) -------------------------------------
dm_tern <- build_table(
  basic_table(show_colcounts = TRUE) |>
    split_cols_by("ARM") |>
    add_overall_col("All Patients") |>
    analyze_vars(vars = c("AGE", "SEX", "RACE"),
                 .stats = c("mean_sd", "median", "range", "count_fraction")) |>
    append_topleft("Characteristic"),
  adsl)
out_tern <- file.path(out_dir, "tlg-demog-tern.rtf")
generate_rtfreport(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("14.1.1a", "Demographics (tern)"),
      footer = make_footer("rtables TableTree", "tern + rtables"))) |>
    rtf_tables(as_rtftables(dm_tern, blank_rows = "between_groups"),
               titles = demog_title),
  out_tern, overwrite = TRUE)
message("wrote ", out_tern)

# ---- 1b. Demographics (gtsummary) ------------------------------------------
dm_gts <- adsl |>
  select(ARM, AGE, SEX, RACE) |>
  tbl_summary(by = ARM,
              label = list(AGE = "Age (years)", SEX = "Sex", RACE = "Race"),
              statistic = list(all_continuous() ~ "{mean} ({sd})")) |>
  modify_header(label = "Characteristic") |>
  add_overall()
out_gts <- file.path(out_dir, "tlg-demog-gtsummary.rtf")
generate_rtfreport(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("14.1.1b", "Demographics (gtsummary)"),
      footer = make_footer("gt_tbl", "gtsummary::tbl_summary()"))) |>
    rtf_tables(as_rtftables(dm_gts, align_count_pct = TRUE,
                            blank_rows = "between_groups"),
               titles = demog_title),
  out_gts, overwrite = TRUE)
message("wrote ", out_gts)

# ---- 1c. Demographics (tfrmt) ----------------------------------------------
age_long <- adsl |>
  group_by(ARM) |>
  summarise(Mean = mean(AGE), SD = sd(AGE), .groups = "drop") |>
  pivot_longer(c(Mean, SD), names_to = "label", values_to = "value") |>
  mutate(group = "Age (years)", param = tolower(label))
cat_long <- function(var, group_lbl) {
  adsl |>
    count(ARM, !!sym(var)) |>
    group_by(ARM) |>
    mutate(pct = n / sum(n) * 100) |>
    ungroup() |>
    pivot_longer(c(n, pct), names_to = "param", values_to = "value") |>
    mutate(group = group_lbl, label = as.character(.data[[var]])) |>
    select(ARM, group, label, param, value)
}
dm_long <- bind_rows(age_long |> select(ARM, group, label, param, value),
                     cat_long("SEX", "Sex"), cat_long("RACE", "Race"))
dm_tfrmt <- print_to_gt(tfrmt(
  group = group, label = label, column = ARM, param = param, value = value,
  body_plan = body_plan(
    frmt_structure("Age (years)", ".default", frmt("xx.x")),
    frmt_structure(".default", ".default",
                   frmt_combine("{n} ({pct}%)",
                                n = frmt("xx"), pct = frmt("xx.x"))))),
  dm_long)
.write(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("14.1.1c", "Demographics (tfrmt)"),
      footer = make_footer("gt_tbl", "tfrmt"))) |>
    rtf_tables(as_rtftables(dm_tfrmt, blank_rows = "between_groups"),
               titles = demog_title),
  "tlg-demog-tfrmt.rtf")

# ---- 2. Adverse events (paginated) -----------------------------------------
ae_tbl <- build_table(
  basic_table(show_colcounts = TRUE) |>
    split_cols_by("ARM") |>
    analyze_num_patients(vars = "USUBJID", .stats = "unique",
      .labels = c(unique = "Total number of patients with at least one AE")) |>
    split_rows_by("AEBODSYS", label_pos = "topleft",
                  split_label = "MedDRA System Organ Class") |>
    summarize_num_patients(var = "USUBJID", .stats = "unique",
                           .labels = c(unique = "Total patients with an AE")) |>
    count_occurrences(vars = "AEDECOD"),
  adae, alt_counts_df = adsl)
ae_pages <- as_rtftables(ae_tbl, split = "group_safe", max_rows = 12,
                         blank_rows = "between_groups", align_count_pct = TRUE)
out_ae <- file.path(out_dir, "tlg-ae.rtf")
generate_rtfreport(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("14.3.1", "Adverse Events by SOC and Preferred Term"),
      footer = make_footer("rtables TableTree", "tern + rtables"))) |>
    rtf_tables(ae_pages,
               titles = rep(list(c("Adverse Events Summary", "Safety Analysis Set")),
                            length(ae_pages))),
  out_ae, overwrite = TRUE)
message("wrote ", out_ae, " (", length(ae_pages), " pages)")

# ---- 3. Assembled deliverable ----------------------------------------------
assemble_rtf(c(out_gts, out_ae), file.path(out_dir, "tlg-assembled.rtf"))
message("wrote ", file.path(out_dir, "tlg-assembled.rtf"))

message("\nDone. Open the .rtf files in ", normalizePath(out_dir),
        "\nScreenshots (PNG) go to man/figures/ as:",
        "\n  tlg-demog-tern.png  tlg-demog-gtsummary.png  tlg-demog-tfrmt.png",
        "\n  tlg-ae.png  tlg-assembled.png")
