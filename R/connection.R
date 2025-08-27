#' Create a new Kagi API connection
#'
#' @param base_url Base URL for the Kagi API
#' @param endpoint API endpoint to use (e.g., "search", "summarizes" or "enrich"). Default: NA
#' @param api_key Kagi API key
#'
#' @return A kagi_connection object
#' @importFrom httr2 request req_url_path_append req_headers req_user_agent req_retry req_error
#' @export
new_kagi_connection <- function(
  base_url = "https://kagi.com/api/v0",
  endpoint = as.character(NA),
  api_key = Sys.getenv("KAGI_API_KEY"),
  max_tries = 3
) {
  stopifnot(is.character(base_url), length(base_url) == 1L, nzchar(base_url))
  stopifnot(is.character(endpoint), length(endpoint) == 1L, nzchar(endpoint))
  # if (!nzchar(api_key)) {
  #   stop("Missing API key. Set KAGI_API_KEY or pass api_key.", call. = FALSE)
  # }

  structure(
    list(
      base_url = base_url,
      endpoint = as.character(NA),
      api_key = api_key,
      max_tries = max_tries
    ),
    class = "kagi_connection"
  )
}

#' @export
print.kagi_connection <- function(x, ...) {
  key <- x$api_key
  masked <- if (is.character(key)) {
    paste0(
      substr(key, 1, 4),
      strrep("•", max(0, nchar(key) - 8)),
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
    "  endpoint: ",
    x$endpoint,
    "\n",
    "  api_key:  ",
    masked,
    "\n",
    sep = ""
  )
  invisible(x)
}

# internal: build a configured httr2 request
kagi_req_build <- function(conn) {
  stopifnot(inherits(conn, "kagi_connection"))

  api_key <- resolve_api_key(conn$api_key)

  request(conn$base_url) |>
    httr2::req_url_path_append(conn$endpoint) |>
    httr2::req_headers(Authorization = paste("Bot", api_key)) |>
    httr2::req_user_agent(rkagi_user_agent()) |>
    httr2::req_retry(max_tries = conn$max_tries) |>
    httr2::req_error(is_error = ~ .x$status_code >= 400)
}
