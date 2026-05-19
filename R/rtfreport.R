# Internal utility: inches to twips.
.in_to_twips <- function(x) {
  as.integer(round(x * 1440))
}

# Internal utility: merge two named lists.
.merge_list <- function(base, override) {
  if (is.null(override)) {
    return(base)
  }
  out <- base
  for (nm in names(override)) {
    out[[nm]] <- override[[nm]]
  }
  out
}

# Internal utility: validate positive integer-like index.
.assert_index <- function(x, max_value, label) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 1L || x > max_value) {
    stop(sprintf("%s is out of range.", label), call. = FALSE)
  }
  as.integer(x)
}

#' Create a header object for a section
#'
#' `rtf_header()` and `rtf_footer()` create structured header/footer objects
#' that can be passed to `add_section()`, `set_section_header()`, or
#' `set_section_footer()`. These objects let you control borders, width, and
#' row height alongside the text content.
#'
#' @param rows A named character vector (single row) or a `list` of named
#'   character vectors (multi-row). Each vector uses names `l`, `c`, `r` for
#'   left, center, right column content. See the Header/Footer section in
#'   `?rtfreport` for column-count rules.
#' @param width_twips Integer. Table width in twips. `NULL` (default) uses the
#'   full writable width (page width minus margins).
#' @param top_border Logical. Whether to draw a top border on the first row.
#'   Default for headers is `FALSE`; default for footers is `TRUE`.
#' @param row_height_twips Integer. Row height in twips. `NULL` (default) reads
#'   the value from `inst/resources/rtfreporter_defaults.R`.
#'
#' @return A named list with elements `rows`, `width_twips`, `top_border`, and
#'   `row_height_twips`.
#'
#' @examples
#' hdr <- rtf_header(
#'   rows = list(
#'     c(l = "Protocol: RTF-101", r = "HOGE company"),
#'     c(l = "Study Title",       r = "Page {AUTO_PAGE} of {TOTAL_PAGES}")
#'   )
#' )
#' ftr <- rtf_footer(c(l = "Confidential"), top_border = TRUE)
#'
#' report <- rtfreport$new()
#' sec <- report$add_section(header = hdr, footer = ftr)
#'
#' @export
rtf_header <- function(rows, width_twips = NULL, top_border = FALSE, row_height_twips = NULL) {
  if (is.character(rows)) rows <- list(rows)
  if (!is.list(rows)) stop("`rows` must be a named character vector or list of named vectors.", call. = FALSE)
  list(
    rows             = rows,
    width_twips      = width_twips,
    top_border       = top_border,
    row_height_twips = row_height_twips
  )
}

#' @rdname rtf_header
#' @export
rtf_footer <- function(rows, width_twips = NULL, top_border = TRUE, row_height_twips = NULL) {
  if (is.character(rows)) rows <- list(rows)
  if (!is.list(rows)) stop("`rows` must be a named character vector or list of named vectors.", call. = FALSE)
  list(
    rows             = rows,
    width_twips      = width_twips,
    top_border       = top_border,
    row_height_twips = row_height_twips
  )
}

