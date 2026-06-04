# ============================================================================
#  Pluggable cell-format functions
# ============================================================================
#
#  `as_rtftables(cell_format = )` lets you re-format the *body cells* of a
#  table column-by-column just before pagination -- typically to line numbers
#  up in a monospaced clinical layout.
#
#  ---------------------------------------------------------------------------
#  THE CONTRACT (how to write your own format function)
#  ---------------------------------------------------------------------------
#  A cell-format function takes ONE table column and returns the reformatted
#  column:
#
#      function(x, nbsp = "\u00a0") -> character
#
#    * `x`   : a character vector -- the cells of a single column.
#    * value : a character vector of the SAME length as `x`.
#
#  Rules:
#    * Return the same length you were given (one element per row); never drop
#      or add rows.
#    * Cells you do not want to touch (e.g. empty group-label cells, or values
#      that do not match your pattern) must be returned unchanged.
#    * Pad with the non-breaking space `"\u00a0"` (the `nbsp` default), NOT a
#      regular space -- RTF / Word collapse leading and repeated normal spaces,
#      which would undo your alignment.
#    * The function is called once per column (see `cell_format` in
#      [as_rtftables()]); it does not know which column it is, so base any
#      width decisions on `x` alone.
#
#  rtfreporter ships a few ready-made format functions (below).  When none of
#  them fits your data's exact notation, write your own following the rules
#  above and pass it as `cell_format`.
# ============================================================================


#' Right-align the cells of a column to a common width
#'
#' A minimal cell-format function (see *The contract* in the
#' \code{vignette} / [as_rtftables()]): every non-empty cell is right-justified
#' to the width of the widest cell, padding on the left with non-breaking
#' spaces.  Empty cells are left empty.  This is the simplest useful formatter
#' and a good template for writing your own.
#'
#' @param x Character vector (one table column).
#' @param nbsp Padding character; defaults to the non-breaking space
#'   (U+00A0) so RTF / Word keep the alignment.  Pass `" "` for plain text.
#'
#' @return Character vector the same length as `x`.
#'
#' @examples
#' fmt_right_align(c("5", "120", "7"))
#'
#' @seealso [fmt_count_paren()], [realign_count_pct()], and the `cell_format`
#'   argument of [as_rtftables()].
#' @export
fmt_right_align <- function(x, nbsp = "\u00a0") {
  if (length(x) == 0L) return(x)
  x <- as.character(x)
  x[is.na(x)] <- ""
  nz <- nzchar(trimws(x))
  if (!any(nz)) return(x)
  w   <- max(nchar(x[nz]))
  out <- x
  out[nz] <- formatC(x[nz], width = w, flag = "")   # right-justify
  if (!identical(nbsp, " ")) out <- gsub(" ", nbsp, out, fixed = TRUE)
  out
}


# Internal core for the count/percent aligners.  Scans the column, then
# right-justifies the integer count and right-justifies the text inside the
# parentheses, so the count digit and the percentage line up.
#
# `bare` decides whether cells with NO parentheses are touched:
#   * bare = FALSE  -> only "count (...)" cells are reformatted; a lone count
#                      (e.g. "0", or a raw total) is left exactly as-is.
#   * bare = TRUE   -> lone integer counts are ALSO padded into the same count
#                      field so they line up under the parenthetical cells.
# Cells that are not reformatted are returned byte-for-byte unchanged (no
# non-breaking-space substitution).
.fmt_count_core <- function(x, nbsp, bare) {
  if (length(x) == 0L) return(x)
  x <- as.character(x)
  x[is.na(x)] <- ""
  rx <- "^[[:space:]]*([0-9]+)[[:space:]]*(\\((.*)\\))?[[:space:]]*$"
  m  <- regmatches(x, regexec(rx, x))
  count  <- rep(NA_character_, length(x))
  inner  <- rep("", length(x))
  haspar <- rep(FALSE, length(x))
  for (i in seq_along(x)) {
    g <- m[[i]]
    if (length(g) == 4L && nzchar(g[2L])) {
      count[i] <- g[2L]
      if (nzchar(g[3L])) { haspar[i] <- TRUE; inner[i] <- g[4L] }
    }
  }
  do <- !is.na(count) & (haspar | bare)   # which cells we actually reformat
  if (!any(do)) return(x)
  wc <- max(nchar(count[do]))                                   # count width
  wi <- if (any(haspar & do)) max(nchar(inner[haspar & do])) else 0L  # inner width
  full <- wc + if (wi > 0L) (2L + wi + 1L) else 0L              # "<count> (<inner>)"
  out <- x
  for (i in which(do)) {
    cc <- formatC(count[i], width = wc, flag = "")              # right-justify count
    if (haspar[i]) {
      ii  <- formatC(inner[i], width = wi, flag = "")           # right-justify inner
      val <- paste0(cc, " (", ii, ")")
    } else {
      val <- formatC(cc, width = max(full, wc), flag = "-")     # bare count padded
    }
    if (!identical(nbsp, " ")) val <- gsub(" ", nbsp, val, fixed = TRUE)
    out[i] <- val
  }
  out
}

