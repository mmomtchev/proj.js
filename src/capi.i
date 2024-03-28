// PJ_COORD
%apply double[4] { double v[4] };

// Per V8-isolate initialization
%header {
struct proj_instance_data {
  PJ_CONTEXT *context;
};
}

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

// Completely hide PJ_CONTEXT from the module user, always insert the argument from
// the environment context
%rename("$ignore", regextarget=1) "^proj_context_.*";

%typemap(in, numinputs=0, noblock=1) PJ_CONTEXT * {
  $1 = static_cast<proj_instance_data *>(SWIG_NAPI_GetInstanceData(env))->context;
}

// Using a typedef enum with the same name as the enum is an edge case
// especially when supporting both C++ and C
#pragma SWIG nowarn=302
