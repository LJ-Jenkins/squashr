#ifndef BUFFER_H
#define BUFFER_H

#include <Rinternals.h>
#include <stddef.h>

typedef struct // path buffer
{
    char *buf;
    size_t len;
    size_t cap;
} pathbuf;

void buf_init(pathbuf *b);
size_t buf_mark(pathbuf *b);
void buf_restore(pathbuf *b, size_t m);
void buf_append(pathbuf *b, const char *s);

#endif