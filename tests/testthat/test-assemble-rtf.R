# assemble_rtf.R -- concatenate multiple rtfreporter-generated RTFs.

.write_demo_rtf <- function(title) {
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(
    header = rtf_header(rows = list(
      c(l = "Protocol RTF-101", r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}")
    )),
    footer = rtf_footer(c(c = "Confidential"))
  ))
  doc <- rtf_tables(doc, list(
    data.frame(A = 1:2, B = c("x", "y"), stringsAsFactors = FALSE)
  ), titles = list(c(title)))
  f <- tempfile(fileext = ".rtf")
  generate_rtfreport(doc, f, overwrite = TRUE)
  f
}

test_that("assemble_rtf() concatenates 2 files into one document with \\sect breaks", {
  f1 <- .write_demo_rtf("Table 14.1.1")
  f2 <- .write_demo_rtf("Table 14.2.1")
  on.exit({ unlink(c(f1, f2)) }, add = TRUE)

  out <- tempfile(fileext = ".rtf")
  on.exit(unlink(out), add = TRUE)

  expect_invisible(assemble_rtf(c(f1, f2), out, overwrite = TRUE))
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 0L)

  lines <- readLines(out, warn = FALSE)
  joined <- paste(lines, collapse = "\n")
  # Both source titles appear in the assembled output
  expect_match(joined, "Table 14\\.1\\.1")
  expect_match(joined, "Table 14\\.2\\.1")
  # Exactly one inter-section break (between the two source files)
  expect_identical(sum(grepl("^\\\\sect$", lines)), 1L)
  # Document still ends with a single closing "}"
  expect_identical(trimws(tail(lines, 1)), "}")
})

test_that("assemble_rtf() concatenates more than 2 files", {
  fs <- vapply(1:3, function(i) .write_demo_rtf(sprintf("T %d", i)),
               character(1L))
  on.exit(unlink(fs), add = TRUE)
  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  assemble_rtf(fs, out, overwrite = TRUE)
  lines <- readLines(out, warn = FALSE)
  # N - 1 section breaks between N source files
  expect_identical(sum(grepl("^\\\\sect$", lines)), 2L)
})

test_that("assemble_rtf() requires at least 2 input files", {
  expect_error(assemble_rtf(character(0), tempfile()),
               "at least 2")
  expect_error(assemble_rtf("only_one.rtf", tempfile()),
               "at least 2")
})

test_that("assemble_rtf() errors if any input file does not exist", {
  f1 <- .write_demo_rtf("X"); on.exit(unlink(f1), add = TRUE)
  expect_error(
    assemble_rtf(c(f1, "/no/such/file.rtf"), tempfile()),
    "not found")
})

test_that("assemble_rtf() refuses to overwrite without overwrite = TRUE", {
  f1 <- .write_demo_rtf("A"); f2 <- .write_demo_rtf("B")
  on.exit(unlink(c(f1, f2)), add = TRUE)
  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  assemble_rtf(c(f1, f2), out, overwrite = TRUE)
  expect_error(assemble_rtf(c(f1, f2), out), "already exists")
})

test_that("assemble_rtf() refuses non-rtfreporter RTFs (missing \\sectd)", {
  fake <- tempfile(fileext = ".rtf"); on.exit(unlink(fake), add = TRUE)
  writeLines(c("{\\rtf1\\ansi", "Hello world.", "}"), fake)
  f1  <- .write_demo_rtf("Real");  on.exit(unlink(f1), add = TRUE)
  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  expect_error(assemble_rtf(c(f1, fake), out, overwrite = TRUE),
               "sectd")
})

# ──────── TOC + bookmarks (v0.0.29+) ──────────────────────────────────────

test_that("assemble_rtf(toc = ...) inserts a TOC page with HYPERLINK + PAGEREF fields", {
  f1 <- .write_demo_rtf("Table 14.1.1")
  f2 <- .write_demo_rtf("Table 14.2.1")
  on.exit(unlink(c(f1, f2)), add = TRUE)

  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  assemble_rtf(c(f1, f2), out,
               toc        = c("T14.1.1 Demographics", "T14.2.1 AE Summary"),
               overwrite  = TRUE)

  txt <- paste(readLines(out, warn = FALSE), collapse = "\n")

  # TOC title and BOTH labels appear, plus an extra \sect for the TOC page
  expect_match(txt, "Table of Contents")
  expect_match(txt, "T14\\.1\\.1 Demographics")
  expect_match(txt, "T14\\.2\\.1 AE Summary")

  # Field codes present: HYPERLINK + PAGEREF (escaped backslashes in regex)
  expect_match(txt, "HYPERLINK")
  expect_match(txt, "PAGEREF")

  # Bookmarks inserted for both source files
  expect_match(txt, "bkmkstart tfl_")
  expect_match(txt, "bkmkend tfl_")

  # 2 bookmarkstart entries — one per source file
  expect_identical(length(gregexpr("bkmkstart tfl_", txt)[[1L]]), 2L)
})

