#' Materialize a search parquet dataset as an openalexVectorise-shaped corpus
#'
#' Read a Kagi search parquet dataset (written by [kagi_request_parquet()]
#' or [kagi_fetch()]) and project it to the three-column corpus schema
#' (`id`, `title`, `abstract`) consumed by `openalexVectorise::embed_corpus()`.
#' The output is a Hive-partitioned Arrow dataset under
#' `<project_dir>/<corpus_name>/`.
#'
#' @param input Path to a search parquet dataset. Either an `endpoint_dir`
#'   produced by [kagi_fetch()] (e.g. `<project_folder>/search`, which contains
#'   a `parquet/` sub-folder), the `parquet/` sub-folder itself, or a partition
#'   path like `<...>/parquet/query=<name>`.
#' @param project_dir openalexVectorise project root. The corpus is written
#'   into `<project_dir>/<corpus_name>/`.
#' @param corpus_name Folder name under `project_dir` (default `"corpus"`,
#'   matching openalexVectorise's default).
#' @param types Character vector of search result types to include
#'   (default `"search"`). Set to multiple types (e.g. `c("search", "news")`)
#'   to include several. Set to `NULL` to include all types present.
#' @param abstract_from Field to use as the `abstract` column. Default
#'   `"snippet"` (the searchResult.snippet field).
#' @param id_prefix Optional character. If non-NULL, the parquet rowwise `id`
#'   is prefixed with this string (useful when stacking multiple corpora
#'   in one project). Default `NULL` (use the existing `id` column unchanged).
#' @param overwrite Logical. If `TRUE`, an existing corpus dataset is deleted
#'   before writing. Default `FALSE`.
#'
#' @return Invisibly, the normalized corpus path.
#'
#' @details
#' Rows with empty `title` AND empty `abstract` are dropped, since
#' openalexVectorise's preprocessor would discard them anyway. The output
#' schema is exactly `id` (character), `title` (character), `abstract`
#' (character) — the minimum contract for
#' `openalexVectorise::embed_corpus()`. Any additional columns from the
#' source parquet are not propagated.
#'
#' @seealso
#'   [kagi_query_search()], [kagi_fetch()], [kagi_request_parquet()]
#'
#' @examples
#' \dontrun{
#' conn <- kagi_connection()
#' q <- kagi_query_search("biodiversity loss", workflow = "search", limit = 50)
#' parquet_path <- kagi_fetch(conn, q, project_folder = "kagi_demo")
#'
#' as_corpus_parquet(
#'   input = parquet_path,
#'   project_dir = "/tmp/oavec_demo"
#' )
#' # → /tmp/oavec_demo/corpus/  is now ready for openalexVectorise::embed_corpus()
#' }
#'
#' @md
#' @importFrom arrow open_dataset write_dataset
#' @export
as_corpus_parquet <- function(
  input,
  project_dir,
  corpus_name = "corpus",
  types = "search",
  abstract_from = "snippet",
  id_prefix = NULL,
  overwrite = FALSE
) {
  if (!is.character(input) || length(input) != 1L || !nzchar(input)) {
    stop("`input` must be a single non-empty path.", call. = FALSE)
  }
  if (
    !is.character(project_dir) ||
      length(project_dir) != 1L ||
      !nzchar(project_dir)
  ) {
    stop("`project_dir` must be a single non-empty path.", call. = FALSE)
  }
  if (
    !is.character(corpus_name) ||
      length(corpus_name) != 1L ||
      !nzchar(corpus_name)
  ) {
    stop("`corpus_name` must be a single non-empty string.", call. = FALSE)
  }
  if (
    !is.character(abstract_from) ||
      length(abstract_from) != 1L ||
      !nzchar(abstract_from)
  ) {
    stop(
      "`abstract_from` must be a single non-empty column name.",
      call. = FALSE
    )
  }
  if (!is.null(id_prefix)) {
    stopifnot(is.character(id_prefix), length(id_prefix) == 1L)
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.null(types) && (!is.character(types) || length(types) == 0L)) {
    stop("`types` must be a non-empty character vector or NULL.", call. = FALSE)
  }

  # Resolve `input` to a parquet dataset root --------------------------------
  if (!dir.exists(input)) {
    stop("`input` does not exist: ", input, call. = FALSE)
  }
  dataset_root <- input
  # If user passed an endpoint dir (with a `parquet/` child), descend.
  if (dir.exists(file.path(input, "parquet"))) {
    dataset_root <- file.path(input, "parquet")
  }

  ds <- tryCatch(
    arrow::open_dataset(dataset_root, format = "parquet"),
    error = function(e) {
      stop(
        "Could not open parquet dataset at `",
        dataset_root,
        "`: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )

  cols <- names(ds)
  needed <- c("id", "title")
  missing <- setdiff(needed, cols)
  if (length(missing) > 0L) {
    stop(
      "Input parquet is missing required columns: ",
      paste(missing, collapse = ", "),
      ". Expected a search dataset with columns `id`, `title`, and `",
      abstract_from,
      "`.",
      call. = FALSE
    )
  }
  if (!abstract_from %in% cols) {
    stop(
      "Input parquet has no column `",
      abstract_from,
      "`. Available columns: ",
      paste(cols, collapse = ", "),
      call. = FALSE
    )
  }

  result <- ds
  if (!is.null(types) && "type" %in% cols) {
    result <- dplyr::filter(result, .data$type %in% !!types)
  }

  result <- dplyr::mutate(
    result,
    id = if (is.null(id_prefix)) {
      as.character(.data$id)
    } else {
      paste0(!!id_prefix, "_", as.character(.data$id))
    },
    title = as.character(.data$title),
    abstract = as.character(.data[[abstract_from]])
  )
  result <- dplyr::select(result, .data$id, .data$title, .data$abstract)
  result <- dplyr::filter(
    result,
    !(is.na(.data$title) | .data$title == "") |
      !(is.na(.data$abstract) | .data$abstract == "")
  )

  # Write the corpus ---------------------------------------------------------
  dir.create(project_dir, recursive = TRUE, showWarnings = FALSE)
  project_dir <- normalizePath(project_dir)
  corpus_path <- file.path(project_dir, corpus_name)
  if (dir.exists(corpus_path)) {
    if (!isTRUE(overwrite)) {
      stop(
        "Corpus already exists at `",
        corpus_path,
        "`. Set `overwrite = TRUE` to replace it.",
        call. = FALSE
      )
    }
    unlink(corpus_path, recursive = TRUE, force = TRUE)
  }
  dir.create(corpus_path, recursive = TRUE, showWarnings = FALSE)

  arrow::write_dataset(
    result,
    path = corpus_path,
    format = "parquet"
  )

  invisible(normalizePath(corpus_path))
}
