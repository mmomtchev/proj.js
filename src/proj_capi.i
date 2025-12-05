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

// TODO: This is a huge amount of work but it will be useful
%ignore PROJ_FILE_API;

// typedefed structs are known to SWIG with the name of the struct
%rename(PJ) PJconsts;

// https://github.com/swig/swig/issues/3120
%ignore proj_create_from_name;

// These types are opaque types in the C++ API
%typemap(ts) PJ_OBJ_LIST "unknown"
%typemap(ts) PJ_INSERT_SESSION "unknown"

%include "capi.i"

// SWIG can't deduce the type of PROJ_VERSION_NUMBER
#pragma SWIG nowarn=304

// This is because "const char*" is not really "const"
%immutable id;
%immutable descr;
%immutable major;
%immutable ell;
%immutable name;
%immutable to_meter;
%immutable defn;
%immutable release;
%immutable version;
%immutable searchpath;
%immutable paths;
%immutable description;
%immutable definition;
%immutable celestial_body_name;
%immutable auth_name;
%immutable code;
%immutable unit_name;
%include <../src/proj.h>
%mutable id;
%mutable descr;
%mutable major;
%mutable ell;
%mutable name;
%mutable to_meter;
%mutable defn;
%mutable release;
%mutable version;
%mutable searchpath;
%mutable paths;
%mutable description;
%mutable definition;
%mutable celestial_body_name;
%mutable auth_name;
%mutable code;
%mutable unit_name;

%constant proj_version = int PROJ_VERSION_NUMBER;

// Because of a large number of improvements for proj.js
#if SWIG_VERSION < 0x050011
#error Generating this project requires SWIG JSE 5.0.11
#endif
