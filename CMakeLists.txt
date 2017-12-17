cmake_minimum_required(VERSION 3.6)
project(YARA C)

add_subdirectory(libyara)

set(YARA_SOURCES
    args.c
    threading.c
    yara.c)
add_executable(yara ${YARA_SOURCES})
target_link_libraries(yara libyara)

set(YARAC_SOURCES
    args.c
    threading.c
    yarac.c)
add_executable(yarac ${YARAC_SOURCES})
target_link_libraries(yarac libyara)
