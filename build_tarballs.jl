# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SpineRuntimes"
version = v"3.8.95"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/EsotericSoftware/spine-runtimes/archive/refs/tags/3.8.95.zip", "3edc09f4e43d1c817025964620e208c81d80c1a18e579949c5c2e672d8a17b13")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/spine-runtimes-*/spine-c/
export CFLAGS="-std=c99"
cat <<EOF > CMakeLists.txt.patch
diff -uNr spine-runtimes-3.8.95-original/spine-c/CMakeLists.txt spine-runtimes-3.8.95/spine-c/CMakeLists.txt
--- spine-runtimes-3.8.95-original/spine-c/CMakeLists.txt	2021-08-18 16:17:20.000000000 +0900
+++ spine-runtimes-3.8.95/spine-c/CMakeLists.txt	2021-08-18 16:45:14.000000000 +0900
@@ -2,7 +2,8 @@
 file(GLOB INCLUDES "spine-c/include/**/*.h")
 file(GLOB SOURCES "spine-c/src/**/*.c" "spine-c/src/**/*.cpp")

-add_library(spine-c STATIC \${SOURCES} \${INCLUDES})
+add_library(spine-c \${SOURCES} \${INCLUDES})
 target_include_directories(spine-c PUBLIC spine-c/include)
-install(TARGETS spine-c DESTINATION dist/lib)
-install(FILES \${INCLUDES} DESTINATION dist/include)
\ No newline at end of file
+install(TARGETS spine-c DESTINATION lib)
+install(FILES \${INCLUDES} DESTINATION include)
+
EOF
patch -p2 -i CMakeLists.txt.patch
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_SHARED_LIBS=1 \
    ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libspine-c", :libspine)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
