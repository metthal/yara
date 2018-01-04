cmake_minimum_required(VERSION 3.6)
project(
	YARA
	LANGUAGES C
	VERSION 3.7.0
)

macro(report_module module_name)
    string(TOUPPER ${module_name} module_name_upper)
    string(TOLOWER ${module_name} module_name_lower)
    if(${module_name_upper}_MODULE)
		message(STATUS "  ${module_name_lower}: ENABLED")
    else()
		message(STATUS "  ${module_name_lower}: DISABLED")
	endif()
endmacro()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

option(CUCKOO_MODULE "Enable cuckoo module" OFF)
option(DOTNET_MODULE "Enable dotnet module" OFF)
option(HASH_MODULE   "Enable hash module"   OFF)
option(MAGIC_MODULE  "Enable magic module"  OFF)
option(MACHO_MODULE  "Enable macho module"  OFF)
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    option(DOWNLOAD_JANSSON "Download Jansson library" ON)
    option(DOWNLOAD_OPENSSL "Download OpenSSL library" ON)
    option(USE_WINCRYPT     "Use Windows Cryptography API" OFF)
endif()

find_package(Threads REQUIRED)
if(MAGIC_MODULE)
    find_package(Magic REQUIRED)
endif()

add_definitions(-DPACKAGE_VERSION="${PROJECT_VERSION}")
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

message(STATUS "Configurable Modules:")
report_module(cuckoo)
report_module(dotnet)
report_module(hash)
report_module(magic)
report_module(macho)

add_subdirectory(deps)
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
