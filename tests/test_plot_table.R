# =============================================================================
# test_plot_table.R  —  rtfplot (ggplot2 PNG) + table alignment / width tests
#
# Covers:
#   P-1  ggplot2 scatter plot → PNG → rtfplot (center, default) → RTF
#   P-2  rtfplot with explicit width/height twips
#   T-1  table_align = "left" (default), table_width_pct = 70
#   T-2  table_align = "center", table_width_twips (absolute)
#   T-3  table_align = "right",  col_rel_width (relative column widths)
#   T-4  table_width_pct = 100  → sum of cellx == writable width
#   T-5  Plot + table on the same page
# =============================================================================

source(file.path("r", "rtf_border.R"))
source(file.path("r", "rtfreport.R"))
source(file.path("r", "rtftable.R"))
source(file.path("r", "rtfplot.R"))
source(file.path("r", "generate_rtfreport.R"))
source(file.path("r", "text_width.R"))

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("ggplot2 is required for this test.", call. = FALSE)
}

OUT_DIR <- file.path("tests", "output")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Default writable width for letter-landscape with 0.5" margins:
# (11 - 0.5 - 0.5) * 1440 = 14400 twips
WRITABLE_TWIPS <- 14400L

# =============================================================================
# Helper: make a small data.frame used across table tests
# =============================================================================
df_small <- data.frame(
  Subject  = c("001", "002", "003"),
  Age      = c(34L, 45L, 28L),
  Sex      = c("M", "F", "M"),
  stringsAsFactors = FALSE
)

# =============================================================================
# Helper: generate a ggplot2 scatter PNG and return its path
# =============================================================================
make_scatter_png <- function(path) {
  p <- ggplot2::ggplot(
    data = data.frame(x = 1:10, y = (1:10)^2 + rnorm(10, sd = 2)),
    ggplot2::aes(x = x, y = y)
  ) +
    ggplot2::geom_point(size = 3, colour = "#2166AC") +
    ggplot2::geom_smooth(method = "lm", se = FALSE, colour = "#D6604D") +
    ggplot2::labs(
      title = "Quadratic trend (simulated)",
      x     = "Visit",
      y     = "Lab value"
    ) +
    ggplot2::theme_bw(base_size = 11)
  ggplot2::ggsave(path, plot = p, width = 7, height = 4.5, dpi = 150)
  invisible(path)
}

png_path <- file.path(OUT_DIR, "scatter.png")
set.seed(42L)
make_scatter_png(png_path)
stopifnot(file.exists(png_path))

# =============================================================================
# P-1: ggplot2 PNG → rtfplot (center, default alignment) → RTF
# =============================================================================
cat("--- P-1: rtfplot center (default) ---\n")

plot_obj <- rtfplot$new(path = png_path)   # center is default
stopifnot(plot_obj$align == "center")
stopifnot(plot_obj$img_type == "png")
stopifnot(plot_obj$img_width > 0L)

r_p1 <- rtfreport$new()
sec_p1 <- r_p1$add_section(
  header = rtf_header(rows = list(
    c(l = "Protocol: PLOT-001", r = "HOGE Pharma Co., Ltd."),
    c(l = "Figure 14.1.1  Lab Value vs. Visit (Safety Population)")
  )),
  footer = rtf_footer(rows = list(c(l = "Source: LB domain.")))
)
r_p1$add_page(
  section_index = sec_p1,
  content       = list(list(type = "figure", data = plot_obj))
)

out_p1 <- file.path(OUT_DIR, "plot_center.rtf")
generate_rtfreport(r_p1, out_p1, overwrite = TRUE)
stopifnot(file.exists(out_p1))
txt_p1 <- paste(readLines(out_p1, warn = FALSE), collapse = "\n")
stopifnot(grepl("\\pict", txt_p1, fixed = TRUE))   # image embedded
stopifnot(grepl("\\qc",   txt_p1, fixed = TRUE))   # center alignment
cat("PASS\n\n")

# =============================================================================
# P-2: rtfplot with explicit width / height
# =============================================================================
cat("--- P-2: rtfplot explicit width/height ---\n")

plot_w <- rtfplot$new(path = png_path, width_twips = 7200L, height_twips = 4680L,
                      align = "left")
stopifnot(plot_w$width_twips  == 7200L)
stopifnot(plot_w$height_twips == 4680L)
stopifnot(plot_w$align == "left")

