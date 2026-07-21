# Golden fixture provenance

The JSON files in this directory were generated with the OpenLineage Python
client's v2 classes and `Serde.to_json()` at upstream commit
`667d632b91291700f1b3e3d6342613ba78edbda6` (client version 1.52.0):

- `minimal-start.json` uses `RunEvent`, `Run`, and `Job`.
- `complete-with-datasets.json` additionally uses input/output datasets and
  nominal-time, SQL, schema, input-statistics, and output-statistics facets.

The generating implementation is in `client/python/src/openlineage/client/`
and its relevant test pattern is
`client/python/tests/test_facet_v2.py::test_full_core_event_serializes_properly`
in the OpenLineage repository. OpenLineage is licensed under Apache License
2.0. Fixture values were chosen for this R package; they are not server output
and require no network access.
