# `openlineage` 0.1.0 Roadmap

**Goal:** Deliver a CRAN-ready R client that covers the primary OpenLineage
workflow: construct a run lifecycle event, serialize it correctly, and emit it
to an HTTP OpenLineage endpoint.

**Architecture:** Use S7 for protocol value models, R6 for the stateful client,
`jsonlite` at the serialization boundary, `httr2` for synchronous HTTP, and
`cli` for user-facing conditions. Support arbitrary facets from day one so
typed coverage can grow without blocking integrations.

**Reference:** The feature inventory is in [`python.md`](python.md). Version
0.1.0 targets OpenLineage schema 2.0.2, the v2 object model used by that
reference, and exposes the schema version and URL as package constants.

---

## Release Principle

Version 0.1.0 is successful if an R user can emit valid `START`, `RUNNING`, and
terminal (`COMPLETE`, `ABORT`, or `FAIL`) events with input/output datasets and
facets. It is not a Python-parity release. The riskiest assumption is wire
compatibility, so golden JSON tests come before convenience features.

## Required for 0.1.0

### Protocol model and serialization

- S7 models for `RunEvent`, `RunState`, `Run`, `Job`, `Dataset`,
  `InputDataset`, and `OutputDataset`.
- Required-field, UUID, event-state, and ISO 8601 timestamp validation.
- Default `producer` and `schemaURL`, with explicit overrides.
- `new_run_id()` and a UTC event-time helper.
- Deterministic conversion to named R lists and JSON: preserve OpenLineage
  camelCase keys, unwrap enums, omit `NULL`, and retain empty arrays where the
  schema requires them.
- A generic `ol_facet(schema_url, ..., producer = NULL)` escape hatch.
- Typed high-use facets: nominal time, parent run, dataset schema, data source,
  SQL, source-code location, error message, input/output statistics, job type,
  processing engine, and job/run/dataset tags.

### Client and transports

- `OpenLineageClient` R6 object with `emit()` and injectable transport.
- Synchronous HTTP transport targeting `api/v1/lineage`, with URL validation,
  timeout, TLS verification, custom headers, API-key bearer authentication,
  and bounded retries for transient failures.
- Console transport for examples/debugging and no-op transport for disabling
  emission; a small accumulating transport for tests.
- Direct constructor configuration plus `OPENLINEAGE_URL`,
  `OPENLINEAGE_ENDPOINT`, `OPENLINEAGE_API_KEY`, and `OPENLINEAGE_DISABLED`.
- Clear `cli` errors that never print authentication material.

### Authentication design

Authentication belongs to the HTTP transport, never to an OpenLineage event or
facet. The 0.1.0 client constructor accepts `api_key`, `headers`, `verify_tls`,
and `timeout`; explicit arguments take precedence over environment variables.
If `api_key` is absent, resolve `OPENLINEAGE_API_KEY`; if both are absent, send
an unauthenticated request.

- Apply API keys with `httr2::req_auth_bearer_token()`, producing
  `Authorization: Bearer <token>`.
- Accept a named character vector of custom headers for tenant, proxy, or
  backend-specific authentication. Permit a custom `Authorization` header only
  when no API key resolves; otherwise fail before sending the request.
- Default `verify_tls = TRUE`. Disabling verification must be explicit and
  should emit a warning.
- Keep credentials in private transport state. Client/transport printing,
  `cli` conditions, debug output, and serialized events must never reveal them.
- Treat HTTP 401 and 403 as non-retryable `openlineage_auth_error` conditions;
  include the endpoint and status, but never response headers or credentials.
- Isolate request authentication behind an internal request-mutating function
  so JWT/token-refresh providers can be added later without changing event or
  transport contracts. JWT exchange and caching remain outside 0.1.0.

### User experience and quality

- README quick start and one vignette covering `START` through `COMPLETE`,
  inputs/outputs, facets, configuration, and failure handling.
- Roxygen reference with `@return` and executable offline examples for every
  export.
- Fully offline testthat suite: S7 validation, golden JSON, lifecycle events,
  `httr2::local_mocked_responses()`, auth precedence/header conflicts, 401/403
  handling, retry/error behavior, and secret redaction.
- Cross-platform R CMD check with no errors, warnings, or unexplained notes.

## Complete Feature Disposition

### Events, client behavior, and utilities

| Python capability | Decision | R direction |
|---|---|---|
| V2 `RunEvent` lifecycle and core run/job/dataset models | **0.1.0** | Primary public model. |
| Generic facets and protocol extension fields | **0.1.0** | Avoid blocking users on typed coverage. |
| Serialization, null removal, enum conversion | **0.1.0** | Central, deterministic serializer. |
| Random run UUID and UTC time helpers | **0.1.0** | Small R-native helpers. |
| Producer and schema URL defaults | **0.1.0** | Per event/client, not global mutable state. |
| Static `JobEvent` and `DatasetEvent` | **Later** | Add after run-event stability. |
| YAML and nested dynamic-environment configuration | **Later** | Constructor and simple environment variables are enough initially. |
| Event filters | **Later** | Exact/regex job filtering is optional policy. |
| Automatic environment/tag facet enrichment | **Later** | Typed facets remain manually usable in 0.1.0. |
| Git/CI source-location autodetection | **Later** | Explicit facet first; autodetection has platform edge cases. |
| Dataset naming helpers for individual databases/clouds | **Later** | Add from demonstrated R integration needs. |
| Redaction framework | **Later** | Protect transport/auth errors in 0.1.0; general field redaction needs a contract. |
| Deprecated v1 events/facets | **Not planned** | A new R package has no legacy compatibility obligation. |
| Python dynamic imports and class registration by string | **Not planned** | Prefer R functions and explicit transport injection. |
| Python typing marker and exact warning/logging behavior | **Not applicable** | Use R documentation, S7 validation, and `cli` conditions. |

