from conan import ConanFile
import subprocess
import json

required_conan_version = ">=2.0.0"

class PROJDependencies(ConanFile):
  settings = 'os', 'compiler', 'build_type', 'arch'

  options = {}
  default_options = {}
  meson_json = subprocess.Popen(['meson', 'introspect', '--buildoptions', 'meson.build'], shell=False, stdout=subprocess.PIPE)
  meson_json.wait()
  data, err = meson_json.communicate()
  meson_opts = [opt for opt in json.loads(data) if opt['section'] == 'user']
  for o in meson_opts:
    # Conan supports only booleans and combos
    if o['type'] == 'boolean':
      options[o['name']] = [ True, False ]
      default_options[o['name']] = o['value']
    elif o['type'] == 'combo':
      options[o['name']] = o['choices']
      default_options[o['name']] = o['value']

  generators = [ 'MesonToolchain', 'PkgConfigDeps', 'CMakeDeps' ]

  def requirements(self):
    if self.options.enable_curl and self.settings.arch != 'wasm':
      self.requires('libcurl/[>=8.6.0 <8.7.0]')

    if self.options.enable_tiff:
      self.requires('libtiff/[>=4.6.0 <4.7.0]')

    self.requires('sqlite3/[>=3.45.0 <3.46.0]')

    self.tool_requires('pkgconf/2.1.0')
    self.tool_requires('sqlite3/[>=3.45.0]')
