/*
 * BaseObject is a special case, pointers to BaseObjects are a special
 * type that can automatically use nn_dynamic_cast when needed.
 */
%template(BaseObjectPtr)      std::shared_ptr<osgeo::proj::util::BaseObject>;
%template(Util_BaseObjectPtr) dropbox::oxygen::nn<std::shared_ptr<osgeo::proj::util::BaseObject>>;

// Do not expose any of those constructors
// (for JavaScript this is an abstract class)
%rename("$ignore", fullname=1) osgeo::proj::util::BaseObjectNNPtr::BaseObjectNNPtr;

%shared_ptr(osgeo::proj::util::BaseObject);
%nn_shared_ptr(osgeo::proj::util::BoxedValue);
%nn_shared_ptr(osgeo::proj::util::ArrayOfBaseObject);
%nn_shared_ptr(osgeo::proj::util::LocalName);
%nn_shared_ptr(osgeo::proj::util::NameSpace);
%nn_shared_ptr(osgeo::proj::util::GenericName);
%nn_shared_ptr(osgeo::proj::util::IComparable);

%header %{
#ifdef DEBUG
#define SWIG_VERBOSE(...) printf(__VA_ARGS__)
#else
#define SWIG_VERBOSE(...)
#endif
%}

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

// %fragment supports $descriptor, while %init does not

%define BASEOBJECT_DOWNCAST_TABLE_ENTRY(TYPE)
baseobject_downcast_table.insert({typeid(TYPE).hash_code(), $descriptor(TYPE *)})
%enddef

%fragment("include_map", "header") {
  #include <map>
}

%fragment("baseobject_downcast_table", "header", fragment="include_map") {
  std::map<std::size_t, swig_type_info *> baseobject_downcast_table;

  void init_baseobject_downcast_table() {
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::ProjectedCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::GeographicCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::VerticalCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::BoundCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::CompoundCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::CRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::SingleCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::GeodeticCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::ProjectedCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::TemporalCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::EngineeringCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::ParametricCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedGeodeticCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedGeographicCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedProjectedCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedVerticalCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedEngineeringCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedParametricCRS);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::crs::DerivedTemporalCRS);
    // These can be downcasted both from BaseObject and from CoordinateOperation (in operation.i)
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::CoordinateOperation);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::SingleOperation);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::ConcatenatedOperation);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::operation::Conversion);
    // These can be downcasted both from BaseObject and from Identifier (in metadata.i)
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::Identifier);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::Citation);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::Extent);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::GeographicBoundingBox);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::TemporalExtent);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::VerticalExtent);
    BASEOBJECT_DOWNCAST_TABLE_ENTRY(osgeo::proj::metadata::PositionalAccuracy);
  }
}

%init {
  init_baseobject_downcast_table();
}

/*
 * These typemaps check all returned shared pointers to a base type and
 * try to dynamically downcast them when the specific class is in the above table.
 * The shared_ptr remains as a pointer to the base object - the virtual destructor
 * will take care of proper deallocation.
 * Unrecognized objects remain as BaseObjectNNPtr objects.
 */
%define TRY_DOWNCASTING(INPUT, OUTPUT, BASE_TYPE, TABLE)
  // The const play is needed to silence a warning about typeid
  // having side-effects
  auto const &obj = *INPUT.get();
  std::size_t rtti_code = typeid(obj).hash_code();
  SWIG_VERBOSE(#TABLE ": downcasting for type %s: ", typeid(obj).name());
  if (TABLE.count(rtti_code) > 0) {
    swig_type_info *info = TABLE.at(rtti_code);
    SWIG_VERBOSE("found %s (%s)\n", info->str, info->name);
    OUTPUT = SWIG_NewPointerObj(INPUT.get(), info, SWIG_POINTER_OWN | %newpointer_flags);
    auto *owner = new std::shared_ptr<BASE_TYPE>(*&INPUT);
    auto finalizer = new SWIG_NAPI_Finalizer([owner](){
      delete owner;
    });
    SWIG_NAPI_SetFinalizer(env, $result, finalizer);
  } else {
    SWIG_VERBOSE("not found\n");
    $typemap(out, std::shared_ptr<BASE_TYPE>, 1=INPUT, result=OUTPUT);
  }
%enddef

%typemap(out, fragment="baseobject_downcast_table") osgeo::proj::util::BaseObjectNNPtr {
  TRY_DOWNCASTING($1, $result, osgeo::proj::util::BaseObject, baseobject_downcast_table)
}

/*
 * TypeScript has static compile-time checking just like C++, which means that
 * the explicit cast cannot be avoided
 */
#ifdef SWIGTYPESCRIPT
%typemap(ts) osgeo::proj::util::BaseObjectNNPtr "BaseObject"
#endif
