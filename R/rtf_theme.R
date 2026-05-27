# ============================================================================
#  rtf_theme — shared mutable theme (R6, optional)
# ============================================================================
#
#  This is the ONE place in `rtfreporter` where R6 is the right tool.
#  Everything else is S3 (see LEARNING.md).  The rest of the package works
#  without R6 installed; `rtf_theme()` is an *optional* feature gated on
#  the `R6` package being available (declared in DESCRIPTION as Suggests).
#
#  Why R6 here and only here
#  -------------------------
#  An rtf_theme is meant to be *shared by many tables* AND *mutated after
#  construction*, with the change taking effect at the next render.
#
#      theme <- rtf_theme(header_bold = FALSE)
#      tbls  <- lapply(dfs, function(df) rtftable(df, theme = theme))
#      # render → headers are not bold
#
#      theme$header_bold <- TRUE       # one in-place mutation
#      # render → every table picks the change up because each rtftable
#      # holds an R6 *reference* to `theme`, not a snapshot
#
#  With S3 lists, mutating `theme$header_bold` after construction would
#  only update the local binding; every rtftable that had snapshotted
#  the value at build time would keep the old default.  R6's reference
#  semantics make the broadcast pattern trivial.
#
#  How it is wired into the renderer
#  ---------------------------------
#  `rtftable()` accepts `theme =` in addition to the regular `style =`
#  argument.  When a theme is given:
#
#    * the rtftable stores the R6 reference in `tbl$theme` and the raw
#      construction kwargs in `tbl$.raw_args`;
#    * at render time `.refresh_theme(tbl)` rebuilds the rtftable from
#      the *current* theme state by re-running the constructor with
#      `style = theme$as_style()` and the cached kwargs.
#
#  Explicit kwargs always beat the theme; e.g. an explicit
#  `col_header_align = "center"` survives any later theme mutation.
#
#  ============================================================================

#' Shared mutable theme (R6 — optional)
#'
#' `rtf_theme` is an R6 class whose instances are designed to be *shared by
#' many tables* and *mutated in place* — every table that holds the same
#' theme reference picks up the new defaults at the next render.  It is
#' the only R6 object in `rtfreporter`; everything else is S3.
#'
#' Field names match [rtf_table_style()] one-for-one.
#'
#' @section R6 is optional:
#' `rtf_theme()` is gated on the suggested `R6` package being installed.
#' If it is not, an informative error is raised.  Users who do not need
#' shared mutable themes do not need to install `R6` at all — the rest
#' of `rtfreporter` runs without it.
#'
#' @param ... Initial field values (same names as [rtf_table_style()]).
#'
#' @return An R6 object of class `rtf_theme`.
#'
#' @seealso
#'   * [rtf_table_style()] — the S3 equivalent (snapshot semantics).
#'   * [rtftable()] — accepts `theme =` to attach an `rtf_theme`.
#'   * `vignette("class-systems", package = "rtfreporter")` for the
#'     S3-vs-R6 design notes.
#'
#' @examples
#' \dontrun{
#' theme <- rtf_theme(header_bold = FALSE)
#'
#' t1 <- rtftable(df1, theme = theme)
#' t2 <- rtftable(df2, theme = theme)
#'
#' # Both tables render with header_bold = FALSE …
#'
#' theme$header_bold <- TRUE
#'
#' # … now both render with header_bold = TRUE, no rebuild needed.
#' }
#'
#' @export
rtf_theme <- function(...) {
  if (!requireNamespace("R6", quietly = TRUE)) {
    stop(
      "`rtf_theme()` requires the `R6` package.  Install it with ",
      "`install.packages(\"R6\")`.  All other rtfreporter features work ",
      "without R6.",
      call. = FALSE
    )
  }
  .rtf_theme_class$new(...)
}

# Internal R6 generator.  Lives behind an exported function so we can
# load this file even when R6 is not installed (the class is created
# lazily at the first rtf_theme() call below).
.rtf_theme_class <- NULL

