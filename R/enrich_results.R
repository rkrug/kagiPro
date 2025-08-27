#' Construct enrich results object
#'
#' Build a typed S3 object of class **`kagi_enrich_results`** from a
#' successful Kagi Enrich API response. The object keeps both the
#' **raw JSON** payload and the parsed content as a tibble for convenient
#' downstream use.
#'
#' @param enrich A prepared enrich request of class **`kagi_enrich`**
#'   (the object you passed to the API).
#' @param raw_json A length-one character string containing the raw JSON
#'   response body returned by the API.
#' @param parsed A parsed list (e.g. from
#'   `jsonlite::fromJSON(..., simplifyVector = FALSE)`)
#'   expected to contain top-level elements `meta` and `data`.
#'
#' @return An object of class **`kagi_enrich_results`** with components:
#' \describe{
#'   \item{`enrich`}{The original `kagi_enrich` request.}
#'   \item{`json`}{Raw JSON string for reproducibility/debugging.}
#'   \item{`meta`}{List with response metadata (e.g., `id`, `ms`, `node`, `api_balance`).}
#'   \item{`data`}{A tibble with enrichment hits (if present). Each row typically
#'   corresponds to an enrichment result with fields such as `url`, `title`,
#'   `snippet`, etc. If no results are available, this is `NULL`.}
#' }
#'
#' @details
#' This is a low-level constructor; most users will obtain a
#' `kagi_enrich_results` via `enrich_perform()` or `kagi_enrich_once()`.
#' Results are coerced into a tibble for ease of inspection and
#' data manipulation. Any rows with missing `url` are dropped.
#'
#' @seealso
#'   \code{\link{kagi_perform}},
#'   \code{\link{new_kagi_enrich}} (request constructor)
#'
#' @examples
#' \dontrun{
#' parsed <- list(
#'   meta = list(ms = 180, node = "def", api_balance = 95),
#'   data = list(
#'              list(
#'                 t = 0,
#'                 url = "https://example.org",
#'                 title = "Enrich result",
#'                 snippet = "Example..."
#'                 )
#'              )
#' )
#' enrich <- new_kagi_enrich(new_kagi_connection(endpoint = "enrich"), q = "open data")
#' raw_json <- jsonlite::toJSON(parsed, auto_unbox = TRUE)
#' res <- new_kagi_enrich_results(enrich, raw_json, parsed)
#' res
#' tibble::as_tibble(res$data)
#' }
#'
#' @md
#' @export
new_kagi_enrich_results <- function(enrich, raw_json, parsed) {
  stopifnot(inherits(enrich, "kagi_enrich"))
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
      enrich = enrich,
      json = raw_json %||% "",
      meta = parsed$meta %||% list(),
      data = data
    ),
    class = "kagi_enrich_results"
  )
}

#' @export
print.kagi_enrich_results <- function(x, ...) {
  n_hits <- nrow(x$data)
  n_related <- sum(vapply(
    x$data,
    function(el) is.list(el) && identical(el$t, 1L),
    logical(1)
  ))
  cat(
    "<kagi_enrich_results>\n",
    "  q:         ",
    x$enrich$q,
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
