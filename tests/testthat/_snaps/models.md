# core model validation raises stable conditions

    Code
      RunState("UNKNOWN")
    Condition
      Error:
      ! `value` must be one of `START`, `RUNNING`, `COMPLETE`, `ABORT`, `FAIL`, or `OTHER`.

---

    Code
      Run("not-a-uuid")
    Condition
      Error:
      ! `run_id` must be a valid UUID.

---

    Code
      Job("", "task")
    Condition
      Error:
      ! `namespace` must not be empty.

---

    Code
      RunEvent(Run(fixture_run_id()), Job("example", "task"), event_type = "START",
      event_time = "2026-01-02 03:04:05")
    Condition
      Error:
      ! `event_time` must be an RFC 3339 date-time with a time-zone offset.

---

    Code
      RunEvent(Run(fixture_run_id()), Job("example", "task"), event_time = new_event_time(
        fixture_event_time()), producer = "not a uri")
    Condition
      Error:
      ! `producer` must be a valid URI.

# RunEvent enforces dataset roles

    Code
      RunEvent(Run(fixture_run_id()), Job("example", "task"), event_time = new_event_time(
        fixture_event_time()), inputs = list(Dataset("example", "untyped")))
    Condition
      Error in `RunEvent()`:
      ! Every element of `inputs` must be an `InputDataset` object.

---

    Code
      RunEvent(Run(fixture_run_id()), Job("example", "task"), event_time = new_event_time(
        fixture_event_time()), outputs = list(InputDataset("example", "wrong-role")))
    Condition
      Error in `RunEvent()`:
      ! Every element of `outputs` must be an `OutputDataset` object.

# facet maps require unique non-empty names

    Code
      Run(fixture_run_id(), facets = list("value"))
    Condition
      Error:
      ! `facets` must have unique, non-empty names.

---

    Code
      Job("example", "task", facets = list(a = 1, a = 2))
    Condition
      Error:
      ! `facets` must have unique, non-empty names.

