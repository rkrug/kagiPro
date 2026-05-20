# tests/testthat/setup-vcr.R
# Configure vcr to record/replay Kagi API requests made via httr2.
# Default record mode is "once": replay if the cassette exists, otherwise
# perform the live request and record. If neither KAGI_API_KEY nor a keyring
# entry "API_kagi" is available, network-touching tests should `skip`
# themselves via `api_key_for_cassette()` in helper_kagi.R.

if (requireNamespace("vcr", quietly = TRUE)) {
  # Resolve the real key (env var first, then keyring) just for the
  # sensitive-data filter — we do NOT export it as KAGI_API_KEY here.
  .kagi_real_key <- tryCatch(get_kagi_api_key(), error = function(e) "")

  vcr::vcr_configure(
    dir = testthat::test_path("fixtures/cassettes"),
    record = cassette_record_mode(),
    filter_sensitive_data = list(
      "<<KAGI_API_KEY>>" = .kagi_real_key
    ),
    filter_request_headers = list("Authorization"),
    match_requests_on = c("method", "uri", "body")
  )
  rm(.kagi_real_key)

  dir.create(
    testthat::test_path("fixtures/cassettes"),
    recursive = TRUE,
    showWarnings = FALSE
  )
}