### Transports

| Transport capability | Decision | Reason |
|---|---|---|
| Synchronous HTTP | **0.1.0** | Main OpenLineage delivery path. |
| Console and no-op | **0.1.0** | Offline examples, debugging, and disabling. |
| File transport | **Later** | Useful for diagnostics but not required for server delivery. |
| Composite/failover transport | **Later** | Requires stable transport and failure semantics first. |
| Gzip HTTP bodies | **Later** | Optimization, not baseline interoperability. |
| JWT token exchange/cache | **Later** | API-key/custom-header auth covers the first release. |
| Asynchronous HTTP and event ordering queue | **Later** | Significant concurrency and shutdown complexity in R. |
| Transform transport and namespace transformer | **Later** | Users can transform models before `emit()` initially. |
| Kafka | **Later, demand-driven** | Adds a heavy system dependency and CRAN complexity. |
| AWS MSK IAM | **Not planned initially** | Only relevant if Kafka demand is proven. |
| Amazon DataZone | **Not planned initially** | Vendor-specific SDK surface. |
| Google Cloud Data Catalog Lineage | **Not planned initially** | Vendor-specific SDK surface. |
| Datadog intake | **Not planned initially** | Standard HTTP may already be sufficient. |
| Remote `fsspec`-style filesystems | **Not planned** | Python-specific abstraction; use R ecosystem integrations if needed. |

### Typed facets

All untyped facets remain sendable through `ol_facet()` in 0.1.0.

| Facet family | Decision |
|---|---|
| Nominal time, parent run, schema, data source, SQL | **Typed in 0.1.0** |
| Source-code location, error message, input/output statistics | **Typed in 0.1.0** |
| Job type, processing engine, job/run/dataset tags | **Typed in 0.1.0** |
| Column lineage | **Later** — valuable but has a complex nested model. |
| Data-quality assertions and both metrics variants | **Later** |
| Dataset type, version, catalog, hierarchy, storage, and symlinks | **Later** |
| Dataset/job documentation and ownership | **Later** |
| Lifecycle state change and base subset conditions | **Later** |
| Environment variables, execution parameters, and external query | **Later** |
| Extraction errors, job dependencies, source code, and test results | **Later** |
| Full JSON-Schema-to-R code generator | **Evaluate later** | Manual core models are lower risk; generate only if schema maintenance becomes costly. |

## Post-0.1 Sequence

- **0.2 — Protocol breadth:** static job/dataset events, column lineage and
  data-quality models, more typed facets, YAML configuration, filters, automatic
  enrichment, and file/composite transports.
- **0.3 — Advanced delivery:** gzip, JWT, asynchronous HTTP, transformation,
  source-control discovery, and dataset naming helpers.
- **Demand-driven extensions:** Kafka first if requested, then MSK IAM or
  vendor-specific cloud transports only with a committed user and maintainer.

## Features We May Never Need

Do not port deprecated v1 models, Python typing markers, dynamic class imports,
or Python-specific filesystem/Airflow compatibility. A schema generator is
optional: adopt one only if maintaining typed S7 facets manually becomes a
measurable burden. Datadog, Amazon DataZone, Google Cloud Data Catalog Lineage,
and MSK IAM integrations should remain external or unimplemented unless normal
HTTP cannot serve the use case. This avoids permanent dependencies and support
obligations for features without demonstrated R demand.

## Delivery Milestones

### M1 — Protocol contract

- [ ] Record schema 2.0.2 and the forward-compatibility policy in package docs.
- [ ] Implement core S7 models, validation, list conversion, and golden JSON.
- [ ] Implement generic facets and the selected typed facets.

### M2 — Emission path

- [ ] Define the transport contract and offline accumulating transport.
- [ ] Implement console, no-op, and synchronous HTTP transports.
- [ ] Implement bearer/custom-header authentication, TLS defaults, credential
  redaction, and non-retryable 401/403 conditions.
- [ ] Implement the R6 client, configuration precedence, and transport errors.

### M3 — Public usability

- [ ] Document every export and add offline examples.
- [ ] Add README quick start, lifecycle vignette, pkgdown index, and `NEWS.md`.
- [ ] Test compatibility fixtures, mocked requests, retries, and failure paths.

### M4 — CRAN release

- [ ] Replace placeholder `DESCRIPTION` metadata; use an informative Title and
  Description, real authors, `[cph]`, HTTPS URLs, and a final license.
- [ ] Add `cran-comments.md`; review bundled fixture/schema licensing and add
  attribution where required.
- [ ] Ensure developer-only files are handled intentionally by `.Rbuildignore`.
- [ ] Run `devtools::document()`, `devtools::test()`,
  `urlchecker::url_check()`, and `devtools::check()`.
- [ ] Run `R CMD check --as-cran` on the built tarball, plus Win-builder and
  R-hub checks; explain any unavoidable notes.
- [ ] Confirm tests/examples make no network calls and complete quickly, as
  required by the [CRAN repository policy](https://cran.r-project.org/web/packages/policies.html)
  and [submission checklist](https://cran.r-project.org/web/packages/submission_checklist.html).
- [ ] Set `Version: 0.1.0`, update release notes, recheck CRAN package-name
  availability, and submit the tested tarball.

## Definition of Done

Version 0.1.0 is complete when two offline golden fixtures and a mocked HTTP
test prove that equivalent R and Python core events produce the same semantic
JSON; the documented lifecycle example runs without credentials; public APIs
are stable enough for one release cycle; and CRAN checks pass on current,
old-release, and development R across Linux, macOS, and Windows.
