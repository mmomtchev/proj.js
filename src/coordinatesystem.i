%nn_shared_ptr(osgeo::proj::cs::Meridian)
%nn_shared_ptr(osgeo::proj::cs::CoordinateSystemAxis)
%nn_shared_ptr(osgeo::proj::cs::CoordinateSystem)
%nn_shared_ptr(osgeo::proj::cs::SphericalCS)
%nn_shared_ptr(osgeo::proj::cs::EllipsoidalCS)
%nn_shared_ptr(osgeo::proj::cs::VerticalCS)
%nn_shared_ptr(osgeo::proj::cs::CartesianCS)
%nn_shared_ptr(osgeo::proj::cs::AffineCS)
%nn_shared_ptr(osgeo::proj::cs::OrdinalCS)
%nn_shared_ptr(osgeo::proj::cs::ParametricCS)
%nn_shared_ptr(osgeo::proj::cs::TemporalCS)
%nn_shared_ptr(osgeo::proj::cs::DateTimeTemporalCS)
%nn_shared_ptr(osgeo::proj::cs::TemporalCountCS)
%nn_shared_ptr(osgeo::proj::cs::TemporalMeasureCS)

// Meridian is nullable when not an nn pointer
%typemap(ts) osgeo::proj::cs::MeridianPtr           "Meridian | null";
%typemap(ts) const osgeo::proj::cs::MeridianPtr &   "Meridian | null";
