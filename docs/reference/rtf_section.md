# Define sections for pages

Map page numbers to sections with headers/footers. Pages are
automatically numbered based on content order (starting at 1).

## Usage

``` r
rtf_section(doc, page = NULL, secinfo)
```

## Arguments

- doc:

  An rtf_document object.

- page:

  Integer or vector of page numbers to assign this section. - Single
  integer: one section starts at this page - Vector: assign multiple
  pages to sections (length must match secinfo)

- secinfo:

  Section information (one or more section definitions): - Single
  section: list(header = ..., footer = ...) - Multiple sections:
  list(sec1, sec2, ...) where each is a section list

## Value

Modified rtf_document with section definitions added.

## Details

The \`page\` parameter identifies where each section starts. Pages are
auto-numbered from your content list (rtf_tables and rtf_figures).

## Examples

``` r
if (FALSE) { # \dontrun{
doc <- rtf_document() %>%
  rtf_tables(list(df1, df2, df3)) %>%
  rtf_section(page = 1, secinfo = list(header = h1, footer = f1)) %>%
  rtf_section(page = 3, secinfo = list(header = h2, footer = f2))
} # }
```
