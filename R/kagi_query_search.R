#' Build a Kagi Search query
#'
#' Construct one or more query objects of class `kagi_query_search` for the
#' Kagi Search API (`POST /search`). Queries are typed JSON bodies that select
#' a workflow (`search`, `images`, `videos`, `news`, or `podcasts`) and may
#' carry filters, lens, extract, and personalization rules.
#'
#' **Default is intentionally neutral.** Calling `kagi_query_search("term")`
#' with no other arguments sends only `{"query": "term", "workflow": "search"}`
#' to the API — no lens, no filters, no personalizations, no safe_search
#' override, no extract. Every shaping option is opt-in. This keeps default
#' results as objective and reproducible as the Kagi API itself allows.
#'
#' If `query` is a character vector and `expand = TRUE`, a list of query objects
#' is returned (one per term) so the same `kagi_request()` parallel-dispatch
#' code path is used for batch fetches.
#'
#' @param query Character vector of one or more search queries. Required.
#' @param workflow Character. One of `"search"`, `"images"`, `"videos"`,
#'   `"news"`, `"podcasts"`. Defaults to `"search"`.
#' @param format Optional character. `"json"` (default) or `"markdown"`
#'   (experimental).
#' @param lens Optional named list describing an inline lens. See the OpenAPI
#'   spec for the shape (`sites_included`, `sites_excluded`,
#'   `keywords_included`, `keywords_excluded`, `file_type`, `time_after`,
#'   `time_before`, `time_relative`, `search_region`).
#' @param lens_id Optional character. ID of a Kagi-side lens, or its full URL.
#'   Mutually exclusive with `lens`.
#' @param timeout Optional numeric between 0.5 and 4.
#' @param page Optional integer between 1 and 10. Page number to request from
#'   the API (body-paginated; the caller controls this directly).
#' @param limit Optional integer between 1 and 1024. Maximum number of results.
#' @param filters Optional named list (`region`, `after`, `before`).
#' @param extract Optional named list (`count`, `timeout`) requesting page
#'   content extraction. Note: this incurs additional Extract-API cost.
#' @param safe_search Optional logical. Default `TRUE` (omits NSFW content).
#' @param personalizations Optional named list (`domains`, `regexes`).
#' @param expand Logical, default `TRUE`. If `TRUE` and `query` has multiple
#'   terms, produce one query object per term.
#' @param open_in_browser Logical, default `FALSE`. If `TRUE`, each query is
#'   also opened in the default browser via [open_search_query()].
#'
#' @return A named list of `kagi_query_search` objects, suitable for
#'   [kagi_request()] or [kagi_fetch()].
#'
#' @details
#' Validation matches the OpenAPI bounds: `timeout` in `[0.5, 4]`, `page` in
#' `[1, 10]`, `limit` in `[1, 1024]`. The `lens` and `lens_id` arguments are
#' mutually exclusive. Other fields are passed through as-is and serialized to
#' the JSON request body when the request is performed.
#'
#' @seealso
#'   [kagi_query_extract()] for the `/extract` endpoint,
#'   [kagi_connection()],
#'   [kagi_request()],
#'   [kagi_fetch()]
#'
#' @examples
#' \dontrun{
#' conn <- kagi_connection()
#' q <- kagi_query_search(
#'   "biodiversity loss",
#'   workflow = "search",
#'   limit = 50,
#'   filters = list(region = "DE")
#' )
#' kagi_fetch(conn, q, project_folder = "kagi_demo")
#' }
#'
#' @md
#' @export
kagi_query_search <- function(
  query,
  workflow = c("search", "images", "videos", "news", "podcasts"),
  format = NULL,
  lens = NULL,
  lens_id = NULL,
  timeout = NULL,
  page = NULL,
  limit = NULL,
  filters = NULL,
  extract = NULL,
  safe_search = NULL,
  personalizations = NULL,
  expand = TRUE,
  open_in_browser = FALSE
) {
  if (missing(query) || is.null(query)) {
    stop("`query` is required.", call. = FALSE)
  }
  if (!is.character(query) || any(!nzchar(trimws(query)))) {
    stop("`query` must be a non-empty character vector.", call. = FALSE)
  }

  workflow <- match.arg(workflow)

  if (!is.null(format)) {
    format <- match.arg(format, choices = c("json", "markdown"))
  }

  if (!is.null(lens) && !is.null(lens_id)) {
    stop("Provide at most one of `lens` or `lens_id`.", call. = FALSE)
  }
  if (!is.null(lens) && !is.list(lens)) {
    stop("`lens` must be a named list.", call. = FALSE)
  }
  if (!is.null(lens_id)) {
    stopifnot(is.character(lens_id), length(lens_id) == 1L, nzchar(lens_id))
  }

  if (!is.null(timeout)) {
    stopifnot(is.numeric(timeout), length(timeout) == 1L, !is.na(timeout))
    if (timeout < 0.5 || timeout > 4) {
      stop("`timeout` must be between 0.5 and 4 seconds.", call. = FALSE)
    }
  }
  if (!is.null(page)) {
    stopifnot(is.numeric(page), length(page) == 1L, !is.na(page))
    page <- as.integer(page)
    if (page < 1L || page > 10L) {
      stop("`page` must be between 1 and 10.", call. = FALSE)
    }
  }
  if (!is.null(limit)) {
    stopifnot(is.numeric(limit), length(limit) == 1L, !is.na(limit))
    limit <- as.integer(limit)
    if (limit < 1L || limit > 1024L) {
      stop("`limit` must be between 1 and 1024.", call. = FALSE)
    }
  }
  if (!is.null(filters) && !is.list(filters)) {
    stop("`filters` must be a named list.", call. = FALSE)
  }
  if (!is.null(extract) && !is.list(extract)) {
    stop(
      "`extract` must be a named list with `count` and optional `timeout`.",
      call. = FALSE
    )
  }
  if (!is.null(safe_search)) {
    stopifnot(
      is.logical(safe_search),
      length(safe_search) == 1L,
      !is.na(safe_search)
    )
  }
  if (!is.null(personalizations) && !is.list(personalizations)) {
    stop("`personalizations` must be a named list.", call. = FALSE)
  }

  queries <- if (isTRUE(expand)) {
    as.list(query)
  } else {
    list(paste(query, collapse = " "))
  }
  queries <- lapply(queries, trimws)

  shared <- Filter(
    Negate(is.null),
    list(
      workflow = workflow,
      format = format,
      lens = lens,
      lens_id = lens_id,
      timeout = timeout,
      page = page,
      limit = limit,
      filters = filters,
      extract = extract,
      safe_search = safe_search,
      personalizations = personalizations
    )
  )

  result <- lapply(queries, function(q) {
    obj <- c(list(query = q), shared)
    class(obj) <- c("kagi_query_search", "list")
    obj
  })

  names(result) <- paste0("query_", seq_along(result))

  if (isTRUE(open_in_browser)) {
    for (obj in result) {
      open_search_query(obj$query)
    }
  }

  result
}

#' @export
print.kagi_query_search <- function(x, ...) {
  cat("<kagi_query_search>\n")
  cat("  query:    \"", x$query, "\"\n", sep = "")
  cat("  workflow: ", x$workflow, "\n", sep = "")
  for (nm in setdiff(names(x), c("query", "workflow"))) {
    val <- x[[nm]]
    if (is.list(val)) {
      cat("  ", nm, ": <", paste(names(val), collapse = ", "), ">\n", sep = "")
    } else {
      cat("  ", nm, ": ", paste(val, collapse = ", "), "\n", sep = "")
    }
  }
  invisible(x)
}
