test_that("is.squashed returns TRUE for squashed and squashed0 objects", {
  expect_true(is.squashed(squash_track(list(a = 1))))
  expect_true(is.squashed(squash_track0(list(a = 1))))
})

test_that("is.squashed returns FALSE for non-squashed objects", {
  expect_false(is.squashed(list(a = 1)))
  expect_false(is.squashed(NULL))
  expect_false(is.squashed(1L))
  expect_false(is.squashed(structure(list(a = 1), class = "myclass")))
})
