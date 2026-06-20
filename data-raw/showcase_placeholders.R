# data-raw/showcase_placeholders.R
# ---------------------------------------------------------------------------
# Write a "Waiting for snapshot" DUMMY PNG for every showcase framework whose
# real Word screenshot has not been captured yet, so the article (and the
# pkgdown site) shows a clearly-labelled placeholder image instead of an empty
# slot.  Real snapshots are captured MANUALLY (open the matching .rtf in Word,
# export / screenshot) and saved over these with the SAME basename.
#
# Existing PNGs are NEVER overwritten -- once a real snapshot replaces a dummy,
# re-running this script leaves it alone.
#
# Run with:  Rscript data-raw/showcase_placeholders.R
# ---------------------------------------------------------------------------

snap_dir <- "inst/rtf-examples/showcase"
dir.create(snap_dir, showWarnings = FALSE, recursive = TRUE)

# One placeholder per rendered RTF in the showcase directory.
rtfs <- list.files(snap_dir, pattern = "\\.rtf$", full.names = FALSE)

for (rtf in rtfs) {
  nm  <- sub("\\.rtf$", "", rtf)
  png <- file.path(snap_dir, paste0(nm, ".png"))
  if (file.exists(png)) next                       # keep real snapshots

  grDevices::png(png, width = 1200, height = 720, res = 120)
  op <- graphics::par(mar = c(0, 0, 0, 0))
  graphics::plot.new()
  graphics::rect(0, 0, 1, 1, col = "#f4f4f4", border = "#cccccc")
  graphics::text(0.5, 0.60, "Waiting for snapshot", cex = 2.0, font = 2,
                 col = "#444444")
  graphics::text(0.5, 0.46, nm, cex = 1.2, col = "#666666")
  graphics::text(0.5, 0.36,
                 sprintf("Open %s.rtf in Word and replace this PNG", nm),
                 cex = 0.95, col = "#888888")
  graphics::par(op)
  grDevices::dev.off()
  cat(sprintf("  placeholder %s\n", png))
}

cat("Done.\n")
