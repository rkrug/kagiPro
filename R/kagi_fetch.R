#' Fetch Kagi Data into an Endpoint-Structured Project Folder
#'
#' High-level helper that runs [kagi_request()] and [kagi_request_parquet()] in
#' sequence and writes outputs into endpoint-scoped project folders.
#'
#' Folder layout:
#'
#' - `<project_folder>/<endpoint>/json`
#' - `<project_folder>/<endpoint>/parquet`
#'
#' @param connection A [kagi_connection()] object.
#' @param query A query object of class `kagi_query_*` or a list of query
#'   objects.
#' @param project_folder Root folder for endpoint-scoped outputs. If `NULL`, a
#'   temporary directory is used.
#' @param endpoint Optional endpoint override. One of `"search"`,
#'   `"enrich_web"`, `"enrich_news"`, `"summarize"`, `"fastgpt"`.
#' @param overwrite Logical. If `TRUE`, endpoint output folders are overwritten.
#' @param workers Number of workers for list requests.
#' @param limit Optional integer limit used for search/enrich request calls.
#' @param verbose Logical indicating whether progress messages should be shown.
#' @param error_mode Error handling mode passed to [kagi_request()].
#'   One of `"stop"` or `"write_dummy"`.
#'
#' @return For a single endpoint, normalized parquet path. For mixed endpoint
#'   query lists, a named list of normalized parquet paths by endpoint.
#'
#' @examples
#' \dontrun{
#' conn <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))
#' q <- query_search("biodiversity", expand = FALSE)
#'
#' kagi_fetch(
#'   connection = conn,
#'   query = q,
#'   project_folder = "kagi_project"
#' )
#' }
#'
#' @md
#' @export
kagi_fetch <- function(
  connection,
  query,
  project_folder = NULL,
  endpoint = NULL,
  overwrite = FALSE,
  workers = 1,
  limit = NULL,
  verbose = FALSE,
  error_mode = c("stop", "write_dummy")
) {
  error_mode <- match.arg(error_mode)

  if (!inherits(connection, "kagi_connection")) {
    stop("`connection` must be of class `kagi_connection`.", call. = FALSE)
  }

  if (is.null(project_folder)) {
    project_folder <- tempfile("kagiPro-project-")
  }
  dir.create(project_folder, recursive = TRUE, showWarnings = FALSE)
  project_folder <- normalizePath(project_folder)

  endpoint_levels <- c("search", "enrich_web", "enrich_news", "summarize", "fastgpt")

  normalize_endpoint <- function(x) {
    if (is.null(x)) return(NULL)
    x <- tolower(x)
    if (!x %in% endpoint_levels) {
      stop("Unknown endpoint: `", x, "`.", call. = FALSE)
    }
    x
  }

  detect_endpoint <- function(q) {
    cls <- class(q)[[1]]
    switch(
      cls,
      kagi_query_search = "search",
      kagi_query_enrich_web = "enrich_web",
      kagi_query_enrich_news = "enrich_news",
      kagi_query_summarize = "summarize",
      kagi_query_fastgpt = "fastgpt",
      stop("Unsupported query class: ", cls, call. = FALSE)
    )
  }

  is_query_obj <- function(x) {
    inherits(
      x,
      c(
        "kagi_query_search",
        "kagi_query_enrich_web",
        "kagi_query_enrich_news",
        "kagi_query_summarize",
        "kagi_query_fastgpt"
      )
    )
  }

  build_endpoint_job <- function(endpoint_name, query_value) {
    endpoint_dir <- file.path(project_folder, endpoint_name)
    json_dir <- file.path(endpoint_dir, "json")
    parquet_dir <- file.path(endpoint_dir, "parquet")

    if (is_query_obj(query_value)) {
      query_value <- list(query_1 = query_value)
    } else {
      if (is.null(names(query_value))) {
        names(query_value) <- paste0("query_", seq_along(query_value))
      } else {
        empty <- which(is.na(names(query_value)) | !nzchar(names(query_value)))
        if (length(empty) > 0L) {
          names(query_value)[empty] <- paste0("query_", empty)
        }
      }
    }

    if (isTRUE(overwrite) && dir.exists(endpoint_dir)) {
      unlink(endpoint_dir, recursive = TRUE, force = TRUE)
    } else if (dir.exists(json_dir)) {
      # Update only touched query datasets, keep untouched ones in place.
      query_dirs <- file.path(json_dir, names(query_value))
      for (qd in query_dirs) {
        if (dir.exists(qd)) {
          unlink(qd, recursive = TRUE, force = TRUE)
        }
      }
    }

    list(
      endpoint_name = endpoint_name,
      query_value = query_value,
      endpoint_dir = endpoint_dir,
      json_dir = json_dir,
      parquet_dir = parquet_dir
    )
  }

  run_endpoint_request <- function(job) {
    kagi_request(
      connection = connection,
      query = job$query_value,
      limit = limit,
      output = job$json_dir,
      overwrite = overwrite,
      append = !overwrite,
      workers = workers,
      verbose = verbose,
      error_mode = error_mode,
      metadata_request_args = list(
        workers = workers,
        error_mode = error_mode
      )
    )
  }

  run_endpoint_parquet <- function(job) {
    out <- kagi_request_parquet(
      input_json = job$json_dir,
      output = job$parquet_dir,
      overwrite = overwrite,
      append = !overwrite,
      verbose = verbose,
      delete_input = FALSE
    )

    out
  }

  endpoint <- normalize_endpoint(endpoint)

  if (is_query_obj(query)) {
    endpoint_detected <- detect_endpoint(query)
    endpoint_use <- endpoint %||% endpoint_detected
    job <- build_endpoint_job(endpoint_use, query)
    run_endpoint_request(job)
    return(run_endpoint_parquet(job))
  }

  if (!is.list(query) || length(query) == 0L) {
    stop("`query` must be a query object or a non-empty list of query objects.", call. = FALSE)
  }

  all_query_objs <- vapply(query, is_query_obj, logical(1))
  if (!all(all_query_objs)) {
    stop("All elements in `query` must be `kagi_query_*` objects.", call. = FALSE)
  }

  endpoints <- vapply(query, detect_endpoint, character(1))

  if (!is.null(endpoint)) {
    if (any(endpoints != endpoint)) {
      stop(
        "`endpoint` override is incompatible with provided query list classes.",
        call. = FALSE
      )
    }
    job <- build_endpoint_job(endpoint, query)
    run_endpoint_request(job)
    return(run_endpoint_parquet(job))
  }

  endpoint_unique <- unique(endpoints)
  if (length(endpoint_unique) == 1L) {
    job <- build_endpoint_job(endpoint_unique[[1]], query)
    run_endpoint_request(job)
    return(run_endpoint_parquet(job))
  }

  split_idx <- split(seq_along(query), endpoints)
  jobs <- lapply(names(split_idx), function(ep) {
    idx <- split_idx[[ep]]
    q_sub <- query[idx]
    build_endpoint_job(ep, q_sub)
  })
  names(jobs) <- names(split_idx)

  # Phase 1: request all endpoints
  lapply(jobs, run_endpoint_request)

  # Phase 2: convert all endpoints to parquet
  out <- lapply(jobs, run_endpoint_parquet)

  out
}
