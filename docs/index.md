`rtfreporter` is a standalone R toolkit for generating **Rich Text
Format (RTF) reports for clinical trial deliverables** — Tables,
Listings and Figures (TFLs). It offers a functional, pipe-friendly API
for composing multi-section RTF documents with clinical-style borders,
multi-row column headers (including spanning groups), automatic
page-number fields, and embedded figures.

It is purposely **independent**: no dependency on `r2rtf`, `reporter`,
or other RTF packages, and no R6/S7 dependency — just base R and S3.

## Why rtfreporter?

- **Clinical-first** — defaults follow common TFL conventions (header
  outer frame + spanning group underlines, no body borders, font-size
  aware row heights).
- **Composable pipe API** —
  `rtf_document() %>% rtf_section() %>% rtf_tables()`.
- **Reproducible page numbering across assembled deliverables** —
  dynamic `{AUTO_PAGE}` / `{AUTO_TOTAL_PAGES}` tokens, plus
  [`assemble_rtf()`](https://ichirio.github.io/rtfreporter/reference/assemble_rtf.md)
  to concatenate per-output RTFs into one TFL package.
- **All S3, no R6** — [`dput()`](https://rdrr.io/r/base/dput.html) /
  [`str()`](https://rdrr.io/r/utils/str.html) /
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) round-trip cleanly.
- **Zero hard dependencies** — works on any modern R out of the box.

## Installation

The package is not on CRAN yet. Install the development version from
GitHub:

``` r

# install.packages("remotes")
remotes::install_github("ichirio/rtfreporter")
```

## A 30-second example

``` r

library(rtfreporter)
library(magrittr)

df <- data.frame(
  USUBJID = c("001-001", "001-002", "001-003"),
  TRT     = c("Placebo", "Active",  "Active"),
  AVAL    = c(12.3, 14.1, 11.7)
)

doc <- rtf_document() %>%
  rtf_section(
    page    = 1,
    secinfo = list(
      header = rtf_header(rows = list(
        c(l = "Protocol XYZ-001", r = "Confidential"),
        c(l = "Table 14.1.1",     r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}")
      )),
      footer = rtf_footer(c(c = "ACME Pharma, Inc."))
    )
  ) %>%
  rtf_tables(
    list(df),
    border           = "tfl",
    row_height_twips = 280L,
    titles    = list(c("Subject Summary", "Safety Population")),
    footnotes = list(c("Source: ADaM ADSL"))
  )

generate_rtfreport(doc, "T_14_1_1.rtf", overwrite = TRUE)
```

## Documentation

The full pkgdown site is at <https://ichirio.github.io/rtfreporter/>:

- **Get started** —
  [`vignette("rtfreporter-quickstart")`](https://ichirio.github.io/rtfreporter/articles/rtfreporter-quickstart.md)
- **Pipe API** —
  [`vignette("rtfreporter-pipes")`](https://ichirio.github.io/rtfreporter/articles/rtfreporter-pipes.md)
- **External API spec** — pkgdown article
- **Internal class design (S3 architecture)** — pkgdown article

## Status & roadmap

`rtfreporter` is currently in active development; the API may change in
backward-incompatible ways before v0.1.0. A short-term roadmap:

- Pre-v0.1 — repeated column headers per `pageby` group; cell background
  colour.
- v0.1.0 — first GitHub release, pkgdown site live.
- v0.2.x — full `R CMD check --as-cran` clean, increased test coverage.
- v0.3+ — CRAN submission, `pharmaverse` candidacy.

See [`CHANGELOG.md`](https://ichirio.github.io/rtfreporter/CHANGELOG.md)
for detailed per-version notes and
[`NEWS.md`](https://ichirio.github.io/rtfreporter/NEWS.md) for the
user-facing changelog.

## Contributing & bug reports

Issues and pull requests are very welcome at
<https://github.com/ichirio/rtfreporter>. Please read
[`CONTRIBUTING.md`](https://ichirio.github.io/rtfreporter/CONTRIBUTING.md)
and the [code of
conduct](https://ichirio.github.io/rtfreporter/CODE_OF_CONDUCT.md)
first.

## License

MIT © 2026 Yoichi Masui. See
[`LICENSE.md`](https://ichirio.github.io/rtfreporter/LICENSE.md).
