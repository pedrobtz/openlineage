# Repository Guidelines

## Purpose & Architecture

`openlineage` is an idiomatic R client for the
[OpenLineage framework](https://openlineage.io/docs/), comparable to the
[Python client](https://openlineage.io/docs/client/python/). Emit
standards-compliant lineage events, using the Python client as a behavioral
reference without copying non-R APIs. Core
concepts include `RunEvent`, `RunState`, `Run`, `Job`, `Dataset`, facets, and
configurable transports. Keep event models separate from serialization,
configuration, and transport code.

## Project Structure & Module Organization

Put package code in `R/`, using focused files such as `R/run-event.R` and
`R/http-transport.R`. Mirror them with tests such as
`tests/testthat/test-run-event.R`; `tests/testthat.R` is the suite entry point.
`DESCRIPTION` lists preferred tools: `httr2` for HTTP, `jsonlite` for JSON,
`S7` for models and validation, `R6` for the stateful client, and `cli` for
user-facing conditions. Use only when needed; justify new dependencies.
`NAMESPACE` and `man/*.Rd` are generated from roxygen2 comments and must not be
edited manually. Use `vignettes/` for workflows and `_pkgdown.yml` for the
documentation-site index.

## Build, Test, and Development Commands

- `Rscript -e 'devtools::load_all()'` loads the package for development.
- `Rscript -e 'devtools::document()'` regenerates documentation and exports.
- `Rscript -e 'devtools::test()'` runs all testthat tests.
- `Rscript -e 'devtools::check()'` performs the full package check.
- `R CMD build .` creates a source package archive.

## Coding Style & Naming Conventions

Use two-space indentation, `<-` assignment, `snake_case` names, and the base
pipe (`|>`). Keep lines near 80 characters and remove trailing whitespace.
Document every exported function with roxygen2 and include executable examples
where practical. Run `air format .` when Air is available. Preserve OpenLineage
wire-format field names only at serialization boundaries; keep R-facing names
idiomatic.

## Testing Guidelines

Use testthat edition 3; the default suite must be fully offline and require no
OpenLineage server. Adapt the Python suite patterns: deterministic event
helpers, checked-in golden JSON fixtures, and an accumulating/no-output fake
transport. Use `httr2::local_mocked_responses()` to assert request endpoints,
headers, bodies, retries, and failures. Compare parsed JSON unless formatting
matters, and table-test validation/configuration edges. Any disposable local
stub-server tests must be opt-in. Run `devtools::check()` before submission.

## Commit & Pull Request Guidelines

History currently contains only `Initial commit`, so use concise, imperative
subjects such as `Add HTTP event transport`. Keep unrelated changes separate.
Pull requests should explain motivation, public API and protocol effects, link
issues, and report `devtools::check()` results. Call out the OpenLineage schema
version used and any compatibility differences from the Python client. The
GitHub Actions R CMD check matrix must pass on macOS, Windows, and Linux.
