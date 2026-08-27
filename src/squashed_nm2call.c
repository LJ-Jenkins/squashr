#include <R.h>
#include <Rinternals.h>
#include <string.h>
#include <stdbool.h>
#include "utils.h"
#include "arg_checks.h"

// split using same logic as squash_C separator handling
static int split_string(const char *input, const char *sep, char ***out)
{
    size_t sep_len = strlen(sep);
    int count = 1;

    for (const char *p = input; *p; p++)
    {
        if (strncmp(p, sep, sep_len) == 0)
        {
            count++;
            p += sep_len - 1;
        }
    }

    char **parts = (char **)R_alloc(count, sizeof(char *));

    int idx = 0;
    const char *start = input;
    const char *cur = input;

    while (*cur)
    {
        if (strncmp(cur, sep, sep_len) == 0)
        {
            size_t len = cur - start;
            char *part = (char *)R_alloc(len + 1, 1);
            memcpy(part, start, len);
            part[len] = '\0';
            parts[idx++] = part;

            cur += sep_len;
            start = cur;
        }
        else
        {
            cur++;
        }
    }

    size_t len = cur - start;
    char *part = (char *)R_alloc(len + 1, 1);
    memcpy(part, start, len);
    part[len] = '\0';
    parts[idx++] = part;

    *out = parts;
    return count;
}

typedef enum
{
    TOK_INT,
    TOK_STR
} tok_type;

typedef struct
{
    tok_type type;
    int i;
    const char *s;
} token;

static SEXP build_call_with_placeholder(token *toks, int n, const char *var)
{
    if (n == 0)
        return R_NilValue;

    int nprot = 0;

    SEXP placeholder = PROTECT(Rf_install(var));
    nprot++;

    SEXP chain = placeholder;

    // Build chain: .data[[idx1]][[idx2]]...[[idxN]]
    for (int i = 0; i < n; i++)
    {
        SEXP idx;
        if (toks[i].type == TOK_INT)
        {
            idx = PROTECT(Rf_ScalarInteger(toks[i].i));
            nprot++;
        }
        else
        {
            idx = PROTECT(Rf_ScalarString(Rf_mkChar(toks[i].s)));
            nprot++;
        }

        // Create: chain[[ idx ]]
        chain = PROTECT(Rf_lang3(R_Bracket2Symbol, chain, idx));
        nprot++;
    }

    UNPROTECT(nprot);
    return chain;
}

static void parse_parts(char **parts, int n,
                        const char *wrap,
                        const char *dup_marker,
                        token *out)
{
    size_t wlen = strlen(wrap);
    size_t mlen = dup_marker ? strlen(dup_marker) : 0;

    for (int i = 0; i < n; i++)
    {
        const char *p = parts[i];

        // ---- check for duplicate marker pattern ----
        if (dup_marker)
        {
            const char *pos = strstr(p, dup_marker);
            if (pos)
            {
                // Check if what follows is a pure number (whole number)
                const char *num_start = pos + mlen;
                if (is_pure_numeric(num_start))
                {
                    // Duplicate marker followed by whole number -> use the number as index
                    out[i].type = TOK_INT;
                    out[i].i = atoi(num_start);
                    continue;
                }
                // Otherwise, treat the whole thing as a string (the marker is part of the name)
                // e.g., "r*1.2" stays as "r*1.2"
            }
        }

        size_t plen = strlen(p);

        if (plen >= 2 * wlen &&
            strncmp(p, wrap, wlen) == 0 &&
            strncmp(p + plen - wlen, wrap, wlen) == 0)
        {
            size_t inner_len = plen - 2 * wlen;
            char *inner = (char *)R_alloc(inner_len + 1, 1);
            memcpy(inner, p + wlen, inner_len);
            inner[inner_len] = '\0';

            // Check if the inner content is purely numeric (whole number)
            if (is_pure_numeric(inner))
            {
                // Was a whole number name - unwrap to string
                out[i].type = TOK_STR;
                out[i].s = inner;
            }
            else
            {
                // Was a name that actually had quotes - keep wrapped
                out[i].type = TOK_STR;
                out[i].s = p;
            }
            continue;
        }

        // ---- plain numeric -> index ----
        if (is_pure_numeric(p))
        {
            out[i].type = TOK_INT;
            out[i].i = atoi(p);
            continue;
        }

        // ---- default -> string ----
        out[i].type = TOK_STR;
        out[i].s = p;
    }
}

SEXP squashed_nm2call_C(SEXP nm, SEXP var, SEXP sep, SEXP wrap, SEXP unique_names)
{
    if (TYPEOF(nm) != STRSXP || Rf_xlength(nm) == 0)
        Rf_error("`nm` must be a non-empty character vector.");

    if (TYPEOF(var) != STRSXP || Rf_xlength(var) != 1 || STRING_ELT(var, 0) == NA_STRING)
        Rf_error("`var` must be a single non-NA string.");
    if (strlen(CHAR(STRING_ELT(var, 0))) == 0)
        Rf_error("`var` must be a non-empty string.");

    squash_arg_checks(sep, wrap, unique_names);

    const char *var_str = CHAR(STRING_ELT(var, 0));

    const char *separator = CHAR(STRING_ELT(sep, 0));
    const char *wrap_str = CHAR(STRING_ELT(wrap, 0));
    const char *dup_marker = NULL;

    if (TYPEOF(unique_names) == LGLSXP)
    {
        dup_marker = NULL;
    }
    else if (TYPEOF(unique_names) == STRSXP)
    {
        dup_marker = CHAR(STRING_ELT(unique_names, 0));
    }

    R_xlen_t n = Rf_xlength(nm);

    // If only one string, return a single call, not a list
    if (n == 1)
    {
        if (STRING_ELT(nm, 0) == NA_STRING)
            Rf_error("`nm` cannot be NA.");

        const char *input = CHAR(STRING_ELT(nm, 0));

        if (*input == '\0')
            Rf_error("`nm` cannot be an empty string.");

        char **parts;
        int n_parts = split_string(input, separator, &parts);

        token *toks = (token *)R_alloc(n_parts, sizeof(token));
        parse_parts(parts, n_parts, wrap_str, dup_marker, toks);

        SEXP call = build_call_with_placeholder(toks, n_parts, var_str);
        return call;
    }

    // Multiple strings - return a list
    SEXP out = PROTECT(allocVector(VECSXP, n));

    for (R_xlen_t i = 0; i < n; i++)
    {
        if (STRING_ELT(nm, i) == NA_STRING)
            Rf_error("`nm` cannot contain contain NA.");

        const char *input = CHAR(STRING_ELT(nm, i));

        if (*input == '\0')
            Rf_error("`nm` cannot contain empty strings.");

        char **parts;
        int n_parts = split_string(input, separator, &parts);

        token *toks = (token *)R_alloc(n_parts, sizeof(token));
        parse_parts(parts, n_parts, wrap_str, dup_marker, toks);

        SEXP call = build_call_with_placeholder(toks, n_parts, var_str);
        SET_VECTOR_ELT(out, i, call);
    }

    UNPROTECT(1);
    return out;
}