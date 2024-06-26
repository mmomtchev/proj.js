# --------------------
# Project files
# --------------------
project('JavaScript bindings for PROJ',
  [ 'c', 'cpp' ],
  default_options : [
    'buildtype=release',
    'c_std=c11',
    'cpp_std=c++17'
  ])
module_name = 'proj'
 
sources = [
  'build/proj_wrap.cc'
  ]

dependencies = [
  dependency('sqlite3',   method : 'pkg-config'),
  dependency('libcurl',   method : 'pkg-config'),
  dependency('libtiff-4', method : 'pkg-config')
]
cmake_dependencies = [
  {'project' : 'PROJ', 'target' : 'proj'}
  ]
cmake_options = [
  { 'BUILD_TESTING'         : false },
  { 'BUILD_EXAMPLES'        : false },
  { 'BUILD_APPS'            : false },
  # PROJ will be "installed" in ./lib/binding
  { 'CMAKE_INSTALL_PREFIX'  : meson.global_source_root() / 'lib' / 'binding' }
  ]

if meson.get_compiler('cpp').get_id() == 'emscripten'
  # Alas, speciyfing a different location at compile-time is not possible
  #add_global_arguments([ '-DPROJ_DATA=proj.db' ], language: [ 'c', 'cpp' ])
  add_global_link_arguments([
      '--embed-file', meson.current_build_dir() / 'subprojects' / 'PROJ' / 'proj.db@/proj.db',
      # Optional, allows the calling JS code to interact with
      # the embedded file system
      '-sEXPORTED_RUNTIME_METHODS=["FS"]'
      ],
    language: [ 'c', 'cpp' ]
    )
endif

# ====================
# Everything below this point is the SWIG+Node-API+emnapi system build
# ====================

install_dir = meson.global_source_root() / 'lib' / 'binding'

# --------------------
# SWIG compiler options
# --------------------
gcc_cpp_args = [
  '-Wno-deprecated-declarations',
  '-Wno-unused-function',
  '-Wno-type-limits',
  '-Wno-deprecated-copy',
  '-Wno-attributes'
  ]
clang_cpp_args = gcc_cpp_args + [
  '-Wno-sometimes-uninitialized',
  '-Wpotentially-evaluated-expression',
  '-Wundefined-inline'
]
msvc_cpp_args = [ '/wo6246', '/wo28182', '/Zc:__cplusplus', '/bigobj' ]

name_suffix = 'node'
if meson.get_compiler('cpp').get_id() == 'clang'
  add_global_arguments(clang_cpp_args, language : 'cpp')
  if host_machine.system() == 'windows'
    add_global_arguments([ '-fms-extensions' ], language: 'cpp')
  endif
endif
if meson.get_compiler('cpp').get_id() == 'gcc'
  add_global_arguments(gcc_cpp_args, language : 'cpp')
endif
if meson.get_compiler('cpp').get_id() == 'msvc'
  add_global_arguments(msvc_cpp_args, language : 'cpp')
endif
if meson.get_compiler('cpp').get_id() == 'emscripten'
  add_global_arguments(
    clang_cpp_args +
    [ '-sNO_DISABLE_EXCEPTION_CATCHING' ],
    language : 'cpp'
  )
  add_global_arguments([ '-D__STDC_FORMAT_MACROS' ], language: [ 'c', 'cpp' ])
  name_suffix = 'mjs'
endif

