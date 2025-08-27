#' Extract search hits from Kagi search results
#'
#' @param x A kagi_search_results object
#' @param ... Additional parameters (not used)
#'
#' @return A tibble of search hits
#' @importFrom tibble tibble
#' @export
kagi_hits <- function(x, ...) {
  UseMethod("kagi_hits")
}

#' @rdname kagi_hits
#' @export
kagi_hits.kagi_search_results <- function(x, ...) {
  rows <- Filter(function(el) is.list(el) && identical(el$t, 0L), x$data)
  if (!length(rows)) {
    return(
      tibble::tibble(
        url = character(),
        title = character(),
        snippet = character(),
        published = character(),
        thumbnail_url = character(),
        t = integer()
      )
    )
  }
  # map to columns safely
  url <- vapply(rows, function(el) el$url %||% NA_character_, character(1))
  title <- vapply(rows, function(el) el$title %||% NA_character_, character(1))
  snippet <- vapply(
    rows,
    function(el) el$snippet %||% NA_character_,
    character(1)
  )
  published <- vapply(
    rows,
    function(el) el$published %||% NA_character_,
    character(1)
  )
  thumbnail_url <- vapply(
    rows,
    function(el) (el$thumbnail$url %||% NA_character_),
    character(1)
  )
  t_val <- vapply(rows, function(el) as.integer(el$t %||% 0L), integer(1))
  tibble(
    url,
    title,
    snippet,
    published,
    thumbnail_url,
    t = t_val
  )
}

#' Extract related searches from Kagi results
#'
#' @param x A kagi_results object
#' @param ... Additional parameters passed to methods
#'
#' @return A data structure containing the related items (type depends on method)
#' @export
kagi_related <- function(x, ...) {
  UseMethod("kagi_related")
}

#' @rdname kagi_related
#' @export
kagi_related.kagi_search_results <- function(x, ...) {
  rel <- Filter(function(el) is.list(el) && identical(el$t, 1L), x$data)
  if (!length(rel)) {
    return(character())
  }
  unique(unlist(
    lapply(rel, function(el) el$list %||% character()),
    use.names = FALSE
  ))
}

#' Extract metadata from Kagi results
#'
#' @param x A kagi_results object
#' @param ... Additional parameters passed to methods
#'
#' @return A list of metadata
#' @export
kagi_meta <- function(x, ...) {
  UseMethod("kagi_meta")
}

#' @rdname kagi_meta
#' @export
kagi_meta.kagi_search_results <- function(x, ...) {
  x$meta
}

#' Convert Kagi results to a tibble
#'
#' @param x A kagi_results object
#' @param ... Additional parameters passed to methods
#'
#' @return A tibble representation of the results
#' @export
as_tibble.kagi_results <- function(x, ...) {
  UseMethod("as_tibble.kagi_results")
}

#' @rdname as_tibble.kagi_results
#' @export
as_tibble.kagi_search_results <- function(x, ...) {
  kagi_hits(x)
}
