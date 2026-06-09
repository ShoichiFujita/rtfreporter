# as_rtftables(split = <function>): custom pagination + add_cont_label() helper.

.df9 <- function() {
  data.frame(
    label = c("A", " a1", " a2", "B", " b1", " b2", "C", " c1", " c2"),
    value = as.character(1:9),
    stringsAsFactors = FALSE
  )
}

test_that("a custom split function drives pagination and page count", {
  df <- .df9()
  # Split into fixed blocks of 3 rows.
  by3 <- function(d, ...) split(d, (seq_len(nrow(d)) - 1L) %/% 3L)
  pages <- as_rtftables(df, split = by3)
  expect_length(pages, 3L)
  expect_true(all(vapply(pages, function(p) inherits(p, "rtftable"),
                         logical(1L))))
  expect_equal(nrow(pages[[1L]]$data), 3L)
})

test_that("custom split receives context args (max_rows) and can use them", {
  df <- .df9()
  seen <- NULL
  by_n <- function(d, max_rows = NULL, ...) {
    seen <<- max_rows
    n <- if (is.null(max_rows)) nrow(d) else max_rows
    split(d, (seq_len(nrow(d)) - 1L) %/% n)
  }
  pages <- as_rtftables(df, split = by_n, max_rows = 4L)
  expect_identical(seen, 4L)
  # 9 rows / 4 -> pages of 4, 4, 1
  expect_length(pages, 3L)
})

test_that("a named list from a custom split becomes page names", {
  df <- .df9()
  # Group by the leading non-space label (LOCF down the indented sub-rows).
  by_group <- function(d, ...) {
    key <- ifelse(grepl("^[^ ]", d$label), d$label, NA_character_)
    for (i in seq_along(key)) if (is.na(key[i]) && i > 1L) key[i] <- key[i - 1L]
    split(d, factor(key, levels = unique(key)))
  }
  pages <- as_rtftables(df, split = by_group)
  expect_length(pages, 3L)
  expect_setequal(names(pages), c("A", "B", "C"))
})

test_that("custom split must return a non-empty list of data.frames", {
  df <- .df9()
  expect_error(as_rtftables(df, split = function(d, ...) d),
               "data.frames")
  expect_error(as_rtftables(df, split = function(d, ...) list()),
               "non-empty")
  expect_error(as_rtftables(df, split = function(d, ...) list(1, 2)),
               "data.frames")
})

# ── add_cont_label() ─────────────────────────────────────────────────────────

test_that("add_cont_label prepends a labelled blank row", {
  df  <- data.frame(g = c("B", "B"), v = c("3", "4"), stringsAsFactors = FALSE)
  out <- add_cont_label(df, label = "Group B")
  expect_equal(nrow(out), 3L)
  expect_identical(out$g[1L], "Group B (Cont.)")
  expect_identical(out$v[1L], "")            # other cells blanked
  expect_identical(out$g[-1L], df$g)         # original rows preserved
})

test_that("add_cont_label honours col and cont_label, and validates input", {
  df  <- data.frame(a = "x", b = "y", stringsAsFactors = FALSE)
  out <- add_cont_label(df, "Lab", cont_label = " (continued)", col = "b")
  expect_identical(out$b[1L], "Lab (continued)")
  expect_identical(out$a[1L], "")

  expect_error(add_cont_label(list(), "x"), "must be a data.frame")
  expect_error(add_cont_label(df, c("a", "b")), "single string")
  expect_error(add_cont_label(df, "x", col = "nope"), "not found")
  expect_error(add_cont_label(df, "x", col = 9L), "out of range")
})

test_that("add_cont_label round-trips inside a custom split", {
  df <- .df9()
  by4_cont <- function(d, cont_label = " (Cont.)", ...) {
    parts <- split(d, (seq_len(nrow(d)) - 1L) %/% 4L)
    for (i in seq_along(parts)) {
      if (i > 1L) {
        parts[[i]] <- add_cont_label(parts[[i]], "Continued",
                                     cont_label = cont_label)
      }
    }
    parts
  }
  pages <- as_rtftables(df, split = by4_cont)
  expect_length(pages, 3L)
  expect_identical(pages[[2L]]$data[[1L]][1L], "Continued (Cont.)")
})
