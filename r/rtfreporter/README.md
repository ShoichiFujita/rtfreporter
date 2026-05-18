
# rtfreporter (R package)

This package provides RTF report generation features specialized for clinical
tables and listings. It is not a general-purpose RTF library, but is focused
on clinical-trial style reporting outputs.

At present the package supports RTF output only. Future versions are expected
to add support for embedding objects from table creation tools such as
`rtables` and `huxtable`.

## Main functions

- `rtfreport`: Create and manage RTF report objects
- `generate_rtfreport`: Write an RTF file
- `rtftable`: Table object with data frame payload and formatting metadata
- `rtfplot`: Object for embedding PNG/JPEG images into RTF
- `hello_rtfreporter`: Simple greeting for smoke tests

## Quick start

See the vignette for end-to-end examples built from the bundled test data:

- `vignettes/rtfreporter-quickstart.Rmd`

---

Cross-language RTF reporting toolkit - R implementation.

## Installation

### From GitHub (development)

```r
# remotes package が必要
# install.packages("remotes")

remotes::install_github("ichirio/rtfreporter", subdir = "r/rtfreporter")
```

### From source

```bash
cd r/rtfreporter
R CMD INSTALL .
```

## Quick start

```r
library(rtfreporter)
hello_rtfreporter()
```

## Development

```r
# ローカルでの開発・テスト
devtools::load_all()
devtools::test()
devtools::check()
```

## License

MIT License - See LICENSE file for details

## Authors

- ichirio (ichirio@example.com)

---

For the Python implementation, see the [python](../../python) directory.
