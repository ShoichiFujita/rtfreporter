# Column-header cell specification

Convenience constructor for a single cell in a column-header row passed
to \[rtftable()\] (via \`col_header =\`) or \[rtf_col_header()\].

## Usage

``` r
col_cell(
  pos,
  label = "",
  align = NULL,
  bold = FALSE,
  italic = FALSE,
  underline = FALSE
)
```

## Arguments

- pos:

  Numeric of length 1 (single column) or length 2 (\`c(start, end)\`,
  inclusive). \`start \<= end\` required; values must be \`\>= 1\`.

- label:

  Character scalar. Cell text; may be \`""\`.

- align:

  Optional \`"left"\`, \`"center"\`, or \`"right"\`. \`NULL\` (default)
  inherits the leftmost covered column's \`header_align\`.

- bold, italic, underline:

  Logical. Default \`FALSE\`.

## Value

A list of class \`"rtf_col_cell"\`.

## Details

Use \`pos = 1\` for a single-column cell and \`pos = c(start, end)\` for
a cell that spans several data columns. Positions are always relative to
the underlying data columns, not to the previous header row.

## Examples

``` r
col_cell(1, "Item")
#> Error in col_cell(1, "Item"): could not find function "col_cell"
col_cell(c(2, 5), "Treatment", align = "center", underline = TRUE)
#> Error in col_cell(c(2, 5), "Treatment", align = "center", underline = TRUE): could not find function "col_cell"
```
