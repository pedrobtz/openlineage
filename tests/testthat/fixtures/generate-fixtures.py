"""Generate the golden fixtures all-facets.json and generic-numbers.json.

Run with the OpenLineage Python client 1.52.0, the version of the other
fixtures, from the package root:

    uv venv .venv && uv pip install --python .venv/bin/python \
        "openlineage-python==1.52.0"
    .venv/bin/python -I tests/testthat/fixtures/generate-fixtures.py

The R tests build the same events with the package's constructors and
compare the JSON exactly (tests/testthat/test-golden-fixtures.R).
"""

import json
import pathlib
from typing import ClassVar

import attr
from openlineage.client.event_v2 import (
    InputDataset,
    Job,
    OutputDataset,
    Run,
    RunEvent,
    RunState,
)
from openlineage.client.facet_v2 import (
    column_lineage_dataset,
    datasource_dataset,
    error_message_run,
    input_statistics_input_dataset,
    job_type_job,
    nominal_time_run,
    output_statistics_output_dataset,
    parent_run,
    processing_engine_run,
    schema_dataset,
    source_code_location_job,
    sql_job,
    tags_dataset,
    tags_job,
    tags_run,
)
from openlineage.client.generated.base import RunFacet, set_producer
from openlineage.client.serde import Serde

PRODUCER = "https://github.com/pedrobtz/openlineage"
RUN_ID = "019c0000-0000-7000-8000-000000000001"
PARENT_RUN_ID = "019c0000-0000-7000-8000-000000000002"
ROOT_RUN_ID = "019c0000-0000-7000-8000-000000000003"
HERE = pathlib.Path(__file__).parent


def write(name, value):
    text = json.dumps(json.loads(Serde.to_json(value)), indent=2, sort_keys=True)
    (HERE / name).write_text(text + "\n", encoding="utf-8")


def all_facets_event():
    run_facets = {
        "nominalTime": nominal_time_run.NominalTimeRunFacet(
            nominalStartTime="2026-01-02T03:00:00.000Z",
            nominalEndTime="2026-01-02T04:00:00.000Z",
        ),
        "parent": parent_run.ParentRunFacet(
            run=parent_run.Run(runId=PARENT_RUN_ID),
            job=parent_run.Job(namespace="scheduler", name="parent-dag"),
            root=parent_run.Root(
                run=parent_run.RootRun(runId=ROOT_RUN_ID),
                job=parent_run.RootJob(namespace="scheduler", name="root-dag"),
            ),
        ),
        "errorMessage": error_message_run.ErrorMessageRunFacet(
            message="Query failed",
            programmingLanguage="R",
            stackTrace="Error in f(): failed",
        ),
        "processingEngine": processing_engine_run.ProcessingEngineRunFacet(
            version="4.6.0",
            name="R",
            openlineageAdapterVersion="0.2.0",
        ),
        "tags": tags_run.TagsRunFacet(
            tags=[tags_run.TagsRunFacetFields(key="team", value="data", source="USER")]
        ),
    }
    job_facets = {
        "sql": sql_job.SQLJobFacet(query="SELECT * FROM source", dialect="ansi"),
        "sourceCodeLocation": source_code_location_job.SourceCodeLocationJobFacet(
            type="git",
            url="https://github.com/example/project/blob/main/job.R",
            repoUrl="https://github.com/example/project.git",
            path="job.R",
            version="0123abcd",
            tag="v1.0.0",
            branch="main",
            pullRequestNumber="42",
        ),
        "jobType": job_type_job.JobTypeJobFacet(
            processingType="BATCH",
            integration="R",
            jobType="QUERY",
            emissionPattern=job_type_job.EmissionPattern(
                eventTrigger="PERIODIC",
                eventContentMode="SNAPSHOT",
                windowDuration=300,
            ),
        ),
        "tags": tags_job.TagsJobFacet(
            tags=[tags_job.TagsJobFacetFields(key="environment", value="production")]
        ),
    }
    schema = schema_dataset.SchemaDatasetFacet(
        fields=[
            schema_dataset.SchemaDatasetFacetFields(
                name="id",
                type="INTEGER",
                description="Primary key",
                ordinal_position=1,
            ),
            schema_dataset.SchemaDatasetFacetFields(
                name="address",
                type="STRUCT",
                ordinal_position=2,
                fields=[schema_dataset.SchemaDatasetFacetFields(name="city", type="STRING")],
            ),
        ]
    )
    source = column_lineage_dataset.InputField(
        namespace="postgres://warehouse",
        name="public.source",
        field="id",
        transformations=[
            column_lineage_dataset.Transformation(type="DIRECT", subtype="IDENTITY", masking=False)
        ],
    )
    return RunEvent(
        eventType=RunState.COMPLETE,
        eventTime="2026-01-02T03:05:00.000Z",
        run=Run(runId=RUN_ID, facets=run_facets),
        job=Job(namespace="example", name="all-facets", facets=job_facets),
        inputs=[
            InputDataset(
                namespace="postgres://warehouse",
                name="public.source",
                facets={
                    "schema": schema,
                    "dataSource": datasource_dataset.DatasourceDatasetFacet(
                        name="warehouse", uri="postgres://warehouse"
                    ),
                    "tags": tags_dataset.TagsDatasetFacet(
                        tags=[
                            tags_dataset.TagsDatasetFacetFields(
                                key="pii", value="true", source="USER", field="id"
                            )
                        ]
                    ),
                },
                inputFacets={
                    "inputStatistics": input_statistics_input_dataset.InputStatisticsInputDatasetFacet(
                        rowCount=0, size=3000000000, fileCount=1
                    )
                },
            )
        ],
        outputs=[
            OutputDataset(
                namespace="postgres://warehouse",
                name="analytics.result",
                facets={
                    "columnLineage": column_lineage_dataset.ColumnLineageDatasetFacet(
                        fields={"id": column_lineage_dataset.Fields(inputFields=[source])},
                        dataset=[],
                    )
                },
                outputFacets={
                    "outputStatistics": output_statistics_output_dataset.OutputStatisticsOutputDatasetFacet(
                        rowCount=1234567890123456, size=2**53, fileCount=10**15
                    )
                },
            )
        ],
        producer=PRODUCER,
    )


@attr.define
class NumbersRunFacet(RunFacet):
    """A run facet with float and integer values at the edges of precision."""

    sum: float
    long: float
    two53: int
    big: float
    quadrillion: float
    negative: float
    tiny: float
    _additional_skip_redact: ClassVar[list[str]] = []

    @staticmethod
    def _get_schema() -> str:
        return "https://example.com/NumbersRunFacet.json"


def main():
    set_producer(PRODUCER)
    write("all-facets.json", all_facets_event())
    write(
        "generic-numbers.json",
        NumbersRunFacet(
            sum=0.1 + 0.2,
            long=123456789.123456789,
            two53=2**53,
            big=3e9,
            quadrillion=1e15,
            negative=-2.5,
            tiny=2**-20,
        ),
    )


if __name__ == "__main__":
    main()
