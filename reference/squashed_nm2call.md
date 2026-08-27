# Convert squashed names to calls

Convert a squashed name back to its original nested structure as a call.

## Usage

``` r
squashed_nm2call(
  nm,
  var = ".data",
  sep = "..",
  wrap = "'",
  unique_names = FALSE
)

squashed0_nm2call(nm, var = ".data")
```

## Arguments

- nm:

  A squashed name to be converted back to a call.

- var:

  A string referring to the object that will be the subject of the call.

- sep:

  The separator used in the squashed names.

- wrap:

  The character used to wrap names in the squashed names.

- unique_names:

  The marker used for uniquely marked names.

## Value

A call representing the original nested structure of the squashed name.

## Details

For `squashed0_nm2call()` inputs should be derived from the names of
squashed0 objects and therefore will already be in a format suitable for
direct conversion back to calls using
[parse](https://rdrr.io/r/base/parse.html).

`squashed_nm2call()` converts squashed names back to calls, using the
`sep`, `wrap`, and `unique_names` arguments to correctly interpret the
structure of the squashed names in relation to the original object. For
example, `"1..'1'"` with `sep=".."` and `wrap="'"` would be interpreted
as `.data[[1]][["1"]]` whereas `"a..b..'1'..a*5"` would be interpreted
as `.data[["a"]][["b"]][["1"]][[5L]]`.

## Note

Caution must be exercised when using these functions, as unexpected
inputs (e.g., malformed squashed names or unsquashed names) may lead to
errors or unexpected behaviour.

## Examples

``` r
squashed_nm2call("1..'1'")
#> .data[[1L]][["1"]]
squashed_nm2call("a..b..'1'..a*5", unique_names = "*")
#> .data[["a"]][["b"]][["1"]][[5L]]

x <- list(list("1" = 1))
y <- squash_track(x)
cll <- squashed_nm2call(names(y), var = "x")
eval(cll)
#> [1] 1
```
