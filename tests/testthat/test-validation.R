test_that("scalar character validation returns its input invisibly", {
  expect_invisible(openlineage:::.ol_validate_scalar_character("value", "x"))
})

test_that("scalar character validation has stable errors", {
  condition <- tryCatch(
    openlineage:::.ol_validate_scalar_character(character(), "name"),
    error = identity
  )

  expect_s3_class(condition, "openlineage_validation_error")
  expect_s3_class(condition, "openlineage_error")
  expect_snapshot(error = TRUE, {
    openlineage:::.ol_validate_scalar_character("", "name")
  })
})
