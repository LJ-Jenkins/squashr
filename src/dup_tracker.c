#include <Rinternals.h>
#include <string.h>
#include "dup_tracker.h"

void tracker_init(dup_tracker *t, int cap) // duplicate tracker initialization
{
    t->keys = (const char **)R_alloc(cap, sizeof(char *));
    t->seen_index = (int *)R_alloc(cap, sizeof(int));
    t->n = 0;
    t->cap = cap;
}

int tracker_find(dup_tracker *t, const char *key) // find a key in the tracker, return index or -1 if not found
{
    for (int i = 0; i < t->n; i++)
        if (strcmp(t->keys[i], key) == 0)
            return i;
    return -1;
}

void tracker_add(dup_tracker *t, const char *key, int idx) // add a key to the tracker
{
    if (t->n >= t->cap)
        Rf_error("dup_tracker overflow");
    t->keys[t->n] = key;
    t->seen_index[t->n] = idx;
    t->n++;
}