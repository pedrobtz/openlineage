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

`column-lineage-facet.json` was generated the same way with client version
1.52.0, from `facet_v2.column_lineage_dataset`, and holds a single
`ColumnLineageDatasetFacet`: output columns with direct transformations, one
with an empty `inputFields`, and dataset-level input fields with and without
transformations.

`upstream-column-lineage-1.json` and `upstream-column-lineage-2.json` are
copied unchanged from `spec/tests/ColumnLineageDatasetFacet/1.json` and
`2.json` at OpenLineage commit `253c006b60f947a031b60ff2c177712e8243c009`.
Each wraps the facet under the key `columnLineage`. The first carries the
deprecated `transformationDescription` and `transformationType` properties
and a 1-1-0 schema URL, which the tests remove or rewrite before comparing.

`all-facets.json` and `generic-numbers.json` were generated with client
version 1.52.0 by `generate-fixtures.py` in this directory, which records how
to run it. `all-facets.json` is one `COMPLETE` event carrying every typed
facet the package implements, including `ParentRunFacet` with `root`,
`JobTypeJobFacet` with an emission pattern, the three tags facets and
statistics counts above 2^31 and up to 2^53. `generic-numbers.json` is a
custom run facet whose float and integer values sit at the edges of double
precision (`0.1 + 0.2`, `2^53`, `3e9`, `1e15`), written by Python's `repr()`.
