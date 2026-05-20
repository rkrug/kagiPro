# tests/testthat/helper_kagi.R
# Helper utilities shared by tests.
#
# Cassette policy
# ---------------
# vcr is configured in setup-vcr.R with `record = cassette_record_mode()`.
# The mode is resolved (in order):
#
#   1. `VCR_RECORD_MODE` env var, if set ("once", "none", "new_episodes",
#      "all" — see ?vcr::vcr_configure).
#   2. `KAGIPRO_RECORD_CASSETTES` env var:
#         "true"  -> "all"   (force re-record on every run)
#         "false" -> "none"  (strict replay; error if cassette missing
#                             or request does not match)
#   3. Default: "once" — record if the cassette is missing, replay
#      otherwise. Local re-runs do NOT re-record.
#
# Practical recipes
# -----------------
#   * Refresh / update cassettes (requires a working API key):
#         KAGIPRO_RECORD_CASSETTES=true Rscript -e 'devtools::test()'
#     or, to refresh a single cassette, delete its .yml file and re-run.
#
#   * Force strict replay (CI default — fail if a cassette is missing or
#     the live request would differ from the recording):
#         KAGIPRO_RECORD_CASSETTES=false Rscript -e 'devtools::test()'
#
#   * Normal local development:
#         Rscript -e 'devtools::test()'
#     Existing cassettes are replayed (no network, no credentials needed).
#     If a brand-new test introduces a new cassette name, it is recorded
#     once on first run.

cassette_record_mode <- function() {
  m <- Sys.getenv("VCR_RECORD_MODE", unset = "")
  if (nzchar(m)) {
    return(m)
  }
  flag <- tolower(Sys.getenv("KAGIPRO_RECORD_CASSETTES", unset = ""))
  if (identical(flag, "true"))  return("all")
  if (identical(flag, "false")) return("none")
  "once"
}

# Resolve a real key (KAGI_API_KEY or keyring "API_kagi"). Returns "" if
# no key is available.
get_kagi_api_key <- function() {
  key <- Sys.getenv("KAGI_API_KEY", "")
  if (nzchar(key)) return(key)
  if (!requireNamespace("keyring", quietly = TRUE)) return("")
  tryCatch(keyring::key_get("API_kagi"), error = function(e) "")
}

cassette_path <- function(name) {
  testthat::test_path("fixtures", "cassettes", paste0(name, ".yml"))
}

# Decide whether the current run will hit the network for a given cassette.
# `"all"` always records; `"new_episodes"` records new interactions; `"once"`
# records only if the cassette is missing; `"none"` never records.
cassette_will_record <- function(name) {
  mode <- cassette_record_mode()
  if (identical(mode, "all")) return(TRUE)
  if (identical(mode, "none")) return(FALSE)
  if (identical(mode, "new_episodes")) return(TRUE)
  # "once": record only when the cassette does not yet exist.
  !file.exists(cassette_path(name))
}

# Build a kagi_connection for cassette-backed tests. When the test will
# record, we use the real key from env/keyring; otherwise we use a
# placeholder so replay works without credentials. Tests that need a key
# (recording) but have none available should call `skip_if_no_key()`.
make_kagi_test_conn <- function(name, max_tries = 1L) {
  key <- if (cassette_will_record(name)) get_kagi_api_key() else "dummy-kagi-key"
  if (!nzchar(key)) key <- "dummy-kagi-key"
  kagiPro::kagi_connection(api_key = key, max_tries = max_tries)
}

# Skip the test if recording is required but no API key is available.
skip_if_cannot_serve_cassette <- function(name) {
  if (!cassette_will_record(name)) {
    return(invisible(NULL))
  }
  if (!requireNamespace("vcr", quietly = TRUE)) {
    testthat::skip("vcr not available; cannot record cassette.")
  }
  if (!nzchar(get_kagi_api_key())) {
    testthat::skip(paste0(
      "Cassette `", name, "` would need to be recorded but no API key is ",
      "available (set KAGI_API_KEY or store keyring entry `API_kagi`)."
    ))
  }
  invisible(NULL)
}
