# rkagi <a href="https://rkrug.github.io/rkagi/"><img src="https://rkrug.github.io/rkagi/logo.png" align="right" height="139" /></a>

> R client for the [Kagi API](https://help.kagi.com/kagi/api/).

---

## Overview

`rkagi` provides a lightweight R interface to the **Kagi API**, including:

- **Search API** — perform web searches with advanced operators
- **Enrich API** — get higher-signal results from specialized indices
- **Universal Summarizer** — summarize text or URLs in one call

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
conn <- new_kagi_connection(
  endpoint = "search",
  api_key  = function() keyring::key_get("API_kagi")
)
```

---

## Example

```r
library(rkagi)

# Build a query
q <- build_kagi_query(
  query    = 'biodiversity "annual report"',
  filetype = "pdf",
  site     = "example.com"
)

# Perform a one-liner search
res <- kagi_search_once(q, limit = 3)
kagi_hits(res)
```

---

## Documentation

A detailed **Quickstart vignette** is included and available at:  
👉 <https://rkrug.github.io/rkagi/articles/quickstart.html>

The full reference and function documentation is published via **pkgdown** at:  
👉 <https://rkrug.github.io/rkagi/>

---

## Contributing

Bug reports and pull requests are welcome at:  
<https://github.com/rkrug/rkagi>

---

## License

MIT © Rainer Krug
