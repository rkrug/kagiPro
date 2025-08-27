#' Create a new Kagi search request
#'
#' @param conn A kagi_connection object
#' @param q Search query
#' @param limit Maximum number of results to return
#'
#' @return A kagi_search object
#' @export
new_kagi_search <- function(
  conn,
  q,
  limit = NULL
) {
  stopifnot(inherits(conn, "kagi_connection"))
  if (!is.character(q) || length(q) != 1L || !nzchar(q)) {
    stop("q must be a non-empty string.", call. = FALSE)
  }

  if (!is.null(limit)) {
    if (!is.numeric(limit) || length(limit) != 1L || limit <= 0) {
      stop("limit must be a positive number or NULL.", call. = FALSE)
    }
    limit <- as.integer(limit)
  }

  conn$endpoint <- "search"

  structure(
    list(
      conn = conn,
      q = q,
      limit = limit
    ),
    class = "kagi_search"
  )
}

#' @export
print.kagi_search <- function(x, ...) {
  cat(
    "<kagi_search>\n",
    "  endpoint: /",
    x$conn$endpoint,
    "\n",
    "  q:        ",
    x$q,
    "\n",
    "  limit:    ",
    x$limit %||% "<default>",
    "\n",
    sep = ""
  )
  invisible(x)
}
