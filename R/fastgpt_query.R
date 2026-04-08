#' Create a FastGPT query payload
#'
#' Construct one or more FastGPT query payloads for `POST /fastgpt`.
#' Use [kagi_request()] to execute the request and obtain JSON responses.
#'
#' @param query Character vector. Query text to answer.
#' @param cache Logical. Whether cached responses are allowed. Default: `TRUE`.
#' @param web_search Logical. Whether to use web search enrichment. Default: `TRUE`.
#'
#' @return A named list of query objects of class `kagi_fastgpt_query` to be
#'   used in [kagi_request()].
#'
#' @details
#' According to current Kagi FastGPT API behavior, `web_search = FALSE` is out
#' of service and rejected. This constructor enforces `web_search = TRUE`.
#'
#' @examples
#' \dontrun{
#' fastgpt_query("Python 3.11")
#' fastgpt_query(c("Python 3.11", "What is biodiversity?"))
#' }
#'
#' @md
#' @export
fastgpt_query <- function(
  query,
  cache = TRUE,
  web_search = TRUE
) {
  stopifnot(is.character(query), length(query) >= 1L)
  query <- trimws(query)
  query <- query[nzchar(query)]
  if (length(query) == 0L) {
    stop("`query` must contain at least one non-empty string.", call. = FALSE)
  }

  stopifnot(is.logical(cache), !any(is.na(cache)))
  stopifnot(is.logical(web_search), !any(is.na(web_search)))
  if (any(!web_search)) {
    stop(
      "`web_search = FALSE` is currently not supported by Kagi FastGPT API.",
      call. = FALSE
    )
  }

  args <- expand.grid(
    query = query,
    cache = cache,
    web_search = web_search,
    stringsAsFactors = FALSE
  )

  result <- lapply(
    seq_len(nrow(args)),
    function(i) {
      res <- as.list(args[i, , drop = TRUE])
      class(res) <- c("kagi_fastgpt_query", class(res))
      res
    }
  )

  names(result) <- paste0("query_", seq_along(result))

  return(result)
}

#' @export
print.kagi_fastgpt_query <- function(x, ...) {
  cat("<kagi_fastgpt_query>\n")
  for (nm in names(x)) {
    cat(nm, ': "', x[[nm]], '"\n', sep = "")
  }
  invisible(x)
}
