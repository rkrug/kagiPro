#' Extract Downloaded Content to Markdown
#'
#' @param project_folder Root project folder containing endpoint subfolders.
#' @param endpoint Optional endpoint selector (for example `"search"` or
#'   `"enrich_news"`). If `NULL`, all supported endpoints are considered.
#' @param query_name Optional query selector. If `NULL`, all query partitions
#'   are considered.
#' @param text_root Root folder name used for extracted text outputs.
#' @param output_format Output format. Only `"markdown"` is supported.
#' @param workers Number of parallel workers to use for extraction.
#' @param verbose Logical indicating whether progress messages should be shown.
#' @param progress Logical indicating whether a progress bar should be shown.
#'
#' @return A data frame with extraction status and diagnostics columns:
#'   `endpoint`, `id`, `query`, `text_path`, `status`, `error`.
#' @export
content_markdown <- function(
  project_folder,
  endpoint = NULL,
  query_name = NULL,
  text_root = "markdown",
  output_format = "markdown",
  workers = 4,
  verbose = FALSE,
  progress = interactive()
) {
  if (!is.character(project_folder) || length(project_folder) != 1L || !nzchar(project_folder)) {
    stop("`project_folder` must be a single non-empty character string.", call. = FALSE)
  }
  validate_optional_scalar(endpoint, "endpoint")
  validate_optional_scalar(query_name, "query_name")

  if (!is.character(text_root) || length(text_root) != 1L || !nzchar(text_root)) {
    stop("`text_root` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.character(output_format) || length(output_format) != 1L || !nzchar(output_format)) {
    stop("`output_format` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.numeric(workers) || length(workers) != 1L || is.na(workers) || workers < 1) {
    stop("`workers` must be a single numeric value >= 1.", call. = FALSE)
  }
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress)) {
    stop("`progress` must be TRUE or FALSE.", call. = FALSE)
  }
  workers <- as.integer(workers)
  if (!identical(output_format, "markdown")) {
    stop("Only `output_format = \"markdown\"` is currently supported.", call. = FALSE)
  }
  if (!requireNamespace("ragnar", quietly = TRUE)) {
    stop(
      "Package `ragnar` is required for markdown extraction. Install it first.",
      call. = FALSE
    )
  }

  if (!dir.exists(project_folder)) {
    stop("`project_folder` does not exist: ", project_folder, call. = FALSE)
  }
  normalize_markdown_output_local <- function(x) {
    if (is.null(x) || length(x) == 0L) {
      return(NA_character_)
    }
    x <- as.character(x)
    if (!nzchar(trimws(x))) NA_character_ else x
  }

  project_folder <- normalizePath(project_folder)

  download_index <- download_content(
    project_folder = project_folder,
    endpoint = endpoint,
    query_name = query_name,
    workers = workers,
    progress = progress,
    verbose = verbose
  )

  if (nrow(download_index) == 0L) {
    return(invisible(data.frame(
      endpoint = character(),
      id = character(),
      query = character(),
      text_path = character(),
      status = character(),
      error = character(),
      stringsAsFactors = FALSE
    )))
  }

  extract_one <- function(i) {
    rec <- download_index[i, , drop = FALSE]
    ep <- as.character(rec$endpoint[[1]])
    id <- as.character(rec$id[[1]])
    q <- as.character(rec$query[[1]])
    path_i <- as.character(rec$path[[1]])
    status_i <- as.character(rec$status[[1]])
    text_root_dir <- file.path(project_folder, ep, text_root)
    dir.create(text_root_dir, recursive = TRUE, showWarnings = FALSE)
    tdir <- file.path(text_root_dir, paste0("query=", q))
    dir.create(tdir, recursive = TRUE, showWarnings = FALSE)
    tpath <- file.path(tdir, paste0(id, ".md"))

    if (status_i != "downloaded" || !file.exists(path_i)) {
      return(data.frame(
        endpoint = ep,
        id = id,
        query = q,
        text_path = tpath,
        status = "extract_failed",
        error = "download missing or failed",
        stringsAsFactors = FALSE
      ))
    }

    if (verbose) {
      message("Extracting markdown ", i, "/", nrow(download_index), ": ", basename(path_i))
    }

    text_i <- tryCatch(
      {
        normalize_markdown_output_local(ragnar::read_as_markdown(path_i))
      },
      error = function(e) {
        structure(NA_character_, error_message = conditionMessage(e))
      }
    )

    err <- attr(text_i, "error_message", exact = TRUE)
    if (is.null(text_i) || length(text_i) == 0L || is.na(text_i) || !nzchar(trimws(text_i))) {
      return(data.frame(
        endpoint = ep,
        id = id,
        query = q,
        text_path = tpath,
        status = "extract_failed",
        error = err %||% "empty extracted text",
        stringsAsFactors = FALSE
      ))
    }

    writeLines(text_i, con = tpath, useBytes = TRUE)
    data.frame(
      endpoint = ep,
      id = id,
      query = q,
      text_path = tpath,
      status = "ok",
      error = NA_character_,
      stringsAsFactors = FALSE
    )
  }

  n_items <- nrow(download_index)
  pb <- NULL
  if (isTRUE(progress) && n_items > 0L) {
    pb <- utils::txtProgressBar(min = 0, max = n_items, style = 3)
    on.exit(close(pb), add = TRUE)
  }

  if (workers <= 1L || n_items <= 1L) {
    out <- lapply(seq_len(n_items), function(i) {
      one <- extract_one(i)
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
          "Could not start parallel extraction with `workers = ", workers,
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
            expr = extract_one(i),
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
        one <- extract_one(i)
        if (!is.null(pb)) {
          utils::setTxtProgressBar(pb, i)
        }
        one
      })
    }
  }

  invisible(do.call(rbind, out))
}
