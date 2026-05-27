# Per-zone border specification for a table

Specifies borders for each logical zone of an \[rtftable()\]. Each zone
is either \`NULL\` (no border) or an \[rtf_border()\] object.
\`first_row\` and \`last_row\` are \*overrides\* merged on top of the
\`body\` spec.

## Usage

``` r
rtf_table_border(
  header = NULL,
  spanning = NULL,
  body = NULL,
  first_row = NULL,
  last_row = NULL
)
```

## Arguments

- header:

  \[rtf_border()\] for column-header rows. \`NULL\` = none.

- spanning:

  \[rtf_border()\] for spanning-header rows. \`NULL\` = none.

- body:

  \[rtf_border()\] for data rows. \`NULL\` = none.

- first_row:

  \[rtf_border()\] override for the first data row.

- last_row:

  \[rtf_border()\] override for the last data row.

## Value

A list of class \`"rtf_table_border"\`.
