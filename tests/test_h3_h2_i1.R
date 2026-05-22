source(file.path("r", "rtf_border.R"))
source(file.path("r", "rtfreport.R"))
source(file.path("r", "rtftable.R"))
source(file.path("r", "rtfplot.R"))
source(file.path("r", "generate_rtfreport.R"))
source(file.path("r", "assemble_rtf.R"))
source(file.path("r", "text_width.R"))

DM <- read.csv(file.path("tests", "testdata", "dm.csv"), stringsAsFactors = FALSE)
AE <- read.csv(file.path("tests", "testdata", "ae.csv"), stringsAsFactors = FALSE)
OUT <- file.path("tests", "output")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# H-3: {AUTO_TOTAL_PAGES} produces RTF NUMPAGES field
# =============================================================================
cat("--- H-3a: {AUTO_TOTAL_PAGES} → RTF NUMPAGES field ---\n")
r <- rtfreport$new()
sec <- r$add_section(
  header = c(l = "Protocol", r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}")
)
r$add_page(sec, title = "Test", content = list(list(type = "table", data = DM[1:2,])))
out_h3a <- file.path(OUT, "h3a_auto_total.rtf")
generate_rtfreport(r, out_h3a, overwrite = TRUE)
txt <- paste(readLines(out_h3a, warn = FALSE), collapse = "\n")
# Should contain the NUMPAGES RTF field, NOT a static count
stopifnot(grepl("NUMPAGES", txt, fixed = TRUE))
stopifnot(grepl("\\chpgn", txt, fixed = TRUE))
cat("PASS\n\n")

cat("--- H-3b: {TOTAL_PAGES} still produces static count ---\n")
r2 <- rtfreport$new()
sec2 <- r2$add_section(
  header = c(l = "Static", r = "Page {AUTO_PAGE} of {TOTAL_PAGES}")
)
r2$add_page(sec2, content = list(list(type = "table", data = DM[1:2,])))
r2$add_page(sec2, content = list(list(type = "table", data = DM[3:4,])))
out_h3b <- file.path(OUT, "h3b_total_pages.rtf")
generate_rtfreport(r2, out_h3b, overwrite = TRUE)
txt2 <- paste(readLines(out_h3b, warn = FALSE), collapse = "\n")
# Static count "2" must appear, NUMPAGES field must NOT appear in this file
stopifnot(grepl(" of 2", txt2, fixed = TRUE))
stopifnot(!grepl("NUMPAGES", txt2, fixed = TRUE))
cat("PASS\n\n")

cat("--- H-3c: {SECTION_PAGES} → RTF SECTIONPAGES field ---\n")
r3 <- rtfreport$new()
sec3 <- r3$add_section(
  footer = c(l = "Section pages: {SECTION_PAGES}")
)
r3$add_page(sec3, content = list(list(type = "table", data = DM[1:2,])))
out_h3c <- file.path(OUT, "h3c_section_pages.rtf")
generate_rtfreport(r3, out_h3c, overwrite = TRUE)
txt3 <- paste(readLines(out_h3c, warn = FALSE), collapse = "\n")
stopifnot(grepl("SECTIONPAGES", txt3, fixed = TRUE))
cat("PASS\n\n")

# =============================================================================
# H-2: assemble_rtf()
# =============================================================================
cat("--- H-2a: assemble_rtf() joins two RTF files ---\n")
# Generate two RTF files
make_report <- function(data, title, hdr_text) {
  r <- rtfreport$new()
  sec <- r$add_section(header = c(l = hdr_text))
  r$add_page(sec, title = title, content = list(list(type = "table", data = data)))
  r
}

file1 <- file.path(OUT, "assemble_in1.rtf")
file2 <- file.path(OUT, "assemble_in2.rtf")
generate_rtfreport(make_report(DM[1:3,], "DM table", "DM Section"),  file1, overwrite = TRUE)
generate_rtfreport(make_report(AE[1:3,], "AE table", "AE Section"),  file2, overwrite = TRUE)

out_h2 <- file.path(OUT, "assembled.rtf")
assemble_rtf(c(file1, file2), out_h2, overwrite = TRUE)

stopifnot(file.exists(out_h2))
asm_txt <- paste(readLines(out_h2, warn = FALSE), collapse = "\n")
# Both section headers should be present
stopifnot(grepl("DM Section", asm_txt, fixed = TRUE))
stopifnot(grepl("AE Section", asm_txt, fixed = TRUE))
# A \sect separator must join the two files
stopifnot(grepl("\\sect", asm_txt, fixed = TRUE))
# Only one {\rtf1 header (from file 1)
n_rtf1 <- length(gregexpr("\\rtf1", asm_txt, fixed = TRUE)[[1]])
stopifnot(n_rtf1 == 1L)
cat("PASS\n\n")

