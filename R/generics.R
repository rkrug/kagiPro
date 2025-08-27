#' Execute a Kagi API request
#'
#' Dispatches to endpoint-specific methods based on the class of `x`.
#' See the method documentation for details on request shape and returned
#' result classes.
#'
#' @param x The request object to execute
#' @param path Optional path to a directory where the raw JSON should be saved
#' @param ... Additional parameters passed to methods
#'
#' @return A results object corresponding to the request type
#' @importFrom httr2 req_perform req_url_query resp_body_string
#' @export
#' @rdname kagi_perform
kagi_perform <- function(x, path, ...) UseMethod("kagi_perform")
