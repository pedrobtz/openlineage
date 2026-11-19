# Changelog

## openlineage (development version)

- New
  [`ColumnLineageDatasetFacet()`](https://pedrobtz.github.io/openlineage/dev/reference/column_lineage_facets.md),
  with
  [`ColumnLineageInputField()`](https://pedrobtz.github.io/openlineage/dev/reference/column_lineage_facets.md)
  and
  [`ColumnLineageTransformation()`](https://pedrobtz.github.io/openlineage/dev/reference/column_lineage_facets.md),
  for column-level lineage (facet schema 1-2-0). Output matches the
  OpenLineage Python client
  ([\#16](https://github.com/pedrobtz/openlineage/issues/16)).

- New `OpenLineageClient$close()`, which closes the client’s transport
  ([\#47](https://github.com/pedrobtz/openlineage/issues/47)).

- `HttpTransport` no longer follows redirects. A 3xx response raises an
  `openlineage_http_error` carrying its `status_code`, instead of
  resending the event without its body, or a credential header to
  another host
  ([\#21](https://github.com/pedrobtz/openlineage/issues/21)).

- Numbers are serialized without loss: integer-valued doubles up to 2^53
  exactly, other doubles with the fewest digits that read back as the
  same value, as the Python client does. Integer fields reject values
  above 2^53
  ([\#22](https://github.com/pedrobtz/openlineage/issues/22)).

- [`new_event_time()`](https://pedrobtz.github.io/openlineage/dev/reference/new_event_time.md)
  no longer emits one millisecond low for about half of all times, and
  raises an `openlineage_validation_error` outside the years 0001 to
  9999 ([\#23](https://github.com/pedrobtz/openlineage/issues/23),
  [\#50](https://github.com/pedrobtz/openlineage/issues/50)).

- Condition messages show user-supplied text, such as column names with
  braces, literally instead of interpolating it
  ([\#24](https://github.com/pedrobtz/openlineage/issues/24)).

- Assigning a property with `@<-` runs the same checks as the
  constructor and raises `openlineage_validation_error`: dataset roles
  in `RunEvent@inputs` and `@outputs`, the tag `field` restriction, and
  `ColumnLineageDatasetFacet@fields`. `x@facets <- list()` is accepted
  and written as [`{}`](https://rdrr.io/r/base/Paren.html), and
  `event@event_type <- "COMPLETE"` converts the string to a `RunState`
  ([\#25](https://github.com/pedrobtz/openlineage/issues/25)).

- HTTP transport failures keep their cause: a response with an
  unreadable or date-valued `Retry-After` is retried with back-off
  instead of failing, without a warning, and a connection failure
  carries the curl error, with no credentials, as `parent`
  ([\#26](https://github.com/pedrobtz/openlineage/issues/26),
  [\#49](https://github.com/pedrobtz/openlineage/issues/49)).

- `HttpTransport$new()` checks that `timeout` is between 0.001 and
  2147483 seconds
  ([\#27](https://github.com/pedrobtz/openlineage/issues/27)), and
  rejects a `url` or `endpoint` with a query or fragment marker,
  whitespace, control characters, or `.` and `..` segments, also when
  percent-encoded
  ([\#28](https://github.com/pedrobtz/openlineage/issues/28)).

- [`ol_facet()`](https://pedrobtz.github.io/openlineage/dev/reference/ol_facet.md)
  takes `schema_url` after `...`, so a field such as `schema` is no
  longer matched to it partially. Positional use is unchanged
  ([\#29](https://github.com/pedrobtz/openlineage/issues/29)).

- Values in
  [`ol_facet()`](https://pedrobtz.github.io/openlineage/dev/reference/ol_facet.md)
  that jsonlite would change silently now raise an
  `openlineage_validation_error`: infinite numbers, complex and raw
  vectors, named atomic vectors, lists with repeated or empty names, and
  other classed objects. `POSIXct` values are written as event times.
  The mapping is documented in
  [`?ol_facet`](https://pedrobtz.github.io/openlineage/dev/reference/ol_facet.md)
  ([\#30](https://github.com/pedrobtz/openlineage/issues/30),
  [\#51](https://github.com/pedrobtz/openlineage/issues/51)).

- Strings that are not valid UTF-8 are rejected before serialization
  ([\#31](https://github.com/pedrobtz/openlineage/issues/31)).

- Passing `transport` together with HTTP arguments is an error also when
  the client is disabled
  ([\#34](https://github.com/pedrobtz/openlineage/issues/34)).

- Input and output statistics counts must be non-negative
  ([\#46](https://github.com/pedrobtz/openlineage/issues/46)).

- [`?HttpTransport`](https://pedrobtz.github.io/openlineage/dev/reference/HttpTransport.md)
  documents the retry delays and that delivery is at least once
  ([\#48](https://github.com/pedrobtz/openlineage/issues/48)).

## openlineage 0.1.0

CRAN release: 2026-07-30

- initial version
