%nn_shared_ptr(osgeo::proj::crs::GeographicCRS)
%nn_shared_ptr(osgeo::proj::crs::VerticalCRS)
%nn_shared_ptr(osgeo::proj::crs::BoundCRS)
%nn_shared_ptr(osgeo::proj::crs::CompoundCRS)
%nn_shared_ptr(osgeo::proj::crs::CRS)
%nn_shared_ptr(osgeo::proj::crs::SingleCRS)
%nn_shared_ptr(osgeo::proj::crs::GeodeticCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedCRS)
%nn_shared_ptr(osgeo::proj::crs::ProjectedCRS)
%nn_shared_ptr(osgeo::proj::crs::TemporalCRS)
%nn_shared_ptr(osgeo::proj::crs::EngineeringCRS)
%nn_shared_ptr(osgeo::proj::crs::ParametricCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedGeodeticCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedGeographicCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedProjectedCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedVerticalCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedEngineeringCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedParametricCRS)
%nn_shared_ptr(osgeo::proj::crs::DerivedTemporalCRS)

// These must be renamed to work in JavaScript and TypeScript
// https://github.com/mmomtchev/swig/issues/145
%rename("createDerivedVertical") osgeo::proj::crs::DerivedVerticalCRS::create;
%rename("createDerivedGeographic") osgeo::proj::crs::DerivedGeographicCRS::create;
%rename("createDerivedGeodetic") osgeo::proj::crs::DerivedGeodeticCRS::create;

// These are declared inline in the header files, but their definitions
// are in the source files. They happen to work when called from inside
// the library, but cannot be used from the outside.
%ignore CRSName;
%ignore WKTKeyword;
%ignore WKTBaseKeyword;

#define DO_NOT_DEFINE_EXTERN_DERIVED_CRS_TEMPLATE
