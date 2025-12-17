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

// TODO: Remove in SWIG JSE 5.0.12
%typemap(ts) SWIGTYPE *, SWIGTYPE & "$typemap(ts, $*1_ltype)";
%typemap(ts) char [ANY] "string";

// https://github.com/swig/swig/issues/3120
// This enum will have to have a name in PROJ
%ignore proj_create_from_name;

// Because of a large number of improvements for proj.js
#if SWIG_VERSION < 0x050011
#error Generating this project requires SWIG JSE 5.0.11
#endif

%include <capi.i>
