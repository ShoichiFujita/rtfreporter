# Add figure content to document

Append one or more image files (PNG/JPEG) as content pages. Each figure
creates one new page. Display dimensions and alignment apply to every
bare path in \`figures\`; elements already constructed via \[rtfplot()\]
keep their own settings.

## Usage

``` r
rtf_figures(
  doc,
  figures,
  width_twips = NULL,
  height_twips = NULL,
  align = "center",
  titles = NULL,
  footnotes = NULL
)
```

## Arguments

- doc:

  An rtf_document object.

- figures:

  A list whose elements are either character file paths to image files
  (PNG/JPEG) or pre-built \`rtfplot\` objects from \[rtfplot()\].

- width_twips:

  Display width in twips for bare paths. \`NULL\` = full writable width.

- height_twips:

  Display height in twips for bare paths. \`NULL\` = derived from the
  image's aspect ratio.

- align:

  Horizontal alignment for bare paths: \`"center"\` (default),
  \`"left"\`, or \`"right"\`.

- titles, footnotes:

  Optional lists of length \`length(figures)\`. See \[rtf_tables()\] for
  the same semantics — character vectors per page, magic tokens
  supported.

## Value

Modified rtf_document with appended figure contents.
