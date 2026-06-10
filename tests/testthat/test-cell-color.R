# Cell text colour (Phase A): col_spec$color / cell_styles$color render as
# \cf<idx>, and the colours are collected into the document \colortbl.
# (Background fill and header/footer text colour are out of scope here.)

.df2 <- function() data.frame(Param = c("Age", "Sex"), Value = c("75", "F"),
                              stringsAsFactors = FALSE)

.render <- function(doc) {
  f <- tempfile(fileext = ".rtf")
  on.exit(unlink(f), add = TRUE)
  generate_rtfreport(doc, f, overwrite = TRUE)
  paste(readLines(f, warn = FALSE), collapse = "\n")
}

test_that("col_spec$color sets a column's text colour via \\cf and \\colortbl", {
  tbl <- rtftable(.df2(), col_spec = list(list(col = 2, color = "#FF0000")))
  txt <- .render(rtf_document() |> rtf_tables(tbl))
  expect_match(txt, "\\\\red255\\\\green0\\\\blue0")   # colour in the table
  expect_match(txt, "\\\\cf[0-9]")                      # applied via \cf
})

test_that("cell_styles$color overrides a single cell's colour", {
  tbl <- rtftable(.df2(), cell_styles = list(
    list(color = c(NA, "#0000FF")),   # row 1, column 2 -> blue
    NULL                              # row 2 -> no override
  ))
  txt <- .render(rtf_document() |> rtf_tables(tbl))
  expect_match(txt, "\\\\red0\\\\green0\\\\blue255")
})

test_that("a declared color_table colour is added to the palette by index", {
  txt <- .render(
    rtf_document(color_table = c("#000000", "#1F4E79")) |>
      rtf_tables(rtftable(.df2()))
  )
  # #1F4E79 = rgb(31, 78, 121)
  expect_match(txt, "\\\\red31\\\\green78\\\\blue121")
})

test_that("the default document colour table is unchanged (no redundant entry)", {
  txt <- .render(rtf_document() |> rtf_tables(rtftable(.df2())))
  pal <- regmatches(txt, regexpr("colortbl[^}]*", txt))
  expect_identical(pal, "colortbl;\\red0\\green0\\blue0;\\red255\\green255\\blue255;")
})

test_that("a black/white col_spec colour is a no-op (reserved slots)", {
  tbl <- rtftable(.df2(), col_spec = list(list(col = 1, color = "#000000")))
  txt <- .render(rtf_document() |> rtf_tables(tbl))
  # No user palette entry added; black text needs no \cf override.
  pal <- regmatches(txt, regexpr("colortbl[^}]*", txt))
  expect_identical(pal, "colortbl;\\red0\\green0\\blue0;\\red255\\green255\\blue255;")
})
