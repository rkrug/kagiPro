#' Build a Kagi search query string
#'
#' Construct one or more query strings for the Kagi Search API by combining
#' free-text terms with structured operators such as `filetype:`, `site:`,
#' `inurl:`, and `intitle:`. Queries can either be concatenated into a
#' single string or expanded into a Cartesian product of all combinations.
#'
#' @param query Character vector of free-text query terms (required).
#'   These can include quoted phrases and boolean operators.
#' @param filetype Optional character vector of file type extensions
#'   (e.g. `"pdf"`, `"docx"`). Each is prefixed with `filetype:`.
#' @param site Optional character vector of domains
#'   (e.g. `"example.com"`, `"gov"`). Each is prefixed with `site:`.
#' @param inurl Optional character vector of URL substrings that must be
#'   present in the result URL. Each is prefixed with `inurl:`.
#' @param intitle Optional character vector of terms that must appear in
#'   the page title. Each is prefixed with `intitle:`.
#' @param expand Logical, default `TRUE`. If `TRUE`, generate a fully
#'   crossed set of queries (Cartesian product of all combinations of
#'   `query`, `filetype`, `site`, `inurl`, and `intitle`). If `FALSE`,
#'   concatenate the arguments into a single combined query string.
#' @param open_in_browser Logical, default `FALSE`. If `TRUE`, each generated
#'   query is immediately opened in the default web browser via
#'   [open_search_query()] for inspection.
#'
#' @return A named list containing the query strings of type `kagi_search_query`,
#'   to be used in [kagi_request()].
#'
#' @details
#' This helper makes it easy to build reproducible, complex queries with
#' structured operators. Use `expand = TRUE` when you want all possible
#' combinations (useful in systematic search contexts). Use `expand = FALSE`
#' when you want a single combined query.
#'
#' @seealso
#'   [open_search_query()],
#'   [kagi_request()],
#'   [kagi_request_parquet()],
#'
#' @examples
#' \dontrun{
#' # Single combined query
#' search_query(
#'   query = "biodiversity",
#'   filetype = c("pdf", "docx"),
#'   site = "example.com",
#'   expand = FALSE
#' )
#'
#' # Expanded combinations
#' search_query(
#'   query = c("biodiversity", "ecosystem"),
#'   filetype = c("pdf", "docx"),
#'   site = c("example.com", "gov"),
#'   expand = TRUE
#' )
#'
#' # Immediately open in browser
#' search_query("openalex api", site = "docs.openalex.org", open_in_browser = TRUE)
#' }
#'
#' @md
#' @export
search_query <- function(
  query,
  filetype = NULL,
  site = NULL,
  inurl = NULL,
  intitle = NULL,
  expand = TRUE,
  open_in_browser = FALSE
) {
  combine <- function(x, prefix = "") {
    if (is.null(x)) {
      return("")
    }
    x <- as.character(x)
    x <- trimws(x)
    x[nzchar(x)]
    paste0(prefix, x)
  }

  if (expand) {
    query <- expand.grid(
      combine(query),
      combine(filetype, "filetype:"),
      combine(site, "site:"),
      combine(inurl, "inurl:"),
      combine(intitle, "intitle:"),
      stringsAsFactors = FALSE
    ) |>
      apply(
        1,
        paste,
        collapse = " "
      )
  } else {
    query <- paste(
      combine(query),
      combine(filetype, "filetype:"),
      combine(site, "site:"),
      combine(inurl, "inurl:"),
      combine(intitle, "intitle:"),
      sep = " "
    )
  }

  query <- trimws(query)

  query <- as.list(query)
  for (i in seq_along(query)) {
    class(query[[i]]) <- c("kagi_search_query", class(query[[i]]))
  }

  names(query) <- paste0("query_", seq_along(query))

  if (open_in_browser) {
    for (x in query) {
      open_search_query(x)
    }
  }

  return(query)
}

#' @export
print.kagi_search_query <- function(x, ...) {
  cat(
    "<kagi_search_query>\n"
  )
  for (i in 1:length(x)) {
    paste0(
      names(x)[i],
      ": \"",
      x[i],
      "\"\n"
    ) |>
      cat()
  }
  invisible(x)
}
