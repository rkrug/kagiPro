#' Known search result types in the `/search` response `data` object.
#' @noRd
#' @keywords internal
KAGI_SEARCH_TYPES <- c(
  "search", "image", "video", "podcast", "podcast_creator", "news",
  "adjacent_question", "direct_answer", "interesting_news",
  "interesting_finds", "infobox", "code", "package_tracking",
  "public_records", "weather", "related_search", "listicle", "web_archive"
)

#' Write a search response JSON page into a Hive-partitioned parquet
#' dataset. Each non-empty result type becomes one `type=<type>/` partition.
#' @noRd
#' @keywords internal
write_search_parquet <- function(con, fn, query_name, pn, output, verbose) {
  any_written <- FALSE
  present_types <- tryCatch(
    {
      payload <- jsonlite::fromJSON(fn, simplifyVector = FALSE)
      intersect(KAGI_SEARCH_TYPES, names(payload$data %||% list()))
    },
    error = function(e) KAGI_SEARCH_TYPES
  )
  for (type_key in present_types) {
    stmt <- sprintf(
      "
      COPY (
        SELECT
          '%s' AS query,
          '%s' AS page,
          '%s' AS type,
          CASE
            WHEN u.url IS NOT NULL AND u.url <> '' THEN
              concat('SEARCH_', md5(lower(regexp_replace(trim(u.url), '#.*$', ''))))
            ELSE
              concat('SEARCH_', md5(concat('%s', '::', '%s', '::', coalesce(cast(u.title AS VARCHAR), 'na'))))
          END AS id,
          u.*
        FROM (
          SELECT UNNEST(data.%s) AS u
          FROM read_json_auto('%s') AS res
          WHERE data.%s IS NOT NULL
        )
      ) TO '%s'
      (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY ('query', 'type'), APPEND)
      ",
      query_name, pn, type_key,
      type_key, query_name,
      type_key, fn, type_key,
      output
    )
    ok <- tryCatch(
      {
        DBI::dbExecute(conn = con, statement = stmt)
        TRUE
      },
      error = function(e) {
        # Most likely cause: this JSON file's inferred STRUCT for `data` has
        # no `<type_key>` field — that type simply wasn't returned for this
        # query/page. Silently skip.
        if (verbose) {
          message("   search type `", type_key, "` skipped: ", conditionMessage(e))
        }
        FALSE
      }
    )
    if (isTRUE(ok)) any_written <- TRUE
  }
  if (verbose && isTRUE(any_written)) {
    message("   Done (search)")
  }
  invisible(any_written)
}

#' Write an extract response JSON page into a Hive-partitioned parquet
#' dataset. Each input URL becomes one row with `url` + `markdown`.
#' @noRd
#' @keywords internal
write_extract_parquet <- function(con, fn, query_name, pn, output, verbose) {
  stmt <- sprintf(
    "
    COPY (
      SELECT
        '%s' AS query,
        '%s' AS page,
        CASE
          WHEN u.url IS NOT NULL AND u.url <> '' THEN
            concat('EXTRACT_', md5(lower(trim(u.url))))
          ELSE
            concat('EXTRACT_', md5(concat('%s', '::', '%s')))
        END AS id,
        u.*
      FROM (
        SELECT UNNEST(res.data) AS u
        FROM read_json_auto('%s') AS res
      )
    ) TO '%s'
    (FORMAT PARQUET, COMPRESSION SNAPPY, PARTITION_BY 'query', APPEND)
    ",
    query_name, pn,
    query_name, pn,
    fn,
    output
  )
  ok <- tryCatch(
    {
      DBI::dbExecute(conn = con, statement = stmt)
      TRUE
    },
    error = function(e) {
      if (verbose) {
        message("   extract skipped: ", conditionMessage(e))
      }
      FALSE
    }
  )
  if (verbose && isTRUE(ok)) {
    message("   Done (extract)")
  }
  invisible(ok)
}

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
#' @param combine Logical, default `FALSE`. If `TRUE`, all per-query/per-type
#'   parquet partitions are combined into a single file
#'   `<output>/combined.parquet` (rows from different result types are
#'   union-merged by column name, with `NULL` filling absent columns), and
#'   the Hive-partitioned dirs are removed.
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
#'   - Search: `SEARCH_<hash>` from normalized `url`; one parquet partition
#'     per non-empty result type (`type=search`, `type=image`, ...).
#'   - Extract: `EXTRACT_<hash>` from normalized `url`; one row per
#'     extracted page.
#'
#'   Dispatch is metadata-driven: the sibling `_query_meta.json` (written by
#'   [kagi_request()]) records the `query_class` and selects the correct
#'   writer.
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
  delete_input = FALSE,
  combine = FALSE
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

    pn <- pn[length(pn)] |>
      gsub(pattern = ".json", replacement = "")

    query_name <- if (has_subdirs) basename(dirname(fn)) else "query_1"

    # Resolve query class from sibling _query_meta.json ---------------------
    meta_path <- file.path(dirname(fn), "_query_meta.json")
    query_class <- NULL
    if (file.exists(meta_path)) {
      qm <- tryCatch(
        jsonlite::fromJSON(meta_path, simplifyVector = FALSE),
        error = function(e) NULL
      )
      query_class <- qm$query_class
    }

    # Check if data is empty -------------------------------------------------

    data_type <- DBI::dbGetQuery(
      conn = con,
      statement = sprintf(
        "SELECT typeof(data) AS type FROM read_json_auto('%s')",
        fn
      )
    )$type

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

    # Metadata-driven dispatch -----------------------------------------------
    if (identical(query_class, "kagi_query_search")) {
      write_search_parquet(con, fn, query_name, pn, output, verbose)
      next
    }
    if (identical(query_class, "kagi_query_extract")) {
      write_extract_parquet(con, fn, query_name, pn, output, verbose)
      next
    }

    stop(
      "Unknown or missing query_class in `", meta_path,
      "`. Expected `kagi_query_search` or `kagi_query_extract`.",
      call. = FALSE
    )
  }

  if (isTRUE(combine)) {
    parquet_files <- list.files(
      output,
      pattern = "\\.parquet$",
      recursive = TRUE,
      full.names = TRUE
    )
    parquet_files <- parquet_files[basename(parquet_files) != "combined.parquet"]
    if (length(parquet_files) > 0L) {
      combined_path <- file.path(output, "combined.parquet")
      glob <- file.path(output, "**", "*.parquet")
      stmt <- sprintf(
        "COPY (SELECT * FROM read_parquet('%s', union_by_name=true, hive_partitioning=true)) TO '%s' (FORMAT PARQUET, COMPRESSION SNAPPY)",
        glob,
        combined_path
      )
      DBI::dbExecute(conn = con, statement = stmt)

      # Drop the Hive-partitioned directories now that combined.parquet has them.
      part_dirs <- list.dirs(output, recursive = FALSE, full.names = TRUE)
      part_dirs <- part_dirs[grepl("^query=", basename(part_dirs))]
      for (d in part_dirs) unlink(d, recursive = TRUE, force = TRUE)

      if (verbose) {
        message("Combined ", length(parquet_files), " parquet files into `", combined_path, "`.")
      }
    } else if (verbose) {
      message("`combine = TRUE` requested but no parquet files were written.")
    }
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
