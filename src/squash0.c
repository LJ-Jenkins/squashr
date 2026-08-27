#include <R.h>
#include <Rinternals.h>
#include "utils.h"

static void fill_leaves(SEXP x, SEXP res, R_xlen_t *pos)
{
    if (x == R_NilValue)
        return;

    if (is_not_flattenable(x))
    {
        if (Rf_xlength(x) == 0)
            return;
        SET_VECTOR_ELT(res, (*pos)++, x);
        return;
    }

    const R_xlen_t n = Rf_xlength(x);

    if (n == 0)
        return;

    for (R_xlen_t i = 0; i < n; ++i)
        fill_leaves(VECTOR_ELT(x, i), res, pos);
}

SEXP squash0_C(SEXP x)
{
    if (is_not_flattenable(x))
        return x;

    const R_xlen_t n = Rf_xlength(x);

    if (n == 0)
        return R_NilValue;

    const R_xlen_t nleaves = count_leaves(x);

    if (nleaves == 0)
        return R_NilValue;

    SEXP res = PROTECT(Rf_allocVector(VECSXP, nleaves));

    R_xlen_t pos = 0;

    fill_leaves(x, res, &pos);

    UNPROTECT(1);

    return res;
}