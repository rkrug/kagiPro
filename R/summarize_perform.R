#' Kagi Universal Summarizer: perform method
#'
#' Executes a prepared summarize_request using the shared kagi_connection.
#' If `text` was provided the request is POSTed as JSON; otherwise it is sent
#' as a GET with query parameters (for URL summarization).
#'
#' @param x A `summarize_request`.
#' @param path Optional file path to save the raw JSON response.
#' @export
kagi_perform.kagi_summarize <- function(x, path = NULL, ...) {
  stopifnot(inherits(x, "kagi_summarize"))

  x$conn$api_key <- resolve_api_key(x$conn$api_key)

  if (!nzchar(x$conn$api_key)) {
    stop(
      "Missing API key. Set KAGI_API_KEY or pass it into new_kagi_connection().",
      call. = FALSE
    )
  }

  if (!is.null(path) && (!is.character(path) || length(path) != 1L)) {
    stop(
      "`path` must be either `NULL` or a character vector of length 1!",
      call. = FALSE
    )
  }

  if (!xor(is.null(x$text), is.null(x$url))) {
    stop(
      "Either 'text' or 'url' must be provided - not both or none.",
      call. = FALSE
    )
  }

  # Build request ----------------------------------------------------------

  req <- x$conn |>
    kagi_req_build() |>
    httr2::req_headers(
      "Content-Type" = "application/json"
    ) |>
    httr2::req_body_json(
      compact_list(
        list(
          url = x$url,
          text = x$text,
          engine = x$engine,
          summary_type = x$summary_type,
          target_language = x$target_language,
          cache = x$cache
        )
      )
    )

  # Perform request --------------------------------------------------------

  resp <- httr2::req_perform(req)

  # Extract results --------------------------------------------------------

  raw_json <- httr2::resp_body_string(resp)
  parsed <- jsonlite::fromJSON(raw_json, simplifyVector = FALSE)

  # Save to file if requested ----------------------------------------------

  if (!is.null(path)) {
    i <- 1
    dir.create(
      path,
      showWarnings = FALSE,
      recursive = TRUE
    )
    fn <- paste0("kagi_summarize_results.", sprintf("%03d", i), ".json")
    writeLines(json_txt, file.path(path, fn), useBytes = TRUE)
  }

  new_kagi_summarize_results(x, raw_json, parsed)
}

# #' @export
# summarize_perform.default <- function(x, ...) {
#   stop("No summarize_perform() method for class: ", paste(class(x), collapse = "/"), call. = FALSE)
# }
