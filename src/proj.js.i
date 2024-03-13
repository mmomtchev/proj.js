%module "proj.js";

#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error This project requires SWIG JavaScript Evolution
#endif

%include <exception.i>

// Rethrow all C++ exceptions as JS exceptions
%exception {
  try {
    $action
  } catch (const std::exception &e) {
    SWIG_Raise(e.what());
    SWIG_fail;
  }
}

%nspace;

// Bypass PROJ own namespace handling, we have to reimplement this the SWIG way
#define NS_PROJ
#define NS_PROJ_START
#define NS_PROJ_END

%{
#define NS_PROJ
#define NS_PROJ_START
#define NS_PROJ_END
%}

// https://www.youtube.com/watch?v=E0YHZXz5hEE
%rename("$ignore", regextarget=1, fullname=1) "dropbox";

namespace util {
  %include <proj/util.hpp>
}

namespace operation {
  %include <proj/coordinateoperation.hpp>
}

#define DO_NOT_DEFINE_EXTERN_DERIVED_CRS_TEMPLATE
namespace crs {
  %include <proj/crs.hpp>
}

%include "io.i"

// Because of https://github.com/mmomtchev/swig/issues/23
#if SWIG_VERSION < 0x050002
#error Generating this project requires SWIG JSE 5.0.2
#endif
%{
// Because of https://github.com/emscripten-core/emscripten/pull/21041
#ifdef __EMSCRIPTEN__
#include <emscripten/version.h>
#if __EMSCRIPTEN_major__ < 3 || (__EMSCRIPTEN_major__ == 3 && __EMSCRIPTEN_minor__ < 1) || (__EMSCRIPTEN_major__ == 3 && __EMSCRIPTEN_minor__ == 1 && __EMSCRIPTEN_tiny__ < 52)
#error Building this project requires emscripten 3.1.52
#endif
#endif
%}
