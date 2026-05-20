testthat::test_that("kagi_query_search returns named list of typed objects", {
  q <- kagiPro::kagi_query_search("biodiversity")
  testthat::expect_type(q, "list")
  testthat::expect_named(q, paste0("query_", seq_along(q)))
  testthat::expect_s3_class(q[[1]], "kagi_query_search")
})

testthat::test_that("kagi_query_search default body is neutral", {
  q <- kagiPro::kagi_query_search("biodiversity")[[1]]
  body <- unclass(q)
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

testthat::test_that("kagi_query_search rejects empty / wrong-type query", {
  testthat::expect_error(kagiPro::kagi_query_search(NULL), "required")
  testthat::expect_error(kagiPro::kagi_query_search(123), "non-empty")
  testthat::expect_error(kagiPro::kagi_query_search(""), "non-empty")
  testthat::expect_error(kagiPro::kagi_query_search(c("ok", "")), "non-empty")
})

testthat::test_that("kagi_query_search validates workflow", {
  testthat::expect_error(
    kagiPro::kagi_query_search("x", workflow = "garbage"),
    "'arg' should be"
  )
  for (wf in c("search", "images", "videos", "news", "podcasts")) {
    q <- kagiPro::kagi_query_search("x", workflow = wf)[[1]]
    testthat::expect_equal(q$workflow, wf)
  }
})

testthat::test_that("kagi_query_search validates numeric bounds", {
  testthat::expect_error(kagiPro::kagi_query_search("x", timeout = 0.1), "between 0.5 and 4")
  testthat::expect_error(kagiPro::kagi_query_search("x", timeout = 5),   "between 0.5 and 4")
  testthat::expect_error(kagiPro::kagi_query_search("x", page = 0),      "between 1 and 10")
  testthat::expect_error(kagiPro::kagi_query_search("x", page = 11),     "between 1 and 10")
  testthat::expect_error(kagiPro::kagi_query_search("x", limit = 0),     "between 1 and 1024")
  testthat::expect_error(kagiPro::kagi_query_search("x", limit = 2000),  "between 1 and 1024")
})

testthat::test_that("kagi_query_search rejects combined lens + lens_id", {
  testthat::expect_error(
    kagiPro::kagi_query_search("x",
      lens = list(file_type = "pdf"),
      lens_id = "abc"
    ),
    "at most one"
  )
})

testthat::test_that("kagi_query_search validates list-shaped args", {
  testthat::expect_error(kagiPro::kagi_query_search("x", lens = "not-a-list"),    "named list")
  testthat::expect_error(kagiPro::kagi_query_search("x", filters = "no"),         "named list")
  testthat::expect_error(kagiPro::kagi_query_search("x", extract = "no"),         "named list")
  testthat::expect_error(kagiPro::kagi_query_search("x", personalizations = "no"),"named list")
})

testthat::test_that("kagi_query_search file_type validates whitelist", {
  # valid
  q <- kagiPro::kagi_query_search("x", file_type = c("pdf", "tex"))[[1]]
  testthat::expect_match(q$query, "filetype:pdf")
  testthat::expect_match(q$query, "filetype:tex")
  # invalid
  testthat::expect_error(
    kagiPro::kagi_query_search("x", file_type = "exe"),
    "Unsupported `file_type`"
  )
  # was deliberately removed from whitelist after Kagi UI audit
  testthat::expect_error(kagiPro::kagi_query_search("x", file_type = "json"), "Unsupported")
  testthat::expect_error(kagiPro::kagi_query_search("x", file_type = "md"),   "Unsupported")
  # case-insensitive
  q2 <- kagiPro::kagi_query_search("x", file_type = "PDF")[[1]]
  testthat::expect_match(q2$query, "filetype:pdf")
})

testthat::test_that("kagi_query_search domain appends site: operators", {
  q <- kagiPro::kagi_query_search("x", domain = c("example.com", "gov"))[[1]]
  testthat::expect_match(q$query, "site:example\\.com")
  testthat::expect_match(q$query, "site:gov")
  testthat::expect_error(kagiPro::kagi_query_search("x", domain = ""), "non-empty")
  testthat::expect_error(kagiPro::kagi_query_search("x", domain = 123), "non-empty")
})

testthat::test_that("kagi_query_search where wraps the query term", {
  testthat::expect_equal(
    kagiPro::kagi_query_search("biodiversity loss", where = "title")[[1]]$query,
    'intitle:"biodiversity loss"'
  )
  testthat::expect_equal(
    kagiPro::kagi_query_search("biodiversity", where = "url")[[1]]$query,
    'inurl:"biodiversity"'
  )
  testthat::expect_equal(
    kagiPro::kagi_query_search("biodiversity", where = "anywhere")[[1]]$query,
    "biodiversity"
  )
  testthat::expect_error(
    kagiPro::kagi_query_search("x", where = "everywhere"),
    "'arg' should be"
  )
})

testthat::test_that("kagi_query_search composes where + file_type + domain", {
  q <- kagiPro::kagi_query_search(
    "biodiversity",
    where = "title",
    file_type = "pdf",
    domain = "example.com"
  )[[1]]
  testthat::expect_equal(q$query, 'intitle:"biodiversity" filetype:pdf site:example.com')
})

testthat::test_that("kagi_query_search keeps shaping args in the body", {
  q <- kagiPro::kagi_query_search(
    "x",
    workflow = "news",
    limit = 25,
    page = 2,
    safe_search = FALSE,
    filters = list(region = "DE"),
    lens_id = "lens-123"
  )[[1]]
  body <- unclass(q)
  testthat::expect_equal(body$workflow, "news")
  testthat::expect_equal(body$limit, 25L)
  testthat::expect_equal(body$page, 2L)
  testthat::expect_equal(body$safe_search, FALSE)
  testthat::expect_equal(body$filters$region, "DE")
  testthat::expect_equal(body$lens_id, "lens-123")
})

testthat::test_that("print.kagi_query_search renders the key fields", {
  q <- kagiPro::kagi_query_search("biodiversity", workflow = "news", limit = 5)[[1]]
  out <- utils::capture.output(print(q))
  testthat::expect_true(any(grepl("<kagi_query_search>", out, fixed = TRUE)))
  testthat::expect_true(any(grepl("biodiversity", out)))
  testthat::expect_true(any(grepl("news", out)))
})
