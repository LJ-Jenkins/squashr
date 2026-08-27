#include <R.h>
#include <Rinternals.h>
#include <string.h>
#include <stdbool.h>
#include "buffer.h"
#include "dup_tracker.h"
#include "utils.h"
#include "arg_checks.h"

// Recursive function to traverse the list and build the result and names
static void squash_track_ptr_recurse(SEXP x, pathbuf *path, const char *sep, const char *wrap, const char *dup_marker, bool mark_dup, SEXP result, SEXP names, int *idx)
{
    R_xlen_t n = Rf_xlength(x);

    if (TYPEOF(x) != VECSXP || Rf_isDataFrame(x) || n == 0)
    {
        SET_VECTOR_ELT(result, *idx, x);
        SET_STRING_ELT(names, *idx, Rf_mkChar(path->buf));
        (*idx)++;
        return;
    }

    SEXP nms = getAttrib(x, R_NamesSymbol);
    dup_tracker tracker;
    if (mark_dup)
        tracker_init(&tracker, n * 2 + 1);
    for (int i = 0; i < n; i++)
    {
        const char *comp;
        char idxbuf[32];
        const char *raw;
        if (nms != R_NilValue && STRING_ELT(nms, i) != NA_STRING && CHAR(STRING_ELT(nms, i))[0] != '\0')
        {
            raw = CHAR(STRING_ELT(nms, i));
            if (strstr(raw, sep) != NULL)
                Rf_error("Name `%s` contains separator `%s`.", raw, sep);
            if (already_wrapped(raw, wrap))
                Rf_error("Name `%s` already matches wrapped numeric format.", raw);
            if (mark_dup && ends_with_dup_pattern_number(raw, dup_marker))
            {
                Rf_error("Name `%s` already matches the duplicate marker pattern `%s<number>`.",
                         raw, dup_marker);
            }
            if (is_pure_numeric(raw))
            {
                char *tmp = (char *)R_alloc(strlen(raw) + 2 * strlen(wrap) + 1, 1);
                strcpy(tmp, wrap);
                strcat(tmp, raw);
                strcat(tmp, wrap);
                comp = tmp;
            }
            else
                comp = raw;
        }
        else
        {
            snprintf(idxbuf, 32, "%d", i + 1);
            comp = idxbuf;
        }
        if (mark_dup)
        {
            int pos = tracker_find(&tracker, comp);
            if (pos >= 0)
            { // duplicate: append index
                char buf[32];
                snprintf(buf, 32, "%s%d", dup_marker, i + 1);
                size_t mark = buf_mark(path);
                if (path->len > 0)
                    buf_append(path, sep);
                buf_append(path, comp);
                buf_append(path, buf);
                squash_track_ptr_recurse(VECTOR_ELT(x, i), path, sep, wrap, dup_marker, mark_dup, result, names, idx);
                buf_restore(path, mark);
                continue;
            }
            else
            {
                tracker_add(&tracker, comp, i + 1);
            }
        }
        size_t mark = buf_mark(path);
        if (path->len > 0)
            buf_append(path, sep);
        buf_append(path, comp);
        squash_track_ptr_recurse(VECTOR_ELT(x, i), path, sep, wrap, dup_marker, mark_dup, result, names, idx);
        buf_restore(path, mark);
    }
}

SEXP squash_track_C(SEXP x, SEXP sep, SEXP wrap, SEXP unique)
{
    if (TYPEOF(x) != VECSXP)
        Rf_error("`x` must be a list or data frame.");

    if (Rf_xlength(x) == 0)
        return x;

    squash_arg_checks(sep, wrap, unique);

    const char *separator = CHAR(STRING_ELT(sep, 0));
    const char *wrap_str = CHAR(STRING_ELT(wrap, 0));
    const char *dup_marker = NULL;
    bool mark_dup = false;

    if (TYPEOF(unique) == LGLSXP)
    {
        mark_dup = false;
        dup_marker = NULL;
    }
    else if (TYPEOF(unique) == STRSXP)
    {
        dup_marker = CHAR(STRING_ELT(unique, 0));
        mark_dup = true;
    }

    int leaves = count_leaves_keep(x);
    SEXP res = PROTECT(Rf_allocVector(VECSXP, leaves));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, leaves));
    Rf_setAttrib(res, R_NamesSymbol, nms);

    pathbuf path;
    buf_init(&path);

    int idx = 0;
    squash_track_ptr_recurse(
        x,
        &path,
        separator,
        wrap_str,
        dup_marker,
        mark_dup,
        res,
        nms,
        &idx);

    SEXP class_attr = PROTECT(Rf_allocVector(STRSXP, 1));
    SET_STRING_ELT(class_attr, 0, Rf_mkChar("squashed"));
    Rf_classgets(res, class_attr);
    UNPROTECT(1);

    Rf_setAttrib(res, Rf_install("sep"), sep);
    Rf_setAttrib(res, Rf_install("wrap"), wrap);
    if (mark_dup)
        Rf_setAttrib(res, Rf_install("unique_names"), unique);

    UNPROTECT(2);
    return res;
}