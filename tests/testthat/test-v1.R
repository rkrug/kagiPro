testthat::test_that("kagi_connection defaults to v1 and rejects unknown api_version", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  testthat::expect_s3_class(conn, "kagi_connection")
  testthat::expect_equal(conn$api_version, "v1")
  testthat::expect_equal(conn$url, "https://kagi.com/api/v1")

  testthat::expect_error(
    kagiPro::kagi_connection(api_key = "dummy", api_version = "v0"),
    "'arg' should be"
  )
})

testthat::test_that("kagi_query_search returns named list of query objects", {
  q <- kagiPro::kagi_query_search("biodiversity")
  testthat::expect_type(q, "list")
  testthat::expect_named(q, paste0("query_", seq_along(q)))
  testthat::expect_s3_class(q[[1]], "kagi_query_search")
  testthat::expect_equal(q[[1]]$query, "biodiversity")
  testthat::expect_equal(q[[1]]$workflow, "search")
})

testthat::test_that("kagi_query_search default body is neutral (no lens, no weights, nothing)", {
  q <- kagiPro::kagi_query_search("biodiversity")[[1]]
  body <- unclass(q)
  # Only `query` and `workflow` should be present. No lens, lens_id, filters,
  # personalizations, safe_search, extract, page, limit, timeout, format.
  testthat::expect_setequal(names(body), c("query", "workflow"))
  testthat::expect_equal(body$workflow, "search")
})

testthat::test_that("kagi_query_search expand = TRUE produces one object per term", {
  q <- kagiPro::kagi_query_search(c("biodiversity", "ecosystem"))
  testthat::expect_length(q, 2L)
  testthat::expect_equal(q[[1]]$query, "biodiversity")
  testthat::expect_equal(q[[2]]$query, "ecosystem")
})

testthat::test_that("kagi_query_search expand = FALSE concatenates queries", {
  q <- kagiPro::kagi_query_search(c("biodiversity", "loss"), expand = FALSE)
  testthat::expect_length(q, 1L)
  testthat::expect_equal(q[[1]]$query, "biodiversity loss")
})

testthat::test_that("kagi_query_search validates numeric bounds", {
  testthat::expect_error(
    kagiPro::kagi_query_search("x", timeout = 0.1),
    "between 0.5 and 4"
  )
  testthat::expect_error(
    kagiPro::kagi_query_search("x", page = 0),
    "between 1 and 10"
  )
  testthat::expect_error(
    kagiPro::kagi_query_search("x", limit = 2000),
    "between 1 and 1024"
  )
})

testthat::test_that("kagi_query_search rejects combined lens + lens_id", {
  testthat::expect_error(
    kagiPro::kagi_query_search(
      "x",
      lens = list(file_type = "pdf"),
      lens_id = "abc"
    ),
    "at most one"
  )
})

testthat::test_that("kagi_query_extract validates and chunks URLs", {
  q1 <- kagiPro::kagi_query_extract("https://example.com/a")
  testthat::expect_length(q1, 1L)
  testthat::expect_s3_class(q1[[1]], "kagi_query_extract")
  testthat::expect_length(q1[[1]]$pages, 1L)

  q15 <- kagiPro::kagi_query_extract(paste0("https://example.com/", 1:15))
  testthat::expect_length(q15, 2L)
  testthat::expect_length(q15[[1]]$pages, 10L)
  testthat::expect_length(q15[[2]]$pages, 5L)
})

testthat::test_that("kagi_query_extract rejects non-HTTPS URLs", {
  testthat::expect_error(
    kagiPro::kagi_query_extract("http://example.com/a"),
    "HTTPS"
  )
})

testthat::test_that("OpenAPI spec ships with the package", {
  p <- system.file("api_specs/openapi.yaml", package = "kagiPro")
  testthat::expect_true(nzchar(p))
  testthat::expect_true(file.exists(p))
})
