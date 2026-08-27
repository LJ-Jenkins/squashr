#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

extern SEXP squash_C(SEXP x, SEXP keep_empty);
extern SEXP squash0_C(SEXP x);
extern SEXP squash_track_C(SEXP x, SEXP sep, SEXP wrap, SEXP unique);
extern SEXP squash_track_no_dups_C(SEXP x);
extern SEXP squashed_nm2call_C(SEXP nm, SEXP var, SEXP sep, SEXP wrap, SEXP unique_names);

static const R_CallMethodDef callMethods[] = {
    {"squash_C", (DL_FUNC)&squash_C, 2},
    {"squash0_C", (DL_FUNC)&squash0_C, 1},
    {"squash_track_C", (DL_FUNC)&squash_track_C, 4},
    {"squash_track_no_dups_C", (DL_FUNC)&squash_track_no_dups_C, 1},
    {"squashed_nm2call_C", (DL_FUNC)&squashed_nm2call_C, 5},
    {NULL, NULL, 0}};

void R_init_squashr(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
