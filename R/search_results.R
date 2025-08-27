#' Construct search results object
#'
#' Build a typed S3 object of class **`kagi_search_results`** from a
#' successful Kagi Search API response. The object keeps both the
#' **raw JSON** payload and the parsed content as a tibble for convenient
#' downstream use.
#'
#' @param search A prepared search request of class **`kagi_search`**
#'   (the object you passed to the API).
#' @param raw_json A length-one character string containing the raw JSON
#'   response body returned by the API.
#' @param parsed A parsed list (e.g. from
#'   `jsonlite::fromJSON(..., simplifyVector = FALSE)`)
#'   expected to contain top-level elements `meta` and `data`.
#'
#' @return An object of class **`kagi_search_results`** with components:
#' \describe{
#'   \item{`search`}{The original `kagi_search` request.}
#'   \item{`json`}{Raw JSON string for reproducibility/debugging.}
#'   \item{`meta`}{List with response metadata (e.g., `id`, `ms`, `node`, `api_balance`).}
#'   \item{`data`}{A tibble with search hits (if present). Each row typically
#'   corresponds to a search result with fields such as `url`, `title`,
#'   `snippet`, etc. If no results are available, this is `NULL`.}
#' }
#'
#' @details
#' This is a low-level constructor; most users will obtain a
#' `kagi_search_results` via `kagi_perform()` or `kagi_search_once()`.
#' Results are coerced into a tibble for ease of inspection and
#' data manipulation. Any rows with missing `url` are dropped.
#'
#' @seealso
#'   \code{\link{kagi_perform}},
#'   \code{\link{new_kagi_search}} (request constructor),
#'   \code{\link{kagi_hits}}, \code{\link{kagi_related}}, \code{\link{kagi_meta}}
#'
#' @examples
#' \dontrun{
#' parsed <- list(
#'   meta = list(ms = 200, node = "abc", api_balance = 99),
#'   data = list(list(t = 0, url = "https://example.com", title = "Result 1", snippet = "Example..."))
#' )
#' search <- new_kagi_search(new_kagi_connection(endpoint = "search"), q = "openalex api")
#' raw_json <- jsonlite::toJSON(parsed, auto_unbox = TRUE)
#' res <- new_kagi_search_results(search, raw_json, parsed)
#' res
#' tibble::as_tibble(res$data)
#' }
#'
#' @md
#' @export
new_kagi_search_results <- function(search, raw_json, parsed) {
  stopifnot(inherits(search, "kagi_search"))
  # parsed is the parsed list with $meta and $data

  data <- jsonlite::fromJSON(raw_json, simplifyDataFrame = TRUE)$data |>
    tibble::as_tibble()
  if ("url" %in% names(data)) {
    data <- data[!data$url |> is.na(), ]
  } else {
    data <- NULL
  }

  structure(
    list(
      search = search,
      json = raw_json %||% "",
      meta = parsed$meta %||% list(),
      data = data
    ),
    class = "kagi_search_results"
  )
}

#' @export
print.kagi_search_results <- function(x, ...) {
  n_hits <- nrow(x$data)
  n_related <- sum(vapply(
    x$data,
    function(el) is.list(el) && identical(el$t, 1L),
    logical(1)
  ))
  cat(
    "<kagi_search_results>\n",
    "  q:         ",
    x$search$q,
    "\n",
    "  hits:      ",
    n_hits,
    "\n",
    "  related:   ",
    n_related,
    "\n",
    "  ms:        ",
    x$meta$ms %||% NA,
    "\n",
    "  api_balance:",
    x$meta$api_balance %||% NA,
    "\n",
    sep = ""
  )
  invisible(x)
}
