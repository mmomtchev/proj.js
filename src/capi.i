// proj.js is a sync-only project, this skips lots of complexity
%begin %{
#define NAPI_HAS_THREADS 0
// This is a bug in SWIG
#include <condition_variable>
%}

// Per V8-isolate initialization
%header %{
struct proj_instance_data {
  PJ_CONTEXT *context;
  std::function<void(int, const char *)> log_fn;
};
#ifdef __EMSCRIPTEN__
extern const char *rootPath;
#endif
extern const bool proj_js_inline_projdb;
extern const char *proj_js_build;
%}

%immutable;
%typemap(ts) const char *proj_js_build "'wasm' | 'native'";
const char *proj_js_build;
const bool proj_js_inline_projdb;
%mutable;

// Support for transforming C/C++ functions into JS functions
%include <std_function.i>
// Support for transforming JS function into C/C++ function
// uses the SWIG_NAPI_Callback fragment and is much more awkward

%wrapper %{
#ifdef __EMSCRIPTEN__
const char *rootPath = "/";
const char *proj_js_build = "wasm";
#ifdef INLINE_PROJDB
const bool proj_js_inline_projdb = true;
#else
const bool proj_js_inline_projdb = false;
#endif
#else
const char *proj_js_build = "native";
const bool proj_js_inline_projdb = false;
#endif
%}

%header %{
#ifdef __EMSCRIPTEN__
// There are few very subtle differences between native and WASM (see proj_trans_generic)
#include <emnapi.h>
#endif
%}

// Normal braces expand SWIG macros such
// as SWIG_Raise
%init {
  auto *instance_data = new proj_instance_data;
  instance_data->context = proj_context_create();
  if (instance_data->context == nullptr) {
    SWIG_Raise("Failed to initialize PROJ context");
  }
  SWIG_NAPI_SetInstanceData(env, instance_data);
}

// %{%} braces conserve and emit preprocessor directives
%init %{
  env.AddCleanupHook([instance_data]() {
    // This is a huge problem because Node.js will  do a final GC pass
    // after the environment has been destroyed - and this is
    // something that PROJ does not appreciate at all.
    // The WASM module does not have this problem, destruction in WASM happens
    // when the tab is closed/refreshed which is NotOurProblem.
    // There is no easy solution.
    //
    // https://github.com/nodejs/node/issues/45088
    //
    // For now, proj.js leaks memory when loaded repeatedly in worker_threads
    //
#ifdef __SANITIZE_ADDRESS__
    proj_context_destroy(instance_data->context);
    delete instance_data;
#else
    (void)instance_data;
#endif
  });
%}

%init %{
#ifdef __EMSCRIPTEN__
  proj_context_set_search_paths(instance_data->context, 1, &rootPath);
#endif
%}

// Completely hide PJ_CONTEXT from the module user, always insert the argument from
// the environment context
%rename("$ignore", regextarget=1) "^proj_context_.*";

%typemap(in, numinputs=0, noblock=1) PJ_CONTEXT * {
  $1 = static_cast<proj_instance_data *>(SWIG_NAPI_GetInstanceData(env))->context;
}

// Using a typedef enum with the same name as the enum is an edge case
// especially when supporting both C++ and C
#pragma SWIG nowarn=302

// Windows at its best
// Mixing std::getenv with the WIN32 API (used by Node.js/libuv) does not always work
// (it seems to depend on the C++ runtime, the compiler used and probably the planetary alignment of the week)
%header %{
#if defined(_WIN32) || defined(__WIN32__)
#include <windows.h>
#include <tchar.h>
#endif

// PROJ and windows.h have a rather unfortunate conflict for STRICT
// that is solved if the header files are included normally
// https://github.com/OSGeo/PROJ/pull/2949
#ifdef STRICT
#undef STRICT
#endif
%}
%init %{
#if defined(_WIN32) || defined(__WIN32__)
  char _win_proj_data[1024];
  GetEnvironmentVariable(TEXT("PROJ_DATA"), _win_proj_data, sizeof(_win_proj_data));
  _putenv((std::string("PROJ_DATA=") + std::string(_win_proj_data)).c_str());
#endif
%}

// TODO: This is a huge amount of work but it will be useful
%ignore PROJ_FILE_API;

// SWIG can't deduce the type of PROJ_VERSION_NUMBER
#pragma SWIG nowarn=304

// Only we can destroy and only when the GC calls us
%rename("$ignore", regextarget=1) "proj.*_destroy";
%ignore proj_cleanup;

/**
 * ==================================================
 * Miscellaneous arguments that need special handling
 * ==================================================
 */

 // PJ_COORD
%apply double[4] { double v[4] };

