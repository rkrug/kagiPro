# Build a Kagi search query string

Construct one or more query strings for the Kagi Search API by combining
free-text terms with structured operators such as `filetype:`, `site:`,
`inurl:`, and `intitle:`. Use
[`kagi_request()`](https://rkrug.github.io/rkagi/reference/kagi_request.md)
to execute the request and obtain the json replies.

## Usage

``` r
enrich_news_query(
  query,
  filetype = NULL,
  site = NULL,
  inurl = NULL,
  intitle = NULL,
  expand = TRUE
)
```

## Arguments

- query:

  Character vector of free-text query terms (required). These can
  include quoted phrases and boolean operators.

- filetype:

  Optional character vector of file type extensions (e.g. `"pdf"`,
  `"docx"`). Each is prefixed with `filetype:`.

- site:

  Optional character vector of domains (e.g. `"example.com"`, `"gov"`).
  Each is prefixed with `site:`.

- inurl:

  Optional character vector of URL substrings that must be present in
  the result URL. Each is prefixed with `inurl:`.

- intitle:

  Optional character vector of terms that must appear in the page title.
  Each is prefixed with `intitle:`.

- expand:

  Logical, default `TRUE`. If `TRUE`, generate a fully crossed set of
  queries (Cartesian product of all combinations of `query`, `filetype`,
  `site`, `inurl`, and `intitle`). If `FALSE`, concatenate the arguments
  into a single combined query string.

## Value

A named list containing query strings of class `kagi_enrich_news_query`,
to be used in
[`kagi_request()`](https://rkrug.github.io/rkagi/reference/kagi_request.md).

## Details

This helper makes it easy to build reproducible, complex queries with
structured operators. Use `expand = TRUE` when you want all possible
combinations (useful in systematic search contexts). Use
`expand = FALSE` when you want a single combined query.

## See also

[`open_search_query()`](https://rkrug.github.io/rkagi/reference/open_search_query.md),
[`kagi_request()`](https://rkrug.github.io/rkagi/reference/kagi_request.md),
[`kagi_request_parquet()`](https://rkrug.github.io/rkagi/reference/kagi_request_parquet.md),

## Examples

``` r
if (FALSE) { # \dontrun{
# Single combined query
search_query(
  query = "biodiversity",
  filetype = c("pdf", "docx"),
  site = "example.com",
  expand = FALSE
)

# Expanded combinations
search_query(
  query = c("biodiversity", "ecosystem"),
  filetype = c("pdf", "docx"),
  site = c("example.com", "gov"),
  expand = TRUE
)

# Open a generated query manually in browser
open_search_query(search_query("openalex api", site = "docs.openalex.org")[[1]])
} # }
```
