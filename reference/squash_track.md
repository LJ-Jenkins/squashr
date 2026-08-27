# Squash a list to a depth of 1 whilst encoding structure in names

`squash_track()` and `squash_track0()` reduce a list to a single level,
tracking and encoding the original structure in the names of the
elements. `squash_track0()` errors on duplicate names at a given level,
whereas `squash_track()` differentiates names flexibly using given
`sep`, `wrap`, and `unique_names` parameters.

## Usage

``` r
squash_track(x, ...)

# S3 method for class 'list'
squash_track(x, sep = "..", wrap = "'", unique_names = FALSE, ...)

squash_track0(x, ...)

# S3 method for class 'list'
squash_track0(x, ...)

is.squashed(x)
```

## Arguments

- x:

  A list or data.frame. For `is.squashed()`, an object to check.

- ...:

  additional arguments to pass to methods.

- sep:

  String separator to use between levels in the names.

- wrap:

  String to wrap around whole number names.

- unique_names:

  Either `FALSE` to allow duplicate names, or a string separator to be
  placed in between the name and the index to differentiate.

## Value

For `squash_track()`, a squashed, 1-level list with class `squashed` and
the `sep` and `wrap` inputs attached as attributes. `unique_names` is
also an attribute if not `FALSE`.

For `squash_track0()`, a squashed, 1-level list with class `squashed0`.

For `is.squashed()`, `TRUE` or `FALSE`.

## Details

To encode the original structure, `squash_track()` concatenates the
names of the elements using the specified `sep`. If an element is
unnamed the index is used instead. If an element is named and the name
is numeric and whole (aka could be confused for an index), then it is
wrapped with the specified `wrap` string. The resulting name structure
can therefore be a mix of names and indices.

If `unique_names` is a string, duplicate names will be made unique by
appending the index to the end of the name, separated by the string
given.

To ensure the original structure can be reconstructed, any names that
match the `squash` patterns upon ingest will cause an error: `sep`
cannot be present in any of the element names; no element names can
already be a whole number with the `wrap` around it; and if
`unique_names` is a string, then no element names can already end with
the `unique_names` separator followed by a whole number.

[data.frame](https://rdrr.io/r/base/data.frame.html) elements of input
lists, as well as empty list elements, are left as is. This is
**unlike** the default behaviour of
[`squash()`](https://lj-jenkins.github.io/squashr/reference/squash.md)
which drops empty elements.

`is.squashed()` checks if a list has been squashed by either
`squash_track()` or `squash_track0()`.

## See also

[squash](https://lj-jenkins.github.io/squashr/reference/squash.md) to
reduce a list to 1-d without tracking the original structure.

[squashed_nm2call](https://lj-jenkins.github.io/squashr/reference/squashed_nm2call.md)
to convert a squashed name back to the original nested structure as a
call.

## Examples

``` r
# for named elements, names are concatenated with `sep`.
x <- list(a = list(b = 1, c = 2), d = 3)
squash_track(x)
#> Squashed list (3 elements)
#> -Element separator: '..'
#> -Wrap character for whole number names: '''
#> -Unique names: FALSE
#> 
#> $a..b
#> [1] 1
#> 
#> $a..c
#> [1] 2
#> 
#> $d
#> [1] 3
#> 
squash_track0(x)
#> $`[["a"]][["b"]]`
#> [1] 1
#> 
#> $`[["a"]][["c"]]`
#> [1] 2
#> 
#> $`[["d"]]`
#> [1] 3
#> 

# for unnamed elements, indices are used
squash_track(list(list(1, 2), 3))
#> Squashed list (3 elements)
#> -Element separator: '..'
#> -Wrap character for whole number names: '''
#> -Unique names: FALSE
#> 
#> $`1..1`
#> [1] 1
#> 
#> $`1..2`
#> [1] 2
#> 
#> $`2`
#> [1] 3
#> 
squash_track0(list(list(1, 2), 3))
#> $`[[1]][[1]]`
#> [1] 1
#> 
#> $`[[1]][[2]]`
#> [1] 2
#> 
#> $`[[2]]`
#> [1] 3
#> 

# for mixed named/unnamed elements, names and indices are combined.
x <- list(a = list(1, 2), list(3, b = 4))
squash_track(x)
#> Squashed list (4 elements)
#> -Element separator: '..'
#> -Wrap character for whole number names: '''
#> -Unique names: FALSE
#> 
#> $a..1
#> [1] 1
#> 
#> $a..2
#> [1] 2
#> 
#> $`2..1`
#> [1] 3
#> 
#> $`2..b`
#> [1] 4
#> 
squash_track0(x)
#> $`[["a"]][[1]]`
#> [1] 1
#> 
#> $`[["a"]][[2]]`
#> [1] 2
#> 
#> $`[[2]][[1]]`
#> [1] 3
#> 
#> $`[[2]][["b"]]`
#> [1] 4
#> 

# names that could also be indices are wrapped with `wrap`.
x <- list(10, "1" = 15, "2" = list("2" = 1, 5, "1.5" = 7))
squash_track(x)
#> Squashed list (5 elements)
#> -Element separator: '..'
#> -Wrap character for whole number names: '''
#> -Unique names: FALSE
#> 
#> $`1`
#> [1] 10
#> 
#> $`'1'`
#> [1] 15
#> 
#> $`'2'..'2'`
#> [1] 1
#> 
#> $`'2'..2`
#> [1] 5
#> 
#> $`'2'..1.5`
#> [1] 7
#> 
squash_track0(x)
#> $`[[1]]`
#> [1] 10
#> 
#> $`[["1"]]`
#> [1] 15
#> 
#> $`[["2"]][["2"]]`
#> [1] 1
#> 
#> $`[["2"]][[2]]`
#> [1] 5
#> 
#> $`[["2"]][["1.5"]]`
#> [1] 7
#> 

# duplicate names remain when `unique_names` is `FALSE`.
squash_track(list(a = 1, a = 2))
#> Squashed list (2 elements)
#> -Element separator: '..'
#> -Wrap character for whole number names: '''
#> -Unique names: FALSE
#> 
#> $a
#> [1] 1
#> 
#> $a
#> [1] 2
#> 
# these can be made unique using the index and a given string:
squash_track(list(a = 1, a = 2), unique_names = "*")
#> Squashed list (2 elements)
#> -Element separator: '..'
#> -Wrap character for whole number names: '''
#> -Unique names: TRUE, distinguished using: '*'
#> 
#> $a
#> [1] 1
#> 
#> $`a*2`
#> [1] 2
#> 
# fails for squash_track0
try(squash_track0(list(a = 1, a = 2)))
#> Error in squash_track0.list(list(a = 1, a = 2)) : 
#>   Duplicate path component `a`. Use `squash()` with `unique_names` to automatically disambiguate duplicates.

is.squashed(squash_track(list(a = 1)))
#> [1] TRUE
is.squashed(squash_track0(list(a = 1)))
#> [1] TRUE
```
