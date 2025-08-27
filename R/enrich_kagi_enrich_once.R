#' Perform a Kagi enrichment in one call
#'
#' This is a high-level convenience wrapper around
#' [new_kagi_connection()], [new_kagi_enrich()], and [kagi_perform()].
#' It constructs a connection, prepares an enrichment request, and performs
#' it in a single step.
#'
#' @param q Character scalar. The enrichment query string. This can include
#'   search operators such as `filetype:pdf`, `site:example.com`,
#'   boolean logic (`AND`, `OR`), quoted phrases, etc.
#' @param limit Optional integer. Maximum number of enrichment results to request.
#'   If `NULL`, the API will return its own default number of hits.
#' @param api_key API key to use for authentication. By default this is
#'   read from the `KAGI_API_KEY` environment variable. For best practice,
#'   set `Sys.setenv(KAGI_API_KEY="...")` or add it to your `~/.Renviron`.
#'   Advanced users can also pass a function that resolves the key lazily
#'   (see [new_kagi_connection()]).
#' @param base_url Base URL for the Kagi API. Defaults to
#'   `"https://kagi.com/api/v0"`. Override only if you are testing against
#'   a mock server or a future API version.
#' @param path Optional file path. If supplied, the raw JSON response will
#'   be written to this path for reproducibility or debugging.
#'
#' @return An object of class **`kagi_enrich_results`**. Key components include:
#'   \describe{
#'     \item{`data`}{A tibble of enrichment hits.}
#'     \item{`kagi_meta()`}{List of response metadata (latency, node, API balance).}
#'   }
#'
#' @seealso
#'   [new_kagi_connection()],
#'   [new_kagi_enrich()],
#'   [kagi_perform.kagi_enrich()],
#'   [kagi_meta()]
#'
#' @examples
#' \dontrun{
#' # Simple one-liner
#' res <- kagi_enrich_once("open data", limit = 3)
#' enrich_extract(res)
#'
#' # With a complex query
#' q <- build_kagi_q(query = "biodiversity",
#'                   filetype = c("pdf", "docx"),
#'                   site = c("example.com", "gov"))
#' res <- kagi_enrich_once(q, limit = 5)
#' enrich_extract(res)
#' }
#'
#' @md
#' @export
kagi_enrich_once <- function(
  q,
  limit,
  api_key = Sys.getenv("KAGI_API_KEY"),
  base_url = "https://kagi.com/api/v0",
  path = NULL
) {
  conn <- new_kagi_connection(
    base_url = base_url,
    endpoint = "enrich",
    api_key = api_key
  )
  s <- new_kagi_enrich(
    conn,
    q = q,
    limit = limit
  )
  kagi_perform(s, path = path)
}
