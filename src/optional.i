// osgeo::proj::util::optional

// Input argument, plain object, conversion by copying using the underlying object typemap
%typemap(in)        osgeo::proj::util::optional {
  if (!$input.IsNull()) {
    $T0type opt_obj;
    $typemap(in, $T0type, input=$input, 1=opt_obj, argnum=$argnum);
    $1 = osgeo::proj::util::optional<$T0type>{opt_obj};
  }
}
// Input argument, const reference, conversion by copying, the extra
// step is needed because local variables do not support $T0type expansion
#if 0
// This is a huge problem because some types are not copyable
%typemap(in)        const osgeo::proj::util::optional & (void *opt_obj) {
  osgeo::proj::util::optional<$T0type> *typed_ptr;
  if (!$input.IsNull()) {
    $T0type opt_obj;
    $typemap(in, $T0type, input=$input, 1=opt_obj, argnum=$argnum);
    typed_ptr = new osgeo::proj::util::optional<$T0type>{opt_obj};
  } else {
    typed_ptr = new osgeo::proj::util::optional<$T0type>{};
  }
  opt_obj = static_cast<void *>(typed_ptr);
  $1 = typed_ptr;
}
%typemap(free)      const osgeo::proj::util::optional & (void *opt_obj) {
  delete static_cast<osgeo::proj::util::optional<$T0type> *>(opt_obj$argnum);
}
#endif

%typemap(ts)        osgeo::proj::util::optional, const osgeo::proj::util::optional & "$typemap(ts, $T0type)[]";

// Return value, plain object, conversion by copying
%typemap(out)       osgeo::proj::util::optional {
  if ($1.has_value()) {
    $typemap(out, $T0type, 1=(*$1), result=$result, argnum=$argnum);
  } else {
    $result = env.Null();
  }
}
// Return value, const reference, conversion by wrapping a constant object
%typemap(out)       const osgeo::proj::util::optional & {
  if ($1->has_value()) {
    $typemap(out, const $T0type &, 1=&(*$1), result=$result, argnum=$argnum);
  } else {
    $result = env.Null();
  }
}
// string and double are special cases, these are copied
%typemap(out)       const osgeo::proj::util::optional<std::string> & {
  if ($1->has_value()) {
    $typemap(out, const std::string &, 1=(*$1), result=$result, argnum=$argnum);
  } else {
    $result = env.Null();
  }
}
%typemap(out)       const osgeo::proj::util::optional<double> & {
  if ($1->has_value()) {
    $typemap(out, double, 1=(**$1), result=$result, argnum=$argnum);
  } else {
    $result = env.Null();
  }
}
