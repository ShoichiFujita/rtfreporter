# Configure document-level settings

Update font, color, page, or default formatting for the document. This
function is typically called once after creating a document. Only
non-NULL parameters are updated (NULL = no change).

## Usage

``` r
rtf_config(
  doc,
  font_table = NULL,
  color_table = NULL,
  page = NULL,
  default_format = NULL
)
```

## Arguments

- doc:

  An rtf_document object.

- font_table:

  Optional font table to replace default.

- color_table:

  Optional color table to replace default.

- page:

  Optional page settings list.

- default_format:

  Optional document-wide default formatting.

## Value

Modified rtf_document object (new copy, original unchanged).
