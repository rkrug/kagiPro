testthat::test_that("query constructors return expected classes", {
  sq <- rkagi::search_query("biodiversity", expand = FALSE)
  testthat::expect_type(sq, "list")
  testthat::expect_s3_class(sq[[1]], "kagi_search_query")

  ew <- rkagi::enrich_web_query("biodiversity", expand = FALSE)
  testthat::expect_type(ew, "list")
  testthat::expect_s3_class(ew[[1]], "kagi_enrich_web_query")

  en <- rkagi::enrich_news_query("biodiversity", expand = FALSE)
  testthat::expect_type(en, "list")
  testthat::expect_s3_class(en[[1]], "kagi_enrich_news_query")

  sm <- rkagi::summarize_query(text = "A short text.", cache = FALSE)
  testthat::expect_type(sm, "list")
  testthat::expect_s3_class(sm[[1]], "kagi_summarize_query")
  testthat::expect_type(sm[[1]]$cache, "logical")
  testthat::expect_false(sm[[1]]$cache)

  fg <- rkagi::fastgpt_query("What is biodiversity?")
  testthat::expect_type(fg, "list")
  testthat::expect_s3_class(fg[[1]], "kagi_fastgpt_query")
  testthat::expect_true(fg[[1]]$web_search)
})

testthat::test_that("fastgpt_query enforces current API constraint", {
  testthat::expect_error(
    rkagi::fastgpt_query("test", web_search = FALSE),
    "currently not supported"
  )
})

testthat::test_that("open_search_query returns encoded URL", {
  opened <- NULL
  testthat::local_mocked_bindings(
    browseURL = function(url) {
      opened <<- url
      invisible(TRUE)
    },
    .package = "utils"
  )

  url <- rkagi::open_search_query("a b")
  testthat::expect_equal(url, "https://kagi.com/search?q=a%20b")
  testthat::expect_equal(opened, url)
})

testthat::test_that("kagi_connection constructor creates expected class", {
  conn <- rkagi::kagi_connection(api_key = "dummy-kagi-key")
  testthat::expect_s3_class(conn, "kagi_connection")
})

testthat::test_that("kagi_request errors on invalid query class", {
  conn <- rkagi::kagi_connection(api_key = "dummy-kagi-key")
  out <- tempfile("rkagi-bad-query-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  testthat::expect_error(
    rkagi::kagi_request(
      connection = conn,
      query = structure("bad", class = "not_a_query"),
      output = out
    ),
    "must be of class"
  )
})

