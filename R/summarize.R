#' Kagi Universal Summarizer: constructors & generics
#'
#' Defines the summarize_request / summarize_results S3 classes and
#' the public generics for performing a request and extracting fields.
#'
#' This code expects the following helpers to exist in your package:
#' - new_kagi_connection()    (kagi_connection constructor)
#' - kagi_req_build()         (preconfigured httr2 request builder)
#' - `%||%` and compact_list  (utilities)
#'
#' @keywords internal

# -------- constructors -------------------------------------------------------

#' @export
new_kagi_summarize <- function(
  conn,
  url = NULL,
  text = NULL,
  engine = c("cecil", "agnes", "muriel", "daphne"), # 'cecil' (default), 'agnes', 'muriel', 'daphne'(deprecated)
  summary_type = c("summary", "takeaway"), # 'summary'(default), 'takeaway'
  target_language = c(
    "EN",
    "BG",
    "CS",
    "DA",
    "DE",
    "EL",
    "ES",
    "ET",
    "FI",
    "FR",
    "HU",
    "ID",
    "IT",
    "JA",
    "KO",
    "LT",
    "LV",
    "NB",
    "NL",
    "PL",
    "PT",
    "RO",
    "RU",
    "SK",
    "SL",
    "SV",
    "TR",
    "UK",
    "ZH",
    "ZH-HANT"
  ), # see https://kagi.com/docs/api/summarize#languages for the updated list
  cache = TRUE # TRUE/FALSE
) {
  # Varify arguments for validity ------------------------------------------

  stopifnot(inherits(conn, "kagi_connection"))

  if (xor(is.null(url), is.null(text)) == FALSE) {
    stop("Provide exactly one of `url` or `text`.", call. = FALSE)
  }
  if (!is.null(url)) {
    stopifnot(is.character(url), length(url) == 1L, nzchar(url))
  }
  if (!is.null(text)) {
    stopifnot(is.character(text), length(text) == 1L, nzchar(text))
  }

  engine <- match.arg(
    arg = engine,
    choices = c("cecil", "agnes", "muriel", "daphne"),
    several.ok = FALSE
  )

  summary_type <- match.arg(
    arg = summary_type,
    choices = c("summary", "takeaway"),
    several.ok = FALSE
  )

  target_language <- match.arg(
    arg = target_language,
    choices = c(
      "EN",
      "BG",
      "CS",
      "DA",
      "DE",
      "EL",
      "ES",
      "ET",
      "FI",
      "FR",
      "HU",
      "ID",
      "IT",
      "JA",
      "KO",
      "LT",
      "LV",
      "NB",
      "NL",
      "PL",
      "PT",
      "RO",
      "RU",
      "SK",
      "SL",
      "SV",
      "TR",
      "UK",
      "ZH",
      "ZH-HANT"
    ),
    several.ok = FALSE
  )

  conn$endpoint <- "summarize"

  # Generate object --------------------------------------------------------

  structure(
    list(
      conn = conn,
      url = url,
      text = text,
      engine = engine,
      summary_type = summary_type,
      target_language = target_language,
      cache = cache
    ),
    class = "kagi_summarize"
  )
}


#' @export
print.kagi_summarize <- function(x, ...) {
  cat("<summarize_request>\n")
  cat("  Endpoint:  /", x$conn$endpoint, "\n", sep = "")
  cat("  Base URL:  ", x$conn$base_url, "\n", sep = "")
  cat(
    "  With:      ",
    if (!is.null(x$url)) "url" else "text",
    "\n",
    sep = ""
  )
  if (!is.null(x$url)) {
    cat("  URL:       ", x$url, "\n", sep = "")
  }
  if (!is.null(x$text)) {
    cat(
      "  Text:      ",
      paste0(substr(x$text, 1, 60), if (nchar(x$text) > 60) "…"),
      "\n",
      sep = ""
    )
  }
  cat("  Engine:    ", x$engine %||% "<default>", "\n", sep = "")
  cat("  Type:      ", x$summary_type %||% "summary", "\n", sep = "")
  cat("  Language:  ", x$target_language %||% "<auto>", "\n", sep = "")
  cat(
    "  Cache:     ",
    if (is.null(x$cache)) "<default>" else as.character(x$cache),
    "\n",
    sep = ""
  )
  invisible(x)
}
