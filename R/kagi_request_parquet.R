#' Convert JSON files to Apache Parquet files
#'
#' Convert a directory of JSON files written by [kagi_request()] into an
#' Apache Parquet dataset. JSON files are processed one-by-one and written as
#' partitioned parquet by `page`.
#'
#' @param input_json Directory containing JSON files from [kagi_request()].
#' @param output output directory for the parquet dataset; default: temporary
#'   directory.
#' @param add_columns List of additional fields to be added to the output. They
#'   have to be provided as a named list, e.g. `list(column_1 = "value_1",
#'   column_2 = 2)`. Only Scalar values are supported.
#' @param overwrite Logical indicating whether to overwrite `output`.
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
  verbose = TRUE,
  delete_input = FALSE
) {
  output_check <- function(output, overwrite, verbose) {
    if (dir.exists(output)) {
      if (!overwrite) {
        stop(
          "Directory ",
          output,
          " exists.\n",
          "Either specify `overwrite = TRUE` , `append = TRUE` or delete it."
        )
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

  output_check(output, overwrite, verbose)

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
    pattern = "*.json$",
    full.names = TRUE,
    recursive = TRUE
  )

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

  ### Names: results_page_x.json
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

    if (has_subdirs) {
      pn <- paste0(basename(dirname(fn)), "_", pn)
    } else {
      pn <- pn
    }

    # Check if data is empty -------------------------------------------------

    data_type <- DBI::dbGetQuery(
      conn = con,
      statement = sprintf(
        "SELECT typeof(data) AS type FROM read_json_auto('%s')",
        fn
      )
    )$type

    type <- fn |>
      basename() |>
      strsplit(split = "_")
    type <- type[[1]][1]

    if (length(data_type) == 0 || is.na(data_type) || grepl("NULL", data_type)) {
      if (verbose) {
        message("   No rows in `data`; skipping.")
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
              page,
              u.*
            FROM (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
            )
          ) TO
            '%s'
          (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'page', APPEND)
        ",
        pn,
        fn,
        output
      ),
      "summarize" = sprintf(
        "
          COPY (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
              WHERE res.data IS NOT NULL
          ) TO
              '%s'
            (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'page', APPEND)
        ",
        pn,
        fn,
        output
      ),
      "fastgpt" = sprintf(
        "
          COPY (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
              WHERE res.data IS NOT NULL
          ) TO
              '%s'
            (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'page', APPEND)
        ",
        pn,
        fn,
        output
      ),
      "enrich" = sprintf(
        "
          COPY (
            SELECT
              page,
              u.*
            FROM (
              SELECT
                '%s' AS page,
                UNNEST(res.data) AS u
              FROM read_json_auto('%s') AS res
            )
          ) TO
            '%s'
          (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'page', APPEND)
        ",
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

  return(invisible(output))
}
