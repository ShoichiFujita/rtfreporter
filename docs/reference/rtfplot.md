# RTF plot object

`rtfplot` reads a PNG or JPEG image and prepares it for embedding inside
an RTF document.

## Usage

``` r
rtfplot(path, width_twips = NULL, height_twips = NULL, align = "center")
```

## Arguments

- path:

  Path to a PNG or JPEG image file.

- width_twips:

  Displayed width in twips. `NULL` = full writable width.

- height_twips:

  Displayed height in twips. `NULL` = derived from aspect ratio.

- align:

  Horizontal alignment: `"center"` (default), `"left"`, or `"right"`.

## Value

An S3 object of class `rtfplot`.

## See also

[`rtf_figures`](https://ichirio.github.io/rtfreporter/reference/rtf_figures.md),
[`generate_rtfreport`](https://ichirio.github.io/rtfreporter/reference/generate_rtfreport.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  plot_obj <- rtfplot("figure.png")
} # }
```
