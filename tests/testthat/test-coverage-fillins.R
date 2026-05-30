# Targeted fill-in tests to lift covr above 90%.
# Each block targets a specific set of currently-uncovered defensive
# branches / error paths.  Kept together so the intent ("close the
# coverage gap, not retest the happy path") is unambiguous.

# ── R/blank_rows.R: input validation + edge-case returns ────────────

test_that("blank_rows_by_change() / by_rule() reject malformed arguments", {
  expect_error(blank_rows_by_change(cols = character(0)),
               "non-empty character")
  expect_error(blank_rows_by_change(cols = NULL),
               "non-empty character")
  expect_error(blank_rows_by_rule(col = character(0), pattern = "x"),
               "single column name")
  expect_error(blank_rows_by_rule(col = "a",         pattern = character(0)),
               "single regular expression")
})

test_that(".resolve_blank_rows() handles NULL / unknown / non-matching specs", {
  # NULL spec -> integer(0)
  expect_identical(
    rtfreporter:::.resolve_blank_rows(NULL, data.frame(x = 1:3)),
    integer(0)
  )
  # Garbage spec -> error
  expect_error(
    rtfreporter:::.resolve_blank_rows(list(class = "bogus"),
                                       data.frame(x = 1:3)),
    "Unrecognised"
  )
})

test_that("blank_rows_by_change() warns + ignores missing columns", {
  df <- data.frame(grp = c("A", "A", "B"), x = 1:3)
  spec <- blank_rows_by_change(cols = "missing_column")
  expect_warning(
    rtfreporter:::.resolve_blank_rows(spec, df),
    "not found.*ignored"
  )
})

test_that("blank_rows_by_rule() warns + returns empty when col is missing", {
  df <- data.frame(grp = c("A", "B", "A"), x = 1:3)
  spec <- blank_rows_by_rule(col = "missing_column", pattern = "^A$")
  expect_warning(
    out <- rtfreporter:::.resolve_blank_rows(spec, df),
    "not found.*ignored"
  )
  expect_identical(out, integer(0))
})

test_that("blank_rows_by_rule() with a pattern that matches nothing -> empty", {
  df <- data.frame(grp = c("A", "B", "A"), x = 1:3)
  spec <- blank_rows_by_rule(col = "grp", pattern = "Z+")
  out <- rtfreporter:::.resolve_blank_rows(spec, df)
  expect_identical(out, integer(0))
})

test_that(".resolve_blank_rows() of an empty data.frame returns integer(0)", {
  df0  <- data.frame(grp = character(0))
  spec <- blank_rows_by_change(cols = "grp")
  expect_identical(rtfreporter:::.resolve_blank_rows(spec, df0), integer(0))

  spec2 <- blank_rows_by_rule(col = "grp", pattern = "x")
  expect_identical(rtfreporter:::.resolve_blank_rows(spec2, df0), integer(0))
})


# ── R/gt_adapter.R: extractor early returns ────────────────────────

test_that("gt extractors return NULL on a synthetic 'gt_tbl' that has no slots", {
  skip_if_not_installed("gt")
  # Fabricate a class but no slots: forces the early-return branches.
  fake <- structure(list(), class = c("gt_tbl", "list"))
  expect_null(rtfreporter:::.extract_col_labels(fake))
  expect_null(rtfreporter:::.extract_col_align(fake))
  expect_null(rtfreporter:::.extract_titles(fake))
  expect_null(rtfreporter:::.extract_visible_mask(fake))
  expect_null(rtfreporter:::.extract_widths(fake))
  expect_identical(rtfreporter:::.extract_spanners(fake), list())
})

test_that(".extract_widths() returns NULL when any column has an unknown unit", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 1)[, c("mpg", "cyl")]) |>
    gt::cols_width(mpg ~ gt::px(100))
  # Manually inject an unparsable width into the second slot.
  g[["_boxhead"]]$column_width[[2L]] <- list(list("3em"))
  expect_null(rtfreporter:::.extract_widths(g))
})

test_that(".extract_spanners() skips a spanner whose vars become non-contiguous", {
  skip_if_not_installed("gt")
  # gt re-orders columns to make spanners contiguous, so to actually
  # exercise the contiguity guard we patch `_spanners` by hand to
  # reference a non-contiguous set in the boxhead column order.
  g <- gt::gt(head(mtcars, 1)[, c("mpg", "cyl", "disp")]) |>
    gt::tab_spanner(label = "Engine", columns = c(cyl))
  # Hijack: claim Engine spans mpg + disp (skipping cyl).  Builds a
  # spanner whose vars resolve to indices c(1, 3) -- non-contiguous.
  g[["_spanners"]]$vars[[1L]] <- c("mpg", "disp")
  rows <- rtfreporter:::.extract_spanners(g)
  expect_length(rows, 0L)
})

