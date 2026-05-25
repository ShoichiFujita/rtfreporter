## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval = FALSE-------------------------------------------------------------
# library(rtfreporter)
# 
# # Create a simple report
# doc <- rtf_document() %>%
#   rtf_tables(list(mtcars)) %>%
#   rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL))
# 
# # Generate RTF file
# generate_rtfreport(doc, "report.rtf")

## ----eval = FALSE-------------------------------------------------------------
# doc <- rtf_document()
# 
# # With custom defaults
# doc <- rtf_document(
#   font_table = list(list(name = "Arial")),
#   page = list(
#     orientation = "portrait",
#     width_in = 8.5,
#     height_in = 11
#   )
# )

## ----eval = FALSE-------------------------------------------------------------
# doc <- rtf_document() %>%
#   rtf_config(page = list(orientation = "portrait"))

## ----eval = FALSE-------------------------------------------------------------
# # Single table per page
# doc <- rtf_document() %>%
#   rtf_tables(list(df1, df2, df3))
# 
# # Multiple tables on one page
# doc <- rtf_document() %>%
#   rtf_tables(list(df1, list(df2a, df2b), df3))
# # Results in: df1 on page 1, df2a+df2b on page 2, df3 on page 3

## ----eval = FALSE-------------------------------------------------------------
# # Named list + auto_section = TRUE  →  one RTF section per element
# doc <- rtf_document() |>
#   rtf_section(secinfo = list(header = common_hdr, footer = common_ftr)) |>
#   rtf_tables(
#     list("Parameter A" = tbl_a, "Parameter B" = tbl_b),
#     auto_section = TRUE            # label_align = "left" (default)
#   )

## ----eval = FALSE-------------------------------------------------------------
# doc <- rtf_document() %>%
#   rtf_figures(list("plot1.png", "plot2.png"))

## ----eval = FALSE-------------------------------------------------------------
# # Single section starting at page 1
# doc <- rtf_document() %>%
#   rtf_tables(list(df1, df2, df3)) %>%
#   rtf_section(page = 1, secinfo = list(
#     header = rtf_header(rows = list(l = "Analysis", r = "Table 1")),
#     footer = rtf_footer(rows = list(c = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}"))
#   ))
# 
# # Multiple sections
# doc <- rtf_document() %>%
#   rtf_tables(list(df1, df2, df3)) %>%
#   rtf_section(
#     page = c(1, 3),
#     secinfo = list(
#       list(header = h1, footer = f1),  # Section 1 (pages 1-2)
#       list(header = h2, footer = f2)   # Section 2 (pages 3+)
#     )
#   )

## ----eval = FALSE-------------------------------------------------------------
# doc <- rtf_document() |>
#   rtf_section(secinfo = list(header = common_hdr, footer = common_ftr))
#   # page= is omitted → stored as "_default" template

## ----eval = FALSE-------------------------------------------------------------
# doc <- rtf_document() %>%
#   rtf_tables(list(df1, df2, df3)) %>%
#   rtf_table_format(pages = "all", border = "tfl", row_height_twips = 280L) %>%
#   rtf_table_format(pages = 1, border = "none")  # Override page 1

## ----eval = FALSE-------------------------------------------------------------
# doc <- doc %>%
#   rtf_header_format(pages = "all", border = "top", row_height_twips = 280L) %>%
#   rtf_footer_format(pages = c(1, 3), border = "top")

## ----eval = FALSE-------------------------------------------------------------
# doc <- doc %>%
#   rtf_figure_format(pages = "all", width_twips = 8000L, height_twips = 6000L)

## ----eval = FALSE-------------------------------------------------------------
# library(rtfreporter)
# library(magrittr)  # For %>% pipe
# 
# # Prepare data
# df_safety <- data.frame(
#   Event = c("Headache", "Nausea", "Dizziness"),
#   Mild = c(5, 3, 2),
#   Moderate = c(2, 1, 1),
#   Severe = c(0, 0, 1)
# )
# 
# df_efficacy <- data.frame(
#   Response = c("Complete", "Partial", "No Response"),
#   Count = c(25, 15, 10),
#   Percent = c("50%", "30%", "20%")
# )
# 
# # Create report
# report <- rtf_document() %>%
#   # Configure document (one-time)
#   rtf_config(page = list(
#     orientation = "landscape",
#     width_in = 11,
#     height_in = 8.5
#   )) %>%
#   # Add content
#   rtf_tables(list(df_safety, df_efficacy)) %>%
#   # Define sections with headers/footers
#   rtf_section(page = 1, secinfo = list(
#     header = rtf_header(rows = list(
#       l = "Clinical Study Report",
#       r = "Safety Analysis"
#     )),
#     footer = rtf_footer(rows = list(
#       c = "Page {CURRENT_PAGE} of {AUTO_TOTAL_PAGES}"
#     ))
#   )) %>%
#   rtf_section(page = 2, secinfo = list(
#     header = rtf_header(rows = list(
#       l = "Clinical Study Report",
#       r = "Efficacy Analysis"
#     )),
#     footer = rtf_footer(rows = list(
#       c = "Page {CURRENT_PAGE} of {AUTO_TOTAL_PAGES}"
#     ))
#   )) %>%
#   # Apply formatting (multiple calls safe, later ones override)
#   rtf_table_format(pages = "all", border = "tfl", row_height_twips = 280L) %>%
#   rtf_header_format(pages = "all", border = "top", row_height_twips = 300L)
# 
# # Generate RTF file
# generate_rtfreport(report, "clinical_report.rtf", overwrite = TRUE)

