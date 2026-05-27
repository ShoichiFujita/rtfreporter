# Clinical TFL-style table border preset

Returns an \[rtf_table_border()\] matching the standard clinical TFL
style: \*\*borders are applied to the column-header block only\*\*, with
no borders in the data area by default. Specifically:

## Usage

``` r
rtf_border_tfl(style = "single", width = 15L, color = NULL)
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

An \`rtf_table_border\` object.

## Details

\* \`header\$top\` — top border on the topmost header row \*
\`header\$bottom\` — bottom border on the bottommost header row \*
Multi-column spanning cells additionally receive a bottom border (group
underline) when they are not themselves the last header row — this is
added automatically by the renderer. \* No vertical lines. \* \*\*No
borders on the data section\*\* (\`body\` / \`first_row\` / \`last_row\`
all \`NULL\`). Callers who want a bottom rule under the last data row
can set it explicitly: \`rtf_table_border(last_row = rtf_border(bottom =
rtf_border_side()))\`.