test_that("assemble_rtf(toc = NULL) is byte-identical to the legacy behaviour", {
  f1 <- .write_demo_rtf("A"); f2 <- .write_demo_rtf("B")
  on.exit(unlink(c(f1, f2)), add = TRUE)

  out_legacy <- tempfile(fileext = ".rtf"); on.exit(unlink(out_legacy), add = TRUE)
  out_null   <- tempfile(fileext = ".rtf"); on.exit(unlink(out_null),   add = TRUE)
  assemble_rtf(c(f1, f2), out_legacy, overwrite = TRUE)
  assemble_rtf(c(f1, f2), out_null,   toc = NULL, overwrite = TRUE)

  expect_identical(readLines(out_legacy, warn = FALSE),
                   readLines(out_null,   warn = FALSE))
})

test_that("assemble_rtf(toc) length must match input_files length", {
  f1 <- .write_demo_rtf("X"); f2 <- .write_demo_rtf("Y")
  on.exit(unlink(c(f1, f2)), add = TRUE)
  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  expect_error(
    assemble_rtf(c(f1, f2), out, toc = "only one entry", overwrite = TRUE),
    "same length"
  )
})

test_that("bookmark name sanitiser strips .rtf and replaces invalid chars", {
  s <- rtfreporter:::.sanitize_bookmark(
    c("table 14.1.1.rtf", "subjects-screened.rtf",
      "1starts-with-digit.rtf", "T_2.rtf")
  )
  # No spaces, dashes, or dots; first char is a letter
  expect_false(any(grepl("[ \\-\\.]", s)))
  expect_true(all(grepl("^[A-Za-z]", s)))
  # Length cap
  long <- paste0(strrep("x", 60), ".rtf")
  expect_lte(nchar(rtfreporter:::.sanitize_bookmark(long)), 32L)
})

test_that("duplicate bookmark names get suffixed (.1, .2 ...)", {
  # Two files whose basenames sanitise to the same bookmark
  d1 <- tempfile(); dir.create(d1); on.exit(unlink(d1, recursive = TRUE), add = TRUE)
  d2 <- tempfile(); dir.create(d2); on.exit(unlink(d2, recursive = TRUE), add = TRUE)
  f1 <- file.path(d1, "x.rtf"); f2 <- file.path(d2, "x.rtf")
  doc <- rtf_document()
  doc <- rtf_section(doc, page = 1, secinfo = list(header = NULL, footer = NULL))
  doc <- rtf_tables(doc, list(data.frame(a = 1L)))
  generate_rtfreport(doc, f1, overwrite = TRUE)
  generate_rtfreport(doc, f2, overwrite = TRUE)

  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  assemble_rtf(c(f1, f2), out,
               toc       = c("entry A", "entry B"),
               overwrite = TRUE)
  txt <- paste(readLines(out, warn = FALSE), collapse = "\n")
  # Both bookmarks present and distinct (suffixed)
  expect_match(txt, "tfl_x_1")
  expect_match(txt, "tfl_x_2")
})

test_that("toc_leader = 'none' suppresses the dot leader", {
  f1 <- .write_demo_rtf("X"); f2 <- .write_demo_rtf("Y")
  on.exit(unlink(c(f1, f2)), add = TRUE)
  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  assemble_rtf(c(f1, f2), out,
               toc        = c("A", "B"),
               toc_leader = "none",
               overwrite  = TRUE)
  txt <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_false(grepl("\\\\tldot", txt))
})

test_that("custom bookmark_prefix is honoured", {
  f1 <- .write_demo_rtf("X"); f2 <- .write_demo_rtf("Y")
  on.exit(unlink(c(f1, f2)), add = TRUE)
  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  assemble_rtf(c(f1, f2), out,
               toc             = c("A", "B"),
               bookmark_prefix = "studyX_",
               overwrite       = TRUE)
  txt <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_match(txt, "bkmkstart studyX_")
  expect_false(grepl("bkmkstart tfl_", txt))
})

test_that("TOC label characters get RTF-escaped (backslash, braces, unicode)", {
  f1 <- .write_demo_rtf("X"); f2 <- .write_demo_rtf("Y")
  on.exit(unlink(c(f1, f2)), add = TRUE)
  out <- tempfile(fileext = ".rtf"); on.exit(unlink(out), add = TRUE)
  assemble_rtf(c(f1, f2), out,
               toc       = c("A {special} \\char",
                              "B with greek α"),
               overwrite = TRUE)
  txt <- paste(readLines(out, warn = FALSE), collapse = "\n")
  # Brace escapes
  expect_match(txt, "\\\\\\{special\\\\\\}")
  # Backslash escape
  expect_match(txt, "\\\\\\\\char")
  # Unicode -> RTF \uN?
  expect_match(txt, "\\\\u945\\?")
})
