# Deprecated formatting functions

\`rtf_table_format()\`, \`rtf_header_format()\`,
\`rtf_footer_format()\`, and \`rtf_figure_format()\` are
\*\*deprecated\*\* and have no effect on the rendered output. They will
be removed in a future release.

## Usage

``` r
rtf_table_format(doc, ...)

rtf_header_format(doc, ...)

rtf_footer_format(doc, ...)

rtf_figure_format(doc, ...)
```

## Arguments

- doc:

  An rtf_document object.

- ...:

  Ignored.

## Value

\`doc\`, unchanged.

## Details

Use the formatting arguments of \[rtf_tables()\] (for tables and bare
data.frames) and \[rtf_figures()\] (for figures) instead, or build each
item explicitly with \[rtftable()\] / \[rtfplot()\] and pass it to
\`rtf_tables()\`.
