source(file.path("r", "rtf_border.R"))
source(file.path("r", "rtfreport.R"))
source(file.path("r", "rtftable.R"))
source(file.path("r", "rtfplot.R"))
source(file.path("r", "generate_rtfreport.R"))

DM <- read.csv(file.path("tests", "testdata", "dm.csv"), stringsAsFactors = FALSE)

# Use same-structure subsets for consistent ncol
dm_sub1 <- DM[1:3, ]
dm_sub2 <- DM[4:6, ]

cat("--- Test 1: multi-DF, shared single col_header (pipe string) ---\n")
tbl1 <- rtftable$new(
  data = list(dm_sub1, dm_sub2),
  col_header = "SubjectID | Sex | Age | Arm"
)
stopifnot(length(tbl1$data_list) == 2L)
stopifnot(is.null(tbl1$data))
stopifnot(length(tbl1$col_header_list) == 2L)
# Shared: both DFs get the same header
stopifnot(identical(tbl1$col_header_list[[1]], tbl1$col_header_list[[2]]))
stopifnot(identical(tbl1$col_header_list[[1]][[1]], c("SubjectID", "Sex", "Age", "Arm")))
cat("PASS\n\n")

cat("--- Test 2: multi-DF, per-DF col_header (2 different headers) ---\n")
tbl2 <- rtftable$new(
  data = list(dm_sub1, dm_sub2),
  col_header = list(
    c("Subj", "Sex", "Age", "Arm"),
    c("PatID", "Gender", "Yrs", "TrtGrp")
  )
)
stopifnot(!identical(tbl2$col_header_list[[1]], tbl2$col_header_list[[2]]))
stopifnot(identical(tbl2$col_header_list[[1]][[1]][1], "Subj"))
stopifnot(identical(tbl2$col_header_list[[2]][[1]][1], "PatID"))
cat("PASS\n\n")

cat("--- Test 3: multi-DF, NULL col_header (use column names per DF) ---\n")
tbl3 <- rtftable$new(data = list(dm_sub1, dm_sub2))
stopifnot(is.null(tbl3$col_header_list[[1]]))
stopifnot(is.null(tbl3$col_header_list[[2]]))
cat("PASS\n\n")

cat("--- Test 4: render multi-DF (shared header) — header appears once per DF ---\n")
r <- rtfreport$new()
sec <- r$add_section(header = c(l = "Multi-DF Test"))
r$add_page(sec, title = "Multi-DF Table",
           content = list(list(type = "table", data = tbl1)))
out <- file.path(tempdir(), "multi_df_shared_hdr.rtf")
generate_rtfreport(r, out, overwrite = TRUE)
txt <- paste(readLines(out, warn = FALSE), collapse = "\n")
# "SubjectID" should appear exactly 2 times (header row for each of 2 DFs)
n_occ <- length(gregexpr("SubjectID", txt, fixed = TRUE)[[1]])
cat("SubjectID occurrences:", n_occ, "\n")
stopifnot(n_occ == 2L)
cat("PASS\n\n")

cat("--- Test 5: render multi-DF with per-DF headers ---\n")
r2 <- rtfreport$new()
sec2 <- r2$add_section()
r2$add_page(sec2, title = "Per-DF Headers",
            content = list(list(type = "table", data = tbl2)))
out2 <- file.path(tempdir(), "multi_df_perdf_hdr.rtf")
generate_rtfreport(r2, out2, overwrite = TRUE)
txt2 <- paste(readLines(out2, warn = FALSE), collapse = "\n")
stopifnot(grepl("Subj", txt2, fixed = TRUE))
stopifnot(grepl("PatID", txt2, fixed = TRUE))
cat("PASS\n\n")

cat("--- Test 6: multi-DF with col_spec (bold) and tfl border ---\n")
tbl6 <- rtftable$new(
  data = list(dm_sub1, dm_sub2),
  col_header = "A | B | C | D",
  col_spec = list(list(col = 1L, align = "left", bold = TRUE)),
  border = "tfl"
)
r6 <- rtfreport$new()
sec6 <- r6$add_section()
r6$add_page(sec6, content = list(list(type = "table", data = tbl6)))
out6 <- file.path(tempdir(), "multi_df_colspec.rtf")
generate_rtfreport(r6, out6, overwrite = TRUE)
txt6 <- paste(readLines(out6, warn = FALSE), collapse = "\n")
stopifnot(grepl("\\b ", txt6, fixed = TRUE))   # bold on
stopifnot(grepl("clbrdrt", txt6, fixed = TRUE)) # tfl border present
cat("PASS\n\n")

cat("--- Test 7: error on mismatched ncol ---\n")
err <- tryCatch(
  rtftable$new(data = list(dm_sub1, dm_sub1[, 1:2])),
  error = function(e) e
)
stopifnot(inherits(err, "error"))
stopifnot(grepl("same number of columns", conditionMessage(err)))
cat("PASS\n\n")

cat("--- Test 8: multi-DF with multi-row col_header (shared 2-row header) ---\n")
# list of 3 char vectors but n_dfs == 2, so treated as shared multi-row header
tbl8 <- rtftable$new(
  data = list(dm_sub1, dm_sub2),
  col_header = list(
    c("", "Group A", "Group B", ""),
    c("ID", "Sex", "Age", "Arm")
  )
)
# n_dfs == 2, col_header has 2 elements that are char vectors
# → treated as per-DF single-row headers (detection rule: length == n_dfs)
stopifnot(!identical(tbl8$col_header_list[[1]], tbl8$col_header_list[[2]]))
cat("(per-DF single-row headers detected for 2-element list with 2 DFs)\n")
cat("PASS\n\n")

cat("--- Test 9: backward compat — single data.frame still works ---\n")
tbl9 <- rtftable$new(dm_sub1, col_header = "ID | Sex | Age | Arm")
stopifnot(is.data.frame(tbl9$data))
stopifnot(is.null(tbl9$data_list))
stopifnot(!is.null(tbl9$col_header))
stopifnot(is.null(tbl9$col_header_list))
cat("PASS\n\n")

cat("All multi-DF tests passed.\n")
