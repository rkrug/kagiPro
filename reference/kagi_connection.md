# Construct a Kagi API connection

Build a typed S3 object of class **`kagi_connection`** which holds the
basic configuration required to talk to the Kagi API. This includes the
API base URL, authentication key, and retry settings.

## Usage

``` r
kagi_connection(
  base_url = "https://kagi.com/api/v0",
  api_key = Sys.getenv("KAGI_API_KEY"),
  max_tries = 3
)
```

## Arguments

- base_url:

  Character scalar. Base URL for the Kagi API. Defaults to
  `"https://kagi.com/api/v0"`.

- api_key:

  API key used for authentication. By default this is read from the
  environment variable `KAGI_API_KEY`. Best practice is to set this
  variable in your `~/.Renviron`. Advanced users may also supply a
  function that resolves the key lazily at request time (see
  [`resolve_api_key()`](https://rkrug.github.io/rkagi/reference/resolve_api_key.md)).

- max_tries:

  Integer scalar. Maximum number of retry attempts for transient errors.
  Defaults to `3`.

## Value

An object of class **`kagi_connection`** with components:

- `base_url`:

  Base API URL.

- `api_key`:

  API key (or a function to resolve it).

- `max_tries`:

  Maximum retry attempts.

## See also

[`resolve_api_key()`](https://rkrug.github.io/rkagi/reference/resolve_api_key.md),

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic connection (API key from env var)
conn <- kagi_connection()
conn

# Explicit API key
conn2 <- kagi_connection(api_key = "my-key")

# Lazy API key via keyring
conn3 <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))
} # }
```
