#' @export
print.squashed <- function(x, ...) {
  cat(
    "Squashed list (", length(x), " elements)\n",
    "-Element separator: '", attr(x, "sep"), "'\n",
    "-Wrap character for whole number names: '",
    attr(x, "wrap"), "'\n",
    "-Unique names",
    if (is.null(attr(x, "unique_names"))) {
      ": FALSE"
    } else {
      paste0(": TRUE, distinguished using: '", attr(x, "unique_names"), "'")
    }, "\n\n",
    sep = ""
  )

  attr(x, "sep") <- NULL
  attr(x, "wrap") <- NULL
  attr(x, "unique_names") <- NULL

  class(x) <- setdiff(class(x), "squashed")
  NextMethod()
}

#' @export
print.squashed0 <- function(x, ...) {
  class(x) <- setdiff(class(x), "squashed0")
  NextMethod()
}
