# Border specification classes for rtfreporter

Three constructor functions build border specifications used in
[`rtf_header`](https://ichirio.github.io/rtfreporter/reference/rtf_header.md),
[`rtf_footer`](https://ichirio.github.io/rtfreporter/reference/rtf_header.md),
and
[`rtftable`](https://ichirio.github.io/rtfreporter/reference/rtftable.md).
All return plain lists with a class attribute.

## Usage

``` r
rtf_border_side(style = "single", width = 15L, color = NULL)

rtf_border(top = NULL, bottom = NULL, left = NULL, right = NULL)

rtf_border_none()
rtf_border_top(style = "single", width = 15L, color = NULL)
rtf_border_bottom(style = "single", width = 15L, color = NULL)
rtf_border_box(style = "single", width = 15L, color = NULL)

rtf_table_border(
  header    = NULL,
  spanning  = NULL,
  body      = NULL,
  first_row = NULL,
  last_row  = NULL
)

rtf_border_tfl(style = "single", width = 15L, color = NULL)
```

## Class hierarchy

- `rtf_border_side` — defines one edge (style, weight, colour).

- `rtf_border` — four edges of a single cell or row.

- `rtf_table_border` — per-zone borders for a full table.

## Arguments

- style:

  Line style. One of `"single"` (default), `"double"`, `"thick"`,
  `"dash"`, `"dot"`.

- width:

  Line weight in twips (integer). Default `15` ≈ 0.5 pt.

- color:

  Line colour. `NULL` (default) = black. Or a 6-digit hex string such as
  `"#003366"`.

- top, bottom, left, right:

  `NULL` (no border on this edge) or an `rtf_border_side` object.

- header:

  An `rtf_border` for column-header rows, or `NULL`.

- spanning:

  An `rtf_border` for spanning-header rows, or `NULL`.

- body:

  An `rtf_border` for data rows, or `NULL`.

- first_row:

  An `rtf_border` override for the first data row (merged on top of
  `body`).

- last_row:

  An `rtf_border` override for the last data row (merged on top of
  `body`).

## Value

- [`rtf_border_side()`](https://rdrr.io/pkg/rtfreporter/man/rtf_border.html)
  — a list of class `"rtf_border_side"`.

- `rtf_border()` and convenience variants — a list of class
  `"rtf_border"`.

- [`rtf_table_border()`](https://rdrr.io/pkg/rtfreporter/man/rtf_border.html)
  and
  [`rtf_border_tfl()`](https://rdrr.io/pkg/rtfreporter/man/rtf_border.html)
  — a list of class `"rtf_table_border"`.

## See also

[`rtf_header`](https://ichirio.github.io/rtfreporter/reference/rtf_header.md),
[`rtf_footer`](https://ichirio.github.io/rtfreporter/reference/rtf_header.md),
[`rtftable`](https://ichirio.github.io/rtfreporter/reference/rtftable.md)

## Examples

``` r
# --- rtf_border_side ---------------------------------------------------------
s_single <- rtf_border_side()                        # single, 15 twips, black
s_thick  <- rtf_border_side("thick", 20L, "#003366") # thick, 20 twips, dark blue

# --- rtf_border (cell) -------------------------------------------------------
b_top    <- rtf_border_top()          # top edge only
b_box    <- rtf_border_box()          # all four edges
b_custom <- rtf_border(
  top    = rtf_border_side("single"),
  bottom = rtf_border_side("double", 10L)
)

# --- rtf_table_border --------------------------------------------------------
tbl_b <- rtf_table_border(
  header   = rtf_border(top = rtf_border_side(), bottom = rtf_border_side()),
  last_row = rtf_border(bottom = rtf_border_side())
)

# TFL clinical preset (same as rtftable default)
tbl_b <- rtf_border_tfl()

# --- Using borders in header/footer ------------------------------------------
ftr <- rtf_footer(
  rows   = list(c(l = "Confidential", r = "{AUTO_PAGE}/{AUTO_TOTAL_PAGES}")),
  border = rtf_border_top()   # default; top dividing line
)
hdr <- rtf_header(
  rows   = list(c(c = "Study Title")),
  border = rtf_border(bottom = rtf_border_side("thick", 20L))
)

# --- Using borders in rtftable -----------------------------------------------
tbl <- rtftable(
  data   = data.frame(A = 1:3, B = letters[1:3]),
  border = rtf_border_tfl()
)

# Custom table border
tbl2 <- rtftable(
  data   = data.frame(X = 1:2),
  border = rtf_table_border(
    header   = rtf_border_box(),
    last_row = rtf_border(bottom = rtf_border_side("double"))
  )
)
```
