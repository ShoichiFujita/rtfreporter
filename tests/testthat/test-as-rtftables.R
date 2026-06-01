## tests/testthat/test-as-rtftables.R
##
## as_rtftables(): unified table-object -> list-of-rtftable converter,
## plus the paginate() deprecation shim.

library(testthat)

# ── data.frame input ──────────────────────────────────────────────────────────

test_that("as_rtftables(data.frame) returns a list of one rtftable", {
  df  <- data.frame(a = 1:3, b = c("x", "y", "z"), stringsAsFactors = FALSE)
  res <- as_rtftables(df)
  expect_type(res, "list")
  expect_length(res, 1L)
  expect_s3_class(res[[1L]], "rtftable")
  expect_identical(res[[1L]]$data$a, 1:3)
})

test_that("as_rtftables(data.frame, split) paginates into multiple rtftables", {
  df  <- data.frame(name = paste0("r", 1:6), v = 1:6, stringsAsFactors = FALSE)
  res <- as_rtftables(df, split = "group_force", max_rows = 3,
                      group_col = "name")
  expect_length(res, 2L)
  expect_true(all(vapply(res, inherits, logical(1L), "rtftable")))
  expect_identical(res[[1L]]$data$name, paste0("r", 1:3))
  expect_identical(res[[2L]]$data$name, paste0("r", 4:6))
})

test_that("as_rtftables(list) flattens and propagates names", {
  l <- list(
    "T1" = data.frame(x = 1:2),
    "T2" = data.frame(x = 3:4)
  )
  res <- as_rtftables(l)
  expect_length(res, 2L)
  expect_identical(names(res), c("T1", "T2"))
})

test_that("as_rtftables errors on unsupported input", {
  expect_error(as_rtftables(42L), "supports")
})

# ── gt input ──────────────────────────────────────────────────────────────────

test_that("as_rtftables(gt) reads metadata into the rtftable", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 3)[, c("mpg", "cyl")]) |>
    gt::cols_label(mpg = "MPG", cyl = "Cyl") |>
    gt::cols_align("right", columns = c(mpg, cyl)) |>
    gt::tab_header(title = "T") |>
    gt::tab_source_note("S")

  res <- as_rtftables(g)
  expect_length(res, 1L)
  rt <- res[[1L]]
  expect_s3_class(rt, "rtftable")
  expect_identical(unlist(rt$col_header[[1L]]), c("MPG", "Cyl"))
  expect_identical(rt$col_spec[[1L]]$align, "right")
  # Page-level blocks travel as attributes.
  expect_identical(attr(rt, "rtf_titles"),    "T")
  expect_identical(attr(rt, "rtf_footnotes"), "S")
})

test_that("as_rtftables(gt) per-cell styles are sliced per page", {
  skip_if_not_installed("gt")
  df <- data.frame(name = paste0("r", 1:6), v = 1:6, stringsAsFactors = FALSE)
  g  <- gt::gt(df) |>
    gt::tab_style(gt::cell_text(weight = "bold"),
                  gt::cells_body(rows = 5))
  res <- as_rtftables(g, split = "group_force", max_rows = 3,
                      group_col = "name")
  expect_length(res, 2L)
  # Page 1 (r1-r3): no styled rows -> cell_styles NULL.
  expect_null(res[[1L]]$cell_styles)
  # Page 2 (r4-r6): bold on its row 2 (= r5).
  cs2 <- res[[2L]]$cell_styles
  expect_false(is.null(cs2))
  expect_true(isTRUE(cs2[[2L]]$bold[1L]))
  expect_null(cs2[[1L]])
  expect_null(cs2[[3L]])
})

test_that("as_rtftables(gt) flows titles/footnotes into rtf_tables()", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 2)) |>
    gt::tab_header(title = "Demo") |>
    gt::tab_source_note("Src")
  pages <- as_rtftables(g)
  doc <- rtf_document() |>
    rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) |>
    rtf_tables(pages)
  expect_identical(doc$titles[[1L]],    "Demo")
  expect_identical(doc$footnotes[[1L]], "Src")
})

test_that("as_rtftables(gt, read = FALSE) ignores metadata", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 2)) |>
    gt::tab_header(title = "Demo")
  res <- as_rtftables(g, read = FALSE)
  expect_null(res[[1L]]$col_header)
  expect_null(attr(res[[1L]], "rtf_titles"))
})

# ── gtsummary input ───────────────────────────────────────────────────────────

test_that("as_rtftables(gtsummary) works end to end", {
  skip_if_not_installed("gtsummary")
  skip_if_not_installed("gt")
  s <- gtsummary::tbl_summary(
    data.frame(age = c(20, 30, 40, 50), grp = c("A", "A", "B", "B")))
  res <- as_rtftables(s)
  expect_true(length(res) >= 1L)
  expect_s3_class(res[[1L]], "rtftable")
})

# ── as_rtftable() single-page wrapper still works ─────────────────────────────

test_that("as_rtftable() delegates to as_rtftables and returns one rtftable", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 2)) |> gt::cols_label(mpg = "MPG")
  rt <- as_rtftable(g)
  expect_s3_class(rt, "rtftable")
  expect_false(is.list(rt) && is.null(attr(rt, "class")))
})

# ── paginate() deprecation ────────────────────────────────────────────────────

test_that("paginate() is deprecated but still functional", {
  # The deprecation warning fires at most once per session; reset the guard
  # so this test reliably observes it regardless of test execution order.
  depr_env <- get(".paginate_depr_env", envir = asNamespace("rtfreporter"))
  depr_env$warned <- FALSE
  df <- data.frame(a = 1:4)
  expect_warning(out <- paginate(df), "deprecated|as_rtftables")
  expect_type(out, "list")
  expect_s3_class(out[[1L]], "data.frame")
  # Second call in the same session does not warn again.
  expect_no_warning(paginate(df))
})
