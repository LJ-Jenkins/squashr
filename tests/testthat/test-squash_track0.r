squash_track02 <- function(x, ...) {
  unclass(squash_track0(x, ...))
}

test_that("squash_track0 with empty list returns empty list (not squashed0 object)", {
  sq <- squash_track0(list())
  expect_equal(length(sq), 0L)
  expect_false(inherits(sq, "squashed0"))
})

test_that("squash_track0 attaches class squashed0", {
  sq <- squash_track0(list(a = 1))
  expect_s3_class(sq, "squashed0")
})

test_that("squash_track0 errors on non-list input", {
  expect_error(squash_track0(1))
  expect_error(squash_track0("string"))
  expect_error(squash_track0(pairlist(x = 1)))
})

test_that("squash_track0 errors on duplicate names at any level", {
  expect_error(squash_track0(list(a = 1, a = 2)))
  expect_error(squash_track0(list(a = list(b = 1, b = 2))))
})

test_that("squash_track0 works with named lists", {
  input <- list(a = list(b = 1, c = 2), d = 3)
  expected <- list('[["a"]][["b"]]' = 1, '[["a"]][["c"]]' = 2, '[["d"]]' = 3)
  expect_equal(squash_track02(input), expected)

  input <- list(a = list(b = list(c = list(d = 1))))
  expected <- list('[["a"]][["b"]][["c"]][["d"]]' = 1)
  expect_equal(squash_track02(input), expected)
})

test_that("squash_track0 works with unnamed lists", {
  input <- list(list(1, 2), 3)
  expected <- list("[[1]][[1]]" = 1, "[[1]][[2]]" = 2, "[[2]]" = 3)
  expect_equal(squash_track02(input), expected)
})

test_that("squash_track0 works with mixed lists", {
  input <- list(a = list(1, c = 2), 3)
  expected <- list('[["a"]][[1]]' = 1, '[["a"]][["c"]]' = 2, "[[2]]" = 3)
  expect_equal(squash_track02(input), expected)
})

test_that("squash_track0 retains empty list elements", {
  sq <- squash_track02(list(a = list()))
  expect_equal(length(sq), 1L)
  expect_equal(sq, list('[["a"]]' = list()))
})

test_that("squash_track0 returns exact element types as is", {
  input <- list(a = mean, b = quote(x + 1), c = data.frame(x = 1))
  sq <- squash_track02(input)
  expect_equal(class(sq[['[["a"]]']]), "function")
  expect_equal(class(sq[['[["b"]]']]), "call")
  expect_equal(class(sq[['[["c"]]']]), "data.frame")
})

test_that("squash_track.squashed0 returns the object unchanged", {
  sq <- squash_track0(list(a = list(b = 1)))
  expect_identical(squash_track(sq), sq)
})

test_that("squash_track0 on a squashed object errors", {
  expect_error(squash_track0(squash_track(list(a = 1))))
})

test_that("squash_track0 on a squashed0 object errors", {
  expect_error(squash_track0(squash_track0(list(a = 1))))
})

test_that("squash_track0 works with data.frame", {
  df <- data.frame(x = 1, y = "a", stringsAsFactors = FALSE)
  sq <- squash_track02(df)
  expect_equal(sq[['[["x"]]']], df$x)
  expect_equal(sq[['[["y"]]']], df$y)
})

test_that("squash_track0 retains all attributes of leaf elements", {
  x <- structure(1, class = "myclass", info = "hello")
  result <- squash_track02(list(x))
  expect_s3_class(result[[1]], "myclass")
  expect_equal(attr(result[[1]], "info"), "hello")

  m <- matrix(1:4, 2, 2)
  result <- squash_track02(list(m))
  expect_equal(dim(result[[1]]), c(2L, 2L))

  df <- structure(data.frame(x = 1), custom = "attr")
  result <- squash_track02(list(df))
  expect_equal(attr(result[[1]], "custom"), "attr")
})
