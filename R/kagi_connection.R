#' Construct a Kagi API connection
#'
#' Build a typed S3 object of class **`kagi_connection`** which holds the
#' basic configuration required to talk to the Kagi API. This includes
#' the API base URL, authentication key, and retry settings.
#'
#' The connection targets the Kagi API (`v1`, the only supported version).
#' Authentication uses the standard HTTP `Bearer` scheme.
#'
#' @param base_url Character scalar. Base URL for the Kagi API. If `NULL`
#'   (default), the canonical base URL for `api_version` is used
#'   (e.g. `https://kagi.com/api/v1`).
#' @param api_key API key used for authentication. By default this is read
#'   from the environment variable `KAGI_API_KEY`. Best practice is to set
#'   this variable in your `~/.Renviron`. Advanced users may also supply
#'   a function that resolves the key lazily at request time
#'   (see [resolve_api_key()]).
#' @param max_tries Integer scalar. Maximum number of retry attempts
#'   for transient errors. Defaults to `3`.
#' @param api_version Character scalar. Currently only `"v1"` is supported.
#'   Retained as an argument for forward compatibility.
#'
#' @return An object of class **`kagi_connection`** with components:
#' \describe{
#'   \item{`base_url`}{Base API URL.}
#'   \item{`api_key`}{API key (or a function to resolve it).}
#'   \item{`max_tries`}{Maximum retry attempts.}
#'   \item{`api_version`}{`"v1"`.}
#' }
#'
#'
#' @seealso
#'   [resolve_api_key()],
#'
#' @examples
#' \dontrun{
#' # Basic connection (API key from env var)
#' conn <- kagi_connection()
#' conn
#'
#' # Explicit API key
#' conn2 <- kagi_connection(api_key = "my-key")
#'
#' # Lazy API key via keyring
#' conn3 <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))
#' }
#'
#' @md
#' @importFrom httr2 request req_url_path_append req_headers req_user_agent req_retry req_error
#' @export
kagi_connection <- function(
  base_url = NULL,
  api_key = Sys.getenv("KAGI_API_KEY"),
  max_tries = 3,
  api_version = "v1"
) {
  api_version <- match.arg(api_version, choices = "v1")

  if (is.null(base_url)) {
    base_url <- "https://kagi.com/api/v1"
  }
  stopifnot(is.character(base_url), length(base_url) == 1L, nzchar(base_url))

  api_key <- resolve_api_key(api_key)

  auth_header <- paste("Bearer", api_key)

  result <- httr2::request(base_url) |>
    httr2::req_headers(Authorization = auth_header) |>
    httr2::req_user_agent(kagiPro_user_agent()) |>
    httr2::req_retry(
      max_tries = max_tries,
      backoff = function(attempt) min(2 ^ attempt, 10),
      is_transient = function(resp) {
        if (is.null(resp)) {
          return(FALSE)
        }
        httr2::resp_status(resp) %in% c(408L, 429L, 500L, 502L, 503L, 504L)
      }
    ) |>
    httr2::req_error(is_error = ~ .x$status_code >= 400)

  result$api_version <- api_version

  class(result) <- c("kagi_connection", class(result))

  return(result)
}

#' @export
print.kagi_connection <- function(x, ...) {
  key <- x$api_key
  masked <- if (is.character(key)) {
    paste0(
      substr(key, 1, 4),
      strrep("<e2><80><a2>", max(0, nchar(key) - 8)),
      substr(key, nchar(key) - 3, nchar(key))
    )
  } else {
    paste(deparse(key), collapse = "\n")
  }
  cat(
    "<kagi_connection>\n",
    "  api_version: ",
    x$api_version,
    "\n",
    "  base_url: ",
    x$base_url %||% x$url %||% "",
    "\n",
    "  api_key:  ",
    masked,
    "\n",
    sep = ""
  )
  invisible(x)
}
