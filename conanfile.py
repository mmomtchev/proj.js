from conan import ConanFile
from os import environ

required_conan_version = ">=2.7.0"

def npm_option(option, default):
    npm_enable_opt = f'npm_config_enable_{option}'
    npm_disable_opt = f'npm_config_disable_{option}'
    if npm_disable_opt in environ:
      return False
    if npm_enable_opt in environ:
      return True
    return default

class PROJDependencies(ConanFile):
  settings = 'os', 'compiler', 'build_type', 'arch'

  options = {
    'conan': [ 'True', 'False' ],
    'tiff':  [ 'True', 'False' ],
    'curl':  [ 'True', 'False' ]
  }

  default_options = {
    'conan': npm_option('conan', False),
    'tiff':  npm_option('tiff', True) and npm_option('tiff-conan', True),
    'curl':  npm_option('curl', True) and npm_option('curl-conan', True)
  }

  generators = [ 'MesonToolchain', 'CMakeToolchain', 'PkgConfigDeps', 'CMakeDeps' ]

  def requirements(self):
    if self.options.curl and self.settings.arch != 'wasm':
      self.requires('libcurl/[>=8.6.0 <8.7.0]')

    if self.options.tiff:
      self.requires('libtiff/[>=4.6.0 <4.7.0]')

    self.requires('sqlite3/[>=3.45.0 <3.46.0]')

    self.tool_requires('pkgconf/2.1.0')
    self.tool_requires('sqlite3/[>=3.45.0]')

  def configure(self):
    if self.settings.arch == 'wasm':
      self.options['libwebp/*'].with_simd = False
