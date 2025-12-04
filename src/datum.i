%nn_shared_ptr(osgeo::proj::datum::Datum)
%nn_shared_ptr(osgeo::proj::datum::DatumEnsemble)
%nn_shared_ptr(osgeo::proj::datum::PrimeMeridian)
%nn_shared_ptr(osgeo::proj::datum::Ellipsoid)
%nn_shared_ptr(osgeo::proj::datum::GeodeticReferenceFrame)
%nn_shared_ptr(osgeo::proj::datum::VerticalReferenceFrame)
%nn_shared_ptr(osgeo::proj::datum::TemporalDatum)
%nn_shared_ptr(osgeo::proj::datum::EngineeringDatum)
%nn_shared_ptr(osgeo::proj::datum::ParametricDatum)
%nn_shared_ptr(osgeo::proj::datum::DynamicGeodeticReferenceFrame)
%nn_shared_ptr(osgeo::proj::datum::DynamicVerticalReferenceFrame)

// These must be renamed to work in JavaScript and TypeScript
// https://github.com/mmomtchev/swig/issues/145
%rename("createDynamicGeodetic") osgeo::proj::datum::DynamicGeodeticReferenceFrame::create;
%rename("createDynamicVertical") osgeo::proj::datum::DynamicVerticalReferenceFrame::create;
