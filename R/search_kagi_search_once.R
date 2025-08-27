#' Perform a Kagi search in one call
#'
#' This is a high-level convenience wrapper around
#' [`new_kagi_connection()`], [`new_kagi_search()`], and [`kagi_perform()`].
#' It constructs a connection, prepares a search request, and performs
#' it in a single step.
#'
#' @param q Character scalar. The search query string. This can include
#'   search operators such as `filetype:pdf`, `site:example.com`,
#'   boolean logic (`AND`, `OR`), quoted phrases, etc.
#' @param limit Optional integer. Maximum number of results to request.
#'   If `NULL` (default), the API will return its own default number of hits.
#' @param api_key API key to use for authentication. By default this is
#'   read from the `KAGI_API_KEY` environment variable. For best practice,
#'   set `Sys.setenv(KAGI_API_KEY="...")` or add it to your `~/.Renviron`.
#'   Advanced users can also pass a function that resolves the key lazily
#'   (see [`new_kagi_connection()`]).
#' @param base_url Base URL for the Kagi API. Defaults to
#'   `"https://kagi.com/api/v0"`. Override only if you are testing against
#'   a mock server or a future API version.
#' @param path Optional file path. If supplied, the raw JSON response will
#'   be written to this path for reproducibility or debugging.
#'
#' @return An object of class **`kagi_search_results`**. Use helper
#'   functions to extract components:
#'   \describe{
#'     \item{`kagi_hits()`}{Return a tibble of primary search hits.}
#'     \item{`kagi_related()`}{Character vector of related queries.}
#'     \item{`kagi_meta()`}{List of response metadata (latency, node, API balance).}
#'   }
#'
#' @seealso
#'   [new_kagi_connection()],
#'   [new_kagi_search()],
#'   [kagi_perform.kagi_search()],
#'   [kagi_hits()],
#'   [kagi_related()],
#'   [kagi_meta()]
#'
#' @examples
#' \dontrun{
#' # Simple one-liner
#' res <- kagi_search_once("openalex api", limit = 3)
#' kagi_hits(res)
#'
#' # With a complex query
#' q <- build_kagi_q(query = "biodiversity",
#'                   filetype = c("pdf", "docx"),
#'                   site = c("example.com", "gov"))
#' res <- kagi_search_once(q, limit = 5)
#' kagi_hits(res)
#' }
#'
#' @md
#' @export
kagi_search_once <- function(
  q,
  limit = NULL,
  api_key = Sys.getenv("KAGI_API_KEY"),
  base_url = "https://kagi.com/api/v0",
  path = NULL
) {
  conn <- new_kagi_connection(
    base_url = base_url,
    endpoint = "search",
    api_key = api_key
  )
  s <- new_kagi_search(conn, q = q, limit = limit)
  kagi_perform(s, path = path)
}
