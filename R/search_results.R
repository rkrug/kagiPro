#' Create a new Kagi search results object
#'
#' @param search A kagi_search object
#' @param raw The raw JSON response from the API
#'
#' @return A kagi_search_results object
#' @export
new_kagi_search_results <- function(search, raw_json, parsed) {
  stopifnot(inherits(search, "kagi_search"))
  # parsed is the parsed list with $meta and $data

  data <- jsonlite::fromJSON(raw_json, simplifyDataFrame = TRUE)$data |>
    tibble::as_tibble()
  if ("url" %in% names(data)) {
    data <- data[!data$url |> is.na(), ]
  } else {
    data <- NULL
  }

  structure(
    list(
      search = search,
      json = raw_json %||% "",
      meta = parsed$meta %||% list(),
      data = data
    ),
    class = "kagi_search_results"
  )
}

#' @export
print.kagi_search_results <- function(x, ...) {
  n_hits <- nrow(x$data)
  n_related <- sum(vapply(
    x$data,
    function(el) is.list(el) && identical(el$t, 1L),
    logical(1)
  ))
  cat(
    "<kagi_search_results>\n",
    "  q:         ",
    x$search$q,
    "\n",
    "  hits:      ",
    n_hits,
    "\n",
    "  related:   ",
    n_related,
    "\n",
    "  ms:        ",
    x$meta$ms %||% NA,
    "\n",
    "  api_balance:",
    x$meta$api_balance %||% NA,
    "\n",
    sep = ""
  )
  invisible(x)
}
