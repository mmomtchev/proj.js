// C++ std::set <-> JS array typemaps
%include <std_string.i>

%header %{
#include <string>
#include <set>
%}


// Input argument, set of plain objects, conversion by copying
%typemap(in)        std::set {
  if ($input.IsArray()) {
    Napi::Array array = $input.As<Napi::Array>();
    for (size_t i = 0; i < array.Length(); i++) {
      std::string c_val;
      Napi::Value js_val = array.Get(i);
      $typemap(in, $T0type, input=js_val, 1=c_val, argnum=array value);
      $1.emplace_back(SWIG_STD_MOVE(c_val));
    }
  } else {
    %argument_fail(SWIG_TypeError, "Array", $symname, $argnum);
  }
}
%typemap(ts)        std::set "$typemap(ts, $T0type)[]";

// Return value, set of plain objects, conversion by copying
%typemap(out)       std::set {
  Napi::Array array = Napi::Array::New(env, $1.size());
  size_t j = 0;
  for (auto i = $1.begin(); i != $1.end(); i++) {
    Napi::Value js_val;
    $typemap(out, $T0type, 1=(*i), result=js_val, argnum=array value);
    array.Set(j++, js_val);
  }
  $result = array;
}
