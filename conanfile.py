from conan import ConanFile
from conan.tools.cmake import CMakeToolchain
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

  generators = [ 'MesonToolchain', 'PkgConfigDeps', 'CMakeDeps' ]

  def requirements(self):
    if self.options.curl and self.settings.arch != 'wasm':
      self.requires('libcurl/[>=8.6.0 <9]')

    if self.options.tiff:
      self.requires('libtiff/[>=4.6.0 <5]')

    self.requires('sqlite3/[>=3.45.0 <4]')

    self.tool_requires('pkgconf/2.1.0')
    self.tool_requires('sqlite3/<host_version>')

  def configure(self):
    if self.settings.arch == 'wasm':
      self.options['libwebp/*'].with_simd = False

  # We don't want the conan build system - conan works best with the platforms' defaults
  # We always use ninja on all platforms (this is the meson approach)
  #
  # conan uses its own meson and ninja
  # we use our own meson (hadron xpack) and ninja (xpack)
  # however everyone shares the same Python (hadron xpack) and cmake (xpack)
  # (although conan supports replacing its meson and ninja,
  # this is a source of trouble and brings no benefits)
  #
  # This is the least opionated approach - no one imposes anything
  # and conan remains optional
  #
  # This should probably be included in the future conan library
  #
  def generate(self):
    tc = CMakeToolchain(self)
    tc.blocks.remove('generic_system')
    tc.generate()
