#' Build a Kagi Extract query
#'
#' Construct one or more query objects of class `kagi_query_extract` for the
#' Kagi Extract API (`POST /extract`). Each query holds up to 10
#' HTTPS URLs. If more URLs are supplied, they are auto-chunked into multiple
#' query objects so the existing parallel dispatch in [kagi_request()] can
#' batch them.
#'
#' @param pages Character vector of HTTPS URLs. Required. Each URL is sent
#'   through `/extract` and converted to markdown.
#' @param timeout Optional numeric. Timeout in seconds for the extraction.
#' @param format Optional character. `"json"` (default) or `"markdown"`.
#' @param chunk_size Integer, default `10` (the API's per-request maximum).
#'   Caller can lower this for finer-grained parallelism.
#'
#' @return A named list of `kagi_query_extract` objects, suitable for
#'   [kagi_request()] or [kagi_fetch()].
#'
#' @details
#' The API requires HTTPS URLs and accepts 1-10 per request. This wrapper
#' validates the HTTPS scheme and chunks long input vectors automatically.
#'
#' @seealso
#'   [kagi_query_search()] for the `/search` endpoint,
#'   [kagi_connection()],
#'   [kagi_request()],
#'   [kagi_fetch()]
#'
#' @examples
#' \dontrun{
#' conn <- kagi_connection()
#' q <- kagi_query_extract(c(
#'   "https://example.com/article-1",
#'   "https://example.com/article-2"
#' ))
#' kagi_fetch(conn, q, project_folder = "kagi_extract_demo")
#' }
#'
#' @md
#' @export
kagi_query_extract <- function(
  pages,
  timeout = NULL,
  format = NULL,
  chunk_size = 10L
) {
  if (missing(pages) || is.null(pages)) {
    stop("`pages` is required.", call. = FALSE)
  }
  if (!is.character(pages) || length(pages) == 0L) {
    stop(
      "`pages` must be a non-empty character vector of HTTPS URLs.",
      call. = FALSE
    )
  }
  if (any(!nzchar(trimws(pages)))) {
    stop("`pages` contains empty entries.", call. = FALSE)
  }
  if (any(!grepl("^https://", pages, ignore.case = TRUE))) {
    stop("All `pages` must be HTTPS URLs.", call. = FALSE)
  }

  if (!is.null(timeout)) {
    stopifnot(is.numeric(timeout), length(timeout) == 1L, !is.na(timeout))
  }
  if (!is.null(format)) {
    format <- match.arg(format, choices = c("json", "markdown"))
  }
  stopifnot(is.numeric(chunk_size), length(chunk_size) == 1L)
  chunk_size <- as.integer(chunk_size)
  if (chunk_size < 1L || chunk_size > 10L) {
    stop("`chunk_size` must be between 1 and 10 (API limit).", call. = FALSE)
  }

  chunks <- split(pages, ceiling(seq_along(pages) / chunk_size))

  shared <- Filter(
    Negate(is.null),
    list(timeout = timeout, format = format)
  )

  result <- lapply(chunks, function(urls) {
    obj <- c(
      list(pages = lapply(unname(urls), function(u) list(url = u))),
      shared
    )
    class(obj) <- c("kagi_query_extract", "list")
    obj
  })

  names(result) <- paste0("query_", seq_along(result))

  result
}

#' @export
print.kagi_query_extract <- function(x, ...) {
  cat("<kagi_query_extract>\n")
  urls <- vapply(x$pages, function(p) p$url, character(1))
  cat("  pages (", length(urls), "):\n", sep = "")
  for (u in utils::head(urls, 5)) {
    cat("    - ", u, "\n", sep = "")
  }
  if (length(urls) > 5) {
    cat("    ... (", length(urls) - 5, " more)\n", sep = "")
  }
  for (nm in setdiff(names(x), "pages")) {
    cat("  ", nm, ": ", x[[nm]], "\n", sep = "")
  }
  invisible(x)
}
