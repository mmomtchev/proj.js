// These use nested structs/classes and are not supported by SWIG
%rename("$ignore", regextarget=1, fullname=1) "JSONFormatter::.*ObjectContext";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::CRSInfo";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::UnitInfo";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::CelestialBodyInfo";
%ignore "PROJJSON_v0_7";

%inline %{
enum class ObjectType {
    PRIME_MERIDIAN,
    ELLIPSOID,
    DATUM,
    GEODETIC_REFERENCE_FRAME,
    VERTICAL_REFERENCE_FRAME,
    CRS,
    GEODETIC_CRS,
    GEOCENTRIC_CRS,
    GEOGRAPHIC_CRS,
    GEOGRAPHIC_2D_CRS,
    GEOGRAPHIC_3D_CRS,
    PROJECTED_CRS,
    VERTICAL_CRS,
    COMPOUND_CRS,
    COORDINATE_OPERATION,
    CONVERSION,
    TRANSFORMATION,
    CONCATENATED_OPERATION,
    DYNAMIC_GEODETIC_REFERENCE_FRAME,
    DYNAMIC_VERTICAL_REFERENCE_FRAME,
    DATUM_ENSEMBLE,
};
%}

// Macros for converting returned structures to JS objects
%define TMAP_OUT(TYPE, NAME)
  {
    Napi::Value js_struct_val;
    $typemap(out, TYPE, 1=$1.NAME, result=js_struct_val);
    %append_output_field(#NAME, js_struct_val);
  }
%enddef

%define TMAP_TSOUT(TYPE, NAME)
#NAME ": $typemap(ts, " #TYPE "), "
%enddef

%define CRSINFO(EX)
EX(std::string, authName)
EX(std::string, code)
EX(std::string, name)
EX(ObjectType, type)
EX(bool, deprecated)
EX(bool, bbox_valid)
EX(double, west_lon_degree)
EX(double, south_lat_degree)
EX(double, east_lon_degree)
EX(double, north_lat_degree)
EX(std::string, areaName)
EX(std::string, projectionMethodName)
EX(std::string, celestialBodyName)
%enddef

%define UNITINFO(EX)
EX(std::string, authName)
EX(std::string, code)
EX(std::string, name)
EX(std::string, category)
EX(double, convFactor)
EX(std::string, projShortName)
%enddef

%define CELESTIALBODYINFO(EX)
EX(std::string, authName)
EX(std::string, name)
%enddef

%typemap(out) osgeo::proj::io::AuthorityFactory::CRSInfo { CRSINFO(TMAP_OUT); }
%typemap(ts) osgeo::proj::io::AuthorityFactory::CRSInfo "{ " CRSINFO(TMAP_TSOUT) " }";

%typemap(out) osgeo::proj::io::AuthorityFactory::UnitInfo { UNITINFO(TMAP_OUT); }
%typemap(ts) osgeo::proj::io::AuthorityFactory::UnitInfo "{ " UNITINFO(TMAP_TSOUT) " }";

%typemap(out) osgeo::proj::io::AuthorityFactory::CelestialBodyInfo { CELESTIALBODYINFO(TMAP_OUT); }
%typemap(ts) osgeo::proj::io::AuthorityFactory::CelestialBodyInfo "{ " CELESTIALBODYINFO(TMAP_TSOUT) " }";


%nn_shared_ptr(osgeo::proj::io::DatabaseContext);
%nn_shared_ptr(osgeo::proj::io::AuthorityFactory);
%nn_shared_ptr(osgeo::proj::io::DatabaseContext);
%nn_shared_ptr(osgeo::proj::io::DatabaseContext);
%nn_shared_ptr(osgeo::proj::io::IJSONExportable);
%nn_shared_ptr(osgeo::proj::io::IWKTExportable);
%nn_shared_ptr(osgeo::proj::io::IPROJStringExportable);

%nn_unique_ptr(osgeo::proj::io::WKTFormatter);
%nn_unique_ptr(osgeo::proj::io::PROJStringFormatter);
%nn_unique_ptr(osgeo::proj::io::JSONFormatter);
%nn_unique_ptr(osgeo::proj::io::WKTNode);
