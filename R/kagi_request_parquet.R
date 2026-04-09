#' Convert JSON files to Apache Parquet files
#'
#' Convert a directory of JSON files written by [kagi_request()] into an
#' Apache Parquet dataset. JSON files are processed one-by-one and written as
#' hive-partitioned parquet by `query`.
#'
#' @param input_json Directory containing JSON files from [kagi_request()].
#' @param output output directory for the parquet dataset; default: temporary
#'   directory.
#' @param add_columns List of additional fields to be added to the output. They
#'   have to be provided as a named list, e.g. `list(column_1 = "value_1",
#'   column_2 = 2)`. Only Scalar values are supported.
#' @param overwrite Logical indicating whether to overwrite `output`.
#' @param append Logical indicating whether to append/update query partitions in
#'   an existing `output` directory without deleting untouched queries.
#' @param verbose Logical indicating whether to print progress information.
#'   Defaults to `TRUE`
#' @param delete_input Determines if the `input_json` should be deleted
#'   afterwards. Defaults to `FALSE`.
#'
#' @return Returns `output` invisibly if parquet files were written; otherwise
#'   `NULL`.
#'
#' @details The function uses DuckDB to read the JSON files and to create the
#'   Apache Parquet files. It creates an in-memory DuckDB connection, reads each
#'   JSON response, and writes endpoint-specific tabular data into the parquet
#'   dataset. Files with `data = null` are skipped.
#'
#'   Output parquet rows include an `id` column for traceability:
#'   - Search: `SEARCH_<hash>` from normalized `url` when available.
#'   - Enrich web: `ENRICH_WEB_<hash>` from normalized `url` when available.
#'   - Enrich news: `ENRICH_NEWS_<hash>` from normalized `url` when available.
#'   - Summarize: `SUMMARIZE_<hash>` from request metadata.
#'   - FastGPT: `FASTGPT_<hash>` from request metadata.
#'
#' @importFrom duckdb duckdb
#' @importFrom DBI dbConnect dbDisconnect dbExecute
#'
#' @md
#'
#' @export