test_that(".extract_spanners() drops a spanner whose vars are all hidden", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 1)[, c("mpg", "cyl", "disp")]) |>
    gt::cols_hide(c(cyl, disp)) |>
    gt::tab_spanner(label = "GoneEngine", columns = c(cyl, disp))
  mask <- rtfreporter:::.extract_visible_mask(g)
  rows <- rtfreporter:::.extract_spanners(g, visible_mask = mask)
  # All vars hidden -> no spanner row.  Use length to dodge any
  # list-vs-list() structural identity quirks.
  expect_length(rows, 0L)
})

test_that(".extract_spanners() copes with NA / empty spanner labels", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 1)[, c("mpg", "cyl", "disp")]) |>
    gt::tab_spanner(label = "Engine", columns = c(cyl, disp))
  # Force the label to NA to hit the `is.na(label) -> ""` fallback.
  g[["_spanners"]]$spanner_label[[1L]] <- NA_character_
  rows <- rtfreporter:::.extract_spanners(g)
  expect_length(rows, 1L)
  expect_identical(rows[[1L]][[1L]]$label, "")
})

test_that(".extract_source_notes() handles all-NA notes -> NULL", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 1)) |>
    gt::tab_source_note("ok")
  # Force the only note to NA to hit the "filter then check empty" branch.
  g[["_source_notes"]][[1L]] <- NA_character_
  expect_null(rtfreporter:::.extract_source_notes(g))
})

test_that(".extract_titles() returns NULL when only NA pieces are present", {
  skip_if_not_installed("gt")
  g <- gt::gt(head(mtcars, 1)) |>
    gt::tab_header(title = NA_character_, subtitle = NA_character_)
  expect_null(rtfreporter:::.extract_titles(g))
})

test_that(".gt_to_rtftable_kwargs() rejects a non-gt argument", {
  skip_if_not_installed("gt")
  expect_error(
    rtfreporter:::.gt_to_rtftable_kwargs(list()),
    "must be a gt_tbl"
  )
})

test_that(".merge_gt_block() returns user when set, gt fallback otherwise", {
  expect_identical(rtfreporter:::.merge_gt_block("U", "G"), "U")
  expect_identical(rtfreporter:::.merge_gt_block(NULL, "G"), "G")
  expect_null(rtfreporter:::.merge_gt_block(NULL, NULL))
})


# ── R/as_rtftable.R: merger edge cases ──────────────────────────────

test_that(".merge_col_spec() returns either operand when the other is NULL", {
  expect_null(rtfreporter:::.merge_col_spec(NULL, NULL))
  u <- list(list(col = 1L, bold = TRUE))
  expect_identical(rtfreporter:::.merge_col_spec(u, NULL), u)
  expect_identical(rtfreporter:::.merge_col_spec(NULL, u), u)
})

test_that(".merge_col_spec() handles user entries that target NEW columns", {
  gt_spec   <- list(list(col = 1L, align = "right"))
  user_spec <- list(list(col = 2L, italic = TRUE))     # new column 2
  out <- rtfreporter:::.merge_col_spec(user_spec, gt_spec)
  cols <- vapply(out, function(e) e$col, integer(1L))
  expect_setequal(cols, c(1L, 2L))
})

test_that("as_rtftable() forwards `...` to rtftable (e.g. col_rel_width passes through)", {
  skip_if_not_installed("gt")
  g   <- gt::gt(head(mtcars, 1)[, c("mpg", "cyl")])
  tbl <- as_rtftable(g, read = FALSE, col_rel_width = c(2, 1))
  expect_identical(tbl$col_rel_width, c(2, 1))
})


# ── R/paginate.R: defensive empty-input paths ──────────────────────

test_that("paginate() of an empty data.frame returns one empty chunk", {
  res <- paginate(data.frame(x = integer(0)), max_rows = 5L)
  expect_length(res, 1L)
  expect_identical(nrow(res[[1L]]), 0L)
})

test_that("paginate() of a one-page-fit data.frame returns the same data", {
  # Hits the `nrow(df) <= max_rows -> single-chunk` early-return path.
  # `paginate()` attaches an `rtf_paginate_meta` attribute to every
  # chunk; compare values only (drop attributes for the equality test).
  df  <- data.frame(grp = c("A", "A", "B"), x = 1:3)
  res <- paginate(df, max_rows = 10L)
  expect_length(res, 1L)
  out <- res[[1L]]
  attr(out, "rtf_paginate_meta") <- NULL
  expect_identical(out, df)
})

test_that("paginate() errors on a list containing a garbage entry", {
  expect_error(
    paginate(data.frame(x = 1:5), max_rows = 3L,
             blank_rows = list("not_a_spec_string")),
    "Unrecognised"
  )
})


# (R6 / rtf_theme tests removed -- the R6 path was deleted in v0.0.41
#  in favour of the all-S3 rtf_table_style snapshot mechanism.)
