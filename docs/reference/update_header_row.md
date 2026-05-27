# Update a specific row in an \`rtf_header()\` object

Adds a new row or replaces an existing row in a header/footer object. If
\`row\` is beyond the current number of rows, intermediate rows are
auto-filled with empty center-aligned rows (\`c(c = "")\`).

## Usage

``` r
update_header_row(header, row, content)

update_footer_row(footer, row, content)
```

## Arguments

- header:

  An \`rtf_header()\` object (returned by \`rtf_header()\`).

- row:

  Integer. Target row number (1-based).

- content:

  A named character vector for the row (e.g. \`c(l = "Left", r =
  "Right")\`). See \`rtf_header()\` for column rules.

- footer:

  An \`rtf_footer()\` object (returned by \`rtf_footer()\`).

## Value

A modified \`rtf_header()\` object.

## Examples

``` r
hdr <- rtf_header(rows = list(
  c(l = "Protocol: XXX-001", r = "Company"),
  c(l = "Table 14.1.1",     r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}")
))

hdr <- update_header_row(hdr, row = 2, content = c(l = "Table 14.2.1", r = "Page {AUTO_PAGE}"))
hdr <- update_header_row(hdr, row = 3, content = c(c = "Draft - Confidential"))
hdr <- update_header_row(hdr, row = 5, content = c(l = "Run date: 2026-01-01"))
```
