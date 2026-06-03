# =============================================================================
# data-raw/gen_tlg_catalog_rtf.R
#
# Regenerate the example RTF files used in
# vignettes/articles/tlg-catalog.Rmd to a KNOWN folder, so you can open them
# in Word / LibreOffice and take screenshots for the article.
#
# Run from the repo root:
#     Rscript data-raw/gen_tlg_catalog_rtf.R
#
# Output: ./output/tlg/*.rtf  (the output/ directory is git-ignored).
# Screenshots then go to man/figures/  (see the message printed at the end).
# =============================================================================

library(rtfreporter)
library(gtsummary)
library(rtables)
library(tern)
library(tfrmt)
library(dplyr)

out_dir <- file.path("output", "tlg")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ---- the same simulated data the article uses (identical seed) -------------
set.seed(2026)
n   <- 60
arm <- sample(c("Placebo", "Xanomeline Low", "Xanomeline High"), n, TRUE)

adsl <- tibble(
  USUBJID = sprintf("01-701-%03d", seq_len(n)),
  ARM     = factor(arm,
                   levels = c("Placebo", "Xanomeline Low", "Xanomeline High")),
  AGE     = round(rnorm(n, 60, 9)),
  SEX     = factor(sample(c("F", "M"), n, TRUE)),
  RACE    = factor(sample(c("WHITE", "BLACK OR AFRICAN AMERICAN", "ASIAN"),
                          n, TRUE, prob = c(.7, .2, .1)))
)
soc <- c("Gastrointestinal disorders", "Nervous system disorders",
         "Skin and subcutaneous tissue disorders")
pt  <- list("Nausea", "Diarrhoea", c("Headache", "Dizziness"),
            c("Rash", "Pruritus"))
adae <- adsl |>
  slice_sample(n = 90, replace = TRUE) |>
  transmute(USUBJID, ARM,
            AESOC   = factor(sample(soc, n(), TRUE)),
            AEDECOD = factor(sample(unlist(pt), n(), TRUE)))

make_header <- function(table_no, title2) {
  rtf_header(rows = list(
    c(l = "Hoge Co. Limited",   r = "CONFIDENTIAL"),
    c(l = "Protocol: RTF-101",  r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}"),
    c(c = paste0("Table ", table_no, "  ", title2))
  ))
}
make_footer <- function(source_object, built_with) {
  rtf_footer(c(l = paste0(
    "Layout adapted from the pharmaverse / NEST TLG catalogs.  ",
    "Source object: ", source_object, " (built with ", built_with, "); ",
    "read into RTF with rtfreporter::as_rtftables().  Data simulated.")))
}

.write <- function(doc, file) {
  path <- file.path(out_dir, file)
  generate_rtfreport(doc, path, overwrite = TRUE)
  message("wrote ", path)
}

# ---- 1. Demographics (gtsummary) -------------------------------------------
dm_tbl <- adsl |>
  select(ARM, AGE, SEX, RACE) |>
  tbl_summary(by = ARM,
              label = list(AGE = "Age (years)", SEX = "Sex", RACE = "Race")) |>
  modify_header(label = "Characteristic")
.write(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("14.1.1", "Demographic and Baseline Characteristics"),
      footer = make_footer("gt_tbl", "gtsummary::tbl_summary()"))) |>
    rtf_tables(as_rtftables(dm_tbl, align_count_pct = TRUE),
               titles = list(c("Demographic and Baseline Characteristics",
                               "Safety Analysis Set"))),
  "tlg-demographics.rtf")

# ---- 2. Adverse events by SOC / PT (tern + rtables) ------------------------
ae_lyt <- basic_table(show_colcounts = TRUE) |>
  split_cols_by("ARM") |>
  analyze_num_patients(vars = "USUBJID", .stats = "unique",
                       .labels = c(unique = "Subjects with >=1 AE")) |>
  split_rows_by("AESOC", label_pos = "topleft", split_label = "SOC") |>
  count_occurrences(vars = "AEDECOD")
ae_tbl <- build_table(ae_lyt, as.data.frame(adae),
                      alt_counts_df = as.data.frame(adsl))
.write(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("14.3.1", "Adverse Events by SOC and Preferred Term"),
      footer = make_footer("rtables TableTree", "tern + rtables"))) |>
    rtf_tables(as_rtftables(ae_tbl, align_count_pct = TRUE)),
  "tlg-ae.rtf")

# ---- 3. Age summary (tfrmt) ------------------------------------------------
age_df <- adsl |>
  group_by(ARM) |>
  summarise(mean = mean(AGE), sd = sd(AGE), .groups = "drop") |>
  tidyr::pivot_longer(c(mean, sd), names_to = "param", values_to = "value") |>
  mutate(group = "Age (years)",
         label = recode(param, mean = "Mean", sd = "SD"),
         column = as.character(ARM))
tf <- tfrmt(group = group, label = label, column = column,
            param = param, value = value,
            body_plan = body_plan(
              frmt_structure(".default", ".default", frmt("xx.x"))))
.write(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("14.1.2", "Age Summary (tfrmt)"),
      footer = make_footer("gt_tbl", "tfrmt"))) |>
    rtf_tables(as_rtftables(print_to_gt(tf, age_df))),
  "tlg-tfrmt-age.rtf")

# ---- 4. Subject listing (plain data.frame) ---------------------------------
lst <- adsl |>
  arrange(USUBJID) |>
  transmute(USUBJID, Arm = ARM, Age = AGE, Sex = SEX) |>
  head(12)
.write(
  rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = make_header("16.2.1", "Subject Listing"),
      footer = make_footer("data.frame / tibble", "base R"))) |>
    rtf_tables(as_rtftables(lst),
               col_header = c("Subject ID", "Arm", "Age", "Sex"),
               col_rel_width = c(3, 3, 1, 1)),
  "tlg-listing.rtf")

message("\nDone. Open the .rtf files in ", normalizePath(out_dir),
        "\nSave screenshots (PNG) to man/figures/ as:",
        "\n  tlg-demographics.png  tlg-ae.png  tlg-tfrmt-age.png  tlg-listing.png")
