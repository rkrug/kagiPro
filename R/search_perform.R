#' @describeIn kagi_perform Execute a Search request
#' @method kagi_perform kagi_search
#' @export
kagi_perform.kagi_search <- function(x, path = NULL, ...) {
  stopifnot(inherits(x, "kagi_search"))

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

  # Build request ----------------------------------------------------------

  req <- x$conn |>
    kagi_req_build() |>
    req_url_query(
      q = x$q,
      limit = x$limit
    )

  # Perform request --------------------------------------------------------

  resp <- req_perform(req)

  # Extract results --------------------------------------------------------

  # Raw JSON text
  json_txt <- resp_body_string(resp)

  # Parsed JSON (list)
  json_lst <- jsonlite::fromJSON(json_txt, simplifyVector = FALSE)

  # Save to file if requested ----------------------------------------------

  if (!is.null(path)) {
    i <- 1
    dir.create(
      path,
      showWarnings = FALSE,
      recursive = TRUE
    )
    fn <- paste0("kagi_search_results.", sprintf("%03d", i), ".json")
    writeLines(json_txt, file.path(path, fn), useBytes = TRUE)
  }

  new_kagi_search_results(x, raw_json = json_txt, parsed = json_lst)
}