r_p2 <- rtfreport$new()
sec_p2 <- r_p2$add_section()
r_p2$add_page(sec_p2, content = list(list(type = "figure", data = plot_w)))
out_p2 <- file.path(OUT_DIR, "plot_explicit_size.rtf")
generate_rtfreport(r_p2, out_p2, overwrite = TRUE)
txt_p2 <- paste(readLines(out_p2, warn = FALSE), collapse = "\n")
stopifnot(grepl("\\pict",        txt_p2, fixed = TRUE))
stopifnot(grepl("\\picwgoal7200", txt_p2, fixed = TRUE))
stopifnot(grepl("\\pichgoal4680", txt_p2, fixed = TRUE))
cat("PASS\n\n")

# =============================================================================
# T-1: table_align = "left" (default), table_width_pct = 70
# =============================================================================
cat("--- T-1: table_align left (default), table_width_pct = 70 ---\n")

tbl_t1 <- rtftable$new(
  data             = df_small,
  table_width_pct  = 70,          # 70% of writable width
  row_height_twips = 280L
)
stopifnot(tbl_t1$table_align == "left")
stopifnot(abs(tbl_t1$table_width_pct_of_writable - 0.70) < 1e-9)

r_t1 <- rtfreport$new()
sec_t1 <- r_t1$add_section()
r_t1$add_page(sec_t1, content = list(list(type = "table", data = tbl_t1)))
out_t1 <- file.path(OUT_DIR, "table_left_pct70.rtf")
generate_rtfreport(r_t1, out_t1, overwrite = TRUE)
txt_t1 <- paste(readLines(out_t1, warn = FALSE), collapse = "\n")

# left-aligned tables must NOT contain \trqc or \trqr
stopifnot(!grepl("\\trqc", txt_t1, fixed = TRUE))
stopifnot(!grepl("\\trqr", txt_t1, fixed = TRUE))

# last cellx value = 70% of 14400 = 10080
stopifnot(grepl("cellx10080", txt_t1, fixed = TRUE))
cat("PASS\n\n")

# =============================================================================
# T-2: table_align = "center", table_width_twips = 9000 (absolute)
# =============================================================================
cat("--- T-2: table_align center, table_width_twips = 9000 ---\n")

tbl_t2 <- rtftable$new(
  data              = df_small,
  table_align       = "center",
  table_width_twips = 9000L,
  col_rel_width     = c(2, 1, 1),   # relative: 2:1:1
  row_height_twips  = 280L
)
stopifnot(tbl_t2$table_align == "center")

r_t2 <- rtfreport$new()
sec_t2 <- r_t2$add_section()
r_t2$add_page(sec_t2, content = list(list(type = "table", data = tbl_t2)))
out_t2 <- file.path(OUT_DIR, "table_center_abs.rtf")
generate_rtfreport(r_t2, out_t2, overwrite = TRUE)
txt_t2 <- paste(readLines(out_t2, warn = FALSE), collapse = "\n")
stopifnot(grepl("\\trqc",    txt_t2, fixed = TRUE))   # center row command
stopifnot(grepl("cellx9000", txt_t2, fixed = TRUE))   # last cellx = table width
cat("PASS\n\n")

# =============================================================================
# T-3: table_align = "right", col_rel_width (relative widths)
# =============================================================================
cat("--- T-3: table_align right, col_rel_width ---\n")

tbl_t3 <- rtftable$new(
  data              = df_small,
  table_align       = "right",
  table_width_twips = 8640L,       # 6 inches
  col_rel_width     = c(3, 1, 1),  # Subject wider
  row_height_twips  = 280L
)
stopifnot(tbl_t3$table_align == "right")

r_t3 <- rtfreport$new()
sec_t3 <- r_t3$add_section()
r_t3$add_page(sec_t3, content = list(list(type = "table", data = tbl_t3)))
out_t3 <- file.path(OUT_DIR, "table_right_relwidth.rtf")
generate_rtfreport(r_t3, out_t3, overwrite = TRUE)
txt_t3 <- paste(readLines(out_t3, warn = FALSE), collapse = "\n")
stopifnot(grepl("\\trqr",    txt_t3, fixed = TRUE))   # right row command
stopifnot(grepl("cellx8640", txt_t3, fixed = TRUE))   # last cellx = table width
cat("PASS\n\n")

# =============================================================================
# T-4: table_width_pct = 100 → full writable width
# =============================================================================
cat("--- T-4: table_width_pct = 100 (full writable width) ---\n")

tbl_t4 <- rtftable$new(
  data             = df_small,
  table_width_pct  = 100,
  row_height_twips = 280L
)
stopifnot(abs(tbl_t4$table_width_pct_of_writable - 1.0) < 1e-9)

