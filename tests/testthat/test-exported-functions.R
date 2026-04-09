testthat::test_that("query constructors return expected classes", {
  sq <- kagiPro::query_search("biodiversity", expand = FALSE)
  testthat::expect_type(sq, "list")
  testthat::expect_s3_class(sq[[1]], "kagi_query_search")

  ew <- kagiPro::query_enrich_web("biodiversity", expand = FALSE)
  testthat::expect_type(ew, "list")
  testthat::expect_s3_class(ew[[1]], "kagi_query_enrich_web")

  en <- kagiPro::query_enrich_news("biodiversity", expand = FALSE)
  testthat::expect_type(en, "list")
  testthat::expect_s3_class(en[[1]], "kagi_query_enrich_news")

  sm <- kagiPro::query_summarize(text = "A short text.", cache = FALSE)
  testthat::expect_type(sm, "list")
  testthat::expect_s3_class(sm[[1]], "kagi_query_summarize")
  testthat::expect_type(sm[[1]]$cache, "logical")
  testthat::expect_false(sm[[1]]$cache)

  fg <- kagiPro::query_fastgpt("What is biodiversity?")
  testthat::expect_type(fg, "list")
  testthat::expect_s3_class(fg[[1]], "kagi_query_fastgpt")
  testthat::expect_true(fg[[1]]$web_search)
})

testthat::test_that("query_fastgpt enforces current API constraint", {
  testthat::expect_error(
    kagiPro::query_fastgpt("test", web_search = FALSE),
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

  url <- kagiPro::open_search_query("a b")
  testthat::expect_equal(url, "https://kagi.com/search?q=a%20b")
  testthat::expect_equal(opened, url)
})

testthat::test_that("kagi_connection constructor creates expected class", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  testthat::expect_s3_class(conn, "kagi_connection")
})

