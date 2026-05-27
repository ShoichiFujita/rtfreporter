# Package index

## Pipe-composition API

Primary user-facing API. Build a document by piping
[`rtf_document()`](https://ichirio.github.io/rtfreporter/reference/rtf_document.md)
through section / content / format calls, then render with
[`generate_rtfreport()`](https://ichirio.github.io/rtfreporter/reference/generate_rtfreport.md).

- [`rtf_document()`](https://ichirio.github.io/rtfreporter/reference/rtf_document.md)
  : Create an RTF document for pipe composition
- [`print(`*`<rtf_document>`*`)`](https://ichirio.github.io/rtfreporter/reference/print.rtf_document.md)
  : Print an rtf_document object
- [`rtf_config()`](https://ichirio.github.io/rtfreporter/reference/rtf_config.md)
  : Configure document-level settings
- [`rtf_section()`](https://ichirio.github.io/rtfreporter/reference/rtf_section.md)
  : Define sections for pages
- [`rtf_tables()`](https://ichirio.github.io/rtfreporter/reference/rtf_tables.md)
  : Add content pages to document
- [`rtf_figures()`](https://ichirio.github.io/rtfreporter/reference/rtf_figures.md)
  : Add figure content to document
- [`rtf_titles()`](https://ichirio.github.io/rtfreporter/reference/rtf_titles.md)
  : Assign content titles to pages
- [`rtf_footnotes()`](https://ichirio.github.io/rtfreporter/reference/rtf_footnotes.md)
  : Assign content footnotes to pages
- [`generate_rtfreport()`](https://ichirio.github.io/rtfreporter/reference/generate_rtfreport.md)
  : Generate an RTF file from a report object
- [`assemble_rtf()`](https://ichirio.github.io/rtfreporter/reference/assemble_rtf.md)
  : Assemble multiple RTF files into one

## Content constructors

Build a richly formatted table or figure object.

- [`rtftable()`](https://ichirio.github.io/rtfreporter/reference/rtftable.md)
  : RTF table object
- [`rtfplot()`](https://ichirio.github.io/rtfreporter/reference/rtfplot.md)
  : RTF plot object

## Headers, footers and tokens

- [`rtf_header()`](https://ichirio.github.io/rtfreporter/reference/rtf_header.md)
  [`rtf_footer()`](https://ichirio.github.io/rtfreporter/reference/rtf_header.md)
  : Create a header or footer object for a section
- [`update_header_row()`](https://ichirio.github.io/rtfreporter/reference/update_header_row.md)
  [`update_footer_row()`](https://ichirio.github.io/rtfreporter/reference/update_header_row.md)
  : Update a specific row in an \`rtf_header()\` object

## External table-object pagination

Convert a \[gt::gt()\] table (or a plain data.frame / tibble — or a list
of either) into a list of data.frames sized for one RTF page each, ready
for
[`rtf_tables()`](https://ichirio.github.io/rtfreporter/reference/rtf_tables.md).
S3-generic so new table object types (e.g. rtables, sft) can plug in via
one method.

- [`paginate()`](https://ichirio.github.io/rtfreporter/reference/paginate.md)
  : Split a table object into per-page data.frames

## Unified column-header API

Multi-row column headers with optional spanning cells expressed
uniformly via `pos = 1` or `pos = c(2, 5)`. Top-level spanning works
without a separate `spanning_header` argument.

- [`col_cell()`](https://ichirio.github.io/rtfreporter/reference/col_cell.md)
  : Column-header cell specification
- [`rtf_col_header()`](https://ichirio.github.io/rtfreporter/reference/rtf_col_header.md)
  : Build a multi-row column-header specification
- [`add_col_header_row()`](https://ichirio.github.io/rtfreporter/reference/add_col_header_row.md)
  : Append (or prepend) a row to an \`rtf_col_header\`

## Borders

Border specifications for cells, rows and table zones.

- [`rtf_border_side()`](https://ichirio.github.io/rtfreporter/reference/rtf_border_side.md)
  : Single-edge border specification
- [`rtf_border_side()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  [`rtf_border()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  [`rtf_border_none()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  [`rtf_border_top()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  [`rtf_border_bottom()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  [`rtf_border_box()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  [`rtf_table_border()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  [`rtf_border_tfl()`](https://ichirio.github.io/rtfreporter/reference/rtf_border.md)
  : Border specification classes for rtfreporter
- [`rtf_border_with()`](https://ichirio.github.io/rtfreporter/reference/rtf_border_with.md)
  : Return a copy of an \`rtf_border\` with selected sides replaced
- [`rtf_table_border()`](https://ichirio.github.io/rtfreporter/reference/rtf_table_border.md)
  : Per-zone border specification for a table
- [`rtf_border_tfl()`](https://ichirio.github.io/rtfreporter/reference/rtf_border_tfl.md)
  : Clinical TFL-style table border preset

## Shared table style (S3, snapshot)

- [`rtf_table_style()`](https://ichirio.github.io/rtfreporter/reference/rtf_table_style.md)
  : Shared table style
- [`rtf_table_style_with()`](https://ichirio.github.io/rtfreporter/reference/rtf_table_style_with.md)
  : Return a copy of an \`rtf_table_style\` with selected fields
  replaced
- [`rtf_table_style_tfl()`](https://ichirio.github.io/rtfreporter/reference/rtf_table_style_tfl.md)
  : Clinical TFL preset (table style)

## Shared mutable theme (R6, optional)

Reference-semantics theme — mutate once, every referencing table
reflects the change at the next render. Requires the optional `R6`
package.

- [`rtf_theme()`](https://ichirio.github.io/rtfreporter/reference/rtf_theme.md)
  : Shared mutable theme (R6 — optional)
- [`rtf_theme_tfl()`](https://ichirio.github.io/rtfreporter/reference/rtf_theme_tfl.md)
  : Clinical TFL preset (R6 theme)

## Visual preview (S3 plot methods)

Quick base-graphics wireframes of rtfreporter objects, for
sanity-checking layouts before rendering RTF.

- [`plot(`*`<rtf_border>`*`)`](https://ichirio.github.io/rtfreporter/reference/plot.rtf_border.md)
  : Visualise an \`rtf_border\`
- [`plot(`*`<rtf_border_side>`*`)`](https://ichirio.github.io/rtfreporter/reference/plot.rtf_border_side.md)
  : Visualise an \`rtf_border_side\`
- [`plot(`*`<rtf_table_border>`*`)`](https://ichirio.github.io/rtfreporter/reference/plot.rtf_table_border.md)
  : Visualise an \`rtf_table_border\`
- [`plot(`*`<rtftable>`*`)`](https://ichirio.github.io/rtfreporter/reference/plot.rtftable.md)
  : Visualise an \`rtftable\`
- [`plot(`*`<rtf_document>`*`)`](https://ichirio.github.io/rtfreporter/reference/plot.rtf_document.md)
  : Visualise an \`rtf_document\`

## Blank-row specifications

- [`blank_rows_by_change()`](https://ichirio.github.io/rtfreporter/reference/blank_rows_by_change.md)
  : Blank-row specification: insert when a variable's value changes
- [`blank_rows_by_rule()`](https://ichirio.github.io/rtfreporter/reference/blank_rows_by_rule.md)
  : Blank-row specification: insert before/after rows matching a pattern

## Column-width helpers

- [`text_width_in()`](https://ichirio.github.io/rtfreporter/reference/text_width_in.md)
  : Estimate the display width of a text string
- [`auto_col_widths()`](https://ichirio.github.io/rtfreporter/reference/auto_col_widths.md)
  : Automatically calculate column widths for a data.frame

## Deprecated

- [`rtf_table_format()`](https://ichirio.github.io/rtfreporter/reference/rtf_format-deprecated.md)
  [`rtf_header_format()`](https://ichirio.github.io/rtfreporter/reference/rtf_format-deprecated.md)
  [`rtf_footer_format()`](https://ichirio.github.io/rtfreporter/reference/rtf_format-deprecated.md)
  [`rtf_figure_format()`](https://ichirio.github.io/rtfreporter/reference/rtf_format-deprecated.md)
  : Deprecated formatting functions
