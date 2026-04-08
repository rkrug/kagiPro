#' Create a new Kagi summarize request
#'
#' Construct a typed S3 object of class `kagi_summarize` that describes a
#' Universal Summarizer request. Use [kagi_request()] to execute the request
#' and obtain the json replies.
#'
#' @param url Optional character scalar. URL to be summarized. Mutually exclusive
#'   with `text`.
#' @param text Optional character scalar. Raw text to be summarized. Mutually
#'   exclusive with `url`.
#' @param engine Character scalar. Summarizer engine (options: `"cecil"`,
#'   `"agnes"`, `"muriel"`, `"daphne"`). Default: `"cecil"`.
#' @param summary_type Character scalar. Type of summary requested (options:
#'   `"summary"`, `"takeaway"`). Default: `"summary"`.
#' @param target_language Character scalar. Target language ISO code. Supported
#'   codes: `"EN"`, `"BG"`, `"CS"`, `"DA"`, `"DE"`, `"EL"`, `"ES"`, `"ET"`,
#'   `"FI"`, `"FR"`, `"HU"`, `"ID"`, `"IT"`, `"JA"`, `"KO"`, `"LT"`, `"LV"`,
#'   `"NB"`, `"NL"`, `"PL"`, `"PT"`, `"RO"`, `"RU"`, `"SK"`, `"SL"`, `"SV"`,
#'   `"TR"`, `"UK"`, `"ZH"`, `"ZH-HANT"`. Default: `"EN"`.
#' @param cache Logical. Whether to allow API-side caching.
#'
#' @return A `kagi_summarize_query` object to be passed to [kagi_request()].
#'
#' @examples
#' \dontrun{
#' req <- summarize_query(text = "Lorem ipsum")
#' req
#' }
#'
#' @md

# -------- constructors -------------------------------------------------------

#' @export
summarize_query <- function(
  url = NULL,
  text = NULL,
  engine = NULL,
  summary_type = NULL,
  target_language = NULL,
  cache = TRUE # TRUE/FALSE
) {
  # Varify arguments for validity ------------------------------------------

  if (xor(is.null(url), is.null(text)) == FALSE) {
    stop("Provide exactly one of `url` or `text`.", call. = FALSE)
  }
  if (!is.null(url)) {
    stopifnot(is.character(url), length(url) == 1L, nzchar(url))
  }
  if (!is.null(text)) {
    stopifnot(is.character(text), length(text) == 1L, nzchar(text))
  }

  engine_choices <- c("cecil", "agnes", "muriel", "daphne")
  summary_type_choices <- c("summary", "takeaway")
  target_language_choices <- c(
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
  )

  if (!is.null(engine)) {
    engine <- match.arg(
      arg = engine,
      choices = engine_choices,
      several.ok = TRUE
    )
  }

  if (!is.null(summary_type)) {
    summary_type <- match.arg(
      arg = summary_type,
      choices = summary_type_choices,
      several.ok = TRUE
    )
  }

  if (!is.null(target_language)) {
    target_language <- match.arg(
      arg = target_language,
      choices = target_language_choices,
      several.ok = TRUE
    )
  }

  if (!is.null(cache)) {
    if (cache) {
      cache <- "true"
    } else {
      cache <- "false"
    }
  }

  # Try expansion ----------------------------------------------------------
  args <- as.list(environment())[names(formals())]
  args <- Filter(Negate(is.null), args)
  args <- expand.grid(args, stringsAsFactors = FALSE)

  for (i in 1:ncol(args)) {
    if (is.list(args[[i]])) {
      args <- args[rep(seq_len(nrow(args)), lengths(args[[i]])), ]
      args[[i]] <- unlist(args[[i]])
    }
  }

  # Generate object --------------------------------------------------------

  result <- lapply(
    seq_len(nrow(args)),
    function(i) {
      res <- setNames(as.character(args[i, , drop = TRUE]), names(args))
      class(res) <- c("kagi_summarize_query", class(res))
      return(res)
    }
  )

  if (nrow(args) == 1) {
    result <- result[[1]]
  }

  return(result)
}

#' @export
print.kagi_summarize_query <- function(x, ...) {
  cat(
    "<kagi_summarize_query>\n"
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
