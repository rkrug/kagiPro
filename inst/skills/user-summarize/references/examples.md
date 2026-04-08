# Summarize Examples

```r
q_text <- summarize_query(
  text = paste(
    "Biodiversity underpins ecosystem services.",
    "Habitat loss and climate pressure accelerate species decline."
  ),
  engine = "cecil",
  summary_type = "takeaway",
  target_language = "EN",
  cache = TRUE
)
```

```r
kagi_request(
  connection = conn,
  query = q_text[[1]],
  output = "summarize_output",
  overwrite = TRUE
)
```

```r
kagi_request(
  connection = conn,
  query = list(ok = q_ok[[1]], err = q_err[[1]]),
  output = "summarize_mixed",
  overwrite = TRUE,
  workers = 1,
  error_mode = "write_dummy"
)
```

