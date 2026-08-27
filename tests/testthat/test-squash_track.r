squash_track2 <- function(x, ...) {
  x <- unclass(squash_track(x, ...))
  attr(x, "sep") <- NULL
  attr(x, "wrap") <- NULL
  attr(x, "unique_names") <- NULL
  x
}

test_that("squash_track with empty list returns empty list (not squashed object)", {
  sq <- squash_track(list())
  expect_equal(length(sq), 0L)
  expect_false(inherits(sq, "squashed"))
})

test_that("squash_track attaches class, and sep/wrap/unique_names attributes", {
  sq <- squash_track(list(1, 2))
  # defaults
  expect_equal(attr(sq, "sep"), "..")
  expect_equal(attr(sq, "wrap"), "'")
  expect_null(attr(sq, "unique_names"))
  expect_s3_class(sq, "squashed")

  sq <- squash_track(list(1, 2), sep = "__", wrap = '"', unique_names = "*")
  expect_equal(attr(sq, "sep"), "__")
  expect_equal(attr(sq, "wrap"), '"')
  expect_equal(attr(sq, "unique_names"), "*")
  expect_s3_class(sq, "squashed")
})

test_that("squash_track with empty list elements retains them", {
  sq <- squash_track2(list(list()))
  expect_equal(length(sq), 1L)
  expect_equal(sq, list("1" = list()))

  sq <- squash_track2(list(integer()))
  expect_equal(length(sq), 1L)
  expect_equal(sq, list("1" = integer()))
})

test_that("squash_track errors on non-list input", {
  expect_error(squash_track(1))
  expect_error(squash_track("string"))
  expect_error(squash_track(pairlist(x = 1)))
})

test_that("squash_track 'sep' and 'wrap' error with non string inputs", {
  expect_error(squash_track(list(1), sep = 1))
  expect_error(squash_track(list(1), wrap = 1))

  expect_error(squash_track(list(1), sep = NA_character))
  expect_error(squash_track(list(1), wrap = NA_character))

  expect_error(squash_track(list(1), sep = c("..", ",,")))
  expect_error(squash_track(list(1), wrap = c("..", ",,")))

  expect_error(squash_track(list(1), sep = ""))
  expect_error(squash_track(list(1), wrap = ""))
})

test_that("squash_track 'unique_names' error with non string, or non FALSE inputs", {
  expect_error(squash_track(list(1), unique_names = 1))
  expect_error(squash_track(list(1), unique_names = NA_character))
  expect_error(squash_track(list(1), unique_names = c("*", "**")))
  expect_error(squash_track(list(1), unique_names = ""))

  expect_error(squash_track(list(1), unique_names = TRUE))
  expect_error(squash_track(list(1), unique_names = NA))
  expect_error(squash_track(list(1), unique_names = c(FALSE, FALSE)))
})

test_that("squash_track errors if string args are the same", {
  expect_error(squash_track(list(1), sep = "..", wrap = ".."))
  expect_error(squash_track(list(1), wrap = "..", unique_names = ".."))
  expect_error(squash_track(list(1), sep = "..", unique_names = ".."))
})

test_that("squash_track errors if 'sep' present in names", {
  expect_error(squash_track(list("a..b" = 1)))
  expect_error(squash_track(list("w[]p" = 1), sep = "[]"))
  expect_no_error(squash_track(list(".w.p." = 1)))
})

test_that("squash_track errors if 'wrap' pattern present in names", {
  expect_error(squash_track(list("'12'" = 1)))
  expect_error(squash_track(list("[]12[]" = 1), wrap = "[]"))
  expect_no_error(squash_track(list("'12.'" = 1)))
  expect_no_error(squash_track(list("'1" = 1)))
  expect_no_error(squash_track(list("[]12]" = 1), wrap = "[]"))
})

test_that("squash_track errors if 'unique_names' pattern present in names", {
  expect_error(squash_track(list("x*1" = 1), unique_names = "*"))
  expect_error(squash_track(list("1[]12" = 1), unique_names = "[]"))
  expect_no_error(squash_track(list("x*1." = 1)))
  expect_no_error(squash_track(list("x*" = 1)))
  expect_no_error(squash_track(list("1[]]5" = 1), unique_names = "[]"))
})

test_that("squash_track works with named lists", {
  input <- list(a = list(b = 1, c = 2), d = 3)
  expected <- list("a..b" = 1, "a..c" = 2, d = 3)
  expect_equal(squash_track2(input), expected)

  input <- list(a = list(b = list(b = list(b = list(a = 1))), c = 2), d = 3)
  expected <- list("a..b..b..b..a" = 1, "a..c" = 2, d = 3)
  expect_equal(squash_track2(input), expected)
})

