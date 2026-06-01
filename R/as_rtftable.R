#' Convert a gt or gtsummary object to an rtftable
#'
#' Bridges the [gt](https://gt.rstudio.com) and
#' [gtsummary](https://www.danieldsjoberg.com/gtsummary/) packages with
#' rtfreporter.  Accepts a `gt_tbl` built with gt's API, **or** any
#' gtsummary table (`tbl_summary`, `tbl_regression`, `tbl_merge`,
#' `tbl_stack`, etc.).
#'
#' When a gtsummary object is supplied, it is first converted to a `gt_tbl`
#' via `gtsummary::as_gt()`, after which the standard gt extraction logic
#' applies.  All options documented below work identically for both input
#' types.
#'
#' @section What is extracted from the gt_tbl:
#'
#' When `read = TRUE` (default), the following gt attributes are read
#' and used to fill in rtftable defaults:
#'
#' \describe{
#'   \item{column labels (`col_header`)}{from `gt_obj[["_boxhead"]]$column_label`.}
#'   \item{per-column alignment (`alignment`)}{from
#'     `gt_obj[["_boxhead"]]$column_align` -> `col_spec[[j]]$align`.}
#'   \item{multi-level spanning headers (`spanning`)}{from
#'     `gt_obj[["_spanners"]]` -> stacked spanner rows above the
#'     column labels in `col_header`.}
#'   \item{per-column widths (`widths`)}{from
#'     `gt_obj[["_boxhead"]]$column_width` -> `column_widths_twips`
#'     (px -> twips at 96 dpi) or `col_rel_width` (%).  Mixed-unit or
#'     partial widths are skipped.}
#'   \item{hidden columns (`hidden`)}{columns whose
#'     `gt_obj[["_boxhead"]]$type == "hidden"` are dropped from the
#'     extracted data.frame, the labels, the alignment, and the
#'     spanner column-index mapping.}
#' }
#'
#' Title / subtitle and source notes also live on the `gt_tbl`, but
#' they map to page-level slots in rtfreporter (`titles[[i]]` and
#' `footnotes[[i]]`), not to the rtftable itself.  Use `read_gt = TRUE`
#' on [rtf_tables()] to pull them through automatically -- or pass them
#' explicitly via [rtf_titles()] / [rtf_footnotes()].
#'
#' @section Granular control:
#'
#' Pass `read = c(...)` with one or more of the following tokens
#' instead of `TRUE` to opt in selectively:
#'
#' * `"col_header"`   -- column labels
#' * `"alignment"`    -- per-column alignment
#' * `"spanning"`     -- multi-level spanner header rows
#' * `"widths"`       -- per-column widths
#' * `"hidden"`       -- drop hidden columns
#'
#' (`"titles"` and `"source_notes"` are recognised but apply at the
#' [rtf_tables()] level, not here.)
#'
#' `read = FALSE` is equivalent to `as.data.frame(gt_obj) |> rtftable(...)`.
#'
#' @section gtsummary limitations:
#'
#' gtsummary tables are converted via `gtsummary::as_gt()`.  The
#' conversion is faithful for cell *content* (formatted strings) and
#' structural metadata (column labels, spanning headers, titles, footnotes,
#' hidden columns, stub/group rows).  The following gtsummary features are
#' **not** carried through to RTF because they depend on HTML/CSS styling
#' that rtfreporter cannot translate:
#'
#' \itemize{
#'   \item **Row indentation** -- hierarchical variable nesting rendered via
#'     `padding-left` in HTML.  Rows appear flat in RTF.
#'   \item **Bold group-header rows** -- applied via `tab_style()` in the
#'     gt object's `_styles` slot, which the current adapter does not read.
#'   \item **Footnote anchor marks in cells** -- the footnote *texts* are
#'     extracted and placed in the page footnote block, but the superscript
#'     glyph (e.g. ¹) inside the data cell is not injected.
#'   \item **Raw HTML tags** (`<br>`, `<span>`, etc.) embedded in cell
#'     values by gtsummary may appear verbatim in the RTF output.
#' }
#'
#' @param gt_obj A `gt_tbl` object (from the gt package) **or** any
#'   gtsummary table object (e.g. the result of `tbl_summary()`,
#'   `tbl_regression()`, `tbl_merge()`, `tbl_stack()`, etc.).
#' @param read `TRUE` (default), `FALSE`, or a character vector of
#'   tokens listed above.  Controls which gt attributes are read.
#' @param ... Passed to [rtftable()].  Explicit values always win
#'   over the gt-extracted ones.
#'
#' @return An `rtftable` S3 object.
#'
#' @examples
#' \dontrun{
#' library(gt)
#'
#' g <- gt(head(mtcars, 5)) |>
#'   cols_label(mpg = "MPG", cyl = "Cyl") |>
#'   cols_align("right", columns = c(mpg, cyl))
#'
#' tbl <- as_rtftable(g)
#'
#' # ---- gtsummary example ----
#' library(gtsummary)
#'
#' s <- trial |>
#'   select(age, grade, response, trt) |>
#'   tbl_summary(by = trt) |>
#'   add_p()
#'
#' tbl2 <- as_rtftable(s)   # gtsummary -> gt -> rtftable automatically
#'
#' doc <- rtf_document() |>
#'   rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) |>
#'   rtf_tables(list(tbl2))
#'
#' generate_rtfreport(doc, "output.rtf", overwrite = TRUE)
#' }
#'
#' @seealso [rtf_tables()] -- accepts `gt_tbl` and gtsummary objects
#'   directly with `read_gt =` for title / subtitle / source-note
#'   flow-through.
#'
#' @export
as_rtftable <- function(gt_obj, read = TRUE, ...) {
  # Accept gtsummary tables: convert to gt first, then proceed as normal.
  if (.is_gtsummary_tbl(gt_obj)) {
    gt_obj <- .gtsummary_to_gt(gt_obj)
  }
  if (!.is_gt_tbl(gt_obj)) {
    stop("`gt_obj` must be a gt_tbl or a gtsummary table object.", call. = FALSE)
  }
  if (!requireNamespace("gt", quietly = TRUE)) {
    stop("`as_rtftable()` requires the `gt` package.  Install it with ",
         "install.packages(\"gt\").", call. = FALSE)
  }

  tokens     <- .resolve_gt_tokens(read)
  gt_kwargs  <- .gt_to_rtftable_kwargs(gt_obj, tokens = tokens)
  user_args  <- list(...)

  # data: gt-derived data.frame is what we use.  No way to override
  # without breaking the abstraction.
  call_args <- list(data = gt_kwargs$data)

  # col_header: prefer user, fall back to gt.
  if (!is.null(user_args$col_header)) {
    call_args$col_header <- user_args$col_header
  } else if (!is.null(gt_kwargs$col_header)) {
    call_args$col_header <- gt_kwargs$col_header
  }

  # col_spec: deep-merge per-column.  Each user col_spec entry wins for
  # the fields it specifies; gt's `align` fills the gaps.
  if (!is.null(gt_kwargs$col_spec) || !is.null(user_args$col_spec)) {
    call_args$col_spec <- .merge_col_spec(user_args$col_spec,
                                          gt_kwargs$col_spec)
  }

  # Phase B width fields: prefer user, fall back to gt.
  for (k in c("column_widths_twips", "col_rel_width")) {
    if (!is.null(user_args[[k]])) {
      call_args[[k]] <- user_args[[k]]
    } else if (!is.null(gt_kwargs[[k]])) {
      call_args[[k]] <- gt_kwargs[[k]]
    }
  }

  # Phase D: cell_styles -- prefer user, fall back to gt-extracted.
  if (!is.null(user_args$cell_styles)) {
    call_args$cell_styles <- user_args$cell_styles
  } else if (!is.null(gt_kwargs$cell_styles)) {
    call_args$cell_styles <- gt_kwargs$cell_styles
  }

  # All other arguments pass through verbatim.
  consumed <- c("data", "col_header", "col_spec",
                "column_widths_twips", "col_rel_width", "cell_styles")
  for (k in setdiff(names(user_args), consumed)) {
    call_args[[k]] <- user_args[[k]]
  }

  do.call(rtftable, call_args)
}


# Per-column merge of col_spec lists.  `user` wins for any field it
# specifies; missing fields fall back to the corresponding entry in
# `gt`.  Either argument may be NULL.
.merge_col_spec <- function(user, gt) {
  if (is.null(user)) return(gt)
  if (is.null(gt))   return(user)

  # Build a hash keyed by `col` (numeric index or character name) so we
  # can merge entries that target the same column.
  key <- function(e) {
    if (is.null(e$col)) "" else paste0("col:", as.character(e$col))
  }
  merged <- list()
  for (e in gt) merged[[key(e)]] <- e
  for (e in user) {
    k <- key(e)
    if (!is.null(merged[[k]])) {
      # Per-field merge: user overrides gt for matching keys.
      base <- merged[[k]]
      for (f in setdiff(names(e), "col")) base[[f]] <- e[[f]]
      merged[[k]] <- base
    } else {
      merged[[k]] <- e
    }
  }
  unname(merged)
}
