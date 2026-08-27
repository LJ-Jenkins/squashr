#include <R.h>
#include <Rinternals.h>
#include "utils.h"

static void fill_leaves_with_names(SEXP x, const char *own_name,
                                   SEXP res, SEXP nms_res, R_xlen_t *pos,
                                   int keep_empty)
{
    if (x == R_NilValue)
    {
        if (!keep_empty)
            return;
        SET_VECTOR_ELT(res, *pos, x);
        SET_STRING_ELT(nms_res, *pos, Rf_mkChar(own_name));
        (*pos)++;
        return;
    }

    if (is_not_flattenable(x))
    {
        if (!keep_empty && Rf_xlength(x) == 0)
            return;
        SET_VECTOR_ELT(res, *pos, x);
        SET_STRING_ELT(nms_res, *pos, Rf_mkChar(own_name));
        (*pos)++;
        return;
    }

    const R_xlen_t n = Rf_xlength(x);

    if (n == 0)
    {
        if (!keep_empty)
            return;
        SET_VECTOR_ELT(res, *pos, x);
        SET_STRING_ELT(nms_res, *pos, Rf_mkChar(own_name));
        (*pos)++;
        return;
    }

    SEXP child_nms = Rf_getAttrib(x, R_NamesSymbol);

    for (R_xlen_t i = 0; i < n; ++i)
    {
        const char *child_nm = "";
        if (child_nms != R_NilValue)
        {
            SEXP s = STRING_ELT(child_nms, i);
            if (s != NA_STRING)
                child_nm = CHAR(s);
        }
        fill_leaves_with_names(VECTOR_ELT(x, i), child_nm, res, nms_res, pos, keep_empty);
    }
}

SEXP squash_C(SEXP x, SEXP keep_empty_sexp)
{
    if (TYPEOF(keep_empty_sexp) != LGLSXP || Rf_xlength(keep_empty_sexp) != 1)
        Rf_error("`keep.empty` must be a single logical.");
    int keep_empty = LOGICAL(keep_empty_sexp)[0] == TRUE;

    if (is_not_flattenable(x))
        return x;

    const R_xlen_t n = Rf_xlength(x);

    if (n == 0)
        return R_NilValue;

    const R_xlen_t nleaves = keep_empty ? count_leaves_keep(x) : count_leaves(x);

    if (nleaves == 0)
        return R_NilValue;

    SEXP res = PROTECT(Rf_allocVector(VECSXP, nleaves));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, nleaves));

    R_xlen_t pos = 0;

    SEXP top_nms = Rf_getAttrib(x, R_NamesSymbol);

    for (R_xlen_t i = 0; i < n; ++i)
    {
        const char *nm = "";
        if (top_nms != R_NilValue)
        {
            SEXP s = STRING_ELT(top_nms, i);
            if (s != NA_STRING)
                nm = CHAR(s);
        }
        fill_leaves_with_names(VECTOR_ELT(x, i), nm, res, nms, &pos, keep_empty);
    }

    int has_name = 0;
    for (R_xlen_t i = 0; i < nleaves; ++i)
    {
        if (CHAR(STRING_ELT(nms, i))[0] != '\0')
        {
            has_name = 1;
            break;
        }
    }
    if (has_name)
        Rf_setAttrib(res, R_NamesSymbol, nms);

    UNPROTECT(2);

    return res;
}