test_that("squash_track works with unnamed lists", {
  input <- list(list(1, 2), 3)
  expected <- list("1..1" = 1, "1..2" = 2, "2" = 3)
  expect_equal(squash_track2(input), expected)

  input <- list(list(list(list(list(1))), 2), 3)
  expected <- list("1..1..1..1..1" = 1, "1..2" = 2, "2" = 3)
  expect_equal(squash_track2(input), expected)
})

test_that("squash_track works with mixed lists", {
  input <- list(a = list(1, c = 2), 3)
  expected <- list("a..1" = 1, "a..c" = 2, "2" = 3)
  expect_equal(squash_track2(input), expected)

  input <- list(a = list("1" = list(b = list(list(a = 1))), 2), 3)
  expected <- list("a..'1'..b..1..a" = 1, "a..2" = 2, "2" = 3)
  expect_equal(squash_track2(input), expected)
})

test_that("squash_track 'sep' correctly changes", {
  input <- list(a = list(1, c = 2), 3)
  expected <- list("a,,1" = 1, "a,,c" = 2, "2" = 3)
  expect_equal(squash_track2(input, sep = ",,"), expected)

  input <- list(a = list("1" = list(b = list(list(a = 1))), 2), 3)
  expected <- list("a^'1'^b^1^a" = 1, "a^2" = 2, "2" = 3)
  expect_equal(squash_track2(input, sep = "^"), expected)
})

test_that("squash_track 'wrap' catches and correctly changes", {
  input <- list(a = list("1" = list(b = list(list(a = 1))), 2), 3)
  expected <- list("a^*1*^b^1^a" = 1, "a^2" = 2, "2" = 3)
  expect_equal(squash_track2(input, sep = "^", wrap = "*"), expected)

  input <- list(
    "1" = 1, "1.5" = 9, ".1" = 5,
    "980429020340" = 10, "100,000" = 3
  )
  expected <- list(
    "<1<" = 1, "1.5" = 9, ".1" = 5,
    "<980429020340<" = 10, "100,000" = 3
  )
  expect_equal(squash_track2(input, wrap = "<"), expected)
})

test_that("squash_track 'unique_names' catches and correctly changes", {
  input <- list(
    list("1" = list(
      b = 3,
      b = list(list(a = 1, a = 2)),
      a = 2,
      b = 1
    ), 2),
    "1" = 3,
    "h*i" = 4,
    "h*" = 5
  )
  expected <- list(
    "1..'1'..b" = 3,
    "1..'1'..b*2..1..a" = 1,
    "1..'1'..b*2..1..a*2" = 2,
    "1..'1'..a" = 2,
    "1..'1'..b*4" = 1,
    "1..2" = 2,
    "'1'" = 3,
    "h*i" = 4,
    "h*" = 5
  )
  expect_equal(squash_track2(input, unique_names = "*"), expected)

  sq <- squash_track(rep(list(x = 1), 100), unique_names = ",.?")
  expect_equal(names(sq), c("x", paste0("x", ",.?", 2:100)))
})

test_that("squash_track returns exact elements as is", {
  input <- list(
    mean,
    list(new.env(parent = emptyenv())),
    pairlist(x = 1),
    quote(x + 1),
    list(expression(hi), b = data.frame(x = 1))
  )
  expected <- list(
    "1" = mean,
    "2..1" = new.env(parent = emptyenv()),
    "3" = pairlist(x = 1),
    "4" = quote(x + 1),
    "5..1" = expression(hi),
    "5..b" = data.frame(x = 1)
  )
  output <- squash_track2(input)
  expect_equal(output, expected)

  expect_equal(class(output[["1"]]), "function")
  expect_equal(class(output[["2..1"]]), "environment")
  expect_equal(class(output[["3"]]), "pairlist")
  expect_equal(class(output[["4"]]), "call")
  expect_equal(class(output[["5..1"]]), "expression")
  expect_equal(class(output[["5..b"]]), "data.frame")
})

test_that("squash_track retains all attributes of leaf elements", {
  x <- structure(1, class = "myclass", info = "hello")
  result <- squash_track2(list(x))
  expect_s3_class(result[[1]], "myclass")
  expect_equal(attr(result[[1]], "info"), "hello")

  m <- matrix(1:4, 2, 2)
  result <- squash_track2(list(m))
  expect_equal(dim(result[[1]]), c(2L, 2L))

  df <- structure(data.frame(x = 1), custom = "attr")
  result <- squash_track2(list(df))
  expect_equal(attr(result[[1]], "custom"), "attr")
})
