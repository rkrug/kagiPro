#' Execute Kagi API requests and save JSON responses
#'
#' Execute one or more `kagiPro` query objects against the Kagi API and write
#' raw JSON responses to disk. Supports [kagi_query_search()] and [kagi_query_extract()].
#'
#' If `query` is a list of query objects, requests are executed in parallel
#' (using `workers`) and each query is written into a named subdirectory under
#' `output`.
#'
#' @param connection A [kagi_connection()] object.
#' @param query A query object of class `kagi_query_search`,
#'   `kagi_query_extract`, or a list of such objects.
#' @param limit Optional integer limit used for search requests.
#' @param pages Integer between 1 and 10. Number of pages to be downloaded
#'   per query. The Kagi `/search` endpoint is body-paginated; each iteration
#'   sets `body$page` to the page index and writes a separate
#'   `search_<page>.json` file. Ignored for `kagi_query_extract` (one shot).
#' @param output Directory where JSON response files are written.
#' @param overwrite Logical. If `TRUE`, existing `output` is deleted before
#'   writing.
#' @param append Logical. If `TRUE`, write into an existing `output` directory
#'   instead of deleting it.
#' @param workers Number of parallel workers to use when `query` is a list.
#' @param verbose Logical indicating whether progress messages should be shown.
#' @param error_mode Error handling mode. `"stop"` (default) throws on request
#'   errors. `"write_dummy"` writes a fallback JSON payload and returns `output`.
#' @param metadata_request_args Optional named list persisted in replay metadata
#'   (`request_args`) for each query. Intended for higher-level orchestrators.
#'
#' @return The normalized path to `output`.
#'
#' @details
#' Files are written as `{endpoint}_{page}.json` (for example `search_1.json`).
#' Pagination for `/search` is body-driven: the caller controls how many pages
#' to fetch via the `pages` argument (1–10), and each iteration sets the
#' `page` field of the request body.
#'
#' Query replay metadata is written alongside JSON outputs:
#' - per query folder: `_query_meta.json`
#'
#' @md
#'
#' @importFrom httr2 req_perform resp_body_json resp_body_string
#' @importFrom utils packageVersion
#' @importFrom future plan multisession sequential
#' @importFrom future.apply future_lapply
#'
#' @export
#'
kagi_request <- function(
  connection,
  query,
  limit = NULL,
  pages = 1,
  output = NULL,
  overwrite = FALSE,
  append = FALSE,
  workers = 1,
  verbose = FALSE,
  error_mode = c("stop", "write_dummy"),
  metadata_request_args = list()
) {
  error_mode <- match.arg(error_mode)
  if (!is.list(metadata_request_args)) {
    stop("`metadata_request_args` must be a list.", call. = FALSE)
  }

  # Helper function -------------------------------------------------------

  output_check <- function(output, overwrite, append, verbose) {
    if (dir.exists(output)) {
      if (!overwrite & !append) {
        stop(
          "Directory ",
          output,
          " exists.\n",
          "Either specify `overwrite = TRUE` , `append = TRUE` or delete it."
        )
      }
      if (!append) {
        if (verbose) {
          message(
            "Deleting and recreating `",
            output,
            "` to avoid inconsistencies."
          )
        }
      } else {
        if (verbose) {
          message(
            "Appending to existing files in `",
            output,
            "`."
          )
        }
        return(output)
      }
      unlink(output, recursive = TRUE)
    }
  }

  perform_request <- function(req, endpoint) {
    tryCatch(
      list(success = TRUE, resp = httr2::req_perform(req)),
      error = function(e) {
        resp <- e$resp %||% e$response %||% NULL
        status <- NULL
        body_txt <- NULL
        body_json <- NULL
        api_code <- NULL
        api_msg <- NULL

        if (!is.null(resp)) {
          status <- tryCatch(resp$status_code, error = function(...) NULL)
          body_txt <- tryCatch(
            httr2::resp_body_string(resp),
            error = function(...) NULL
          )

          if (!is.null(body_txt) && nzchar(body_txt)) {
            body_json <- tryCatch(
              jsonlite::fromJSON(body_txt, simplifyVector = FALSE),
              error = function(...) NULL
            )
            if (
              is.list(body_json) &&
                !is.null(body_json$error) &&
                length(body_json$error) > 0
            ) {
              first_error <- body_json$error[[1]]
              api_code <- first_error$code %||% NULL
              api_msg <- first_error$msg %||% NULL
            }
          }
        }

        details <- c(
          paste0("Kagi request failed for endpoint `", endpoint, "`."),
          paste0("URL: ", req$url),
          if (!is.null(status)) paste0("HTTP status: ", status),
          if (!is.null(api_code) || !is.null(api_msg)) {
            paste0(
              "API error: [",
              if (is.null(api_code)) "?" else api_code,
              "] ",
              if (is.null(api_msg)) "" else api_msg
            )
          },
          if (!is.null(body_txt) && nzchar(body_txt)) {
            paste0("Response body: ", body_txt)
          },
          paste0("Original error: ", conditionMessage(e))
        )

        list(
          success = FALSE,
          endpoint = endpoint,
          url = req$url,
          status = status,
          api_code = api_code,
          api_msg = api_msg,
          body_txt = body_txt,
          body_json = body_json,
          error_message = paste(details, collapse = "\n")
        )
      }
    )
  }

  build_dummy_payload <- function(
    endpoint,
    req_error,
    query_name = NULL,
    page = 1L
  ) {
    meta_src <- req_error$body_json$meta %||% list()
    meta <- list(
      id = if (is.null(req_error$status)) {
        "error_request"
      } else {
        paste0("error_", req_error$status)
      },
      endpoint = endpoint,
      query_name = query_name %||% NA_character_,
      page = page,
      node = meta_src$node %||% NA_character_,
      ms = meta_src$ms %||% NA_real_,
      api_balance = meta_src$api_balance %||% NA_real_
    )

    data <- NULL

    list(
      meta = meta,
      data = data,
      error = list(
        list(
          code = req_error$api_code %||% req_error$status %||% NA_integer_,
          msg = req_error$api_msg %||% req_error$error_message,
          ref = NULL
        )
      )
    )
  }

  # argument check ------------------------------------------------------------

  if (!inherits(connection, "kagi_connection")) {
    stop("`connection` must be of class `kagi_connection`.")
  }

  if (
    !inherits(
      query,
      c(kagi_query_classes(), "list")
    )
  ) {
    stop(
      paste(
        "`query` must be of class `kagi_query_*` or a `list` of",
        "such objects. Recognised classes:",
        paste(kagi_query_classes(), collapse = ", ")
      )
    )
  }

  # Call for each element if query is a list ---------------------------

  if (
    !inherits(
      query,
      kagi_query_classes()
    )
  ) {
    is_query_object <- function(x) {
      inherits(x, kagi_query_classes())
    }

    if (is.null(output)) {
      stop("No `output` output specified!")
    }

    output_check(output, overwrite, append, verbose)

    dir.create(output, recursive = TRUE, showWarnings = FALSE)
    output <- normalizePath(output)
    progress_file <- file.path(output, "00_in.progress")
    file.create(progress_file)
    success <- FALSE
    on.exit(
      {
        if (isTRUE(success)) {
          unlink(progress_file)
        }
      },
      add = TRUE
    )

    apply_one <- function(i) {
      nm <- names(query)[i]
      if (is.null(nm) || !nzchar(nm)) {
        nm <- paste0("query_", i)
      }
      query_i <- query[[i]]
      if (
        !is_query_object(query_i) &&
          is.list(query_i) &&
          length(query_i) == 1L &&
          is_query_object(query_i[[1]])
      ) {
        query_i <- query_i[[1]]
      }
      attr(query_i, "query_name") <- nm
      child_output <- file.path(output, nm)
      kagi_request(
        connection = connection,
        query = query_i,
        limit = limit,
        pages = pages,
        output = child_output,
        overwrite = FALSE,
        append = TRUE,
        verbose = verbose,
        error_mode = error_mode,
        metadata_request_args = metadata_request_args
      )
    }

    if (workers <= 1) {
      result <- lapply(seq_along(query), apply_one)
    } else {
      future::plan(future::multisession, workers = workers)
      on.exit(
        future::plan(future::sequential),
        add = TRUE
      )
      result <- future.apply::future_lapply(
        seq_along(query),
        apply_one,
        future.seed = TRUE
      )
    }
    success <- TRUE
    return(output)
  } else {
    # Argument checks --------------------------------------------------------

    if (is.null(output)) {
      stop("No `output` output specified!")
    }

    output_check(output, overwrite, append, verbose)

    # Preparations -----------------------------------------------------------

    dir.create(output, recursive = TRUE, showWarnings = FALSE)

    output <- normalizePath(output)
    progress_file <- file.path(output, "00_in.progress")
    file.create(progress_file)
    success <- FALSE
    on.exit(
      {
        if (isTRUE(success)) {
          unlink(progress_file)
        }
      },
      add = TRUE
    )

    query_class <- class(query)[[1]]
    endpoint <- endpoint_path_from_query_class(query_class)
    base_body <- unclass_query(query)
    if (identical(query_class, "kagi_query_search") &&
        !is.null(limit) && is.null(base_body$limit)) {
      base_body$limit <- as.integer(limit)
    }

    if (!is.numeric(pages) || length(pages) != 1L || is.na(pages)) {
      stop("`pages` must be a single integer between 1 and 10.", call. = FALSE)
    }
    pages <- as.integer(pages)
    if (pages < 1L || pages > 10L) {
      stop("`pages` must be between 1 and 10.", call. = FALSE)
    }

    build_req <- function(page_n) {
      body <- base_body
      if (identical(query_class, "kagi_query_search")) {
        body$page <- as.integer(page_n)
      }
      connection |>
        httr2::req_url_path_append(endpoint) |>
        httr2::req_headers("Content-Type" = "application/json") |>
        httr2::req_body_json(body) |>
        httr2::req_user_agent(
          paste("kagiPro v", packageVersion("kagiPro"))
        )
    }

    query_name <- attr(query, "query_name", exact = TRUE)
    if (is.null(query_name) || !nzchar(query_name)) {
      query_name <- "query_1"
    }

    endpoint_name <- endpoint_from_query_class(query_class)
    write_query_metadata(
      query_dir = output,
      query_name = query_name,
      endpoint = endpoint_name,
      query_class = query_class,
      query_payload = serialize_query_payload(query, query_class = query_class),
      request_args = utils::modifyList(
        x = list(limit = limit, pages = pages),
        val = metadata_request_args
      )
    )

    # Page loop. Extract has no pagination, so it's always one shot.
    page_limit <- if (identical(query_class, "kagi_query_extract")) 1L else pages
    page <- 1L
    repeat {
      req <- build_req(page)
      if (verbose) {
        message("\nDownloading page ", page)
        message("URL: ", req$url)
      }

      req_result <- perform_request(req, endpoint = endpoint)
      if (!isTRUE(req_result$success)) {
        if (identical(error_mode, "stop")) {
          stop(req_result$error_message, call. = FALSE)
        }

        dummy <- build_dummy_payload(
          endpoint = endpoint,
          req_error = req_result,
          query_name = query_name,
          page = page
        )
        writeLines(
          jsonlite::toJSON(
            dummy,
            auto_unbox = TRUE,
            null = "null",
            na = "null"
          ),
          con = file.path(
            output,
            paste0(gsub("/", "_", endpoint), "_", page, ".json")
          )
        )

        warning(req_result$error_message, call. = FALSE)
        break
      }

      resp <- req_result$resp

      data <- resp |>
        httr2::resp_body_json()

      resp |>
        httr2::resp_body_string() |>
        writeLines(
          con = file.path(
            output,
            paste0(gsub("/", "_", endpoint), "_", page, ".json")
          )
        )

      page <- page + 1L

      if (page > page_limit) {
        break
      }
    }
    ###

    success <- TRUE
    return(output)
  }
}
