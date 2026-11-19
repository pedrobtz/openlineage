# column lineage validation errors are stable

    Code
      ColumnLineageDatasetFacet(list(list()))
    Condition
      Error:
      ! `fields` must have unique, non-empty names.
    Code
      ColumnLineageDatasetFacet(list(a = NULL))
    Condition
      Error:
      ! `fields$a` must be an unnamed list, not `NULL`.
    Code
      ColumnLineageDatasetFacet(list(a = list("x")))
    Condition
      Error:
      ! Every element of `fields$a` must be a `ColumnLineageInputField` object.

# braces in column names are text, not code (#24)

    Code
      ColumnLineageDatasetFacet(list(`{1+1}` = NULL))
    Condition
      Error:
      ! `fields${1+1}` must be an unnamed list, not `NULL`.