%apply bool {
  int allow_deprecated,
  int deprecated,
  int crs_area_of_use_contains_bbox,
  int approximateMatch,
  int proj_is_deprecated,
  int proj_is_equivalent_to,
  int proj_is_equivalent_to_with_ctx,
  int proj_is_crs,
  int proj_is_derived_crs,
  int proj_crs_is_derived,
  int proj_coordoperation_is_instantiable
};
%typemap(ts) const char *auth_name "string | null";
%typemap(ts) const char *category "string | null";
%typemap(ts) PROJ_CRS_LIST_PARAMETERS *params "PROJ_CRS_LIST_PARAMETERS | null";

// Generic arrays from C pointer & length to JS Array
%define OUTPUT_DATA_LENGTH(TYPE)
%typemap(out) (TYPE *OUTPUT_DATA, size_t OUTPUT_LENGTH) {
  Napi::Array array = Napi::Array::New(env, $2);
  for (int i = 0; i < $2; i++) {
    Napi::Value js_val;
    $typemap(out, TYPE, 1=$1[i], result=js_val);
    array.Set(i, js_val);
  }
  $result = array;
}
%enddef
// Instantiated for int, double and PJ_TYPE
OUTPUT_DATA_LENGTH(int)
OUTPUT_DATA_LENGTH(double)
OUTPUT_DATA_LENGTH(PJ_TYPE)

// out_result_count is used in several functions
// we transform it to a local variable in each wrapper
%typemap(in, numinputs=0) int *out_result_count (int _global_out_result_count) {
  $1 = &_global_out_result_count;
};

// out_confidence is added to the return values which become an object
%typemap(in, numinputs=0) int **out_confidence (int *_global_out_confidence) {
  $1 = &_global_out_confidence;
};
%typemap(argout) int **out_confidence {
  size_t elements = proj_list_get_count(result);
  if ($1 != nullptr) {
    Napi::Value js_val;
    $typemap(out, (int *OUTPUT_DATA, size_t OUTPUT_LENGTH), 1=_global_out_confidence, 2=elements, result=js_val);
    proj_int_list_destroy(*$1);
    %append_output_field("confidence", js_val);
  }
}
%typemap(tsout, merge="object") int **out_confidence "confidence: number[]";

// Generic arrays from JS Array to C with pointer & length
// (search for $*n_ltype in SWIG manual)
%typemap(in, numinputs=1) (SWIGTYPE *array, size_t count) (std::shared_ptr<$*1_ltype []> data) {
  if (!$input.IsArray()) {
    SWIG_NAPI_Raise(env, "argument must be an array");
  }
  Napi::Array js_array = $input.As<Napi::Array>();
  data = std::shared_ptr<$*1_ltype []>(new $*1_ltype [js_array.Length()]);
  for (size_t i = 0; i < js_array.Length(); i++) {
    $typemap(in, $*1_type, input=js_array.Get(i), 1=data[i], argnum=argument array member);
  }
  $1 = data.get();
  $2 = js_array.Length();
}

// proj_create_from_name
%typemap(in, numinputs=1) (PJ_TYPE *types, size_t typesCount) = (SWIGTYPE *array, size_t count);
%typemap(ts) (PJ_TYPE *types, size_t typesCount) "PJ_TYPE[]";

// proj_get_area_of_use
%typemap(in, numinputs=0)
    (double *out_west_lon_degree, double *out_south_lat_degree,
    double *out_east_lon_degree, double *out_north_lat_degree,
    const char **out_area_name)
    (double _global_area[4], char *_global_area_name) {
  $1 = &_global_area[0];
  $2 = &_global_area[1];
  $3 = &_global_area[2];
  $4 = &_global_area[3];
  $5 = &_global_area_name;
}
%typemap(argout)
    (double *out_west_lon_degree, double *out_south_lat_degree,
    double *out_east_lon_degree, double *out_north_lat_degree,
    const char **out_area_name) {
  Napi::Value js_area_name;
  $typemap(out, double[4], 1=_global_area);
  $typemap(out, char *, 1=_global_area_name, result=js_area_name);
  %append_output(js_area_name);
}
%typemap(tsout, merge="overwrite")
    (double *out_west_lon_degree, double *out_south_lat_degree,
    double *out_east_lon_degree, double *out_north_lat_degree,
    const char **out_area_name)
  "[ number, number, number, number, string ]";

/**
 * ========================
 * PROJ_CRS_LIST_PARAMETERS
 * ========================
 */

// This is an ordinary structure which must be enriched
// with constructor/destructor and conversions for the types
%typemap(out) std::vector<int> getTypes = std::vector RETURN;
%typemap(ts)  std::vector<int> getTypes "PJ_TYPE[]";
%typemap(in)  const std::vector<int> &paramTypes = std::vector const &INPUT;
%typemap(ts)  const std::vector<int> &paramTypes "PJ_TYPE[]";

