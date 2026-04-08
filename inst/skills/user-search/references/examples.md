# Search Examples

```r
q <- search_query(
  query = 'biodiversity "annual report"',
  filetype = c("pdf", "docx"),
  site = c("example.com", "gov"),
  inurl = c("2024", "report"),
  intitle = "summary",
  expand = FALSE
)

kagi_request(
  connection = conn,
  query = q[[1]],
  limit = 5,
  output = "search_single",
  overwrite = TRUE
)
```

```r
kagi_request(
  connection = conn,
  query = q_many,
  limit = 3,
  output = "search_batch",
  overwrite = TRUE,
  workers = 2,
  error_mode = "write_dummy"
)
```

```r
kagi_request_parquet(
  input_json = "search_batch",
  output = "search_batch_parquet",
  overwrite = TRUE
)
```

