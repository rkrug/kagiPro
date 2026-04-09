#' Re-Run a Stored Query by Name and Refresh Parquet
#'
#' Update one query dataset by `query_name` using metadata written by
#' [kagi_request()]. The function scans per-query metadata files under
#' `<project_folder>/<endpoint>/json/<query_name>/_query_meta.json`,
#' re-runs all matching query definitions, and refreshes only the touched
#' parquet query partitions.
#'
#' If the same `query_name` exists across multiple endpoints, all matching
#' endpoints are updated.
#'
#' @param connection A [kagi_connection()] object.
#' @param project_folder Root project folder containing endpoint subfolders.
#' @param query_name Query name to update (for example `"query_1"` or
#'   `"biodiversity_main"`).
#' @param workers Number of workers for request execution.
#' @param verbose Logical indicating whether progress messages should be shown.
#' @param error_mode Error handling mode passed to [kagi_request()]. One of
#'   `"stop"` or `"write_dummy"`.
#'
#' @return Named list of normalized parquet output paths by updated endpoint.
#'
#' @examples
#' \dontrun{
#' kagi_update_query(
#'   connection = conn,
#'   project_folder = "kagi_project",
#'   query_name = "query_1"
#' )
#' }
#'
#' @md
#' @export
kagi_update_query <- function(
  connection,
  project_folder,
  query_name,
  workers = 1,
  verbose = FALSE,
  error_mode = c("stop", "write_dummy")
) {
  error_mode <- match.arg(error_mode)

  if (!inherits(connection, "kagi_connection")) {
    stop("`connection` must be of class `kagi_connection`.", call. = FALSE)
  }
  if (!is.character(project_folder) || length(project_folder) != 1L || !nzchar(project_folder)) {
    stop("`project_folder` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!is.character(query_name) || length(query_name) != 1L || !nzchar(query_name)) {
    stop("`query_name` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!dir.exists(project_folder)) {
    stop("`project_folder` does not exist: ", project_folder, call. = FALSE)
  }

  project_folder <- normalizePath(project_folder)

  endpoint_dirs <- list.dirs(project_folder, recursive = FALSE, full.names = FALSE)
  if (length(endpoint_dirs) == 0L) {
    stop("No endpoint folders found in `project_folder`.", call. = FALSE)
  }

  matches <- list()
  for (ep in endpoint_dirs) {
    json_dir <- file.path(project_folder, ep, "json")
    if (!dir.exists(json_dir)) {
      next
    }
    query_dirs <- list.dirs(json_dir, recursive = FALSE, full.names = TRUE)
    query_dirs <- query_dirs[basename(query_dirs) != "_meta"]
    if (length(query_dirs) == 0L) {
      next
    }
    meta_files <- file.path(query_dirs, "_query_meta.json")
    meta_files <- meta_files[file.exists(meta_files)]
    if (length(meta_files) == 0L) {
      next
    }
    entries <- lapply(meta_files, read_query_meta_file)
    keep_idx <- which(vapply(entries, function(x) identical(as.character(x$query_name), query_name), logical(1)))
    if (length(keep_idx) > 0L) {
      matches[[ep]] <- entries[keep_idx]
    }
  }

  if (length(matches) == 0L) {
    stop(
      "No metadata entry found for query_name `",
      query_name,
      "` in `",
      project_folder,
      "`.",
      call. = FALSE
    )
  }

  out <- list()

  for (ep in names(matches)) {
    entries <- matches[[ep]]
    if (length(entries) > 1L) {
      ord <- order(vapply(entries, function(x) as.character(x$updated_at %||% ""), character(1)), decreasing = TRUE)
      entry <- entries[[ord[[1]]]]
    } else {
      entry <- entries[[1]]
    }

    query_obj <- reconstruct_query_from_meta(
      query_class = as.character(entry$query_class),
      query_payload = entry$query_payload
    )
    effective_error_mode <- as.character(entry$request_args$error_mode %||% error_mode)
    if (!effective_error_mode %in% c("stop", "write_dummy")) {
      effective_error_mode <- error_mode
    }
    effective_workers <- entry$request_args$workers %||% workers

    query_list <- stats::setNames(list(query_obj), query_name)
    json_dir <- file.path(project_folder, ep, "json")
    parquet_dir <- file.path(project_folder, ep, "parquet")

    if (!dir.exists(json_dir)) {
      stop("Missing JSON folder for endpoint `", ep, "`: ", json_dir, call. = FALSE)
    }
    if (!dir.exists(parquet_dir)) {
      stop("Missing parquet folder for endpoint `", ep, "`: ", parquet_dir, call. = FALSE)
    }

    query_json_dir <- file.path(json_dir, query_name)
    if (dir.exists(query_json_dir)) {
      unlink(query_json_dir, recursive = TRUE, force = TRUE)
    }

    kagi_request(
      connection = connection,
      query = query_list,
      limit = entry$request_args$limit %||% NULL,
      output = json_dir,
      overwrite = FALSE,
      append = TRUE,
      workers = effective_workers,
      verbose = verbose,
      error_mode = effective_error_mode,
      metadata_request_args = list(
        workers = effective_workers,
        error_mode = effective_error_mode
      )
    )

    tmp_json <- tempfile("kagiPro-update-json-")
    tmp_query_dir <- file.path(tmp_json, query_name)
    dir.create(tmp_query_dir, recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(tmp_json, recursive = TRUE, force = TRUE), add = TRUE)

    src_dir <- file.path(json_dir, query_name)
    if (!dir.exists(src_dir)) {
      stop(
        "Updated JSON query folder not found for endpoint `",
        ep,
        "` and query `",
        query_name,
        "`.",
        call. = FALSE
      )
    }

    json_files <- list.files(src_dir, pattern = "\\.json$", full.names = TRUE)
    if (length(json_files) == 0L) {
      stop(
        "No JSON files found for endpoint `",
        ep,
        "` and query `",
        query_name,
        "` after rerun.",
        call. = FALSE
      )
    }

    file.copy(json_files, tmp_query_dir, overwrite = TRUE)

    out[[ep]] <- kagi_request_parquet(
      input_json = tmp_json,
      output = parquet_dir,
      overwrite = FALSE,
      append = TRUE,
      verbose = verbose,
      delete_input = FALSE
    )
  }

  out
}