// As these cannot be used from JS they must be replaced with
// setters/getters. Alas, a typedef anonymous struct cannot have
// ignores so we cannot ignore only PROJ_CRS_LIST_PARAMETERS::types.
// Thus we ignore all member variables called types but not any
// eventual function arguments.
%rename("$ignore", %$isvariable) types;
%rename("$ignore", %$isvariable) typesCount;

%extend PROJ_CRS_LIST_PARAMETERS {
  PROJ_CRS_LIST_PARAMETERS() {
    return proj_get_crs_list_parameters_create();
  }
  ~PROJ_CRS_LIST_PARAMETERS() {
    if ($self->types && $self->typesCount) delete [] $self->types;
    proj_get_crs_list_parameters_destroy($self);
  }
  std::vector<int> getTypes() {
    std::vector<int> r;
    for (size_t i = 0; i < $self->typesCount; i++)
      r.push_back($self->types[i]);
    return r;
  }
  void setTypes(std::vector<int> const &paramTypes) {
    if ($self->types && $self->typesCount) delete [] $self->types;
    PJ_TYPE *types = new PJ_TYPE[paramTypes.size()];
    for (size_t i = 0; i < paramTypes.size(); i++)
      types[i] = static_cast<PJ_TYPE>(paramTypes[i]);
    $self->types = types;
    $self->typesCount = paramTypes.size();
  }
}

/**
 * ==================================================================
 * Methods that expect a number of output arguments in raw C pointers
 * and are transformed to return a structured object in JS
 * ==================================================================
 */

