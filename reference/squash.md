# Squash a list to a depth of 1

Squash a nested list into a list of depth 1.

## Usage

``` r
squash(x, keep.empty = FALSE)

squash0(x)
```

## Arguments

- x:

  A list.

- keep.empty:

  Logical, indicating whether to retain empty elements (e.g., `NULL`,
  `numeric(0)`, etc.) in the squashed list. Defaults to `FALSE`.

## Value

A list of depth 1. If a non-list (or data.frame) is provided, the input
is returned. If the squashed list is empty, `NULL` is returned.

## Details

`squash()` differs to [`unlist()`](https://rdrr.io/r/base/unlist.html)
in three key ways:

1.  It does not simplify the result, **nor** any elements of the input
    list.

2.  data.frame elements are left as is, rather than being
    unlisted/squashed.

3.  Names are not combined, inner names are preserved.

`squash0()` is a barebones version of `squash()`, which strips names and
drops empty elements by default for a slight performance gain.

## See also

[`squash_track()`](https://lj-jenkins.github.io/squashr/reference/squash_track.md)
for squashing whilst encoding the original structure through names.

## Examples

``` r
# no simplification, always 1d list result
squash(list(x = 1, list(a = 2, 3)))
#> $x
#> [1] 1
#> 
#> $a
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 
squash0(list(x = 1, list(a = 2, 3)))
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 

# data.frames left as is
squash(list(x = 1, y = data.frame(a = 2, b = 3)))
#> $x
#> [1] 1
#> 
#> $y
#>   a b
#> 1 2 3
#> 
squash0(list(x = 1, y = data.frame(a = 2, b = 3)))
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#>   a b
#> 1 2 3
#> 

# empty list returns NULL
squash(list())
#> NULL
squash0(list(NULL, numeric()))
#> NULL

# inner names are preserved
squash(list(a = 1, b = list(list(a = 1))))
#> $a
#> [1] 1
#> 
#> $a
#> [1] 1
#> 

# result nor any elements of the input list are simplified
unlist(list(1, 2, 3))
#> [1] 1 2 3
squash0(list(1, 2, 3))
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 
unlist(list(1:3, list("a", "b")), recursive = FALSE)
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 
#> [[4]]
#> [1] "a"
#> 
#> [[5]]
#> [1] "b"
#> 
squash0(list(1:3, list("a", "b")))
#> [[1]]
#> [1] 1 2 3
#> 
#> [[2]]
#> [1] "a"
#> 
#> [[3]]
#> [1] "b"
#> 
```
