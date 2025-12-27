// PJ_COORD
%apply double[4] { double v[4] };

// Per V8-isolate initialization
%header %{
struct proj_instance_data {
  PJ_CONTEXT *context;
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

// Experimental function pointer support
%include <function.i>

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

// out_result_count is used in several functions
// we transform it to a local variable in each wrapper
%typemap(in, numinputs=0) int *out_result_count (int _global_out_result_count) {
  $1 = &_global_out_result_count;
};

// out_confidence is added to the return values which become an array
%typemap(in, numinputs=0) int **out_confidence (int *_global_out_confidence) {
  $1 = &_global_out_confidence;
};
%typemap(argout, fragment=SWIG_From_frag(int)) int **out_confidence {
  size_t elements = proj_list_get_count(result);
  Napi::Array confidence = Napi::Array::New(env, elements);
  if ($1 != nullptr) {
    for (size_t i = 0; i < elements; i++)
      confidence.Set(i, SWIG_From(int)(_global_out_confidence[i]));
    proj_int_list_destroy(*$1);
  }
  %append_output(confidence);
}
%typemap(ts) PJ_OBJ_LIST *proj_identify "[ PJ_OBJ_LIST, number[] ]";

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
  // TODO C Arrays support in SWIG JSE is inherited from JavaScriptCore and lacks many features

  Napi::Array js_array = Napi::Array::New(env);
  // Ignore trailing zeros
  size_t len = 15;
  while ($1[len - 1] == 0 && len > 0) len--;
  for (size_t i = 0; i < len; i++) {
    Napi::Value js_val;
    $typemap(out, double, 1=$1[i], result=js_val);
    js_array.Set(i, js_val);
  }
  $result = js_array;
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
%typemap(out) PJ *(*PJ_LIST::proj)(PJ *) {
  $result = SWIG_NAPI_Function<PJ *, PJ *>(
    env,
    std::function<PJ *(PJ *)>($1),
    // Note that arguments are the decayed types
    std::function<void(Napi::Env, const Napi::CallbackInfo &, PJ *)>(
        [](Napi::Env env, const Napi::CallbackInfo &info, PJ *in) -> void {
          // Ignore these two, these are SWIG quirks
          // that require some major refactoring to be eliminated
          int res10;
          void *argp10;
          $typemap(in, PJ *, input=info[0], 1=in, argnum=PJ, disown=0);
      }
    ),
    [](Napi::Env env, PJ *c_out) -> Napi::Value {
      Napi::Value js_out;
      $typemap(out, PJ *, 1=c_out, result=js_out, argnum=result)
      return js_out;
    }
  );
}
%typemap(ts) PJ *(*PJ_LIST::proj)(PJ *) "(x: PJ) => PJ";

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
