cmake_minimum_required(VERSION 3.6)
project(
	YARA
	LANGUAGES C
	VERSION 3.7.0
)

# Prints status messages during configuration that tells you
# whether the configurable module is enabled or not.
#
# module_name - Module name. Case-insensitive.
#
# Example:
# report_module("cuckoo")
macro(report_module module_name)
    string(TOUPPER ${module_name} module_name_upper)
    string(TOLOWER ${module_name} module_name_lower)
    if(${module_name_upper}_MODULE)
		message(STATUS "  ${module_name_lower}: ENABLED")
    else()
		message(STATUS "  ${module_name_lower}: DISABLED")
	endif()
endmacro()

### Enable our own custom CMake modules.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

### Configurable options.
option(CUCKOO_MODULE "Enable cuckoo module"            OFF)
option(DOTNET_MODULE "Enable dotnet module"            OFF)
option(HASH_MODULE   "Enable hash module"              OFF)
option(MAGIC_MODULE  "Enable magic module"             OFF)
option(MACHO_MODULE  "Enable macho module"             OFF)
option(YARA_SHARED   "Build libyara as shared library" OFF)
option(YARA_TESTS    "Build tests"                     OFF)
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    option(DOWNLOAD_JANSSON "Download Jansson library" ON)
    option(DOWNLOAD_OPENSSL "Download OpenSSL library" ON)
    option(USE_WINCRYPT     "Use Windows Cryptography API" OFF)
endif()

# Show all configurable modules and whether they are configured or not.
message(STATUS "Configurable Modules:")
report_module(cuckoo)
report_module(dotnet)
report_module(hash)
report_module(magic)
report_module(macho)

### Requirements.
find_package(Threads REQUIRED)

### Global definitions.
# Provide YARA version through PACKAGE_VERSION define.
add_definitions(-DPACKAGE_VERSION="${PROJECT_VERSION}")
# Turn off CRT secure warnings for MSVC.
if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

### Subdirectories.
add_subdirectory(deps)
add_subdirectory(libyara)

###.yara
set(YARA_SOURCES
    args.c
    threading.c
    yara.c)
add_executable(yara ${YARA_SOURCES})
target_link_libraries(yara libyara)

### yarac
set(YARAC_SOURCES
    args.c
    threading.c
    yarac.c)
add_executable(yarac ${YARAC_SOURCES})
target_link_libraries(yarac libyara)

### Tests.
if(YARA_TESTS)
	enable_testing()
	add_subdirectory(tests)
endif()
