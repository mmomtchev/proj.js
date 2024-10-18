%nn_shared_ptr(osgeo::proj::metadata::Identifier);
%nn_shared_ptr(osgeo::proj::metadata::Citation);
%nn_shared_ptr(osgeo::proj::metadata::Extent);
%nn_shared_ptr(osgeo::proj::metadata::GeographicBoundingBox);
%nn_shared_ptr(osgeo::proj::metadata::TemporalExtent);
%nn_shared_ptr(osgeo::proj::metadata::VerticalExtent);
%nn_shared_ptr(osgeo::proj::metadata::PositionalAccuracy);

%define IDENTIFIER_DOWNCAST_TABLE_ENTRY(TYPE)
identifier_downcast_table.insert({typeid(TYPE).hash_code(), $descriptor(TYPE *)})
%enddef

%fragment("identifier_downcast_table", "header", fragment="include_map") {
  std::map<std::size_t, swig_type_info *> identifier_downcast_table;

  void init_identifier_downcast_table() {
    IDENTIFIER_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::Identifier);
    IDENTIFIER_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::Citation);
    IDENTIFIER_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::Extent);
    IDENTIFIER_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::GeographicBoundingBox);
    IDENTIFIER_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::TemporalExtent);
    IDENTIFIER_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::VerticalExtent);
    IDENTIFIER_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::PositionalAccuracy);
  }
}

%init {
  init_identifier_downcast_table();
}

// See util.i for the downcasting mechanics
// This overwrites the typemap created by %nn_shared_ptr
%typemap(out, fragment="identifier_downcast_table") dropbox::oxygen::nn<std::shared_ptr<osgeo::proj::metadata::Identifier>> {
  TRY_DOWNCASTING($1, $result, osgeo::proj::metadata::Identifier, identifier_downcast_table)
}

// Extent is nullable when not an nn pointer
%typemap(ts) osgeo::proj::metadata::ExtentPtr           "Extent | null";
%typemap(ts) const osgeo::proj::metadata::ExtentPtr &   "Extent | null";

// PropertyMap is a very special class that is used only as an input
// argument, in JavaScript the usual convention is to pass an object
%typemap(in) const osgeo::proj::util::PropertyMap &properties (osgeo::proj::util::PropertyMap pmap) {
  if ($input.IsObject()) {
    Napi::Object obj = $input.ToObject();
    Napi::Array keys = obj.GetPropertyNames();
    for (size_t i = 0; i < keys.Length(); i++) {
      Napi::Value js_key = keys.Get(i);
      Napi::Value js_val = obj.Get(js_key);
      if (!js_key.IsString()) {
        %argument_fail(SWIG_TypeError, "string", $symname, key);
      }
      std::string *c_key;
      $typemap(in, const std::string &, input=js_key, 1=c_key, argnum=object field);
      if (js_val.IsString()) {
        std::string *s;
        $typemap(in, const std::string &, input=js_val, 1=s, argnum=object field);
        pmap.set(*c_key, *s);
      } else if (js_val.IsBoolean()) {
        bool b;
        $typemap(in, bool, input=js_val, 1=b, argnum=object field);
        pmap.set(*c_key, b);
      } else if (js_val.IsNumber()) {
        double d;
        $typemap(in, double, input=js_val, 1=d, argnum=object field);
        pmap.set(*c_key, static_cast<int>(d));
      } else {
        // try a generic object, the typemap will do the checking, this can throw
        osgeo::proj::util::BaseObject *o;
        $typemap(in, osgeo::proj::util::BaseObject *, input=js_val, 1=o, argnum=object field);
        if (o == SWIG_NULLPTR) {
          %argument_fail(SWIG_TypeError, "object value is null", $symname, $argnum);
        }
        auto nn_ptr = osgeo::proj::util::BaseObjectNNPtr{
          dropbox::oxygen::i_promise_i_checked_for_null,
          std::shared_ptr<osgeo::proj::util::BaseObject>(o, SWIG_null_deleter())
        };
        pmap.set(*c_key, nn_ptr);
      }
    }
    $1 = &pmap;
  } else {
    %argument_fail(SWIG_TypeError, "Object", $symname, $argnum);
  }
}
%typemap(ts) const osgeo::proj::util::PropertyMap &properties "Record<string, boolean | string | number | BaseObject>";
