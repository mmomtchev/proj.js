[tool_requires]
openssl/*: strawberryperl/5.32.1.1

[settings]
arch=x86_64
os=Windows
build_type=Release
compiler=clang
compiler.version=17
compiler.cppstd=gnu20
compiler.runtime=static
compiler.runtime_version=v144

[conf]
user.openssl:windows_use_jom=True
