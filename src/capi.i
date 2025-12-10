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
    proj_context_destroy(instance_data->context);
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

// proj_create_from_name
%typemap(in, numinputs=1) (const PJ_TYPE *types, size_t typesCount) (std::shared_ptr<PJ_TYPE []> pj_types) {
  $typemap(in, size_t, 1=$2, input=info[$argnum + 1]);
  pj_types = std::shared_ptr<PJ_TYPE []>($2);
  $1 = pj_types.get();
}
%typemap(ts, numinputs=1) (const PJ_TYPE *types, size_t typesCount) "PJ_TYPE[]"

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

// https://github.com/swig/swig/issues/3120
%ignore proj_create_from_name;

// These types are opaque types in the C++ API
%typemap(ts) PJ_OBJ_LIST "unknown"
%typemap(ts) PJ_INSERT_SESSION "unknown"

// SWIG can't deduce the type of PROJ_VERSION_NUMBER
#pragma SWIG nowarn=304

/**
 * The PJ structure
 */

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
 * Lists
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

PJ_LIST(PJ_OPERATIONS, proj_list_operations);


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