.init_rtf_theme_class <- function() {
  if (!is.null(.rtf_theme_class)) return(invisible(NULL))
  if (!requireNamespace("R6", quietly = TRUE)) return(invisible(NULL))

  .rtf_theme_class <<- R6::R6Class(
    classname = "rtf_theme",
    public = list(
      # ── Zone borders ────────────────────────────────────────────────
      border_header    = NULL,
      border_spanning  = NULL,
      border_body      = NULL,
      border_first_row = NULL,
      border_last_row  = NULL,

      # ── Column-header text defaults ────────────────────────────────
      header_align  = NULL,
      header_bold   = FALSE,
      header_italic = FALSE,

      # ── Data-row text defaults ─────────────────────────────────────
      align     = "left",
      bold      = FALSE,
      italic    = FALSE,
      underline = FALSE,

      # ── Cell metrics ───────────────────────────────────────────────
      cell_padding_left_twips  = NULL,
      cell_padding_right_twips = NULL,
      row_height_twips         = NULL,

      initialize = function(
        border_header    = NULL,
        border_spanning  = NULL,
        border_body      = NULL,
        border_first_row = NULL,
        border_last_row  = NULL,
        header_align     = NULL,
        header_bold      = FALSE,
        header_italic    = FALSE,
        align            = "left",
        bold             = FALSE,
        italic           = FALSE,
        underline        = FALSE,
        cell_padding_left_twips  = NULL,
        cell_padding_right_twips = NULL,
        row_height_twips         = NULL
      ) {
        .check_border <- function(b, nm) {
          if (!is.null(b) && !inherits(b, "rtf_border")) {
            stop(sprintf("`%s` must be NULL or an rtf_border object.", nm),
                 call. = FALSE)
          }
        }
        .check_border(border_header,    "border_header")
        .check_border(border_spanning,  "border_spanning")
        .check_border(border_body,      "border_body")
        .check_border(border_first_row, "border_first_row")
        .check_border(border_last_row,  "border_last_row")

        self$border_header    <- border_header
        self$border_spanning  <- border_spanning
        self$border_body      <- border_body
        self$border_first_row <- border_first_row
        self$border_last_row  <- border_last_row

        self$header_align  <- header_align
        self$header_bold   <- isTRUE(header_bold)
        self$header_italic <- isTRUE(header_italic)

        self$align     <- align
        self$bold      <- isTRUE(bold)
        self$italic    <- isTRUE(italic)
        self$underline <- isTRUE(underline)

        self$cell_padding_left_twips  <- cell_padding_left_twips
        self$cell_padding_right_twips <- cell_padding_right_twips
        self$row_height_twips         <- row_height_twips

        invisible(self)
      },

      # Snapshot the theme's current state as an immutable S3 rtf_table_style.
      # Called by the renderer at every render to materialise the
      # currently-effective defaults.
      as_style = function() {
        rtf_table_style(
          border_header    = self$border_header,
          border_spanning  = self$border_spanning,
          border_body      = self$border_body,
          border_first_row = self$border_first_row,
          border_last_row  = self$border_last_row,
          header_align     = self$header_align,
          header_bold      = self$header_bold,
          header_italic    = self$header_italic,
          align            = self$align,
          bold             = self$bold,
          italic           = self$italic,
          underline        = self$underline,
          cell_padding_left_twips  = self$cell_padding_left_twips,
          cell_padding_right_twips = self$cell_padding_right_twips,
          row_height_twips         = self$row_height_twips
        )
      },

      print = function(...) {
        cat("<rtf_theme (R6 — shared mutable)>\n")
        cat("  borders:\n")
        for (z in c("header", "spanning", "body", "first_row", "last_row")) {
          v <- self[[paste0("border_", z)]]
          cat(sprintf("    %-10s: %s\n", z,
                      if (is.null(v)) "none" else "<rtf_border>"))
        }
        cat(sprintf("  header_align : %s\n",
                    if (is.null(self$header_align)) "(inherit align)"
                    else self$header_align))
        cat(sprintf("  header_bold  : %s\n", self$header_bold))
        cat(sprintf("  align        : %s\n", self$align))
        cat(sprintf("  bold         : %s\n", self$bold))
        invisible(self)
      }
    )
  )
  invisible(NULL)
}

# Initialise on package load if R6 is available.  `.onLoad()` is in zzz.R.

#' Clinical TFL preset (R6 theme)
#'
#' R6 equivalent of [rtf_table_style_tfl()].  Returns a freshly constructed
#' `rtf_theme` matching the standard clinical TFL preset; mutate its fields
#' to broadcast the change to every referencing table.
#'
#' @return An `rtf_theme` (R6) object.
#' @export
rtf_theme_tfl <- function() {
  s <- rtf_border_side()
  rtf_theme(
    border_header = rtf_border(top = s, bottom = s),
    header_bold   = FALSE,
    header_align  = NULL
  )
}

# Internal: rebuild an rtftable from its cached construction kwargs and
# the *current* state of its attached theme.  Called once per render of
# each rtftable in generate_rtfreport.R.
.refresh_theme <- function(tbl) {
  if (is.null(tbl$theme) || is.null(tbl$.raw_args)) return(tbl)
  theme <- tbl$theme
  raw   <- tbl$.raw_args
  raw$data  <- if (!is.null(tbl$data)) tbl$data else tbl$data_list
  raw$style <- theme$as_style()
  raw$theme <- NULL                       # break recursion
  result <- do.call(.new_rtftable, raw)
  result$theme    <- theme                # carry the reference forward
  result$.raw_args <- tbl$.raw_args       # keep the original raw args
  result
}
