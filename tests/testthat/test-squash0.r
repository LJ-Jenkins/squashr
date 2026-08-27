test_that("squash0 returns NULL for an empty list", {
  expect_null(squash0(list()))
})

test_that("squash0 returns NULL when all elements are empty", {
  expect_null(squash0(list(NULL)))
  expect_null(squash0(list(NULL, numeric(0), integer(0))))
  expect_null(squash0(list(list(), list(list()))))
})

test_that("squash0 returns a non-list input unchanged", {
  expect_identical(squash0(1L), 1L)
  expect_identical(squash0("a"), "a")
  expect_identical(squash0(TRUE), TRUE)
})

test_that("squash0 returns a data.frame unchanged", {
  df <- data.frame(x = 1, y = 2)
  expect_identical(squash0(df), df)
})

test_that("squash0 always returns a 1-d list", {
  expect_type(squash0(list(1, list(2, 3))), "list")
  expect_length(squash0(list(1, list(2, 3))), 3L)

  expect_length(squash0(list(list(list(1)), 2)), 2L)
  expect_length(squash0(list(list(list(list(1, 2))), 3)), 3L)
})

test_that("squash0 does not simplify to an atomic vector", {
  expect_type(squash0(list(1L, 2L, 3L)), "list")
  expect_type(squash0(list("a", "b")), "list")
})

test_that("squash0 preserves element values exactly", {
  expect_equal(squash0(list(1, list(2, 3))), list(1, 2, 3))
  expect_equal(squash0(list(list(list(1L)))), list(1L))
})

test_that("squash0 strips all names", {
  expect_null(names(squash0(list(a = 1, b = 2))))
  expect_null(names(squash0(list(a = 1, b = list(c = 2, d = 3)))))
  expect_null(names(squash0(list(list(x = 1), list(y = 2)))))
})

test_that("squash0 leaves data.frame elements as-is", {
  df <- data.frame(x = 1:2, y = 3:4)
  result <- squash0(list(1, df))
  expect_identical(result[[2]], df)
  expect_s3_class(result[[2]], "data.frame")
})

test_that("squash0 leaves pairlist, call, and expression elements as-is", {
  result <- squash0(list(list(quote(x + 1), pairlist(a = 1))))
  expect_equal(class(result[[1]]), "call")
  expect_equal(class(result[[2]]), "pairlist")
})

test_that("squash0 always drops NULL and empty atomics", {
  expect_length(squash0(list(1, NULL, 2)), 2L)
  expect_equal(squash0(list(1, NULL, 2)), list(1, 2))

  expect_equal(squash0(list(a = 1, b = numeric(0), c = 2)), list(1, 2))
})

test_that("squash0 always drops empty lists", {
  expect_length(squash0(list(1, list(), 2)), 2L)
  expect_equal(squash0(list(1, list(), 2)), list(1, 2))
})

test_that("squash0 retains all attributes of leaf elements", {
  x <- structure(1, class = "myclass", info = "hello")
  result <- squash0(list(x))
  expect_s3_class(result[[1]], "myclass")
  expect_equal(attr(result[[1]], "info"), "hello")

  m <- matrix(1:4, 2, 2)
  result <- squash0(list(m))
  expect_equal(dim(result[[1]]), c(2L, 2L))

  df <- structure(data.frame(x = 1), custom = "attr")
  result <- squash0(list(df))
  expect_equal(attr(result[[1]], "custom"), "attr")
})
