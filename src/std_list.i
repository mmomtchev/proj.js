// C++ std::list <-> JS array typemaps

%header %{
#include <list>
#include <utility>
%}

// Most of the std::lists in PROJ are lists of std::pair
// Convert them to JS arrays
%include <std_pair.i>
%apply(std::pair RETURN)            { std::pair };
%apply(std::pair *RETURN)           { std::pair *, std::pair & };


// Input argument, list of plain objects, conversion by copying
%typemap(in)        std::list {
  if ($input.IsArray()) {
    Napi::Array array = $input.As<Napi::Array>();
    for (size_t i = 0; i < array.Length(); i++) {
      $T0type c_val;
      Napi::Value js_val = array.Get(i);
      $typemap(in, $T0type, input=js_val, 1=c_val, argnum=array value);
      $1.emplace_back(SWIG_STD_MOVE(c_val));
    }
  } else {
    %argument_fail(SWIG_TypeError, "Array", $symname, $argnum);
  }
}
%typemap(ts)        std::list "$typemap(ts, $T0type)[]";

// Return value, list of plain objects, conversion by copying
%typemap(out)       std::list {
  Napi::Array array = Napi::Array::New(env, $1.size());
  size_t j = 0;
  for (auto i = $1.begin(); i != $1.end(); i++) {
    Napi::Value js_val;
    $typemap(out, $T0type, 1=(*i), result=js_val, argnum=array value);
    array.Set(j++, js_val);
  }
  $result = array;
}
