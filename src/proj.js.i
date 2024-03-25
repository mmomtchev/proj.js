%module "proj.js";

#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error This project requires SWIG JavaScript Evolution
#endif

%include <exception.i>
%include <std_string.i>

// Rethrow all C++ exceptions as JS exceptions
%exception {
  try {
    $action
  } catch (const std::exception &e) {
    SWIG_Raise(e.what());
    SWIG_fail;
  }
}

//%nspace;
#define PROJ_MSVC_DLL
#define PROJ_INTERNAL [[gnu::visibility("hidden")]]
#define PROJ_DLL
#define PROJ_GCC_DLL
#define PROJ_FOR_TEST [[gnu::visibility("hidden")]]

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

%include "nn.i"
%include "util.i"
%include "io.i"
%include "common.i"
%include "operation.i"
%include "datum.i"
%include "coordinatesystem.i"
%include "crs.i"

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