// Return an input argument as a named field in a structured object with rename
%define OUTPUT_FIELD_NAME(TYPE, CNAME, JSNAME)
%typemap(in, numinputs=0) TYPE *CNAME ($*1_ltype val) {
  $1 = &val;
}
%typemap(argout) TYPE *CNAME {
  Napi::Value js_out;
  $typemap(out, $*1_ltype, 1=*$1, result=js_out)
  %append_output_field(#JSNAME, js_out);
}
%typemap(tsout, merge="object") TYPE *CNAME #JSNAME ": $typemap(ts, $*1_ltype)";
%enddef

// Same thing but the C name is always out_<JS name>
#define OUTPUT_FIELD(TYPE, NAME) OUTPUT_FIELD_NAME(TYPE, out_##NAME, NAME)

// Transform return true/false to void/throw
%typemap(out) int THROW_IF_FALSE {
  if (!$1)
    SWIG_Raise("$1_name failed");
  $result = env.Undefined();
}
%typemap(ts) int THROW_IF_FALSE "void";

// Return an input argument as a named field in a structured object with rename and new type
%define OUTPUT_FIELD_CAST(CTYPE, CNAME, JSTYPE, JSNAME)
%typemap(in, numinputs=0) CTYPE *CNAME ($*1_ltype val) {
  $1 = &val;
}
%typemap(argout) CTYPE *CNAME {
  Napi::Value js_out;
  $typemap(out, JSTYPE, 1=static_cast<CTYPE>(*$1), result=js_out)
  %append_output_field(#JSNAME, js_out);
}
%typemap(tsout, merge="object") CTYPE *CNAME #JSNAME ": $typemap(ts, " #JSTYPE ")";
%enddef

// proj_coordoperation_get_towgs84_values
%typemap(in, numinputs=0, noblock=1) int emit_error_if_incompatible "$1 = 1;";
// Helmert transform
// (array of up to 15 values)
%typemap(in, numinputs=0) (double *out_values, int value_count)
    (double values[15]) {
  $1 = values;
  $2 = 15;
  memset($1, 0, sizeof(values));
}
%typemap(argout) (double *out_values, int value_count) {
  // Find the true length, ignore trailing zeros
  size_t len = 15;
  while ($1[len - 1] == 0 && len > 0) len--;
  // Apply the generic typemap from above
  $typemap(out, (double *OUTPUT_DATA, size_t OUTPUT_LENGTH), 2=len);
}
%typemap(tsout, merge="overwrite") (double *out_values, int value_count) "number[]";

// proj_trans_bounds
OUTPUT_FIELD(double,        xmin)
OUTPUT_FIELD(double,        ymin)
OUTPUT_FIELD(double,        xmax)
OUTPUT_FIELD(double,        ymax)
OUTPUT_FIELD_CAST(int, out_open_license, bool, open_license);
OUTPUT_FIELD(int,           available);
// proj_prime_meridian_get_parameters
OUTPUT_FIELD(double,        longitude)
OUTPUT_FIELD(double,        unit_conv_factor)
OUTPUT_FIELD(const char *,  unit_name)
// proj_coordoperation_get_method_info
OUTPUT_FIELD(const char *,  method_name)
OUTPUT_FIELD(const char *,  method_auth_name)
OUTPUT_FIELD(const char *,  method_code)
// proj_coordoperation_get_param
OUTPUT_FIELD(const char *,  name)
OUTPUT_FIELD(const char *,  auth_name)
OUTPUT_FIELD(const char *,  code)
OUTPUT_FIELD(double,        value)
OUTPUT_FIELD(const char *,  value_string)
OUTPUT_FIELD(const char *,  unit_auth_name)
OUTPUT_FIELD(const char *,  unit_code)
OUTPUT_FIELD(const char *,  unit_category)
// proj_cs_get_axis_info
OUTPUT_FIELD(const char *,  abbrev)
OUTPUT_FIELD(const char *,  direction)
// proj_ellipsoid_get_parameters
OUTPUT_FIELD(double,        semi_major_metre)
OUTPUT_FIELD(double,        semi_minor_metre)
OUTPUT_FIELD(double,        inv_flattening)
OUTPUT_FIELD_CAST(int, out_is_semi_minor_computed, bool, is_semi_minor_computed)
// proj_coordoperation_get_grid_used
OUTPUT_FIELD(const char *,  short_name)
OUTPUT_FIELD(const char *,  full_name)
OUTPUT_FIELD(const char *,  package_name)
OUTPUT_FIELD(const char *,  url)
OUTPUT_FIELD_CAST(int, out_direct_download, bool, direct_download)
OUTPUT_FIELD_CAST(int, out_available, bool, available)

%apply int THROW_IF_FALSE {
  int proj_trans_bounds,
  int proj_prime_meridian_get_parameters,
  int proj_coordoperation_get_method_info,
  int proj_coordoperation_get_param,
  int proj_cs_get_axis_info,
  int proj_ellipsoid_get_parameters,
  int proj_coordoperation_get_grid_used,
  int proj_coordoperation_get_towgs84_values
};

// Merge out_value / out_value_string in a single value with two possible types
%typemap(argout) (double *out_value, const char **out_value_string) {
  Napi::Value js_val;
  if (*$2) {
    $typemap(out, char *, 1=*$2, result=js_val);
  } else {
    $typemap(out, double, 1=*$1, result=js_val);
  }
  %append_output_field("value", js_val);
}
%typemap(tsout, merge="object") (double *out_value, const char **out_value_string) "value: string | number";

/**
 * =========================================
 * proj_trans_generic
 * =========================================
 */

// This is a very special case. We want to preserve the bulk
// nature of this function and its ability to accept arbitrarily
// structured data which in the JS world will likely come as
// scijs/ndarray or @stdlib/ndarray.
// It accepts four TypedArrays, each with a stride, allowing
// to use a single TypedArray in which the values are interleaved.
// Alas, numinputs>1 typemaps are very limited in SWIG.
// This is why we accept an object of the TS type below
// for each dimension.
// JS is expected to express the strides the JS way - in elements
// and not in bytes.

%typemap(ts) (double *x, size_t sx, size_t nx)
    "{ data: Float64Array | number, stride?: number, offset?: number }";
%typemap(in, numinputs=1) (double *x, size_t sx, size_t nx) (double constant, napi_value js_data) {
  if (!$input.IsObject()) {
    SWIG_Raise("Expected { data: TypedArray, stride?: number } for each dimension");
  }
  Napi::Object input = $input.ToObject();
  js_data = input.Get("data");
  Napi::Value data{env, js_data};
  if (data.IsNumber()) {
    constant = data.ToNumber().DoubleValue();
    $1 = &constant;
    $2 = 1;
    $3 = 1;
  } else {
    if (!data.IsTypedArray()) {
      SWIG_Raise("Expected a TypedArray for data");
    }
    if (data.As<Napi::TypedArray>().TypedArrayType() != napi_float64_array) {
      SWIG_Raise("Expected a Float64Array for data");
    }
    Napi::Float64Array values = data.As<Napi::Float64Array>();
    Napi::Value stride = input.Get("stride");
    if (stride.IsUndefined()) {
      $2 = 1;
    } else if (stride.IsNumber()) {
      $2 = stride.ToNumber().Int64Value();
    } else {
      SWIG_Raise("Expected a number or undefined for stride");
    }
    Napi::Value first = input.Get("offset");
    size_t offset;
    if (first.IsUndefined()) {
      offset = 0;
    } else if (first.IsNumber()) {
      offset = first.ToNumber().Int64Value();
    } else {
      SWIG_Raise("Expected a number or undefined for offset");
    }
    if (offset >= values.ElementLength()) {
      SWIG_Raise("Offset is beyond the end of the array");
    }
    $3 = (values.ElementLength() - offset) / $2 +
        (((values.ElementLength() - offset) % $2) ? 1 : 0);
    // Pointer arithmetic is of double* type
    $1 = values.Data() + offset;
  }
  // PROJ expects strides in bytes
  $2 *= sizeof(double);
}

// This is one of the very few differences between Node-API for native modules and emnapi for WASM
// WASM operates with a separate heap, so when going out of the proj_trans_generic function we must copy
// the data back to the JS memory space.
// Note that this is not asyncable since we are not allowed to keep local V8 references this way,
// if one day this project supports async, this will have to be implemented with a persistent reference.
// This also means that in the WASM world the zero-copy nature of this function is lost.
// TODO: I just saw there is some progress on this issue:
// https://github.com/WebAssembly/design/issues/1555
// Follow this development.
%typemap(argout) (double *x, size_t sx, size_t nx)
%{
#ifdef __EMSCRIPTEN__
emnapi_sync_memory(env, false, &js_data$argnum, 0, NAPI_AUTO_LENGTH);
#endif
%}

%apply(double *x, size_t sx, size_t nx) {
  (double *y, size_t sy, size_t ny),
  (double *z, size_t sz, size_t nz),
  (double *t, size_t st, size_t nt)
};

/**
 * =========================================
 * Opaque typedefs that must be destroyed
 * PJ, PJ_OPERATION_FACTORY_CONTEXT, PJ_AREA
 * =========================================
 */

// Opaque types cannot be extended
// This hack allows to add a destructor to an opaque type
// Maybe this could become a SWIG feature at some point
// because it is a common design pattern in old C software
%define PROJ_OPAQUE_TYPE_WITH_DESTROY(NAME, DESTROY)

// Do not wrap PROJ's original
%ignore NAME;

// Create another type that holds a pointer to PJ
// and destroys it on destruction.
// It will replace PJ and take its name
%rename(NAME) js##NAME;
%ignore js##NAME::get;
%ignore js##NAME::js##NAME(NAME *v);
%inline %{
class js##NAME {
  NAME *self;
public:
  js##NAME(NAME *v): self(v) {}
  ~js##NAME() { DESTROY(self); }
  NAME *get() { return self; }
};
%}

// Convert all PJ to jsPJ
%typemap(in) NAME * {
  js##NAME *wrap;
  $typemap(in, js##NAME *, 1=wrap);
  $1 = wrap ? wrap->get() : nullptr;
}
%typemap(out) NAME * {
  js##NAME *wrap = new js##NAME($1);
  $typemap(out, js##NAME *, 1=wrap, owner=SWIG_POINTER_OWN);
}

%typemap(ts) NAME * #NAME;
%enddef

%ignore PJconsts;
PROJ_OPAQUE_TYPE_WITH_DESTROY(PJ, proj_destroy);
PROJ_OPAQUE_TYPE_WITH_DESTROY(PJ_OPERATION_FACTORY_CONTEXT, proj_operation_factory_context_destroy);
PROJ_OPAQUE_TYPE_WITH_DESTROY(PJ_AREA, proj_area_destroy);

// Attach some specific methods to the object itself
%extend jsPJ {
  jsPJ(PJ_CONTEXT *ctx, const char *definition) {
    return new jsPJ(proj_create(ctx, definition));
  }
  const char* toString() {
    return proj_get_name($self->get());
  }
}

%extend jsPJ_AREA {
  jsPJ_AREA() {
    return new jsPJ_AREA(proj_area_create());
  }
  jsPJ_AREA(double west_lon_degree, double south_lat_degree,
                double east_lon_degree, double north_lat_degree) {
    jsPJ_AREA *self = new jsPJ_AREA(proj_area_create());
    proj_area_set_bbox(self->get(), west_lon_degree, south_lat_degree,
      east_lon_degree, north_lat_degree);
    return self;
  }
  void set_bbox(double west_lon_degree, double south_lat_degree,
                double east_lon_degree, double north_lat_degree) {
    proj_area_set_bbox($self->get(), west_lon_degree, south_lat_degree,
      east_lon_degree, north_lat_degree);
  }
  void set_name(const char *name) {
    proj_area_set_name($self->get(), name);
  }
}
// Area is always optional
%typemap(default) PJ_AREA *area { $1 = nullptr; };

/**
 * =========================
 * Lists of the PJ_LIST type
 * =========================
 */
// The descr field is simply a pointer to pointer
// that must be copied to a string
%typemap(out) const char *const *descr {
  $typemap(out, const char *, 1=*$1);
}
%typemap(ts) const char *const *descr "string";

// The name LIST is not very accurate in JavaScript
%rename(PJ_LIST_ELEMENT) PJ_LIST;

// The function pointer
%typemap(out) PJ *_SWIG_call_funcptr< PJ *,PJ * > {
  // The calling semantics of this function pointer are rather unusual
  // we simply return the same JS object with which we were called.
  // Most functions do exactly this and wrapping it again as a non-owned
  // proxy is very dangerous as the original can disappear.
  // Do not add complexity.
  // This entry point will probably be removed from the JS interface.
  $result = info[0];
}
%napi_funcptr(proj_op_func_ptr, PJ *, PJ *);

// TODO: SWIG JavaScript has a built-in arrays_javascript
// but it works only for numbers
%define PJ_LIST(TYPE, NAME)
%typemap(out) TYPE *NAME {
  // Create a new JS array
  Napi::Array array = Napi::Array::New(env);
  // We received a TYPE * from the underlying function
  TYPE *list = $1;
  for (size_t i = 0; list->id; list++, i++) {
    // This is an array of pointers -> we create
    // an array of JS objects that wrap each pointer
    // Each wrapper does not own the underlying C object
    // (these are the PROJ calling semantics, the returned
    // values are static)
    Napi::Value jsobj;
    // Call the out typemap for each element with
    // 1 = list (input)
    // result = jsobj (result)
    $typemap(out, TYPE *, 1=list, result=jsobj, owner=0);

    array.Set(i, jsobj);
  }
  // Our own result is the array
  $result = array;
}
%typemap(ts) TYPE *NAME "PJ_LIST_ELEMENT[]";
%enddef

%extend PJ_LIST {
  std::string toString() {
    return std::string{$self->id} + ": " + std::string{*($self->descr)};
  }
}

PJ_LIST(PJ_OPERATIONS, proj_list_operations);
PJ_LIST(PJ_ELLPS, proj_list_ellps);
PJ_LIST(PJ_PRIME_MERIDIANS, proj_list_prime_meridians);

/**
 * ================================
 * Lists of the PJ_STRING_LIST type
 * ================================
 */

%typemap(out) PROJ_STRING_LIST {
  if ($1 == NULL) {
    SWIG_NAPI_Raise(env, "Error getting list");
  }
  Napi::Array r = Napi::Array::New(env);
  char **s = $1;
  size_t i = 0;
  while (*s) {
    Napi::Value el;
    $typemap(out, char*, 1=*s, result=el);
    r.Set(i, el);
    i++;
    s++;
  }
  $result = r;
  proj_string_list_destroy($1);
}
%typemap(ts) PROJ_STRING_LIST "string[]";

// The special case of proj_create_from_wkt
%typemap(in, numinputs=0) PROJ_STRING_LIST* (PROJ_STRING_LIST strings) {
  $1 = &strings;
};
%typemap(argout) PROJ_STRING_LIST * {
  PROJ_STRING_LIST s = *$1;
  Napi::Array js_array = Napi::Array::New(env);
  size_t i = 0;
  while (s && s[i]) {
    Napi::Value js_string;
    $typemap(out, char*, 1=s[i], result=js_string);
    js_array.Set(i++, js_string);
  }
  %append_output(js_array);
}
// If there are errors, simply throw the very first one
%typemap(argout) PROJ_STRING_LIST *out_grammar_errors {
  PROJ_STRING_LIST s = *$1;
  if (s && s[0]) {
    SWIG_NAPI_Raise(env, s[0]);
  }
}
// freearg gets run even if exiting with an exception
%typemap(freearg) PROJ_STRING_LIST * {
  proj_string_list_destroy(*$1);
}

%typemap(ts) PJ *proj_create_from_wkt "[ PJ, string[] ]";


/**
 * ================
 * Lists of options
 * ================
 */

// The generic case of const char *const *options
%typemap(in) const char *const *options {
  $1 = nullptr;
  if (!$input.IsObject()) {
    SWIG_NAPI_Raise(env, "options must be a Record<string, string | boolean | number>");
  }
  Napi::Object js_options = $input.ToObject();
  Napi::Array keys = js_options.GetPropertyNames();
  $1 = new char * [keys.Length() + 1];
  for (size_t i = 0; i < keys.Length(); i++) {
    Napi::Value js_key = keys.Get(i);
    if (!js_key.IsString()) {
      // new zeroed allocated memory which means
      // that the delete below will work
      SWIG_NAPI_Raise(env, "Keys must be strings");
    }
    std::string line = js_key.ToString().Utf8Value();
    Napi::Value element = js_options.Get(js_key);
    if (element.IsBoolean()) {
      bool v = element.ToBoolean().Value();
      if (v) {
        line += "=YES";
      } else {
        line += "=NO";
      }
    } else if (element.IsNumber()) {
      double d = element.ToNumber().DoubleValue();
      line += "=" + std::to_string(d);
    } else if (element.IsString()) {
      line += "=" + element.ToString().Utf8Value();
    } else {
      SWIG_NAPI_Raise(env, "options must be a Record<string, string | boolean | number>");
    }
    $1[i] = new char[line.size() + 1];
    strncpy($1[i], line.c_str(), line.size() + 1);
  }
  $1[keys.Length()] = NULL;
}
%typemap(freearg) const char *const *options {
  char **s = $1;
  while (s && *s) {
    delete [] *s;
    s++;
  }
  delete [] $1;
}
%typemap(ts) const char *const *options "Record<string, string | boolean | number>";
// options are obviously optional
%typemap(default) const char *const *options {
  $1 = nullptr;
}


/**
 * ======================
 * Other lists of strings
 * ======================
 */

// Generic NULL-terminated array of NULL-terminated strings in
//     const char *const *
// This one has enough reuse potential to be included in SWIG
%typemap(in) const char *const *strings_null_terminated {
  $1 = nullptr;
  if (!$input.IsArray()) {
    SWIG_Raise("argument must be an array of strings");
  }
  Napi::Array array = $input.As<Napi::Array>();
  $1 = new char * [array.Length() + 1];
  for (size_t i = 0; i < array.Length(); i++) {
    if (!array.Get(i).IsString())
      SWIG_Raise("argument must be an array of strings");
    std::string element = array.Get(i).ToString().Utf8Value();
    $1[i] = new char [element.size() + 1];
    strncpy($1[i], element.c_str(), element.size() + 1);
  }
  $1[array.Length()] = NULL;
}
%typemap(freearg) const char *const *strings_null_terminated = const char *const *options;
%typemap(ts) const char *const *strings_null_terminated "string[]";

// proj_operation_factory_context_set_allowed_intermediate_crs
%apply(const char *const *strings_null_terminated) { const char *const *list_of_auth_name_codes };

/**
 * ==================================
 * Lists of the monolithic block type
 * ==================================
 *
 * These are monolithic blocks of objects that must be freed as a whole.
 * We expose a container object to JS that can be iterated.
 * Each returned object will carry a reference to its parent, since
 * the parent cannot be GCed until all objects have been released.
 * The higher level part of the iterator is in the JS import.
 */

%newobject iterator;

%define PROJ_BLOCK_PTRARRAY(TYPE, NAME, DESTROY)

%inline {
class TYPE##_ITERATOR;
class TYPE##_CONTAINER {
  TYPE **list;
public:
  TYPE##_CONTAINER(TYPE **v);
  ~TYPE##_CONTAINER();
  TYPE##_ITERATOR *iterator();
};

class TYPE##_ITERATOR {
  TYPE **current;
public:
  TYPE##_ITERATOR(TYPE **v);
  TYPE *next();
};

}
%wrapper {
  TYPE##_CONTAINER::TYPE##_CONTAINER(TYPE **v) : list{v} {}
  TYPE##_CONTAINER::~TYPE##_CONTAINER(){ DESTROY(list); }
  TYPE##_ITERATOR *TYPE##_CONTAINER::iterator(){ return new TYPE##_ITERATOR{list}; }

  TYPE##_ITERATOR::TYPE##_ITERATOR(TYPE **v) : current{v} {}
  TYPE *TYPE##_ITERATOR::next() {
    if (*current)
      return *(current++);
    return NULL;
  }
}

