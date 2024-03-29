from conan import ConanFile

required_conan_version = ">=2.0.0"

class PROJDependencies(ConanFile):
  settings = 'os', 'compiler', 'build_type', 'arch'

  options = {
    'CURL': [ True, False ],
    'TIFF': [ True, False ]
  }

  default_options = {
    'CURL': True,
    'TIFF': True
  }

  generators = [ 'MesonToolchain', 'PkgConfigDeps', 'CMakeDeps' ]

  def requirements(self):
    if self.options.CURL and self.settings.arch != 'wasm':
      self.requires('libcurl/[>=8.6.0 <8.7.0]')

    if self.options.TIFF:
      self.requires('libtiff/[>=4.6.0 <4.7.0]')

    self.requires('sqlite3/[>=3.45.0 <3.46.0]')

    self.tool_requires('pkgconf/2.1.0')
    self.tool_requires('sqlite3/[>=3.45.0]')
