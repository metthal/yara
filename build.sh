#!/bin/sh

mkdir -p build
cd build
cmake -G"Unix Makefiles" -DOPENSSL_ROOT_DIR=c:/cygwin64 -DCMAKE_BUILD_TYPE=Release -DYARA_TESTS=ON ..
cmake --build . -- -j
