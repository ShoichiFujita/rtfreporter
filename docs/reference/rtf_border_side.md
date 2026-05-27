# Single-edge border specification

Defines the line style, weight, and colour for one edge of a cell. Use
this as an argument to \[rtf_border()\].

## Usage

``` r
rtf_border_side(style = "single", width = 15L, color = NULL)
```

## Arguments

- style:

  Line style. One of \`"single"\` (default), \`"double"\`, \`"thick"\`,
  \`"dash"\`, \`"dot"\`.

- width:

  Line weight in twips. Default \`15\` ≈ 0.5 pt.

- color:

  Line colour. \`NULL\` (default) = black. Or a 6-digit hex string such
  as \`"#003366"\`.

## Value

A list of class \`"rtf_border_side"\`.
