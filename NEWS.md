# openlineage 0.1.0

- Added an offline quick start and lifecycle vignette covering datasets,
  facets, configuration, authentication, and condition handling.
- Added generic and typed facets for common run, job, dataset, input, and
  output metadata, with validation of their placement.
- Added S7 models for run events, runs, jobs, and datasets.
- Added OpenLineage 2.0.2 schema and package producer constants.
- `AccumulatingTransport`, `ConsoleTransport`, and `NoopTransport` support
  offline testing, local inspection, and disabled emission.
- `as_openlineage_list()` and `to_openlineage_json()` provide deterministic
  OpenLineage serialization.
- `HttpTransport` provides synchronous delivery, bearer or custom-header
  authentication, bounded retries, timeouts, and configurable TLS verification.
- `OpenLineageClient` coordinates injected, HTTP, console, and disabled
  transports with explicit-over-environment configuration precedence.
- `ol_facet()` supports custom and future facet schemas without discarding
  extension fields.
- `new_event_time()` formats event timestamps as millisecond-precision UTC.
- `new_run_id()` generates UUID identifiers for OpenLineage runs.
