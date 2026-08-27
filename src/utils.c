#include <Rinternals.h>
#include <string.h>

bool is_pure_numeric(const char *s) // is a string wholely 0-9
{
    if (*s == '\0')
        return false;
    while (*s)
    {
        if (*s < '0' || *s > '9')
            return false;
        s++;
    }
    return true;
}

bool already_wrapped(const char *name, const char *wrap) // is a name already wrapped with the given str
{
    size_t nl = strlen(name), wl = strlen(wrap);
    if (nl < 2 * wl)
        return false;
    if (strncmp(name, wrap, wl) != 0)
        return false;
    if (strncmp(name + nl - wl, wrap, wl) != 0)
        return false;
    size_t inner_len = nl - 2 * wl;
    char buf[128];
    if (inner_len >= sizeof(buf))
        return false;
    memcpy(buf, name + wl, inner_len);
    buf[inner_len] = '\0';
    return is_pure_numeric(buf);
}

bool ends_with_dup_pattern_number(const char *name, const char *marker) // does the name end with the pattern marker + number
{
    size_t nl = strlen(name);
    size_t ml = strlen(marker);

    if (nl <= ml)
        return false;

    for (size_t i = 0; i <= nl - ml; i++)
    {
        if (strncmp(name + i, marker, ml) == 0)
        {
            const char *num = name + i + ml;

            if (*num == '\0')
                return false;

            while (*num)
            {
                if (*num < '0' || *num > '9')
                    return false;
                num++;
            }

            return true;
        }
    }

    return false;
}

int is_not_flattenable(SEXP x)
{
    return TYPEOF(x) != VECSXP || Rf_isDataFrame(x);
}

R_xlen_t count_leaves(SEXP x)
{
    if (x == R_NilValue)
        return 0;

    if (is_not_flattenable(x))
        return Rf_xlength(x) > 0 ? 1 : 0;

    const R_xlen_t n = Rf_xlength(x);

    if (n == 0)
        return 0;

    R_xlen_t total = 0;

    for (R_xlen_t i = 0; i < n; ++i)
        total += count_leaves(VECTOR_ELT(x, i));

    return total;
}

R_xlen_t count_leaves_keep(SEXP x)
{
    if (x == R_NilValue)
        return 1;

    if (is_not_flattenable(x))
        return 1;

    const R_xlen_t n = Rf_xlength(x);

    if (n == 0)
        return 1;

    R_xlen_t total = 0;

    for (R_xlen_t i = 0; i < n; ++i)
        total += count_leaves_keep(VECTOR_ELT(x, i));

    return total;
}

char *format_path_component(int index, const char *name)
{
    char *component;

    if (name && strlen(name) > 0)
    {
        // Check if name is purely numeric (no quotes needed, but must be quoted to distinguish from index)
        bool is_numeric = true;
        for (const char *p = name; *p; p++)
        {
            if (*p < '0' || *p > '9')
            {
                is_numeric = false;
                break;
            }
        }

        if (is_numeric)
        {
            // Numeric name: must use quotes
            int needed = snprintf(NULL, 0, "[[\"%s\"]]", name);
            if (needed < 0)
                error("snprintf failed");
            component = (char *)R_alloc(needed + 1, 1);
            snprintf(component, needed + 1, "[[\"%s\"]]", name);
        }
        else
        {
            // Check for quotes in the name
            bool has_double_quote = false;
            bool has_single_quote = false;

            for (const char *p = name; *p; p++)
            {
                if (*p == '"')
                    has_double_quote = true;
                else if (*p == '\'')
                    has_single_quote = true;
            }

            // Choose quote style that avoids escaping
            char quote_char;
            if (!has_double_quote)
            {
                quote_char = '"';
            }
            else if (!has_single_quote)
            {
                quote_char = '\'';
            }
            else
            {
                // Name contains both types of quotes - use double quotes and escape
                quote_char = '"';
                // Escape double quotes in the name
                int escaped_len = 0;
                for (const char *p = name; *p; p++)
                {
                    if (*p == '"')
                        escaped_len += 2;
                    else
                        escaped_len += 1;
                }

                char *escaped = (char *)R_alloc(escaped_len + 1, 1);
                char *dest = escaped;
                for (const char *src = name; *src; src++)
                {
                    if (*src == '"')
                    {
                        *dest++ = '\\';
                        *dest++ = '"';
                    }
                    else
                    {
                        *dest++ = *src;
                    }
                }
                *dest = '\0';

                int needed = snprintf(NULL, 0, "[[%c%s%c]]", quote_char, escaped, quote_char);
                if (needed < 0)
                    error("snprintf failed");
                component = (char *)R_alloc(needed + 1, 1);
                snprintf(component, needed + 1, "[[%c%s%c]]", quote_char, escaped, quote_char);
                return component;
            }

            // No escaping needed
            int needed = snprintf(NULL, 0, "[[%c%s%c]]", quote_char, name, quote_char);
            if (needed < 0)
                error("snprintf failed");
            component = (char *)R_alloc(needed + 1, 1);
            snprintf(component, needed + 1, "[[%c%s%c]]", quote_char, name, quote_char);
        }
    }
    else
    {
        // No name: use numeric index
        int needed = snprintf(NULL, 0, "[[%d]]", index + 1);
        if (needed < 0)
            error("snprintf failed");
        component = (char *)R_alloc(needed + 1, 1);
        snprintf(component, needed + 1, "[[%d]]", index + 1);
    }

    return component;
}