#' Align "count (parenthetical)" cells
#'
#' Aligns clinical cells made of an integer **count** followed by a
#' **parenthetical** part -- e.g. `"69 (80.2%)"`, `"3 (<1%)"`, `"70 (100%)"`.
#' It scans the whole column, then right-justifies the count to the widest
#' count and right-justifies the text *inside* the parentheses to the widest
#' one, so the count digit **and** the percentage line up across rows.
#'
#' Only cells that have parentheses are touched; cells **without** them -- a
#' lone count such as `"0"` or a raw total, a continuous statistic like
#' `"75.2 (8.6)"` whose "count" is not an integer, free text, or empty
#' group-label cells -- are returned **unchanged**.  Use
#' [fmt_count_paren_bare()] if you also want bare integer counts padded into
#' the same column.
#'
#' Unlike the fixed-width [realign_count_pct()] this adapts to the column's
#' actual digit counts and does not care what is *inside* the parentheses,
#' coping with mixed notations like `"(<1%)"`, `"(100%)"` and `"( 2.8%)"` in
#' one column (e.g. tables produced by `tfrmt`).
#'
#' @inheritParams fmt_right_align
#'
#' @return Character vector the same length as `x`.
#'
#' @examples
#' # Only the parenthetical cells are aligned; the lone "0" is left as-is.
#' fmt_count_paren(c("1 (1.2%)", "0", "11 (3.6%)", "108 (35.3%)"))
#'
#' @seealso [fmt_count_paren_bare()], [fmt_right_align()],
#'   [realign_count_pct()], and the `cell_format` argument of [as_rtftables()].
#' @export
fmt_count_paren <- function(x, nbsp = "\u00a0") {
  .fmt_count_core(x, nbsp = nbsp, bare = FALSE)
}

#' Align "count (parenthetical)" cells, including bare counts
#'
#' Like [fmt_count_paren()], but a **bare integer count** with no parentheses
#' (a lone `"0"` for a zero count, or a raw event total) is also padded into
#' the same count field, so it lines up under the parenthetical cells instead
#' of drifting out of line.  Cells that do not start with an integer (text,
#' decimals, empty cells) are still returned unchanged.
#'
#' @inheritParams fmt_right_align
#'
#' @return Character vector the same length as `x`.
#'
#' @examples
#' # The lone "0" is padded to share the column width.
#' fmt_count_paren_bare(c("1 (1.2%)", "0", "11 (3.6%)", "108 (35.3%)"))
#'
#' @seealso [fmt_count_paren()] (parenthetical cells only).
#' @export
fmt_count_paren_bare <- function(x, nbsp = "\u00a0") {
  .fmt_count_core(x, nbsp = nbsp, bare = TRUE)
}


# Internal: resolve the `cell_format` argument into a per-column list of
# functions (length `ncol`; NULL entries = leave the column untouched).
#
#   * a single function -> applied to columns 2..ncol (column 1 is the row
#     label and is left alone, the usual clinical convention);
#   * a list            -> taken positionally, `cell_format[[j]]` for column j
#     (entries that are not functions are ignored).
.resolve_cell_format <- function(cell_format, ncol) {
  if (is.null(cell_format) || ncol < 1L) return(NULL)
  fl <- vector("list", ncol)
  if (is.function(cell_format)) {
    if (ncol >= 2L) for (j in 2:ncol) fl[[j]] <- cell_format
  } else if (is.list(cell_format)) {
    n <- min(length(cell_format), ncol)
    for (j in seq_len(n)) {
      if (is.function(cell_format[[j]])) fl[[j]] <- cell_format[[j]]
    }
  } else {
    stop("`cell_format` must be a function or a list of functions.",
         call. = FALSE)
  }
  fl
}

# Internal: apply a resolved per-column format list to a data.frame's
# character columns.
.apply_cell_format <- function(df, fl) {
  for (j in seq_along(fl)) {
    f <- fl[[j]]
    if (is.function(f) && j <= ncol(df) && is.character(df[[j]])) {
      formatted <- f(df[[j]])
      if (length(formatted) != nrow(df)) {
        stop(sprintf(paste0("A `cell_format` function must return a vector the ",
                            "same length as the column (got %d, expected %d)."),
                     length(formatted), nrow(df)), call. = FALSE)
      }
      df[[j]] <- as.character(formatted)
    }
  }
  df
}
