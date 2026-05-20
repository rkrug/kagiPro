# Cassette-backed end-to-end tests for kagi_fetch().
# See helper_kagi.R for the cassette policy (KAGIPRO_RECORD_CASSETTES,
# VCR_RECORD_MODE).

testthat::test_that("kagi_fetch search produces combined parquet", {
  cn <- "kagi-fetch-search-combined"
  skip_if_cannot_serve_cassette(cn)
  conn <- make_kagi_test_conn(cn)
  q <- kagiPro::kagi_query_search("kagiPro test", limit = 5)
  project <- tempfile("kagi-fetch-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  vcr::use_cassette(cn, {
    parquet_path <- kagiPro::kagi_fetch(
      connection = conn,
      query = q,
      project_folder = project,
      pages = 1,
      overwrite = TRUE,
      verbose = FALSE,
      combine = TRUE
    )
  })

  testthat::expect_true(file.exists(file.path(parquet_path, "combined.parquet")))
  df <- arrow::read_parquet(file.path(parquet_path, "combined.parquet"))
  testthat::expect_true(nrow(df) > 0L)
  testthat::expect_true(all(c("id", "query", "type") %in% names(df)))
  testthat::expect_true(all(startsWith(df$id, "SEARCH_")))
})

testthat::test_that("kagi_fetch search keeps Hive partitions with combine = FALSE", {
  cn <- "kagi-fetch-search-partitioned"
  skip_if_cannot_serve_cassette(cn)
  conn <- make_kagi_test_conn(cn)
  q <- kagiPro::kagi_query_search("kagiPro test", limit = 5)
  project <- tempfile("kagi-fetch-part-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  vcr::use_cassette(cn, {
    parquet_path <- kagiPro::kagi_fetch(
      connection = conn,
      query = q,
      project_folder = project,
      pages = 1,
      overwrite = TRUE,
      verbose = FALSE,
      combine = FALSE
    )
  })

  parts <- list.dirs(parquet_path, recursive = TRUE, full.names = FALSE)
  testthat::expect_true(any(grepl("^query=query_1", parts)))
  testthat::expect_false(file.exists(file.path(parquet_path, "combined.parquet")))
})

testthat::test_that("kagi_fetch extract roundtrips to parquet", {
  cn <- "kagi-fetch-extract"
  skip_if_cannot_serve_cassette(cn)
  conn <- make_kagi_test_conn(cn)
  q <- kagiPro::kagi_query_extract("https://example.com")
  project <- tempfile("kagi-fetch-extract-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  vcr::use_cassette(cn, {
    parquet_path <- kagiPro::kagi_fetch(
      connection = conn,
      query = q,
      project_folder = project,
      overwrite = TRUE,
      verbose = FALSE,
      combine = TRUE
    )
  })

  # JSON must always be written; parquet only if Kagi returned non-empty data.
  json_files <- list.files(
    file.path(project, "extract", "json"),
    pattern = "extract_.*\\.json$",
    recursive = TRUE,
    full.names = TRUE
  )
  testthat::expect_gt(length(json_files), 0L)
  payload <- jsonlite::fromJSON(json_files[[1]], simplifyVector = FALSE)
  testthat::expect_true("data" %in% names(payload))

  combined <- file.path(parquet_path, "combined.parquet")
  if (file.exists(combined)) {
    df <- arrow::read_parquet(combined)
    testthat::expect_true(all(c("id", "query", "url", "markdown") %in% names(df)))
    testthat::expect_true(all(startsWith(df$id, "EXTRACT_")))
  }
})
