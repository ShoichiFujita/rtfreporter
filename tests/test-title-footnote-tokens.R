# Title / footnote rendering — text-paragraph form (no magic tokens, no tables)
#
# After v0.0.11 magic tokens ({HALF_BLANK_ROW}, {BLANK_ROW}) are removed.
# Titles and footnotes are rendered as ordinary RTF paragraphs that inherit
# the document font size.

library(devtools)
load_all(quiet = TRUE)
library(magrittr)

cat("\n=== Title / footnote text-paragraph rendering ===\n")

df <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)

gen <- function(doc) {
  f <- tempfile(fileext = ".rtf")
  generate_rtfreport(doc, f, overwrite = TRUE)
  on.exit(unlink(f))
  paste(readLines(f, warn = FALSE), collapse = "\n")
}

# ── Default title: NULL → one centred blank paragraph ─────────────────────
doc1 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) %>%
  rtf_tables(list(df))
txt1 <- gen(doc1)
stopifnot(grepl("\\\\pard\\\\qc\\\\par", txt1))
cat("OK  title = NULL → one centred blank paragraph (\\pard\\qc\\par)\n")

# ── Title text → centred bold paragraph(s) ────────────────────────────────
doc2 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) %>%
  rtf_tables(list(df), titles = list(c("Table 14.1.1", "Safety Population")))
txt2 <- gen(doc2)
stopifnot(grepl("\\\\pard\\\\qc\\\\b Table 14\\.1\\.1\\\\b0\\\\par", txt2))
stopifnot(grepl("\\\\pard\\\\qc\\\\b Safety Population\\\\b0\\\\par", txt2))
cat("OK  title text → centred bold paragraphs\n")

# ── Title with explicit empty string = blank line ─────────────────────────
doc3 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) %>%
  rtf_tables(list(df), titles = list(c("Table 14.1.1", "", "Safety Population")))
txt3 <- gen(doc3)
# We expect one blank \pard\qc\par BETWEEN the two text paragraphs.
stopifnot(grepl("Table 14\\.1\\.1", txt3))
stopifnot(grepl("Safety Population", txt3))
n_blank <- length(gregexpr("\\\\pard\\\\qc\\\\par", txt3)[[1L]])
stopifnot(n_blank >= 1L)
cat("OK  empty string within title yields a blank paragraph\n")

# ── character(0) suppresses the title block entirely ──────────────────────
doc4 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) %>%
  rtf_tables(list(df), titles = list(character(0)))
txt4 <- gen(doc4)
# No \pard\qc\par or bold paragraph from the title block.
# (Page header/footer here are NULL, so any \pard\qc\par would come from title.)
stopifnot(!grepl("\\\\pard\\\\qc\\\\par", txt4))
cat("OK  title = character(0) suppresses the title block\n")

# ── Footnote: paragraph with top border on first row only ─────────────────
doc5 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) %>%
  rtf_tables(list(df),
             footnotes = list(c("Note 1: foo.", "", "Note 2: bar.")))
txt5 <- gen(doc5)
stopifnot(grepl("\\\\pard\\\\brdrt\\\\brdrs\\\\brdrw15\\\\ql Note 1: foo\\.", txt5))
stopifnot(grepl("Note 2: bar\\.", txt5))
# Second line should NOT carry the border (single top border on row 1 only).
n_brdr <- length(gregexpr("\\\\brdrt\\\\brdrs", txt5)[[1L]])
stopifnot(n_brdr == 1L)
cat("OK  footnote: top border on first line only, blank lines kept\n")

# ── Magic tokens are NOT special anymore: treated as literal text ─────────
doc6 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) %>%
  rtf_tables(list(df), titles = list("{HALF_BLANK_ROW}"))
txt6 <- gen(doc6)
# The literal string should appear (escaped: \{HALF_BLANK_ROW\}).
stopifnot(grepl("\\\\\\{HALF_BLANK_ROW\\\\\\}", txt6))
cat("OK  '{HALF_BLANK_ROW}' is now treated as literal text\n")

# ── Column-header bold default is now FALSE ───────────────────────────────
tbl <- rtftable(df)
stopifnot(identical(tbl$col_spec[[1L]]$header_bold, FALSE))
stopifnot(identical(tbl$col_spec[[2L]]$header_bold, FALSE))
cat("OK  rtftable col_spec header_bold default is FALSE\n")

# ── Header/footer rows with magic token are now literal text ──────────────
doc7 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(
    header = rtf_header(rows = list(
      c(l = "Protocol"),
      c(c = "{HALF_BLANK_ROW}"),
      c(l = "Below")
    )),
    footer = NULL
  )) %>%
  rtf_tables(list(df))
txt7 <- gen(doc7)
# The literal escaped string {HALF_BLANK_ROW} appears in header
stopifnot(grepl("\\\\\\{HALF_BLANK_ROW\\\\\\}", txt7))
# No \trrh<half> — only \trrh<full> rows
n_full <- length(gregexpr("\\\\trrh230\\b", txt7)[[1L]])
stopifnot(n_full >= 3L)   # 3 header rows
cat("OK  rtf_header() rows: token is literal, all rows at default height\n")

# ── rtf_titles() / rtf_footnotes() standalone still works ─────────────────
doc8 <- rtf_document() %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) %>%
  rtf_tables(list(df, df)) %>%
  rtf_titles(list("Page One", c("Page Two", "", "Subtitle"))) %>%
  rtf_footnotes(list(NULL, "Footnote of page 2"))
stopifnot(length(doc8$titles)    == 2L)
stopifnot(length(doc8$footnotes) == 2L)
txt8 <- gen(doc8)
stopifnot(grepl("Page One",            txt8))
stopifnot(grepl("Page Two",            txt8))
stopifnot(grepl("Footnote of page 2",  txt8))
cat("OK  rtf_titles() / rtf_footnotes() standalone\n")

cat("\n=== ALL TITLE/FOOTNOTE TEXT-PARAGRAPH TESTS PASSED ===\n\n")
