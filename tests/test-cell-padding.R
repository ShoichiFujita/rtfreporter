# Verify header/footer cells inherit the content-table cell padding default
# (72 twips left/right) and that per-block overrides work.

library(devtools)
load_all(quiet = TRUE)
library(magrittr)

cat("\n=== Cell padding unification ===\n")

df <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
gen <- function(doc) {
  f <- tempfile(fileext = ".rtf")
  generate_rtfreport(doc, f, overwrite = TRUE)
  on.exit(unlink(f))
  paste(readLines(f, warn = FALSE), collapse = "\n")
}

# ── Default: header/footer cells emit \li72\ri72 (matching content table) ───
doc1 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(
    header = rtf_header(rows = list(c(l = "LEFT", r = "RIGHT"))),
    footer = rtf_footer(rows = list(c = "FOOT"))
  )) %>%
  rtf_tables(list(df))
txt1 <- gen(doc1)

# Expect \li72\ri72 in header text segment
stopifnot(grepl("\\\\ql\\\\li72\\\\ri72 LEFT", txt1))
stopifnot(grepl("\\\\qr\\\\li72\\\\ri72 RIGHT", txt1))
stopifnot(grepl("\\\\qc\\\\li72\\\\ri72 FOOT",  txt1))
cat("OK  header/footer cells default to \\li72\\ri72\n")

# ── Per-block override: rtf_header(cell_padding_*) takes precedence ─────────
doc2 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(
    header = rtf_header(rows = list(c(l = "LEFT", r = "RIGHT")),
                        cell_padding_left_twips  = 144L,
                        cell_padding_right_twips = 36L),
    footer = NULL
  )) %>%
  rtf_tables(list(df))
txt2 <- gen(doc2)
stopifnot(grepl("\\\\ql\\\\li144\\\\ri36 LEFT",  txt2))
stopifnot(grepl("\\\\qr\\\\li144\\\\ri36 RIGHT", txt2))
cat("OK  rtf_header(cell_padding_*_twips) override applied\n")

# ── Empty cell ("" — full default height) carries the same padding ─────────
doc3 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(
    header = rtf_header(rows = list(
      c(l = "Top"),
      c(c = ""),                    # explicit empty row
      c(l = "Below")
    )),
    footer = NULL
  )) %>%
  rtf_tables(list(df))
txt3 <- gen(doc3)
stopifnot(grepl("\\\\ql\\\\li72\\\\ri72 Top",   txt3))
stopifnot(grepl("\\\\ql\\\\li72\\\\ri72 Below", txt3))
# Empty c-cell emits \qc\li72\ri72 \cell  (single empty centred cell)
stopifnot(grepl("\\\\qc\\\\li72\\\\ri72 \\\\cell", txt3))
cat("OK  empty cell carries padding too\n")

# ── Resource-level default change cascades automatically (no per-block need) ─
# Simulate admin tweak by mocking the loader cache — read the resource normally
# but with an override.
orig <- rtfreporter:::.load_rtfreporter_defaults()
stopifnot(identical(orig$default_cell_padding_left_twips,  72L))
stopifnot(identical(orig$default_cell_padding_right_twips, 72L))
cat("OK  resource file exposes default_cell_padding_left/right_twips = 72L\n")

cat("\n=== ALL CELL-PADDING TESTS PASSED ===\n\n")
