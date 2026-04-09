# Corpus Pipeline Testing

1. Validate selector expansion (`endpoint` / `query_name` NULL behavior).
2. Validate file placement for `content`, `markdown`, and `abstract`.
3. Validate `read_corpus(abstracts = TRUE)` lazy-link behavior by `id + query`.
4. Validate schema expectations (`abstract` lowercase; no stale `Abstract`).
5. Validate provider failures produce row-level status/error instead of silent drops.
6. Validate progress messaging remains usable under parallel runs.
