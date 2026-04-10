# kagiPro <a href="https://rkrug.github.io/kagiPro/"><img src="https://rkrug.github.io/kagiPro/logo.png" align="right" height="139" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/rkrug/kagiPro/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rkrug/kagiPro/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

> R client for the [Kagi API](https://help.kagi.com/kagi/api/).

---

## Overview

`kagiPro` provides a lightweight R interface to the **Kagi API**, including:

- **Search API** — perform web searches with advanced operators
- **Enrich API** — get higher-signal results from specialized indices
- **Universal Summarizer** — summarize text or URLs in one call
- **FastGPT API** — ask grounded LLM questions with optional web context

The package follows the [rOpenSci](https://ropensci.org) style for API clients:

- S3 classes for **connections**, **requests**, and **results**
- Extractor helpers to work with results as tibbles or text
- Secure API key handling with [keyring](https://cran.r-project.org/package=keyring)
- Replay metadata for query-by-name reruns in project workflows

---

## Installation

```r
# Install the development version from GitHub
# install.packages("remotes")
remotes::install_github("rkrug/kagiPro")
```

---

## Authentication

You need a [Kagi account](https://kagi.com) with API access (paid plan).  
Store your API key securely in your system keychain:

```r
# Run once to save your key in the keychain
keyring::key_set("API_kagi")
```

The package will resolve the key at request time with:

```r
conn <- kagi_connection(
  api_key  = function() keyring::key_get("API_kagi")
)
```

---

## Example

```r
library(kagiPro)

# Build a query
q <- query_search(
  query    = 'biodiversity "annual report"',
  filetype = "pdf",
  site     = "example.com",
  expand   = FALSE
)

# Execute request and write JSON output
conn <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))
out <- tempfile("kagiPro-search-")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

kagi_request(
  connection = conn,
  query = q,
  limit = 3,
  output = out,
  overwrite = TRUE
)
```

---

## Documentation

A detailed **Quickstart vignette** is included and available at:  
👉 <https://rkrug.github.io/kagiPro/articles/quickstart.html>

Endpoint guides are available at:
- <https://rkrug.github.io/kagiPro/articles/search-endpoint.html>
- <https://rkrug.github.io/kagiPro/articles/enrich-endpoint.html>
- <https://rkrug.github.io/kagiPro/articles/summarize-endpoint.html>
- <https://rkrug.github.io/kagiPro/articles/fastgpt-endpoint.html>
- <https://rkrug.github.io/kagiPro/articles/corpus-workflow.html>
- <https://rkrug.github.io/kagiPro/articles/agent-quick-index.html>
- <https://rkrug.github.io/kagiPro/articles/api-contracts.html>

AI-agent skills (for Codex/Claude-style workflows) are packaged under:
- `inst/skills/`
- `inst/skills/README.md` (index and selection rules)
- machine-readable AI indexes:
  - `llms.txt` (compact)
  - `llms-full.txt` (extended contracts/workflows)

The full reference and function documentation is published via **pkgdown** at:  
👉 <https://rkrug.github.io/kagiPro/>

---

## Project-Folder Workflow (`kagi_fetch`)

For project-oriented runs aligned with `openalexPro`, use `kagi_fetch()` as the
high-level entrypoint. It writes endpoint-scoped folders:

- `<project_folder>/<endpoint>/json`
- `<project_folder>/<endpoint>/parquet`

```r
library(kagiPro)

conn <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))
q <- query_search("biodiversity policy", expand = FALSE)

parquet_path <- kagi_fetch(
  connection = conn,
  query = q,
  project_folder = "kagi_project"
)
```

To rerun one stored query by name (and refresh only that parquet query
partition), use `kagi_update_query()`:

```r
kagi_update_query(
  connection = conn,
  project_folder = "kagi_project",
  query_name = "query_1"
)
```

To reclaim space from JSON request payloads while keeping rerun metadata, use:

```r
clean_request("kagi_project", dry_run = TRUE)   # preview
clean_request("kagi_project", dry_run = FALSE)  # execute
```

---

## OpenAlexPro Bridge

For abstract enrichment, use the modular pipeline:
download content -> extract markdown -> summarize markdown.

```r
# Assumes `kagi_project/search/parquet` already exists
download_content(
  project_folder = "kagi_project",
  endpoint = "search"
)

content_markdown(
  project_folder = "kagi_project",
  endpoint = "search"
)

markdown_abstract(
  project_folder = "kagi_project",
  endpoint = "search",
  summarizer_fn = summarize_with_openai,
  model = "gpt-4.1-mini"
)

# Abstract parquet is written under:
# kagi_project/search/abstract/query=<query_name>/
```

---

## Contributing

Bug reports and pull requests are welcome at:  
<https://github.com/rkrug/kagiPro>

---

## Disclaimer

This package is provided **as is**, without warranty of any kind, express or implied, including but not limited to fitness for a particular purpose, merchantability, or non-infringement.

The authors and contributors are not liable for any claim, damages, or other liability arising from the use of this software. Users are responsible for validating outputs and assessing suitability for their own workflows and decisions.

---

## AI-Assisted Development Notice

Parts of this package's code, tests, and documentation were developed or refined with AI coding assistants (for example Codex/Claude-style tools) under human direction and review.

AI-generated content may contain mistakes or omissions. Final responsibility for verification, testing, and release quality remains with the maintainers.

---

## License

MIT © Rainer Krug
