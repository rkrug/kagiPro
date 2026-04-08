#' Construct a Kagi API connection
#'
#' Build a typed S3 object of class **`kagi_connection`** which holds the
#' basic configuration required to talk to the Kagi API. This includes
#' the API base URL, authentication key, and retry settings.
#'
#' @param base_url Character scalar. Base URL for the Kagi API.
#'   Defaults to `"https://kagi.com/api/v0"`.
#' @param api_key API key used for authentication. By default this is read
#'   from the environment variable `KAGI_API_KEY`. Best practice is to set
#'   this variable in your `~/.Renviron`. Advanced users may also supply
#'   a function that resolves the key lazily at request time
#'   (see [resolve_api_key()]).
#' @param max_tries Integer scalar. Maximum number of retry attempts
#'   for transient errors. Defaults to `3`.
#'
#' @return An object of class **`kagi_connection`** with components:
#' \describe{
#'   \item{`base_url`}{Base API URL.}
#'   \item{`api_key`}{API key (or a function to resolve it).}
#'   \item{`max_tries`}{Maximum retry attempts.}
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
  base_url = "https://kagi.com/api/v0",
  api_key = Sys.getenv("KAGI_API_KEY"),
  max_tries = 3
) {
  stopifnot(is.character(base_url), length(base_url) == 1L, nzchar(base_url))
  # if (!nzchar(api_key)) {
  #   stop("Missing API key. Set KAGI_API_KEY or pass api_key.", call. = FALSE)
  # }

  api_key <- resolve_api_key(api_key)

  result <- httr2::request(base_url) |>
    httr2::req_headers(Authorization = paste("Bot", api_key)) |>
    httr2::req_user_agent(rkagi_user_agent()) |>
    httr2::req_retry(max_tries = max_tries) |>
    httr2::req_error(is_error = ~ .x$status_code >= 400)

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
    "  base_url: ",
    x$base_url,
    "\n",
    "  api_key:  ",
    masked,
    "\n",
    sep = ""
  )
  invisible(x)
}
