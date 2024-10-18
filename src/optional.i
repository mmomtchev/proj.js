// osgeo::proj::util::optional

/*
 * Input arguments
 */

// Input argument, plain object, conversion by copying using the underlying object typemap
%typemap(in)        osgeo::proj::util::optional {
  if (!$input.IsNull()) {
    $T0type obj;
    $typemap(in, $T0type, input=$input, 1=obj, argnum=$argnum);
    $1 = osgeo::proj::util::optional<$T0type>{obj};
  }
}
// Input argument, const reference, conversion by constructing an 'optional'
// around the object held by JS
// (DataEpoch & Measure do not support operator=, thus the unique_ptr gymnastics)
%typemap(in)        const osgeo::proj::util::optional & (std::unique_ptr<$*1_ltype> opt_object) {
  if (!$input.IsNull()) {
    $T0type *obj;
    $typemap(in, const $T0type &, input=$input, 1=obj, argnum=$argnum);
    opt_object = std::make_unique<$*1_ltype>(*obj);
  } else {
    opt_object = std::make_unique<$*1_ltype>();
  }
  $1 = opt_object.get();
}

// string and double are special cases, these are copied
%typemap(in)        const osgeo::proj::util::optional<std::string> & (osgeo::proj::util::optional<std::string> opt_string) {
  if (!$input.IsNull()) {
    $typemap(in, std::string, input=$input, 1=opt_string, argnum=$argnum);
  }
  $1 = &opt_string;
}
%typemap(in)        const osgeo::proj::util::optional<double> & (osgeo::proj::util::optional<double> opt_double) {
  if (!$input.IsNull()) {
    $typemap(in, double, input=$input, 1=opt_double, argnum=$argnum);
  }
  $1 = &opt_double;
}

%typemap(ts)        osgeo::proj::util::optional, const osgeo::proj::util::optional & "$typemap(ts, $T0type)";

/*
 * Return values
 */

// Return value, plain object, conversion by copying
%typemap(out)       osgeo::proj::util::optional {
  if ($1.has_value()) {
    $typemap(out, $T0type, 1=(*$1), result=$result, argnum=$argnum);
  } else {
    $result = env.Null();
  }
}
// Return value, const reference, conversion by wrapping a constant object
// This typemap is not entirely safe because we wrap an existing object
// Normally, this object would be part of its parent object, but this
// object can be garbage-collected and if the user decides to keep its
// copy, this will be a dangling pointer
// The only safe way to do it is to always copy each object
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
