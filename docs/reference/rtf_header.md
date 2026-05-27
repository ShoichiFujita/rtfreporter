# Create a header or footer object for a section

\`rtf_header()\` and \`rtf_footer()\` create structured header/footer
objects that can be passed to \`rtf_section()\`. Use
\[update_header_row()\] / \[update_footer_row()\] to add or replace
individual rows after creation.

## Usage

``` r
rtf_header(
  rows,
  border = NULL,
  width_twips = NULL,
  row_height_twips = NULL,
  cell_padding_left_twips = NULL,
  cell_padding_right_twips = NULL,
  top_border = NULL
)

rtf_footer(
  rows,
  border = rtf_border_top(),
  width_twips = NULL,
  row_height_twips = NULL,
  cell_padding_left_twips = NULL,
  cell_padding_right_twips = NULL,
  top_border = NULL
)
```

## Arguments

- rows:

  A named character vector (single row) or a \`list\` of named character
  vectors (multi-row). Each vector uses names \`l\`, \`c\`, \`r\` for
  left, center, right column content.

- border:

  An \[rtf_border()\] object controlling the border applied to all rows
  of the header/footer table. \`NULL\` = no border (default for header).
  Use \[rtf_border_top()\] for a horizontal dividing line (default for
  footer).

- width_twips:

  Integer. Table width in twips. \`NULL\` (default) uses the full
  writable width (page width minus margins).

- row_height_twips:

  Integer. Row height in twips. \`NULL\` (default) reads the value from
  \`inst/resources/rtfreporter_defaults.R\`.

- cell_padding_left_twips, cell_padding_right_twips:

  Integer cell padding on the left / right side of each header (or
  footer) cell, matching the content-table convention. \`NULL\`
  (default) reads from \`inst/resources/rtfreporter_defaults.R\` (0L for
  both since v0.0.21).

- top_border:

  \*\*Deprecated.\*\* Use \`border = rtf_border_top()\` or \`border =
  NULL\` instead.

## Value

A named list with elements \`rows\`, \`border\`, \`width_twips\`, and
\`row_height_twips\`.

## Examples

``` r
hdr <- rtf_header(
  rows = list(
    c(l = "Protocol: RTF-101", r = "ACME Pharma"),
    c(l = "Table 14.1.1",     r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}")
  )
)
ftr <- rtf_footer(c(l = "Confidential"))

hdr <- update_header_row(hdr, row = 3, content = c(c = "Draft"))
```
