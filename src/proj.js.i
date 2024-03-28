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

// Convert all returned std::vectors to JavaScript arrays
%apply(std::vector RETURN)            { std::vector };
%apply(std::vector *RETURN)           { std::vector *, std::vector & };

%include "capi.i"
%include "nn.i"
%include "util.i"
%include "common.i"
%include "io.i"
%include "operation.i"
%include "datum.i"
%include "coordinatesystem.i"
%include "crs.i"

%include <proj/util.hpp>
%include <proj/common.hpp>
%include <../src/proj.h>
%include <proj/io.hpp>
%include <proj/datum.hpp>
%include <proj/coordinatesystem.hpp>
%include <proj/coordinateoperation.hpp>
%include <proj/coordinatesystem.hpp>
%include <proj/crs.hpp>


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
