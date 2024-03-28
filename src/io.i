// These use C++ features not supported by SWIG
%rename("$ignore", regextarget=1, fullname=1) "JSONFormatter::.*ObjectContext";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::CRSInfo";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::UnitInfo";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::CelestialBodyInfo";
%ignore "PROJJSON_v0_7";

%nn_shared_ptr(osgeo::proj::io::DatabaseContext);
%nn_shared_ptr(osgeo::proj::io::AuthorityFactory);
%nn_shared_ptr(osgeo::proj::io::DatabaseContext);
%nn_shared_ptr(osgeo::proj::io::DatabaseContext);
%nn_shared_ptr(osgeo::proj::io::IJSONExportable);
%nn_shared_ptr(osgeo::proj::io::IWKTExportable);
%nn_shared_ptr(osgeo::proj::io::IPROJStringExportable);

%nn_unique_ptr(osgeo::proj::io::WKTNode);

// FIXME: this seems to trigger a bug in SWIG
%ignore proj_create_from_name;
