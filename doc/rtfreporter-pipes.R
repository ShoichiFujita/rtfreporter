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
# doc <- rtf_document() %>%
#   rtf_figures(list("plot1.png", "plot2.png"))

## ----eval = FALSE-------------------------------------------------------------
# # Single section starting at page 1
# doc <- rtf_document() %>%
#   rtf_tables(list(df1, df2, df3)) %>%
#   rtf_section(page = 1, secinfo = list(
#     header = rtf_header(rows = list(l = "Analysis", r = "Table 1")),
#     footer = rtf_footer(rows = list(c = "Page {CURRENT_PAGE}"))
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

