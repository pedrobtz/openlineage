# openlineage (development version)

# openlineage 0.2.0

## Breaking changes

* `ol_facet()` takes `schema_url` after `...`, so a field such as `schema`
  is no longer matched to it partially. Passing the URL first, or as
  `schema_url =`, works as before (#29).

* `HttpTransport` no longer follows redirects. A 3xx response raises an
  `openlineage_http_error` carrying its `status_code`, instead of resending
  the event without its body, or a credential header to another host (#21).

* Values that were written silently wrong are now an
  `openlineage_validation_error`:
  * in `ol_facet()`: infinite numbers, complex and raw vectors, named atomic
    vectors, lists with repeated or empty names, classed lists, other classed
    objects, and `Date` values that are infinite or outside the years 0001 to
    9999 (#30, #64, #65);
  * anywhere: strings that are not valid UTF-8 (#31, #63);
  * integer fields above 2^53 and negative input and output statistics
    counts (#22, #46).

* `HttpTransport$new()` checks that `timeout` is between 0.001 and 2147483
  seconds (#27). It rejects a `url` or `endpoint` with a query or fragment
  marker, whitespace, control characters, or `.` and `..` segments, also
  when percent-encoded (#28). It rejects `headers` that set
  `Content-Length`, `Transfer-Encoding`, `Host` or another header that
  frames the request (#62).

* Passing `transport` together with HTTP arguments is an error also when the
  client is disabled (#34).

* openlineage now requires httr2 1.2.0 or later (#70).

## New features

* New `ColumnLineageDatasetFacet()`, with `ColumnLineageInputField()` and
  `ColumnLineageTransformation()`, for column-level lineage (facet schema
  1-2-0). Output matches the OpenLineage Python client (#16).

* New `OpenLineageClient$close()`, which closes the client's transport and
  raises an `openlineage_transport_error` if that fails (#47, #66).

* `POSIXct` and `POSIXlt` values in `ol_facet()` are written as event times.
  The mapping of R values to JSON is documented in `?ol_facet` (#30, #51,
  #65).

* `event@event_type <- "COMPLETE"` converts the string to a `RunState`, and
  `x@facets <- list()` is accepted and written as `{}` (#25).

## Bug fixes

* Numbers are serialized without loss: integer-valued doubles up to 2^53
  exactly, other doubles with the fewest digits that read back as the same
  value, as the Python client does (#22).

* `new_event_time()` no longer emits one millisecond low for about half of
  all times, and raises an `openlineage_validation_error` outside the years
  0001 to 9999 (#23, #50).

* Condition messages show user-supplied text, such as column names with
  braces, literally instead of interpolating it (#24).

* Assigning a property with `@<-` runs the same checks as the constructor
  and raises `openlineage_validation_error`: dataset roles in
  `RunEvent@inputs` and `@outputs`, the tag `field` restriction, and
  `ColumnLineageDatasetFacet@fields` (#25).

* A 429 or 503 response with a `Retry-After` date and no `Date` header is
  retried, instead of failing as if no response had arrived. `Retry-After`
  accepts seconds and all three HTTP-date forms, and an unreadable value
  falls back to back-off without a warning (#26, #49, #61, #67).

* A connection failure carries the curl error, with no credentials, as
  `parent` (#26).

* Non-ASCII text is sent as UTF-8 in every locale, including `LC_ALL=C`
  (#63).

* `?HttpTransport` documents the retry delays and that delivery is at least
  once (#48).

# openlineage 0.1.0

* initial version
