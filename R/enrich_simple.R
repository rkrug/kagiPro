#' Perform a Kagi enrich in one call
#'
#' @param q enrich query
#' @param limit Maximum number of results
#' @param api_key Kagi API key
#' @param base_url Base URL for the Kagi API
#'
#' @return A kagi_enrich_results object
#' @export
kagi_enrich_once <- function(
  q,
  api_key = Sys.getenv("KAGI_API_KEY"),
  base_url = "https://kagi.com/api/v0"
) {
  conn <- new_kagi_connection(
    base_url = base_url,
    endpoint = "enrich",
    api_key = api_key
  )
  s <- new_kagi_enrich(conn, q = q)
  kagi_perform(s)
}
