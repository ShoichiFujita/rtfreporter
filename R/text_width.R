# text_width.R — Font-aware text width estimation for column sizing.
#
# Provides:
#   text_width_in()   — estimated display width of a string in inches
#   auto_col_widths() — suggested column widths (twips) for a data.frame

# Courier New character widths at 12pt in points.
# All characters are equal-width (monospace), so a single constant is used.
.COURIER_CHAR_W_PT_AT_12 <- 7.22

# Arial approximate average character width at 12pt in points.
# This is a simplified constant; for production use consider a per-glyph table.
.ARIAL_CHAR_W_PT_AT_12 <- 6.0

# Internal: character width in inches for one character.
.char_width_in <- function(font_lower, size_pt) {
  base_w <- switch(font_lower,
    courier     = .COURIER_CHAR_W_PT_AT_12,
    courier_new = .COURIER_CHAR_W_PT_AT_12,
    arial       = .ARIAL_CHAR_W_PT_AT_12,
    .COURIER_CHAR_W_PT_AT_12            # fallback: treat as Courier
  )
  (base_w * size_pt / 12) / 72          # scale to size, convert pt → inches
}


#' Estimate the display width of a text string
#'
#' Returns an estimated display width in **inches** for a character string
#' rendered in the given font and size.  For Courier New (monospace) the
#' estimate is reliable; for proportional fonts (Arial) it is an average-width
#' approximation.
#'
#' @param text A character vector.  `NA` is treated as `""`.
#' @param font Font name.  One of `"courier_new"` (default), `"courier"`, or
#'   `"arial"`.  Unrecognised values fall back to Courier New.
#' @param size_half_points Font size in **half-points** (the unit used by RTF
#'   and `rtfreport$new()`).  Default `18` = 9 pt.
#'
#' @return A numeric vector of estimated widths in inches (same length as
#'   `text`).
#'
#' @examples
#' text_width_in("Hello, World!")          # ~0.88 inches at 9pt Courier New
#' text_width_in("abc", size_half_points = 24)   # 12pt
#'
#' @export
text_width_in <- function(text, font = "courier_new", size_half_points = 18L) {
  text <- ifelse(is.na(text), "", as.character(text))
  size_pt  <- as.numeric(size_half_points) / 2
  char_w   <- .char_width_in(tolower(font), size_pt)
  nchar(text, type = "chars") * char_w
}


#' Automatically calculate column widths for a data.frame
#'
#' Scans the content of each column (header labels and data values) to derive
#' suggested column widths in **twips**.  The widths can be passed directly to
#' [rtftable()]'s `column_widths_twips` argument.
#'
#' @param df A `data.frame`.
#' @param col_header Column header labels.  `NULL` (default) uses `names(df)`.
#'   Accepts the same formats as `rtftable(col_header = ...)`: a character
#'   vector, a pipe-delimited string, or a list of character vectors (only the
#'   first row is used for width estimation).
#' @param font Font name passed to [text_width_in()].  Default `"courier_new"`.
#' @param size_half_points Font size in half-points.  Default `18` (= 9 pt).
#' @param table_width_twips If not `NULL`, the column widths are scaled so that
#'   their sum equals this value.  Useful for fitting tables to a fixed page
#'   width.
#' @param min_col_width_twips Minimum width per column in twips.  Default
#'   `720` (= 0.5 inch).
#' @param col_padding_twips Extra twips added to each column width to account
#'   for cell padding and inter-column spacing.  Default `288` (= 0.2 inch).
#'
#' @return An integer vector of column widths in twips, one per column of `df`.
#'
#' @examples
#' df <- data.frame(
#'   USUBJID  = c("SUBJ-001", "SUBJ-002"),
#'   TREATMENT = c("Placebo", "Active"),
#'   AGE      = c(45L, 62L)
#' )
#' widths <- auto_col_widths(df, table_width_twips = 14400L)
#' tbl <- rtftable$new(df, column_widths_twips = widths)
#'
#' @export
auto_col_widths <- function(df,
                             col_header         = NULL,
                             font               = "courier_new",
                             size_half_points   = 18L,
                             table_width_twips  = NULL,
                             min_col_width_twips = 720L,
                             col_padding_twips  = 288L) {
  if (!is.data.frame(df)) stop("`df` must be a data.frame.", call. = FALSE)
  ncols   <- ncol(df)
  size_pt <- as.numeric(size_half_points) / 2

  # Resolve header labels (use first row when multi-row).
  hdr_labels <- if (is.null(col_header)) {
    names(df)
  } else {
    # Normalize: pipe string → char vector; list → first row.
    h <- col_header
    if (is.character(h) && length(h) == 1L && grepl("|", h, fixed = TRUE)) {
      h <- trimws(strsplit(h, "|", fixed = TRUE)[[1]])
    }
    if (is.list(h)) h <- h[[1L]]     # first header row only
    h
  }
  if (length(hdr_labels) < ncols) {
    hdr_labels <- c(hdr_labels, rep("", ncols - length(hdr_labels)))
  }

  # Maximum content width per column (header vs data), in inches.
  char_w <- .char_width_in(tolower(font), size_pt)
  col_max_in <- vapply(seq_len(ncols), function(j) {
    hdr_w  <- nchar(as.character(hdr_labels[j] %||% ""), type = "chars") * char_w
    data_w <- max(0, nchar(as.character(df[[j]]), type = "chars") * char_w,
                  na.rm = TRUE)
    max(hdr_w, data_w)
  }, numeric(1L))

  # Convert to twips and add padding.
  col_w <- as.integer(round(col_max_in * 1440)) + as.integer(col_padding_twips)
  col_w <- pmax(col_w, as.integer(min_col_width_twips))

  # Scale to table_width_twips when requested.
  if (!is.null(table_width_twips)) {
    total_w <- as.integer(table_width_twips)
    total_natural <- sum(col_w)
    if (total_natural > 0L) {
      col_w <- as.integer(round(col_w * total_w / total_natural))
      # Absorb rounding drift in the last column.
      col_w[ncols] <- total_w - sum(col_w[-ncols])
      col_w <- pmax(col_w, as.integer(min_col_width_twips))
    }
  }

  col_w
}
