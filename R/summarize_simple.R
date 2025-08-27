#' Kagi Universal Summarizer: convenience one-liner
#'
#' Runs the Universal Summarizer in one call. Provide exactly one of `url` or `text`.
#'
#' @export
summarize_once <- function(
  url = NULL,
  text = NULL,
  engine = NULL,
  summary_type = NULL,
  target_language = NULL,
  cache = NULL,
  api_key = Sys.getenv("KAGI_API_KEY"),
  base_url = "https://kagi.com/api/v0",
  path = NULL
) {
  conn <- new_kagi_connection(
    base_url = base_url,
    endpoint = "summarize",
    api_key = api_key
  )
  req <- new_summarize_request(
    conn,
    url = url,
    text = text,
    engine = engine,
    summary_type = summary_type,
    target_language = target_language,
    cache = cache
  )
  summarize_perform(req, path = path)
}
