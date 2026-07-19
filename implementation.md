# openlineage 0.1.0 Implementation

This document is the source of truth for implementing version 0.1.0. The
product scope remains in [`roadmap.md`](roadmap.md); this file records execution
order, decisions, progress, and newly discovered work.

**Status:** Stages 0–6 complete; ready for Stage 7
**Last updated:** 2026-07-19

## Working Agreements

- Complete stages in order unless this document records why work moved.
- Add tests with each behavior; the default suite must remain fully offline.
- End every stage with `devtools::test()` and `devtools::check()`.
- Update this file after decisions, discoveries, completed work, and commits.
- Do not commit this currently untracked file unless it is intentionally added
  to repository history.

## Locked Decisions

- Target OpenLineage schema 2.0.2 and its v2 object model.
- Use S7 for protocol values, R6 for the client, `jsonlite` for serialization,
  `httr2` for HTTP, and `cli` for user-facing conditions.
- Use `uuid` for random run identifiers rather than maintaining UUID bit-level
  logic in the package.
- Keep models, serialization, configuration, and transports separate.
- Authentication is an HTTP transport concern; credentials never enter events.
- HTTP retries cover low-level connection failures and status codes 429, 500,
  502, 503, and 504. `max_retries` counts attempts after the first request.
- Client configuration resolves `disabled` first; an explicit logical value
  overrides `OPENLINEAGE_DISABLED`. Disabled clients use `NoopTransport` and
  do not validate unused delivery settings.
- An injected transport takes precedence over HTTP environment variables.
  Combining it with explicit HTTP constructor arguments is rejected as
  ambiguous. Without a transport or URL, the client uses `ConsoleTransport`;
  partial HTTP settings without a URL are rejected.
- Support `RunEvent` in 0.1.0. Static `JobEvent` and `DatasetEvent` are deferred.
- Allow arbitrary facets even when no typed R model exists.

## Staged Implementation

### Stage 0 — Freeze contracts and fixtures

- [x] Record exported names, constructor signatures, defaults, and condition
  classes in a compact API table below.
- [x] Confirm schema URLs, required fields, enum values, and null/empty-array
  behavior against OpenLineage 2.0.2.
- [x] Select at least two Python-client fixtures: a minimal `START` event and a
  terminal event with datasets and facets.
- [x] Copy only required fixtures into `tests/testthat/fixtures/`, recording
  their source and license.
- [x] Define semantic JSON comparison: parse objects before comparison and
  compare arrays in protocol-significant order.

**Gate:** The public contract and expected wire payloads are unambiguous before
model implementation begins.

### Stage 1 — Package foundation and utilities

- [x] Add package constants for producer and schema URL.
- [x] Implement `new_run_id()` and a UTC event-time helper.
- [x] Establish internal validation and `cli` condition helpers.
- [x] Create focused source/test files and shared deterministic test helpers.
- [x] Document all exports with roxygen2 and regenerate `NAMESPACE` and `man/`.

**Gate:** Utilities are deterministic where injectable, validation failures
have stable classes, and package loading/checking succeeds.

### Stage 2 — Core models and serialization

- [x] Implement `RunState`, `Run`, `Job`, `Dataset`, `InputDataset`,
  `OutputDataset`, and `RunEvent` as S7 models.
- [x] Validate required values, UUIDs, states, timestamps, and dataset roles.
- [x] Implement one recursive list conversion boundary that preserves
  OpenLineage field names, unwraps enums, omits `NULL`, and retains required
  empty arrays.
- [x] Implement deterministic JSON serialization.
- [x] Match the minimal golden fixture semantically.

**Gate:** A minimal `START` event validates and produces the expected JSON.

### Stage 3 — Facets and lifecycle coverage

- [x] Implement `ol_facet()` with `_producer`, `_schemaURL`, and extension
  fields without discarding unknown values.
- [x] Add the typed facets listed for 0.1.0 in `roadmap.md`.
- [x] Support job, run, input-dataset, and output-dataset facet placement.
- [x] Table-test every lifecycle state and representative invalid inputs.
- [x] Match the terminal golden fixture with datasets and facets.

**Gate:** `START`, `RUNNING`, `COMPLETE`, `ABORT`, and `FAIL` events serialize
correctly, including generic and typed facets.

### Stage 4 — Transport contract and local transports

- [x] Define the internal transport interface and return/error semantics.
- [x] Implement accumulating, console, and no-op transports.
- [x] Verify injected transports receive the model or serialized payload
  specified by the contract—never an accidental mixture of both.
- [x] Test transport failures with stable condition classes.

**Gate:** Lifecycle examples can run offline and tests can inspect all emitted
events without an OpenLineage server.

### Stage 5 — HTTP delivery and authentication

