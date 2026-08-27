test_that("squashed_nm2call: named parts produce string subscripts", {
  expect_equal(squashed_nm2call("a"), quote(.data[["a"]]))
  expect_equal(squashed_nm2call("a..b"), quote(.data[["a"]][["b"]]))
  expect_equal(squashed_nm2call("a..b..c"), quote(.data[["a"]][["b"]][["c"]]))
})

test_that("squashed_nm2call: numeric parts produce integer subscripts", {
  expect_equal(squashed_nm2call("1"), quote(.data[[1L]]))
  expect_equal(squashed_nm2call("1..2"), quote(.data[[1L]][[2L]]))
})

test_that("squashed_nm2call: wrapped parts produce string subscripts", {
  expect_equal(squashed_nm2call("'1'"), quote(.data[["1"]]))
  expect_equal(squashed_nm2call("1..'1'"), quote(.data[[1L]][["1"]]))
})

test_that("squashed_nm2call: custom var is used as the root symbol", {
  expect_equal(squashed_nm2call("a..b", var = "x"), quote(x[["a"]][["b"]]))
  expect_equal(squashed_nm2call("1", var = "mylist"), quote(mylist[[1L]]))
})

test_that("squashed_nm2call: custom sep is respected", {
  expect_equal(squashed_nm2call("a,,b", sep = ",,"), quote(.data[["a"]][["b"]]))
})

test_that("squashed_nm2call: custom wrap is respected", {
  expect_equal(
    squashed_nm2call("a^*1*", sep = "^", wrap = "*"),
    quote(.data[["a"]][["1"]])
  )
})

test_that("squashed_nm2call: unique_names marker followed by whole number -> integer subscript", {
  expect_equal(squashed_nm2call("a*2", unique_names = "*"), quote(.data[[2L]]))
  expect_equal(
    squashed_nm2call("a..b*3..c", unique_names = "*"),
    quote(.data[["a"]][[3L]][["c"]])
  )
  # marker not followed by a whole number -> treated as part of the name
  expect_equal(squashed_nm2call("h*i", unique_names = "*"), quote(.data[["h*i"]]))
  expect_equal(squashed_nm2call("h*", unique_names = "*"), quote(.data[["h*"]]))
})

test_that("squashed_nm2call: vector nm returns a list of calls", {
  result <- squashed_nm2call(c("a..b", "1..2"))
  expect_type(result, "list")
  expect_length(result, 2L)
  expect_equal(result[[1L]], quote(.data[["a"]][["b"]]))
  expect_equal(result[[2L]], quote(.data[[1L]][[2L]]))
})

test_that("squashed_nm2call: generated calls eval to the original values", {
  x <- list(a = list(b = 42, "1" = 99), list(5, 6))
  sq <- squash_track(x)
  for (nm in names(sq)) {
    cll <- squashed_nm2call(nm, var = "x")
    expect_equal(eval(cll), sq[[nm]])
  }
})

test_that("squashed_nm2call errors on invalid nm", {
  expect_error(squashed_nm2call(1L))
  expect_error(squashed_nm2call(character(0)))
  expect_error(squashed_nm2call(NA_character_))
  expect_error(squashed_nm2call(""))
})

test_that("squashed_nm2call errors on invalid var", {
  expect_error(squashed_nm2call("a", var = 1L))
  expect_error(squashed_nm2call("a", var = NA_character_))
  expect_error(squashed_nm2call("a", var = ""))
})

test_that("squashed_nm2call errors on invalid sep, wrap, or unique_names", {
  expect_error(squashed_nm2call("a", sep = 1))
  expect_error(squashed_nm2call("a", sep = ""))
  expect_error(squashed_nm2call("a", sep = NA_character_))
  expect_error(squashed_nm2call("a", wrap = 1))
  expect_error(squashed_nm2call("a", wrap = ""))
  expect_error(squashed_nm2call("a", sep = "..", wrap = ".."))
  expect_error(squashed_nm2call("a", unique_names = TRUE))
  expect_error(squashed_nm2call("a", unique_names = NA))
  expect_error(squashed_nm2call("a", unique_names = ""))
  expect_error(squashed_nm2call("a", sep = "..", unique_names = ".."))
})

test_that("squashed0_nm2call converts squash0 names to calls", {
  expect_equal(squashed0_nm2call('[["a"]][["b"]]', var = "x"), quote(x[["a"]][["b"]]))
  expect_equal(squashed0_nm2call("[[1]][[2]]", var = "x"), quote(x[[1]][[2]]))
  expect_equal(squashed0_nm2call('[["a"]][[1]]', var = "x"), quote(x[["a"]][[1]]))
})

test_that("squashed0_nm2call uses '.data' as default var", {
  expect_equal(squashed0_nm2call('[["a"]]'), quote(.data[["a"]]))
})

test_that("squashed0_nm2call: generated calls eval to the original values", {
  x <- list(a = list(b = 42), list("z" = 99))
  sq <- squash_track0(x)
  for (nm in names(sq)) {
    cll <- squashed0_nm2call(nm, var = "x")
    expect_equal(eval(cll), sq[[nm]])
  }
})

test_that("squashed0_nm2call errors when nm is not a single string", {
  expect_error(squashed0_nm2call(c('[["a"]]', '[["b"]]')))
  expect_error(squashed0_nm2call(character(0)))
  expect_error(squashed0_nm2call(1L))
  expect_error(squashed0_nm2call(NA_character_))
  expect_error(squashed0_nm2call(""))
})

test_that("squashed0_nm2call errors on invalid var", {
  expect_error(squashed0_nm2call('[["a"]]', var = 1L))
  expect_error(squashed0_nm2call('[["a"]]', var = NA_character_))
  expect_error(squashed0_nm2call('[["a"]]', var = ""))
})
