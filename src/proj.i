%module "proj.js";

#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error This project requires SWIG JavaScript Evolution
#endif

%include <exception.i>
%include <std_string.i>
%include <std_vector.i>
%include <arrays_javascript.i>

// Rethrow all C++ exceptions as JS exceptions
%exception {
  try {
    $action
  } catch (const std::exception &e) {
    SWIG_Raise(e.what());
    SWIG_fail;
  }
}

%apply unsigned long long { size_t };

// TODO: Should be added to SWIG
%typemap(ts) SWIGTYPE *, SWIGTYPE & "$typemap(ts, $*1_ltype)";
%typemap(ts) char [ANY] "string";

#define PROJ_MSVC_DLL
#define PROJ_INTERNAL [[gnu::visibility("hidden")]]
#define PROJ_DLL
#define PROJ_GCC_DLL
#define PROJ_FOR_TEST [[gnu::visibility("hidden")]]
#define PROJ_PRIVATE private

// Include this in the wrapper
%{
#include <proj/util.hpp>
#include <proj/coordinateoperation.hpp>
#include <proj/crs.hpp>
#include <proj/io.hpp>

using namespace NS_PROJ;
%}

// PROJ makes extensive use of class methods that are public but are hidden and
// are not available from outside the library itself
%rename("$ignore", %$isgnuhidden) "";

%rename("clone") operator=;
%rename("equal") operator==;
%rename("not_equal") operator!=;
%rename("lt") operator<;
%rename("toString") operator std::string;

// Convert all returned std::vectors to JavaScript arrays
%apply(std::vector RETURN)            { std::vector };
%apply(std::vector *RETURN)           { std::vector *, std::vector & };

// Convert std::list
%include "std_list.i"

// Convert std::set
%include "std_set.i"

// This can be considered a plain string
%include "optional.i"

// Ignore the C API, it is in a separate module
%rename("$ignore", regextarget=1) "proj_.*";
%rename("%s") proj_js_inline_projdb;
%rename("%s") proj_js_build;

%include "capi.i"
%include "nn.i"
%include "util.i"
%include "common.i"
%include "io.i"
%include "metadata.i"
%include "operation.i"
%include "datum.i"
%include "coordinatesystem.i"
%include "crs.i"
%include "factory.i"

%include <proj/util.hpp>
%include <proj/io.hpp>
%include <proj/metadata.hpp>
%include <proj/common.hpp>
%include <proj/datum.hpp>
%include <proj/coordinatesystem.hpp>
%include <proj/coordinateoperation.hpp>
%include <proj/coordinatesystem.hpp>
%include <proj/crs.hpp>

// Because of a large number of improvements for proj.js
#if SWIG_VERSION < 0x050011
#error Generating this project requires SWIG JSE 5.0.11
#endif
