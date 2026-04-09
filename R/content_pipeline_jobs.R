#' @keywords internal
content_supported_endpoints <- function() {
  c("search", "enrich", "enrich_web", "enrich_news")
}

#' @keywords internal
validate_optional_scalar <- function(x, arg) {
  if (is.null(x)) {
    return(invisible(NULL))
  }
  if (!is.character(x) || length(x) != 1L || !nzchar(x)) {
    stop("`", arg, "` must be NULL or a single non-empty character string.", call. = FALSE)
  }
  invisible(NULL)
}

#' @keywords internal
resolve_endpoint_query_jobs <- function(project_folder, endpoint = NULL, query_name = NULL) {
  validate_optional_scalar(endpoint, "endpoint")
  validate_optional_scalar(query_name, "query_name")

  supported <- content_supported_endpoints()
  endpoint <- if (!is.null(endpoint)) tolower(endpoint) else NULL

  if (!is.null(endpoint) && !endpoint %in% supported) {
    stop(
      "`endpoint` must be one of: ",
      paste(supported, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (!dir.exists(project_folder)) {
    stop("`project_folder` does not exist: ", project_folder, call. = FALSE)
  }
  project_folder <- normalizePath(project_folder)

  if (is.null(endpoint)) {
    ep_dirs <- list.dirs(project_folder, full.names = FALSE, recursive = FALSE)
    endpoints <- intersect(ep_dirs, supported)
  } else {
    endpoints <- endpoint
  }

  if (length(endpoints) == 0L) {
    return(data.frame(
      endpoint = character(),
      query = character(),
      stringsAsFactors = FALSE
    ))
  }

  jobs <- lapply(endpoints, function(ep) {
    parquet_dir <- file.path(project_folder, ep, "parquet")
    if (!dir.exists(parquet_dir)) {
      return(NULL)
    }
    q_dirs <- list.dirs(parquet_dir, recursive = FALSE, full.names = FALSE)
    queries <- sub("^query=", "", q_dirs[grepl("^query=", q_dirs)])
    queries <- unique(queries[nzchar(queries)])
    if (!is.null(query_name)) {
      queries <- queries[queries %in% query_name]
    }
    if (length(queries) == 0L) {
      return(NULL)
    }
    data.frame(
      endpoint = rep(ep, length(queries)),
      query = queries,
      stringsAsFactors = FALSE
    )
  })

  jobs <- do.call(rbind, Filter(Negate(is.null), jobs))
  if (is.null(jobs) || nrow(jobs) == 0L) {
    return(data.frame(
      endpoint = character(),
      query = character(),
      stringsAsFactors = FALSE
    ))
  }

  jobs <- unique(jobs)
  rownames(jobs) <- NULL
  jobs
}
