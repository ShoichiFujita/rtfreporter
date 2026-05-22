# =============================================================================
# test_shift_table.R  —  Lab shift table: one section per test item
#
# Structure:
#   rtfreport
#     Section 1 (ALT)  ← header bottom-left = "ALT (Alanine Aminotransferase)"
#       Page 1: ALT shift counts table
#     Section 2 (AST)  ← header bottom-left = "AST (Aspartate Aminotransferase)"
#       Page 1: AST shift counts table
#     Section 3 (HGB)  ← header bottom-left = "HGB (Hemoglobin)"
#       Page 1: HGB shift counts table
#
# RTF header/footer are per-section, so the test item name in the header
# changes per section without duplicating any content.
# =============================================================================

source(file.path("r", "rtf_border.R"))
source(file.path("r", "rtfreport.R"))
source(file.path("r", "rtftable.R"))
source(file.path("r", "rtfplot.R"))
source(file.path("r", "generate_rtfreport.R"))
source(file.path("r", "text_width.R"))

OUT_DIR <- file.path("tests", "output")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# 1. Synthetic shift-count data (Baseline × Post-treatment × Treatment arm)
# =============================================================================

make_shift_df <- function(a_low, a_norm, a_high, b_low, b_norm, b_high) {
  data.frame(
    Baseline = c("Low", "Normal", "High"),
    A_Low    = a_low,
    A_Normal = a_norm,
    A_High   = a_high,
    B_Low    = b_low,
    B_Normal = b_norm,
    B_High   = b_high,
    stringsAsFactors = FALSE,
    check.names      = FALSE
  )
}

lab_data <- list(
  list(
    label = "ALT (Alanine Aminotransferase)",
    short = "ALT",
    df    = make_shift_df(
      a_low  = c(4L,  0L, 0L), a_norm = c(1L, 13L, 1L), a_high = c(0L, 2L, 3L),
      b_low  = c(3L,  0L, 0L), b_norm = c(1L, 14L, 0L), b_high = c(0L, 1L, 4L)
    )
  ),
  list(
    label = "AST (Aspartate Aminotransferase)",
    short = "AST",
    df    = make_shift_df(
      a_low  = c(5L,  0L, 0L), a_norm = c(0L, 11L, 2L), a_high = c(0L, 1L, 5L),
      b_low  = c(4L,  0L, 0L), b_norm = c(1L, 12L, 1L), b_high = c(0L, 2L, 4L)
    )
  ),
  list(
    label = "HGB (Hemoglobin)",
    short = "HGB",
    df    = make_shift_df(
      a_low  = c(2L,  1L, 0L), a_norm = c(1L, 16L, 1L), a_high = c(0L, 1L, 2L),
      b_low  = c(3L,  0L, 0L), b_norm = c(0L, 15L, 2L), b_high = c(0L, 2L, 2L)
    )
  )
)

# =============================================================================
# 2. Shared table structure (same for all test items)
# =============================================================================

# Column widths: Baseline column wider, 6 count columns equal
col_widths <- c(2160L, 900L, 900L, 900L, 900L, 900L, 900L)

# Spanning header: Treatment A / Treatment B over count columns (2-7)
spanning_hdr <- list(
  list(from = 2L, to = 4L, label = "Treatment A  (N=24)", underline = TRUE),
  list(from = 5L, to = 7L, label = "Treatment B  (N=24)", underline = TRUE)
)

# Column header: "Baseline" in col 1, Low/Normal/High repeated for each arm
col_hdr <- c("Baseline", "Low", "Normal", "High", "Low", "Normal", "High")

# col_spec: first column left-aligned (baseline labels), counts centered
col_spec_shift <- lapply(seq_len(7L), function(j) {
  list(col = j, align = if (j == 1L) "left" else "center")
})

# Helper: build an rtftable for one test item
make_shift_table <- function(df) {
  rtftable$new(
    data                = df,
    col_header          = col_hdr,
    spanning_header     = spanning_hdr,
    col_spec            = col_spec_shift,
    column_widths_twips = col_widths,
    border              = "tfl",
    row_height_twips    = 280L
  )
}

# =============================================================================
# 3. Common footer (identical for all sections)
# =============================================================================

common_footer <- rtf_footer(
  rows = list(
    c(l = paste0("ALT=Alanine Aminotransferase; ",
                 "AST=Aspartate Aminotransferase; HGB=Hemoglobin")),
    c(l = "Low/Normal/High: site reference range categories.  n = number of subjects.",
      r = "CONFIDENTIAL")
  )
)

# =============================================================================
# 4. Build report: one section per test item
#    Header bottom-left (row 4) carries the test item name — changes per section
# =============================================================================

report <- rtfreport$new()

for (item in lab_data) {
  # Per-section header: rows 1-3 common, row 4 = test item name (bottom-left)
  sec_header <- rtf_header(
    rows = list(
      c(l = "Protocol: LAB-001",
        r = "HOGE Pharma Co., Ltd."),
      c(l = "Study Title: Phase III Safety Lab Assessment",
        r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}"),
      c(c = "Table 14.3.1  Laboratory Shift Table (Safety Population)"),
      c(l = item$label)   # ← test item name: bottom-left, changes per section
    )
  )

  sec <- report$add_section(header = sec_header, footer = common_footer)

  report$add_page(
    section_index = sec,
    content       = list(list(type = "table", data = make_shift_table(item$df))),
    footer_notes  = paste0(
      "Source: LB domain.  ",
      "Subjects with both a baseline and at least one post-baseline assessment included."
    )
  )
}

# =============================================================================
# 5. Generate RTF
# =============================================================================

outfile <- file.path(OUT_DIR, "shift_table.rtf")
generate_rtfreport(report, outfile, overwrite = TRUE)
stopifnot(file.exists(outfile))

rtf_txt <- paste(readLines(outfile, warn = FALSE), collapse = "\n")

# --- assertions ---

# 3 sections → 2 \sect separators in the output
n_sect <- length(gregexpr("\\sect\n", rtf_txt, fixed = TRUE)[[1]])
stopifnot(n_sect == 2L)

# Each test item label must appear in a {\header} block
for (item in lab_data) {
  # The label appears inside {\header ...}
  stopifnot(grepl(item$label, rtf_txt, fixed = TRUE))
}

# Spanning header labels present
stopifnot(grepl("Treatment A", rtf_txt, fixed = TRUE))
stopifnot(grepl("Treatment B", rtf_txt, fixed = TRUE))

# Column header row: "Baseline" present (shared across all tables)
stopifnot(grepl("Baseline", rtf_txt, fixed = TRUE))

# TFL border: header top border
stopifnot(grepl("clbrdrt", rtf_txt, fixed = TRUE))

# NUMPAGES field for AUTO_TOTAL_PAGES
stopifnot(grepl("NUMPAGES", rtf_txt, fixed = TRUE))

# Footer abbreviations present
stopifnot(grepl("Alanine Aminotransferase", rtf_txt, fixed = TRUE))
stopifnot(grepl("CONFIDENTIAL", rtf_txt, fixed = TRUE))

cat(sprintf("Shift table RTF generated: %s\n", outfile))
cat(sprintf("  Sections : 3\n"))
cat(sprintf("  Pages    : 3 (one per test item)\n"))
cat(sprintf("  File size: %d bytes\n", file.info(outfile)$size))
cat("All assertions passed.\n")
