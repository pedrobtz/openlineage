test_that("column lineage matches the Python client fixture", {
  identity <- ColumnLineageTransformation("DIRECT", "IDENTITY", masking = FALSE)
  hashed <- ColumnLineageTransformation(
    "DIRECT",
    "TRANSFORMATION",
    "sha256(email)",
    TRUE
  )
  filter <- ColumnLineageTransformation("INDIRECT", "FILTER", "WHERE active")

  facet <- ColumnLineageDatasetFacet(
    fields = list(
      customer_id = list(column_lineage_input(
        "public.customers",
        "id",
        identity
      )),
      email_hash = list(column_lineage_input(
        "public.customers",
        "email",
        hashed
      )),
      loaded_at = list()
    ),
    dataset = list(
      column_lineage_input("public.customers", "active", filter),
      column_lineage_input("public.orders", "customer_id")
    )
  )

  expect_json_semantically_equal(
    to_openlineage_json(facet),
    read_json_fixture("column-lineage-facet.json")
  )
})

test_that("column lineage reproduces the upstream spec fixtures", {
  second <- read_json_fixture("upstream-column-lineage-2.json")$columnLineage
  expect_json_semantically_equal(
    to_openlineage_json(column_lineage_from_wire(second)),
    second
  )

  # The first fixture predates 1-2-0: drop the deprecated per-column
  # properties and take the current schema URL before comparing.
  first <- read_json_fixture("upstream-column-lineage-1.json")$columnLineage
  first$fields <- lapply(first$fields, \(column) column["inputFields"])
  first$`_schemaURL` <- paste0(
    "https://openlineage.io/spec/facets/1-2-0/",
    "ColumnLineageDatasetFacet.json#/$defs/ColumnLineageDatasetFacet"
  )
  facet <- column_lineage_from_wire(first)
  facet@dataset <- NULL
  expect_json_semantically_equal(to_openlineage_json(facet), first)
  expect_identical(
    names(as_openlineage_list(facet)$fields),
    c("NAME", "AMOUNT_OFF", "STARTS_AT", "ENDS_AT")
  )
})

test_that("fields serializes as a JSON object for zero and one columns", {
  empty <- ColumnLineageDatasetFacet()
  one <- ColumnLineageDatasetFacet(list(id = list()))

  expect_match(to_openlineage_json(empty), '"fields":{}', fixed = TRUE)
  expect_match(to_openlineage_json(empty), '"dataset":[]', fixed = TRUE)
  expect_match(
    to_openlineage_json(one),
    '"fields":{"id":{"inputFields":[]}}',
    fixed = TRUE
  )
  expect_identical(
    as_openlineage_list(ColumnLineageDatasetFacet(dataset = NULL))$dataset,
    NULL
  )
})

test_that("column lineage nests under an output dataset", {
  facet <- ColumnLineageDatasetFacet(
    list(id = list(column_lineage_input("public.source", "id")))
  )
  dataset <- OutputDataset(
    "postgres://warehouse",
    "analytics.result",
    facets = list(columnLineage = facet)
  )

  value <- as_openlineage_list(dataset)$facets$columnLineage

  expect_identical(value$fields$id$inputFields[[1]]$field, "id")
  expect_identical(value$fields$id$inputFields[[1]]$transformations, list())
})

test_that("column lineage keeps output column order and non-ASCII names (#37)", {
  # setNames() keeps the names UTF-8; a `"z\u00e9ta" =` tag would become a
  # symbol in the native encoding, which is not UTF-8 under LC_ALL=C.
  facet <- ColumnLineageDatasetFacet(
    stats::setNames(
      list(
        list(column_lineage_input("t\u00e9", "a")),
        list(column_lineage_input("t", "b"))
      ),
      c("z\u00e9ta", "alpha")
    )
  )

  value <- jsonlite::fromJSON(
    to_openlineage_json(facet),
    simplifyVector = FALSE
  )

  expect_identical(names(value$fields), c("z\u00e9ta", "alpha"))
  expect_identical(value$fields[["z\u00e9ta"]]$inputFields[[1]]$field, "a")
  expect_identical(
    value$fields[["z\u00e9ta"]]$inputFields[[1]]$name,
    "t\u00e9"
  )
})

test_that("column lineage constructors reject invalid inputs", {
  input <- column_lineage_input("t", "a")

  expect_error(
    ColumnLineageDatasetFacet(NULL),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageDatasetFacet(list(list(input))),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageDatasetFacet(list(a = list(input), a = list(input))),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageDatasetFacet(list(a = NULL)),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageDatasetFacet(list(a = input)),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageDatasetFacet(list(a = list("x"))),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageDatasetFacet(list(a = list(b = input))),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageDatasetFacet(dataset = list("x")),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageInputField("ns", "t", NA_character_),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageInputField("ns", "t", "a", list("DIRECT")),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageTransformation(c("DIRECT", "INDIRECT")),
    class = "openlineage_validation_error"
  )
  expect_error(
    ColumnLineageTransformation("DIRECT", masking = NA),
    class = "openlineage_validation_error"
  )
})

test_that("column lineage property setters validate", {
  facet <- ColumnLineageDatasetFacet(list(a = list()))

  expect_error(
    facet@fields <- list(list()),
    class = "openlineage_validation_error"
  )
  expect_error(
    facet@dataset <- list("x"),
    class = "openlineage_validation_error"
  )
  expect_error(facet@fields <- NULL, class = "openlineage_validation_error")
  expect_error(
    facet@fields <- list(a = list("x")),
    class = "openlineage_validation_error"
  )
  facet@fields <- list(b = list(column_lineage_input("t", "b")))
  expect_named(as_openlineage_list(facet)$fields, "b")
})

test_that("an empty fields list can be assigned and is written as {} (#25)", {
  facet <- ColumnLineageDatasetFacet(list(a = list()))

  facet@fields <- list()

  expect_match(to_openlineage_json(facet), '"fields":{}', fixed = TRUE)
})

test_that("braces in column names are text, not code (#24)", {
  input <- column_lineage_input("t", "a")
  names <- c("{1+1}", "a{b", "}", "{.code x}")

  for (name in names) {
    condition <- tryCatch(
      ColumnLineageDatasetFacet(stats::setNames(list(NULL), name)),
      error = identity
    )
    expect_s3_class(condition, "openlineage_validation_error")
    expect_match(
      conditionMessage(condition),
      paste0("`fields$", name, "`"),
      fixed = TRUE
    )

    condition <- tryCatch(
      ColumnLineageDatasetFacet(stats::setNames(list(list("x")), name)),
      error = identity
    )
    expect_s3_class(condition, "openlineage_validation_error")
    expect_match(conditionMessage(condition), name, fixed = TRUE)
  }
  expect_snapshot(error = TRUE, ColumnLineageDatasetFacet(list("{1+1}" = NULL)))
})

test_that("column lineage validation errors are stable", {
  expect_snapshot(error = TRUE, {
    ColumnLineageDatasetFacet(list(list()))
    ColumnLineageDatasetFacet(list(a = NULL))
    ColumnLineageDatasetFacet(list(a = list("x")))
  })
})

test_that("transformation subtype and description may be empty strings", {
  value <- as_openlineage_list(
    ColumnLineageTransformation("DIRECT", subtype = "", description = "")
  )

  expect_identical(value, list(type = "DIRECT", subtype = "", description = ""))
  expect_error(
    ColumnLineageTransformation(""),
    class = "openlineage_validation_error"
  )
})
