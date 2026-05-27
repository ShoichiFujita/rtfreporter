# Return a copy of an \`rtf_border\` with selected sides replaced

Non-mutating: returns a new \`rtf_border\` with the supplied side(s) set
on top of \`border\`. \`NULL\` arguments leave the corresponding side
unchanged.

## Usage

``` r
rtf_border_with(border, top = NULL, bottom = NULL, left = NULL, right = NULL)
```

## Arguments

- border:

  An \[rtf_border()\] object. \`NULL\` is accepted and treated as an
  empty border.

- top, bottom, left, right:

  Replacement \[rtf_border_side()\] values, or \`NULL\` to leave a side
  unchanged.

## Value

A new \`rtf_border\` object.
