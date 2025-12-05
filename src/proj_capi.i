%module "proj-capi.js";

#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error This project requires SWIG JavaScript Evolution
#endif

%include <arrays_javascript.i>

%{
#include <proj.h>
%}

%apply unsigned long long { size_t };

// TODO: Should be added to SWIG
%typemap(ts) SWIGTYPE *, SWIGTYPE & "$typemap(ts, $*1_ltype)";
%typemap(ts) char [ANY] "string";

// Because of a large number of improvements for proj.js
#if SWIG_VERSION < 0x050011
#error Generating this project requires SWIG JSE 5.0.11
#endif

// Destruction of PJ in the C API will be a nightmare
// Objects will have to be earmarked per returning function

// Only we can destroy
%ignore proj_destroy;

%include <capi.i>
