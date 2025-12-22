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

%init {
  auto *instance_data = new proj_instance_data;
  instance_data->context = proj_context_create();
  if (instance_data->context == nullptr) {
    SWIG_Raise("Failed to initialize PROJ context");
  }
  SWIG_NAPI_SetInstanceData(env, instance_data);
  env.AddCleanupHook([instance_data]() {
    // This is a huge problem because Node.js (the culprit being V8) will sometimes
    // do a final GC pass after the environment has been destroyed - and this is
    // something that PROJ does not appreciate at all.
    // The WASM module does not have this problem, destruction in WASM happens
    // when the tab is closed/refreshed which is NotOurProblem.
    // There is no easy solution.
    // For now, proj.js leaks memory when loaded repeatedly in worker_threads
    // proj_context_destroy(instance_data->context);
    delete instance_data;
  });
}

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

/**
 * ==================================================
 * Miscellaneous arguments that need special handling
 * ==================================================
 */

%apply bool { int allow_deprecated };
%apply bool { int deprecated };
%apply bool { int crs_area_of_use_contains_bbox };
%apply bool { int approximateMatch };
%apply bool { int proj_is_deprecated };
%apply bool { int proj_is_equivalent_to };
%apply bool { int proj_is_equivalent_to_with_ctx };
%apply bool { int proj_is_crs };
%apply bool { int proj_is_derived_crs };
%apply bool { int proj_crs_is_derived };
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
  $result = SWIG_AppendOutput($result, confidence);
}
%typemap(ts) PJ_OBJ_LIST *proj_identify "[ PJ_OBJ_LIST, number[] ]";

// Generic arrays from JS Array to C with pointer & length
// (search for $*n_ltype in SWIG manual)
// Alas this does not work for primitive types!!!
// Investigate, because all SWIG JSE examples use $typemap
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
%typemap(in, numinputs=1) (PJ_TYPE *types, size_t typesCount) (std::shared_ptr<PJ_TYPE[]> data) {
  if (!$input.IsArray()) {
    SWIG_NAPI_Raise(env, "argument must be an array");
  }
  Napi::Array js_array = $input.As<Napi::Array>();
  data = std::shared_ptr<PJ_TYPE[]>(new PJ_TYPE[js_array.Length()]);
  for (size_t i = 0; i < js_array.Length(); i++) {
    int value;
    SWIG_AsVal(int)(js_array.Get(i), &value);
    data[i] = static_cast<PJ_TYPE>(value);
  }
  $1 = data.get();
  $2 = js_array.Length();
}
%typemap(ts) (PJ_TYPE *types, size_t typesCount) "PJ_TYPE[]";

// proj_get_area_of_use
%typemap(in, numinputs=0)
  (double *out_west_lon_degree, double *out_south_lat_degree, double *out_east_lon_degree, double *out_north_lat_degree, const char **out_area_name)
  (double _global_area[4], char *_global_area_name) {
    $1 = &_global_area[0];
    $2 = &_global_area[1];
    $3 = &_global_area[2];
    $4 = &_global_area[3];
    $5 = &_global_area_name;
  }
%typemap(argout)
  (double *out_west_lon_degree, double *out_south_lat_degree, double *out_east_lon_degree, double *out_north_lat_degree, const char **out_area_name) {
    Napi::Value js_area_name;
    $typemap(out, double[4], 1=_global_area);
    $typemap(out, char *, 1=_global_area_name, result=js_area_name);
    SWIG_AppendOutput($result, js_area_name);
  }
%typemap(tsout) (double *out_west_lon_degree, double *out_south_lat_degree, double *out_east_lon_degree, double *out_north_lat_degree, const char **out_area_name)
  "[ number, number, number, number, string ]";


/**
 * ================
 * The PJ structure
 * ================
 */

// Only we can destroy
%rename("$ignore", regextarget=1) "proj.*_destroy";

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
%ignore jsPJ::jsPJ;
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
  $1[keys.Length()] = 0;
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
  $result = SWIG_AppendOutput($result, js_array);
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
