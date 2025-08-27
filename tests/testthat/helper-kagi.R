# tests/testthat/helper-kagi.R
# Helper utilities shared by tests

skip_if_no_kagi_key <- function() {
  if (!nzchar(Sys.getenv("KAGI_API_KEY"))) {
    testthat::skip("KAGI_API_KEY not set; skipping live-recorded tests.")
  }
}

# CRAN guidelines: skip on CRAN to avoid real HTTP during first cassette recording
skip_on_cran_if_recording <- function() {
  if (identical(Sys.getenv("NOT_CRAN"), "false")) {
    testthat::skip("Skipping on CRAN")
  }
}