## ----eval = FALSE-------------------------------------------------------------
# library(rtfreporter)
# 
# data_dir <- system.file("extdata", package = "rtfreporter")
# lab_rbc <- readRDS(file.path(data_dir, "lab_rbc.rds"))
# lab_wbc <- readRDS(file.path(data_dir, "lab_wbc.rds"))
# lab_hgb <- readRDS(file.path(data_dir, "lab_hgb.rds"))
# 
# # Spanning header and column-header row (identical for all parameters)
# spanning_hdr <- list(
#   list(from = 2L,  to = 7L,  label = "Drug A (N=30)", underline = TRUE),
#   list(from = 8L,  to = 13L, label = "Drug B (N=30)", underline = TRUE),
#   list(from = 14L, to = 19L, label = "Total (N=60)",  underline = TRUE)
# )
# col_hdr <- c("Baseline\nGrade", rep(c("0","1","2","3","4","Total"), 3L))
# 
# make_shift_tbl <- function(df) {
#   rtftable(
#     df,
#     col_header          = col_hdr,
#     spanning_header     = spanning_hdr,
#     column_widths_twips = c(1200L, rep(733L, 18L)),
#     col_spec = c(
#       list(list(col = 1, align = "left")),
#       lapply(2:19, function(j) list(col = j, align = "center"))
#     ),
#     row_height_twips = 360L,
#     border           = "tfl",
#     table_align      = "left"
#   )
# }

## ----eval = FALSE-------------------------------------------------------------
# common_hdr <- rtf_header(rows = list(
#   c(l = "Protocol: STUDY001",
#     r = "DRAFT"),
#   c(l = "Drug Co., Ltd.",
#     r = "Page {AUTO_PAGE} of {AUTO_TOTAL_PAGES}"),
#   c(c = "Table 14.x.x.x  Shift table of Toxicity Grade"),
#   c(c = "<Safety Analysis Set>"),
#   c(c = "")   # blank row — row 6 appended automatically per section
# ))
# 
# common_ftr <- rtf_footer(rows = list(
#   c(l = paste0(
#     "Note: Percentages are based on the number of subjects in the Safety ",
#     "Analysis Set (N) for each treatment group. ",
#     "Run date: ", Sys.Date()
#   ))
# ))

## ----eval = FALSE-------------------------------------------------------------
# doc <- rtf_document() |>
#   rtf_config(page = list(
#     orientation    = "landscape",
#     width_in       = 11,    height_in      = 8.5,
#     margin_top_in  = 0.75,  margin_bottom_in = 0.75,
#     margin_left_in = 0.5,   margin_right_in  = 0.5
#   )) |>
#   # Register the common header/footer as the "_default" template
#   # (page= is intentionally omitted)
#   rtf_section(secinfo = list(header = common_hdr, footer = common_ftr)) |>
#   # Named list → one RTF section per element
#   # The element name is appended as a left-aligned row 6 in the header
#   rtf_tables(
#     list(
#       "Red Blood Cell Count (10^6/uL)"   = make_shift_tbl(lab_rbc),
#       "White Blood Cell Count (10^3/uL)" = make_shift_tbl(lab_wbc),
#       "Hemoglobin (g/dL)"                = make_shift_tbl(lab_hgb)
#     ),
#     auto_section = TRUE          # section_label_align = "left" by default
#   )
# 
# generate_rtfreport(doc, "lab_shift.rtf", overwrite = TRUE)

## ----eval = FALSE-------------------------------------------------------------
# lab_params <- list(
#   list(param = "Red Blood Cell Count (10^6/uL)",   data = lab_rbc),
#   list(param = "White Blood Cell Count (10^3/uL)", data = lab_wbc),
#   list(param = "Hemoglobin (g/dL)",                data = lab_hgb)
# )
# 
# make_lab_hdr <- function(label) {
#   update_header_row(
#     rtf_header(rows = common_hdr_rows),
#     row = 6L, content = c(l = label)
#   )
# }
# 
# doc <- rtf_document() |>
#   rtf_config(page = list(...))
# 
# for (i in seq_along(lab_params)) {
#   doc <- doc |>
#     rtf_tables(list(make_shift_tbl(lab_params[[i]]$data))) |>
#     rtf_section(page    = i,
#                 secinfo = list(header = make_lab_hdr(lab_params[[i]]$param),
#                                footer = common_ftr))
# }

## ----eval = FALSE-------------------------------------------------------------
# report <- rtf_document() %>%
#   rtf_tables(list(df1, df2)) %>%
#   rtf_section(page = 1, secinfo = sec_info) %>%
#   rtf_table_format(pages = "all", border = "tfl")

## ----eval = FALSE-------------------------------------------------------------
# report <- rtfreport()
# sec <- report$add_section(header = h1, footer = f1)
# report$add_page(section_index = sec, content = list(rtftable(df1)))
# report$add_page(section_index = sec, content = list(rtftable(df2)))
# report$set_default_page(...)

## ----eval = FALSE-------------------------------------------------------------
# # This is safe - only updates page 1
# doc <- doc %>%
#   rtf_table_format(pages = 1, border = "none")
# 
# # Later call doesn't overwrite - NULL means "no change"
# doc <- doc %>%
#   rtf_table_format(pages = "all", row_height_twips = 300L)
# # Result: page 1 has border="none", row_height=300L
# #         other pages have border="tfl", row_height=300L

