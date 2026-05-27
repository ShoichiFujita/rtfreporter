# Visualise an \`rtf_document\`

Draws a grid of page thumbnails. Each thumbnail shows the title /
content / footnote regions, with header and footer bands sketched in
grey.

## Usage

``` r
# S3 method for class 'rtf_document'
plot(x, max_pages = 12L, ...)
```

## Arguments

- x:

  An \[rtf_document()\] object.

- max_pages:

  Maximum number of pages to draw (default \`12\`). Larger documents are
  truncated with a note.

- ...:

  Unused.

## Value

Invisibly returns \`x\`.
