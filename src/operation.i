%nn_shared_ptr(osgeo::proj::coordinates::CoordinateMetadata);
%nn_shared_ptr(osgeo::proj::operation::CoordinateOperation);
%nn_shared_ptr(osgeo::proj::operation::Transformation);
%nn_shared_ptr(osgeo::proj::operation::GeneralOperationParameter);
%nn_shared_ptr(osgeo::proj::operation::OperationParameter);
%nn_shared_ptr(osgeo::proj::operation::GeneralParameterValue);
%nn_shared_ptr(osgeo::proj::operation::ParameterValue);
%nn_shared_ptr(osgeo::proj::operation::OperationParameterValue);
%nn_shared_ptr(osgeo::proj::operation::OperationMethod);
%nn_shared_ptr(osgeo::proj::operation::SingleOperation);
%nn_shared_ptr(osgeo::proj::operation::Conversion);
%nn_shared_ptr(osgeo::proj::operation::PointMotionOperation);
%nn_shared_ptr(osgeo::proj::operation::ConcatenatedOperation);

%nn_unique_ptr(osgeo::proj::operation::CoordinateOperationContext);
%nn_unique_ptr(osgeo::proj::operation::CoordinateOperationFactory);
%nn_unique_ptr(osgeo::proj::operation::CoordinateTransformer);

// See util.i for the downcasting mechanics
// This overwrites the typemap created by %nn_shared_ptr
%typemap(out, fragment="downcast_tables") dropbox::oxygen::nn<std::shared_ptr<osgeo::proj::operation::CoordinateOperation>> {
  TRY_DOWNCASTING($1, $result, osgeo::proj::operation::CoordinateOperation, coordinate_operation_downcast_table)
}
