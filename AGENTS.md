# Agent Instructions for rtfreporter

## ⚠️ Mandatory first step

**Before modifying any code, test, or documentation, always read the specs files first.**

```
specs/api_contract.md               ← Public API definitions (R and Python)
specs/feature_proposal_20260515.md  ← Approved implementation specs
specs/release_guidelines.md         ← Release and packaging rules
```

The specs are the **single source of truth**. All R code, Python code, tests, and
vignettes must conform to the specs. If a spec and code disagree, the spec wins
unless the user explicitly asks to change the spec first.

---

## Workflow rule

1. **Read relevant spec sections** before writing any code.
2. **Update specs first** when a design decision changes (API shape, behavior,
   defaults, data structures).
3. **Then update** in this order:
   - R implementation (`R/`)
   - R help (`man/`, roxygen comments in `R/`)
   - R vignettes (`vignettes/`)
   - R tests (`tests/`)
   - Python implementation (`python/src/rtfreporter/`)
   - Python tests (`python/tests/`)
4. Never introduce an API pattern in code that is not documented in the specs.

---

## Repository structure

This repository **is the R package** (DESCRIPTION is at the root). R is the primary
language. Python is an experimental secondary implementation maintained in a
subdirectory.

```
rtfreporter/                        ← repo root = R package root (CRAN-ready layout)
├── AGENTS.md                       ← This file (read first)
├── DESCRIPTION                     ← R package manifest
├── NAMESPACE
├── LICENSE
├── README.md
├── rtfreporter.Rproj
│
├── R/                              ← R source files
│   ├── rtfreport.R
│   ├── generate_rtfreport.R
│   ├── rtftable.R
│   ├── rtfplot.R
│   └── hello.R
│
├── man/                            ← R help files (*.Rd) — update when API changes
│   ├── rtfreport.Rd
│   ├── generate_rtfreport.Rd
│   ├── rtftable.Rd
│   ├── rtfplot.Rd
│   └── hello_rtfreporter.Rd
│
├── tests/                          ← R tests (run with Rscript tests/test_rtfreport.R)
│   ├── test_rtfreport.R            ← primary test suite (must pass before any commit)
│   ├── test_rtfreport_old.R        ← backward-compat test (do NOT modify)
│   ├── quickstart_examples.R
│   ├── feature_test.R
│   ├── multisection_demo.R
│   └── rowheight_demo.R
│
├── vignettes/
│   └── rtfreporter-quickstart.Rmd
│
├── inst/
│   └── resources/
│       └── rtf_commands.R          ← RTF command definitions (shared with Python via JSON)
│
├── specs/                          ← Source of truth — always update before code
│   ├── api_contract.md
│   ├── feature_proposal_20260515.md
│   └── release_guidelines.md
│
└── python/                         ← ⚠️ Experimental — NOT a published package yet
    ├── README.md
    ├── pyproject.toml
    ├── src/rtfreporter/
    │   ├── core.py
    │   └── resources/rtf_commands.json
    └── tests/
        └── test_core.py
```

---

## Python subdirectory — important notes

- Python is an **experimental secondary implementation**. R is primary.
- Python code is maintained here for **development and API parity tracking only**.
  It is **not published to PyPI** at this time.
- Python API must mirror the R API as closely as Python idioms allow.
- In the future, `python/` will be **migrated to a separate repository**
  (tentatively `rtfreporter-py`) and published to PyPI independently.
- When developing Python code, write it as if it will be published (clean API,
  docstrings, tests, pyproject.toml). Avoid making it depend on the R package
  structure; it should be self-contained within `python/`.
- The Python `AGENTS.md` (when created at migration time) should reference
  `specs/` from the R repository as the source of truth until Python has its own.

---

## Key API rules (summary — see specs for full detail)

### Header/Footer constructors

Use `rtf_header()` / `rtf_footer()` for multi-row or border-controlled headers:
```r
hdr <- rtf_header(
  rows = list(
    c(l = "Protocol: RTF-101", r = "HOGE company"),
    c(l = "Study Title",       r = "Page {AUTO_PAGE} of {TOTAL_PAGES}")
  )
)
ftr <- rtf_footer(c(l = "Confidential"))  # top_border = TRUE by default
report$add_section(header = hdr, footer = ftr)
```

Shorthand (single row, no border/width control):
```r
report$add_section(
  header = c(l = "Protocol: RTF-101", r = "Page {AUTO_PAGE} of {TOTAL_PAGES}"),
  footer = c(l = "Confidential")
)
```

### Header/Footer get/set methods

```r
# Set (after section creation)
report$set_section_header(sec_idx, hdr)
report$set_section_footer(sec_idx, ftr)

# Get
hdr <- report$get_section_header(sec_idx)
ftr <- report$get_section_footer(sec_idx)
```

### Header/Footer row format

Named keys: `l` = left, `r` = right, `c` = center.

**Column-count rules:**
- Only `l` / `c` / `r` → 1 column
- `l` + `r` (no `c`) → 2 columns
- `c` with `l` or `r`, or all three → 3 columns (missing keys fill with `""`)

Legacy `list(columns = c(...))` is accepted for backward compatibility but
**must not be written in new code**.

### Page tokens

| Token | Behavior |
|-------|----------|
| `{AUTO_PAGE}` | `\chpgn` — dynamic page number (recommended) |
| `{PAGE}` | Alias for `{AUTO_PAGE}` |
| `{TOTAL_PAGES}` | Static total page count at render time |
| `{AUTO_TOTAL_PAGES}` | Alias for `{TOTAL_PAGES}` |

Recommended: `"Page {AUTO_PAGE} of {TOTAL_PAGES}"`.

Tests must **not** assert literal page numbers. Instead:
```r
stopifnot(grepl("\\chpgn",  rtf_txt, fixed = TRUE))  # {AUTO_PAGE}
stopifnot(grepl(" of 2",    rtf_txt, fixed = TRUE))  # {TOTAL_PAGES}
```

---

## Running tests

```powershell
# R — from repo root
cd c:\Yrepo\rtfreporter
Rscript tests/test_rtfreport.R

# Python — from python/ subdirectory
cd c:\Yrepo\rtfreporter\python
python -m pytest tests/
```

All tests in `tests/test_rtfreport.R` must pass before any PR or release.

