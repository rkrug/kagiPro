# Tests for clean_request(). Pure file-system; no API.

build_project <- function() {
  project <- tempfile("clean-")
  json_dir <- file.path(project, "search", "json", "query_1")
  dir.create(json_dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(
    list.files(testthat::test_path("fixtures/json_search/query_1"), full.names = TRUE),
    json_dir,
    overwrite = TRUE
  )
  project
}

testthat::test_that("clean_request(dry_run = TRUE) reports without deleting", {
  project <- build_project()
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  before <- list.files(project, recursive = TRUE)
  res <- kagiPro::clean_request(project, dry_run = TRUE)
  after <- list.files(project, recursive = TRUE)

  testthat::expect_setequal(before, after)
  testthat::expect_true(is.list(res) || is.data.frame(res) || is.null(res) || is.character(res))
})

testthat::test_that("clean_request(dry_run = FALSE) deletes JSON pages but keeps metadata", {
  project <- build_project()
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  kagiPro::clean_request(project, dry_run = FALSE)

  q_dir <- file.path(project, "search", "json", "query_1")
  testthat::expect_true(file.exists(file.path(q_dir, "_query_meta.json")))
  testthat::expect_false(file.exists(file.path(q_dir, "search_1.json")))
})

testthat::test_that("clean_request handles a project with no JSON to clean", {
  project <- tempfile("empty-project-")
  dir.create(project)
  on.exit(unlink(project, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_no_error(
    kagiPro::clean_request(project, dry_run = TRUE)
  )
})
