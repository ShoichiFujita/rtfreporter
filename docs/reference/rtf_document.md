# Create an RTF document for pipe composition

Initialize a new RTF document object for building reports with pipes.
Provides sensible defaults for clinical trial reports.

## Usage

``` r
rtf_document(
  font_table = NULL,
  color_table = NULL,
  page = NULL,
  default_format = NULL
)
```

## Arguments

- font_table:

  Optional font table. Default: list(list(name = "Courier"))

- color_table:

  Optional color table. Default: c("#000000")

- page:

  Optional page settings (orientation, dimensions, margins). Default:
  landscape letter 11x8.5", margins 0.9 inch (top/bottom) and 0.6 inch
  (left/right).

- default_format:

  Optional document-wide default formatting.

## Value

An rtf_document object (S3 class) with structure: - document:
list(font_table, color_table, page, default_format) - contents: list
(initially empty, populated by rtf_tables/rtf_figures) - sections: list
(initially empty, populated by rtf_section)

## Examples

``` r
if (FALSE) { # \dontrun{
doc <- rtf_document()
} # }
```
