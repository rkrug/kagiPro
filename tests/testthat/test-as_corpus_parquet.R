# Tests for as_corpus_parquet() built on top of a fixture-derived parquet
# dataset (search JSON -> parquet -> corpus).

build_search_parquet <- function() {
  tmp <- tempfile("corpus-fixture-")
  kagiPro::kagi_request_parquet(
    input_json = testthat::test_path("fixtures/json_search"),
    output = tmp,
    overwrite = TRUE,
    verbose = FALSE,
    combine = FALSE
  )
  tmp
}

testthat::test_that("as_corpus_parquet writes (id, title, abstract)", {
  parquet_dir <- build_search_parquet()
  on.exit(unlink(parquet_dir, recursive = TRUE, force = TRUE), add = TRUE)

  project <- tempfile("corpus-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  res <- kagiPro::as_corpus_parquet(
    input = parquet_dir,
    project_dir = project,
    overwrite = TRUE
  )
  corpus_dir <- file.path(project, "corpus")
  testthat::expect_true(dir.exists(corpus_dir))

  ds <- arrow::open_dataset(corpus_dir, format = "parquet")
  df <- dplyr::collect(ds)
  testthat::expect_setequal(names(df), c("id", "title", "abstract"))
  testthat::expect_true(nrow(df) > 0L)
})

testthat::test_that("as_corpus_parquet accepts an endpoint_dir (with parquet/ child)", {
  parquet_dir <- build_search_parquet()
  endpoint_dir <- tempfile("endpoint-")
  dir.create(file.path(endpoint_dir, "parquet"), recursive = TRUE)
  file.copy(
    list.files(parquet_dir, full.names = TRUE),
    file.path(endpoint_dir, "parquet"),
    recursive = TRUE
  )
  on.exit(unlink(c(parquet_dir, endpoint_dir), recursive = TRUE, force = TRUE), add = TRUE)

  project <- tempfile("corpus-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  kagiPro::as_corpus_parquet(
    input = endpoint_dir,
    project_dir = project,
    overwrite = TRUE
  )
  testthat::expect_true(dir.exists(file.path(project, "corpus")))
})

testthat::test_that("as_corpus_parquet errors on missing required columns", {
  bad <- tempfile("bad-corpus-")
  dir.create(bad)
  on.exit(unlink(bad, recursive = TRUE, force = TRUE), add = TRUE)

  # Write a parquet that lacks `title`
  arrow::write_parquet(
    data.frame(id = "x", url = "https://example.com", stringsAsFactors = FALSE),
    file.path(bad, "part.parquet")
  )

  project <- tempfile("corpus-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_error(
    kagiPro::as_corpus_parquet(
      input = bad,
      project_dir = project,
      overwrite = TRUE
    ),
    "missing required columns"
  )
})

testthat::test_that("as_corpus_parquet refuses to overwrite without flag", {
  parquet_dir <- build_search_parquet()
  on.exit(unlink(parquet_dir, recursive = TRUE, force = TRUE), add = TRUE)

  project <- tempfile("corpus-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)
  kagiPro::as_corpus_parquet(
    input = parquet_dir,
    project_dir = project,
    overwrite = TRUE
  )

  testthat::expect_error(
    kagiPro::as_corpus_parquet(
      input = parquet_dir,
      project_dir = project,
      overwrite = FALSE
    ),
    "already exists"
  )
})

testthat::test_that("as_corpus_parquet applies id_prefix", {
  parquet_dir <- build_search_parquet()
  on.exit(unlink(parquet_dir, recursive = TRUE, force = TRUE), add = TRUE)
  project <- tempfile("corpus-")
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  kagiPro::as_corpus_parquet(
    input = parquet_dir,
    project_dir = project,
    id_prefix = "KAGI",
    overwrite = TRUE
  )
  df <- arrow::open_dataset(file.path(project, "corpus"), format = "parquet") |>
    dplyr::collect()
  testthat::expect_true(all(startsWith(df$id, "KAGI_")))
})
