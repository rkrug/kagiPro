#' Create a new Kagi enrich results object
#'
#' @param enrich A kagi_enrich object
#' @param raw The raw JSON response from the API
#'
#' @return A kagi_enrich_results object
#' @importFrom tibble as_tibble
#' @export
new_kagi_enrich_results <- function(enrich, raw_json, parsed) {
  stopifnot(inherits(enrich, "kagi_enrich"))
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
      enrich = enrich,
      json = raw_json %||% "",
      meta = parsed$meta %||% list(),
      data = data
    ),
    class = "kagi_enrich_results"
  )
}

#' @export
print.kagi_enrich_results <- function(x, ...) {
  n_hits <- nrow(x$data)
  n_related <- sum(vapply(
    x$data,
    function(el) is.list(el) && identical(el$t, 1L),
    logical(1)
  ))
  cat(
    "<kagi_enrich_results>\n",
    "  q:         ",
    x$enrich$q,
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
