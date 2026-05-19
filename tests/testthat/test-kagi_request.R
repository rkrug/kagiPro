# Cassette-backed tests for kagi_request().
#
# On first run (when no cassette exists), vcr records the live API
# response — this requires a usable key from `KAGI_API_KEY` or the keyring
# entry "API_kagi". On subsequent runs the cassette is replayed and no
# network call is made; a placeholder key is used so the suite still
# passes in CI / on machines without credentials.

skip_unless_recordable <- function(cassette_name) {
  if (file.exists(cassette_path(cassette_name))) {
    return(invisible(NULL))
  }
  if (!requireNamespace("vcr", quietly = TRUE)) {
    testthat::skip("vcr not available; cannot record cassette.")
  }
  key <- get_kagi_api_key()
  if (!nzchar(key)) {
    testthat::skip(paste0(
      "Missing Kagi API key for recording cassette `", cassette_name,
      "`. Set KAGI_API_KEY or store keyring entry `API_kagi`."
    ))
  }
  invisible(NULL)
}

make_conn <- function(cassette_name) {
  key <- if (file.exists(cassette_path(cassette_name))) {
    "dummy-kagi-key"
  } else {
    get_kagi_api_key()
  }
  kagiPro::kagi_connection(api_key = key, max_tries = 1L)
}

testthat::test_that("kagi_request search: single query, success", {
  cn <- "kagi-request-search-success"
  skip_unless_recordable(cn)
  conn <- make_conn(cn)
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
  skip_unless_recordable(cn)
  conn <- make_conn(cn)
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
  skip_unless_recordable(cn)
  conn <- make_conn(cn)
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
  skip_unless_recordable(cn)
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
