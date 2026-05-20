# Cassette-backed tests for kagi_request().
# See helper_kagi.R for the cassette policy (KAGIPRO_RECORD_CASSETTES,
# VCR_RECORD_MODE). Existing cassettes are replayed by default; nothing
# is re-recorded on routine local runs.

testthat::test_that("kagi_request search: single query, success", {
  cn <- "kagi-request-search-success"
  skip_if_cannot_serve_cassette(cn)
  conn <- make_kagi_test_conn(cn)
  q <- kagiPro::kagi_query_search("kagiPro test", limit = 5)[[1]]
  out <- tempfile("kagi-req-search-")
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  vcr::use_cassette(cn, {
    res <- kagiPro::kagi_request(
      connection = conn,
      query = q,
      pages = 1,
      output = out,
      overwrite = TRUE,
      verbose = FALSE
    )
  })

  testthat::expect_true(dir.exists(res))
  testthat::expect_true(file.exists(file.path(res, "search_1.json")))
  testthat::expect_true(file.exists(file.path(res, "_query_meta.json")))

  payload <- jsonlite::fromJSON(file.path(res, "search_1.json"), simplifyVector = FALSE)
  testthat::expect_true(is.list(payload$data))
})

testthat::test_that("kagi_request extract: single chunk, success", {
  cn <- "kagi-request-extract-success"
  skip_if_cannot_serve_cassette(cn)
  conn <- make_kagi_test_conn(cn)
  q <- kagiPro::kagi_query_extract("https://example.com")[[1]]
  out <- tempfile("kagi-req-extract-")
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  vcr::use_cassette(cn, {
    res <- kagiPro::kagi_request(
      connection = conn,
      query = q,
      output = out,
      overwrite = TRUE,
      verbose = FALSE
    )
  })

  testthat::expect_true(file.exists(file.path(res, "extract_1.json")))
  payload <- jsonlite::fromJSON(file.path(res, "extract_1.json"), simplifyVector = FALSE)
  testthat::expect_true(is.list(payload$data) || is.null(payload$data))
})

testthat::test_that("kagi_request: list of queries writes per-query subdirs", {
  cn <- "kagi-request-search-list"
  skip_if_cannot_serve_cassette(cn)
  conn <- make_kagi_test_conn(cn)
  q <- kagiPro::kagi_query_search(c("alpha", "beta"), limit = 5)
  out <- tempfile("kagi-req-list-")
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  vcr::use_cassette(cn, {
    res <- kagiPro::kagi_request(
      connection = conn,
      query = q,
      pages = 1,
      output = out,
      overwrite = TRUE,
      verbose = FALSE
    )
  })

  testthat::expect_true(dir.exists(file.path(res, "query_1")))
  testthat::expect_true(dir.exists(file.path(res, "query_2")))
  testthat::expect_true(file.exists(file.path(res, "query_1", "search_1.json")))
  testthat::expect_true(file.exists(file.path(res, "query_2", "search_1.json")))
})

testthat::test_that("kagi_request: error_mode='write_dummy' writes a dummy payload on failure", {
  cn <- "kagi-request-dummy"
  skip_if_cannot_serve_cassette(cn)
  # Bad API key forces a 401/403; with write_dummy we get a structured
  # error payload on disk and a warning instead of an abort.
  conn <- kagiPro::kagi_connection(api_key = "deliberately-bad-key", max_tries = 1L)
  q <- kagiPro::kagi_query_search("kagiPro test", limit = 1)[[1]]
  out <- tempfile("kagi-req-dummy-")
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  res <- NULL
  vcr::use_cassette(cn, {
    testthat::expect_warning({
      res <- kagiPro::kagi_request(
        connection = conn,
        query = q,
        pages = 1,
        output = out,
        overwrite = TRUE,
        verbose = FALSE,
        error_mode = "write_dummy"
      )
    })
  })

  testthat::expect_true(file.exists(file.path(res, "search_1.json")))
  payload <- jsonlite::fromJSON(file.path(res, "search_1.json"), simplifyVector = FALSE)
  testthat::expect_true(startsWith(payload$meta$id %||% "", "error_"))
  testthat::expect_true(is.list(payload$error))
})

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x
