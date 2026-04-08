# rkagi Enrich Endpoint Guide

## Enrich Endpoint: Context Discovery for Web and News

The Enrich API is useful when a plain search result list is not enough
and you want curated context for a topic.

In `rkagi`, this is split into two constructors:

- [`enrich_web_query()`](https://rkrug.github.io/rkagi/reference/enrich_web_query.md)
  for web context.
- [`enrich_news_query()`](https://rkrug.github.io/rkagi/reference/enrich_news_query.md)
  for news context.

The execution flow is identical for both.

### Create the connection once

``` r
library(rkagi)

conn <- kagi_connection(
  api_key = function() keyring::key_get("API_kagi")
)
```

### Build web and news enrich queries

Assume you are tracking biodiversity policy from institutional sources.

``` r
q_web <- enrich_web_query(
  query = "open data portals",
  site = "gov",
  expand = FALSE
)

q_news <- enrich_news_query(
  query = "biodiversity policy",
  expand = FALSE
)
```

Both constructors return named lists, so single and batch execution
share the same interface.

### Execute a focused run for each enrich type

``` r
out_web <- "enrich_web"
dir.create(out_web, recursive = TRUE, showWarnings = FALSE)

kagi_request(
  connection = conn,
  query = q_web[[1]],
  output = out_web,
  overwrite = TRUE
)
```

``` r
out_news <- "enrich_news"
dir.create(out_news, recursive = TRUE, showWarnings = FALSE)

kagi_request(
  connection = conn,
  query = q_news[[1]],
  output = out_news,
  overwrite = TRUE
)
```

At this stage you have two independent JSON collections, one for web
context and one for news context.

### Move to a thematic batch workload

For recurring monitoring, prepare a topic vector and run it as a batch.

``` r
q_news_batch <- enrich_news_query(
  query = c("biodiversity", "ecosystem restoration", "nature finance"),
  expand = TRUE
)

kagi_request(
  connection = conn,
  query = q_news_batch,
  output = "enrich_news_batch",
  overwrite = TRUE,
  workers = 2
)
```

This pattern is well suited for weekly or monthly trend snapshots.

### Handle request failures without losing the whole run

If you want long jobs to continue when one request fails:

``` r
kagi_request(
  connection = conn,
  query = q_news_batch,
  output = "enrich_news_batch_safe",
  overwrite = TRUE,
  workers = 2,
  error_mode = "write_dummy"
)
```

Failed requests are written as dummy JSON with `data = null` plus an
`error` block, and the function emits warnings.

### Convert enrich output to parquet

``` r
kagi_request_parquet(
  input_json = "enrich_news_batch",
  output = "enrich_news_batch_parquet",
  overwrite = TRUE
)
```

Use parquet when you want to join enrich data with other tables or build
reproducible reports.

### Operational recommendations

- Keep web and news outputs in separate directories.
- Start with `workers = 1` during debugging, then increase.
- Keep raw JSON as the source of truth, and regenerate parquet as
  needed.
