%nn_shared_ptr(osgeo::proj::crs::GeographicCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::VerticalCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::BoundCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::CompoundCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::CRSPtr)
%nn_shared_ptr(osgeo::proj::crs::SingleCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::GeodeticCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::ProjectedCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::TemporalCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::EngineeringCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::ParametricCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedGeodeticCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedGeographicCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedProjectedCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedVerticalCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedEngineeringCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedParametricCRSPtr)
%nn_shared_ptr(osgeo::proj::crs::DerivedTemporalCRSPtr)

%nn_shared_ptr(osgeo::proj::metadata::UnitOfMeasurePtr)
%nn_shared_ptr(osgeo::proj::metadata::GeographicExtentPtr)
%nn_shared_ptr(osgeo::proj::metadata::GeographicBoundingBoxPtr)
%nn_shared_ptr(osgeo::proj::metadata::TemporalExtentPtr)
%nn_shared_ptr(osgeo::proj::metadata::VerticalExtentPtr)
%nn_shared_ptr(osgeo::proj::metadata::ExtentPtr)
%nn_shared_ptr(osgeo::proj::metadata::IdentifierPtr)
%nn_shared_ptr(osgeo::proj::metadata::PositionalAccuracyPtr)

#define DO_NOT_DEFINE_EXTERN_DERIVED_CRS_TEMPLATE
%include <proj/coordinatesystem.hpp>
%include <proj/crs.hpp>
