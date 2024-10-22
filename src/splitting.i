void swig_em_write_profile();

%{
#ifdef __EMSCRIPTEN__
  #include <emscripten.h>
  // Write the execution profile used for WASM code splitting
  EM_JS(void, swig_em_write_profile, (), {
    var __write_profile = wasmExports.__write_profile;
    if (!__write_profile) {
      console.error('__write_profile not exported');
      return;
    }

    var len = __write_profile(0, 0);
    var ptr = _malloc(len);
    __write_profile(ptr, len);

    var profile_data = HEAPU8.subarray(ptr, ptr + len);
    console.log(`writing profile.data, ${len} bytes`);
    const fs = require('fs');
    fs.writeFileSync('profile.data', profile_data);

    _free(ptr);
  });
#else
  void swig_em_write_profile() {
    SWIG_fail("Not a WASM build");
  }
#endif
%}
