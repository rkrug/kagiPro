#' Create a new Kagi enrich request
#'
#' @param conn A kagi_connection object
#' @param q enrich query
#' @param limit Maximum number of results to return
#'
#' @return A kagi_enrich object
#' @export
new_kagi_enrich <- function(
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

  conn$endpoint <- "enrich/web"

  structure(
    list(
      conn = conn,
      q = q,
      limit = limit
    ),
    class = "kagi_enrich"
  )
}

#' @export
print.kagi_enrich <- function(x, ...) {
  cat(
    "<kagi_enrich>\n",
    "  endpoint: /",
    x$conn$endpoint,
    "\n",
    "  q:        ",
    x$q,
    "\n",
    sep = ""
  )
  invisible(x)
}
