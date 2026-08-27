#ifndef DUP_TRACKER_H
#define DUP_TRACKER_H

#include <Rinternals.h>
#include <stddef.h>

typedef struct // track dups per node
{
    const char **keys;
    int *seen_index;
    int n;
    int cap;
} dup_tracker;

void tracker_init(dup_tracker *t, int cap);
int tracker_find(dup_tracker *t, const char *key);
void tracker_add(dup_tracker *t, const char *key, int idx);

#endif