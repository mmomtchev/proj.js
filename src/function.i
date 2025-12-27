// This is experimental support for function pointers that
// may be included in a future SWIG JSE version

%wrapper %{
template <typename RET, typename ...ARGS>
Napi::Function SWIG_NAPI_Function(
    Napi::Env env,
    // The C/C++ function
    std::function<RET(ARGS...)> c_fn,
    // A function that will transform the given JS arguments to C++ args
    std::function<void(Napi::Env, const Napi::CallbackInfo &, std::decay_t<ARGS> & ...)> tmaps_in,
    // A function the will transform the returned C++ value to napi_value
    std::function<Napi::Value(Napi::Env, RET)> tmap_out
  ) {
    // Here we are in the code that runs when JS/SWIG asks to transform
    // the returned C/C++ function to JS function
    // We are always on the main thread
  Napi::Function js_fn = Napi::Function::New(env,
    [tmaps_in, tmap_out, c_fn](const Napi::CallbackInfo &info) -> Napi::Value {
    // Here we are in the code that runs when JS calls the returned function
    // We are always on the main thread
    Napi::Env env{info.Env()};
    // Convert the JS arguments into C++ 
    std::tuple<std::decay_t<ARGS>...> args;
    // This trick allows to expand the tuple and pass
    // the values by reference
    std::apply([&tmaps_in, &info, &env](std::decay_t<ARGS> & ...args) {
      tmaps_in(env, info, args...);
    }, args);

    Napi::Value js_ret;
    if constexpr (std::is_void_v<RET>) {
      std::apply(c_fn, args);
      js_ret = env.Undefined();
    } else {
      RET c_ret = std::apply(c_fn, args);
      js_ret = tmap_out(env, c_ret);
    }
    return js_ret;
  });

  return js_fn;
}
%}
