#!/bin/sh

mkdir -p build
cd build
cmake -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCUCKOO_MODULE=ON -DMAGIC_MODULE=ON -DYARA_TESTS=ON ..
cmake --build . -- -j
