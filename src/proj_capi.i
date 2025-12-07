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

// Only we can destroy
%ignore proj_destroy;

// Opaque types cannot be extended
// This hack allows to add a destructor to an opaque type
// Maybe this could become a SWIG feature at some point
// because it is a common design pattern in old C software

// Do not wrap PROJ's own PJ
%ignore PJconsts;
%ignore PJ;

// Create another type that holds a pointer to PJ
// and destroys it on destruction.
// It will replace PJ and take its name
%rename(PJ) jsPJ;
%ignore jsPJ::get;
%inline %{
class jsPJ {
  PJ *self;
public:
  jsPJ(PJ *v): self(v) {}
  ~jsPJ() { proj_destroy(self); }
  PJ *get() { return self; }
  const char* toString() { return proj_get_name(self); }
};

%}

// Convert all PJ to jsPJ
%typemap(in) PJ * {
  jsPJ *wrap;
  $typemap(in, jsPJ *, 1=wrap);
  $1 = wrap->get();
}
%typemap(out) PJ * {
  jsPJ *wrap = new jsPJ($1);
  $typemap(out, jsPJ *, 1=wrap, owner=SWIG_POINTER_OWN);
}

%typemap(ts) PJ * "PJ";

%include <capi.i>
