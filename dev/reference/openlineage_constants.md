# OpenLineage protocol constants

Constants used by `openlineage` when constructing OpenLineage events.
`OPENLINEAGE_SCHEMA_URL` identifies the schema document, while
`OPENLINEAGE_RUN_EVENT_SCHEMA_URL` identifies its `RunEvent` definition.

## Usage

``` r
OPENLINEAGE_SCHEMA_VERSION

OPENLINEAGE_SCHEMA_URL

OPENLINEAGE_RUN_EVENT_SCHEMA_URL

OPENLINEAGE_PRODUCER
```

## Format

Character scalars.

## Examples

``` r
OPENLINEAGE_SCHEMA_VERSION
#> [1] "2.0.2"
OPENLINEAGE_SCHEMA_URL
#> [1] "https://openlineage.io/spec/2-0-2/OpenLineage.json"
OPENLINEAGE_RUN_EVENT_SCHEMA_URL
#> [1] "https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent"
OPENLINEAGE_PRODUCER
#> [1] "https://github.com/pedrobtz/openlineage"
```
