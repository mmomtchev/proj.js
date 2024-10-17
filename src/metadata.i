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