- [x] Implement endpoint normalization for `api/v1/lineage`, timeout, and TLS
  verification with `httr2`.
- [x] Add bearer API-key and custom-header authentication with conflict checks.
- [x] Keep credentials private and redact them from printing and conditions.
- [x] Add bounded retries only for approved transient failures; 401 and 403
  must raise non-retryable `openlineage_auth_error` conditions.
- [x] Assert URLs, headers, bodies, retry behavior, and failures using
  `httr2::local_mocked_responses()`.

**Gate:** Mocked requests prove correct wire delivery and no test requires a
live endpoint or exposes a secret.

### Stage 6 — R6 client and configuration

- [x] Implement `OpenLineageClient` with `emit()` and transport injection.
- [x] Resolve explicit arguments before `OPENLINEAGE_URL`,
  `OPENLINEAGE_ENDPOINT`, `OPENLINEAGE_API_KEY`, and `OPENLINEAGE_DISABLED`.
- [x] Define behavior for disabled emission and invalid/conflicting settings.
- [x] Test independent clients to prevent leaked mutable or credential state.

**Gate:** The documented constructor can emit through HTTP, console, no-op,
and accumulating transports with deterministic configuration precedence.

### Stage 7 — Public documentation and compatibility

- [ ] Add an offline README quick start and lifecycle vignette.
- [ ] Document configuration, authentication, facets, errors, and extension
  points; ensure every example is executable without network access.
- [ ] Cross-check both golden fixtures against the Python client semantics.
- [ ] Add `NEWS.md` and organize the pkgdown reference index.

**Gate:** A new user can construct and emit a complete lifecycle using only
package documentation, and all examples pass offline.

### Stage 8 — CRAN hardening and release

- [ ] Finalize `DESCRIPTION`, authors, license, URLs, and dependency bounds.
- [ ] Review fixture/schema attribution and bundled-file licensing.
- [ ] Run documentation, tests, URL checks, `R CMD check --as-cran`,
  Win-builder, and R-hub checks; resolve or explain every note.
- [ ] Confirm CI on Linux, macOS, and Windows for current, old-release, and
  development R.
- [ ] Set version 0.1.0, finalize release notes and `cran-comments.md`, then
  build and inspect the submission tarball.

**Gate:** The tested source tarball has no errors or warnings, no unexplained
notes, and is ready for CRAN submission.

## Public API Contract

Changing an entry after Stage 0 requires a dated reason in the progress log.
Constructor arguments use `snake_case`; serialization maps them to the
protocol's camelCase names.

| API | Locked signature or contract |
|---|---|
| `RunState` | `RunState(value)`; one of `START`, `RUNNING`, `COMPLETE`, `ABORT`, `FAIL`, or `OTHER` |
| `Run` | `Run(run_id, facets = list())` |
| `Job` | `Job(namespace, name, facets = list())` |
| `Dataset` | `Dataset(namespace, name, facets = list())` |
| `InputDataset` | `InputDataset(namespace, name, facets = list(), input_facets = list())` |
| `OutputDataset` | `OutputDataset(namespace, name, facets = list(), output_facets = list())` |
| `RunEvent` | `RunEvent(run, job, event_type = NULL, event_time = new_event_time(), inputs = list(), outputs = list(), producer = OPENLINEAGE_PRODUCER, schema_url = OPENLINEAGE_RUN_EVENT_SCHEMA_URL)` |
| Serialization | `as_openlineage_list(x)` and `to_openlineage_json(x, pretty = FALSE)` |
| Generic facet | `ol_facet(schema_url, ..., producer = OPENLINEAGE_PRODUCER, deleted = NULL)` |
| Utilities | `new_run_id()` and `new_event_time(time = Sys.time())` |
| Constants | `OPENLINEAGE_SCHEMA_VERSION`, `OPENLINEAGE_SCHEMA_URL`, `OPENLINEAGE_RUN_EVENT_SCHEMA_URL`, and `OPENLINEAGE_PRODUCER` |
| Client | `OpenLineageClient$new(transport = NULL, url = NULL, endpoint = "api/v1/lineage", api_key = NULL, headers = character(), timeout = 5, verify_tls = TRUE, max_retries = 3L, disabled = NULL)`; `emit(event)` returns `event` invisibly after success |
| HTTP transport | `HttpTransport$new(url, endpoint = "api/v1/lineage", api_key = NULL, headers = character(), timeout = 5, verify_tls = TRUE, max_retries = 3L)` |
| Transport contract | `emit(event)` receives a validated `RunEvent` model and returns it invisibly after successful delivery; transport failures inherit from `openlineage_transport_error` |
| Local transports | `AccumulatingTransport$new()`, `ConsoleTransport$new(stream = stdout(), pretty = TRUE)`, and `NoopTransport$new()`; all provide `close()`, and the accumulator provides public `events` plus `clear()` |

