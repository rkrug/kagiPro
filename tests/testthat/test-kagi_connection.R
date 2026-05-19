testthat::test_that("kagi_connection defaults are v1 / Bearer", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  testthat::expect_s3_class(conn, "kagi_connection")
  testthat::expect_equal(conn$api_version, "v1")
  testthat::expect_equal(conn$url, "https://kagi.com/api/v1")
})

testthat::test_that("kagi_connection rejects an empty api_key", {
  withr::local_envvar(KAGI_API_KEY = "")
  testthat::expect_error(
    kagiPro::kagi_connection(),
    "Missing API key"
  )
})

testthat::test_that("kagi_connection rejects unknown api_version", {
  testthat::expect_error(
    kagiPro::kagi_connection(api_key = "dummy", api_version = "v0"),
    "'arg' should be"
  )
  testthat::expect_error(
    kagiPro::kagi_connection(api_key = "dummy", api_version = "v2"),
    "'arg' should be"
  )
})

testthat::test_that("kagi_connection accepts a lazy api_key function", {
  conn <- kagiPro::kagi_connection(api_key = function() "lazy-key")
  testthat::expect_s3_class(conn, "kagi_connection")
  testthat::expect_equal(conn$api_version, "v1")
})

testthat::test_that("kagi_connection honours base_url override", {
  conn <- kagiPro::kagi_connection(
    api_key = "k",
    base_url = "https://staging.kagi.example/api/v1"
  )
  testthat::expect_equal(conn$url, "https://staging.kagi.example/api/v1")
})

testthat::test_that("kagi_connection print masks the api key", {
  conn <- kagiPro::kagi_connection(api_key = "abcdefghijklmnop")
  out <- utils::capture.output(print(conn))
  testthat::expect_false(any(grepl("abcdefghijklmnop", out, fixed = TRUE)))
  testthat::expect_true(any(grepl("api_version", out)))
})
