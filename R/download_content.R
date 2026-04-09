#' Download Endpoint Content for Abstract Generation
#'
#' @param project_folder Root project folder containing endpoint subfolders.
#' @param endpoint Optional endpoint selector (for example `"search"` or
#'   `"enrich_news"`). If `NULL`, all supported endpoints are considered.
#' @param query_name Optional query selector. If `NULL`, all query partitions
#'   are considered.
#' @param workers Number of parallel workers to use for downloads.
#' @param progress Logical indicating whether a progress bar should be shown.
#' @param verbose Logical indicating whether progress messages should be shown.
#'
#' @return A data frame with download status and paths.
#' @export
download_content <- function(
  project_folder,
  endpoint = NULL,
  query_name = NULL,
  workers = 4,
  progress = interactive(),
  verbose = FALSE
) {
  if (!is.character(project_folder) || length(project_folder) != 1L || !nzchar(project_folder)) {
    stop("`project_folder` must be a single non-empty character string.", call. = FALSE)
  }
  validate_optional_scalar(endpoint, "endpoint")
  validate_optional_scalar(query_name, "query_name")
  if (!is.numeric(workers) || length(workers) != 1L || is.na(workers) || workers < 1) {
    stop("`workers` must be a single numeric value >= 1.", call. = FALSE)
  }
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress)) {
    stop("`progress` must be TRUE or FALSE.", call. = FALSE)
  }
  workers <- as.integer(workers)

  if (!dir.exists(project_folder)) {
    stop("`project_folder` does not exist: ", project_folder, call. = FALSE)
  }
  project_folder <- normalizePath(project_folder)
  jobs <- resolve_endpoint_query_jobs(
    project_folder = project_folder,
    endpoint = endpoint,
    query_name = query_name
  )

  empty_result <- function() {
    data.frame(
      endpoint = character(),
      id = character(),
      query = character(),
      url = character(),
      path = character(),
      content_type = character(),
      status = character(),
      error = character(),
      stringsAsFactors = FALSE
    )
  }
  if (nrow(jobs) == 0L) {
    return(invisible(empty_result()))
  }

  rows <- lapply(seq_len(nrow(jobs)), function(i) {
    ep <- jobs$endpoint[[i]]
    q <- jobs$query[[i]]
    input_parquet <- file.path(project_folder, ep, "parquet")
    if (!dir.exists(input_parquet)) {
      return(NULL)
    }
    df <- read_parquet_dataset(input_parquet)
    if (nrow(df) == 0L) {
      return(NULL)
    }
    if (!"id" %in% names(df) || !"url" %in% names(df) || !"query" %in% names(df)) {
      stop("Input parquet must contain `id`, `query`, and `url` columns.", call. = FALSE)
    }
    df <- df[df$query %in% q, c("id", "query", "url"), drop = FALSE]
    if (nrow(df) == 0L) {
      return(NULL)
    }
    df$endpoint <- ep
    df <- df[, c("endpoint", "id", "query", "url"), drop = FALSE]
    df
  })
  rows <- do.call(rbind, Filter(Negate(is.null), rows))
  if (is.null(rows) || nrow(rows) == 0L) {
    return(invisible(empty_result()))
  }
  rows <- unique(rows)
  rows <- rows[
    !is.na(rows$id) & nzchar(rows$id) &
      !is.na(rows$url) & nzchar(rows$url) &
      !is.na(rows$query) & nzchar(rows$query) &
      !is.na(rows$endpoint) & nzchar(rows$endpoint),
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0L) {
    return(invisible(empty_result()))
  }

  n_items <- nrow(rows)
  pb <- NULL
  if (isTRUE(progress) && n_items > 0L) {
    pb <- utils::txtProgressBar(min = 0, max = n_items, style = 3)
    on.exit(close(pb), add = TRUE)
  }

  download_one <- function(i) {
    guess_url_extension_local <- function(url) {
      if (is.null(url) || length(url) == 0L || is.na(url) || !nzchar(url)) {
        return(".bin")
      }
      u <- sub("[#?].*$", "", as.character(url))
      ext <- tools::file_ext(u)
      if (!nzchar(ext)) {
        ".bin"
      } else {
        paste0(".", tolower(ext))
      }
    }

    rec <- rows[i, , drop = FALSE]
    ep <- as.character(rec$endpoint[[1]])
    q <- as.character(rec$query[[1]])
    id <- as.character(rec$id[[1]])
    url <- as.character(rec$url[[1]])
    ext <- guess_url_extension_local(url)

    content_root <- file.path(project_folder, ep, "content")
    dir.create(content_root, recursive = TRUE, showWarnings = FALSE)
    dir_i <- file.path(content_root, paste0("query=", q))
    dir.create(dir_i, recursive = TRUE, showWarnings = FALSE)
    path_i <- file.path(dir_i, paste0(id, ext))

    if (verbose) {
      message("Downloading ", i, "/", nrow(rows), ": ", url)
    }

    one <- tryCatch(
      {
        req <- httr2::request(url) |>
          httr2::req_user_agent(kagiPro_user_agent()) |>
          httr2::req_timeout(30)
        resp <- httr2::req_perform(req)
        raw <- httr2::resp_body_raw(resp)
        writeBin(raw, path_i, useBytes = TRUE)
        list(
          endpoint = ep,
          id = id,
          query = q,
          url = url,
          path = path_i,
          content_type = as.character(resp$headers[["content-type"]] %||% ""),
          status = "downloaded",
          error = NA_character_
        )
      },
      error = function(e) {
        list(
          endpoint = ep,
          id = id,
          query = q,
          url = url,
          path = path_i,
          content_type = NA_character_,
          status = "download_failed",
          error = conditionMessage(e)
        )
      }
    )
    as.data.frame(one, stringsAsFactors = FALSE)
  }

  if (workers <= 1L || n_items <= 1L) {
    out <- lapply(seq_len(n_items), function(i) {
      one <- download_one(i)
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
          "Could not start parallel downloads with `workers = ", workers,
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
            expr = download_one(i),
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
        one <- download_one(i)
        if (!is.null(pb)) {
          utils::setTxtProgressBar(pb, i)
        }
        one
      })
    }
  }

  invisible(do.call(rbind, out))
}
