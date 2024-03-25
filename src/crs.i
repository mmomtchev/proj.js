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

#define DO_NOT_DEFINE_EXTERN_DERIVED_CRS_TEMPLATE
%include <proj/coordinatesystem.hpp>
%include <proj/crs.hpp>
