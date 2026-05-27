# Assign content footnotes to pages

Same shape as \[rtf_titles()\]: a list with one element per page, each a
character vector whose entries become rows of the footnote block. Magic
tokens are honoured. \`NULL\` per element suppresses the footnote for
that page.

## Usage

``` r
rtf_footnotes(doc, footnotes)
```

## Arguments

- doc:

  An rtf_document object.

- footnotes:

  A list of length equal to the number of pages.

## Value

Modified rtf_document.
