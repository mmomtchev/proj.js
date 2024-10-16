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

%include "capi.i"
%include "nn.i"
%include "util.i"
%include "common.i"
%include "io.i"
%include "operation.i"
%include "datum.i"
%include "coordinatesystem.i"
%include "crs.i"
%include "factory.i"

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

%include <proj/util.hpp>
%include <proj/io.hpp>
%include <proj/common.hpp>
%include <proj/datum.hpp>
%include <proj/coordinatesystem.hpp>
%include <proj/coordinateoperation.hpp>
%include <proj/coordinatesystem.hpp>
%include <proj/crs.hpp>

// Because of a large number of improvements for proj.js
#if SWIG_VERSION < 0x050005
#error Generating this project requires SWIG JSE 5.0.5
#endif
