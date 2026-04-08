# Create a FastGPT query payload

Construct one or more FastGPT query payloads for `POST /fastgpt`. Use
[`kagi_request()`](https://rkrug.github.io/rkagi/reference/kagi_request.md)
to execute the request and obtain JSON responses.

## Usage

``` r
fastgpt_query(query, cache = TRUE, web_search = TRUE)
```

## Arguments

- query:

  Character vector. Query text to answer.

- cache:

  Logical. Whether cached responses are allowed. Default: `TRUE`.

- web_search:

  Logical. Whether to use web search enrichment. Default: `TRUE`.

## Value

A named list of query objects of class `kagi_fastgpt_query` to be used
in
[`kagi_request()`](https://rkrug.github.io/rkagi/reference/kagi_request.md).

## Details

According to current Kagi FastGPT API behavior, `web_search = FALSE` is
out of service and rejected. This constructor enforces
`web_search = TRUE`.

## Examples

``` r
if (FALSE) { # \dontrun{
fastgpt_query("Python 3.11")
fastgpt_query(c("Python 3.11", "What is biodiversity?"))
} # }
```
