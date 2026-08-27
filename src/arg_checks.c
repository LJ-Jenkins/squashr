#include <Rinternals.h>
#include <string.h>

void squash_arg_checks(SEXP sep, SEXP wrap, SEXP unique)
{
    if (TYPEOF(sep) != STRSXP || Rf_xlength(sep) != 1 || STRING_ELT(sep, 0) == NA_STRING)
        Rf_error("`sep` must be a single non-NA string.");
    if (TYPEOF(wrap) != STRSXP || Rf_xlength(wrap) != 1 || STRING_ELT(wrap, 0) == NA_STRING)
        Rf_error("`wrap` must be a single non-NA string.");
    if (STRING_ELT(sep, 0) == STRING_ELT(wrap, 0))
        Rf_error("`sep` and `wrap` cannot be the same string.");
    if (strlen(CHAR(STRING_ELT(sep, 0))) == 0)
        Rf_error("`sep` must be a non-empty string.");
    if (strlen(CHAR(STRING_ELT(wrap, 0))) == 0)
        Rf_error("`wrap` must be a non-empty string.");

    if (TYPEOF(unique) == LGLSXP && Rf_xlength(unique) == 1)
    {
        if (LOGICAL(unique)[0] == NA_LOGICAL)
            Rf_error("`unique_names` cannot be NA.");
        if (LOGICAL(unique)[0] == TRUE)
            Rf_error("`unique_names = TRUE` is not allowed. Use FALSE to leave duplicates as-is, or a string to mark them.");
    }
    else if (TYPEOF(unique) == STRSXP && Rf_xlength(unique) == 1)
    {
        if (STRING_ELT(unique, 0) == NA_STRING)
            Rf_error("`unique_names` cannot be NA.");
        if (STRING_ELT(sep, 0) == STRING_ELT(unique, 0) || STRING_ELT(wrap, 0) == STRING_ELT(unique, 0))
            Rf_error("`unique_names` cannot be the same as `sep` or `wrap`.");
        if (strlen(CHAR(STRING_ELT(unique, 0))) == 0)
            Rf_error("`unique_names` must be a non-empty string.");
    }
    else
    {
        Rf_error("`unique_names` must be either a single logical or a single string.");
    }
}