All facet constructors accept `producer = OPENLINEAGE_PRODUCER`. Job and
dataset facets also accept `deleted = NULL` where allowed by their schemas.

| Typed facet API | Locked signature excluding common trailing arguments |
|---|---|
| `NominalTimeRunFacet` | `(nominal_start_time, nominal_end_time = NULL)` |
| `ParentRunFacet` | `(run, job, root = NULL)` |
| `SchemaDatasetFacet` | `(fields = list())` |
| `SchemaField` | `(name, type = NULL, description = NULL, ordinal_position = NULL, fields = list())` |
| `DatasourceDatasetFacet` | `(name = NULL, uri = NULL)` |
| `SQLJobFacet` | `(query, dialect = NULL)` |
| `SourceCodeLocationJobFacet` | `(type, url, repo_url = NULL, path = NULL, version = NULL, tag = NULL, branch = NULL, pull_request_number = NULL)` |
| `ErrorMessageRunFacet` | `(message, programming_language, stack_trace = NULL)` |
| `InputStatisticsInputDatasetFacet` | `(row_count = NULL, size = NULL, file_count = NULL)` |
| `OutputStatisticsOutputDatasetFacet` | `(row_count = NULL, size = NULL, file_count = NULL)` |
| `JobTypeJobFacet` | `(processing_type, integration, job_type = NULL, emission_pattern = NULL)` |
| `EmissionPattern` | `(event_trigger, event_content_mode, window_duration = NULL)` |
| `ProcessingEngineRunFacet` | `(version, name = NULL, openlineage_adapter_version = NULL)` |
| Tags | `ol_tag(key, value, source = NULL, field = NULL)` plus `TagsJobFacet(tags = list())`, `TagsRunFacet(tags = list())`, and `TagsDatasetFacet(tags = list())` |

## Wire Contract

- `OPENLINEAGE_SCHEMA_URL` is
  `https://openlineage.io/spec/2-0-2/OpenLineage.json`; run events use its
  `#/$defs/RunEvent` pointer.
- Base events require `eventTime`, `producer`, and `schemaURL`; run events also
  require `run` and `job`. `eventType`, `inputs`, and `outputs` are optional in
  the schema, although constructors default collection fields to empty lists.
- `Run` requires `runId`; `Job` and every dataset require `namespace` and
  `name`; facets require `_producer` and `_schemaURL`.
- Event and nominal times must be RFC 3339/ISO 8601 date-times with a time-zone
  offset. Run IDs accept any valid UUID; their UUID version is not contractual.
- Default facet maps serialize as `{}` and default input/output collections as
  `[]`. Explicit `NULL` optional properties are omitted recursively.
- Object member order is insignificant. Array order is preserved and compared
  as protocol-significant. Wire keys include `eventType`, `eventTime`, `runId`,
  `schemaURL`, `inputFacets`, and `outputFacets` exactly as shown.
- Core models reject unknown properties. `ol_facet()` is the extension point
  for unknown or future facet fields.

## Condition Contract

| Class | Parent | Meaning |
|---|---|---|
| `openlineage_validation_error` | `openlineage_error` | Invalid event, model, facet, UUID, timestamp, or URI |
| `openlineage_config_error` | `openlineage_error` | Missing or conflicting client/transport configuration |
| `openlineage_transport_error` | `openlineage_error` | Delivery failed before an HTTP response was available |
| `openlineage_http_error` | `openlineage_transport_error` | Non-success HTTP response or exhausted HTTP retries |
| `openlineage_auth_error` | `openlineage_http_error` | Non-retryable HTTP 401 or 403 response |
| `openlineage_insecure_tls_warning` | `warning` | TLS verification was explicitly disabled |

## Open Decisions and Blockers

- Package author details are required before Stage 8; the package now uses the
  MIT license.
- Golden fixtures are sufficient for core compatibility in 0.1.0; do not
  bundle the complete upstream schema unless model maintenance demonstrates a
  need for local schema validation or generation.
- No implementation blockers remain for Stage 7.

## Deferred Beyond 0.1.0

Static job/dataset events, YAML configuration, filters, automatic enrichment,
file/composite transports, JWT exchange, asynchronous delivery, gzip, column
lineage, data-quality models, and vendor-specific transports remain out of
scope. Move an item into 0.1.0 only by updating both this file and `roadmap.md`
with the reason and schedule impact.

## Progress Log

### 2026-07-19

- Created the staged implementation tracker from the approved v0.1.0 roadmap.
- Chose contract-first sequencing because wire compatibility is the primary
  release risk and later layers depend on stable serialization behavior.