testthat::test_that("kagi_request progress marker is removed on success", {
  conn <- kagiPro::kagi_connection(
    base_url = "https://example.invalid/api/v0",
    api_key = "dummy-kagi-key"
  )
  q <- kagiPro::query_search("biodiversity", expand = FALSE)
  out <- tempfile("kagiPro-marker-success-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  testthat::local_mocked_bindings(
    req_perform = function(req) {
      structure(list(status_code = 200L), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(meta = list(next_cursor = NULL), data = list())
    },
    resp_body_string = function(resp) {
      "{\"meta\":{\"next_cursor\":null},\"data\":[]}"
    },
    .package = "httr2"
  )

  path <- kagiPro::kagi_request(
    connection = conn,
    query = q,
    output = out,
    overwrite = TRUE
  )

  testthat::expect_true(dir.exists(path))
  testthat::expect_false(file.exists(file.path(path, "00_in.progress")))
})

testthat::test_that("kagi_request writes per-query metadata only", {
  conn <- kagiPro::kagi_connection(
    base_url = "https://example.invalid/api/v0",
    api_key = "dummy-kagi-key"
  )
  q <- kagiPro::query_search("biodiversity", expand = FALSE)
  out <- tempfile("kagiPro-meta-upsert-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  testthat::local_mocked_bindings(
    req_perform = function(req) {
      structure(list(status_code = 200L), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(meta = list(next_cursor = NULL), data = list())
    },
    resp_body_string = function(resp) {
      "{\"meta\":{\"next_cursor\":null},\"data\":[]}"
    },
    .package = "httr2"
  )

  kagiPro::kagi_request(
    connection = conn,
    query = list(my_query = q[[1]]),
    output = out,
    overwrite = TRUE,
    limit = 1
  )

  kagiPro::kagi_request(
    connection = conn,
    query = list(my_query = q[[1]]),
    output = out,
    overwrite = FALSE,
    append = TRUE,
    limit = 7
  )

  meta_file <- file.path(out, "my_query", "_query_meta.json")
  testthat::expect_true(file.exists(meta_file))
  testthat::expect_false(file.exists(file.path(out, "_meta", "queries.jsonl")))

  meta <- jsonlite::fromJSON(meta_file, simplifyVector = FALSE)
  testthat::expect_equal(meta$query_name, "my_query")
  testthat::expect_equal(meta$endpoint, "search")
  testthat::expect_equal(meta$query_class, "kagi_query_search")
  testthat::expect_equal(meta$request_args$limit, 7)
})

testthat::test_that("kagi_request progress marker remains on failure", {
  conn <- kagiPro::kagi_connection(
    base_url = "https://example.invalid/api/v0",
    api_key = "dummy-kagi-key"
  )
  q <- kagiPro::query_search("biodiversity", expand = FALSE)
  out <- tempfile("kagiPro-marker-fail-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  testthat::local_mocked_bindings(
    req_perform = function(req) {
      stop("request failed", call. = FALSE)
    },
    .package = "httr2"
  )

  testthat::expect_error(
    kagiPro::kagi_request(
      connection = conn,
      query = q[[1]],
      output = out,
      overwrite = TRUE,
      error_mode = "stop"
    ),
    "Kagi request failed for endpoint"
  )
  testthat::expect_true(file.exists(file.path(out, "00_in.progress")))
})

testthat::test_that("kagi_request errors on invalid query class", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  out <- tempfile("kagiPro-bad-query-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  testthat::expect_error(
    kagiPro::kagi_request(
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
  conn <- kagiPro::kagi_connection(api_key = key)
  q <- kagiPro::query_search("openalex api", expand = FALSE)
  out <- tempfile("kagiPro-search-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-search-request", {
    path <- kagiPro::kagi_request(
      connection = conn,
      query = q,
      limit = 1,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^search_[0-9]+\\.json$", full.names = TRUE, recursive = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("enrich web request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-enrich-web-request")
  conn <- kagiPro::kagi_connection(api_key = key)
  q <- kagiPro::query_enrich_web("open data", expand = FALSE)
  out <- tempfile("kagiPro-enrich-web-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-enrich-web-request", {
    path <- kagiPro::kagi_request(
      connection = conn,
      query = q,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^enrich_web_[0-9]+\\.json$", full.names = TRUE, recursive = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("enrich news request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-enrich-news-request")
  conn <- kagiPro::kagi_connection(api_key = key)
  q <- kagiPro::query_enrich_news("climate policy", expand = FALSE)
  out <- tempfile("kagiPro-enrich-news-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-enrich-news-request", {
    path <- kagiPro::kagi_request(
      connection = conn,
      query = q,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^enrich_news_[0-9]+\\.json$", full.names = TRUE, recursive = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("summarize request is recorded with vcr", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-summarize-request")
  conn <- kagiPro::kagi_connection(api_key = key)
  q <- kagiPro::query_summarize(
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
  out <- tempfile("kagiPro-summarize-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  withCallingHandlers(
    vcr::use_cassette("kagi-summarize-request", {
      path <- kagiPro::kagi_request(
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

  files <- list.files(out, pattern = "^summarize_[0-9]+\\.json$", full.names = TRUE, recursive = TRUE)
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
  conn <- kagiPro::kagi_connection(api_key = key)
  q <- kagiPro::query_fastgpt(
    query = "What is Python 3.11?",
    cache = TRUE,
    web_search = TRUE
  )
  out <- tempfile("kagiPro-fastgpt-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  vcr::use_cassette("kagi-fastgpt-request", {
    path <- kagiPro::kagi_request(
      connection = conn,
      query = q,
      output = out,
      overwrite = TRUE
    )
    testthat::expect_true(dir.exists(path))
  })

  files <- list.files(out, pattern = "^fastgpt_[0-9]+\\.json$", full.names = TRUE, recursive = TRUE)
  testthat::expect_gte(length(files), 1)
})

testthat::test_that("kagi_request_parquet converts local json exports", {
  in_dir <- tempfile("kagiPro-json-")
  out_dir <- tempfile("kagiPro-parquet-")
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

  res <- kagiPro::kagi_request_parquet(
    input_json = in_dir,
    output = out_dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  testthat::expect_true(dir.exists(res))
  parquet_files <- list.files(res, recursive = TRUE, full.names = TRUE, pattern = "\\.parquet$")
  testthat::expect_true(length(parquet_files) > 0)

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  cols <- DBI::dbGetQuery(
    con,
    sprintf("SELECT * FROM read_parquet('%s') LIMIT 1", parquet_files[[1]])
  )
  testthat::expect_true("id" %in% names(cols))
  testthat::expect_true("query" %in% names(cols))
  testthat::expect_equal(cols$query[[1]], "query_1")
  testthat::expect_match(cols$id[[1]], "^SEARCH_")
})

testthat::test_that("kagi_request_parquet keeps query names as hive partition values", {
  in_dir <- tempfile("kagiPro-json-query-partition-")
  out_dir <- tempfile("kagiPro-parquet-query-partition-")
  dir.create(file.path(in_dir, "my_query"), recursive = TRUE, showWarnings = FALSE)
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
    path = file.path(in_dir, "my_query", "search_1.json"),
    auto_unbox = TRUE
  )

  kagiPro::kagi_request_parquet(
    input_json = in_dir,
    output = out_dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  testthat::expect_true(dir.exists(file.path(out_dir, "query=my_query")))
})

testthat::test_that("kagi_request_parquet append updates one query partition only", {
  in_full <- tempfile("kagiPro-json-full-")
  in_update <- tempfile("kagiPro-json-update-")
  out_dir <- tempfile("kagiPro-parquet-update-")
  dir.create(file.path(in_full, "q1"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(in_full, "q2"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(in_update, "q1"), recursive = TRUE, showWarnings = FALSE)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(in_full, recursive = TRUE), add = TRUE)
  on.exit(unlink(in_update, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  payload_q1 <- list(meta = list(id = "x"), data = list(list(t = 0, url = "https://example.com/a", title = "A1", snippet = "S")))
  payload_q2 <- list(meta = list(id = "y"), data = list(list(t = 0, url = "https://example.com/b", title = "B1", snippet = "S")))
  payload_q1_new <- list(meta = list(id = "x2"), data = list(list(t = 0, url = "https://example.com/a", title = "A2", snippet = "S")))

  jsonlite::write_json(payload_q1, file.path(in_full, "q1", "search_1.json"), auto_unbox = TRUE)
  jsonlite::write_json(payload_q2, file.path(in_full, "q2", "search_1.json"), auto_unbox = TRUE)
  jsonlite::write_json(payload_q1_new, file.path(in_update, "q1", "search_1.json"), auto_unbox = TRUE)

  kagiPro::kagi_request_parquet(
    input_json = in_full,
    output = out_dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  kagiPro::kagi_request_parquet(
    input_json = in_update,
    output = out_dir,
    overwrite = FALSE,
    append = TRUE,
    verbose = FALSE
  )

  testthat::expect_true(dir.exists(file.path(out_dir, "query=q1")))
  testthat::expect_true(dir.exists(file.path(out_dir, "query=q2")))

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  dat <- DBI::dbGetQuery(
    con,
    sprintf(
      "SELECT query, title FROM read_parquet('%s')",
      file.path(gsub("'", "''", out_dir), "**", "*.parquet")
    )
  )
  testthat::expect_true(any(dat$query == "q2" & dat$title == "B1"))
  testthat::expect_true(any(dat$query == "q1" & dat$title == "A2"))
  testthat::expect_false(any(dat$query == "q1" & dat$title == "A1"))
})

testthat::test_that("kagi_request_parquet progress marker lifecycle", {
  in_ok <- tempfile("kagiPro-json-ok-")
  out_ok <- tempfile("kagiPro-parquet-ok-")
  dir.create(in_ok, recursive = TRUE, showWarnings = FALSE)
  dir.create(out_ok, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(in_ok, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_ok, recursive = TRUE), add = TRUE)

  payload <- list(meta = list(id = "x"), data = list(list(t = 0, url = "https://example.com", title = "A")))
  jsonlite::write_json(payload, file.path(in_ok, "search_1.json"), auto_unbox = TRUE)
  kagiPro::kagi_request_parquet(
    input_json = in_ok,
    output = out_ok,
    overwrite = TRUE,
    verbose = FALSE
  )
  testthat::expect_false(file.exists(file.path(out_ok, "00_in.progress")))

  in_fail <- tempfile("kagiPro-json-fail-")
  out_fail <- tempfile("kagiPro-parquet-fail-")
  dir.create(in_fail, recursive = TRUE, showWarnings = FALSE)
  dir.create(out_fail, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(in_fail, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_fail, recursive = TRUE), add = TRUE)

  jsonlite::write_json(payload, file.path(in_fail, "search_1.json"), auto_unbox = TRUE)
  jsonlite::write_json(payload, file.path(in_fail, "summarize_1.json"), auto_unbox = TRUE)
  testthat::expect_error(
    kagiPro::kagi_request_parquet(
      input_json = in_fail,
      output = out_fail,
      overwrite = TRUE,
      verbose = FALSE
    ),
    "same type"
  )
  testthat::expect_true(file.exists(file.path(out_fail, "00_in.progress")))
})

testthat::test_that("kagi_fetch writes endpoint-scoped folders for scalar endpoint", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  q <- kagiPro::query_search("biodiversity", expand = FALSE)
  proj <- tempfile("kagiPro-project-")
  dir.create(proj, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  seen <- list()
  testthat::local_mocked_bindings(
    kagi_request = function(connection, query, limit, output, overwrite, append, workers, verbose, error_mode, metadata_request_args) {
      seen$json <<- output
      seen$metadata <<- metadata_request_args
      dir.create(output, recursive = TRUE, showWarnings = FALSE)
      invisible(output)
    },
    kagi_request_parquet = function(input_json, output, overwrite, append, verbose, delete_input, ...) {
      seen$parquet <<- output
      dir.create(output, recursive = TRUE, showWarnings = FALSE)
      invisible(normalizePath(output))
    },
    .package = "kagiPro"
  )

  out <- kagiPro::kagi_fetch(
    connection = conn,
    query = q,
    project_folder = proj
  )

  testthat::expect_equal(seen$json, file.path(normalizePath(proj), "search", "json"))
  testthat::expect_equal(seen$parquet, file.path(normalizePath(proj), "search", "parquet"))
  testthat::expect_equal(out, normalizePath(file.path(proj, "search", "parquet")))
})

testthat::test_that("kagi_fetch splits mixed endpoint lists", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  q <- c(
    kagiPro::query_search("biodiversity", expand = FALSE),
    kagiPro::query_enrich_news("biodiversity", expand = FALSE)
  )
  names(q) <- c("search_a", "news_a")
  proj <- tempfile("kagiPro-project-mixed-")
  dir.create(proj, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  seen_outputs <- character()
  testthat::local_mocked_bindings(
    kagi_request = function(connection, query, limit, output, overwrite, append, workers, verbose, error_mode, metadata_request_args) {
      seen_outputs <<- c(seen_outputs, output)
      dir.create(output, recursive = TRUE, showWarnings = FALSE)
      invisible(output)
    },
    kagi_request_parquet = function(input_json, output, overwrite, append, verbose, delete_input, ...) {
      dir.create(output, recursive = TRUE, showWarnings = FALSE)
      invisible(normalizePath(output))
    },
    .package = "kagiPro"
  )

  out <- kagiPro::kagi_fetch(
    connection = conn,
    query = q,
    project_folder = proj
  )

  testthat::expect_type(out, "list")
  testthat::expect_true(all(c("search", "enrich_news") %in% names(out)))
  testthat::expect_true(any(grepl(file.path("search", "json"), seen_outputs, fixed = TRUE)))
  testthat::expect_true(any(grepl(file.path("enrich_news", "json"), seen_outputs, fixed = TRUE)))
})

testthat::test_that("kagi_update_query reruns by query name and refreshes parquet partition", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  proj <- tempfile("kagiPro-update-query-")
  json_dir <- file.path(proj, "search", "json")
  parquet_dir <- file.path(proj, "search", "parquet")
  dir.create(file.path(json_dir, "my_query"), recursive = TRUE, showWarnings = FALSE)
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  meta_entry <- list(
    query_name = "my_query",
    endpoint = "search",
    query_class = "kagi_query_search",
    query_payload = "biodiversity",
    request_args = list(limit = 5),
    schema_version = "1.0.0",
    kagiPro_version = "0.4.0",
    updated_at = "2026-01-01T00:00:00Z"
  )
  jsonlite::write_json(
    meta_entry,
    path = file.path(json_dir, "my_query", "_query_meta.json"),
    auto_unbox = TRUE,
    null = "null"
  )

  req_limit <- NULL
  parquet_append <- NULL
  testthat::local_mocked_bindings(
    kagi_request = function(connection, query, limit, output, overwrite, append, workers, verbose, error_mode, metadata_request_args) {
      req_limit <<- limit
      dir.create(file.path(output, "my_query"), recursive = TRUE, showWarnings = FALSE)
      jsonlite::write_json(
        list(meta = list(id = "x"), data = list(list(t = 0, url = "https://example.org", title = "X"))),
        file.path(output, "my_query", "search_1.json"),
        auto_unbox = TRUE
      )
      invisible(output)
    },
    kagi_request_parquet = function(input_json, output, overwrite, append, verbose, delete_input, ...) {
      parquet_append <<- append
      testthat::expect_true(file.exists(file.path(input_json, "my_query", "search_1.json")))
      invisible(normalizePath(output))
    },
    .package = "kagiPro"
  )

  out <- kagiPro::kagi_update_query(
    connection = conn,
    project_folder = proj,
    query_name = "my_query"
  )

  testthat::expect_equal(req_limit, 5)
  testthat::expect_true(isTRUE(parquet_append))
  testthat::expect_true("search" %in% names(out))
  testthat::expect_equal(out[["search"]], normalizePath(parquet_dir))
})

testthat::test_that("kagi_update_query updates same query name across endpoints", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")
  proj <- tempfile("kagiPro-update-query-multi-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  endpoints <- c("search", "enrich_news")
  for (ep in endpoints) {
    json_dir <- file.path(proj, ep, "json")
    parquet_dir <- file.path(proj, ep, "parquet")
    dir.create(file.path(json_dir, "shared_query"), recursive = TRUE, showWarnings = FALSE)
    dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
    entry <- list(
      query_name = "shared_query",
      endpoint = ep,
      query_class = if (ep == "search") "kagi_query_search" else "kagi_query_enrich_news",
      query_payload = "climate",
      request_args = list(limit = if (ep == "search") 3 else NULL),
      schema_version = "1.0.0",
      kagiPro_version = "0.4.0",
      updated_at = "2026-01-01T00:00:00Z"
    )
    jsonlite::write_json(
      entry,
      path = file.path(json_dir, "shared_query", "_query_meta.json"),
      auto_unbox = TRUE,
      null = "null"
    )
  }

  seen <- character()
  testthat::local_mocked_bindings(
    kagi_request = function(connection, query, limit, output, overwrite, append, workers, verbose, error_mode, metadata_request_args) {
      ep <- basename(dirname(output))
      seen <<- c(seen, ep)
      dir.create(file.path(output, "shared_query"), recursive = TRUE, showWarnings = FALSE)
      fn <- if (ep == "search") "search_1.json" else "enrich_news_1.json"
      jsonlite::write_json(
        list(meta = list(id = "x"), data = list(list(t = 0, url = "https://example.org", title = "X"))),
        file.path(output, "shared_query", fn),
        auto_unbox = TRUE
      )
      invisible(output)
    },
    kagi_request_parquet = function(input_json, output, overwrite, append, verbose, delete_input, ...) {
      invisible(normalizePath(output))
    },
    .package = "kagiPro"
  )

  out <- kagiPro::kagi_update_query(
    connection = conn,
    project_folder = proj,
    query_name = "shared_query"
  )

  testthat::expect_true(all(endpoints %in% names(out)))
  testthat::expect_true(all(endpoints %in% seen))
})

testthat::test_that("kagi_update_query errors cleanly for missing or corrupt metadata", {
  conn <- kagiPro::kagi_connection(api_key = "dummy-kagi-key")

  proj_missing <- tempfile("kagiPro-update-missing-")
  dir.create(file.path(proj_missing, "search", "json"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(proj_missing, "search", "parquet"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj_missing, recursive = TRUE), add = TRUE)

  testthat::expect_error(
    kagiPro::kagi_update_query(conn, proj_missing, "nope"),
    "No metadata entry found"
  )

  proj_corrupt <- tempfile("kagiPro-update-corrupt-")
  dir.create(file.path(proj_corrupt, "search", "json", "q1"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(proj_corrupt, "search", "parquet"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj_corrupt, recursive = TRUE), add = TRUE)
  writeLines("{not-json", con = file.path(proj_corrupt, "search", "json", "q1", "_query_meta.json"))

  testthat::expect_error(
    kagiPro::kagi_update_query(conn, proj_corrupt, "q"),
    "Corrupt metadata file"
  )
})

testthat::test_that("clean_request dry_run reports deletions without mutating", {
  proj <- tempfile("kagiPro-clean-dry-")
  qdir <- file.path(proj, "search", "json", "query_a")
  dir.create(qdir, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(proj, "search", "json", "_meta"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  writeLines("{}", file.path(qdir, "_query_meta.json"))
  writeLines("{\"x\":1}", file.path(qdir, "search_1.json"))
  writeLines("tmp", file.path(qdir, "scratch.txt"))
  writeLines("idx", file.path(proj, "search", "json", "_meta", "queries.jsonl"))
  writeLines("progress", file.path(proj, "search", "json", "00_in.progress"))

  res <- kagiPro::clean_request(project_folder = proj, dry_run = TRUE, verbose = FALSE)

  testthat::expect_true(is.list(res))
  testthat::expect_true(nrow(res$details) >= 1L)
  testthat::expect_true(res$totals$files >= 2L)
  testthat::expect_true(file.exists(file.path(qdir, "search_1.json")))
  testthat::expect_true(file.exists(file.path(qdir, "_query_meta.json")))
  testthat::expect_true(dir.exists(file.path(proj, "search", "json", "_meta")))
})

testthat::test_that("clean_request removes JSON data artifacts and preserves metadata", {
  proj <- tempfile("kagiPro-clean-run-")
  qdir <- file.path(proj, "enrich_web", "json", "query_b")
  pdir <- file.path(proj, "enrich_web", "parquet")
  dir.create(qdir, recursive = TRUE, showWarnings = FALSE)
  dir.create(pdir, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(proj, "enrich_web", "json", "_meta"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  writeLines("{}", file.path(qdir, "_query_meta.json"))
  writeLines("{\"x\":1}", file.path(qdir, "enrich_web_1.json"))
  writeLines("other", file.path(qdir, "other.tmp"))
  writeLines("idx", file.path(proj, "enrich_web", "json", "_meta", "queries.jsonl"))
  writeLines("progress", file.path(proj, "enrich_web", "json", "00_in.progress"))
  writeLines("parquet-data", file.path(pdir, "keep.parquet"))

  res <- kagiPro::clean_request(project_folder = proj, dry_run = FALSE, verbose = FALSE)

  testthat::expect_true(res$totals$files >= 2L)
  testthat::expect_true(file.exists(file.path(qdir, "_query_meta.json")))
  testthat::expect_false(file.exists(file.path(qdir, "enrich_web_1.json")))
  testthat::expect_false(file.exists(file.path(qdir, "other.tmp")))
  testthat::expect_false(file.exists(file.path(proj, "enrich_web", "json", "00_in.progress")))
  testthat::expect_false(dir.exists(file.path(proj, "enrich_web", "json", "_meta")))
  testthat::expect_true(file.exists(file.path(pdir, "keep.parquet")))
})

testthat::test_that("kagi_request_parquet uses endpoint-prefixed ids for enrich outputs", {
  payload <- list(
    meta = list(id = "x", node = "test", ms = 1),
    data = list(
      list(t = 0, url = "https://example.com/a", title = "A"),
      list(t = 1, url = "https://example.com/b", title = "B")
    )
  )

  in_web <- tempfile("kagiPro-json-enrich-web-")
  out_web <- tempfile("kagiPro-parquet-enrich-web-")
  dir.create(in_web, recursive = TRUE, showWarnings = FALSE)
  dir.create(out_web, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(in_web, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_web, recursive = TRUE), add = TRUE)

  jsonlite::write_json(
    payload,
    path = file.path(in_web, "enrich_web_1.json"),
    auto_unbox = TRUE
  )

  kagiPro::kagi_request_parquet(
    input_json = in_web,
    output = out_web,
    overwrite = TRUE,
    verbose = FALSE
  )

  parquet_web <- list.files(out_web, recursive = TRUE, full.names = TRUE, pattern = "\\.parquet$")
  testthat::expect_true(length(parquet_web) > 0)

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  ids_web <- DBI::dbGetQuery(
    con,
    sprintf("SELECT DISTINCT id FROM read_parquet('%s')", parquet_web[[1]])
  )$id
  testthat::expect_true(all(grepl("^ENRICH_WEB_", ids_web)))

  in_news <- tempfile("kagiPro-json-enrich-news-")
  out_news <- tempfile("kagiPro-parquet-enrich-news-")
  dir.create(in_news, recursive = TRUE, showWarnings = FALSE)
  dir.create(out_news, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(in_news, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_news, recursive = TRUE), add = TRUE)

  jsonlite::write_json(
    payload,
    path = file.path(in_news, "enrich_news_1.json"),
    auto_unbox = TRUE
  )

  kagiPro::kagi_request_parquet(
    input_json = in_news,
    output = out_news,
    overwrite = TRUE,
    verbose = FALSE
  )

  parquet_news <- list.files(out_news, recursive = TRUE, full.names = TRUE, pattern = "\\.parquet$")
  testthat::expect_true(length(parquet_news) > 0)
  ids_news <- DBI::dbGetQuery(
    con,
    sprintf("SELECT DISTINCT id FROM read_parquet('%s')", parquet_news[[1]])
  )$id
  testthat::expect_true(all(grepl("^ENRICH_NEWS_", ids_news)))
})

testthat::test_that("list requests gracefully handle one summarize error and parquet conversion", {
  testthat::skip_if_not_installed("vcr")
  skip_on_cran_if_recording()
  key <- api_key_for_cassette("kagi-summarize-list-mixed-errors")
  conn <- kagiPro::kagi_connection(api_key = key)

  q_ok <- kagiPro::query_summarize(
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
  q_err <- kagiPro::query_summarize(
    text = "Too short.",
    engine = "cecil",
    summary_type = "summary",
    target_language = "EN",
    cache = TRUE
  )

  q_list <- list(ok = q_ok, err = q_err)

  out <- tempfile("kagiPro-summarize-list-")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  got_expected_warning <- FALSE
  withCallingHandlers(
    vcr::use_cassette("kagi-summarize-list-mixed-errors", {
      kagiPro::kagi_request(
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

  parquet_dir <- tempfile("kagiPro-summarize-error-parquet-")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(parquet_dir, recursive = TRUE), add = TRUE)

  parquet_path <- kagiPro::kagi_request_parquet(
    input_json = file.path(out, "err"),
    output = parquet_dir,
    overwrite = TRUE,
    verbose = FALSE
  )
  testthat::expect_true(dir.exists(parquet_path))
  testthat::expect_true(length(list.files(parquet_path, recursive = TRUE)) > 0)
})

testthat::test_that("write_dummy mode produces endpoint-aware fallback payloads", {
  conn <- kagiPro::kagi_connection(
    base_url = "https://no-such-host.invalid/api/v0",
    api_key = "dummy-kagi-key"
  )

  test_cases <- list(
    list(name = "search", query = kagiPro::query_search("x", expand = FALSE)),
    list(name = "enrich_web", query = kagiPro::query_enrich_web("x", expand = FALSE)),
    list(name = "enrich_news", query = kagiPro::query_enrich_news("x", expand = FALSE)),
    list(name = "summarize", query = kagiPro::query_summarize(text = paste(rep("x", 50), collapse = " "))),
    list(name = "fastgpt", query = kagiPro::query_fastgpt("What is x?"))
  )

  for (tc in test_cases) {
    out <- tempfile(paste0("kagiPro-dummy-", tc$name, "-"))
    dir.create(out, recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(out, recursive = TRUE), add = TRUE)

    testthat::expect_warning(
      kagiPro::kagi_request(
        connection = conn,
        query = tc$query,
        output = out,
        overwrite = TRUE,
        error_mode = "write_dummy"
      ),
      "Kagi request failed for endpoint"
    )

    json_files <- list.files(out, pattern = "\\.json$", full.names = TRUE, recursive = TRUE)
    json_files <- json_files[grepl("_[0-9]+\\.json$", basename(json_files))]
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

testthat::test_that("summarize_with_openai validates inputs", {
  testthat::expect_true(is.na(kagiPro::summarize_with_openai(text = "")))
  testthat::expect_error(
    kagiPro::summarize_with_openai(
      text = "Some text",
      api_key = ""
    ),
    "Missing OpenAI API key"
  )
})

testthat::test_that("summarize_with_kagi validates inputs", {
  testthat::expect_true(is.na(kagiPro::summarize_with_kagi(text = "")))
  testthat::expect_error(
    kagiPro::summarize_with_kagi(text = "Some text", api_key = NULL, connection = NULL),
    "Missing API key"
  )
})

testthat::test_that("content_markdown uses ragnar backend and writes markdown path", {
  proj <- tempfile("kagiPro-content-md-proj-")
  dir.create(file.path(proj, "search", "content", "query=q1"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  src <- file.path(proj, "search", "content", "query=q1", "SEARCH_abc.pdf")
  writeLines("dummy", src)

  testthat::local_mocked_bindings(
    download_content = function(...) {
      data.frame(
        endpoint = "search",
        id = "SEARCH_abc",
        query = "q1",
        url = "https://example.org/a.pdf",
        path = src,
        content_type = "application/pdf",
        status = "downloaded",
        error = NA_character_,
        stringsAsFactors = FALSE
      )
    },
    .package = "kagiPro"
  )

  testthat::local_mocked_bindings(
    read_as_markdown = function(path, ...) {
      testthat::expect_equal(normalizePath(path), normalizePath(src))
      "# Title\n\nBody"
    },
    .package = "ragnar"
  )

  out <- kagiPro::content_markdown(
    project_folder = proj,
    endpoint = "search",
    query_name = "q1"
  )

  testthat::expect_equal(nrow(out), 1L)
  testthat::expect_equal(out$status[[1]], "ok")
  testthat::expect_equal(out$endpoint[[1]], "search")
  testthat::expect_match(out$text_path[[1]], "search/markdown/query=q1/SEARCH_abc\\.md$")
  testthat::expect_true(file.exists(out$text_path[[1]]))
})

testthat::test_that("content_markdown marks row failed when ragnar throws", {
  proj <- tempfile("kagiPro-content-md-fail-proj-")
  dir.create(file.path(proj, "search", "content", "query=q1"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  src <- file.path(proj, "search", "content", "query=q1", "SEARCH_abc.pdf")
  writeLines("dummy", src)

  testthat::local_mocked_bindings(
    download_content = function(...) {
      data.frame(
        endpoint = "search",
        id = "SEARCH_abc",
        query = "q1",
        url = "https://example.org/a.pdf",
        path = src,
        content_type = "application/pdf",
        status = "downloaded",
        error = NA_character_,
        stringsAsFactors = FALSE
      )
    },
    .package = "kagiPro"
  )

  testthat::local_mocked_bindings(
    read_as_markdown = function(path, ...) stop("cannot parse"),
    .package = "ragnar"
  )

  out <- kagiPro::content_markdown(
    project_folder = proj,
    endpoint = "search",
    query_name = "q1"
  )

  testthat::expect_equal(nrow(out), 1L)
  testthat::expect_equal(out$status[[1]], "extract_failed")
  testthat::expect_equal(out$endpoint[[1]], "search")
  testthat::expect_false("text" %in% names(out))
  testthat::expect_match(out$error[[1]], "cannot parse")
})

testthat::test_that("content_markdown marks row failed when ragnar returns empty", {
  proj <- tempfile("kagiPro-content-md-empty-proj-")
  dir.create(file.path(proj, "search", "content", "query=q1"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  src <- file.path(proj, "search", "content", "query=q1", "SEARCH_abc.pdf")
  writeLines("dummy", src)

  testthat::local_mocked_bindings(
    download_content = function(...) {
      data.frame(
        endpoint = "search",
        id = "SEARCH_abc",
        query = "q1",
        url = "https://example.org/a.pdf",
        path = src,
        content_type = "application/pdf",
        status = "downloaded",
        error = NA_character_,
        stringsAsFactors = FALSE
      )
    },
    .package = "kagiPro"
  )

  testthat::local_mocked_bindings(
    read_as_markdown = function(path, ...) "",
    .package = "ragnar"
  )

  out <- kagiPro::content_markdown(
    project_folder = proj,
    endpoint = "search",
    query_name = "q1"
  )

  testthat::expect_equal(nrow(out), 1L)
  testthat::expect_equal(out$status[[1]], "extract_failed")
  testthat::expect_equal(out$endpoint[[1]], "search")
  testthat::expect_false("text" %in% names(out))
})

testthat::test_that("markdown_abstract writes one parquet file per query", {
  proj <- tempfile("kagiPro-md-abs-proj-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  parquet_dir <- file.path(proj, "search", "parquet")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
  kagiPro:::write_parquet_dataset(
    df = data.frame(
      id = c("SEARCH_a", "SEARCH_b"),
      url = c("https://example.org/a", "https://example.org/b"),
      query = c("q1", "q1"),
      stringsAsFactors = FALSE
    ),
    output = parquet_dir,
    overwrite = TRUE,
    verbose = FALSE
  )

  md_dir <- file.path(proj, "search", "markdown", "query=q1")
  dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines("This is markdown text A", file.path(md_dir, "SEARCH_a.md"))

  testthat::local_mocked_bindings(
    summarize_with_openai = function(text, model, ...) {
      paste("summary:", substr(text, 1, 4))
    },
    .package = "kagiPro"
  )

  out <- kagiPro::markdown_abstract(
    project_folder = proj,
    endpoint = "search",
    query_name = "q1",
    workers = 1,
    progress = FALSE,
    summarizer_fn = kagiPro::summarize_with_openai
  )

  testthat::expect_true(is.data.frame(out))
  testthat::expect_true(all(c("endpoint", "id", "query", "abstract", "status", "error") %in% names(out)))
  testthat::expect_true(all(out$endpoint == "search"))

  out_dir <- file.path(proj, "search", "abstract", "query=q1")
  out_files <- list.files(out_dir, pattern = "\\.parquet$", full.names = TRUE)
  testthat::expect_equal(length(out_files), 1L)
  out_file <- out_files[[1]]
  src_files <- list.files(
    file.path(proj, "search", "parquet", "query=q1"),
    pattern = "\\.parquet$",
    full.names = TRUE
  )
  testthat::expect_true(length(src_files) >= 1L)
  testthat::expect_equal(basename(out_file), basename(src_files[[1]]))

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  got <- DBI::dbGetQuery(con, sprintf("SELECT * FROM read_parquet('%s')", out_file))
  testthat::expect_equal(nrow(got), 2L)
  testthat::expect_true(any(got$status == "ok"))
  testthat::expect_true(any(got$status == "summarize_skipped"))
})

testthat::test_that("download_content expands across endpoints when endpoint is NULL", {
  proj <- tempfile("kagiPro-download-expand-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  search_parquet <- file.path(proj, "search", "parquet")
  news_parquet <- file.path(proj, "enrich_news", "parquet")
  dir.create(search_parquet, recursive = TRUE, showWarnings = FALSE)
  dir.create(news_parquet, recursive = TRUE, showWarnings = FALSE)

  kagiPro:::write_parquet_dataset(
    data.frame(id = "SEARCH_1", query = "q1", url = "not-a-url", stringsAsFactors = FALSE),
    output = search_parquet,
    overwrite = TRUE
  )
  kagiPro:::write_parquet_dataset(
    data.frame(id = "ENRICH_NEWS_1", query = "q1", url = "still-not-a-url", stringsAsFactors = FALSE),
    output = news_parquet,
    overwrite = TRUE
  )

  out <- kagiPro::download_content(
    project_folder = proj,
    endpoint = NULL,
    query_name = "q1",
    workers = 1,
    progress = FALSE
  )

  testthat::expect_true(is.data.frame(out))
  testthat::expect_equal(sort(unique(out$endpoint)), sort(c("search", "enrich_news")))
  testthat::expect_true(all(out$query == "q1"))
})

testthat::test_that("content_markdown expands across endpoints when endpoint is NULL", {
  proj <- tempfile("kagiPro-content-expand-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  src_search <- file.path(proj, "search", "content", "query=q1", "SEARCH_1.pdf")
  src_news <- file.path(proj, "enrich_news", "content", "query=q1", "ENRICH_NEWS_1.html")
  dir.create(dirname(src_search), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(src_news), recursive = TRUE, showWarnings = FALSE)
  writeLines("dummy", src_search)
  writeLines("dummy", src_news)

  testthat::local_mocked_bindings(
    download_content = function(...) {
      data.frame(
        endpoint = c("search", "enrich_news"),
        id = c("SEARCH_1", "ENRICH_NEWS_1"),
        query = c("q1", "q1"),
        url = c("https://example.org/a.pdf", "https://example.org/n.html"),
        path = c(src_search, src_news),
        content_type = c("application/pdf", "text/html"),
        status = c("downloaded", "downloaded"),
        error = c(NA_character_, NA_character_),
        stringsAsFactors = FALSE
      )
    },
    .package = "kagiPro"
  )

  testthat::local_mocked_bindings(
    read_as_markdown = function(path, ...) paste("content from", basename(path)),
    .package = "ragnar"
  )

  out <- kagiPro::content_markdown(
    project_folder = proj,
    endpoint = NULL,
    query_name = "q1",
    workers = 1,
    progress = FALSE
  )

  testthat::expect_equal(sort(unique(out$endpoint)), sort(c("search", "enrich_news")))
  testthat::expect_true(all(out$status == "ok"))
  testthat::expect_true(all(file.exists(out$text_path)))
})

testthat::test_that("markdown_abstract expands across endpoints when endpoint is NULL", {
  proj <- tempfile("kagiPro-md-abstract-expand-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  search_parquet <- file.path(proj, "search", "parquet")
  web_parquet <- file.path(proj, "enrich_web", "parquet")
  dir.create(search_parquet, recursive = TRUE, showWarnings = FALSE)
  dir.create(web_parquet, recursive = TRUE, showWarnings = FALSE)

  kagiPro:::write_parquet_dataset(
    data.frame(id = "SEARCH_1", url = "https://example.org/a", query = "q1", stringsAsFactors = FALSE),
    output = search_parquet,
    overwrite = TRUE
  )
  kagiPro:::write_parquet_dataset(
    data.frame(id = "ENRICH_WEB_1", url = "https://example.org/b", query = "q1", stringsAsFactors = FALSE),
    output = web_parquet,
    overwrite = TRUE
  )

  md_search <- file.path(proj, "search", "markdown", "query=q1")
  md_web <- file.path(proj, "enrich_web", "markdown", "query=q1")
  dir.create(md_search, recursive = TRUE, showWarnings = FALSE)
  dir.create(md_web, recursive = TRUE, showWarnings = FALSE)
  writeLines("search markdown text", file.path(md_search, "SEARCH_1.md"))
  writeLines("web markdown text", file.path(md_web, "ENRICH_WEB_1.md"))

  out <- kagiPro::markdown_abstract(
    project_folder = proj,
    endpoint = NULL,
    query_name = "q1",
    workers = 1,
    progress = FALSE,
    summarizer_fn = function(text, model, ...) {
      paste("summary", substr(text, 1, 6))
    }
  )

  testthat::expect_true(is.data.frame(out))
  testthat::expect_equal(sort(unique(out$endpoint)), sort(c("search", "enrich_web")))
  testthat::expect_true(all(c("abstract", "status") %in% names(out)))
  testthat::expect_true(file.exists(file.path(proj, "search", "abstract", "query=q1")))
  testthat::expect_true(file.exists(file.path(proj, "enrich_web", "abstract", "query=q1")))
})

testthat::test_that("read_corpus returns Arrow dataset by default", {
  proj <- tempfile("kagiPro-read-corpus-ds-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  parquet_dir <- file.path(proj, "search", "parquet")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)

  kagiPro:::write_parquet_dataset(
    data.frame(
      id = "SEARCH_1",
      query = "q1",
      Title = "A",
      stringsAsFactors = FALSE
    ),
    output = parquet_dir,
    overwrite = TRUE
  )

  x <- kagiPro::read_corpus(project_folder = proj, endpoint = "search")
  testthat::expect_true(inherits(x, "Dataset"))
})

testthat::test_that("read_corpus collects data when return_data = TRUE", {
  proj <- tempfile("kagiPro-read-corpus-col-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  parquet_dir <- file.path(proj, "search", "parquet")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)

  kagiPro:::write_parquet_dataset(
    data.frame(
      id = "SEARCH_1",
      query = "q1",
      Title = "A",
      stringsAsFactors = FALSE
    ),
    output = parquet_dir,
    overwrite = TRUE
  )

  x <- kagiPro::read_corpus(project_folder = proj, endpoint = "search", return_data = TRUE)
  testthat::expect_true(is.data.frame(x))
  testthat::expect_equal(nrow(x), 1L)
})

testthat::test_that("read_corpus links abstracts by id and query", {
  proj <- tempfile("kagiPro-read-corpus-abs-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  parquet_dir <- file.path(proj, "search", "parquet")
  abstract_dir <- file.path(proj, "search", "abstract")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(abstract_dir, recursive = TRUE, showWarnings = FALSE)

  kagiPro:::write_parquet_dataset(
    data.frame(
      id = c("SEARCH_1", "SEARCH_2"),
      query = c("q1", "q1"),
      Title = c("A", "B"),
      stringsAsFactors = FALSE
    ),
    output = parquet_dir,
    overwrite = TRUE
  )

  kagiPro:::write_parquet_dataset(
    data.frame(
      id = "SEARCH_1",
      query = "q1",
      abstract = "Alpha abstract",
      stringsAsFactors = FALSE
    ),
    output = abstract_dir,
    overwrite = TRUE
  )

  x <- kagiPro::read_corpus(project_folder = proj, endpoint = "search", return_data = TRUE, abstracts = TRUE)
  testthat::expect_true("abstract" %in% names(x))
  testthat::expect_equal(nrow(x), 2L)
  testthat::expect_equal(x$abstract[x$id == "SEARCH_1"][[1]], "Alpha abstract")
  testthat::expect_true(is.na(x$abstract[x$id == "SEARCH_2"][[1]]))
})

testthat::test_that("read_corpus adds NA abstract when abstract dataset is missing", {
  proj <- tempfile("kagiPro-read-corpus-abs-missing-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  parquet_dir <- file.path(proj, "search", "parquet")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)

  kagiPro:::write_parquet_dataset(
    data.frame(
      id = "SEARCH_1",
      query = "q1",
      Title = "A",
      stringsAsFactors = FALSE
    ),
    output = parquet_dir,
    overwrite = TRUE
  )

  x <- kagiPro::read_corpus(project_folder = proj, endpoint = "search", return_data = TRUE, abstracts = TRUE)
  testthat::expect_true("abstract" %in% names(x))
  testthat::expect_true(all(is.na(x$abstract)))
  testthat::expect_equal(nrow(x), 1L)
})

testthat::test_that("read_corpus excludes list columns for lazy abstract join with message", {
  proj <- tempfile("kagiPro-read-corpus-list-drop-")
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)
  parquet_dir <- file.path(proj, "search", "parquet")
  abstract_dir <- file.path(proj, "search", "abstract")
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(abstract_dir, recursive = TRUE, showWarnings = FALSE)

  kagiPro:::write_parquet_dataset(
    data.frame(
      id = c("SEARCH_1", "SEARCH_2"),
      query = c("q1", "q1"),
      Title = c("A", "B"),
      list = I(list(c("x", "y"), NULL)),
      stringsAsFactors = FALSE
    ),
    output = parquet_dir,
    overwrite = TRUE
  )

  kagiPro:::write_parquet_dataset(
    data.frame(
      id = "SEARCH_1",
      query = "q1",
      abstract = "Alpha abstract",
      stringsAsFactors = FALSE
    ),
    output = abstract_dir,
    overwrite = TRUE
  )

  testthat::expect_message(
    kagiPro::read_corpus(project_folder = proj, endpoint = "search", abstracts = TRUE, return_data = TRUE),
    "Excluding list-typed columns for lazy abstract join"
  )
  x <- suppressMessages(
    kagiPro::read_corpus(project_folder = proj, endpoint = "search", abstracts = TRUE, return_data = TRUE)
  )
  testthat::expect_false("list" %in% names(x))
  testthat::expect_true("abstract" %in% names(x))
  testthat::expect_equal(x$abstract[x$id == "SEARCH_1"][[1]], "Alpha abstract")
  testthat::expect_true(is.na(x$abstract[x$id == "SEARCH_2"][[1]]))

  y <- testthat::expect_no_message(
    kagiPro::read_corpus(project_folder = proj, endpoint = "search", abstracts = TRUE, return_data = TRUE, silent = TRUE)
  )
  testthat::expect_false("list" %in% names(y))
  testthat::expect_true("abstract" %in% names(y))
})
