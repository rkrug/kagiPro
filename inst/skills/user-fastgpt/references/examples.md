# FastGPT Examples

```r
q_fast <- fastgpt_query(
  query = "What is Python 3.11?",
  cache = TRUE,
  web_search = TRUE
)
```

```r
kagi_request(
  connection = conn,
  query = q_fast[[1]],
  output = "fastgpt_output",
  overwrite = TRUE
)
```

```r
kagi_request(
  connection = conn,
  query = q_fast_many,
  output = "fastgpt_batch_safe",
  overwrite = TRUE,
  workers = 2,
  error_mode = "write_dummy"
)
```

