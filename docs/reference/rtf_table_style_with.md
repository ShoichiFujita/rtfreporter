# Return a copy of an \`rtf_table_style\` with selected fields replaced

Non-mutating derivation: returns a new \`rtf_table_style\` whose listed
fields are overridden. Unknown field names raise an error.

## Usage

``` r
rtf_table_style_with(style, ...)
```

## Arguments

- style:

  An \[rtf_table_style()\] object.

- ...:

  Named field overrides. Allowed names match the arguments of
  \[rtf_table_style()\].

## Value

A new \`rtf_table_style\` object.
