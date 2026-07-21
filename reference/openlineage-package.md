# Create and Emit OpenLineage Events

Build validated OpenLineage 2.0.2 run events, serialize them to the
protocol wire format, and emit them through local or synchronous HTTP
transports.

## Main workflow

Create a [Run](https://pedrobtz.github.io/openlineage/reference/Run.md),
[Job](https://pedrobtz.github.io/openlineage/reference/Job.md), and
optional input/output datasets, then combine them in a
[RunEvent](https://pedrobtz.github.io/openlineage/reference/RunEvent.md).
An
[OpenLineageClient](https://pedrobtz.github.io/openlineage/reference/OpenLineageClient.md)
emits the event through an injected transport or through HTTP configured
by constructor arguments or environment variables.

## Facets and extensions

Typed facet constructors cover common metadata. Use
[ol_facet](https://pedrobtz.github.io/openlineage/reference/ol_facet.md)
to attach a facet schema that does not yet have a typed R constructor.

## See also

[OpenLineageClient](https://pedrobtz.github.io/openlineage/reference/OpenLineageClient.md),
[RunEvent](https://pedrobtz.github.io/openlineage/reference/RunEvent.md),
[local_transports](https://pedrobtz.github.io/openlineage/reference/local_transports.md),
[HttpTransport](https://pedrobtz.github.io/openlineage/reference/HttpTransport.md)

## Author

**Maintainer**: Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

Authors:

- Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]
