#!/bin/sh

rm -rf build && mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCUCKOO_MODULE=ON -DDEX_MODULE=ON -DDOTNET_MODULE=ON -DMAGIC_MODULE=ON -DMACHO_MODULE=ON -DYARA_TESTS=ON ..
cmake --build . -- -j
