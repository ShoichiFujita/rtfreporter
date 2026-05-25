# Basic tests for Pipe Composition API (rtf_document)
# Run this script to verify pipe API functionality

# Load package from development directory
library(devtools)
load_all(quiet = TRUE)

# Load magrittr for pipe operator %>%
library(magrittr)

# ==============================================================================
# Test 1: Create and configure document
# ==============================================================================
cat("\n=== Test 1: Document Creation and Configuration ===\n")

doc <- rtf_document()
cat("✓ rtf_document() created\n")
cat("  Class:", class(doc), "\n")
cat("  Structure:", paste(names(doc), collapse=", "), "\n")

# Check default values
stopifnot(doc$document$page$orientation == "landscape")
stopifnot(doc$document$page$width_in == 11)
stopifnot(doc$document$page$height_in == 8.5)
cat("✓ Default clinical trial settings applied\n")

# Configure document
doc2 <- rtf_config(doc, page = list(orientation = "portrait"))
stopifnot(doc2$document$page$orientation == "portrait")
stopifnot(doc$document$page$orientation == "landscape")  # Original unchanged
cat("✓ rtf_config() works (immutable pattern)\n")

# ==============================================================================
# Test 2: Add content
# ==============================================================================
cat("\n=== Test 2: Content Addition ===\n")

# Create test data
df1 <- data.frame(A = 1:3, B = c("x", "y", "z"))
df2 <- data.frame(ID = c(10, 20, 30), Value = c(100, 200, 300))

# Add tables: bare data.frames are promoted to rtftable_r6 with shared formatting
doc3 <- rtf_document() %>%
  rtf_tables(list(df1, df2), col_rel_width = c(1, 2), row_height_twips = 280L)

stopifnot(length(doc3$contents) == 2)
stopifnot(inherits(doc3$contents[[1L]], "rtftable_r6"))
stopifnot(identical(doc3$contents[[1L]]$col_rel_width, c(1, 2)))
stopifnot(identical(doc3$contents[[1L]]$row_height_twips, 280L))
stopifnot(identical(doc3$contents[[2L]]$col_rel_width, c(1, 2)))
cat("✓ rtf_tables() promotes data.frames and applies shared formatting\n")
cat("  Pages created:", length(doc3$contents), "\n")

# Pre-built rtftable() objects keep their own settings
custom_tbl <- rtftable(df2, col_rel_width = c(3, 1))
doc4 <- rtf_document() %>%
  rtf_tables(list(df1, custom_tbl), col_rel_width = c(1, 2))

stopifnot(identical(doc4$contents[[1L]]$col_rel_width, c(1, 2)))   # bare df: applied
stopifnot(identical(doc4$contents[[2L]]$col_rel_width, c(3, 1)))   # rtftable(): preserved
cat("✓ rtftable() object settings take precedence over rtf_tables() defaults\n")

# Validation: list-in-list (multi-content per page) is rejected
err <- tryCatch(
  rtf_document() %>% rtf_tables(list(df1, list(df2))),
  error = function(e) e
)
stopifnot(inherits(err, "error"))
cat("✓ Multi-content-per-page is rejected (1 content per page enforced)\n")

# ==============================================================================
# Test 3: Section definition
# ==============================================================================
cat("\n=== Test 3: Section Definition ===\n")

doc5 <- rtf_document() %>%
  rtf_tables(list(df1, df2)) %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL))

stopifnot(length(doc5$sections) == 1)
stopifnot(!is.null(doc5$sections[["1"]]))
cat("✓ rtf_section() maps pages to sections\n")
cat("  Sections defined:", length(doc5$sections), "\n")

# Multiple sections
doc6 <- rtf_document() %>%
  rtf_tables(list(df1, df2)) %>%
  rtf_section(page = c(1, 2), secinfo = list(
    list(header = NULL, footer = NULL),
    list(header = NULL, footer = NULL)
  ))

stopifnot(length(doc6$sections) == 2)
cat("✓ Multiple sections supported\n")

# ==============================================================================
# Test 4: Deprecated format functions emit warnings and are no-ops
# ==============================================================================
cat("\n=== Test 4: Deprecated rtf_*_format() Functions ===\n")

base_doc <- rtf_document() %>% rtf_tables(list(df1, df2))

for (fn_name in c("rtf_table_format", "rtf_header_format",
                  "rtf_footer_format", "rtf_figure_format")) {
  fn   <- get(fn_name)
  saw  <- FALSE
  out  <- withCallingHandlers(
    fn(base_doc, pages = "all", border = "tfl"),
    warning = function(w) { saw <<- TRUE; invokeRestart("muffleWarning") }
  )
  stopifnot(saw)                       # Deprecation warning was emitted
  stopifnot(identical(out, base_doc))  # No-op (document unchanged)
  cat("✓", fn_name, "is a deprecated no-op\n")
}

# ==============================================================================
# Test 6: Print method
# ==============================================================================
cat("\n=== Test 6: Print S3 Method ===\n")

doc12 <- rtf_document() %>%
  rtf_tables(list(df1, df2, df1)) %>%
  rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL))

cat("Document output:\n")
print(doc12)

# ==============================================================================
# Test 7: Integration test - full workflow
# ==============================================================================
cat("\n=== Test 7: Full Workflow Integration ===\n")

# Create a complete report
workflow_doc <- rtf_document() %>%
  rtf_config(page = list(
    orientation = "landscape",
    width_in = 11,
    height_in = 8.5
  )) %>%
  rtf_tables(list(df1, df2),
             border = "tfl", row_height_twips = 280L,
             col_rel_width = c(1, 2)) %>%
  rtf_section(page = 1, secinfo = list(
    header = list(l = "Section 1", r = "Page 1"),
    footer = list(c = "Footer 1")
  )) %>%
  rtf_section(page = 2, secinfo = list(
    header = list(l = "Section 2", r = "Page 2"),
    footer = list(c = "Footer 2")
  ))

stopifnot(length(workflow_doc$contents) == 2)
stopifnot(length(workflow_doc$sections) == 2)
stopifnot(inherits(workflow_doc$contents[[1L]], "rtftable_r6"))
stopifnot(identical(workflow_doc$contents[[1L]]$col_rel_width, c(1, 2)))
cat("✓ Complete workflow successful\n")

# ==============================================================================
# Summary
# ==============================================================================
cat("\n=== ALL TESTS PASSED ===\n")
cat("✓ Document creation and configuration\n")
cat("✓ Content addition (1 content per page; bare df promoted to rtftable_r6)\n")
cat("✓ Section definition (single and multiple)\n")
cat("✓ Deprecated rtf_*_format() functions warn and are no-ops\n")
cat("✓ Print S3 method\n")
cat("✓ Full workflow integration\n")
cat("\nPipe Composition API is fully functional!\n\n")
