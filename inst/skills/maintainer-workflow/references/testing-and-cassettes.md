# Testing and Cassettes

## Baseline Expectations

- Use `testthat` (edition 3).
- Use `vcr` for HTTP recording/replay.
- Keep cassettes in `tests/testthat/fixtures/cassettes` only.

## Re-recording Workflow

1. Ensure API key is available via `keyring::key_get("API_kagi")`.
2. Set `VCR_RECORD_MODE` appropriately (for example `all` during refresh).
3. Re-run targeted tests that exercise changed requests.
4. Review cassettes for expected endpoint URLs and payload shape.
5. Reset recording mode after cassette updates.

## Required Coverage for Request-Path Changes

- Successful request path.
- List/batch request path.
- At least one failure path with `error_mode = "write_dummy"`.
- Parquet conversion handling for dummy/error payloads.

## Regression Triggers

Always re-run tests if changing:

- Constructor return shape.
- Request recursion/list handling.
- Error formatting/dummy payload shape.
- Parquet extraction logic.

