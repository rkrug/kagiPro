#' Clean JSON Request Data While Preserving Query Metadata
#'
#' Remove JSON request data files from endpoint JSON folders in a project while
#' preserving per-query metadata files (`_query_meta.json`).
#'
#' This function is intended for reclaiming disk space while keeping enough
#' metadata for [kagi_update_query()] reruns.
#'
#' @param project_folder Root project folder containing endpoint subfolders.
#' @param dry_run Logical. If `TRUE`, do not delete anything and only report
#'   what would be removed.
#' @param verbose Logical. If `TRUE`, print progress messages.
#'
#' @return A list with:
#' - `details`: data frame with per-query deletion counts/bytes
#' - `totals`: list with `files` and `bytes`
#' - `dry_run`: logical flag
#'
#' @examples
#' \dontrun{
#' clean_request("kagi_project", dry_run = TRUE)
#' clean_request("kagi_project", dry_run = FALSE)
#' }
#'
#' @md
#' @export
clean_request <- function(
  project_folder,
  dry_run = FALSE,
  verbose = TRUE
) {
  if (!is.character(project_folder) || length(project_folder) != 1L || !nzchar(project_folder)) {
    stop("`project_folder` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!dir.exists(project_folder)) {
    stop("`project_folder` does not exist: ", project_folder, call. = FALSE)
  }
  if (!is.logical(dry_run) || length(dry_run) != 1L || is.na(dry_run)) {
    stop("`dry_run` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.logical(verbose) || length(verbose) != 1L || is.na(verbose)) {
    stop("`verbose` must be TRUE or FALSE.", call. = FALSE)
  }

  project_folder <- normalizePath(project_folder)
  endpoint_dirs <- list.dirs(project_folder, recursive = FALSE, full.names = TRUE)

  details <- data.frame(
    endpoint = character(),
    query = character(),
    files = integer(),
    bytes = numeric(),
    stringsAsFactors = FALSE
  )

  for (ep_dir in endpoint_dirs) {
    endpoint <- basename(ep_dir)
    json_dir <- file.path(ep_dir, "json")
    if (!dir.exists(json_dir)) {
      next
    }

    if (file.exists(file.path(json_dir, "00_in.progress"))) {
      if (!dry_run) unlink(file.path(json_dir, "00_in.progress"), force = TRUE)
    }
    if (dir.exists(file.path(json_dir, "_meta"))) {
      if (!dry_run) unlink(file.path(json_dir, "_meta"), recursive = TRUE, force = TRUE)
    }

    query_dirs <- list.dirs(json_dir, recursive = FALSE, full.names = TRUE)
    query_dirs <- query_dirs[basename(query_dirs) != "_meta"]

    for (q_dir in query_dirs) {
      q_name <- basename(q_dir)

      files <- list.files(q_dir, full.names = TRUE, recursive = TRUE, all.files = TRUE, no.. = TRUE)
      keep <- file.path(q_dir, "_query_meta.json")
      to_delete <- files[normalizePath(files, mustWork = FALSE) != normalizePath(keep, mustWork = FALSE)]

      if (length(to_delete) == 0L) {
        next
      }

      sizes <- suppressWarnings(file.info(to_delete)$size)
      sizes[is.na(sizes)] <- 0

      details <- rbind(
        details,
        data.frame(
          endpoint = endpoint,
          query = q_name,
          files = length(to_delete),
          bytes = sum(sizes),
          stringsAsFactors = FALSE
        )
      )

      if (verbose) {
        message(
          if (dry_run) "[dry-run] " else "",
          "Cleaning `", endpoint, "/", q_name, "`: ",
          length(to_delete), " file(s)"
        )
      }

      if (!dry_run) {
        unlink(to_delete, recursive = TRUE, force = TRUE)
        # remove empty directories created during recursive deletion
        subdirs <- list.dirs(q_dir, recursive = TRUE, full.names = TRUE)
        subdirs <- subdirs[order(nchar(subdirs), decreasing = TRUE)]
        for (d in subdirs) {
          if (identical(d, q_dir)) next
          if (dir.exists(d) && length(list.files(d, all.files = TRUE, no.. = TRUE)) == 0L) {
            unlink(d, recursive = TRUE, force = TRUE)
          }
        }
      }
    }
  }

  totals <- list(
    files = if (nrow(details) == 0L) 0L else as.integer(sum(details$files)),
    bytes = if (nrow(details) == 0L) 0 else sum(details$bytes)
  )

  list(details = details, totals = totals, dry_run = dry_run)
}