testthat::test_that("search request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-search-request")
  conn <- rkagi::kagi_connection(api_key = key)
  q <- rkagi::search_query("openalex api", expand = FALSE)
  out <- tempfile("rkagi-search-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-search-request", {
    path <- rkagi::kagi_request(
      connection = conn,
      query = q,
      limit = 1,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^search_[0-9]+\\.json$", full.names = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("enrich web request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-enrich-web-request")
  conn <- rkagi::kagi_connection(api_key = key)
  q <- rkagi::enrich_web_query("open data", expand = FALSE)
  out <- tempfile("rkagi-enrich-web-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-enrich-web-request", {
    path <- rkagi::kagi_request(
      connection = conn,
      query = q,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^enrich_web_[0-9]+\\.json$", full.names = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("enrich news request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-enrich-news-request")
  conn <- rkagi::kagi_connection(api_key = key)
  q <- rkagi::enrich_news_query("climate policy", expand = FALSE)
  out <- tempfile("rkagi-enrich-news-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-enrich-news-request", {
    path <- rkagi::kagi_request(
      connection = conn,
      query = q,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^enrich_news_[0-9]+\\.json$", full.names = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("summarize request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-summarize-request")
  conn <- rkagi::kagi_connection(api_key = key)
  q <- rkagi::summarize_query(
    text = paste(
      "Biodiversity underpins ecosystem services such as pollination, soil fertility,",
      "water purification, and climate regulation.",
      "Habitat loss, pollution, invasive species, and climate change are accelerating",
      "species decline across terrestrial and marine ecosystems.",
      "Protecting biodiversity improves food security, public health, and resilience",
      "of social and economic systems to environmental shocks."
    ),
    engine = "cecil",
    summary_type = "summary",
    target_language = "EN",
    cache = TRUE
  )
  out <- tempfile("rkagi-summarize-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  withCallingHandlers(
    vcr::use_cassette("kagi-summarize-request", {
      path <- rkagi::kagi_request(
        connection = conn,
        query = q,
        output = out,
        overwrite = TRUE,
        error_mode = "write_dummy"
      )
      testthat::expect_true(dir.exists(path))
    }),
    warning = function(w) {
      if (grepl("Kagi request failed for endpoint `summarize`", conditionMessage(w))) {
        invokeRestart("muffleWarning")
      }
    }
  )

  files <- list.files(out, pattern = "^summarize_[0-9]+\\.json$", full.names = TRUE)
  testthat::expect_gte(length(files), 1)
  payload <- jsonlite::fromJSON(files[[1]], simplifyVector = FALSE)
  payload_id <- payload$meta$id
  if (is.null(payload_id)) {
    payload_id <- ""
  }
  if (grepl("^error_", payload_id)) {
    testthat::expect_null(payload$data$output)
    testthat::expect_equal(payload$data$tokens, 0L)
  } else {
    testthat::expect_true(is.character(payload$data$output))
    testthat::expect_true(nzchar(payload$data$output))
  }
})

testthat::test_that("fastgpt request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-fastgpt-request")
  conn <- rkagi::kagi_connection(api_key = key)
  q <- rkagi::fastgpt_query(
    query = "What is Python 3.11?",
    cache = TRUE,
    web_search = TRUE
  )
  out <- tempfile("rkagi-fastgpt-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-fastgpt-request", {
    path <- rkagi::kagi_request(
      connection = conn,
      query = q,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^fastgpt_[0-9]+\\.json$", full.names = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("kagi_request_parquet converts local json exports", {
  in_dir <- tempfile("rkagi-json-")
  out_dir <- tempfile("rkagi-parquet-")
  dir.create(in_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  payload <- list(
    meta = list(id = "x", node = "test", ms = 1),
    data = list(
      list(t = 0, url = "https://example.com", title = "Example", snippet = "S")
    )
  )
  jsonlite::write_json(
    payload,
    path = file.path(in_dir, "search_1.json"),
    auto_unbox = TRUE
  )

  res <- rkagi::kagi_request_parquet(
    input_json = in_dir,
    output = out_dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  testthat::expect_true(dir.exists(res))
  testthat::expect_true(length(list.files(res, recursive = TRUE)) > 0)
})

testthat::test_that("list requests gracefully handle one summarize error and parquet conversion", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-summarize-list-mixed-errors")
  conn <- rkagi::kagi_connection(api_key = key)

  q_ok <- rkagi::summarize_query(
    text = paste(
      "Biodiversity underpins ecosystem services such as pollination, soil fertility,",
      "water purification, and climate regulation.",
      "Habitat loss, pollution, invasive species, and climate change are accelerating",
      "species decline, which affects food security and resilience.",
      "Conservation and restoration policies can improve ecological and economic stability."
    ),
    engine = "cecil",
    summary_type = "summary",
    target_language = "EN",
    cache = TRUE
  )

  # Intentionally too short -> expected API-side summarize error
  q_err <- rkagi::summarize_query(
    text = "Too short.",
    engine = "cecil",
    summary_type = "summary",
    target_language = "EN",
    cache = TRUE
  )

  q_list <- list(ok = q_ok, err = q_err)

  out <- tempfile("rkagi-summarize-list-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  got_expected_warning <- FALSE
  withCallingHandlers(
    vcr::use_cassette("kagi-summarize-list-mixed-errors", {
      rkagi::kagi_request(
        connection = conn,
        query = q_list,
        output = out,
        overwrite = TRUE,
        workers = 1,
        error_mode = "write_dummy"
      )
    }),
    warning = function(w) {
      if (grepl("Kagi request failed for endpoint `summarize`", conditionMessage(w))) {
        got_expected_warning <<- TRUE
        invokeRestart("muffleWarning")
      }
    }
  )
  testthat::expect_true(got_expected_warning)

  ok_json <- file.path(out, "ok", "summarize_1.json")
  err_json <- file.path(out, "err", "summarize_1.json")
  testthat::expect_true(file.exists(ok_json))
  testthat::expect_true(file.exists(err_json))

  err_payload <- jsonlite::fromJSON(err_json, simplifyVector = FALSE)
  testthat::expect_match(err_payload$meta$id, "^error_")
  testthat::expect_null(err_payload$data$output)
  testthat::expect_equal(err_payload$data$tokens, 0L)

  parquet_dir <- tempfile("rkagi-summarize-error-parquet-")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(parquet_dir, recursive = TRUE), add = TRUE)

  parquet_path <- rkagi::kagi_request_parquet(
    input_json = file.path(out, "err"),
    output = parquet_dir,
    overwrite = TRUE,
    verbose = FALSE
  )
  testthat::expect_true(dir.exists(parquet_path))
  testthat::expect_true(length(list.files(parquet_path, recursive = TRUE)) > 0)
})

testthat::test_that("write_dummy mode produces endpoint-aware fallback payloads", {
  conn <- rkagi::kagi_connection(
    base_url = "https://no-such-host.invalid/api/v0",
    api_key = "dummy-kagi-key"
  )

  test_cases <- list(
    list(name = "search", query = rkagi::search_query("x", expand = FALSE)),
    list(name = "enrich_web", query = rkagi::enrich_web_query("x", expand = FALSE)),
    list(name = "enrich_news", query = rkagi::enrich_news_query("x", expand = FALSE)),
    list(name = "summarize", query = rkagi::summarize_query(text = paste(rep("x", 50), collapse = " "))),
    list(name = "fastgpt", query = rkagi::fastgpt_query("What is x?"))
  )

  for (tc in test_cases) {
    out <- tempfile(paste0("rkagi-dummy-", tc$name, "-"))
    dir.create(out, recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(out, recursive = TRUE), add = TRUE)

    testthat::expect_warning(
      rkagi::kagi_request(
        connection = conn,
        query = tc$query,
        output = out,
        overwrite = TRUE,
        error_mode = "write_dummy"
      ),
      "Kagi request failed for endpoint"
    )

    json_files <- list.files(out, pattern = "\\.json$", full.names = TRUE)
    testthat::expect_gte(length(json_files), 1)

    payload <- jsonlite::fromJSON(json_files[[1]], simplifyVector = FALSE)
    testthat::expect_match(payload$meta$id, "^error_")
    testthat::expect_true(nzchar(payload$meta$endpoint))

    if (payload$meta$endpoint == "summarize") {
      testthat::expect_null(payload$data$output)
      testthat::expect_equal(payload$data$tokens, 0L)
    }
    if (payload$meta$endpoint == "fastgpt") {
      testthat::expect_null(payload$data$output)
      testthat::expect_equal(payload$data$tokens, 0L)
    }
  }
})
