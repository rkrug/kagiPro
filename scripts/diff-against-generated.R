#!/usr/bin/env Rscript
# Cross-check the JSON bodies kagiPro sends against the openapi-generator
# reference implementation.
#
# This script is local-only. It is NOT run by R CMD check or by the test suite.
# It exits silently if the generated reference package is not available.
#
# Layout assumed:
#   <parent>/rkagi/     (this package; cwd or located via R CMD)
#   <parent>/kagiAPI/   (openapi-generator output, package name "openapi")
#
# Usage (from anywhere):
#   Rscript path/to/rkagi/scripts/diff-against-generated.R
# Or from R:
#   source("scripts/diff-against-generated.R")
#
# Exit codes:
#   0  no diffs found (or reference package not available -> skipped)
#   1  one or more sample payloads diverge from the generator's output

main <- function() {
  ref_dir <- locate_reference_package()
  if (is.null(ref_dir)) {
    message(
      "[diff-against-generated] `../kagiAPI` not found at the parent of rkagi. Skipping."
    )
    return(invisible(0L))
  }

  # Load both packages without installing. kagiPro is the package under
  # development; `openapi` is the generated reference.
  require_or_stop("devtools")
  devtools::load_all(rkagi_root(), quiet = TRUE)
  loaded_ref <- tryCatch(
    {
      devtools::load_all(ref_dir, quiet = TRUE)
      TRUE
    },
    error = function(e) {
      message(
        "[diff-against-generated] Could not load reference package at ",
        ref_dir,
        ": ",
        conditionMessage(e),
        "\nSkipping."
      )
      FALSE
    }
  )
  if (!isTRUE(loaded_ref)) {
    return(invisible(0L))
  }

  cases <- build_cases()
  diffs <- 0L
  for (case in cases) {
    cat(sprintf("\n== %s ==\n", case$name))
    diff_count <- diff_case(case)
    diffs <- diffs + diff_count
  }

  if (diffs == 0L) {
    cat(
      "\n[diff-against-generated] OK: all sample payloads match the generated reference.\n"
    )
    invisible(0L)
  } else {
    cat(sprintf(
      "\n[diff-against-generated] %d field-level diff(s) found.\n",
      diffs
    ))
    invisible(1L)
  }
}

# ---------------------------------------------------------------------------
# Locate sibling packages

rkagi_root <- function() {
  # Resolve the rkagi root from this script's location.
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- sub("^--file=", "", grep("^--file=", args, value = TRUE))
  script_path <- if (length(file_arg) == 1L) {
    normalizePath(file_arg, mustWork = FALSE)
  } else {
    # Interactive: assume cwd is rkagi root.
    getwd()
  }
  # scripts/<file>.R -> parent is rkagi root
  if (basename(dirname(script_path)) == "scripts") {
    return(normalizePath(dirname(dirname(script_path))))
  }
  normalizePath(getwd())
}

locate_reference_package <- function() {
  parent <- dirname(rkagi_root())
  candidate <- file.path(parent, "kagiAPI")
  if (!dir.exists(candidate)) {
    return(NULL)
  }
  if (!file.exists(file.path(candidate, "DESCRIPTION"))) {
    return(NULL)
  }
  normalizePath(candidate)
}

require_or_stop <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      "Package `",
      pkg,
      "` is required for this script. Install with: ",
      "install.packages('",
      pkg,
      "')",
      call. = FALSE
    )
  }
}

# ---------------------------------------------------------------------------
# Sample cases

build_cases <- function() {
  list(
    list(
      name = "search: minimal",
      kagi = kagiPro::query_search_v1("biodiversity loss")[[1]],
      ref = openapi::SearchRequest$new(
        query = "biodiversity loss",
        workflow = "search",
        format = "json",
        safe_search = NULL,
        lens_id = NULL,
        lens = NULL,
        timeout = NULL,
        page = NULL,
        limit = NULL,
        filters = NULL,
        extract = NULL,
        personalizations = NULL
      )
    ),
    list(
      name = "search: limit + filters",
      kagi = kagiPro::query_search_v1(
        "biodiversity loss",
        limit = 50,
        filters = list(region = "DE", after = "2024-01-01")
      )[[1]],
      ref = openapi::SearchRequest$new(
        query = "biodiversity loss",
        workflow = "search",
        format = "json",
        lens_id = NULL,
        lens = NULL,
        timeout = NULL,
        page = NULL,
        limit = 50L,
        filters = openapi::SearchRequestFilters$new(
          region = "DE",
          after = "2024-01-01",
          before = NULL
        ),
        extract = NULL,
        safe_search = NULL,
        personalizations = NULL
      )
    ),
    list(
      name = "search: workflow=news + lens",
      kagi = kagiPro::query_search_v1(
        "biodiversity",
        workflow = "news",
        lens = list(sites_included = c("nature.com", "science.org"))
      )[[1]],
      ref = openapi::SearchRequest$new(
        query = "biodiversity",
        workflow = "news",
        format = "json",
        lens_id = NULL,
        lens = openapi::SearchRequestLens$new(
          sites_included = c("nature.com", "science.org"),
          sites_excluded = NULL,
          keywords_included = NULL,
          keywords_excluded = NULL,
          file_type = NULL,
          time_after = NULL,
          time_before = NULL,
          time_relative = NULL,
          search_region = NULL
        ),
        timeout = NULL,
        page = NULL,
        limit = NULL,
        filters = NULL,
        extract = NULL,
        safe_search = NULL,
        personalizations = NULL
      )
    ),
    list(
      name = "extract: two URLs",
      kagi = kagiPro::kagi_query_extract(c(
        "https://example.com/a",
        "https://example.com/b"
      ))[[1]],
      ref = openapi::ExtractRequest$new(
        pages = list(
          openapi::PageInput$new(url = "https://example.com/a"),
          openapi::PageInput$new(url = "https://example.com/b")
        ),
        timeout = NULL,
        format = "json"
      )
    )
  )
}

