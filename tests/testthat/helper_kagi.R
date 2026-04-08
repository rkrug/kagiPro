# tests/testthat/helper_kagi.R
# Helper utilities shared by tests

# Resolve keyring key for first-time cassette recording.
get_kagi_api_key <- function() {
  if (!requireNamespace("keyring", quietly = TRUE)) {
    return(Sys.getenv("KAGI_API_KEY", ""))
  }

  key <- tryCatch(
    keyring::key_get("API_kagi"),
    error = function(e) ""
  )

  if (nzchar(key)) {
    return(key)
  }

  key <- Sys.getenv("KAGI_API_KEY", "")

  key
}

cassette_path <- function(name) {
  testthat::test_path("fixtures", "cassettes", paste0(name, ".yml"))
}

# If cassette exists, replay can run with a placeholder key.
# If cassette does not exist, fetch real key via keyring for live recording.
api_key_for_cassette <- function(name) {
  if (file.exists(cassette_path(name))) {
    key <- Sys.getenv("KAGI_API_KEY", "")
    if (!nzchar(key)) {
      key <- "dummy-kagi-key"
    }
    return(key)
  }

  key <- get_kagi_api_key()
  if (!nzchar(key)) {
    testthat::skip(
      paste0(
        "Missing Kagi API key for recording cassette `",
        name,
        "`. Set KAGI_API_KEY or store keyring entry API_kagi."
      )
    )
  }
  key
}

# CRAN guidelines: skip on CRAN to avoid real HTTP during first cassette recording
skip_on_cran_if_recording <- function() {
  if (identical(Sys.getenv("NOT_CRAN"), "false")) {
    testthat::skip("Skipping on CRAN")
  }
}
