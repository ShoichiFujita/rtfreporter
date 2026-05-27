# Header/footer and content cells inherit the same cell padding default
# (72 twips left/right); per-block overrides win.

test_that("default header/footer cells emit \\li72\\ri72 like content cells", {
  df <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(
    header = rtf_header(rows = list(c(l = "LEFT", r = "RIGHT"))),
    footer = rtf_footer(rows = list(c = "FOOT"))
  ))
  doc <- rtf_tables(doc, list(df))

  txt <- .render_to_string(doc)
  expect_match(txt, "\\\\ql\\\\li72\\\\ri72 LEFT")
  expect_match(txt, "\\\\qr\\\\li72\\\\ri72 RIGHT")
  expect_match(txt, "\\\\qc\\\\li72\\\\ri72 FOOT")
})

test_that("rtf_header(cell_padding_*_twips) overrides the defaults", {
  df <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(
    header = rtf_header(rows = list(c(l = "LEFT", r = "RIGHT")),
                        cell_padding_left_twips  = 144L,
                        cell_padding_right_twips = 36L),
    footer = NULL
  ))
  doc <- rtf_tables(doc, list(df))

  txt <- .render_to_string(doc)
  expect_match(txt, "\\\\ql\\\\li144\\\\ri36 LEFT")
  expect_match(txt, "\\\\qr\\\\li144\\\\ri36 RIGHT")
})

test_that("empty header cells still carry the cell padding", {
  df <- data.frame(A = 1L, B = "x", stringsAsFactors = FALSE)
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(
    header = rtf_header(rows = list(
      c(l = "Top"), c(c = ""), c(l = "Below")
    )),
    footer = NULL
  ))
  doc <- rtf_tables(doc, list(df))

  txt <- .render_to_string(doc)
  expect_match(txt, "\\\\ql\\\\li72\\\\ri72 Top")
  expect_match(txt, "\\\\ql\\\\li72\\\\ri72 Below")
  expect_match(txt, "\\\\qc\\\\li72\\\\ri72 \\\\cell")
})

test_that("resource file exposes the documented default cell-padding values", {
  defaults <- rtfreporter:::.load_rtfreporter_defaults()
  expect_identical(defaults$default_cell_padding_left_twips,  72L)
  expect_identical(defaults$default_cell_padding_right_twips, 72L)
})
