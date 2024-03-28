/*
 * BaseObject is a special case, pointers to BaseObjects are a special
 * type that can automatically use nn_dynamic_cast when needed.
 */
%template(BaseObjectPtr)    std::shared_ptr<osgeo::proj::util::BaseObject>;

%shared_ptr(osgeo::proj::util::BaseObject);
%nn_shared_ptr(osgeo::proj::util::BoxedValue);
%nn_shared_ptr(osgeo::proj::util::ArrayOfBaseObject);
%nn_shared_ptr(osgeo::proj::util::LocalName);
%nn_shared_ptr(osgeo::proj::util::NameSpace);
%nn_shared_ptr(osgeo::proj::util::GenericName);
%nn_shared_ptr(osgeo::proj::util::IComparable);

/*
 * Certain PROJ functions - mostly those parsing user strings - return a C++ pointer to a BaseObject that is
 * in fact one of the derived classes.
 * When using those functions from C++, this pointer will be downcasted using nn_dynamic_cast and the RTTI type
 * information.
 * In a fully duck typed language such as JavaScript, we can downcast right at the function return.
 * This means that when a user calls createFromUserInput(), the returned object will be of the derived type
 * when this type has been referenced in the table below.
 * For this to work, the module has to be compiled with C++ RTTI enabled.
 */

%define DOWNCAST_TABLE_ENTRY(TYPE)
downcast_table.insert({
  typeid(TYPE).name(),
  $descriptor(TYPE *)
})
%enddef

// %fragment supports $descriptor, while %init does not
%fragment("baseobject_downcast_table", "header") {
  #include <map>
  std::map<std::string, swig_type_info *> downcast_table;
  #define BASEOBJECT_DOWNCAST_ENABLED

  void init_baseobject_downcast_table() {
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::ProjectedCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::GeographicCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::VerticalCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::BoundCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::CompoundCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::CRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::SingleCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::GeodeticCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::ProjectedCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::TemporalCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::EngineeringCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::ParametricCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedGeodeticCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedGeographicCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedProjectedCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedVerticalCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedEngineeringCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedParametricCRS);
    DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedTemporalCRS);
  }
}

%init %{
  #ifdef BASEOBJECT_DOWNCAST_ENABLED
  init_baseobject_downcast_table();
  #endif
%}

/*
 * This typemap checks all returned objects of BaseObjectNNPtr and tries
 * to dynamically downcast them when the specific class is in the above table.
 * The shared_ptr remains as a pointer to a BaseObject - the virtual destructor
 * will take care of proper deallocation.
 * Unrecognized objects remain as BaseObjectNNPtr objects.
 */
%typemap(out, fragment="baseobject_downcast_table") osgeo::proj::util::BaseObjectNNPtr {
  std::string rtti_name = typeid(*$1.get()).name();
  if (downcast_table.count(rtti_name) > 0) {
    swig_type_info *info = downcast_table.at(rtti_name);
    %set_output(SWIG_NewPointerObj($1.get(), info, SWIG_POINTER_OWN | %newpointer_flags));
    auto *owner = new std::shared_ptr<osgeo::proj::util::BaseObject>(*&$1);
    auto finalizer = new SWIG_NAPI_Finalizer([owner](){
      delete owner;
    });
    SWIG_NAPI_SetFinalizer(env, $result, finalizer);
  } else {
    $typemap(out, std::shared_ptr<osgeo::proj::util::BaseObject>);
  }
}

/*
 * TypeScript has static compile-time checking just like C++, which means that
 * the explicit cast cannot be avoided
 */
#ifdef SWIGTYPESCRIPT
%typemap(ts) osgeo::proj::util::BaseObjectNNPtr "BaseObject"
#endif
