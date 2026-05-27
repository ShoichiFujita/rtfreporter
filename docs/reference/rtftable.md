# RTF table object

`rtftable` holds one or more `data.frame`s together with all table-level
formatting metadata. Pass an `rtftable` to
[`rtf_tables()`](https://ichirio.github.io/rtfreporter/reference/rtf_tables.md)
in a pipe chain to use rich formatting such as spanning headers,
relative column widths, TFL borders, and table alignment.

## Usage

``` r
rtftable(
  data,
  col_header              = NULL,
  spanning_header         = NULL,
  col_spec                = NULL,
  border                  = "tfl",
  blank_rows              = NULL,
  col_rel_width           = NULL,
  column_widths_twips     = NULL,
  table_width_twips       = NULL,
  table_width_pct_of_writable = NULL,
  table_width_pct         = NULL,
  table_align             = "left",
  row_height_twips        = 0L,
  row_height_exact        = FALSE,
  header_row_height_twips = NULL,
  blank_row_height_twips  = NULL,
  cell_padding_left_twips = 72L,
  cell_padding_right_twips = 72L,
  cell_valign             = "bottom"
)
```

## Arguments

- data:

  A `data.frame`, **or a list of `data.frame`s** with the same number of
  columns. When a list is supplied every data.frame is rendered
  consecutively, each preceded by its own column-header and (optionally)
  spanning-header rows.

- col_header:

  Column header specification. One of:

  - `NULL` — use column names as a single header row.

  - A character vector — one element per column (single header row).

  - A pipe-delimited string `"A | B | C"`.

  - A `list` of the above for multiple header rows (shared across all
    data.frames when `data` is a list).

  - When `data` is a list of *N* data.frames: a list of exactly *N*
    header specs (one per data.frame) — detected when the list length
    equals *N* and every element is `NULL`, a character vector, or a
    list-of-character-vectors.

- spanning_header:

  A list of spanning-header specs. Each element is a named list with
  `from` (int), `to` (int), `label` (chr), `underline` (logical). When
  `data` is a list the spanning header is repeated before each
  data.frame.

- col_spec:

  A list of per-column formatting specs. Each element is a named list
  with `col` (column index or name) plus any of: `align`
  (`"left"`/`"center"`/`"right"`), `bold`, `italic`, `underline`
  (logical), `indent_twips` (integer), `header_bold`, `header_italic`,
  `header_align`.

- border:

  Border specification. `"tfl"` (default) applies the Clinical-TFL
  standard (header top+bottom, last-data-row bottom, no vertical lines).
  `NULL` disables all borders. An
  [`rtf_table_border`](https://rdrr.io/pkg/rtfreporter/man/rtf_border.html)
  object or named list gives full control.

- blank_rows:

  Integer vector of positions at which to insert a blank separator row
  in the data section. `0` inserts one before the first data row; `k`
  inserts one after data row `k`.

- col_rel_width:

  Numeric vector of *relative* column widths (e.g. `c(3, 1, 1)`
  distributes 3:1:1). Ignored when `column_widths_twips` is set.

- column_widths_twips:

  Integer vector of *absolute* column widths in twips. Takes precedence
  over `col_rel_width`.

- table_width_twips:

  Total table width in twips (absolute). Used with `col_rel_width` when
  `column_widths_twips` is not set. 1440 twips = 1 inch.

- table_width_pct:

  Table width as a **percentage** (0–100) of the writable page width.
  `100` = full writable width (margins to margins). Takes precedence
  over `table_width_pct_of_writable`.

- table_width_pct_of_writable:

  Table width as a **fraction** (0–1) of the writable page width. Kept
  for backward compatibility; prefer `table_width_pct`.

- table_align:

  Horizontal placement of the table on the page. `"left"` (default),
  `"center"`, or `"right"`. Emits `\trqc` or `\trqr` in the RTF row
  definition; `"left"` uses the RTF default.

- row_height_twips:

  Row height in twips for data rows. `0` (default) = automatic height.
  Always specify a positive integer; use `row_height_exact = TRUE` for a
  fixed (clipped) height.

- row_height_exact:

  Logical. `FALSE` (default) = *minimum* height (`\trrh` positive; rows
  expand if content is taller). `TRUE` = *exact* height (`\trrh`
  negative; content is clipped if taller).

- header_row_height_twips:

  Row height for header/spanning rows. `NULL` uses `row_height_twips`.

- blank_row_height_twips:

  Height of blank separator rows in twips. `NULL` (default) uses
  `row_height_twips`.

- cell_padding_left_twips:

  Left cell padding in twips (default 0 since v0.0.21; cell content sits
  flush against the cell border).

- cell_padding_right_twips:

  Right cell padding in twips (default 0).

- cell_valign:

  Vertical cell alignment: `"bottom"` (default), `"top"`, or `"center"`.

## Value

An S3 object of class `rtftable`.

## See also

`rtfreport`,
[`generate_rtfreport`](https://ichirio.github.io/rtfreporter/reference/generate_rtfreport.md),
[`rtf_border_tfl`](https://rdrr.io/pkg/rtfreporter/man/rtf_border.html),
[`auto_col_widths`](https://ichirio.github.io/rtfreporter/reference/auto_col_widths.md)

## Examples

``` r
# --- Minimal single-DF table -------------------------------------------------
df <- data.frame(USUBJID = c("101-001", "101-002"), AGE = c(54L, 61L))
tbl <- rtftable(df)

# --- Table width and alignment -----------------------------------------------
# 70 percent of page width, centered
tbl2 <- rtftable(df,
  table_width_pct = 70,
  table_align     = "center")

# Absolute width, right-aligned
tbl3 <- rtftable(df,
  table_width_twips = 7200L,
  table_align       = "right")

# --- Relative column widths --------------------------------------------------
tbl4 <- rtftable(df,
  col_rel_width     = c(2, 1),
  table_width_twips = 9000L)

# --- Spanning header ---------------------------------------------------------
counts <- data.frame(
  Baseline = c("Low", "Normal", "High"),
  A_Low = c(4L, 0L, 0L), A_Norm = c(1L, 13L, 1L), A_High = c(0L, 2L, 3L),
  B_Low = c(3L, 0L, 0L), B_Norm = c(1L, 14L, 0L), B_High = c(0L, 1L, 4L)
)
shift_tbl <- rtftable(
  data            = counts,
  col_header      = c("Baseline", "Low", "Normal", "High", "Low", "Normal", "High"),
  spanning_header = list(
    list(from = 2L, to = 4L, label = "Treatment A (N=24)", underline = TRUE),
    list(from = 5L, to = 7L, label = "Treatment B (N=24)", underline = TRUE)
  ),
  column_widths_twips = c(2160L, 900L, 900L, 900L, 900L, 900L, 900L),
  border              = "tfl",
  row_height_twips    = 280L
)

# --- Multi data.frame (shared spanning header, per-DF col_header) ------------
df1 <- data.frame(A = 1:2, B = 3:4)
df2 <- data.frame(A = 5:6, B = 7:8)
tbl_multi <- rtftable(
  data       = list(df1, df2),
  col_header = list(c("Group 1 A", "Group 1 B"), c("Group 2 A", "Group 2 B"))
)

# --- col_spec: first column left, rest centered ------------------------------
tbl5 <- rtftable(df,
  col_spec = list(
    list(col = 1L, align = "left"),
    list(col = 2L, align = "center")
  )
)
```
