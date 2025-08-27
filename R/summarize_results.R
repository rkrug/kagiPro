#' Construct summarize results object
#'
#' Build a typed S3 object of class **`kagi_summarize_results`** from a
#' successful Universal Summarizer response. The object keeps both the
#' **raw JSON** payload (as returned by the API) and the **parsed** fields
#' you will typically use (`meta`, `summary`, `tokens`).
#'
#' @param request A prepared summarize request of class **`kagi_summarize`**
#'   (the object you passed to the API).
#' @param raw_json A length-one character string containing the raw JSON
#'   response body returned by the API.
#' @param parsed A parsed list (e.g. from `jsonlite::fromJSON(..., simplifyVector = FALSE)`)
#'   expected to contain top-level elements `meta` and `data`. From `data`,
#'   the function extracts `output` (as `summary`) and `tokens`.
#'
#' @return An object of class **`kagi_summarize_results`** with components:
#' \describe{
#'   \item{`request`}{The original `kagi_summarize` request.}
#'   \item{`raw_json`}{Raw JSON string for reproducibility/debugging.}
#'   \item{`meta`}{List with response metadata (e.g., `ms`, `node`, `api_balance`).}
#'   \item{`summary`}{Character scalar with the summarizer output text (or `list()` if absent).}
#'   \item{`tokens`}{Integer (or `list()` if absent) with token usage reported by the API.}
#' }
#'
#' @details
#' This is a low-level constructor; most users will obtain a
#' `kagi_summarize_results` via `kagi_perform()` (or your high-level
#' wrapper). The fields use `%||%` to provide safe fallbacks when the API
#' omits optional elements.
#'
#' @seealso
#'   \code{\link{kagi_perform}},
#'   \code{\link{new_kagi_summarize}} (request constructor),
#'
#' @examples
#' \dontrun{
#' parsed <- list(
#'   meta = list(ms = 123, node = "xyz", api_balance = 42),
#'   data = list(output = "Short summary...", tokens = 256L)
#' )
#' req <- new_kagi_summarize(new_kagi_connection(endpoint = "summarize"), text = "Lorem ipsum")
#' res <- new_kagi_summarize_results(req, raw_json = jsonlite::toJSON(parsed), parsed = parsed)
#' res
#' }
#'
#' @md
#' @export
new_kagi_summarize_results <- function(
  request,
  raw_json,
  parsed
) {
  stopifnot(inherits(request, "kagi_summarize"))
  structure(
    list(
      request = request,
      raw_json = raw_json,
      meta = parsed$meta %||% list(),
      summary = parsed$data$output %||% list(), # expected fields: output, tokens
      tokens = parsed$data$tokens %||% list() # expected fields: output, tokens used
    ),
    class = "kagi_summarize_results"
  )
}


#' @export
print.kagi_summarize_results <- function(x, ...) {
  print(x$request)
  summary <- x$summary %||% ""
  tokens <- x$tokens %||% NA_integer_
  cat("<summarize_results>\n")
  cat("  ms:        ", x$meta$ms %||% NA, "\n", sep = "")
  cat("  tokens:    ", tokens, "\n", sep = "")
  cat("  node:      ", x$meta$node %||% NA, "\n", sep = "")
  cat(
    "  preview:   ",
    paste0(substr(summary, 1, 100), if (nchar(summary) > 100) "..."),
    "\n",
    sep = ""
  )
  invisible(x)
}
