#' Build a Kagi search query string
#'
#' @param query   Character scalar with the main search terms (can include quotes/`AND`/`OR`/...).
#' @param filetype Character vector of file extensions, e.g. c("pdf","docx"). Combined with `OR.`
#' @param site     Character vector of domains, e.g. c("example.com","gov"). Combined with `OR.`
#' @param inurl    Character vector of URL substrings to require in the URL. Multiple act like `AND.`
#' @param intitle  Character vector of title terms to require in the page title. Multiple act like `AND.`
#' @param expand  `TRUE` or `FALSE`, whether to expand the query to include all combinations of the parameters.
#'  Default: `TRUE`. If `FALSE`, the normal R recycling rules are used - so use with care!
#' @param open_in_browser `TRUE` or `FALSE`, whether to open the query in the browser. Default: `FALSE`
#' @return A single character string suitable for the `q` parameter.
#' @md
#' @export
build_kagi_query <- function(
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

  if (open_in_browser) {
    for (x in query) {
      open_kagi_query(x)
    }
  }

  return(query)
}
