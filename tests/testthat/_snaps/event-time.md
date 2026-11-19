# new_event_time validates its input

    Code
      new_event_time("2026-01-02T03:04:05Z")
    Condition
      Error:
      ! `time` must be a single, non-missing POSIXt value.

---

    Code
      new_event_time(as.POSIXct(NA))
    Condition
      Error:
      ! `time` must be a single, non-missing POSIXt value.

# new_event_time stays within years 0001 to 9999 (#50)

    Code
      new_event_time(year_10000)
    Condition
      Error:
      ! `time` must fall between the years 0001 and 9999.

