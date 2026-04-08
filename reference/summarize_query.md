# Create a new Kagi summarize request

Construct a typed S3 object of class `kagi_summarize` that describes a
Universal Summarizer request. Use
[`kagi_request()`](https://rkrug.github.io/rkagi/reference/kagi_request.md)
to execute the request and obtain the json replies.

## Usage

``` r
summarize_query(
  url = NULL,
  text = NULL,
  engine = NULL,
  summary_type = NULL,
  target_language = NULL,
  cache = TRUE
)
```

## Arguments

- url:

  Optional character scalar. URL to be summarized. Mutually exclusive
  with `text`.

- text:

  Optional character scalar. Raw text to be summarized. Mutually
  exclusive with `url`.

- engine:

  Character scalar. Summarizer engine (options: `"cecil"`, `"agnes"`,
  `"muriel"`, `"daphne"`). Default: `"cecil"`.

- summary_type:

  Character scalar. Type of summary requested (options: `"summary"`,
  `"takeaway"`). Default: `"summary"`.

- target_language:

  Character scalar. Target language ISO code. Supported codes: `"EN"`,
  `"BG"`, `"CS"`, `"DA"`, `"DE"`, `"EL"`, `"ES"`, `"ET"`, `"FI"`,
  `"FR"`, `"HU"`, `"ID"`, `"IT"`, `"JA"`, `"KO"`, `"LT"`, `"LV"`,
  `"NB"`, `"NL"`, `"PL"`, `"PT"`, `"RO"`, `"RU"`, `"SK"`, `"SL"`,
  `"SV"`, `"TR"`, `"UK"`, `"ZH"`, `"ZH-HANT"`. Default: `"EN"`.

- cache:

  Logical. Whether to allow API-side caching.

## Value

A named list of `kagi_summarize_query` objects to be passed to
[`kagi_request()`](https://rkrug.github.io/rkagi/reference/kagi_request.md).

## Examples

``` r
if (FALSE) { # \dontrun{
req <- summarize_query(text = "Lorem ipsum")
req
} # }
```
