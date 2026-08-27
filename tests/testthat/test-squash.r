test_that("squash returns NULL for an empty list", {
  expect_null(squash(list()))
})

test_that("squash returns NULL when all elements are empty and keep.empty is FALSE", {
  expect_null(squash(list(NULL)))
  expect_null(squash(list(NULL, numeric(0), integer(0))))
  expect_null(squash(list(list(), list(list()))))
})

test_that("squash returns a non-list input unchanged", {
  expect_identical(squash(1L), 1L)
  expect_identical(squash("a"), "a")
  expect_identical(squash(TRUE), TRUE)
})

test_that("squash returns a data.frame unchanged", {
  df <- data.frame(x = 1, y = 2)
  expect_identical(squash(df), df)
})

test_that("squash always returns a 1-d list", {
  expect_type(squash(list(1, list(2, 3))), "list")
  expect_length(squash(list(1, list(2, 3))), 3L)

  expect_length(squash(list(list(list(1)), 2)), 2L)
  expect_length(squash(list(list(list(list(1, 2))), 3)), 3L)
})

test_that("squash does not simplify to an atomic vector", {
  expect_type(squash(list(1L, 2L, 3L)), "list")
  expect_type(squash(list("a", "b")), "list")
})

test_that("squash preserves element values exactly", {
  expect_equal(squash(list(1, list(2, 3))), list(1, 2, 3))
  expect_equal(squash(list(list(list(1L)))), list(1L))
})

test_that("squash preserves inner names from the immediate parent", {
  expect_equal(squash(list(a = 1, b = list(c = 2, 3))), list(a = 1, c = 2, 3))
  expect_equal(squash(list(list(a = 1, b = 2), 3)), list(a = 1, b = 2, 3))
})

test_that("squash attaches no names when all elements are unnamed", {
  expect_null(names(squash(list(1, list(2, 3)))))
  expect_null(names(squash(list(list(list(1)), 2))))
})

test_that("squash leaves data.frame elements as-is", {
  df <- data.frame(x = 1:2, y = 3:4)
  result <- squash(list(a = 1, b = df))
  expect_identical(result$b, df)
  expect_s3_class(result$b, "data.frame")
})

test_that("squash leaves pairlist, call, and expression elements as-is", {
  result <- squash(list(list(quote(x + 1), pairlist(a = 1))))
  expect_equal(class(result[[1]]), "call")
  expect_equal(class(result[[2]]), "pairlist")
})

test_that("squash drops NULL and empty atomics by default", {
  expect_length(squash(list(1, NULL, 2)), 2L)
  expect_equal(squash(list(1, NULL, 2)), list(1, 2))

  expect_length(squash(list(a = 1, b = numeric(0), c = 2)), 2L)
  expect_equal(names(squash(list(a = 1, b = numeric(0), c = 2))), c("a", "c"))
})

test_that("squash drops empty lists by default", {
  expect_length(squash(list(1, list(), 2)), 2L)
  expect_equal(squash(list(1, list(), 2)), list(1, 2))
})

test_that("squash keep.empty = TRUE retains NULL", {
  result <- squash(list(NULL, 1), keep.empty = TRUE)
  expect_length(result, 2L)
  expect_null(result[[1]])
  expect_equal(result[[2]], 1)
})

test_that("squash keep.empty = TRUE retains empty atomics", {
  result <- squash(list(a = numeric(0), b = 1), keep.empty = TRUE)
  expect_length(result, 2L)
  expect_equal(names(result), c("a", "b"))
  expect_equal(result$a, numeric(0))
})

test_that("squash keep.empty = TRUE retains empty lists", {
  result <- squash(list(a = list(), b = 1), keep.empty = TRUE)
  expect_length(result, 2L)
  expect_equal(result$a, list())
})

test_that("squash keep.empty errors on non-logical or length != 1", {
  expect_error(squash(list(1), keep.empty = "yes"))
  expect_error(squash(list(1), keep.empty = 1L))
  expect_error(squash(list(1), keep.empty = c(TRUE, FALSE)))
})

test_that("squash retains all attributes of leaf elements", {
  x <- structure(1, class = "myclass", info = "hello")
  result <- squash(list(x))
  expect_s3_class(result[[1]], "myclass")
  expect_equal(attr(result[[1]], "info"), "hello")

  m <- matrix(1:4, 2, 2)
  result <- squash(list(m))
  expect_equal(dim(result[[1]]), c(2L, 2L))

  df <- structure(data.frame(x = 1), custom = "attr")
  result <- squash(list(df))
  expect_equal(attr(result[[1]], "custom"), "attr")
})
