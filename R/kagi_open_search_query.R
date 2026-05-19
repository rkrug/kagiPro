#' Open Kagi search(es) in the browser
#'
#' Open one or more Kagi search queries in the default browser. The URL is
#' built from the query object so that every non-null shaping field
#' (`workflow`, `lens`, `lens_id`, `filters`, `safe_search`, `page`, `limit`,
#' `timeout`, `format`, `personalizations`, `extract`) is appended as a URL
#' query parameter alongside `q`. Scalars are URL-encoded; nested
#' lists are JSON-encoded then URL-encoded so the full search intent is
#' visible in the address bar (whether the Kagi web UI honours each field
#' is up to Kagi).
#'
#' @param query Either a single `kagi_query_search` object (as returned by
#'   `kagi_query_search(...)[[1]]`) or a named list of such objects (the raw
#'   return value of [kagi_query_search()]). Every query in the list is
#'   opened.
#' @param session_token Optional Kagi session token for private search
#'   (see your Kagi account's "Session Link").
#'
#' @return Invisibly, a character vector of the URLs that were opened.
#' @export
kagi_open_search_query <- function(
  query,
  session_token = NULL
) {
  if (inherits(query, "kagi_query_search")) {
    queries <- list(query)
  } else if (is.list(query) &&
             length(query) > 0L &&
             all(vapply(query, inherits, logical(1), what = "kagi_query_search"))) {
    queries <- query
  } else {
    stop(
      "`query` must be a `kagi_query_search` object or a list of such objects.",
      call. = FALSE
    )
  }

  base <- "https://kagi.com/search"

  encode_value <- function(v) {
    if (is.list(v)) {
      txt <- jsonlite::toJSON(v, auto_unbox = TRUE, null = "null")
    } else {
      txt <- paste(as.character(v), collapse = ",")
    }
    utils::URLencode(txt, reserved = TRUE)
  }

  build_url <- function(q) {
    term <- as.character(q$query)[[1]]
    stopifnot(nzchar(term))

    params <- c(q = utils::URLencode(term, reserved = TRUE))
    if (!is.null(session_token) && nzchar(session_token)) {
      params <- c(token = session_token, params)
    }

    shaping <- q[setdiff(names(q), "query")]
    shaping <- Filter(function(x) !is.null(x) && length(x) > 0L, shaping)
    for (nm in names(shaping)) {
      params <- c(params, stats::setNames(encode_value(shaping[[nm]]), nm))
    }

    paste0(base, "?", paste0(names(params), "=", params, collapse = "&"))
  }

  urls <- vapply(queries, function(q) {
    url <- build_url(q)
    utils::browseURL(url)
    url
  }, character(1))

  invisible(unname(urls))
}
