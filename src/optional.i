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
// around the object held by JS, the extra step is needed because local
// variables do not support $T0type expansion
// (some PROJ objects do not support operator=)
%typemap(in)        const osgeo::proj::util::optional & (void *to_delete) {
  osgeo::proj::util::optional<$T0type> *typed_ptr;
  if (!$input.IsNull()) {
    $T0type *obj;
    $typemap(in, const $T0type &, input=$input, 1=obj, argnum=$argnum);
    typed_ptr = new osgeo::proj::util::optional<$T0type>{*obj};
  } else {
    typed_ptr = new osgeo::proj::util::optional<$T0type>{};
  }
  to_delete = static_cast<void *>(typed_ptr);
  $1 = typed_ptr;
}
%typemap(freearg)      const osgeo::proj::util::optional & {
  delete static_cast<osgeo::proj::util::optional<$T0type> *>(to_delete$argnum);
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
%typemap(freearg)   const osgeo::proj::util::optional<std::string> &, const osgeo::proj::util::optional<double> & ""

%typemap(ts)        osgeo::proj::util::optional, const osgeo::proj::util::optional & "$typemap(ts, $T0type)[]";

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
