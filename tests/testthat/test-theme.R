# rtf_theme — the one R6 class in the package.  Demonstrates that mutating
# a shared theme is picked up by every referencing rtftable at render time.

test_that("rtf_theme() requires the optional R6 package", {
  skip_if_not_installed("R6")
  th <- rtf_theme()
  expect_s3_class(th, "rtf_theme")
  expect_s3_class(th, "R6")
})

test_that("rtf_theme_tfl() returns the canonical TFL preset as an R6 theme", {
  skip_if_not_installed("R6")
  th <- rtf_theme_tfl()
  expect_s3_class(th, "rtf_theme")
  expect_false(th$header_bold)
  expect_s3_class(th$border_header, "rtf_border")
  expect_s3_class(th$border_header$top, "rtf_border_side")
})

test_that("theme$as_style() snapshots the current state as an rtf_table_style", {
  skip_if_not_installed("R6")
  th  <- rtf_theme_tfl()
  sty <- th$as_style()
  expect_s3_class(sty, "rtf_table_style")
  expect_false(sty$header_bold)
})

test_that("rtftable(theme = ...) stores the R6 reference and raw kwargs", {
  skip_if_not_installed("R6")
  th  <- rtf_theme_tfl()
  df  <- data.frame(A = 1:2, B = c("x", "y"), stringsAsFactors = FALSE)
  tbl <- rtftable(df, theme = th)

  expect_identical(tbl$theme, th)
  expect_false(is.null(tbl$.raw_args))
  # Defaults from the theme were snapshotted at construction.
  expect_false(tbl$col_spec[[1L]]$header_bold)
})

test_that("explicit rtftable args still beat the theme defaults", {
  skip_if_not_installed("R6")
  th  <- rtf_theme(header_align = "center")
  df  <- data.frame(L = "x", N = 1L, stringsAsFactors = FALSE)
  tbl <- rtftable(df, theme = th, col_header_align = "right")
  # The explicit "right" wins; the theme's "center" is the fallback only.
  expect_identical(tbl$col_spec[[1L]]$header_align, "right")
  expect_identical(tbl$col_spec[[2L]]$header_align, "right")
})

test_that("mutating the theme broadcasts to every referencing rtftable at render", {
  skip_if_not_installed("R6")
  th <- rtf_theme(header_bold = FALSE)
  df <- data.frame(A = 1:2, B = c("x", "y"), stringsAsFactors = FALSE)
  t1 <- rtftable(df, theme = th)
  t2 <- rtftable(df, theme = th)

  # First render: header NOT bold for either table.
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(t1, t2))
  txt_before <- .render_to_string(doc)
  expect_false(grepl("\\\\b A\\\\b0", txt_before))
  expect_false(grepl("\\\\b B\\\\b0", txt_before))

  # Mutate the theme in place.
  th$header_bold <- TRUE

  # Second render: BOTH tables now show bold column headers, even though the
  # rtftable objects themselves were never rebuilt.
  txt_after <- .render_to_string(doc)
  expect_match(txt_after, "\\\\b A\\\\b0")
  expect_match(txt_after, "\\\\b B\\\\b0")
})

test_that("theme is also reflected in border zone resolution at render time", {
  skip_if_not_installed("R6")
  th <- rtf_theme(
    border_header = rtf_border(top    = rtf_border_side(),
                                bottom = rtf_border_side())
  )
  df  <- data.frame(A = 1:2, B = c("x", "y"), stringsAsFactors = FALSE)
  tbl <- rtftable(df, theme = th)

  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(tbl))
  txt <- .render_to_string(doc)
  expect_match(txt, "\\\\clbrdrt\\\\brdrs")
  expect_match(txt, "\\\\clbrdrb\\\\brdrs")

  # Replace the header border on the theme — next render reflects it.
  th$border_header <- NULL
  txt2 <- .render_to_string(doc)
  expect_false(grepl("\\\\clbrdrt\\\\brdrs", txt2))
})
