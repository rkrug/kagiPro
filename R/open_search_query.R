#' Open a Kagi search in the browser
#'
#' @param query A full query string (typically from [search_query()]).
#' @param session_token Optional Kagi session token for private search
#'   (see your Kagi account's "Session Link").
#' @export
open_search_query <- function(
  query,
  session_token = NULL
) {
  stopifnot(is.character(query), length(query) == 1L, nzchar(query))
  enc <- utils::URLencode(query, reserved = TRUE)

  base <- "https://kagi.com/search"
  url <- if (is.null(session_token) || !nzchar(session_token)) {
    paste0(base, "?q=", enc)
  } else {
    paste0(base, "?token=", session_token, "&q=", enc)
  }

  utils::browseURL(url)
  invisible(url)
}
