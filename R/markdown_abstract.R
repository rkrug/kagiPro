#' Summarize Markdown into Query-Level Abstract Parquet
#'
#' Read markdown files generated for a specific endpoint/query and summarize
#' each record with either OpenAI or Kagi text summarization. The result is
#' written as a single parquet file per query under `abstract/`.
#'
#' @param project_folder Root project folder containing endpoint subfolders.
#' @param endpoint Optional endpoint selector (for example `"search"` or
#'   `"enrich_news"`). If `NULL`, all supported endpoints are considered.
#' @param query_name Optional query selector. If `NULL`, all query partitions
#'   are considered.
#' @param workers Number of parallel workers to use for summarization.
#' @param progress Logical indicating whether progress messages should be shown.
#' @param verbose Logical indicating whether detailed messages should be shown.
#' @param summarizer_fn Function with signature
#'   `fn(text, model, ...) -> character(1) | NA_character_`.
#' @param model Provider-specific model/engine.
#' @param connection Optional [kagi_connection()] object. Used for
#'   [summarize_with_kagi()] when not supplied via `provider_args`.
#' @param provider_args Optional named list forwarded to `summarizer_fn`.
#' @param markdown_root Root folder name containing markdown files.
#' @param abstract_root Root folder name for abstract parquet outputs.
#'
#' @return Invisibly returns a data frame with columns
#'   `endpoint`, `id`, `query`, `abstract`, `status`, `error`.
#' @export
markdown_abstract <- function(
  project_folder,
  endpoint = NULL,
  query_name = NULL,
  workers = 4,
  progress = interactive(),
  verbose = FALSE,
  summarizer_fn = summarize_with_openai,
  model = "gpt-4.1-mini",
  connection = NULL,
  provider_args = list(),
  markdown_root = "markdown",
  abstract_root = "abstract"
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
  if (!is.list(provider_args)) {
    stop("`provider_args` must be a list.", call. = FALSE)
  }
  if (!is.function(summarizer_fn)) {
    stop("`summarizer_fn` must be a function.", call. = FALSE)
  }
  if (!is.null(connection) && !inherits(connection, "kagi_connection")) {
    stop("`connection` must be NULL or of class `kagi_connection`.", call. = FALSE)
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
      abstract = character(),
      status = character(),
      error = character(),
      stringsAsFactors = FALSE
    )
  }
  if (nrow(jobs) == 0L) {
    return(invisible(empty_result()))
  }

  text_index <- lapply(seq_len(nrow(jobs)), function(i) {
    ep <- jobs$endpoint[[i]]
    q <- jobs$query[[i]]
    parquet_dir <- file.path(project_folder, ep, "parquet")
    if (!dir.exists(parquet_dir)) {
      return(NULL)
    }

    parquet_df <- read_parquet_dataset(parquet_dir)
    if (nrow(parquet_df) == 0L) {
      return(NULL)
    }
    if (!"id" %in% names(parquet_df) || !"query" %in% names(parquet_df)) {
      stop("Parquet data must contain `id` and `query` columns.", call. = FALSE)
    }

    ids <- unique(as.character(parquet_df$id[parquet_df$query %in% q]))
    ids <- ids[!is.na(ids) & nzchar(ids)]
    if (length(ids) == 0L) {
      return(NULL)
    }

    md_dir <- file.path(project_folder, ep, markdown_root, paste0("query=", q))
    if (!dir.exists(md_dir) || length(list.files(md_dir, pattern = "\\.md$", full.names = TRUE)) == 0L) {
      content_markdown(
        project_folder = project_folder,
        endpoint = ep,
        query_name = q,
        workers = workers,
        progress = FALSE,
        verbose = verbose
      )
    }

    md_dir <- file.path(project_folder, ep, markdown_root, paste0("query=", q))
    md_files <- list.files(md_dir, pattern = "\\.md$", full.names = TRUE)
    md_paths <- stats::setNames(
      object = md_files,
      nm = sub("\\.md$", "", basename(md_files))
    )
    matched_paths <- unname(md_paths[ids])
    exists_vec <- !is.na(matched_paths) & file.exists(matched_paths)
    data.frame(
      endpoint = rep(ep, length(ids)),
      id = ids,
      query = rep(q, length(ids)),
      text_path = matched_paths,
      status = ifelse(exists_vec, "ok", "extract_failed"),
      error = ifelse(exists_vec, NA_character_, "markdown missing"),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  })
  text_index <- do.call(rbind, Filter(Negate(is.null), text_index))
  if (is.null(text_index) || nrow(text_index) == 0L) {
    return(invisible(empty_result()))
  }

  if (identical(summarizer_fn, summarize_with_kagi) && is.null(provider_args$connection)) {
    provider_args$connection <- connection
  }

  summarize_rows <- summarize_text_records(
    text_index = text_index[, c("id", "query", "text_path", "status", "error"), drop = FALSE],
    summarizer_fn = summarizer_fn,
    model = model,
    provider_args = provider_args,
    workers = workers,
    progress = progress,
    verbose = verbose
  )

  summarize_rows$endpoint <- text_index$endpoint
  summarize_rows$query <- text_index$query
  summarize_rows <- summarize_rows[, c("endpoint", "id", "query", "Abstract", "status", "error"), drop = FALSE]
  names(summarize_rows)[names(summarize_rows) == "Abstract"] <- "abstract"

  split_keys <- unique(summarize_rows[, c("endpoint", "query"), drop = FALSE])
  for (i in seq_len(nrow(split_keys))) {
    ep <- split_keys$endpoint[[i]]
    q <- split_keys$query[[i]]
    chunk <- summarize_rows[summarize_rows$endpoint %in% ep & summarize_rows$query %in% q, , drop = FALSE]
    out_dir <- file.path(project_folder, ep, abstract_root, paste0("query=", q))
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    old_files <- list.files(out_dir, pattern = "\\.parquet$", full.names = TRUE)
    if (length(old_files) > 0L) {
      unlink(old_files, force = TRUE)
    }
    source_query_dir <- file.path(project_folder, ep, "parquet", paste0("query=", q))
    source_files <- if (dir.exists(source_query_dir)) {
      sort(list.files(source_query_dir, pattern = "\\.parquet$", full.names = TRUE))
    } else {
      character()
    }
    target_basename <- if (length(source_files) >= 1L) {
      basename(source_files[[1]])
    } else {
      paste0(digest::digest(chunk, algo = "xxhash64"), ".parquet")
    }
    out_file <- file.path(out_dir, target_basename)
    write_single_parquet_file(
      df = chunk[, c("id", "query", "abstract", "status", "error"), drop = FALSE],
      out_file = out_file,
      overwrite = TRUE
    )

    if (isTRUE(progress)) {
      message("Wrote abstract parquet: ", out_file)
    }
  }

  invisible(summarize_rows)
}

