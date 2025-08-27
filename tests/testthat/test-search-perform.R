# tests/testthat/test-search-perform.R

testthat::test_that("kagi_perform() returns typed results (recorded with vcr)", {
  skip_if_no_kagi_key()
  skip_on_cran_if_recording()
  testthat::skip_if_not_installed("vcr")

  vcr::use_cassette("search_basic", {
    conn <- new_kagi_connection(
      endpoint = "search",
      api_key = Sys.getenv("KAGI_API_KEY")
    )
    s <- new_kagi_search(conn, q = "biodiversity evidence synthesis", limit = 2)
    # save raw JSON to a temp file to exercise the 'path' arg
    tmp <- tempfile(fileext = ".json")
    res <- kagi_perform(s, path = tmp)

    testthat::expect_s3_class(res, "kagi_search_results")
    testthat::expect_true(file.exists(tmp))
    testthat::expect_true(nchar(res$json) > 0)

    hits <- kagi_hits(res)
    testthat::expect_s3_class(hits, "tbl_df")
    testthat::expect_true(all(c("url", "title", "snippet") %in% names(hits)))

    # related <- kagi_related(res)
    # testthat::expect_true(is.character(related))

    meta <- kagi_meta(res)
    testthat::expect_type(meta, "list")
  })
})
