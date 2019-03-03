#!/bin/sh

rm -rf build && mkdir build
cd build
cmake "${CMAKE_OPTS}" ..
cmake --build . -- -j
