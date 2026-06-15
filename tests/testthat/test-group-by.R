## tests/testthat/test-group-by.R
##
## Selectable group-detection logic for the group-aware splits (issue #128):
## `group_by = c("auto", "indent", "value", "filled")`, decoupled from the
## `group_col` target column.

library(testthat)

.gids <- function(df, group_col = NULL, group_by = "auto") {
  gidx <- rtfreporter:::.resolve_group_col(group_col, df)
  rtfreporter:::.compute_group_info(df, gidx, group_by)$id
}

.d_indent <- data.frame(
  V1 = c("Age", "  Mean", "  SD", "Sex", "  F", "  M"), V2 = 1:6,
  stringsAsFactors = FALSE)
.d_value <- data.frame(
  V1 = c("A", "A", "B", "B", "C"), V2 = 1:5, stringsAsFactors = FALSE)
.d_filled <- data.frame(
  V1 = c("GrpA", "", "", "GrpB", ""), V2 = 1:5, stringsAsFactors = FALSE)


# -- mode auto-detection -----------------------------------------------------

test_that(".detect_group_mode picks the mode from column content", {
  expect_identical(rtfreporter:::.detect_group_mode(.d_indent$V1), "indent")
  expect_identical(rtfreporter:::.detect_group_mode(.d_value$V1),  "value")
  expect_identical(rtfreporter:::.detect_group_mode(.d_filled$V1), "filled")
})


# -- each explicit mode ------------------------------------------------------

test_that("indent mode groups by leading whitespace", {
  expect_identical(.gids(.d_indent, group_by = "indent"),
                   c(1L, 1L, 1L, 2L, 2L, 2L))
  # On non-indented data every non-empty row is its own group.
  expect_identical(.gids(.d_value, group_by = "indent"), 1:5)
})

test_that("value mode groups by maximal runs of equal values", {
  expect_identical(.gids(.d_value, group_by = "value"),
                   c(1L, 1L, 2L, 2L, 3L))
})

test_that("filled mode groups a non-empty label with its empty members", {
  expect_identical(.gids(.d_filled, group_by = "filled"),
                   c(1L, 1L, 1L, 2L, 2L))
})


# -- auto resolves to the right mode -----------------------------------------

test_that("auto resolves indent / value / filled from content", {
  expect_identical(.gids(.d_indent), c(1L, 1L, 1L, 2L, 2L, 2L))
  expect_identical(.gids(.d_value),  c(1L, 1L, 2L, 2L, 3L))
  expect_identical(.gids(.d_filled), c(1L, 1L, 1L, 2L, 2L))
})


# -- group_col selects the target column -------------------------------------

test_that("group_col targets a non-first column (by integer)", {
  d <- data.frame(Label = c("x", "y", "z", "w"),
                  Grp   = c("G", "G", "H", "H"), stringsAsFactors = FALSE)
  expect_identical(.gids(d, group_col = 2L, group_by = "value"),
                   c(1L, 1L, 2L, 2L))
})


# -- end-to-end through as_rtftables() ---------------------------------------

test_that("as_rtftables(group_by=) drives group_safe pagination", {
  # value grouping: two 2-row groups + one 1-row group; max_rows = 2 keeps
  # whole groups together -> 3 pages.
  pages <- as_rtftables(.d_value, split = "group_safe", max_rows = 2,
                        group_by = "value")
  expect_length(pages, 3L)
})

test_that("as_rtftables(group_by='filled') keeps a label with its members", {
  pages <- as_rtftables(.d_filled, split = "group_safe", max_rows = 3,
                        group_by = "filled")
  # GrpA (3 rows) fills page 1; GrpB (2 rows) -> page 2.
  expect_length(pages, 2L)
})

test_that("group_by default ('auto') is backward compatible for indent tables", {
  auto <- as_rtftables(.d_indent, split = "group_safe", max_rows = 4)
  ind  <- as_rtftables(.d_indent, split = "group_safe", max_rows = 4,
                       group_by = "indent")
  expect_identical(length(auto), length(ind))
})


# -- validation --------------------------------------------------------------

test_that("an unknown group_by is rejected", {
  expect_error(as_rtftables(.d_value, split = "group_safe", max_rows = 2,
                            group_by = "nonsense"))
})
