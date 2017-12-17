cmake_minimum_required(VERSION 3.6)
project(YARA C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

option(CUCKOO_MODULE "Enable cuckoo module" OFF)
option(DOTNET_MODULE "Enable dotnet module" OFF)
option(HASH_MODULE   "Enable hash module"   OFF)
option(MAGIC_MODULE  "Enable magic module"  OFF)
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    option(USE_WINCRYPT "Use Windows Cryptography API" OFF)
endif()

find_package(Threads REQUIRED)
if(CUCKOO_MODULE)
    find_package(Jansson REQUIRED)
endif()
if(HASH_MODULE)
    # We can use WinCrypt under windows, so OpenSSL is not required
    # but it is required if it is requested.
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        if(NOT USE_WINCRYPT)
            find_package(OpenSSL)
            if(NOT OPENSSL_FOUND)
                message("OpenSSL not found. Using WinCrypt API.")
            endif()
        endif()
    else()
        find_package(OpenSSL REQUIRED)
    endif()
endif()
if(MAGIC_MODULE)
    find_package(Magic REQUIRED)
endif()

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
