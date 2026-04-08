# rkagi Summarize Endpoint Guide

## Summarize Endpoint: Robust Summaries in Real Pipelines

The Universal Summarizer endpoint is often where users need both quality
and resilience.

In practice, summarization workloads are mixed: some inputs are ideal,
some are too short, and some fail upstream for reasons outside your
script. This guide shows how to keep pipelines reliable while preserving
useful output.

### Establish a reusable connection

``` r
library(rkagi)

conn <- kagi_connection(
  api_key = function() keyring::key_get("API_kagi")
)
```

### Build summarize queries for URL and text sources

`rkagi` supports both URL-based and raw-text summarization.

``` r
q_url <- summarize_query(
  url = "https://www.example.com/long-article",
  engine = "muriel",
  summary_type = "summary",
  target_language = "EN",
  cache = TRUE
)
```

``` r
q_text <- summarize_query(
  text = paste(
    "Biodiversity underpins ecosystem services such as pollination, soil fertility,",
    "water purification, and climate regulation.",
    "Habitat loss and climate pressure accelerate species decline with consequences",
    "for resilience and human wellbeing."
  ),
  engine = "cecil",
  summary_type = "takeaway",
  target_language = "EN",
  cache = TRUE
)
```

Both calls return named lists, so execution stays consistent regardless
of input style.

### Execute a normal summarize request

``` r
out_sum <- "summarize_output"
dir.create(out_sum, recursive = TRUE, showWarnings = FALSE)

kagi_request(
  connection = conn,
  query = q_text[[1]],
  output = out_sum,
  overwrite = TRUE
)
```

This is the baseline path for standard inputs.

### Handle known short-input failures safely

Very short text can trigger server-side failures (for example minimum
document size constraints). If you do not want a full pipeline stop, use
graceful mode.

``` r
q_short <- summarize_query(
  text = "Too short.",
  engine = "cecil",
  summary_type = "summary",
  target_language = "EN"
)

kagi_request(
  connection = conn,
  query = q_short[[1]],
  output = "summarize_short_safe",
  overwrite = TRUE,
  error_mode = "write_dummy"
)
```

In this mode, the request warns and writes a dummy JSON payload, where
summarize fields are present but empty (`data$output = null`,
`data$tokens = 0`).

### Run mixed batches with one success and one failure

A realistic batch often contains both valid and invalid inputs.

``` r
q_ok <- summarize_query(
  text = paste(rep("Long summarize input text.", 40), collapse = " "),
  engine = "cecil",
  summary_type = "summary",
  target_language = "EN"
)

q_err <- summarize_query(
  text = "short",
  engine = "cecil",
  summary_type = "summary",
  target_language = "EN"
)

kagi_request(
  connection = conn,
  query = list(ok = q_ok[[1]], err = q_err[[1]]),
  output = "summarize_mixed",
  overwrite = TRUE,
  workers = 1,
  error_mode = "write_dummy"
)
```

This keeps the successful summary while recording a structured
placeholder for the failed item.

### Convert summarize JSON to parquet

``` r
kagi_request_parquet(
  input_json = "summarize_mixed",
  output = "summarize_mixed_parquet",
  overwrite = TRUE
)
```

Parquet conversion allows downstream analysis while retaining run-level
consistency.

### Operational recommendations

- Use meaningful minimum text lengths before sending summarize requests.
- Use `workers = 1` while diagnosing warnings, then scale up.
- Prefer `error_mode = "write_dummy"` for long unattended jobs.
