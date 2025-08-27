#' Perform a Kagi search in one call
#'
#' @param q Search query
#' @param limit Maximum number of results
#' @param api_key Kagi API key
#' @param base_url Base URL for the Kagi API
#'
#' @return A kagi_search_results object
#' @export
kagi_search_once <- function(
  q,
  limit = NULL,
  api_key = Sys.getenv("KAGI_API_KEY"),
  base_url = "https://kagi.com/api/v0"
) {
  conn <- new_kagi_connection(
    base_url = base_url,
    endpoint = "search",
    api_key = api_key
  )
  s <- new_kagi_search(conn, q = q, limit = limit)
  kagi_perform(s)
}
