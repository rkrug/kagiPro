#' Read a kagiPro Parquet Corpus
#'
#' Modelled on `openalexPro::read_corpus()` with an additional
#' `abstracts` switch. By default this opens an Arrow dataset from a parquet
#' directory. When `return_data = TRUE`, the result is collected into memory.
#'
#' If `abstracts = TRUE`, abstract data is read from the sibling
#' `abstract` folder and left-joined by `id` + `query`. If no abstract files are
#' present, an `abstract` column filled with `NA` is added.
#'
#' @param project_folder Root project folder.
#' @param endpoint Endpoint folder name under `project_folder`.
#' @param corpus Folder name under `project_folder/endpoint` to read as parquet
#'   corpus. Defaults to `"parquet"`.
#' @param return_data Logical; if `TRUE`, collect and return in-memory data.
#' @param abstracts Logical; if `TRUE`, link sibling abstract data by `id` and
#'   `query`.
#' @param silent Logical; if `TRUE`, suppress informative messages.
#'
#' @return An Arrow dataset/query when `return_data = FALSE`, otherwise a data
#'   frame/tibble.
#' @importFrom rlang .data
#' @export
read_corpus <- function(project_folder, endpoint, corpus = "parquet", return_data = FALSE, abstracts = FALSE, silent = FALSE) {
  if (!is.character(project_folder) || length(project_folder) != 1L || !nzchar(project_folder)) {
    stop("`project_folder` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.character(endpoint) || length(endpoint) != 1L || !nzchar(endpoint)) {
    stop("`endpoint` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.character(corpus) || length(corpus) != 1L || !nzchar(corpus)) {
    stop("`corpus` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.logical(return_data) || length(return_data) != 1L || is.na(return_data)) {
    stop("`return_data` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.logical(abstracts) || length(abstracts) != 1L || is.na(abstracts)) {
    stop("`abstracts` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.logical(silent) || length(silent) != 1L || is.na(silent)) {
    stop("`silent` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!dir.exists(project_folder)) {
    stop("`project_folder` does not exist: ", project_folder, call. = FALSE)
  }

  project_folder <- normalizePath(project_folder)
  endpoint <- tolower(endpoint)
  corpus_path <- file.path(project_folder, endpoint, corpus)
  if (!dir.exists(corpus_path)) {
    stop("Corpus directory does not exist: ", corpus_path, call. = FALSE)
  }

  result <- arrow::open_dataset(corpus_path, format = "parquet")

  if (isTRUE(abstracts)) {
    list_field_names <- {
      fields <- result$schema$fields
      field_names <- vapply(fields, function(f) f$name, character(1))
      types <- vapply(fields, function(f) f$type$ToString(), character(1))
      field_names[grepl("^(list|large_list|fixed_size_list)<", types)]
    }
    if (length(list_field_names) > 0L) {
      if (!isTRUE(silent)) {
        message(
          "Excluding list-typed columns for lazy abstract join: ",
          paste(list_field_names, collapse = ", ")
        )
      }
      result <- dplyr::select(result, -dplyr::all_of(list_field_names))
    }

    base_cols <- names(result)
    if (!all(c("id", "query") %in% base_cols)) {
      stop("`abstracts = TRUE` requires `id` and `query` columns in `corpus`.", call. = FALSE)
    }

    abstract_dir <- file.path(project_folder, endpoint, "abstract")
    abstract_files <- if (dir.exists(abstract_dir)) {
      list.files(abstract_dir, pattern = "\\.parquet$", recursive = TRUE, full.names = TRUE)
    } else {
      character()
    }

    if (length(abstract_files) == 0L) {
      result <- dplyr::mutate(result, abstract = NA_character_)
    } else {
      abstract_ds <- arrow::open_dataset(abstract_dir, format = "parquet")
      abstract_cols <- names(abstract_ds)
      if (!all(c("id", "query") %in% abstract_cols)) {
        stop("Abstract dataset must contain `id` and `query` columns.", call. = FALSE)
      }

      if (!"abstract" %in% abstract_cols) {
        stop("Abstract dataset must contain an `abstract` column.", call. = FALSE)
      }

      abstract_ds <- dplyr::select(
        abstract_ds,
        .data$id,
        .data$query,
        .data$abstract
      )

      result <- dplyr::left_join(result, abstract_ds, by = c("id", "query"))
      result <- dplyr::mutate(
        result,
        abstract = ifelse(
          is.na(.data$abstract),
          NA_character_,
          as.character(.data$abstract)
        )
      )
    }
  }

  if (isTRUE(return_data)) {
    result <- dplyr::collect(result)
  }

  result
}
