# Changelog

All notable changes to rtfreporter are documented in this file. Changes are recorded for **major.minor** version releases only (v0.1.0, v0.2.0, etc.). Patch and development versions (v0.1.1, v0.0.6, v0.0.dev, etc.) are not recorded.

---

## v0.1.0 (TBD - when ready for public release)

> **Status**: Currently in development as v0.0.7. Will be released as v0.1.0 when complete.

### 🔴 Breaking Changes

#### Pipe API formatting moved into `rtf_tables()` / `rtf_figures()`

The four standalone format functions did not actually affect rendered RTF
output — values were stored but never read by the renderer. They are now
deprecated and replaced by formatting arguments on the constructor functions:

```r
# Old (v0.0.6, never worked):
doc <- rtf_document() %>%
  rtf_tables(list(df1, df2)) %>%
  rtf_table_format(pages = "all", border = "tfl", row_height_twips = 280L)

# New (v0.0.7):
doc <- rtf_document() %>%
  rtf_tables(list(df1, df2),
             border = "tfl", row_height_twips = 280L,
             col_rel_width = c(2, 1, 1))
```

Affected functions: `rtf_table_format()`, `rtf_header_format()`,
`rtf_footer_format()`, `rtf_figure_format()`. They remain available as
`.Deprecated()` no-ops; planned for removal in a future release.

**Migration:** Move each formatting argument directly onto `rtf_tables()` or
`rtf_figures()` (for shared defaults across bare `data.frame` / path items),
or onto `rtftable()` / `rtfplot()` (for per-item control). For header/footer
border and row height, set them on `rtf_header()` / `rtf_footer()` directly.

---

#### One content per page enforced

Each element of `rtf_tables()` / `rtf_figures()` now corresponds to exactly
one page (one table **or** one figure). The previously documented but
silently broken pattern `list(df1, list(rtfplot(...), rtftable(df2)))`
(multiple items on one page) is rejected at validation time.

**Migration:** Place each table / figure on its own page (consecutive pages
in the same section share the section header).

---

#### `rtf_figures()` runtime bug fixed

Previously crashed at render time because paths were wrapped in `list(path)`
but the renderer expected `rtfplot_r6` objects. Paths are now promoted to
`rtfplot_r6`, and `width_twips` / `height_twips` / `align` may be supplied
to `rtf_figures()` directly. Pre-built `rtfplot()` objects in `figures` are
accepted unchanged.

---

### 🔴 Breaking Changes

#### R6 classes are now private; public API is S3 functions only

Previously, users called R6 class constructors directly:
```r
# Old (v0.0.5):
report <- rtfreport$new()
tbl    <- rtftable$new(df, ...)
fig    <- rtfplot$new("path/to/img.png")
```

In v0.1.0, use S3 wrapper functions:
```r
# New (v0.1.0):
report <- rtfreport()
tbl    <- rtftable(df, ...)
fig    <- rtfplot("path/to/img.png")
```

**Migration:** Replace all `ClassName$new(...)` with `ClassName(...)`.  
**Reason:** Cleaner public API; internal R6 classes renamed to `rtftable_r6`, `rtfplot_r6`, `rtfreport_r6` for clarity.

---

#### Content type auto-detection; explicit `type` field no longer required

Previously, `add_page()` required explicit block specifications with `type`:
```r
# Old (v0.0.5):
report$add_page(
  section_index = sec,
  content = list(
    list(type = "table", data = rtftable$new(df, ...)),
    list(type = "figure", data = rtfplot$new("img.png"))
  )
)
```

In v0.1.0, objects are auto-detected from their class:
```r
# New (v0.1.0):
report$add_page(
  section_index = sec,
  content = list(
    rtftable(df, ...),
    rtfplot("img.png")
  )
)
```

**Auto-detection rules:**
- `rtftable_r6` → `type = "table"`
- `rtfplot_r6` → `type = "figure"`
- `data.frame` → `type = "table"`
- File path (`character(1)`) → `type = "figure"`

**Migration:** Simplify content lists by passing objects directly. Backward compatibility: explicit `type` field still works internally.

---

### ✨ Features

#### Multi-line content titles and footer notes

`title` and `footer_notes` in `add_page()` now accept character vectors for multiple lines:
```r
report$add_page(
  section_index = sec,
  title = c("Line 1", "Line 2"),
  footer_notes = c("Note 1", "Note 2")
)
```

---

### 🔧 Internal Changes

- R6 classes renamed for clarity:
  - `rtftable` → `rtftable_r6`
  - `rtfplot` → `rtfplot_r6`
  - `rtfreport` → `rtfreport_r6`
- New internal helper `.normalize_content_item()` for block type auto-detection
- S3 wrapper functions created in `r/wrappers.R`

---

## v0.0.5 and earlier

Not recorded (pre-v0.1.0).
