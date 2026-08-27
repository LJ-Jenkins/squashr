#include <Rinternals.h>
#include <string.h>
#include "buffer.h"

void buf_init(pathbuf *b) // buffer initialization
{
    b->cap = 256;
    b->len = 0;
    b->buf = (char *)R_alloc(b->cap, 1);
    b->buf[0] = '\0';
}

size_t buf_mark(pathbuf *b) { return b->len; } // mark current position for backtracking

void buf_restore(pathbuf *b, size_t m) // restore to a previous mark (backtracking)
{
    b->len = m;
    b->buf[m] = '\0';
}

void buf_append(pathbuf *b, const char *s) // append a string to the buffer, resizing if necessary
{
    size_t n = strlen(s);
    if (b->len + n + 1 > b->cap)
    {
        size_t nc = b->cap * 2 + n;
        char *tmp = (char *)R_alloc(nc, 1);
        memcpy(tmp, b->buf, b->len);
        b->buf = tmp;
        b->cap = nc;
    }
    memcpy(b->buf + b->len, s, n);
    b->len += n;
    b->buf[b->len] = '\0';
}