#' Convert squashed names to calls
#'
#' @description
#' Convert a squashed name back to its original
#' nested structure as a call.
#' @details
#' For `squashed0_nm2call()` inputs should be derived from the
#' names of squashed0 objects and therefore will already be in
#' a format suitable for direct conversion back to calls using
#' [parse].
#'
#' `squashed_nm2call()` converts squashed names back to calls,
#' using the `sep`, `wrap`, and `unique_names` arguments to
#' correctly interpret the structure of the squashed names in
#' relation to the original object. For example, `"1..'1'"`
#' with `sep=".."` and `wrap="'"` would be interpreted as
#' `.data[[1]][["1"]]` whereas `"`a..b..'1'..a*5`"` would
#' be interpreted as `.data[["a"]][["b"]][["1"]][[5L]]`.
#' @param nm A squashed name to be converted back to a call.
#' @param var A string referring to the object that will be the subject
#' of the call.
#' @param sep The separator used in the squashed names.
#' @param wrap The character used to wrap names in the squashed names.
#' @param unique_names The marker used for uniquely marked names.
#' @return A call representing the original nested structure
#' of the squashed name.
#' @examples
#' squashed_nm2call("1..'1'")
#' squashed_nm2call("a..b..'1'..a*5", unique_names = "*")
#'
#' x <- list(list("1" = 1))
#' y <- squash0(x)
#' cll <- squashed0_nm2call(names(y), var = "x")
#' eval(cll)
#' @export
squashed_nm2call <- function(
  nm,
  var = ".data",
  sep = "..",
  wrap = "'",
  unique_names = FALSE
) {
  .Call(squashed_nm2call_C, nm, var, sep, wrap, unique_names)
}
# This function converts a squashed name
# back to the original nested structure as an expr,
# ready to be eval()'d
# For example, `1..'1'` with sep=".." and wrap="'"
# would become [[1]][["1"]]
# and `a..b..'1'..a*5` with unique_names="*"
# would become [["a"]][["b"]][["1"]][[5L]]
# as we can just use the index for the dup 'a'
# element

#' @rdname squashed_nm2call
#' @export
squashed0_nm2call <- function(nm, var = ".data") {
  if (!is.character(nm) || length(nm) != 1L || is.na(nm) || !nzchar(nm)) {
    stop("`nm` must be a single string")
  }
  if (!is.character(var) || length(var) != 1L || is.na(var) || !nzchar(var)) {
    stop("`var` must be a single string")
  }

  parse(text = paste0(var, nm))[[1L]]
}
