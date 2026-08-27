#include <R.h>
#include <Rinternals.h>
#include <string.h>
#include <stdbool.h>
#include "buffer.h"
#include "utils.h"

static void buf_append_component(pathbuf *b, int index, const char *name)
{
    if (!name)
    {
        char tmp[32];
        int n = snprintf(tmp, sizeof(tmp), "[[%d]]", index + 1);
        if (b->len + (size_t)n + 1 > b->cap)
        {
            size_t nc = b->cap * 2 + b->len + (size_t)n + 1;
            char *new_buf = (char *)R_alloc(nc, 1);
            memcpy(new_buf, b->buf, b->len);
            b->buf = new_buf;
            b->cap = nc;
        }
        memcpy(b->buf + b->len, tmp, n);
        b->len += n;
        b->buf[b->len] = '\0';
        return;
    }

    bool has_dquote = false, has_squote = false;
    for (const char *p = name; *p; p++)
    {
        if (*p == '"')
            has_dquote = true;
        else if (*p == '\'')
            has_squote = true;
    }

    size_t nlen = strlen(name);

    if (has_dquote && has_squote)
    {
        size_t esc_len = 0;
        for (const char *p = name; *p; p++)
            esc_len += (*p == '"') ? 2 : 1;
        size_t needed = esc_len + 7;
        if (b->len + needed + 1 > b->cap)
        {
            size_t nc = b->cap * 2 + b->len + needed + 1;
            char *tmp = (char *)R_alloc(nc, 1);
            memcpy(tmp, b->buf, b->len);
            b->buf = tmp;
            b->cap = nc;
        }
        char *p = b->buf + b->len;
        *p++ = '[';
        *p++ = '[';
        *p++ = '"';
        for (const char *s = name; *s; s++)
        {
            if (*s == '"')
            {
                *p++ = '\\';
                *p++ = '"';
            }
            else
                *p++ = *s;
        }
        *p++ = '"';
        *p++ = ']';
        *p++ = ']';
        *p = '\0';
        b->len = (size_t)(p - b->buf);
        return;
    }

    char quote = has_dquote ? '\'' : '"';
    size_t needed = nlen + 7;
    if (b->len + needed + 1 > b->cap)
    {
        size_t nc = b->cap * 2 + b->len + needed + 1;
        char *tmp = (char *)R_alloc(nc, 1);
        memcpy(tmp, b->buf, b->len);
        b->buf = tmp;
        b->cap = nc;
    }
    char *p = b->buf + b->len;
    *p++ = '[';
    *p++ = '[';
    *p++ = quote;
    memcpy(p, name, nlen);
    p += nlen;
    *p++ = quote;
    *p++ = ']';
    *p++ = ']';
    *p = '\0';
    b->len = (size_t)(p - b->buf);
}

static void squash_no_dups_recurse_C(SEXP x, pathbuf *path, SEXP result, SEXP names, int *idx)
{
    R_xlen_t n = Rf_xlength(x);

    // non-list, data frame, or empty list
    if (TYPEOF(x) != VECSXP || Rf_isDataFrame(x) || n == 0)
    {
        SET_VECTOR_ELT(result, *idx, x);
        SET_STRING_ELT(names, *idx, Rf_mkChar(path->buf));
        (*idx)++;
        return;
    }

    SEXP nms = Rf_getAttrib(x, R_NamesSymbol);

    for (int i = 0; i < n; i++)
    {
        const char *raw_name = NULL;
        if (nms != R_NilValue && STRING_ELT(nms, i) != NA_STRING)
        {
            raw_name = CHAR(STRING_ELT(nms, i));
            if (raw_name[0] == '\0')
                raw_name = NULL;
        }

        // check for duplicate names at this level without allocating a tracker
        if (raw_name)
        {
            for (int j = 0; j < i; j++)
            {
                const char *prev = NULL;
                if (nms != R_NilValue && STRING_ELT(nms, j) != NA_STRING)
                {
                    prev = CHAR(STRING_ELT(nms, j));
                    if (prev[0] == '\0')
                        prev = NULL;
                }
                if (prev && strcmp(raw_name, prev) == 0)
                    Rf_error("Duplicate path component `%s`. Use `squash()` with `unique_names` to automatically disambiguate duplicates.", raw_name);
            }
        }

        size_t mark = buf_mark(path);
        buf_append_component(path, i, raw_name);

        squash_no_dups_recurse_C(VECTOR_ELT(x, i), path, result, names, idx);
        buf_restore(path, mark);
    }
}

SEXP squash_track_no_dups_C(SEXP x)
{
    if (TYPEOF(x) != VECSXP)
    {
        Rf_error("`x` must be a list or data frame.");
    }

    if (Rf_xlength(x) == 0)
    {
        return x;
    }

    int leaves = count_leaves_keep(x);
    SEXP res = PROTECT(Rf_allocVector(VECSXP, leaves));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, leaves));
    Rf_setAttrib(res, R_NamesSymbol, nms);

    pathbuf path;
    buf_init(&path);

    int idx = 0;
    squash_no_dups_recurse_C(x, &path, res, nms, &idx);

    SEXP class_attr = PROTECT(Rf_allocVector(STRSXP, 1));
    SET_STRING_ELT(class_attr, 0, Rf_mkChar("squashed0"));
    Rf_classgets(res, class_attr);
    UNPROTECT(1);

    UNPROTECT(2);
    return res;
}