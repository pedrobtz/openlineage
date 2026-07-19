# openlineage 0.0.0.9000

- Added generic and typed facets for common run, job, dataset, input, and
  output metadata, with validation of their placement.
- Added S7 models for run events, runs, jobs, and datasets.
- Added OpenLineage 2.0.2 schema and package producer constants.
- `AccumulatingTransport`, `ConsoleTransport`, and `NoopTransport` support
  offline testing, local inspection, and disabled emission.
- `as_openlineage_list()` and `to_openlineage_json()` provide deterministic
  OpenLineage serialization.
- `ol_facet()` supports custom and future facet schemas without discarding
  extension fields.
- `new_event_time()` formats event timestamps as millisecond-precision UTC.
- `new_run_id()` generates UUID identifiers for OpenLineage runs.