cat("--- H-2b: assemble_rtf() error on missing file ---\n")
err <- tryCatch(
  assemble_rtf(c(file1, "nonexistent.rtf"), file.path(OUT, "should_fail.rtf")),
  error = function(e) e
)
stopifnot(inherits(err, "error"))
stopifnot(grepl("not found", conditionMessage(err)))
cat("PASS\n\n")

cat("--- H-2c: assemble_rtf() error when only one file supplied ---\n")
err2 <- tryCatch(
  assemble_rtf(c(file1), file.path(OUT, "should_fail2.rtf")),
  error = function(e) e
)
stopifnot(inherits(err2, "error"))
cat("PASS\n\n")

cat("--- H-2d: assemble_rtf() with 3 files ---\n")
file3 <- file.path(OUT, "assemble_in3.rtf")
generate_rtfreport(make_report(DM[4:6,], "DM2 table", "DM2 Section"), file3, overwrite = TRUE)
out_h2d <- file.path(OUT, "assembled_3.rtf")
assemble_rtf(c(file1, file2, file3), out_h2d, overwrite = TRUE)
asm3_txt <- paste(readLines(out_h2d, warn = FALSE), collapse = "\n")
stopifnot(grepl("DM Section",  asm3_txt, fixed = TRUE))
stopifnot(grepl("AE Section",  asm3_txt, fixed = TRUE))
stopifnot(grepl("DM2 Section", asm3_txt, fixed = TRUE))
cat("PASS\n\n")

# =============================================================================
# I-1: text_width_in() and auto_col_widths()
# =============================================================================
cat("--- I-1a: text_width_in() basic estimates ---\n")
# 13 chars at 9pt Courier (7.22pt/char → 7.22*9/12=5.415pt → 5.415/72 = 0.0752 in per char)
w <- text_width_in("Hello, World!", font = "courier_new", size_half_points = 18L)
stopifnot(is.numeric(w) && length(w) == 1L)
stopifnot(w > 0.5 && w < 2.0)   # rough sanity: ~0.977 inches
cat(sprintf("  'Hello, World!' width at 9pt Courier: %.4f in\n", w))

# Vectorised
ws <- text_width_in(c("A", "ABCDE", ""), font = "courier_new", size_half_points = 18L)
stopifnot(length(ws) == 3L)
stopifnot(ws[1] < ws[2])   # longer string is wider
stopifnot(ws[3] == 0)      # empty string has zero width
cat("PASS\n\n")

cat("--- I-1b: auto_col_widths() returns one width per column ---\n")
widths <- auto_col_widths(DM)
stopifnot(is.integer(widths))
stopifnot(length(widths) == ncol(DM))
stopifnot(all(widths >= 720L))    # at least min_col_width
cat(sprintf("  DM column widths (twips): %s\n", paste(widths, collapse = ", ")))
cat("PASS\n\n")

cat("--- I-1c: auto_col_widths() with table_width_twips scales sum correctly ---\n")
target_w <- 14400L
widths_scaled <- auto_col_widths(DM, table_width_twips = target_w)
stopifnot(sum(widths_scaled) == target_w)
cat(sprintf("  Sum of scaled widths: %d (target %d)\n", sum(widths_scaled), target_w))
cat("PASS\n\n")

cat("--- I-1d: auto_col_widths() result used in rtftable ---\n")
widths2 <- auto_col_widths(DM[, 1:2], table_width_twips = 10000L)
tbl <- rtftable$new(DM[1:3, 1:2], column_widths_twips = widths2)
r_i1 <- rtfreport$new()
sec_i1 <- r_i1$add_section()
r_i1$add_page(sec_i1, content = list(list(type = "table", data = tbl)))
out_i1 <- file.path(OUT, "i1_auto_widths.rtf")
generate_rtfreport(r_i1, out_i1, overwrite = TRUE)
i1_txt <- paste(readLines(out_i1, warn = FALSE), collapse = "\n")
stopifnot(grepl("cellx10000", i1_txt, fixed = TRUE))
cat("PASS\n\n")

cat("--- I-1e: auto_col_widths() with custom col_header ---\n")
widths3 <- auto_col_widths(
  DM[, 1:2],
  col_header = "Subject Identifier | Sex",
  table_width_twips = 8000L
)
stopifnot(sum(widths3) == 8000L)
cat("PASS\n\n")

cat("All H-3 / H-2 / I-1 tests passed.\n")
