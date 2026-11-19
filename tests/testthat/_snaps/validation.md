# scalar character validation has stable errors

    Code
      .ol_validate_scalar_character("", "name")
    Condition
      Error:
      ! `name` must not be empty.

# strings that are not valid UTF-8 are rejected (#31)

    Code
      Job("ns", invalid)
    Condition
      Error:
      ! `name` must be valid UTF-8 text.

