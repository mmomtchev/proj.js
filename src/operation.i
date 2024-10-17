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

%define COORDINATE_OPERATION_DOWNCAST_TABLE_ENTRY(TYPE)
coordinate_operation_downcast_table.insert({typeid(TYPE).hash_code(), $descriptor(TYPE *)})
%enddef

%fragment("coordinate_operation_downcast_table", "header", fragment="include_map") {
  std::map<std::size_t, swig_type_info *> coordinate_operation_downcast_table;

  void init_coordinate_operation_downcast_table() {
    COORDINATE_OPERATION_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::CoordinateOperation);
    COORDINATE_OPERATION_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::SingleOperation);
    COORDINATE_OPERATION_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::ConcatenatedOperation);
    COORDINATE_OPERATION_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::Conversion);
  }
}

%init {
  init_coordinate_operation_downcast_table();
}

// See util.i for the downcasting mechanics
// This overwrites the typemap created by %nn_shared_ptr
%typemap(out, fragment="coordinate_operation_downcast_table") dropbox::oxygen::nn<std::shared_ptr<osgeo::proj::operation::CoordinateOperation>> {
  TRY_DOWNCASTING($1, $result, osgeo::proj::operation::CoordinateOperation, coordinate_operation_downcast_table)
}
