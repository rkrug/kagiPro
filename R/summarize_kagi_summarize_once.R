#' Perform a Kagi summarization in one call
#'
#' This is a high-level convenience wrapper around
#' [new_kagi_connection()], [new_kagi_summarize()], and [kagi_perform()].
#' It constructs a connection, prepares a summarization request, and performs
#' it in a single step.
#'
#' @param url Optional character scalar. URL to be summarized. Mutually exclusive
#'   with `text`. If both are provided, `text` takes precedence.
#' @param text Optional character scalar. Raw text to be summarized.
#'   Mutually exclusive with `url`.
#' @param engine Optional character scalar. Summarizer engine to use (e.g.
#'   `"muriel"`, `"cecil"`). If `NULL`, the API default is used.
#' @param summary_type Optional character scalar. Type of summary requested
#'   (e.g. `"summary"`, `"takeaway"`). If `NULL`, the API default is used.
#' @param target_language Optional character scalar. Target language for
#'   the summary (ISO code such as `"EN"`, `"FR"`, `"DE"`, etc.).
#'   If `NULL`, the API default is used.
#' @param cache Optional logical. Whether to use cached summarizations on the API side.
#'   If `NULL`, the API default is used.
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
#' @return An object of class **`kagi_summarize_results`**. Key components include:
#'   \describe{
#'     \item{`tokens`}{Token usage information.}
#'     \item{`meta`}{List of response metadata (latency, node, API balance).}
#'   }
#'
#' @seealso
#'   [new_kagi_connection()],
#'   [new_kagi_summarize()],
#'   [kagi_perform()]
#'
#' @examples
#' \dontrun{
#' # Summarize a URL
#' res <- kagi_summarize_once(
#'   url = "https://www.youtube.com/watch?v=ZSRHeXYDLko",
#'   engine = "muriel",
#'   summary_type = "summary",
#'   target_language = "EN"
#' )
#'
#' # Summarize raw text
#' res <- kagi_summarize_once(
#'   text = "Long input text to be summarized...",
#'   engine = "cecil",
#'   summary_type = "takeaway"
#' )
#' }
#'
#' @md
#' @export
kagi_summarize_once <- function(
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
  req <- new_kagi_summarize(
    conn,
    url = url,
    text = text,
    engine = engine,
    summary_type = summary_type,
    target_language = target_language,
    cache = cache
  )
  kagi_perform(req, path = path)
}
