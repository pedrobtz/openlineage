# CLAUDE.md

<!-- markdownlint-disable-next-line MD013 -->
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Shared conventions

The portfolio's shared rules are synced into `.claude/shared/` from
`pedrobtz/packages:claude/shared/`. Never edit them here. Where this file and
a shared file disagree, this file wins for this package.

@.claude/shared/workflow.md
@.claude/shared/r-package.md
@.claude/shared/ci.md
@.claude/shared/correctness.md
@.claude/shared/assurance.md

`AGENTS.md` predates this file and holds the repository's own style, testing
and pull request guidelines for any agent. It overlaps the shared files on
commands, roxygen and commit style; where they differ, this file and the
shared files win for Claude Code. Deviations are stated as such below.

## What this is

An R client for the [OpenLineage](https://openlineage.io/docs/)
specification: build and validate run events, serialize them to JSON with
the wire field names, and deliver them through a transport. The OpenLineage
Python client is the behavioural reference, but its non-R APIs are not
copied. Event models stay separate from serialization, configuration and
transport code.

Deviation from the zero-dependency rule: runtime dependencies are `cli`
(conditions), `httr2` (HTTP), `jsonlite` (JSON), `R6` (the stateful client
and transports), `S7` (models and validation) and `uuid` (run IDs). Justify
any new one.

There is no design or roadmap document and no `.agents/` directory. The
exported docs, `vignettes/openlineage-lifecycle.Rmd`, the golden fixtures and
the tests are the contract.

## Current state

On CRAN as 0.1.0 (published 2026-07-30). `main` is the development version,
`0.1.0.9000`, with no changes yet under its `NEWS.md` heading. It targets
OpenLineage schema 2.0.2 (`OPENLINEAGE_SCHEMA_VERSION`).

Implemented: S7 models for run states, runs, jobs, datasets and run events;
typed core facets (nominal time, parent run, error message, processing
engine, schema, data source, SQL, source code location, job type, input and
output statistics, tags) and generic facets; deterministic JSON
serialization; UUID and event-time helpers; console, no-op and accumulating
local transports; a synchronous HTTP transport; and the R6
`OpenLineageClient`. Not implemented: asynchronous or batched delivery, and
transports other than HTTP (for example Kafka or file).

Gaps from the shared rules, as of 2026-11-11:

- `R-CMD-check.yaml` is the hand-rolled r-lib template, not a call to
  `pedrobtz/r-actions`, so it does not count as the pre-submission check.
  Issue [#8](https://github.com/pedrobtz/openlineage/issues/8) tracks the
  move. `coverage.yaml` calls r-actions' `coverage.yml` at `@v1`, not at a
  commit pin, although it holds a write token.
- No `cran-release.yaml`; the `.9000` bump was a hand-made pull request.
- No `.agents/assurance.md`.
- `cran-comments.md` still lists a local macOS check as its test
  environment, not CI legs.

## Versions and dependents

The current version's parent issue is
[#5](https://github.com/pedrobtz/openlineage/issues/5), `v0.1.1`. The
`cran-release` reminder is
[#4](https://github.com/pedrobtz/openlineage/issues/4). Sibling packages that
depend on this one: none.

## Commands

The shared commands apply. Specific to this package:

```sh
Rscript -e 'pkgdown::check_pkgdown()'            # reference index is complete
```

## Architecture

One focused file per concern under `R/`, each mirrored by
`tests/testthat/test-<name>.R`.

- **Models (`R/models.R`).** S7 classes `RunState`, `Run`, `Job`, `Dataset`,
  `InputDataset`, `OutputDataset` and `RunEvent`, with validators.
  `R/zzz.R` calls `S7::methods_register()` in `.onLoad()`.
- **Facets (`R/ol-facets.R`).** Abstract S7 bases (`.OpenLineageFacet`,
  `.RunFacet`, `.JobFacet`, `.DatasetFacet`, `.InputDatasetFacet`,
  `.OutputDatasetFacet`, `.GenericFacet`), the typed facets, tags, and the
  wire-name tables `.ol_facet_wire_maps` and `.ol_record_wire_maps`.
- **Serialization (`R/serialization.R`).** `as_openlineage_list()` walks a
  model to named lists through `.ol_to_wire()`, applying wire names, dropping
  `NULL` properties and unwrapping `RunState`. `to_openlineage_json()` calls
  `jsonlite::toJSON()` with `auto_unbox = TRUE` and `digits = NA`.
- **Transports (`R/transports.R`, `R/z-http-transport.R`).** The internal R6
  base `.OpenLineageTransport` and the local transports, then
  `HttpTransport`, which inherits from it. The `z-` prefix makes the HTTP
  file collate after `R/transports.R`, since R6 resolves `inherit` when the
  file is sourced.
- **Client (`R/client.R`).** `OpenLineageClient` picks its transport: a
  no-op one if `disabled` (or `OPENLINEAGE_DISABLED=true`), the injected
  `transport` if given, HTTP if `url` or `OPENLINEAGE_URL` is set, and the
  console otherwise. `OPENLINEAGE_ENDPOINT` and `OPENLINEAGE_API_KEY` fill
  arguments left unset.
- **Shared helpers.** `R/validation.R` (`.ol_validate_*()`,
  `.ol_normalize_*()`), `R/conditions.R` (`.ol_abort()`),
  `R/constants.R` (schema version, URLs, producer), `R/run-id.R` and
  `R/event-time.R`.

Internal objects carry the `.ol_` prefix (or `.OpenLineage` for internal
classes); exported names follow OpenLineage's own class names
(`RunEvent`, `HttpTransport`), so CamelCase there is deliberate. The code
uses the base pipe (`|>`).

Deviation: `README.md` is the source; there is no `README.Rmd`.

## Invariants that are easy to break

- **Wire names exist only at the serialization boundary.** R-facing
  properties are `snake_case` (`event_time`, `run_id`, `schema_url`);
  `.ol_model_fields()` and the wire maps translate them to `eventTime`,
  `runId`, `schemaURL`, `_producer`. A new facet needs an entry in
  `.ol_facet_wire_maps`, or serialization fails with "No wire mapping is
  registered".
- **Output must match the Python client.** `tests/testthat/fixtures/` holds
  JSON produced by the Python client at a recorded upstream commit (see its
  `README.md`), and `test-golden-fixtures.R` compares against them. A change
  in key names, `NULL` omission or number formatting breaks that parity.
- **Every error is an `openlineage_error`.** Conditions carry
  `openlineage_validation_error`, `openlineage_config_error` or
  `openlineage_transport_error` as well. Most go through `.ol_abort()`;
  `R/client.R` and `R/z-http-transport.R` build some by hand with
  `call = NULL`. HTTP failures carry `status_code`.
- **Credentials are never printed.** `HttpTransport` passes every custom
  header to `httr2::req_headers()` with `.redact`, and the client and
  transport `print()` methods show only the transport class, the endpoint
  and the kind of authentication. An API key together with a custom
  `Authorization` header is an error.
- **Retry policy.** Only HTTP 429, 500, 502, 503 and 504 and httr2
  connection failures are retried, at most `max_retries` times after the
  first attempt. The delay honours `Retry-After` (capped at 60 s), otherwise
  backs off as `2^(n - 1)` seconds capped at 30. 401 and 403 are never
  retried. `.ol_http_retry_sleep()` is the one place that sleeps, so tests
  can replace it.
- **`verify_tls = FALSE` warns** with `openlineage_insecure_tls_warning`.
- **`transport =` excludes HTTP arguments.** Passing it with `url`,
  `api_key` or any non-default HTTP argument is a config error, and so are
  HTTP settings without a URL.
- **`new_event_time()` emits UTC with exactly three fractional digits**
  (`2026-01-02T03:04:05.000Z`), truncating rather than rounding.

## Testing

- The suite is fully offline and needs no OpenLineage server. HTTP is tested
  with `httr2::local_mocked_responses()`, which also asserts the request's
  endpoint, headers, body and retries. A test against a local stub server
  must be opt-in.
- `tests/testthat/helper-events.R` gives `fixture_run_id()` and
  `fixture_event_time()`, deterministic inputs for events.
- `tests/testthat/helper-json.R` gives `read_json_fixture()` and
  `expect_json_semantically_equal()`, which compares parsed JSON with object
  keys sorted. Compare parsed JSON unless formatting itself is under test.
- The golden fixtures are the conformance oracle, generated with the Python
  client (`tests/testthat/fixtures/README.md` records the commit and
  version). No other external corpus is used.
- Condition wording is pinned in snapshots under `tests/testthat/_snaps/`.

## Continuous integration

- `R-CMD-check.yaml`: the r-lib template matrix, macOS and Windows release
  and Ubuntu devel, release and oldrel-1, built with
  `--compact-vignettes=gs+qpdf`. No CRAN-like containers and no
  `nosuggests` leg (see Current state).
- `coverage.yaml`: calls r-actions' `coverage.yml@v1`;
  `.github/badges/coverage.svg` is the badge.
- `pkgdown.yaml`: the r-lib template, deploying to `gh-pages` with
  `clean: false`.
