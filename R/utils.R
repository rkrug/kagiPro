`%||%` <- function(x, y) {
  if (is.null(x) || (is.character(x) && !nzchar(x))) y else x
}

#' Resolve API key from a connection object
#' @keywords internal
resolve_api_key <- function(api_key) {
  if (is.null(api_key)) {
    key <- Sys.getenv("KAGI_API_KEY", "")
  } else if (is.function(api_key)) {
    key <- api_key()
  } else {
    key <- api_key
  }

  if (!nzchar(key)) {
    stop("Missing API key (set KAGI_API_KEY or pass api_key).", call. = FALSE)
  }
  key
}


#' Build a User-Agent string for kagiPro
#' @keywords internal
kagiPro_user_agent <- function() {
  pkg <- utils::packageDescription("kagiPro")
  paste0(pkg$Package, "/", pkg$Version)
}

#' Resolve canonical endpoint from query class
#' @noRd
#' @keywords internal
endpoint_from_query_class <- function(query_class) {
  switch(
    query_class,
    kagi_query_search = "search",
    kagi_query_extract = "extract",
    stop("Unknown Query Class: ", query_class, call. = FALSE)
  )
}

#' Resolve request path endpoint from query class
#' @noRd
#' @keywords internal
endpoint_path_from_query_class <- function(query_class) {
  switch(
    query_class,
    kagi_query_search = "search",
    kagi_query_extract = "extract",
    stop("Unknown Query Class: ", query_class, call. = FALSE)
  )
}

#' All supported query classes
#' @noRd
#' @keywords internal
kagi_query_classes <- function() {
  c(
    "kagi_query_search",
    "kagi_query_extract"
  )
}

#' Serialize query payload for metadata
#' @noRd
#' @keywords internal
serialize_query_payload <- function(query, query_class = class(query)[[1]]) {
  unclass(query)
}

#' Strip the kagi_query_* class so the object can be serialized as a plain list
#' for JSON body construction.
#' @noRd
#' @keywords internal
unclass_query <- function(query) {
  cls <- class(query)
  class(query) <- cls[!cls %in% kagi_query_classes()]
  query
}

#' Reconstruct query object from persisted metadata
#' @noRd
#' @keywords internal
reconstruct_query_from_meta <- function(query_class, query_payload) {
  switch(
    query_class,
    kagi_query_search = {
      q <- if (is.list(query_payload)) query_payload else list()
      class(q) <- c("kagi_query_search", "list")
      q
    },
    kagi_query_extract = {
      q <- if (is.list(query_payload)) query_payload else list()
      class(q) <- c("kagi_query_extract", "list")
      q
    },
    stop("Unsupported query_class in metadata: ", query_class, call. = FALSE)
  )
}

#' Write per-query metadata
#' @noRd
#' @keywords internal
write_query_metadata <- function(
  query_dir,
  query_name,
  endpoint,
  query_class,
  query_payload,
  request_args = list(),
  schema_version = "1.0.0"
) {
  dir.create(query_dir, recursive = TRUE, showWarnings = FALSE)

  entry <- list(
    query_name = query_name,
    endpoint = endpoint,
    query_class = query_class,
    query_payload = query_payload,
    request_args = request_args,
    schema_version = schema_version,
    kagiPro_version = as.character(utils::packageVersion("kagiPro")),
    updated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )

  jsonlite::write_json(
    entry,
    path = file.path(query_dir, "_query_meta.json"),
    auto_unbox = TRUE,
    null = "null",
    pretty = TRUE
  )

  invisible(entry)
}

#' Read and validate per-query metadata file
#' @noRd
#' @keywords internal
read_query_meta_file <- function(path) {
  if (!file.exists(path)) {
    stop("Metadata file not found: ", path, call. = FALSE)
  }
  entry <- tryCatch(
    jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) {
      stop(
        "Corrupt metadata file `",
        path,
        "`: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )

  required <- c("query_name", "endpoint", "query_class", "query_payload")
  missing <- required[!vapply(required, function(k) !is.null(entry[[k]]), logical(1))]
  if (length(missing) > 0L) {
    stop(
      "Invalid metadata file `",
      path,
      "`. Missing fields: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  entry
}
