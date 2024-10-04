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
  'build/proj_wrap.cc'
]

enable_curl = false
enable_tiff = false
inline_projdb = false
async = false

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
if not get_option('no_async')
  async = true
endif

# Build PROJ and its dependencies
cmake = import('cmake')
summary({
  'async enabled'           : async,
  'libcurl enabled'         : enable_curl,
  'libtiff enabled'         : enable_tiff,
  'inline proj.db'          : inline_projdb
})

cmake_dependencies = [
  {'project' : 'PROJ', 'target' : 'proj'}
]
cmake_options = [
  { 'BUILD_TESTING'         : false },
  { 'BUILD_EXAMPLES'        : false },
  { 'BUILD_APPS'            : false },
  { 'ENABLE_TIFF'           : enable_tiff },
  { 'ENABLE_CURL'           : enable_curl }
]

if inline_projdb
  add_global_link_arguments([
      '--embed-file', meson.current_build_dir() / 'deps' / 'PROJ' / 'proj.db@/proj.db',
      ],
    language: [ 'c', 'cpp' ]
  )
endif

cmake_opts = cmake.subproject_options()
# Buiild proj as a static library to be included in a shared module
cmake_opts.add_cmake_defines([
  { 'BUILD_SHARED_LIBS'                 : false },
  { 'CMAKE_POSITION_INDEPENDENT_CODE'   : true }
])
cmake_opts.set_install(false)
cmake_opts.set_install(true, target : 'generate_proj_db')

foreach cmake_dep : cmake_dependencies
  project = cmake.subproject(cmake_dep.get('project'), options : cmake_opts)
  dependencies += [ project.dependency(cmake_dep.get('target')) ]
endforeach

# --------------------
# Build the module
# --------------------
napi = import('node-api')
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
    'environments': ['web','webview','worker'],
    # Export the FS subsystem
    'exported_runtime_methods': ['emnapiInit', 'FS']
  }
)


# --------------------
# The special case of proj.db
# --------------------
custom_target(
  'proj.db',
  command             : [
    'node',
    '-e',
    'fs.mkdirSync("' + get_option('prefix') + '", { recursive: true }); ' +
    'fs.copyFileSync("' + meson.current_build_dir() / 'deps' / 'PROJ' / 'proj.db' + '", "' + get_option('prefix')  / 'proj.db' + '");'
  ],
  depends             : cmake.subproject('PROJ', options : cmake_opts).target('generate_proj_db'),
  input               : [],
  output              : 'proj.db',
  build_by_default    : true
)
