#!/bin/sh

mkdir -p build
cd build
cmake ${CMAKE_OPTS} -DYARA_TESTS=ON ..
cmake --build . -- -j
