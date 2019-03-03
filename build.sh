#!/bin/sh

mkdir -p build
cd build
cmake -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DYARA_TESTS=ON ..
cmake --build . -- -j
