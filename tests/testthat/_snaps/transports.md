# transport configuration and events are validated

    Code
      .ol_transport_emit(list(), transport_test_event())
    Condition
      Error:
      ! `transport` must be an R6 object with an `emit(event)` method.

---

    Code
      NoopTransport$new()$emit("serialized JSON")
    Condition
      Error:
      ! `event` must be a `RunEvent` object.

---

    Code
      ConsoleTransport$new(stdout(), pretty = 1)
    Condition
      Error in `ConsoleTransport$new()`:
      ! `pretty` must be `TRUE` or `FALSE`.

---

    Code
      console_with_closed_stream("initialize")
    Condition
      Error in `ConsoleTransport$new()`:
      ! `stream` must be an open, writable connection.

# transport failures have a stable condition class

    Code
      .ol_transport_emit(transport, transport_test_event())
    Condition
      Error:
      ! Transport failed to emit the OpenLineage event.
      Caused by error:
      ! offline transport failure

# console write failures are transport errors

    Code
      console_with_closed_stream("emit")
    Condition
      Error in `console_with_closed_stream()`:
      ! Console transport failed to write the OpenLineage event.
      Caused by error in `writeLines()`:
      ! invalid connection

