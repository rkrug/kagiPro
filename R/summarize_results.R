#' @export
new_kagi_summarize_results <- function(
  request,
  raw_json,
  parsed
) {
  stopifnot(inherits(request, "kagi_summarize"))
  structure(
    list(
      request = request,
      raw_json = raw_json,
      meta = parsed$meta %||% list(),
      summary = parsed$data$output %||% list(), # expected fields: output, tokens
      tokens = parsed$data$tokens %||% list() # expected fields: output, tokens used
    ),
    class = "kagi_summarize_results"
  )
}


#' @export
print.kagi_summarize_results <- function(x, ...) {
  print(x$request)
  summary <- x$summary %||% ""
  tokens <- x$tokens %||% NA_integer_
  cat("<summarize_results>\n")
  cat("  ms:        ", x$meta$ms %||% NA, "\n", sep = "")
  cat("  tokens:    ", tokens, "\n", sep = "")
  cat("  node:      ", x$meta$node %||% NA, "\n", sep = "")
  cat(
    "  preview:   ",
    paste0(substr(summary, 1, 100), if (nchar(summary) > 100) "…"),
    "\n",
    sep = ""
  )
  invisible(x)
}