#' RTF report object
#'
#' `rtfreport` is an R6 class representing one RTF clinical report. Content is
#' organised in a three-level hierarchy: **document → section → page**.
#'
#' @section Header / Footer format:
#'
#' Headers and footers use a plain named character vector to specify cell
#' content. The names map to alignment:
#'
#' | Name | Alignment |
#' |------|-----------|
#' | `l`  | left      |
#' | `r`  | right     |
#' | `c`  | center    |
#'
#' **Section-level header/footer** (single row, passed directly):
#' ```r
#' add_section(header = c(l = "Protocol", r = "Page {AUTO_PAGE} of {TOTAL_PAGES}"))
#' set_section_footer(sec, c(l = "Confidential"))
#' ```
#'
#' **Object form** with multi-row and border/width control:
#' ```r
#' hdr <- rtf_header(
#'   rows = list(
#'     c(l = "Protocol: RTF-101", r = "Page {AUTO_PAGE} of {TOTAL_PAGES}"),
#'     c(l = "Study Title",       r = "Company Name")
#'   )
#' )
#' ftr <- rtf_footer(c(l = "Confidential - For Clinical Study Use Only"))
#' report$add_section(header = hdr, footer = ftr)
#' ```
#'
#' **Page tokens** available in header/footer text:
#' - `{AUTO_PAGE}` — replaced with `\chpgn` (dynamic page number rendered per page by the RTF viewer).
#' - `{AUTO_TOTAL_PAGES}` — replaced with the RTF `NUMPAGES` field (dynamic total, rendered by the viewer).
#' - `{PAGE}` — replaced with the first page number of the section (static integer at render time).
#' - `{TOTAL_PAGES}` — replaced with the total page count of the document (static integer at render time).
#'
#' @param font_table A list of font definitions. Each element is a list with at
#'   least a `name` element (character string). Default: `list(list(name = "Courier"))`.
#' @param color_table A character vector of hex color codes (e.g. `"#000000"`).
#'   Default: `c("#000000")`.
#' @param default_page A named list of page layout settings. Keys:
#'   `paper`, `orientation`, `width_twips`, `height_twips`,
#'   `margin_top_twips`, `margin_bottom_twips`, `margin_left_twips`,
#'   `margin_right_twips`. Default: letter landscape with 0.75″ top/bottom and
#'   0.5″ left/right margins.
#' @param default_format A named list of text/table formatting defaults. Keys:
#'   `font_index`, `font_size_half_points`, `line_spacing`,
#'   `table_cell_height_twips`.
#'
#' @examples
#' report <- rtfreport$new()
#' sec <- report$add_section(
#'   header = c(l = "Protocol: RTF-101", r = "Page {AUTO_PAGE} of {TOTAL_PAGES}"),
#'   footer = c(l = "Confidential")
#' )
#' report$add_page(sec, title = "Table 1")
#'
#' @export
rtfreport <- R6::R6Class(
  classname = "rtfreport",
  public = list(
    document = NULL,
    sections = NULL,

    initialize = function(
      font_table = NULL,
      color_table = NULL,
      default_page = NULL,
      default_format = NULL
    ) {
      if (is.null(font_table)) {
        font_table <- list(list(name = "Courier"))
      }
      if (is.null(color_table)) {
        color_table <- c("#000000")
      }
      if (is.null(default_page)) {
        default_page <- list(
          paper = "letter",
          orientation = "landscape",
          width_twips = .in_to_twips(11),
          height_twips = .in_to_twips(8.5),
          margin_top_twips = .in_to_twips(0.75),
          margin_bottom_twips = .in_to_twips(0.75),
          margin_left_twips = .in_to_twips(0.5),
          margin_right_twips = .in_to_twips(0.5)
        )
      }
      if (is.null(default_format)) {
        default_format <- list(
          font_index = 0L,
          font_size_half_points = 18L,
          line_spacing = 1L,
          table_cell_height_twips = 240L
        )
      }

      self$document <- list(
        font_table = font_table,
        color_table = color_table,
        default_page = default_page,
        default_format = default_format
      )
      self$sections <- list()
      invisible(self)
    },

    add_section = function(header = NULL, footer = NULL) {
      section <- list(
        header = header,
        footer = footer,
        pages = list()
      )
      self$sections[[length(self$sections) + 1L]] <- section
      length(self$sections)
    },

    get_section = function(section_index) {
      idx <- .assert_index(section_index, length(self$sections), "section_index")
      self$sections[[idx]]
    },

    get_section_header = function(section_index) {
      idx <- .assert_index(section_index, length(self$sections), "section_index")
      self$sections[[idx]]$header
    },

    get_section_footer = function(section_index) {
      idx <- .assert_index(section_index, length(self$sections), "section_index")
      self$sections[[idx]]$footer
    },

    set_section_header = function(section_index, header) {
      idx <- .assert_index(section_index, length(self$sections), "section_index")
      self$sections[[idx]]$header <- header
      invisible(self)
    },

    set_section_footer = function(section_index, footer) {
      idx <- .assert_index(section_index, length(self$sections), "section_index")
      self$sections[[idx]]$footer <- footer
      invisible(self)
    },

    add_page = function(section_index, title = NULL, content = list(), footer_notes = NULL, page_options = NULL) {
      sec_idx <- .assert_index(section_index, length(self$sections), "section_index")

      page <- list(
        title = title,
        content = content,
        footer_notes = footer_notes,
        page_options = page_options
      )
      sec <- self$sections[[sec_idx]]
      sec$pages[[length(sec$pages) + 1L]] <- page
      self$sections[[sec_idx]] <- sec
      length(sec$pages)
    },

    get_page = function(section_index, page_index) {
      sec_idx <- .assert_index(section_index, length(self$sections), "section_index")
      sec <- self$sections[[sec_idx]]
      page_idx <- .assert_index(page_index, length(sec$pages), "page_index")
      sec$pages[[page_idx]]
    },

    set_page_title = function(section_index, page_index, title) {
      sec_idx <- .assert_index(section_index, length(self$sections), "section_index")
      page_idx <- .assert_index(page_index, length(self$sections[[sec_idx]]$pages), "page_index")
      self$sections[[sec_idx]]$pages[[page_idx]]$title <- title
      invisible(self)
    },

    set_page_footer_notes = function(section_index, page_index, footer_notes) {
      sec_idx <- .assert_index(section_index, length(self$sections), "section_index")
      page_idx <- .assert_index(page_index, length(self$sections[[sec_idx]]$pages), "page_index")
      self$sections[[sec_idx]]$pages[[page_idx]]$footer_notes <- footer_notes
      invisible(self)
    },

    set_page_options = function(section_index, page_index, page_options) {
      sec_idx <- .assert_index(section_index, length(self$sections), "section_index")
      page_idx <- .assert_index(page_index, length(self$sections[[sec_idx]]$pages), "page_index")
      self$sections[[sec_idx]]$pages[[page_idx]]$page_options <- page_options
      invisible(self)
    },

    add_block = function(section_index, page_index, block) {
      if (!is.list(block) || is.null(block$type)) {
        stop("`block` must be a list with `type`.", call. = FALSE)
      }
      sec_idx <- .assert_index(section_index, length(self$sections), "section_index")
      page_idx <- .assert_index(page_index, length(self$sections[[sec_idx]]$pages), "page_index")
      page <- self$sections[[sec_idx]]$pages[[page_idx]]
      page$content[[length(page$content) + 1L]] <- block
      self$sections[[sec_idx]]$pages[[page_idx]] <- page
      invisible(self)
    },

    add_table = function(section_index, page_index, data, footer = NULL, metadata = NULL) {
      block <- list(type = "table", data = data, footer = footer, metadata = metadata)
      self$add_block(section_index = section_index, page_index = page_index, block = block)
    },

    add_listing = function(section_index, page_index, data, footer = NULL, metadata = NULL) {
      block <- list(type = "listing", data = data, footer = footer, metadata = metadata)
      self$add_block(section_index = section_index, page_index = page_index, block = block)
    },

    add_figure = function(section_index, page_index, path, footer = NULL, metadata = NULL) {
      if (inherits(path, "rtfplot")) {
        block <- list(type = "figure", data = path, footer = footer, metadata = metadata)
      } else {
        block <- list(type = "figure", path = path, footer = footer, metadata = metadata)
      }
      self$add_block(section_index = section_index, page_index = page_index, block = block)
    },

    add_section_from_dataframes = function(
      data_list,
      section_header = NULL,
      section_footer = NULL,
      page_titles = NULL,
      block_type = "table",
      page_footer_notes = NULL,
      metadata = NULL
    ) {
      if (!is.list(data_list) || length(data_list) == 0L) {
        stop("`data_list` must be a non-empty list.", call. = FALSE)
      }
      if (!block_type %in% c("table", "listing")) {
        stop("`block_type` must be either 'table' or 'listing'.", call. = FALSE)
      }

      sec_idx <- self$add_section(header = section_header, footer = section_footer)
      n_items <- length(data_list)

      if (is.null(page_titles)) {
        nm <- names(data_list)
        if (!is.null(nm) && length(nm) == n_items && any(nzchar(nm))) {
          page_titles <- nm
        } else {
          default_prefix <- if (block_type == "listing") "Listing" else "Table"
          page_titles <- paste0(default_prefix, " ", seq_len(n_items))
        }
      } else if (length(page_titles) == 1L && n_items > 1L) {
        page_titles <- rep(page_titles, n_items)
      } else if (length(page_titles) != n_items) {
        stop("`page_titles` must have length 1 or match `data_list`.", call. = FALSE)
      }

      if (is.null(page_footer_notes)) {
        page_footer_notes <- rep(list(NULL), n_items)
      } else if (is.list(page_footer_notes)) {
        if (length(page_footer_notes) == 1L && n_items > 1L) {
          page_footer_notes <- rep(page_footer_notes, n_items)
        } else if (length(page_footer_notes) != n_items) {
          stop("`page_footer_notes` must have length 1 or match `data_list`.", call. = FALSE)
        }
      } else if (length(page_footer_notes) == 1L && n_items > 1L) {
        page_footer_notes <- rep(page_footer_notes, n_items)
      } else if (length(page_footer_notes) != n_items) {
        stop("`page_footer_notes` must have length 1 or match `data_list`.", call. = FALSE)
      }

      for (i in seq_len(n_items)) {
        page_idx <- self$add_page(section_index = sec_idx, title = page_titles[[i]])
        self$add_block(
          section_index = sec_idx,
          page_index = page_idx,
          block = list(type = block_type, data = data_list[[i]], metadata = metadata)
        )
        if (!is.null(page_footer_notes[[i]])) {
          self$set_page_footer_notes(sec_idx, page_idx, page_footer_notes[[i]])
        }
      }

      sec_idx
    },

    set_document_defaults = function(
      font_table = NULL,
      color_table = NULL,
      default_page = NULL,
      default_format = NULL
    ) {
      if (!is.null(font_table)) {
        self$document$font_table <- font_table
      }
      if (!is.null(color_table)) {
        self$document$color_table <- color_table
      }
      if (!is.null(default_page)) {
        self$document$default_page <- .merge_list(self$document$default_page, default_page)
      }
      if (!is.null(default_format)) {
        self$document$default_format <- .merge_list(self$document$default_format, default_format)
      }
      invisible(self)
    },

    set_default_page = function(page) {
      self$document$default_page <- .merge_list(self$document$default_page, page)
      invisible(self)
    },

    set_default_format = function(fmt) {
      self$document$default_format <- .merge_list(self$document$default_format, fmt)
      invisible(self)
    },

    set_default_header = function(header) {
      warning("set_default_header() is deprecated. Set header per section via add_section(header=...) instead.", call. = FALSE)
      invisible(self)
    },

    set_default_footer = function(footer) {
      warning("set_default_footer() is deprecated. Set footer per section via add_section(footer=...) instead.", call. = FALSE)
      invisible(self)
    },

    validate = function() {
      if (length(self$sections) == 0L) {
        stop("rtfreport must contain at least one section.", call. = FALSE)
      }
      for (i in seq_along(self$sections)) {
        sec <- self$sections[[i]]
        if (length(sec$pages) == 0L) {
          stop(sprintf("Section %d must contain at least one page.", i), call. = FALSE)
        }
        for (j in seq_along(sec$pages)) {
          page <- sec$pages[[j]]
          if (!is.list(page$content)) {
            stop(sprintf("Section %d page %d content must be a list.", i, j), call. = FALSE)
          }
          for (k in seq_along(page$content)) {
            block <- page$content[[k]]
            if (is.null(block$type)) {
              stop(sprintf("Section %d page %d block %d must define `type`.", i, j, k), call. = FALSE)
            }
            if (!block$type %in% c("table", "listing", "figure")) {
              stop(sprintf("Unsupported block type `%s`.", block$type), call. = FALSE)
            }
            if (block$type %in% c("table", "listing") && is.null(block$data)) {
              stop(sprintf("Section %d page %d block %d requires `data`.", i, j, k), call. = FALSE)
            }
            if (block$type == "figure" &&
                is.null(block$path) && !inherits(block$data, "rtfplot")) {
              stop(sprintf("Section %d page %d block %d requires `path` or an rtfplot object.", i, j, k), call. = FALSE)
            }
          }
        }
      }
      invisible(TRUE)
    }
  )
)
