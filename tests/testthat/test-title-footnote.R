# Title / footnote text-paragraph rendering and the rtf_titles / rtf_footnotes
# pipe helpers.  Magic tokens are no longer special — they render literally.

.render_with <- function(doc) .render_to_string(doc)

test_that("title = NULL defaults to a single centred blank paragraph", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(df))
  txt <- .render_with(doc)
  expect_match(txt, "\\\\pard\\\\qc\\\\par")
})

test_that("title text renders as centred bold paragraphs", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(df),
                    titles = list(c("Table 14.1.1", "Safety Population")))
  txt <- .render_with(doc)
  expect_match(txt, "\\\\pard\\\\qc\\\\b Table 14\\.1\\.1\\\\b0\\\\par")
  expect_match(txt, "\\\\pard\\\\qc\\\\b Safety Population\\\\b0\\\\par")
})

test_that("an empty string within title yields a blank paragraph", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(df),
                    titles = list(c("Table 14.1.1", "", "Safety Population")))
  txt <- .render_with(doc)
  expect_match(txt, "Table 14\\.1\\.1")
  expect_match(txt, "Safety Population")
  expect_gte(length(gregexpr("\\\\pard\\\\qc\\\\par", txt)[[1L]]), 1L)
})

test_that("title = character(0) suppresses the title block entirely", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(df), titles = list(character(0)))
  txt <- .render_with(doc)
  expect_false(grepl("\\\\pard\\\\qc\\\\par", txt))
})

test_that("footnote: top border on first line only; blank lines preserved", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(df),
                    footnotes = list(c("Note 1: foo.", "", "Note 2: bar.")))
  txt <- .render_with(doc)
  expect_match(txt, "\\\\pard\\\\brdrt\\\\brdrs\\\\brdrw15\\\\ql Note 1: foo\\.")
  expect_match(txt, "Note 2: bar\\.")
  expect_identical(length(gregexpr("\\\\brdrt\\\\brdrs", txt)[[1L]]), 1L)
})

test_that("legacy magic tokens are now rendered as literal text", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(df), titles = list("{HALF_BLANK_ROW}"))
  txt <- .render_with(doc)
  expect_match(txt, "\\\\\\{HALF_BLANK_ROW\\\\\\}")
})

test_that("rtftable col_spec header_bold defaults to FALSE", {
  tbl <- rtftable(data.frame(A = 1L, B = "x", stringsAsFactors = FALSE))
  expect_false(tbl$col_spec[[1L]]$header_bold)
  expect_false(tbl$col_spec[[2L]]$header_bold)
})

test_that("rtf_header() rows treat legacy tokens as literal text", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(
    header = rtf_header(rows = list(
      c(l = "Protocol"),
      c(c = "{HALF_BLANK_ROW}"),
      c(l = "Below")
    )),
    footer = NULL
  ))
  doc <- rtf_tables(doc, list(df))
  txt <- .render_with(doc)
  expect_match(txt, "\\\\\\{HALF_BLANK_ROW\\\\\\}")
  expect_gte(length(gregexpr("\\\\trrh230\\b", txt)[[1L]]), 3L)
})

test_that("rtf_titles() and rtf_footnotes() set per-page titles/footnotes", {
  df  <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(df, df))
  doc <- rtf_titles(doc, list("Page One", c("Page Two", "", "Subtitle")))
  doc <- rtf_footnotes(doc, list(NULL, "Footnote of page 2"))

  expect_length(doc$titles,    2L)
  expect_length(doc$footnotes, 2L)
  txt <- .render_with(doc)
  expect_match(txt, "Page One")
  expect_match(txt, "Page Two")
  expect_match(txt, "Footnote of page 2")
})
