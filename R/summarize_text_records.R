#' @keywords internal
summarize_text_records <- function(
  text_index,
  summarizer_fn,
  model,
  provider_args = list(),
  workers = 1,
  progress = FALSE,
  verbose = FALSE
) {
  if (!is.data.frame(text_index) || nrow(text_index) == 0L) {
    return(data.frame(
      id = character(),
      Abstract = character(),
      status = character(),
      error = character(),
      stringsAsFactors = FALSE
    ))
  }

  ids <- as.character(text_index$id)
  if (identical(summarizer_fn, summarize_with_openai) && workers > 1L) {
    workers <- 1L
    if (isTRUE(verbose)) {
      message("OpenAI summarization uses sequential execution to avoid rate-limit bursts.")
    }
  }
  text_paths <- if ("text_path" %in% names(text_index)) {
    as.character(text_index$text_path)
  } else {
    rep(NA_character_, nrow(text_index))
  }
  ok <- text_index$status == "ok" &
    !is.na(text_paths) &
    nzchar(text_paths) &
    file.exists(text_paths)
  out <- vector("list", nrow(text_index))

  summarize_one <- function(i) {
    id <- ids[[i]]
    if (!ok[[i]]) {
      return(data.frame(
        id = id,
        Abstract = NA_character_,
        status = "summarize_skipped",
        error = "no extracted text",
        stringsAsFactors = FALSE
      ))
    }
    txt <- tryCatch(
      paste(readLines(text_paths[[i]], warn = FALSE, encoding = "UTF-8"), collapse = "\n"),
      error = function(e) {
        structure(NA_character_, error_message = conditionMessage(e))
      }
    )
    read_err <- attr(txt, "error_message", exact = TRUE)
    if (is.null(txt) || length(txt) == 0L || is.na(txt) || !nzchar(trimws(txt))) {
      return(data.frame(
        id = id,
        Abstract = NA_character_,
        status = "summarize_skipped",
        error = read_err %||% "no extracted text",
        stringsAsFactors = FALSE
      ))
    }
    one <- tryCatch(
      {
        res <- do.call(
          summarizer_fn,
          c(list(text = txt, model = model), provider_args)
        )
        res <- as.character(res %||% NA_character_)[[1]]
        if (!nzchar(trimws(res))) {
          res <- NA_character_
        }
        data.frame(
          id = id,
          Abstract = res,
          status = if (is.na(res)) "summarize_failed" else "ok",
          error = if (is.na(res)) "empty summary" else NA_character_,
          stringsAsFactors = FALSE
        )
      },
      error = function(e) {
        data.frame(
          id = id,
          Abstract = NA_character_,
          status = "summarize_failed",
          error = conditionMessage(e),
          stringsAsFactors = FALSE
        )
      }
    )
    one
  }

  n_items <- nrow(text_index)
  pb <- NULL
  if (isTRUE(progress) && n_items > 0L) {
    pb <- utils::txtProgressBar(min = 0, max = n_items, style = 3)
    on.exit(close(pb), add = TRUE)
  }

  if (workers <= 1L || n_items <= 1L) {
    out <- lapply(seq_len(n_items), function(i) {
      one <- summarize_one(i)
      if (!is.null(pb)) {
        utils::setTxtProgressBar(pb, i)
      }
      one
    })
  } else {
    plan_ok <- TRUE
    tryCatch(
      {
        future::plan(future::multisession, workers = workers)
      },
      error = function(e) {
        plan_ok <<- FALSE
        warning(
          "Could not start parallel summarization with `workers = ", workers,
          "`. Falling back to sequential execution. Original error: ",
          conditionMessage(e),
          call. = FALSE
        )
      }
    )

    if (isTRUE(plan_ok)) {
      on.exit(future::plan(future::sequential), add = TRUE)
      futures <- lapply(
        seq_len(n_items),
        function(i) {
          future::future(
            expr = summarize_one(i),
            seed = TRUE
          )
        }
      )

      out <- vector("list", n_items)
      done <- rep(FALSE, n_items)
      n_done <- 0L
      while (n_done < n_items) {
        pending <- which(!done)
        progressed <- FALSE
        for (i in pending) {
          if (future::resolved(futures[[i]])) {
            out[[i]] <- future::value(futures[[i]])
            done[[i]] <- TRUE
            n_done <- n_done + 1L
            progressed <- TRUE
            if (!is.null(pb)) {
              utils::setTxtProgressBar(pb, n_done)
            }
          }
        }
        if (!progressed) {
          Sys.sleep(0.05)
        }
      }
    } else {
      out <- lapply(seq_len(n_items), function(i) {
        one <- summarize_one(i)
        if (!is.null(pb)) {
          utils::setTxtProgressBar(pb, i)
        }
        one
      })
    }
  }

  out <- do.call(rbind, out)
  if (verbose) {
    n_ok <- sum(out$status == "ok", na.rm = TRUE)
    message("Summarized ", n_ok, " of ", nrow(out), " record(s).")
  }
  out
}
