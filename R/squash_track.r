#' @title
#' Squash a list to a depth of 1 whilst encoding structure in names
#' @description
#' `squash_track()`  and `squash_track0()` reduce a list to a single level,
#' tracking and encoding the original structure in the names of the
#' elements. `squash_track0()` errors on duplicate names at a given
#' level, whereas `squash_track()` differentiates names flexibly using
#' given `sep`, `wrap`, and `unique_names` parameters.
#' @param x A list or data.frame. For `is.squashed()`, an object to check.
#' @param sep String separator to use between levels in the names.
#' @param wrap String to wrap around whole number names.
#' @param unique_names Either `FALSE` to allow duplicate names, or a string
#' separator to be placed in between the name and the index to differentiate.
#' @param ... additional arguments to pass to methods.
#' @return
#' For `squash_track()`, a squashed, 1-level list with class `squashed` and the
#' `sep` and `wrap` inputs attached as attributes. `unique_names` is also an
#' attribute if not `FALSE`.
#'
#' For `squash_track0()`, a squashed, 1-level list with class `squashed0`.
#'
#' For `is.squashed()`, `TRUE` or `FALSE`.
#' @details
#' To encode the original structure, `squash_track()` concatenates the
#' names of the elements using the specified `sep`. If an element is unnamed
#' the index is used instead. If an element is named and the name is numeric
#' and whole (aka could be confused for an index), then it is wrapped with
#' the specified `wrap` string. The resulting name structure can therefore
#' be a mix of names and indices.
#'
#' If `unique_names` is a string, duplicate names will be made unique by
#' appending the index to the end of the name, separated by the string given.
#'
#' To ensure the original structure can be reconstructed, any names that match
#' the `squash` patterns upon ingest will cause an error: `sep` cannot be
#' present in any of the element names; no element names can already be a
#' whole number with the `wrap` around it; and if `unique_names` is
#' a string, then no element names can already end with the `unique_names`
#' separator followed by a whole number.
#'
#' [data.frame] elements of input lists, as well as empty list elements,
#' are left as is. This is **unlike** the default behaviour of `squash()`
#' which drops empty elements.
#'
#' `is.squashed()` checks if a list has been squashed by either `squash_track()`
#' or `squash_track0()`.
#' @seealso
#' [squash] to reduce a list to 1-d without tracking the original structure.
#'
#' [squashed_nm2call] to convert a squashed name back to the original nested
#' structure as a call.
#' @examples
#' # for named elements, names are concatenated with `sep`.
#' x <- list(a = list(b = 1, c = 2), d = 3)
#' squash_track(x)
#' squash_track0(x)
#'
#' # for unnamed elements, indices are used
#' squash_track(list(list(1, 2), 3))
#' squash_track0(list(list(1, 2), 3))
#'
#' # for mixed named/unnamed elements, names and indices are combined.
#' x <- list(a = list(1, 2), list(3, b = 4))
#' squash_track(x)
#' squash_track0(x)
#'
#' # names that could also be indices are wrapped with `wrap`.
#' x <- list(10, "1" = 15, "2" = list("2" = 1, 5, "1.5" = 7))
#' squash_track(x)
#' squash_track0(x)
#'
#' # duplicate names remain when `unique_names` is `FALSE`.
#' squash_track(list(a = 1, a = 2))
#' # these can be made unique using the index and a given string:
#' squash_track(list(a = 1, a = 2), unique_names = "*")
#' # fails for squash_track0
#' try(squash_track0(list(a = 1, a = 2)))
#'
#' is.squashed(squash_track(list(a = 1)))
#' is.squashed(squash_track0(list(a = 1)))
#' @export
squash_track <- function(x, ...) {
  UseMethod("squash_track", x)
}

#' @rdname squash_track
#' @export
squash_track.list <- function(
  x,
  sep = "..",
  wrap = "'",
  unique_names = FALSE,
  ...
) {
  .Call(squash_track_C, x, sep, wrap, unique_names)
}

#' @export
squash_track.data.frame <- function(
  x,
  sep = "..",
  wrap = "'",
  unique_names = FALSE,
  ...
) {
  .Call(squash_track_C, as.list(x), sep, wrap, unique_names)
}

#' @export
squash_track.squashed <- function(x, unique_names = FALSE, ...) {
  attr_sep <- attr(x, "sep")
  attr_wrap <- attr(x, "wrap")
  attr_unique_names <- attr(x, "unique_names")

  if ((i <- isFALSE(unique_names)) && !is.null(attr_unique_names)) {
    stop(
      "Cannot re-squash a squashed object with a different ",
      "`unique_names` attribute."
    )
  }

  if (!i) {
    .Call(squash_track_C, x, attr_sep, attr_wrap, unique_names)
  } else {
    x
  }
}

#' @export
squash_track.squashed0 <- function(x, ...) {
  x
}

#' @rdname squash_track
#' @export
squash_track0 <- function(x, ...) {
  UseMethod("squash_track0")
}

#' @rdname squash_track
#' @export
squash_track0.list <- function(x, ...) {
  .Call(squash_track_no_dups_C, x)
}

#' @export
squash_track0.data.frame <- function(x, ...) {
  .Call(squash_track_no_dups_C, as.list(x))
}

#' @export
squash_track0.squashed <- function(x, ...) {
  stop("Cannot call `squash_track0()` on a squashed object.")
}

#' @export
squash_track0.squashed0 <- function(x, ...) {
  stop("Cannot call `squash_track0()` on a squashed0 object.")
}

#' @export
as.list.squashed <- function(x, ...) {
  class(x) <- setdiff(class(x), "squashed")
  NextMethod()
}

#' @export
as.list.squashed0 <- function(x, ...) {
  class(x) <- setdiff(class(x), "squashed0")
  NextMethod()
}

#' @rdname squash_track
#' @export
is.squashed <- function(x) {
  inherits(x, c("squashed", "squashed0"))
}
