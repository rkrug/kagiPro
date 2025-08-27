# tests/testthat/setup-vcr.R
# Configure vcr to record/replay Kagi API requests made via httr2

if (requireNamespace("vcr", quietly = TRUE)) {
  vcr::vcr_configure(
    dir = testthat::test_path("fixtures/cassettes"),
    record = Sys.getenv("VCR_RECORD_MODE", unset = "once"),
    filter_sensitive_data = list(
      "<<KAGI_API_KEY>>" = Sys.getenv("KAGI_API_KEY")
    ),
    filter_request_headers = list("Authorization"),
    match_requests_on = c("method", "uri", "body")
  )
  # Ensure directory exists
  dir.create(
    testthat::test_path("fixtures/cassettes"),
    recursive = TRUE,
    showWarnings = FALSE
  )
}
