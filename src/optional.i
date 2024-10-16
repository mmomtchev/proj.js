// C++ osgeo::proj::util::optional<std::string> <-> JS string

// This is almost a string, but not quite

// Input argument, plain object, conversion by copying
%typemap(in)        osgeo::proj::util::optional<std::string> {
  if (!$input.IsNull()) {
    std::string opt_string;
    $typemap(in, std::string, input=$input, 1=opt_string, argnum=$argnum);
    $1 = osgeo::proj::util::optional<std::string>{opt_string};
  }
}
%typemap(in)        const osgeo::proj::util::optional<std::string> & (osgeo::proj::util::optional<std::string> opt_string) {
  if (!$input.IsNull()) {
    $typemap(in, std::string, input=$input, 1=opt_string, argnum=$argnum);
  }
  $1 = &opt_string;
}

%typemap(ts)        osgeo::proj::util::optional<std::string>, const osgeo::proj::util::optional<std::string> & "string";

// Return value, plain object, conversion by copying
%typemap(out)       osgeo::proj::util::optional<std::string> {
  if ($1.has_value()) {
    $typemap(out, std::string, 1=(*$1), result=$result, argnum=$argnum);
  } else {
    $result = env.Null();
  }
}
%typemap(out)       const osgeo::proj::util::optional<std::string> & {
  if ($1->has_value()) {
    $typemap(out, const std::string &, 1=(*$1), result=$result, argnum=$argnum);
  } else {
    $result = env.Null();
  }
}
