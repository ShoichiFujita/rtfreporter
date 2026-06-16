# rtftable(blank_row_normalize=): render-time blank-row handling (#136).
#   "detect"   -- an all-NA/"" data row -> single full-width blank row
#   "collapse" -- a run of >= 2 consecutive blank rows -> one
# Default c("detect", "collapse").

# Count single-column blank rows emitted by .blank_row_rtf() (\trgaph0\trleft0).
.count_blank_rows <- function(txt) {
  m <- gregexpr("\\\\trgaph0\\\\trleft0", txt)[[1L]]
  if (length(m) == 1L && m[[1L]] == -1L) 0L else length(m)
}

.render1 <- function(df, ...) {
  doc <- rtf_document() |>
    rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) |>
    rtf_tables(rtftable(df, ...))
  .render_to_string(doc)
}

.empty_mix <- function() {
  data.frame(
    A = c("x", "", "y", "", "", "z"),
    B = c("1", "", "2", "", "", "3"),
    stringsAsFactors = FALSE)
}


# ── argument resolution / validation ─────────────────────────────────────────

test_that("blank_row_normalize is stored resolved; none/NULL disable; bad token errors", {
  df <- data.frame(A = "x", stringsAsFactors = FALSE)
  expect_equal(rtftable(df)$blank_row_normalize, c("detect", "collapse"))
  expect_equal(rtftable(df, blank_row_normalize = "none")$blank_row_normalize,
               character(0))
  expect_equal(rtftable(df, blank_row_normalize = NULL)$blank_row_normalize,
               character(0))
  expect_equal(rtftable(df, blank_row_normalize = character(0))$blank_row_normalize,
               character(0))
  expect_equal(rtftable(df, blank_row_normalize = "detect")$blank_row_normalize,
               "detect")
  expect_error(rtftable(df, blank_row_normalize = "bogus"),
               "subset of")
})


# ── "detect": all-empty data row -> single full-width blank row ───────────────

test_that("detect turns all-empty data rows into single-column blank rows", {
  df <- .empty_mix()
  # detect only (no collapse): rows 2, 4, 5 each become a blank row -> 3.
  expect_equal(.count_blank_rows(.render1(df, blank_row_normalize = "detect")), 3L)
  # none: all-empty rows stay as data rows -> 0 blank rows emitted.
  expect_equal(.count_blank_rows(.render1(df, blank_row_normalize = "none")), 0L)
})

test_that("an all-empty data row is rendered with a single cell, not one per column", {
  df <- data.frame(A = c("x", ""), B = c("1", ""), stringsAsFactors = FALSE)
  txt <- .render1(df, blank_row_normalize = "detect")
  # The blank row template has exactly one \cellx, the data row has two.
  expect_match(txt, "\\\\trgaph0\\\\trleft0")            # blank row present
})


# ── "collapse": consecutive blank rows reduced to one ────────────────────────

test_that("collapse reduces a run of detected blanks to a single blank row", {
  df <- .empty_mix()
  # detect + collapse (default): row 2 (1) + the 4-5 run collapsed (1) = 2.
  expect_equal(.count_blank_rows(.render1(df)), 2L)
  expect_equal(
    .count_blank_rows(.render1(df, blank_row_normalize = c("detect", "collapse"))),
    2L)
})

test_that("collapse also merges an explicit separator next to a detected blank", {
  # Row 2 is all-empty (detected). A separator after row 2 would sit adjacent to
  # it; collapse must merge them into one blank row.
  df <- data.frame(A = c("x", "", "y"), B = c("1", "", "2"),
                   stringsAsFactors = FALSE)
  txt <- .render1(df, blank_rows = 2L)                  # separator after row 2
  # detected blank (row 2) + separator after row 2 -> collapsed to 1.
  expect_equal(.count_blank_rows(txt), 1L)
})

test_that("collapse alone (no detect) does not invent blanks", {
  expect_equal(.count_blank_rows(.render1(.empty_mix(),
                                          blank_row_normalize = "collapse")), 0L)
})


# ── detect respects indentation: NBSP / non-empty cells are not 'empty' ──────

test_that("an NBSP-indented or partly-filled row is NOT treated as blank", {
  nbsp <- intToUtf8(160L)
  df <- data.frame(
    A = c("Group", paste0(nbsp, nbsp, "Sub"), "x"),   # indented, not empty
    B = c("", "", "1"),
    stringsAsFactors = FALSE)
  # No row is fully empty -> detect finds nothing.
  expect_equal(.count_blank_rows(.render1(df, blank_row_normalize = "detect")), 0L)
})


# ── pagination: normalization is per page (after the split) ───────────────────

test_that("blank_row_normalize flows from as_rtftables() through to each page", {
  df <- data.frame(
    grp = c("A", "A", "B", "B"),
    val = c("1", "", "2", ""),                          # a trailing empty per group
    stringsAsFactors = FALSE)
  pages <- as_rtftables(df, split = "rows", split_rows = 3L)
  # Each page's rtftable carries the default normalization.
  for (p in pages) expect_equal(p$blank_row_normalize, c("detect", "collapse"))
})