r_t4 <- rtfreport$new()
sec_t4 <- r_t4$add_section()
r_t4$add_page(sec_t4, content = list(list(type = "table", data = tbl_t4)))
out_t4 <- file.path(OUT_DIR, "table_pct100.rtf")
generate_rtfreport(r_t4, out_t4, overwrite = TRUE)
txt_t4 <- paste(readLines(out_t4, warn = FALSE), collapse = "\n")
# Last cellx must equal full writable width
stopifnot(grepl(paste0("cellx", WRITABLE_TWIPS), txt_t4, fixed = TRUE))
cat("PASS\n\n")

# =============================================================================
# T-5: Plot (center) + table (left, pct=80) on the same page
# =============================================================================
cat("--- T-5: rtfplot + rtftable on the same page ---\n")

tbl_t5 <- rtftable$new(
  data             = df_small,
  table_width_pct  = 80,
  row_height_twips = 280L
)

r_t5 <- rtfreport$new()
sec_t5 <- r_t5$add_section(
  header = rtf_header(rows = list(
    c(l = "Protocol: PLOT-001", r = "HOGE Pharma Co., Ltd."),
    c(l = "Figure + Table on one page")
  )),
  footer = rtf_footer(rows = list(
    c(l = "Source: LB domain.",  r = "CONFIDENTIAL")
  ))
)
r_t5$add_page(
  section_index = sec_t5,
  content       = list(
    # Constrain width so figure + table fit on one landscape page.
    list(type = "figure", data = rtfplot$new(path = png_path, width_twips = 7200L)),
    list(type = "table",  data = tbl_t5)
  )
)

out_t5 <- file.path(OUT_DIR, "plot_and_table.rtf")
generate_rtfreport(r_t5, out_t5, overwrite = TRUE)
stopifnot(file.exists(out_t5))
txt_t5 <- paste(readLines(out_t5, warn = FALSE), collapse = "\n")
stopifnot(grepl("\\pict",        txt_t5, fixed = TRUE))   # figure embedded
stopifnot(grepl("Subject",       txt_t5, fixed = TRUE))   # table header
stopifnot(grepl("cellx11520",    txt_t5, fixed = TRUE))   # 80% of 14400
cat("PASS\n\n")

# =============================================================================
# A-1: Default alignment — unnamed single-column header and footer → center
# =============================================================================
cat("--- A-1: unnamed single-column header/footer defaults to center ---\n")

r_a1 <- rtfreport$new()
sec_a1 <- r_a1$add_section(
  # Row with NO key (unnamed) → should default to \qc (center)
  header = rtf_header(rows = list(
    c(l = "Protocol: ALIGN-001", r = "Company"),  # explicit l/r → unchanged
    c("Unnamed center header row")                 # no key → center
  )),
  footer = rtf_footer(rows = list(
    c("Unnamed center footer row")                 # no key → center
  ))
)
r_a1$add_page(sec_a1, content = list(list(type = "table", data = df_small)))
out_a1 <- file.path(OUT_DIR, "default_align.rtf")
generate_rtfreport(r_a1, out_a1, overwrite = TRUE)
txt_a1 <- paste(readLines(out_a1, warn = FALSE), collapse = "\n")

# Verify text present
stopifnot(grepl("Unnamed center header row", txt_a1, fixed = TRUE))
stopifnot(grepl("Unnamed center footer row", txt_a1, fixed = TRUE))
# Extract header block and footer block; both must contain \qc
hdr_start <- regexpr("{\\header", txt_a1, fixed = TRUE)[1]
ftr_start <- regexpr("{\\footer", txt_a1, fixed = TRUE)[1]
stopifnot(hdr_start > 0L, ftr_start > 0L)

# Locate \qc in a ~500-char window around the unnamed text in header
hdr_pos <- regexpr("Unnamed center header row", txt_a1, fixed = TRUE)[1]
hdr_window <- substr(txt_a1, max(1L, hdr_pos - 60L), hdr_pos)
stopifnot(grepl("\\qc", hdr_window, fixed = TRUE))

# Locate \qc in a ~500-char window around the unnamed text in footer
ftr_pos <- regexpr("Unnamed center footer row", txt_a1, fixed = TRUE)[1]
ftr_window <- substr(txt_a1, max(1L, ftr_pos - 60L), ftr_pos)
stopifnot(grepl("\\qc", ftr_window, fixed = TRUE))
cat("PASS\n\n")

# =============================================================================
# Summary
# =============================================================================
cat(sprintf("Output files:\n"))
for (f in c("scatter.png", "plot_center.rtf", "plot_explicit_size.rtf",
            "table_left_pct70.rtf", "table_center_abs.rtf",
            "table_right_relwidth.rtf", "table_pct100.rtf", "plot_and_table.rtf",
            "default_align.rtf")) {
  sz <- file.info(file.path(OUT_DIR, f))$size
  cat(sprintf("  %-30s  %d bytes\n", f, sz))
}
cat("All P / T / A tests passed.\n")
