# rkagi <a href="https://rkrug.github.io/rkagi/"><img src="https://rkrug.github.io/rkagi/logo.png" align="right" height="139" /></a>

> R client for the [Kagi API](https://help.kagi.com/kagi/api/).

---

## Overview

`rkagi` provides a lightweight R interface to the **Kagi API**, including:

- **Search API** — perform web searches with advanced operators
- **Enrich API** — get higher-signal results from specialized indices
- **Universal Summarizer** — summarize text or URLs in one call
- **FastGPT API** — ask grounded LLM questions with optional web context

The package follows the [rOpenSci](https://ropensci.org) style for API clients:

- S3 classes for **connections**, **requests**, and **results**
- Extractor helpers to work with results as tibbles or text
- Secure API key handling with [keyring](https://cran.r-project.org/package=keyring)

---

## Installation

```r
# Install the development version from GitHub
# install.packages("remotes")
remotes::install_github("rkrug/rkagi")
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
library(rkagi)

# Build a query
q <- search_query(
  query    = 'biodiversity "annual report"',
  filetype = "pdf",
  site     = "example.com",
  expand   = FALSE
)

# Execute request and write JSON output
conn <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))
out <- tempfile("rkagi-search-")
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
👉 <https://rkrug.github.io/rkagi/articles/quickstart.html>

Endpoint guides are available at:
- <https://rkrug.github.io/rkagi/articles/search-endpoint.html>
- <https://rkrug.github.io/rkagi/articles/enrich-endpoint.html>
- <https://rkrug.github.io/rkagi/articles/summarize-endpoint.html>
- <https://rkrug.github.io/rkagi/articles/fastgpt-endpoint.html>

AI-agent skills (for Codex/Claude-style workflows) are packaged under:
- `inst/skills/`
- `inst/skills/README.md` (index and selection rules)

The full reference and function documentation is published via **pkgdown** at:  
👉 <https://rkrug.github.io/rkagi/>

---

## Contributing

Bug reports and pull requests are welcome at:  
<https://github.com/rkrug/rkagi>

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
