# Corpus Examples

```r
conn <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))

queries <- list(
  bio_reports = query_search("biodiversity annual report", expand = FALSE)[[1]],
  ecosystem_methods = query_search("ecosystem services valuation methods", expand = FALSE)[[1]]
)

kagi_fetch(
  connection = conn,
  query = queries,
  project_folder = "tests_complex",
  overwrite = TRUE
)
```

```r
download_content(
  project_folder = "tests_complex",
  endpoint = "search",
  query_name = NULL,
  workers = 4
)

content_markdown(
  project_folder = "tests_complex",
  endpoint = "search",
  query_name = NULL,
  workers = 4
)
```

```r
markdown_abstract(
  project_folder = "tests_complex",
  endpoint = "search",
  query_name = NULL,
  summarizer_fn = summarize_with_openai,
  model = "gpt-4.1-mini",
  workers = 1
)

ds <- read_corpus(
  project_folder = "tests_complex",
  endpoint = "search",
  corpus = "parquet",
  abstracts = TRUE,
  silent = TRUE
)
```
