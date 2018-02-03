# Adds module to the build of specified target.
# Takes care of adding source file modules/<module-name>.c
# and defining <MODULE_NAME>_MODULE define. Name of the source
# file needs to be lowercase while defined macro is uppercased.
#
# target - Target for which to add the module
# module_name - Name of the module. Case-insensitive.
#
# Example:
# add_module(libyara cuckoo)
macro(add_module target module_name)
    string(TOUPPER ${module_name} module_name_upper)
    string(TOLOWER ${module_name} module_name_lower)
    if(${module_name_upper}_MODULE)
        target_compile_definitions(${target} PUBLIC ${module_name_upper}_MODULE)
        target_sources(${target} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/modules/${module_name_lower}.c")
    endif()
endmacro()

# Adds process related source file proc/<platform>.c to the build
# of specified target and defines USE_<PLATFORM>_PROC. Source file name
# needs to be lowercase while defined macro is uppercased.
#
# target - Target for which to add the process file
# platform - Name of the platform. Case-insensitive.
#
# Example:
# add_proc(libyara "${CMAKE_SYSTEM_NAME}")
macro(add_proc target platform)
    string(TOUPPER ${platform} platform_upper)
    string(TOLOWER ${platform} platform_lower)
    target_compile_definitions(${target} PUBLIC USE_${platform_upper}_PROC)
    target_sources(${target} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/proc/${platform_lower}.c")
endmacro()

### Sources files that are always built.
set(LIBYARA_SOURCES
    ahocorasick.c
    arena.c
    atoms.c
    compiler.c
    endian.c
    exec.c
    exefiles.c
    filemap.c
    grammar.c
    hash.c
    hex_grammar.c
    hex_lexer.c
    lexer.c
    libyara.c
    mem.c
    modules.c
    object.c
    parser.c
    proc.c
    re.c
    re_grammar.c
    re_lexer.c
    rules.c
    scan.c
    sizedstr.c
    stopwatch.c
    stream.c
    strutils.c
    threading.c)

### Modules that are always built.
list(APPEND LIBYARA_SOURCES
    modules/elf.c
    modules/math.c
    modules/pe.c
    modules/pe_utils.c
    modules/tests.c
    modules/time.c)

### Library.
if(YARA_SHARED)
	add_library(libyara SHARED ${LIBYARA_SOURCES})
else()
	add_library(libyara STATIC ${LIBYARA_SOURCES})
endif()

# Target 'libyara' would produce liblibyara filename, so override it.
set_target_properties(libyara PROPERTIES PREFIX "")
set_target_properties(libyara PROPERTIES OUTPUT_NAME "libyara")

# Bind include directories to 'libyara' target.
target_include_directories(libyara PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

### Modules which are configurable.
### We need to do this here because target 'libyara' does not exist
### before calling add_library().
add_module(libyara cuckoo)
add_module(libyara dotnet)
add_module(libyara hash)
add_module(libyara magic)
add_module(libyara macho)

### Proc files for process scanning. It depends on platform.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux"
   OR CMAKE_SYSTEM_NAME STREQUAL "Windows"
   OR CMAKE_SYSTEM_NAME STREQUAL "FreeBSD"
   OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    add_proc(libyara ${CMAKE_SYSTEM_NAME})
else()
    add_proc(libyara "none")
endif()

### Add defines for proper crypto library.
if(HASH_MODULE)
    if(USE_WINCRYPT)
        target_compile_definitions(libyara PUBLIC HAVE_WINCRYPT)
    else()
		target_compile_definitions(libyara PUBLIC HAVE_LIBCRYPTO)
    endif()
endif()

### Link dependencies.
target_link_libraries(libyara Threads::Threads)
# Cuckoo needs Jansson.
if(CUCKOO_MODULE)
    target_link_libraries(libyara Jansson)
endif()
# Hash needs OpenSSL if WinCrypt is not used.
if(HASH_MODULE)
    if(NOT USE_WINCRYPT)
        target_link_libraries(libyara OpenSSL::Crypto)
    endif()
endif()
# Magic needs libmagic.
if(MAGIC_MODULE)
    target_link_libraries(libyara Magic)
endif()
# GCC and Clang needs  to link against math library.
if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
    target_link_libraries(libyara m)
endif()