#' @keywords internal
write_single_parquet_file <- function(df, out_file, overwrite = TRUE) {
  if (file.exists(out_file)) {
    if (!isTRUE(overwrite)) {
      stop("Output file exists and `overwrite = FALSE`: ", out_file, call. = FALSE)
    }
    unlink(out_file, force = TRUE)
  }

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  DBI::dbWriteTable(con, "tmp_df", df, overwrite = TRUE)
  DBI::dbExecute(
    con,
    sprintf(
      "COPY tmp_df TO '%s' (FORMAT PARQUET)",
      gsub("'", "''", normalizePath(out_file, winslash = "/", mustWork = FALSE))
    )
  )
  invisible(normalizePath(out_file))
}

#' Summarize Text via OpenAI Chat Completions
#'
#' @param text Plain text to summarize.
#' @param model OpenAI model name.
#' @param api_key OpenAI API key. Defaults to `API_openai`.
#' @param base_url OpenAI API base URL.
#' @param system_prompt Prompt used to guide summarization behavior.
#'
#' @return A single summary string (or `NA_character_`).
#' @export
summarize_with_openai <- function(
  text,
  model = "gpt-4.1-mini",
  api_key = Sys.getenv("API_openai", ""),
  base_url = "https://api.openai.com/v1",
  system_prompt = "Summarize the input text in 4 to 6 concise sentences for scientific/literature review workflows.",
  retry_max_tries = 5
) {
  if (is.null(text) || !nzchar(trimws(as.character(text)))) {
    return(NA_character_)
  }
  if (!nzchar(api_key)) {
    stop("Missing OpenAI API key (`API_openai`).", call. = FALSE)
  }

  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("chat", "completions") |>
    httr2::req_headers(
      Authorization = paste("Bearer", api_key),
      "Content-Type" = "application/json"
    ) |>
    httr2::req_body_json(
      list(
        model = model,
        messages = list(
          list(role = "system", content = system_prompt),
          list(role = "user", content = as.character(text))
        )
      ),
      auto_unbox = TRUE
    ) |>
    httr2::req_retry(max_tries = retry_max_tries)

  resp <- httr2::req_perform(req)
  payload <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  out <- payload$choices[[1]]$message$content %||% NA_character_
  out <- as.character(out)[[1]]
  if (!nzchar(trimws(out))) NA_character_ else out
}

#' Summarize Text via Kagi Summarize Endpoint
#'
#' @param text Plain text to summarize.
#' @param model Kagi summarize engine (`"cecil"`, `"agnes"`, `"muriel"`,
#'   `"daphne"`).
#' @param connection Optional [kagi_connection()] object.
#' @param api_key Optional Kagi API key override.
#' @param base_url Optional Kagi API base URL override.
#' @param summary_type Summarize mode (`"summary"` or `"takeaway"`).
#' @param target_language Target language code.
#' @param cache Cache flag forwarded to Kagi summarize endpoint.
#'
#' @return A single summary string (or `NA_character_`).
#' @export
summarize_with_kagi <- function(
  text,
  model = "cecil",
  connection = NULL,
  api_key = NULL,
  base_url = NULL,
  summary_type = "summary",
  target_language = "EN",
  cache = TRUE,
  retry_max_tries = 5
) {
  if (is.null(text) || !nzchar(trimws(as.character(text)))) {
    return(NA_character_)
  }

  if (!is.null(connection) && !inherits(connection, "kagi_connection")) {
    stop("`connection` must be NULL or of class `kagi_connection`.", call. = FALSE)
  }

  if (is.null(base_url)) {
    base_url <- if (!is.null(connection)) connection$base_url else "https://kagi.com/api/v0"
  }
  key <- if (!is.null(connection)) connection$api_key else api_key
  key <- resolve_api_key(key)

  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("summarize") |>
    httr2::req_headers(Authorization = paste0("Bot ", key)) |>
    httr2::req_url_query(
      text = as.character(text),
      engine = model,
      summary_type = summary_type,
      target_language = target_language,
      cache = if (isTRUE(cache)) "true" else "false"
    ) |>
    httr2::req_retry(max_tries = retry_max_tries)

  resp <- httr2::req_perform(req)
  payload <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  out <- payload$data$output %||% NA_character_
  out <- as.character(out)[[1]]
  if (!nzchar(trimws(out))) NA_character_ else out
}
