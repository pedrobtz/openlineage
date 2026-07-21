# Package index

## Overview

- [`openlineage`](https://pedrobtz.github.io/openlineage/reference/openlineage-package.md)
  [`openlineage-package`](https://pedrobtz.github.io/openlineage/reference/openlineage-package.md)
  : Create and Emit OpenLineage Events

## Events and models

- [`RunEvent()`](https://pedrobtz.github.io/openlineage/reference/RunEvent.md)
  : OpenLineage run event
- [`RunState()`](https://pedrobtz.github.io/openlineage/reference/RunState.md)
  : OpenLineage run state
- [`Run()`](https://pedrobtz.github.io/openlineage/reference/Run.md) :
  OpenLineage run
- [`Job()`](https://pedrobtz.github.io/openlineage/reference/Job.md) :
  OpenLineage job
- [`Dataset()`](https://pedrobtz.github.io/openlineage/reference/datasets.md)
  [`InputDataset()`](https://pedrobtz.github.io/openlineage/reference/datasets.md)
  [`OutputDataset()`](https://pedrobtz.github.io/openlineage/reference/datasets.md)
  : OpenLineage datasets

## Facets

- [`ol_facet()`](https://pedrobtz.github.io/openlineage/reference/ol_facet.md)
  : Create a generic OpenLineage facet
- [`NominalTimeRunFacet()`](https://pedrobtz.github.io/openlineage/reference/run_facets.md)
  [`ParentRunFacet()`](https://pedrobtz.github.io/openlineage/reference/run_facets.md)
  [`ErrorMessageRunFacet()`](https://pedrobtz.github.io/openlineage/reference/run_facets.md)
  [`ProcessingEngineRunFacet()`](https://pedrobtz.github.io/openlineage/reference/run_facets.md)
  : Typed run facets
- [`SQLJobFacet()`](https://pedrobtz.github.io/openlineage/reference/job_facets.md)
  [`SourceCodeLocationJobFacet()`](https://pedrobtz.github.io/openlineage/reference/job_facets.md)
  [`EmissionPattern()`](https://pedrobtz.github.io/openlineage/reference/job_facets.md)
  [`JobTypeJobFacet()`](https://pedrobtz.github.io/openlineage/reference/job_facets.md)
  : Typed job facets
- [`SchemaField()`](https://pedrobtz.github.io/openlineage/reference/dataset_facets.md)
  [`SchemaDatasetFacet()`](https://pedrobtz.github.io/openlineage/reference/dataset_facets.md)
  [`DatasourceDatasetFacet()`](https://pedrobtz.github.io/openlineage/reference/dataset_facets.md)
  : Typed dataset facets
- [`InputStatisticsInputDatasetFacet()`](https://pedrobtz.github.io/openlineage/reference/io_statistics_facets.md)
  [`OutputStatisticsOutputDatasetFacet()`](https://pedrobtz.github.io/openlineage/reference/io_statistics_facets.md)
  : Input and output statistics facets
- [`ol_tag()`](https://pedrobtz.github.io/openlineage/reference/ol_tag.md)
  : Create an OpenLineage tag
- [`TagsJobFacet()`](https://pedrobtz.github.io/openlineage/reference/tags_facets.md)
  [`TagsRunFacet()`](https://pedrobtz.github.io/openlineage/reference/tags_facets.md)
  [`TagsDatasetFacet()`](https://pedrobtz.github.io/openlineage/reference/tags_facets.md)
  : Typed tags facets

## Serialization

- [`as_openlineage_list()`](https://pedrobtz.github.io/openlineage/reference/as_openlineage_list.md)
  : Convert an OpenLineage value to its wire representation
- [`to_openlineage_json()`](https://pedrobtz.github.io/openlineage/reference/to_openlineage_json.md)
  : Serialize an OpenLineage value to JSON

## Client and transports

- [`OpenLineageClient`](https://pedrobtz.github.io/openlineage/reference/OpenLineageClient.md)
  : OpenLineage client
- [`local_transports`](https://pedrobtz.github.io/openlineage/reference/local_transports.md)
  [`AccumulatingTransport`](https://pedrobtz.github.io/openlineage/reference/local_transports.md)
  [`ConsoleTransport`](https://pedrobtz.github.io/openlineage/reference/local_transports.md)
  [`NoopTransport`](https://pedrobtz.github.io/openlineage/reference/local_transports.md)
  : Local OpenLineage transports
- [`HttpTransport`](https://pedrobtz.github.io/openlineage/reference/HttpTransport.md)
  : Synchronous HTTP transport

## Event utilities

- [`new_run_id()`](https://pedrobtz.github.io/openlineage/reference/new_run_id.md)
  : Generate a run identifier
- [`new_event_time()`](https://pedrobtz.github.io/openlineage/reference/new_event_time.md)
  : Format an OpenLineage event time
- [`OPENLINEAGE_SCHEMA_VERSION`](https://pedrobtz.github.io/openlineage/reference/openlineage_constants.md)
  [`OPENLINEAGE_SCHEMA_URL`](https://pedrobtz.github.io/openlineage/reference/openlineage_constants.md)
  [`OPENLINEAGE_RUN_EVENT_SCHEMA_URL`](https://pedrobtz.github.io/openlineage/reference/openlineage_constants.md)
  [`OPENLINEAGE_PRODUCER`](https://pedrobtz.github.io/openlineage/reference/openlineage_constants.md)
  : OpenLineage protocol constants
