%module "proj-capi.js";

#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error This project requires SWIG JavaScript Evolution
#endif

%include <arrays_javascript.i>
%include <std_vector.i>

%{
#include <proj.h>
%}

%apply unsigned long long { size_t };

// https://github.com/swig/swig/issues/3120
// This enum will have to have a name in PROJ
%ignore proj_create_from_name;
%rename(proj_create_from_name) proj_create_from_name2;

// Because of a large number of improvements for proj.js
#if SWIG_VERSION < 0x050011
#error Generating this project requires SWIG JSE 5.0.11
#endif

%include <capi.i>

%inline %{
PJ_OBJ_LIST *proj_create_from_name2(PJ_CONTEXT *ctx, const char *auth_name,
                      const char *searchedName, PJ_TYPE *types, size_t typesCount,
                      int approximateMatch, size_t limitResultCount,
                      const char *const *options);
%}
%wrapper %{
PJ_OBJ_LIST *proj_create_from_name2(PJ_CONTEXT *ctx, const char *auth_name,
                      const char *searchedName, PJ_TYPE *types, size_t typesCount,
                      int approximateMatch, size_t limitResultCount,
                      const char *const *options) {
  return proj_create_from_name(ctx, auth_name, searchedName, types,
    typesCount, approximateMatch, limitResultCount, options);
}
%}
