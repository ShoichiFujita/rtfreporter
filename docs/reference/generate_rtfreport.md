# Generate an RTF file from a report object

Render an `rtf_document` (built with the pipe API) — or the internal
`rtfreport` S3 object — to a single RTF file.

## Usage

``` r
generate_rtfreport(report, file_path, overwrite = FALSE)
```

## Arguments

- report:

  An `rtf_document` object from
  [`rtf_document()`](https://ichirio.github.io/rtfreporter/reference/rtf_document.md),
  or an internal `rtfreport` S3 object.

- file_path:

  Output RTF file path.

- overwrite:

  Logical; whether to overwrite an existing file.

## Value

Invisibly returns `file_path`.

## See also

[`rtf_document`](https://ichirio.github.io/rtfreporter/reference/rtf_document.md),
[`rtf_tables`](https://ichirio.github.io/rtfreporter/reference/rtf_tables.md),
[`rtf_section`](https://ichirio.github.io/rtfreporter/reference/rtf_section.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  library(magrittr)
  df <- data.frame(A = 1:3, B = c("x", "y", "z"))
  doc <- rtf_document() %>%
    rtf_section(page = 1, secinfo = list(header = rtf_header(c(l = "Example")))) %>%
    rtf_tables(list(df))
  generate_rtfreport(doc, tempfile(fileext = ".rtf"), overwrite = TRUE)
} # }
```
