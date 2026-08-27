#ifndef UTILS_H
#define UTILS_H

#include <Rinternals.h>
#include <stddef.h>

int is_not_flattenable(SEXP x);
R_xlen_t count_leaves(SEXP x);
R_xlen_t count_leaves_keep(SEXP x);
int is_list_a_df_ptr(SEXP x);
int count_leaves_ptr(SEXP x);
bool is_pure_numeric(const char *s);
bool already_wrapped(const char *name, const char *wrap);
bool ends_with_dup_pattern_number(const char *name, const char *marker);
char *format_path_component(int index, const char *name);

#endif