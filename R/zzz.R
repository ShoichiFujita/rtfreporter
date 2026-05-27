# Package-load hooks.

.onLoad <- function(libname, pkgname) {
  # Initialise the optional rtf_theme R6 class generator, if R6 is
  # installed.  All other classes are S3 and do not require any setup.
  .init_rtf_theme_class()
  invisible()
}
