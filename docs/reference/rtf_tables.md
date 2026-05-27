# Add content pages to document

Append one or more content items as pages. \*\*Each element of
\`tables\` becomes exactly one page\*\*, holding a single table or
figure.

## Usage

``` r
rtf_tables(
  doc,
  tables,
  col_header = NULL,
  col_header_align = NULL,
  spanning_header = NULL,
  col_spec = NULL,
  border = "tfl",
  blank_rows = NULL,
  read_attributes = TRUE,
  style = NULL,
  col_rel_width = NULL,
  column_widths_twips = NULL,
  table_width_twips = NULL,
  table_width_pct_of_writable = NULL,
  table_width_pct = NULL,
  table_align = "left",
  row_height_twips = NULL,
  row_height_exact = FALSE,
  header_row_height_twips = NULL,
  blank_row_height_twips = NULL,
  cell_padding_left_twips = 0L,
  cell_padding_right_twips = 0L,
  cell_valign = "bottom",
  titles = NULL,
  footnotes = NULL,
  auto_section = FALSE,
  section_label_align = "left"
)
```

## Arguments

- doc:

  An rtf_document object.

- tables:

  A list where each element is one page's content. Each element must be
  one of: - \`data.frame\`: simple table; the table-format arguments
  below apply. - \`rtftable\` object (from \`rtftable()\`): table with
  full formatting. - \`rtfplot\` object (from \`rtfplot()\`): embedded
  figure.

- col_header, spanning_header, col_spec, border, blank_rows:

  Per-table content settings applied to bare \`data.frame\` elements.
  See \[rtftable()\] for details.

- col_rel_width, column_widths_twips, table_width_twips,
  table_width_pct_of_writable, table_width_pct, table_align:

  Column-width and table-width settings applied to bare \`data.frame\`
  elements. See \[rtftable()\] for details.

- row_height_twips, row_height_exact, header_row_height_twips,
  blank_row_height_twips:

  Row-height settings applied to bare \`data.frame\` elements. See
  \[rtftable()\] for details.

- cell_padding_left_twips, cell_padding_right_twips, cell_valign:

  Cell layout settings applied to bare \`data.frame\` elements. See
  \[rtftable()\] for details.

- titles:

  \`NULL\` (default) or a list of length \`length(tables)\`. Each
  element is a character vector — one element per row of that page's
  title. Magic tokens \`"HALF_BLANK_ROW"\` and \`"BLANK_ROW"\` are
  honoured. Use \`NULL\` per element to fall back to the default
  (\`HALF_BLANK_ROW\` — one half-height blank row).

- footnotes:

  \`NULL\` (default) or a list of length \`length(tables)\`. Same
  structure as \`titles\`; each element becomes one row in the footnote
  block. Magic tokens supported.

- auto_section:

  Logical. When \`TRUE\` and \`tables\` is a \*\*named\*\* list, each
  name is used as a per-section heading appended to the common header
  defined by \`rtf_section(secinfo = ...)\` (called without a \`page\`
  argument). The document is then automatically split into one RTF
  section per named element. Unnamed items fall through to the previous
  section. Default \`FALSE\`.

- section_label_align:

  Alignment for the auto-appended section label row. One of \`"left"\`
  (default), \`"center"\`, or \`"right"\`.

## Value

Modified rtf_document with appended contents.

## Details

Table-formatting arguments (\`col_rel_width\`, \`border\`,
\`row_height_twips\`, ...) accepted by this function are applied
\*\*only to bare \`data.frame\` elements\*\* of \`tables\`. Elements
already constructed via \`rtftable()\` or \`rtfplot()\` carry their own
settings and are not overridden.

## Examples

``` r
if (FALSE) { # \dontrun{
df1 <- data.frame(A = 1:3, B = c("x", "y", "z"))
df2 <- data.frame(A = 4:6, B = c("p", "q", "r"))

# Three pages, shared formatting applied to both bare data.frames
doc <- rtf_document() %>%
  rtf_tables(
    list(df1, df2, rtfplot("fig.png")),
    col_rel_width    = c(1, 2),
    border           = "tfl",
    row_height_twips = 280L
  )
} # }
```
