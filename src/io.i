// These use C++ features not supported by SWIG
%rename("$ignore", regextarget=1, fullname=1) "JSONFormatter::ObjectContext";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::CRSInfo";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::UnitInfo";
%rename("$ignore", regextarget=1, fullname=1) "AuthorityFactory::CelestialBodyInfo";
namespace {
  using namespace util;
  %include <proj/io.hpp>
}