kagi_request_parquet <- function(
  input_json = NULL,
  output = NULL,
  add_columns = list(),
  overwrite = FALSE,
  append = FALSE,
  verbose = TRUE,
  delete_input = FALSE
) {
  output_check <- function(output, overwrite, append, verbose) {
    if (dir.exists(output)) {
      if (!overwrite && !append) {
        stop(
          "Directory ",
          output,
          " exists.\n",
          "Either specify `overwrite = TRUE`, `append = TRUE`, or delete it."
        )
      }
      if (append) {
        if (verbose) {
          message("Appending/updating query partitions in `", output, "`.")
        }
        return(invisible(NULL))
      }
      if (verbose) {
        message(
          "Deleting and recreating `",
          output,
          "` to avoid inconsistencies."
        )
      }
      unlink(output, recursive = TRUE)
    }
  }

  # Argument Checks --------------------------------------------------------

  ## Check if input_json is specified
  if (is.null(input_json)) {
    stop("No `input_json` to convert specified!")
  }

  ## Check if output is specified
  if (is.null(output)) {
    stop("No output to convert to specified!")
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

  # Preparations -----------------------------------------------------------

  ## Create and setup in memory DuckDB
  con <- DBI::dbConnect(duckdb::duckdb())

  on.exit(
    try(DBI::dbDisconnect(con, shutdown = TRUE), silent = TRUE),
    add = TRUE
  )
  paste0(
    "INSTALL json; LOAD json; "
  ) |>
    DBI::dbExecute(conn = con)

  ## Read names of json files
  jsons <- list.files(
    input_json,
    pattern = "\\.json$",
    full.names = TRUE,
    recursive = TRUE
  )
  jsons <- jsons[grepl("_[0-9]+\\.json$", basename(jsons))]
  if (length(jsons) == 0L) {
    stop(
      "No endpoint JSON files found in `input_json`. Expected files like `search_1.json`.",
      call. = FALSE
    )
  }

  jsons <- jsons[
    order(
      as.numeric(
        sub(
          ".*_([0-9]+)\\.json$",
          "\\1",
          jsons
        )
      )
    )
  ]

  types <- jsons |>
    basename() |>
    strsplit(split = "_") |>
    vapply(
      FUN = '[[',
      1,
      FUN.VALUE = character(1)
    ) |>
    unique()

  if (length(types) > 1) {
    stop("All JSON files must be of the same type!")
  }

  # if (types == "group") {
  #   types <- "group_by"
  # }

  # if (types == "single") {}

  # Go through all jsons, i.e. one per page --------------------------------

  has_subdirs <- length(list.dirs(input_json)) > 1
  query_names <- if (has_subdirs) {
    unique(basename(dirname(jsons)))
  } else {
    "query_1"
  }

  if (isTRUE(append) && dir.exists(output)) {
    for (qn in query_names) {
      qpart <- file.path(output, paste0("query=", qn))
      if (dir.exists(qpart)) {
        unlink(qpart, recursive = TRUE, force = TRUE)
      }
    }
  }

  ### Names: endpoint_page_x.json
  for (i in seq_along(jsons)) {
    fn <- jsons[i]
    if (verbose) {
      message("Converting ", i, " of ", length(jsons), " : ", fn)
    }

    ## Extract page number into pn
    pn <- basename(fn) |>
      strsplit(split = "_")
    pn <- pn[[1]]

    # pn <- pn[[1]][length(pn[[1]])] |>
    pn <- pn[length(pn)] |>
      gsub(pattern = ".json", replacement = "")

    query_name <- if (has_subdirs) basename(dirname(fn)) else "query_1"

    # Check if data is empty -------------------------------------------------

    data_type <- DBI::dbGetQuery(
      conn = con,
      statement = sprintf(
        "SELECT typeof(data) AS type FROM read_json_auto('%s')",
        fn
      )
    )$type

    type <- basename(fn)
    type <- sub("_[0-9]+\\.json$", "", type)

    data_type_chr <- toupper(as.character(data_type %||% ""))
    if (
      length(data_type_chr) == 0 ||
      is.na(data_type_chr) ||
      grepl("NULL", data_type_chr)
    ) {
      if (verbose) {
        message("   No rows in `data`; skipping.")
      }
      next
    }

    if (!grepl("LIST|STRUCT", data_type_chr)) {
      if (verbose) {
        message(
          "   `data` has unsupported type `",
          data_type_chr,
          "` (likely error/dummy payload); skipping."
        )
      }
      next
    }

    # Extract and convert the data -------------------------------------------

    statement <- switch(
      type,
      "search" = sprintf(
        "
          COPY (
            SELECT
              '%s' AS query,
              page,
              CASE
                WHEN u.url IS NOT NULL AND u.url <> '' THEN
                  concat('SEARCH_', md5(lower(regexp_replace(trim(u.url), '#.*$', ''))))
                ELSE
                  concat('SEARCH_', md5(concat('%s', '::', coalesce(cast(u.t AS VARCHAR), 'na'))))
              END AS id,
              u.*
            FROM (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
            )
          ) TO
            '%s'
          (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'query', APPEND)
        ",
        query_name,
        pn,
        pn,
        fn,
        output
      ),
      "summarize" = sprintf(
        "
          COPY (
            SELECT
              '%s' AS query,
              '%s' AS page,
              concat('SUMMARIZE_', md5(coalesce(cast(res.meta.id AS VARCHAR), '%s'))) AS id,
              UNNEST(res.data) AS u
            FROM read_json_auto('%s') AS res
            WHERE res.data IS NOT NULL
          ) TO
              '%s'
            (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'query', APPEND)
        ",
        query_name,
        pn,
        pn,
        fn,
        output
      ),
      "fastgpt" = sprintf(
        "
          COPY (
            SELECT
              '%s' AS query,
              '%s' AS page,
              concat('FASTGPT_', md5(coalesce(cast(res.meta.id AS VARCHAR), '%s'))) AS id,
              UNNEST(res.data) AS u
            FROM read_json_auto('%s') AS res
            WHERE res.data IS NOT NULL
          ) TO
              '%s'
            (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'query', APPEND)
        ",
        query_name,
        pn,
        pn,
        fn,
        output
      ),
      "enrich_web" = sprintf(
        "
          COPY (
            SELECT
              '%s' AS query,
              page,
              CASE
                WHEN u.url IS NOT NULL AND u.url <> '' THEN
                  concat('ENRICH_WEB_', md5(lower(regexp_replace(trim(u.url), '#.*$', ''))))
                ELSE
                  concat('ENRICH_WEB_', md5(concat('%s', '::', coalesce(cast(u.t AS VARCHAR), 'na'))))
              END AS id,
              u.*
            FROM (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
            )
          ) TO
            '%s'
          (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'query', APPEND)
        ",
        query_name,
        pn,
        pn,
        fn,
        output
      ),
      "enrich_news" = sprintf(
        "
          COPY (
            SELECT
              '%s' AS query,
              page,
              CASE
                WHEN u.url IS NOT NULL AND u.url <> '' THEN
                  concat('ENRICH_NEWS_', md5(lower(regexp_replace(trim(u.url), '#.*$', ''))))
                ELSE
                  concat('ENRICH_NEWS_', md5(concat('%s', '::', coalesce(cast(u.t AS VARCHAR), 'na'))))
              END AS id,
              u.*
            FROM (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
            )
          ) TO
            '%s'
          (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'query', APPEND)
        ",
        query_name,
        pn,
        pn,
        fn,
        output
      ),
      "enrich" = sprintf(
        "
          COPY (
            SELECT
              '%s' AS query,
              page,
              CASE
                WHEN u.url IS NOT NULL AND u.url <> '' THEN
                  concat('ENRICH_', md5(lower(regexp_replace(trim(u.url), '#.*$', ''))))
                ELSE
                  concat('ENRICH_', md5(concat('%s', '::', coalesce(cast(u.t AS VARCHAR), 'na'))))
              END AS id,
              u.*
            FROM (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
            )
          ) TO
            '%s'
          (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'query', APPEND)
        ",
        query_name,
        pn,
        pn,
        fn,
        output
      ),
      stop("Unknown type of JSON files: ", type)
    )

    try(
      {
        ## save as page partitioned parquet
        DBI::dbExecute(conn = con, statement = statement)
        if (verbose) {
          message("   Done")
        }
      },
      silent = !verbose
    )
  }

  if (delete_input) {
    unlink(input_json, recursive = TRUE, force = TRUE)
  }

  if (file.exists(output)) {
    if (verbose) {
      message("Output written to `", output, "`")
    }
  } else {
    if (verbose) {
      message("No output written to `", output, "`")
    }
    output <- NULL
  }

  success <- TRUE
  return(invisible(output))
}
