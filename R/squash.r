#' Squash a list to a depth of 1
#' @description
#' Squash a nested list into a list of depth 1.
#' @details
#' `squash()` differs to [`unlist()`] in three key ways:
#' 1. It does not simplify the result, **nor** any elements
#' of the input list.
#' 2. data.frame elements are left as is, rather than
#' being unlisted/squashed.
#' 3. Names are not combined, inner names are preserved.
#'
#' `squash0()` is a barebones version of `squash()`, which
#' strips names and drops empty elements by default for a
#' slight performance gain.
#' @param x A list.
#' @param keep.empty Logical, indicating whether to retain
#' empty elements (e.g., `NULL`, `numeric(0)`, etc.) in the
#' squashed list. Defaults to `FALSE`.
#' @return A list of depth 1. If a non-list (or data.frame)
#' is provided, the input is returned. If the squashed list
#' is empty, `NULL` is returned.
#' @seealso
#' [`squash_track()`] for squashing whilst encoding the
#' original structure through names.
#' @examples
#' # no simplification, always 1d list result
#' squash(list(x = 1, list(a = 2, 3)))
#' squash0(list(x = 1, list(a = 2, 3)))
#'
#' # data.frames left as is
#' squash(list(x = 1, y = data.frame(a = 2, b = 3)))
#' squash0(list(x = 1, y = data.frame(a = 2, b = 3)))
#'
#' # empty list returns NULL
#' squash(list())
#' squash0(list(NULL, numeric()))
#'
#' # inner names are preserved
#' squash(list(a = 1, b = list(list(a = 1))))
#'
#' # result nor any elements of the input list are simplified
#' unlist(list(1, 2, 3))
#' squash0(list(1, 2, 3))
#' unlist(list(1:3, list("a", "b")), recursive = FALSE)
#' squash0(list(1:3, list("a", "b")))
#' @export
squash <- function(x, keep.empty = FALSE) {
  .Call(squash_C, x, keep.empty)
}

#' @rdname squash
#' @export
squash0 <- function(x) {
  .Call(squash0_C, x)
}
