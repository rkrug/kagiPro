#' @keywords internal
read_parquet_dataset <- function(path) {
  parquet_files <- list.files(path, pattern = "\\.parquet$", recursive = TRUE, full.names = TRUE)
  if (length(parquet_files) == 0L) {
    return(data.frame())
  }

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  rows <- lapply(parquet_files, function(fn) {
    stmt <- sprintf("SELECT * FROM read_parquet('%s')", gsub("'", "''", fn))
    DBI::dbGetQuery(con, stmt)
  })

  do.call(rbind, rows)
}

#' @keywords internal
write_parquet_dataset <- function(df, output, overwrite = FALSE, verbose = FALSE) {
  if (dir.exists(output)) {
    if (!overwrite) {
      stop("Directory exists: ", output, ". Set `overwrite = TRUE`.", call. = FALSE)
    }
    if (verbose) {
      message("Deleting existing output: ", output)
    }
    unlink(output, recursive = TRUE, force = TRUE)
  }

  dir.create(output, recursive = TRUE, showWarnings = FALSE)

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  DBI::dbWriteTable(con, "augmented", df, overwrite = TRUE)

  partition_clause <- if ("query" %in% names(df)) {
    "PARTITION_BY 'query',"
  } else if ("page" %in% names(df)) {
    "PARTITION_BY 'page',"
  } else {
    ""
  }
  stmt <- sprintf(
    "COPY (SELECT * FROM augmented) TO '%s' (FORMAT PARQUET, COMPRESSION SNAPPY, %s APPEND)",
    gsub("'", "''", output),
    partition_clause
  )
  DBI::dbExecute(con, stmt)

  invisible(output)
}
