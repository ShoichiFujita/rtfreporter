# rtf_border and rtf_table_style (all S3): construction, derivation, sharing.

test_that("rtf_border is a plain S3 list with class 'rtf_border'", {
  b <- rtf_border_top()
  expect_s3_class(b, "rtf_border")
  expect_false(inherits(b, "R6"))
  expect_false(is.null(b$top))
  expect_null(b$bottom)
})

test_that("rtf_border_with() returns an independent copy", {
  base    <- rtf_border_top()
  derived <- rtf_border_with(base, bottom = rtf_border_side("dot"))
  expect_null(base$bottom)
  expect_identical(derived$bottom$style, "dot")
  expect_identical(derived$top$style,    "single")
})

test_that("rtf_border_with() supports multi-side overrides and NULL sides", {
  two <- rtf_border_with(rtf_border_top(),
                          bottom = rtf_border_side("double", 20L),
                          left   = NULL)
  expect_identical(two$top$style,    "single")
  expect_identical(two$bottom$style, "double")
  expect_identical(two$bottom$width, 20L)
  expect_null(two$left)
})

test_that("rtf_border() validates its sides", {
  expect_error(rtf_border(top = "not-a-side"),
               "rtf_border_side")
})

test_that("rtf_border_side() validates style, width, and color", {
  expect_error(rtf_border_side(style = "nope"), "should be one of")
  expect_error(rtf_border_side(width = 0L),     "positive integer")
  expect_error(rtf_border_side(color = "red"),  "6-digit hex")
})

test_that("rtf_table_style is S3 with class 'rtf_table_style'", {
  sty <- rtf_table_style_tfl()
  expect_s3_class(sty, "rtf_table_style")
  expect_false(inherits(sty, "R6"))
  expect_false(sty$header_bold)
})

test_that("rtf_table_style_with() returns a copy with selected fields replaced", {
  sty  <- rtf_table_style_tfl()
  sty2 <- rtf_table_style_with(sty, header_bold = TRUE)
  expect_true(sty2$header_bold)
  expect_false(sty$header_bold)
})

test_that("rtf_table_style_with() rejects unknown field names", {
  sty <- rtf_table_style_tfl()
  expect_error(rtf_table_style_with(sty, nonexistent = 1L),
               "Unknown style field")
})

test_that("style values are snapshotted into each rtftable at construction", {
  sty <- rtf_table_style_tfl()
  df  <- data.frame(A = 1:2, B = c("x", "y"), stringsAsFactors = FALSE)

  t1       <- rtftable(df, style = sty)
  sty_bold <- rtf_table_style_with(sty, header_bold = TRUE)
  t2       <- rtftable(df, style = sty_bold)

  expect_false(t1$col_spec[[1L]]$header_bold)
  expect_true (t2$col_spec[[1L]]$header_bold)
})

test_that("col_spec[[j]]$border applies per-column in the header row", {
  df  <- data.frame(L = "x", N = 1L, V = 2.5)
  tbl <- rtftable(df,
    border = rtf_table_border(header = rtf_border_top()),
    col_spec = list(
      list(col = 2, border = rtf_border(top    = rtf_border_side("double", 20L),
                                         bottom = rtf_border_side("double", 20L)))
    ))
  expect_s3_class(tbl$col_spec[[2L]]$border, "rtf_border")
  expect_identical(tbl$col_spec[[2L]]$border$bottom$style, "double")

  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(tbl))
  txt <- .render_to_string(doc)
  expect_match(txt, "\\\\brdrdb")   # \brdrdb = RTF "double" border command
})

test_that("border = 'tfl' produces an rtf_table_border with header-only zones", {
  tbl <- rtftable(data.frame(A = 1), border = "tfl")
  expect_s3_class(tbl$border, "rtf_table_border")
  expect_s3_class(tbl$border$header, "rtf_border")
})