- Implemented Stage 1 at the user's direction while Stage 0 remains open.
- Added public OpenLineage 2.0.2 constants, `new_run_id()`, and
  `new_event_time()`; the time helper always emits UTC with milliseconds.
- Added internal `cli` errors with `openlineage_error` and
  `openlineage_validation_error` classes.
- Added 17 offline tests, deterministic test helpers, roxygen documentation,
  pkgdown indexing, and NEWS.
- Verification: tests and pkgdown checks pass. `R CMD check` has zero errors;
  its one warning and one note are the known metadata/dependency items above.
- Completed Stage 0 after Stage 1: locked constructor and condition names,
  required fields, collection/null behavior, and JSON comparison semantics.
- Generated `minimal-start.json` and `complete-with-datasets.json` with the
  upstream Python v2 client at commit `667d632b91291700f1b3e3d6342613ba78edbda6`;
  provenance and its Apache-2.0 license are recorded beside the fixtures.
- Added an order-aware semantic JSON expectation and fixture checks. All 28
  tests and the pkgdown check pass; `R CMD check` remains at zero errors with
  only the previously recorded license warning and unused-import note.
- Implemented Stage 2 with S7 core models, strict UUID/state/time/URI and
  dataset-role validation, wire-name conversion, recursive `NULL` omission,
  and deterministic JSON serialization.
- The minimal `START` event matches the Python golden fixture semantically.
  All 80 tests and pkgdown checks pass; `R CMD check` has zero errors and
  warnings, with one expected note for the Stage 5/6 `httr2` and R6 imports.
- Implemented Stage 3 with `ol_facet()` as the extension point and typed run,
  job, dataset, input-statistics, output-statistics, job-type, and tag facets.
- Added role-aware facet-map validation so typed facets can only be attached
  where their OpenLineage schema permits; generic facets remain usable in all
  maps for forward-compatible extensions.
- Covered `START`, `RUNNING`, `COMPLETE`, `ABORT`, `FAIL`, and `OTHER`, plus
  representative validation failures, nested schema fields, parent runs, and
  all typed facet families. The complete dataset event matches the Python
  fixture semantically.
- Declared R 4.1.0 as the minimum version because package style uses the native
  pipe and lambda shorthand. All 142 tests and pkgdown checks pass; `R CMD
  check` has zero errors and warnings, with the expected unused `httr2`/R6
  note pending Stages 5 and 6.
- Implemented Stage 4 with a model-first transport contract: `emit(event)`
  receives a validated `RunEvent` and returns that event invisibly after
  successful delivery. The internal adapter normalizes custom transport
  returns, preserves already classified package errors, and wraps unexpected
  failures as `openlineage_transport_error`.
- Added independent R6 `AccumulatingTransport`, `ConsoleTransport`, and
  `NoopTransport` implementations. The accumulator stores models in order,
  console output supports compact or pretty JSON, and all local transports
  provide synchronous `close()` behavior.
- Added offline coverage for model injection, return visibility, accumulator
  isolation and clearing, console output, no-op emission, invalid
  configuration, and custom/console failures. All 178 tests and pkgdown checks
  pass; `R CMD check` has zero errors and warnings, with one expected `httr2`
  note pending Stage 5.
- Implemented Stage 5 with synchronous JSON `POST` delivery, normalized base
  URLs and endpoints, request timeouts, and explicit TLS verification control.
- Added bearer API-key and custom-header authentication. Conflicting
  `Authorization` sources and custom `Content-Type` values are rejected;
  credential values are redacted in httr2 requests, R6 printing and `str()`,
  and trace-free package conditions.
- Added bounded retries for connection failures and HTTP 429, 500, 502, 503,
  and 504 responses. HTTP 401/403 bypass retries and raise
  `openlineage_auth_error`; other responses use `openlineage_http_error`.
- Added fully offline request, authentication, TLS, retry, failure, and secret
  redaction tests using `httr2::local_mocked_responses()`. All 258 tests and
  pkgdown checks pass; `R CMD check` has zero errors, warnings, and notes.
- Implemented Stage 6 with an R6 `OpenLineageClient` that delegates validated
  `RunEvent` models to injected or automatically configured transports and
  preserves invisible event returns.
- Added deterministic constructor precedence for explicit arguments and the
  four supported environment variables. Disabled mode uses the no-op
  transport, injected transports ignore HTTP environment settings, HTTP
  settings without a URL fail, and otherwise unconfigured clients use the
  console transport.
- Added offline integration coverage for HTTP, console, no-op, and accumulating
  delivery, invalid/conflicting configuration, client-boundary validation,
  and isolation of mutable state and credentials between clients. A dedicated
  test review found and closed the client-validation and environment-only
  partial-configuration gaps. All 306 tests and pkgdown checks pass; `R CMD
  check` has zero errors, warnings, and notes.
