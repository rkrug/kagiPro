# Tests for kagi_request_parquet(). Uses fixture JSON pages so we do not
# need to hit the API.

fixture_search_dir  <- function() testthat::test_path("fixtures/json_search")
fixture_extract_dir <- function() testthat::test_path("fixtures/json_extract")

testthat::test_that("converts search JSON to Hive-partitioned parquet", {
  out <- tempfile("parquet-search-")
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  res <- kagiPro::kagi_request_parquet(
    input_json = fixture_search_dir(),
    output = out,
    overwrite = TRUE,
    verbose = FALSE,
    combine = FALSE
  )
  testthat::expect_type(res, "character")
  testthat::expect_true(dir.exists(out))

  parts <- list.dirs(out, recursive = TRUE, full.names = FALSE)
  testthat::expect_true("query=query_1" %in% parts)
  testthat::expect_true(any(grepl("^query=query_1/type=", parts)))

  ds <- arrow::open_dataset(out, format = "parquet")
  df <- dplyr::collect(ds)
  testthat::expect_true(nrow(df) > 0L)
  testthat::expect_true(all(c("id", "query", "type") %in% names(df)))
  testthat::expect_true(all(startsWith(df$id, "SEARCH_")))
})

testthat::test_that("combine = TRUE collapses partitions into combined.parquet", {
  out <- tempfile("parquet-combined-")
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  kagiPro::kagi_request_parquet(
    input_json = fixture_search_dir(),
    output = out,
    overwrite = TRUE,
    verbose = FALSE,
    combine = TRUE
  )

  files <- list.files(out, recursive = TRUE)
  testthat::expect_true("combined.parquet" %in% files)
  testthat::expect_false(any(grepl("^query=", files)))

  df <- arrow::read_parquet(file.path(out, "combined.parquet"))
  testthat::expect_true(nrow(df) > 0L)
  testthat::expect_true(all(c("id", "query", "type") %in% names(df)))
})

testthat::test_that("converts extract JSON to single-partition parquet", {
  out <- tempfile("parquet-extract-")
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  kagiPro::kagi_request_parquet(
    input_json = fixture_extract_dir(),
    output = out,
    overwrite = TRUE,
    verbose = FALSE,
    combine = FALSE
  )

  parts <- list.dirs(out, recursive = TRUE, full.names = FALSE)
  testthat::expect_true("query=query_1" %in% parts)
  df <- arrow::open_dataset(out, format = "parquet") |> dplyr::collect()
  testthat::expect_true(all(c("id", "query", "url", "markdown") %in% names(df)))
  testthat::expect_equal(nrow(df), 2L)
  testthat::expect_true(all(startsWith(df$id, "EXTRACT_")))
})

testthat::test_that("rejects missing input_json / output", {
  testthat::expect_error(
    kagiPro::kagi_request_parquet(input_json = NULL, output = tempfile()),
    "input_json"
  )
  testthat::expect_error(
    kagiPro::kagi_request_parquet(input_json = fixture_search_dir(), output = NULL),
    "output"
  )
})

testthat::test_that("refuses to overwrite without flag", {
  out <- tempfile("parquet-collide-")
  dir.create(out)
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_error(
    kagiPro::kagi_request_parquet(
      input_json = fixture_search_dir(),
      output = out,
      overwrite = FALSE,
      append = FALSE,
      verbose = FALSE
    ),
    "exists"
  )
})
