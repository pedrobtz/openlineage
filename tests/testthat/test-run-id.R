test_that("new_run_id returns a valid UUID", {
  id <- new_run_id()

  expect_length(id, 1L)
  expect_match(
    id,
    "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
  )
})

test_that("new_run_id returns a new value on each call", {
  ids <- vapply(seq_len(100L), \(x) new_run_id(), character(1))

  expect_identical(anyDuplicated(ids), 0L)
})
