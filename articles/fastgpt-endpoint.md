# rkagi FastGPT Endpoint Guide

## FastGPT Endpoint: Practical Prompt Workflows

FastGPT is the endpoint to use when you need direct prompt-response
interactions with optional web grounding.

This guide focuses on how to structure prompts for repeatable runs,
scale to batches, and handle transient failures without dropping the
full job.

### Create one connection for all runs

``` r
library(rkagi)

conn <- kagi_connection(
  api_key = function() keyring::key_get("API_kagi")
)
```

### Build a single prompt query

``` r
q_fast <- fastgpt_query(
  query = "What is Python 3.11?",
  cache = TRUE,
  web_search = TRUE
)

q_fast
```

Like other query builders in `rkagi`, this returns a named list for
consistency.

### Execute and store the first response

``` r
out_fast <- "fastgpt_output"
dir.create(out_fast, recursive = TRUE, showWarnings = FALSE)

kagi_request(
  connection = conn,
  query = q_fast[[1]],
  output = out_fast,
  overwrite = TRUE
)
```

Persisting responses to JSON is useful for prompt comparison and
reproducibility.

### Scale prompts to a batch job

``` r
q_fast_many <- fastgpt_query(
  query = c(
    "What are ecosystem services?",
    "What is biodiversity offsetting?",
    "How does pollination support food systems?"
  ),
  cache = TRUE,
  web_search = TRUE
)

kagi_request(
  connection = conn,
  query = q_fast_many,
  output = "fastgpt_batch",
  overwrite = TRUE,
  workers = 2
)
```

This pattern is suitable for generating comparable outputs across a
fixed prompt set.

### Keep long runs resilient with graceful error handling

``` r
kagi_request(
  connection = conn,
  query = q_fast_many,
  output = "fastgpt_batch_safe",
  overwrite = TRUE,
  workers = 2,
  error_mode = "write_dummy"
)
```

When a request fails, dummy JSON is written and the job continues. For
FastGPT, dummy records include `data$output = null` and
`data$tokens = 0`.

### Convert FastGPT output to parquet

``` r
kagi_request_parquet(
  input_json = "fastgpt_batch_safe",
  output = "fastgpt_batch_parquet",
  overwrite = TRUE
)
```

This gives a clean table-like format for reporting or joins with other
run metadata.

### Operational recommendations

- Keep prompts concise and task-specific.
- Version your prompt sets explicitly in scripts.
- Use graceful mode for unattended batch processing.
