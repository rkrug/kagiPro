`%||%` <- function(x, y) {
  if (is.null(x) || (is.character(x) && !nzchar(x))) y else x
}

#' Resolve API key from a connection object
#' @keywords internal
resolve_api_key <- function(api_key) {
  if (is.null(api_key)) {
    key <- Sys.getenv("KAGI_API_KEY", "")
  } else if (is.function(api_key)) {
    key <- api_key()
  } else {
    key <- api_key
  }

  if (!nzchar(key)) {
    stop("Missing API key (set KAGI_API_KEY or pass api_key).", call. = FALSE)
  }
  key
}


#' Build a User-Agent string for rkagi
#' @keywords internal
rkagi_user_agent <- function() {
  pkg <- utils::packageDescription("rkagi")
  paste0(pkg$Package, "/", pkg$Version)
}
