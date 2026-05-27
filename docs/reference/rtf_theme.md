# Shared mutable theme (R6 — optional)

\`rtf_theme\` is an R6 class whose instances are designed to be \*shared
by many tables\* and \*mutated in place\* — every table that holds the
same theme reference picks up the new defaults at the next render. It is
the only R6 object in \`rtfreporter\`; everything else is S3.

## Usage

``` r
rtf_theme(...)
```

## Arguments

- ...:

  Initial field values (same names as \[rtf_table_style()\]).

## Value

An R6 object of class \`rtf_theme\`.

## Details

Field names match \[rtf_table_style()\] one-for-one.

## R6 is optional

\`rtf_theme()\` is gated on the suggested \`R6\` package being
installed. If it is not, an informative error is raised. Users who do
not need shared mutable themes do not need to install \`R6\` at all —
the rest of \`rtfreporter\` runs without it.

## See also

\* \[rtf_table_style()\] — the S3 equivalent (snapshot semantics). \*
\[rtftable()\] — accepts \`theme =\` to attach an \`rtf_theme\`. \*
\`vignette("class-systems", package = "rtfreporter")\` for the S3-vs-R6
design notes.

## Examples

``` r
if (FALSE) { # \dontrun{
theme <- rtf_theme(header_bold = FALSE)

t1 <- rtftable(df1, theme = theme)
t2 <- rtftable(df2, theme = theme)

# Both tables render with header_bold = FALSE …

theme$header_bold <- TRUE

# … now both render with header_bold = TRUE, no rebuild needed.
} # }
```