# --------------------
# emnapi
# --------------------
includes = []
extra_output_files = []
if meson.get_compiler('cpp').get_id() == 'emscripten'
  extra_output_files += [ module_name + '.wasm' ]

  if not get_option('no_async')
    async_opts = [ '-pthread', '-DEMNAPI_WORKER_POOL_SIZE=4' ]
    add_global_arguments(async_opts, language : [ 'c', 'cpp' ])
    add_global_link_arguments(async_opts, language: [ 'c', 'cpp' ])
    extra_output_files += [ module_name + '.worker.mjs' ]
  else
    add_global_arguments([ '-DNO_ASYNC=1' ], language: [ 'c', 'cpp' ])
  endif
  add_global_link_arguments([
    '-sDEFAULT_PTHREAD_STACK_SIZE=1MB',
    '-sPTHREAD_POOL_SIZE=4',
    '-Wno-emcc',
    '-Wno-pthreads-mem-growth',
    '-sALLOW_MEMORY_GROWTH=1',
    '-sEXPORTED_FUNCTIONS=["_napi_register_wasm_v1","_malloc","_free"]',
    '-sNO_DISABLE_EXCEPTION_CATCHING',
    '--bind',
    '-sMODULARIZE',
    '-sEXPORT_ES6=1',
    '-sEXPORT_NAME=' + module_name,
# Pay attention to this value, if you overflow it, you will get
# all kinds of weird errors
    '-sSTACK_SIZE=1MB'
  ], language: [ 'c', 'cpp' ])

  if get_option('debug')
    add_global_arguments([ '-gsource-map' ], language : 'cpp')
    add_global_link_arguments(
      [ '-gsource-map',
      '-sSAFE_HEAP=1',
      '-sASSERTIONS=2',
      '-sSTACK_OVERFLOW_CHECK=2'
      ], language: [ 'c', 'cpp' ])
  endif

  includes += run_command(
    'node',
    '-p',
    'require("emnapi").include_dir', check: true
    ).stdout().strip()
  sources += run_command(
    'node',
    '-p',
    'require("emnapi").sources.map(x => path.relative(process.cwd(), x)).join(",")', check: true
    ).stdout().strip().split(',')
  emnapi_js_lib = run_command('node', '-p', 'require("emnapi").js_library', check: true).stdout().strip()
  add_global_link_arguments('--js-library=' + emnapi_js_lib, language : [ 'c', 'cpp' ])
endif

# --------------------
# Node-API
# --------------------
includes += run_command('node', '-p', 'require("node-addon-api").include_dir', check: true).stdout().strip()
includes += include_directories(meson.get_external_property('node_api_include'))
add_global_link_arguments(meson.get_external_property('node_lib', []), language : [ 'c', 'cpp' ])

# --------------------
# conan + meson + CMake integration
# (ie make CMake use the conan-provided libraries)
# --------------------
cmake = import('cmake')
cmake_opts = cmake.subproject_options()
cmake_opts.add_cmake_defines([
  { 'CMAKE_FIND_PACKAGE_PREFER_CONFIG'  : true },
  { 'CMAKE_PREFIX_PATH'                 : meson.current_build_dir() },
  { 'CMAKE_FIND_LIBRARY_SUFFIXES'       : '.a' },
  { 'BUILD_SHARED_LIBS'                 : false },
  { 'CMAKE_POSITION_INDEPENDENT_CODE'   : true }
  ])
cmake_opts.add_cmake_defines(cmake_options)
if get_option('debug')
  cmake_opts.add_cmake_defines({ 'CMAKE_BUILD_TYPE' : 'Debug' })
else
  cmake_opts.add_cmake_defines({ 'CMAKE_BUILD_TYPE' : 'Release' })
endif
cmake_opts.set_install(false)
cmake_opts.set_install(true, target : 'generate_proj_db')

foreach cmake_dep : cmake_dependencies
  project = cmake.subproject(cmake_dep.get('project'), options : cmake_opts)
  dependencies += [ project.dependency(cmake_dep.get('target')) ]
endforeach

# --------------------
# Build the module
# --------------------
main_target = shared_module(
  module_name,
  sources,
  include_directories : [ includes, 'src' ],
  name_prefix         : '',
  name_suffix         : name_suffix,
  install             : true,
  install_dir         : install_dir,
  dependencies        : dependencies
)

# --------------------
# Install the extra files produced by the build (emscripten)
# --------------------
if extra_output_files.length() > 0
  custom_target(
    'extra_files',
    command             : [ 'node', '-e', '' ],
    depends             : main_target,
    input               : main_target,
    output              : [ extra_output_files ],
    install             : true,
    install_dir         : install_dir
  )
endif

# --------------------
# Install the extra files produced by SWIG
# --------------------
copy_files = [ 'build' / module_name + '.d.ts', 'build' / module_name + '_wrap.cjs' ]
foreach copy_file : copy_files
  install_data(
    copy_file,
    install_dir         : install_dir
  )
endforeach

# --------------------
# The special case of proj.db
# --------------------
custom_target(
  'proj.db',
  command             : [
    'node',
    '-e',
    'fs.mkdirSync("' + install_dir + '", { recursive: true }); ' +
    'fs.copyFileSync("' + meson.current_build_dir() / 'subprojects' / 'PROJ' / 'proj.db' + '", "' + install_dir  / 'proj.db' + '");'
    ],
  depends             : cmake.subproject('PROJ', options : cmake_opts).target('generate_proj_db'),
  input               : [],
  output              : 'proj.db',
  build_by_default    : true
  )
