# Tests for kagi_open_search_query(). browseURL is mocked so no real
# browser is opened.

with_mocked_browse <- function(expr) {
  ns <- asNamespace("utils")
  original <- get("browseURL", envir = ns)
  calls <- new.env(parent = emptyenv())
  calls$urls <- character()

  stub <- function(url, ...) {
    calls$urls <- c(calls$urls, url)
    invisible(url)
  }

  unlockBinding("browseURL", ns)
  assign("browseURL", stub, envir = ns)
  on.exit({
    assign("browseURL", original, envir = ns)
    lockBinding("browseURL", ns)
  }, add = TRUE)

  list(value = force(expr), urls = calls$urls)
}

testthat::test_that("opens a single kagi_query_search object", {
  q <- kagiPro::kagi_query_search("biodiversity")[[1]]
  out <- with_mocked_browse(kagiPro::kagi_open_search_query(q))
  testthat::expect_length(out$urls, 1L)
  testthat::expect_true(startsWith(out$urls[[1]], "https://kagi.com/search?"))
  testthat::expect_match(out$urls[[1]], "q=biodiversity")
  testthat::expect_match(out$urls[[1]], "workflow=search")
})

testthat::test_that("opens every query in a list", {
  q <- kagiPro::kagi_query_search(c("a", "b", "c"))
  out <- with_mocked_browse(kagiPro::kagi_open_search_query(q))
  testthat::expect_length(out$urls, 3L)
  testthat::expect_true(all(grepl("^https://kagi.com/search\\?", out$urls)))
  testthat::expect_match(out$urls[[1]], "q=a")
  testthat::expect_match(out$urls[[2]], "q=b")
  testthat::expect_match(out$urls[[3]], "q=c")
})

testthat::test_that("URL encodes shaping fields", {
  q <- kagiPro::kagi_query_search(
    "climate change",
    workflow = "news",
    limit = 50,
    safe_search = TRUE,
    lens_id = "abc",
    filters = list(region = "DE")
  )[[1]]
  out <- with_mocked_browse(kagiPro::kagi_open_search_query(q))
  url <- out$urls[[1]]
  testthat::expect_match(url, "q=climate%20change")
  testthat::expect_match(url, "workflow=news")
  testthat::expect_match(url, "limit=50")
  testthat::expect_match(url, "safe_search=TRUE")
  testthat::expect_match(url, "lens_id=abc")
  # nested list is JSON-encoded then URL-encoded
  testthat::expect_match(url, "filters=%7B%22region%22%3A%22DE%22%7D")
})

testthat::test_that("session_token is prepended when supplied", {
  q <- kagiPro::kagi_query_search("biodiversity")[[1]]
  out <- with_mocked_browse(
    kagiPro::kagi_open_search_query(q, session_token = "tok-123")
  )
  testthat::expect_match(out$urls[[1]], "^https://kagi.com/search\\?token=tok-123&")
})

testthat::test_that("rejects non-kagi_query_search inputs", {
  testthat::expect_error(
    kagiPro::kagi_open_search_query("a plain string"),
    "kagi_query_search"
  )
  testthat::expect_error(
    kagiPro::kagi_open_search_query(list()),
    "kagi_query_search"
  )
  testthat::expect_error(
    kagiPro::kagi_open_search_query(list(structure("x", class = "kagi_query_extract"))),
    "kagi_query_search"
  )
})

testthat::test_that("returns the URLs invisibly", {
  q <- kagiPro::kagi_query_search("biodiversity")[[1]]
  with_mocked_browse({
    val <- kagiPro::kagi_open_search_query(q)
    testthat::expect_type(val, "character")
    testthat::expect_length(val, 1L)
  })
})
