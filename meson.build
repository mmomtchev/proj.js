# --------------------
# Project files
# --------------------
project('JavaScript bindings for PROJ',
  [ 'c', 'cpp' ],
  default_options : [
    'buildtype=release',
    'c_std=c11',
    'cpp_std=c++17'
  ],
  subproject_dir: 'deps',
  meson_version: '>=1.5.0'
)
module_name = 'proj'
 
sources = [
  'swig/proj_wrap.cc'
]

enable_curl = false
enable_tiff = false
inline_projdb = false

data_dir = meson.project_source_root() / 'lib' / 'binding'

# This is what parses the options
napi = import('node-api')

dependencies = [
  dependency('sqlite3', method : 'pkg-config')
]
if get_option('tiff')
  dependencies += dependency('libtiff-4', method : 'pkg-config')
  enable_tiff = true
endif
if get_option('curl') and meson.get_compiler('cpp').get_id() != 'emscripten'
  dependencies += dependency('libcurl',   method : 'pkg-config')
  enable_curl = true
endif
if get_option('inline_projdb') and meson.get_compiler('cpp').get_id() == 'emscripten'
  add_project_arguments([ '-DINLINE_PROJDB' ], language: 'cpp')
  inline_projdb = true
endif

# Build PROJ and its dependencies
cmake = import('cmake')
summary({
  'libcurl enabled'         : enable_curl,
  'libtiff enabled'         : enable_tiff,
  'inline proj.db'          : inline_projdb
})

if inline_projdb
  add_global_link_arguments([
      '--embed-file', meson.current_build_dir() / 'deps' / 'PROJ' / 'proj.db@/proj.db',
      ],
    language: [ 'c', 'cpp' ]
  )
endif

# We don't use SWIG code splitting (for now)
if meson.get_compiler('cpp').get_id() == 'msvc'
  add_global_arguments([ '/bigobj' ], language: 'cpp')
endif

cmake_opts = cmake.subproject_options()
# Build proj as a static library to be included in a shared module
cmake_opts.add_cmake_defines([
  { 'BUILD_TESTING'                     : false },
  { 'BUILD_EXAMPLES'                    : false },
  { 'BUILD_APPS'                        : false },
  { 'ENABLE_TIFF'                       : enable_tiff },
  { 'ENABLE_CURL'                       : enable_curl },
  { 'BUILD_SHARED_LIBS'                 : false },
  { 'CMAKE_DISABLE_FIND_PACKAGE_Threads': true },
  { 'CMAKE_POSITION_INDEPENDENT_CODE'   : true },
  { 'CMAKE_INSTALL_DATADIR'             : data_dir },
  # The PROJ CMake hasn't been updated with those policies (but it works)
  { 'CMAKE_POLICY_WARNING_CMP0112'      : false },
  { 'CMAKE_POLICY_WARNING_CMP0126'      : false }
])

cmake_proj = cmake.subproject('PROJ', options: cmake_opts)
dependencies += [ cmake_proj.dependency('proj') ]

# --------------------
# Build the module
# --------------------
main_target = napi.extension_module(
  module_name,
  sources,
  include_directories : [ 'src' ],
  install             : true,
  dependencies        : dependencies,
  node_api_options: {
    'swig': true,
    # Node.js is excluded from the WASM loader on purpose:
    # * it has its own native build that is much better than WASM
    # * and including it produces a loader that confuses web bundlers such as Webpack
    # 'environments': ['web','webview','worker'],
    # Export the FS subsystem
    'exported_runtime_methods': ['emnapiInit', 'FS']
  }
)

# --------------------
# SWIG generated JS/TS
# --------------------
install_data('swig' / 'proj.d.ts', install_dir: data_dir)
install_data('swig' / 'proj_wrap.cjs', install_dir: '.')

# --------------------
# The special case of proj.db
# --------------------
custom_target(
  'proj.db',
  command             : [
    'node',
    '-e',
    'fs.mkdirSync("' + get_option('prefix') + '", { recursive: true }); ' +
    'fs.copyFileSync("' + meson.current_build_dir() / 'deps' / 'PROJ' / 'proj.db' + '", "' + meson.current_build_dir() / 'proj.db' + '");'
  ],
  depends             : cmake.subproject('PROJ', options : cmake_opts).target('generate_proj_db'),
  input               : [],
  output              : 'proj.db',
  build_by_default    : true,
  install             : true,
  install_dir         : data_dir / 'proj'
)