%typemap(out) TYPE **NAME {
  if ($1 == NULL) {
    SWIG_NAPI_Raise(env, "Error getting list");
  }
  TYPE##_CONTAINER *r = new TYPE##_CONTAINER{$1};
  $typemap(out, TYPE##_CONTAINER *, 1=r, owner=SWIG_POINTER_OWN);
}
%typemap(ts) TYPE **NAME "$typemap(ts, " #TYPE "_CONTAINER)";

%enddef


/**
 * ==============================
 * Lists of the PJ_UNIT_INFO type
 * ==============================
 */
PROJ_BLOCK_PTRARRAY(PROJ_UNIT_INFO, proj_get_units_from_database, proj_unit_list_destroy);
PROJ_BLOCK_PTRARRAY(PROJ_CELESTIAL_BODY_INFO, proj_get_celestial_body_list_from_database, proj_celestial_body_list_destroy);
PROJ_BLOCK_PTRARRAY(PROJ_CRS_INFO, proj_get_crs_info_list_from_database, proj_crs_info_list_destroy);


/**
 * =============================
 * Lists of the PJ_OBJ_LIST type
 * =============================
 *
 * These are opaque structures that the user cannot manipulate directly.
 */
%ignore PJ_OBJ_LIST;
%ignore proj_list_get;
%ignore proj_list_get_count;
%rename(PJ_OBJ_LIST) PJ_OBJ_LIST_WRAPPER;
// TODO: provide a mechanism to disallow constructing of certain classes from JS
%inline {
class PJ_OBJ_LIST_WRAPPER {
  PJ_OBJ_LIST *list;
public:
  PJ_OBJ_LIST_WRAPPER(PJ_OBJ_LIST *v);
  ~PJ_OBJ_LIST_WRAPPER();
  // SWIG will eliminate the PJ_CONTEXT arguments
  size_t length();
  PJ *unsafe_get(PJ_CONTEXT *ctx, size_t i);
};
}
%wrapper {
  PJ_OBJ_LIST_WRAPPER::PJ_OBJ_LIST_WRAPPER(PJ_OBJ_LIST *v) : list{v} {};
  PJ_OBJ_LIST_WRAPPER::~PJ_OBJ_LIST_WRAPPER() {
    proj_list_destroy(list);
  }
  size_t PJ_OBJ_LIST_WRAPPER::length() {
    return proj_list_get_count(list);
  }
  PJ *PJ_OBJ_LIST_WRAPPER::unsafe_get(PJ_CONTEXT *ctx, size_t i) {
    if (i >= proj_list_get_count(list)) {
      throw std::runtime_error{"Out of bounds"};
    }
    return proj_list_get(ctx, list, i);
  }
}
%typemap(out) PJ_OBJ_LIST * {
  if ($1 == NULL) {
    SWIG_NAPI_Raise(env, "Error getting list");
  }
  PJ_OBJ_LIST_WRAPPER *wrapper = new PJ_OBJ_LIST_WRAPPER($1);
  $typemap(out, PJ_OBJ_LIST_WRAPPER *, 1=wrapper, owner=SWIG_POINTER_OWN);
}
%typemap(ts) PJ_OBJ_LIST * "PJ_OBJ_LIST";


/**
 * ================
 * The log function
 * ================
 */

// The original PROJ log function setter is not usable from JS
%ignore proj_log_func;

// This is very tricky, especially when dealing with async JS functions.
// There is a section in the SWIG JSE manual that covers it in detail.
%rename(proj_log_func) proj_log_func_wrapper;

%typemap(in, fragment="SWIG_NAPI_Callback") std::function<void(int, const const char *)> {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  
  // SWIG_NAPI_Callback returns an std::function that can be used to call into JS
  $1 = SWIG_NAPI_Callback<void, int, const char *>(
    // First argument is the JavaScript function
    $input,
    // The second argument is a function
    // The first two arguments are fixed - the Node-API environment pointer
    //   and a reference to a napi_value vector that will receive the
    //   converted arguments
    // The next arguments are the C++ function type arguments
    std::function<void(Napi::Env, std::vector<napi_value> &, int, const char *)>(
        [](Napi::Env env, std::vector<napi_value> &js_args, int err, const char *msg) -> void {
        // $typemap allows to simply insert the existing SWIG typemap for this type
        $typemap(out, int, 1=err, result=js_args.at(0), argnum=err);
        $typemap(out, char *, 1=msg, result=js_args.at(1), argnum=msg);
      }
    ),
    // This argument is a function that will convert the returned value
    [](Napi::Env env, Napi::Value js_ret) -> void {
      if (!js_ret.IsUndefined())
        SWIG_Raise("JavaScript log function returned a value, it should return undefined");
    },
    // This will be the value of 'this' inside the JavaScript function
    env.Global()
  );
}

// This is the associated TypeScript type
%typemap(ts) std::function<void(int, const char *)>
  "(this: typeof globalThis, err: number, msg: string) => void";

// If a function asks for the instance_data, produce it out of thin air
%typemap(in, numinputs=0) proj_instance_data *instance_data {
  $1 = static_cast<proj_instance_data *>(SWIG_NAPI_GetInstanceData(env));
}

// This is the log function setter that will be exported to JavaScript. It accepts
// an std::function parameter that SWIG will transform using the above typemaps.
// It will use the void* data parameter to send itself back the std::function to call.
// (C++ lambdas that do not capture anything can be casted to function pointers).
%inline %{
void proj_log_func_wrapper(proj_instance_data *instance_data, PJ_CONTEXT *ctx, std::function<void(int, const char *)> fn);  
%}
%wrapper %{
void proj_log_func_wrapper(proj_instance_data *instance_data, PJ_CONTEXT *ctx, std::function<void(int, const char *)> fn) {
  using cb_t = decltype(fn);
  // Store the log function in the instance data
  // (to avoid complex allocation/deallocation)
  instance_data->log_fn = fn;
  // Pass a pointer to this std::function
  auto *cb = &instance_data->log_fn;
  proj_log_func(ctx, cb, [](void *context, int err, const char *msg) -> void {
    auto fn_ = reinterpret_cast<cb_t*>(context);
    (*fn_)(err, msg);
  });
}
%}


/**
 * ============
 * Main Include
 * ============
 */

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
