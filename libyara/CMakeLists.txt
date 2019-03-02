# Adds module to the build of specified target.
# Takes care of adding source file modules/<module-name>.c
# and defining <MODULE_NAME>_MODULE define. Name of the source
# file needs to be lowercase while defined macro is uppercased.
#
# target - Target for which to add the module
# module_name - Name of the module. Case-insensitive.
#
# Example:
# add_optional_module(libyara cuckoo)
macro(add_optional_module target module_name)
    string(TOUPPER ${module_name} module_name_upper)
    string(TOLOWER ${module_name} module_name_lower)
    if(${module_name_upper}_MODULE)
        target_compile_definitions(${target} PUBLIC ${module_name_upper}_MODULE)
        target_sources(${target} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/modules/${module_name_lower}.c")
    endif()
endmacro()

macro(create_lexer_parser lexer_file parser_file)
	string(REGEX REPLACE "\.l$" "" lexer_name ${lexer_file})
	string(REGEX REPLACE "\.y$" "" parser_name ${parser_file})
	string(REGEX REPLACE "\.l$" "\.c" lexer_output_file ${lexer_file})
	string(REGEX REPLACE "\.y$" "\.c" parser_output_file ${parser_file})
	string(REGEX REPLACE "\.y$" "\.h" parser_output_header_file ${parser_file})
	set(${lexer_name}_C "${CMAKE_CURRENT_BINARY_DIR}/${lexer_output_file}")
	set(${parser_name}_C "${CMAKE_CURRENT_BINARY_DIR}/${parser_output_file}")
	set(${parser_name}_H "${CMAKE_CURRENT_BINARY_DIR}/${parser_output_header_file}")
	FLEX_TARGET(${lexer_name} "${CMAKE_CURRENT_SOURCE_DIR}/${lexer_file}" "${${lexer_name}_C}")
	BISON_TARGET(${parser_name} "${CMAKE_CURRENT_SOURCE_DIR}/${parser_file}" "${${parser_name}_C}")
	ADD_FLEX_BISON_DEPENDENCY(${lexer_name} ${parser_name})
endmacro()

create_lexer_parser(lexer.l grammar.y)
create_lexer_parser(hex_lexer.l hex_grammar.y)
create_lexer_parser(re_lexer.l re_grammar.y)

set(LIBYARA_SOURCES
	ahocorasick.c
	arena.c
	atoms.c
	bitmask.c
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
	scanner.c
	sizedstr.c
	stack.c
	stopwatch.c
	stream.c
	strutils.c
	threading.c
	"${lexer_C}"
	"${grammar_C}"
	"${hex_lexer_C}"
	"${hex_grammar_C}"
	"${re_lexer_C}"
	"${re_grammar_C}"
)

list(APPEND LIBYARA_SOURCES
	modules/elf.c
	modules/math.c
	modules/pe.c
	modules/pe_utils.c
	modules/tests.c
	modules/time.c
)

if(YARA_SHARED)
	add_library(libyara SHARED ${LIBYARA_SOURCES})
else()
	add_library(libyara STATIC ${LIBYARA_SOURCES})
endif()

add_optional_module(libyara cuckoo)
add_optional_module(libyara dex)
add_optional_module(libyara dotnet)
add_optional_module(libyara hash)
add_optional_module(libyara macho)
add_optional_module(libyara magic)

if(MSVC)
	target_compile_options(libyara PRIVATE /W3)
	target_compile_definitions(libyara PUBLIC _CRT_SECURE_NO_WARNINGS)
else()
	target_compile_options(libyara PRIVATE -Wall -Werror)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	target_compile_definitions(libyara PUBLIC USE_LINUX_PROC)
	target_sources(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/proc/linux.c")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	target_compile_definitions(libyara PUBLIC USE_WINDOWS_PROC)
	target_sources(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/proc/windows.c")
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
	target_compile_definitions(libyara PUBLIC USE_FREEBSD_PROC)
	target_sources(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/proc/freebsd.c")
elseif(CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
	target_compile_definitions(libyara PUBLIC USE_OPENBSD_PROC)
	target_sources(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/proc/openbsd.c")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	target_compile_definitions(libyara PUBLIC USE_MACH_PROC)
	target_sources(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/proc/mach.c")
else()
	target_compile_definitions(libyara PUBLIC USE_NO_PROC)
	target_sources(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/proc/none.c")
endif()

set_target_properties(
	libyara PROPERTIES
	VERSION ${PROJECT_VERSION}
	SOVERSION ${PROJECT_VERSION}
)

# Target 'libyara' would produce liblibyara filename, so override it.
set_target_properties(libyara PROPERTIES PREFIX "")
set_target_properties(libyara PROPERTIES OUTPUT_NAME "libyara")

target_include_directories(libyara PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_include_directories(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(libyara PUBLIC
	"$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>"
)
target_include_directories(libyara PUBLIC
	"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
	"$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}>"
)

target_link_libraries(libyara Threads::Threads)

if(NOT MSVC)
	target_link_libraries(libyara m)
endif()

if(CUCKOO_MODULE)
	target_link_libraries(libyara Jansson::Jansson)
endif()

if(DEX_MODULE_DEBUG)
	target_compile_definitions(libyara PUBLIC DEBUG_DEX_MODULE)
endif()

if(HASH_MODULE)
	if(USE_OPENSSL_CRYPTO)
		target_compile_definitions(libyara PUBLIC USE_OPENSSL_CRYPTO)
		target_link_libraries(libyara OpenSSL::Crypto OpenSSL::SSL)
	elseif(USE_WINCRYPT_CRYPTO)
		target_compile_definitions(libyara PUBLIC USE_WINCRYPT_CRYPTO)
	elseif(USE_COMMONCRYPTO_CRYPTO)
		target_compile_definitions(libyara PUBLIC USE_COMMONCRYPTO_CRYPTO)
	endif()
endif()

# This should set 'off_t' type to the correct size according to the compiler (64-bit/32-bit)
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	target_compile_definitions(libyara PUBLIC _FILE_OFFSET_BITS=64)
else()
	target_compile_definitions(libyara PUBLIC _FILE_OFFSET_BITS=32)
endif()

if(MAGIC_MODULE)
	target_link_libraries(libyara Magic::Magic)
endif()

if(YARA_PROFILING)
	target_compile_definitions(libyara PUBLIC PROFILING_ENABLED)
endif()

if(YARA_ADDRESS_SANITIZER)
	setup_address_sanitizer(libyara)
endif()

if(YARA_JEMALLOC)
	setup_custom_allocator(libyara JEMALLOC Jemalloc::Jemalloc)
endif()

if(YARA_TCMALLOC)
	setup_custom_allocator(libyara TCMALLOC GPerfTools::Tcmalloc)
endif()

if(YARA_CPU_PROFILER)
	target_link_libraries(libyara GPerfTools::Profiler)
endif()

configure_file(
	"${CMAKE_CURRENT_SOURCE_DIR}/include/yara/version.h.in"
	"${CMAKE_CURRENT_BINARY_DIR}/include/yara/version.h"
	@ONLY
)

configure_file(
	"${CMAKE_CURRENT_SOURCE_DIR}/yara.pc.in"
	"${CMAKE_CURRENT_BINARY_DIR}/yara.pc"
	@ONLY
)

# Headers.
set(MAIN_LIBYARA_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/include/yara.h")
file(GLOB_RECURSE LIBYARA_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/include/yara/*.h")
list(APPEND LIBYARA_HEADERS
	"${grammar_H}"
	"${hex_grammar_H}"
	"${re_grammar_H}"
	"${CMAKE_CURRENT_BINARY_DIR}/include/yara/version.h"
)

install(
	TARGETS libyara
	EXPORT yara
	RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"
	LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}"
	ARCHIVE DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}"
)
install(
	FILES ${MAIN_LIBYARA_HEADER}
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}"
)
install(
	FILES ${LIBYARA_HEADERS}
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/yara"
)
install(
	FILES "${CMAKE_CURRENT_BINARY_DIR}/yara.pc"
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}/pkgconfig"
)
install(
	EXPORT yara
	DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}/cmake"
)
#get_target_property(LIBS libyara LINK_LIBRARIES)
#foreach(LIB ${LIBS})
#	if(TARGET ${LIB})
#		set(IS_TARGET " is target")
#		get_target_property(SUBLIBS ${LIB} INTERFACE_LINK_LIBRARIES)
#		get_target_property(IS_IMPORTED ${LIB} TYPE)
#		if("${IS_IMPORTED}" STREQUAL "INTERFACE_LIBRARY")
#			set(SUBLIBS2 "")
#		else()
#			get_target_property(SUBLIBS2 ${LIB} IMPORTED_LOCATION)
#		endif()
#	else()
#		set(IS_TARGET " is not target")
#		set(SUBLIBS "")
#		set(SUBLIBS2 "")
#	endif()
#	message("${LIB}: ${IS_TARGET} (${SUBLIBS}) (${SUBLIBS2})")
#endforeach()
