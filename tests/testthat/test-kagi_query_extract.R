testthat::test_that("kagi_query_extract returns typed objects", {
  q <- kagiPro::kagi_query_extract("https://example.com/a")
  testthat::expect_length(q, 1L)
  testthat::expect_s3_class(q[[1]], "kagi_query_extract")
  testthat::expect_named(q, "query_1")
  testthat::expect_length(q[[1]]$pages, 1L)
  testthat::expect_equal(q[[1]]$pages[[1]]$url, "https://example.com/a")
})

testthat::test_that("kagi_query_extract chunks at 10 URLs by default", {
  q <- kagiPro::kagi_query_extract(paste0("https://example.com/", 1:15))
  testthat::expect_length(q, 2L)
  testthat::expect_length(q[[1]]$pages, 10L)
  testthat::expect_length(q[[2]]$pages, 5L)
})

testthat::test_that("kagi_query_extract honours chunk_size override", {
  q <- kagiPro::kagi_query_extract(
    paste0("https://example.com/", 1:7),
    chunk_size = 3
  )
  testthat::expect_length(q, 3L)
  testthat::expect_equal(
    unname(vapply(q, function(x) length(x$pages), integer(1))),
    c(3L, 3L, 1L)
  )
})

testthat::test_that("kagi_query_extract validates HTTPS only", {
  testthat::expect_error(kagiPro::kagi_query_extract("http://example.com"), "HTTPS")
  testthat::expect_error(kagiPro::kagi_query_extract("ftp://example.com"), "HTTPS")
  testthat::expect_error(kagiPro::kagi_query_extract("example.com"), "HTTPS")
})

testthat::test_that("kagi_query_extract rejects empty / wrong-type input", {
  testthat::expect_error(kagiPro::kagi_query_extract(NULL), "required")
  testthat::expect_error(kagiPro::kagi_query_extract(character(0)), "non-empty")
  testthat::expect_error(kagiPro::kagi_query_extract(c("https://a", "")), "empty entries")
  testthat::expect_error(kagiPro::kagi_query_extract(1L), "non-empty")
})

testthat::test_that("kagi_query_extract validates chunk_size bounds", {
  testthat::expect_error(
    kagiPro::kagi_query_extract("https://a", chunk_size = 0),
    "between 1 and 10"
  )
  testthat::expect_error(
    kagiPro::kagi_query_extract("https://a", chunk_size = 11),
    "between 1 and 10"
  )
})

testthat::test_that("kagi_query_extract optional fields land in body", {
  q <- kagiPro::kagi_query_extract(
    "https://example.com/a",
    timeout = 3,
    format = "markdown"
  )[[1]]
  body <- unclass(q)
  testthat::expect_equal(body$timeout, 3)
  testthat::expect_equal(body$format, "markdown")
})

testthat::test_that("print.kagi_query_extract renders URLs", {
  q <- kagiPro::kagi_query_extract(paste0("https://example.com/", 1:3))[[1]]
  out <- utils::capture.output(print(q))
  testthat::expect_true(any(grepl("<kagi_query_extract>", out, fixed = TRUE)))
  testthat::expect_true(any(grepl("https://example.com/1", out, fixed = TRUE)))
})
