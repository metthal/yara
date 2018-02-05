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

### Source files.
# Setup flex/bison related files. If flex & bison are present, then use them.
# Otherwise just use pregenerated files.
if(FLEX_BISON_INSTALLED)
	set(LEXER_C "${CMAKE_CURRENT_BINARY_DIR}/lexer.c")
	set(GRAMMAR_C "${CMAKE_CURRENT_BINARY_DIR}/grammar.c")
	set(GRAMMAR_H "${CMAKE_CURRENT_BINARY_DIR}/grammar.h")
	FLEX_TARGET(lexer "${CMAKE_CURRENT_SOURCE_DIR}/lexer.l" "${LEXER_C}")
	BISON_TARGET(grammar "${CMAKE_CURRENT_SOURCE_DIR}/grammar.y" "${GRAMMAR_C}")
	ADD_FLEX_BISON_DEPENDENCY(lexer grammar)

	set(HEX_LEXER_C "${CMAKE_CURRENT_BINARY_DIR}/hex_lexer.c")
	set(HEX_GRAMMAR_C "${CMAKE_CURRENT_BINARY_DIR}/hex_grammar.c")
	set(HEX_GRAMMAR_H "${CMAKE_CURRENT_BINARY_DIR}/hex_grammar.h")
	FLEX_TARGET(hex_lexer "${CMAKE_CURRENT_SOURCE_DIR}/hex_lexer.l" "${HEX_LEXER_C}")
	BISON_TARGET(hex_grammar "${CMAKE_CURRENT_SOURCE_DIR}/hex_grammar.y" "${HEX_GRAMMAR_C}")
	ADD_FLEX_BISON_DEPENDENCY(hex_lexer hex_grammar)

	set(RE_LEXER_C "${CMAKE_CURRENT_BINARY_DIR}/re_lexer.c")
	set(RE_GRAMMAR_C "${CMAKE_CURRENT_BINARY_DIR}/re_grammar.c")
	set(RE_GRAMMAR_H "${CMAKE_CURRENT_BINARY_DIR}/re_grammar.h")
	FLEX_TARGET(re_lexer "${CMAKE_CURRENT_SOURCE_DIR}/re_lexer.l" "${RE_LEXER_C}")
	BISON_TARGET(re_grammar "${CMAKE_CURRENT_SOURCE_DIR}/re_grammar.y" "${RE_GRAMMAR_C}")
	ADD_FLEX_BISON_DEPENDENCY(re_lexer re_grammar)
else()
	set(LEXER_C "${CMAKE_CURRENT_SOURCE_DIR}/lexer.c")
	set(GRAMMAR_C "${CMAKE_CURRENT_SOURCE_DIR}/grammar.c")
	set(GRAMMAR_H "${CMAKE_CURRENT_SOURCE_DIR}/grammar.h")

	set(HEX_LEXER_C "${CMAKE_CURRENT_SOURCE_DIR}/hex_lexer.c")
	set(HEX_GRAMMAR_C "${CMAKE_CURRENT_SOURCE_DIR}/hex_grammar.c")
	set(HEX_GRAMMAR_H "${CMAKE_CURRENT_SOURCE_DIR}/hex_grammar.h")

	set(RE_LEXER_C "${CMAKE_CURRENT_SOURCE_DIR}/re_lexer.c")
	set(RE_GRAMMAR_C "${CMAKE_CURRENT_SOURCE_DIR}/re_grammar.c")
	set(RE_GRAMMAR_H "${CMAKE_CURRENT_SOURCE_DIR}/re_grammar.h")
endif()

# Sources files that are always built.
set(LIBYARA_SOURCES
    ahocorasick.c
    arena.c
    atoms.c
    compiler.c
    endian.c
    exec.c
    exefiles.c
    filemap.c
    hash.c
    libyara.c
    mem.c
    modules.c
    object.c
    parser.c
    proc.c
    re.c
    rules.c
    scan.c
    sizedstr.c
    stream.c
    strutils.c
    threading.c
	${LEXER_C}
	${GRAMMAR_C}
	${HEX_LEXER_C}
	${HEX_GRAMMAR_C}
	${RE_LEXER_C}
	${RE_GRAMMAR_C})

# Stopwatch is needed only when profiling is enabled.
if(YARA_PROFILING)
	list(APPEND LIBYARA_SOURCES stopwatch.c)
endif()

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
# Library version.
set_target_properties(libyara PROPERTIES
	VERSION ${PROJECT_VERSION}
	SOVERSION ${PROJECT_VERSION})

# Target 'libyara' would produce liblibyara filename, so override it.
set_target_properties(libyara PROPERTIES PREFIX "")
set_target_properties(libyara PROPERTIES OUTPUT_NAME "libyara")

# Bind include directories to 'libyara' target.
# Binary directory needs to be first because of pregenerated bison headers.
target_include_directories(libyara PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_include_directories(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(libyara PUBLIC
	"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
	"$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include>")

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
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	add_proc(libyara "mach")
else()
    add_proc(libyara "none")
endif()

### Add defines for proper crypto library.
if(HASH_MODULE)
    if(USE_WINCRYPT)
        target_compile_definitions(libyara PUBLIC HAVE_WINCRYPT)
	elseif(USE_COMMONCRYPTO)
		target_compile_definitions(libyara PUBLIC HAVE_COMMONCRYPTO)
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
	if(NOT USE_WINCRYPT AND NOT USE_COMMONCRYPTO)
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

### Configuration for pkg-config.
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/yara.pc.in"
	"${CMAKE_CURRENT_BINARY_DIR}/yara.pc"
	@ONLY)

### Headers.
set(MAIN_LIBYARA_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/include/yara.h")
file(GLOB_RECURSE LIBYARA_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/include/yara/*.h")
list(APPEND LIBYARA_HEADERS "${GRAMMAR_H}" "${HEX_GRAMMAR_H}" "${RE_GRAMMAR_H}")

### Installation.
install(TARGETS libyara
	EXPORT YARA
	RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"
	LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}"
	ARCHIVE DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
install(FILES ${MAIN_LIBYARA_HEADER}
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}")
install(FILES ${LIBYARA_HEADERS}
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/yara")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/yara.pc"
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}/pkgconfig")
install(EXPORT YARA
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}/yara")