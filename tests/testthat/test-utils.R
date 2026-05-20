# Tests for internal dispatch helpers in R/utils.R.

testthat::test_that("kagi_query_classes lists current classes", {
  cls <- kagiPro:::kagi_query_classes()
  testthat::expect_setequal(cls, c("kagi_query_search", "kagi_query_extract"))
})

testthat::test_that("endpoint_from_query_class maps classes to endpoints", {
  testthat::expect_equal(
    kagiPro:::endpoint_from_query_class("kagi_query_search"),
    "search"
  )
  testthat::expect_equal(
    kagiPro:::endpoint_from_query_class("kagi_query_extract"),
    "extract"
  )
  testthat::expect_error(
    kagiPro:::endpoint_from_query_class("kagi_query_other"),
    "Unknown Query Class"
  )
})

testthat::test_that("endpoint_path_from_query_class matches endpoint", {
  testthat::expect_equal(
    kagiPro:::endpoint_path_from_query_class("kagi_query_search"),
    "search"
  )
  testthat::expect_equal(
    kagiPro:::endpoint_path_from_query_class("kagi_query_extract"),
    "extract"
  )
  testthat::expect_error(
    kagiPro:::endpoint_path_from_query_class("kagi_query_other"),
    "Unknown Query Class"
  )
})

testthat::test_that("unclass_query strips kagi_query_* class tags", {
  q <- kagiPro::kagi_query_search("x")[[1]]
  bare <- kagiPro:::unclass_query(q)
  testthat::expect_false(inherits(bare, "kagi_query_search"))
  testthat::expect_true(is.list(bare))
  testthat::expect_equal(bare$query, "x")
})

testthat::test_that("serialize_query_payload returns a plain list", {
  q <- kagiPro::kagi_query_search("biodiversity", limit = 5)[[1]]
  payload <- kagiPro:::serialize_query_payload(q)
  testthat::expect_type(payload, "list")
  testthat::expect_false(inherits(payload, "kagi_query_search"))
  testthat::expect_equal(payload$query, "biodiversity")
  testthat::expect_equal(payload$limit, 5L)
})

testthat::test_that("reconstruct_query_from_meta restores both classes", {
  search_payload <- list(query = "biodiversity", workflow = "search")
  q1 <- kagiPro:::reconstruct_query_from_meta("kagi_query_search", search_payload)
  testthat::expect_s3_class(q1, "kagi_query_search")
  testthat::expect_equal(q1$query, "biodiversity")

  extract_payload <- list(pages = list(list(url = "https://example.com/a")))
  q2 <- kagiPro:::reconstruct_query_from_meta("kagi_query_extract", extract_payload)
  testthat::expect_s3_class(q2, "kagi_query_extract")
  testthat::expect_equal(q2$pages[[1]]$url, "https://example.com/a")

  testthat::expect_error(
    kagiPro:::reconstruct_query_from_meta("kagi_query_other", list()),
    "Unsupported query_class"
  )
})

testthat::test_that("resolve_api_key resolves env var, function, and literal", {
  withr::local_envvar(KAGI_API_KEY = "env-key")
  testthat::expect_equal(kagiPro:::resolve_api_key(NULL), "env-key")
  testthat::expect_equal(kagiPro:::resolve_api_key("literal"), "literal")
  testthat::expect_equal(kagiPro:::resolve_api_key(function() "lazy"), "lazy")

  withr::local_envvar(KAGI_API_KEY = "")
  testthat::expect_error(kagiPro:::resolve_api_key(NULL), "Missing API key")
})

testthat::test_that("kagiPro_user_agent advertises the package", {
  ua <- kagiPro:::kagiPro_user_agent()
  testthat::expect_match(ua, "^kagiPro/")
})