# ---------------------------------------------------------------------------
# Diffing

diff_case <- function(case) {
  # Normalize both sides by round-tripping through JSON with identical
  # settings. This eliminates spurious "character vs list-of-character"
  # diffs caused by jsonlite's array-handling defaults.
  kagi_body <- normalize_via_json(unclass(case$kagi))
  ref_body <- normalize_via_json(jsonlite::fromJSON(
    case$ref$toJSONString(),
    simplifyVector = TRUE
  ))

  # Drop fields the generator emits as API-spec defaults but kagiPro
  # intentionally omits (semantically equivalent).
  kagi_body <- strip_api_defaults(drop_nulls(kagi_body))
  ref_body <- strip_api_defaults(drop_nulls(ref_body))

  diffs <- compare_lists(kagi_body, ref_body, path = "")
  if (length(diffs) == 0L) {
    cat("  OK\n")
    return(0L)
  }
  for (d in diffs) {
    cat("  - ", d, "\n", sep = "")
  }
  length(diffs)
}

normalize_via_json <- function(x) {
  jsonlite::fromJSON(
    jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null"),
    simplifyVector = TRUE,
    simplifyDataFrame = FALSE,
    simplifyMatrix = FALSE
  )
}

# Drop fields that match a known OpenAPI default ("kagiPro intentionally
# omits these because the API applies the default server-side"). Recursive
# so nested struct defaults are caught too.
API_DEFAULTS <- list(
  format = "json"
)
strip_api_defaults <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  for (k in names(API_DEFAULTS)) {
    if (!is.null(x[[k]]) && identical(x[[k]], API_DEFAULTS[[k]])) {
      x[[k]] <- NULL
    }
  }
  lapply(x, strip_api_defaults)
}

to_plain_list <- function(x) {
  if (is.list(x)) {
    x <- lapply(x, to_plain_list)
  }
  x
}

drop_nulls <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  x <- x[
    !vapply(
      x,
      function(v) is.null(v) || (is.list(v) && length(v) == 0L),
      logical(1)
    )
  ]
  lapply(x, drop_nulls)
}

compare_lists <- function(a, b, path = "") {
  diffs <- character(0)
  keys <- union(names(a), names(b))
  for (k in keys) {
    sub_path <- if (nzchar(path)) paste0(path, ".", k) else k
    av <- a[[k]]
    bv <- b[[k]]
    if (is.null(av) && !is.null(bv)) {
      diffs <- c(
        diffs,
        sprintf("%s: missing in kagiPro (ref=%s)", sub_path, fmt_val(bv))
      )
      next
    }
    if (!is.null(av) && is.null(bv)) {
      diffs <- c(
        diffs,
        sprintf("%s: missing in reference (kagiPro=%s)", sub_path, fmt_val(av))
      )
      next
    }
    if (is.list(av) && is.list(bv)) {
      diffs <- c(diffs, compare_lists(av, bv, sub_path))
    } else if (!identical(av, bv)) {
      diffs <- c(
        diffs,
        sprintf(
          "%s: kagiPro=%s  reference=%s",
          sub_path,
          fmt_val(av),
          fmt_val(bv)
        )
      )
    }
  }
  diffs
}

fmt_val <- function(v) {
  if (is.null(v)) {
    return("NULL")
  }
  if (length(v) > 1L) {
    return(paste0("[", paste(v, collapse = ", "), "]"))
  }
  as.character(v)
}

# ---------------------------------------------------------------------------

status <- main()
if (!interactive()) {
  quit(status = if (is.null(status)) 0L else as.integer(status))
}
