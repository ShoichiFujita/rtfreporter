# Blank-row specification: insert when a variable's value changes

Constructor for a blank-row spec that inserts a blank separator row each
time the value of any column in \`cols\` differs from the previous row.
Pass the result to \`rtftable(blank_rows = ...)\`, optionally combined
with other specs via a list.

## Usage

``` r
blank_rows_by_change(
  cols,
  include_before_first = TRUE,
  include_after_last = TRUE
)
```

## Arguments

- cols:

  Character vector of column names in the data frame.

- include_before_first:

  Logical. When \`TRUE\` (default), also insert a blank row before the
  first data row.

- include_after_last:

  Logical. When \`TRUE\` (default), also insert a blank row after the
  last data row.

## Value

An object of class \`rtf_blank_rows_by_change\`.

## Examples

``` r
if (FALSE) { # \dontrun{
rtftable(df, blank_rows = blank_rows_by_change(c("Treatment", "Visit")))
} # }
```
