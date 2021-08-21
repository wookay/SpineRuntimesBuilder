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
+++ spine-runtimes-3.8.95/spine-c/CMakeLists.txt	2021-08-20 10:16:42.000000000 +0900
@@ -1,8 +1,12 @@
+project(libspine)
+cmake_minimum_required(VERSION 3.1)
+set(CMAKE_MACOSX_RPATH 1)
+
 include_directories(include)
 file(GLOB INCLUDES "spine-c/include/**/*.h")
-file(GLOB SOURCES "spine-c/src/**/*.c" "spine-c/src/**/*.cpp")
+file(GLOB SOURCES "spine-c/src/**/*.c" "spine-c/src/**/*.cpp" "spine-c-unit-tests/extension.c")

-add_library(spine-c STATIC \${SOURCES} \${INCLUDES})
+add_library(spine-c \${SOURCES} \${INCLUDES})
 target_include_directories(spine-c PUBLIC spine-c/include)
-install(TARGETS spine-c DESTINATION dist/lib)
-install(FILES \${INCLUDES} DESTINATION dist/include)
\ No newline at end of file
+install(TARGETS spine-c DESTINATION lib)
+install(FILES \${INCLUDES} DESTINATION include)
diff -uNr spine-runtimes-3.8.95-original/spine-c/spine-c-unit-tests/extension.c spine-runtimes-3.8.95/spine-c/spine-c-unit-tests/extension.c
--- spine-runtimes-3.8.95-original/spine-c/spine-c-unit-tests/extension.c	1970-01-01 09:00:00.000000000 +0900
+++ spine-runtimes-3.8.95/spine-c/spine-c-unit-tests/extension.c	2021-08-22 00:57:06.000000000 +0900
@@ -0,0 +1,25 @@
+#include <unistd.h>
+#include <stdio.h>
+#include "spine/extension.h"
+#include "spine/spine.h"
+
+#ifdef __cplusplus
+extern "C" {
+#endif
+
+    void _spAtlasPage_createTexture(spAtlasPage* self, const char* path) {
+        self->rendererObject = 0;
+        self->width = 2048;
+        self->height = 2048;
+    }
+
+    void _spAtlasPage_disposeTexture(spAtlasPage* self) {
+    }
+
+    char* _spUtil_readFile(const char* path, int* length) {
+        return _spReadFile(path, length);
+    }
+
+#ifdef __cplusplus
+}
+#endif
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
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libspine-c", :libspine)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
