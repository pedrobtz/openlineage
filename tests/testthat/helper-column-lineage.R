column_lineage_input <- function(name, field, ...) {
  ColumnLineageInputField(
    "postgres://warehouse",
    name,
    field,
    list(...)
  )
}

# Builds a facet from a parsed upstream fixture with the constructors, so
# the comparison checks the constructors and the serializer together.
column_lineage_from_wire <- function(x) {
  input_field <- function(value) {
    transformations <- lapply(value$transformations, function(t) {
      ColumnLineageTransformation(
        t$type,
        subtype = t$subtype,
        description = t$description,
        masking = t$masking
      )
    })
    ColumnLineageInputField(
      value$namespace,
      value$name,
      value$field,
      transformations
    )
  }

  ColumnLineageDatasetFacet(
    fields = lapply(x$fields, \(column) {
      lapply(column$inputFields, input_field)
    }),
    dataset = if (is.null(x$dataset)) NULL else lapply(x$dataset, input_field),
    producer = x$`_producer`
  )
}
