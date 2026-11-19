test_that("the JSON comparison helper has no numeric tolerance (#22)", {
  expect_success(expect_json_semantically_equal(
    '{"a":1,"b":2}',
    '{"b":2,"a":1}'
  ))
  expect_failure(
    expect_json_semantically_equal('{"a":123456789}', '{"a":123456789.5}')
  )
  expect_failure(
    expect_json_semantically_equal(
      '{"a":9007199254740992}',
      '{"a":9.00719925474099e+15}'
    )
  )
  expect_failure(expect_json_semantically_equal('{"a":1}', '{"a":1.5}'))
  expect_failure(expect_json_semantically_equal('{"a":1}', '{"a":"1"}'))
  expect_failure(expect_json_semantically_equal('{"a":[1]}', '{"a":1}'))
})
