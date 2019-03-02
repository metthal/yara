cmake_minimum_required(VERSION 3.8)
project(
	YARA
	LANGUAGES C
	VERSION 3.9.0
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

macro(setup_custom_allocator target_name allocator_define allocator_library)
	target_compile_definitions(${target_name} PUBLIC ${allocator_define})
	target_compile_options(${target_name} BEFORE PUBLIC -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free)
	target_link_libraries(${target_name} ${allocator_library})
endmacro()

macro(setup_address_sanitizer target_name)
	target_compile_options(${target_name} BEFORE PUBLIC -fsanitize=address)
	target_link_libraries(${target_name} asan)
endmacro()

option(YARA_TOOLS             "Build yara & yarac tools"            ON)
option(YARA_SHARED            "Build libyara as shared library"     OFF)
option(YARA_TESTS             "Build tests"                         OFF)
option(YARA_PROFILING         "Enable/disable profiling"            OFF)
option(YARA_ADDRESS_SANITIZER "Enable/disable address sanitizer"    OFF)
option(YARA_JEMALLOC          "Enable/disable jemalloc allocator"   OFF)
option(YARA_TCMALLOC          "Enable/disable tcmalloc allocator"   OFF)
option(YARA_CPU_PROFILER      "Enable/disable CPU profilerr"        OFF)
option(CUCKOO_MODULE          "Enable/disable cuckoo module"        OFF)
option(DEX_MODULE             "Enable/disable dex module"           OFF)
option(DEX_MODULE_DEBUG       "Enable/disable dex module debugging" OFF)
option(DOTNET_MODULE          "Enable/disable dotnet module"        OFF)
option(HASH_MODULE            "Enable/disable hash module"          ON)
option(MAGIC_MODULE           "Enable/disable magic module"         OFF)
option(MACHO_MODULE           "Enable/disable macho module"         OFF)

### Enable our own custom CMake modules.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Show all optional and whether they are enabled or not.
message(STATUS "Optional Modules:")
report_module(cuckoo)
report_module(dex)
report_module(dotnet)
report_module(hash)
report_module(magic)
report_module(macho)

include(CheckIncludeFiles)
include(FindUnixCommands)
include(GNUInstallDirs)
find_package(Threads REQUIRED)
find_package(FLEX 2.6 REQUIRED)
find_package(BISON 3.0 REQUIRED)

if(CUCKOO_MODULE)
	find_package(Jansson 2.6 REQUIRED)
endif()

if(HASH_MODULE)
	find_package(OpenSSL 1.0.0)
	if(OPENSSL_FOUND)
		set(USE_OPENSSL_CRYPTO 1)
	else()
		message("*****************************************************************")
		message("  Could not find OpenSSL library. Some features in \"pe\" module")
		message("  have been disabled. If you want to enable all features please")
		message("  install OpenSSL and run this script again.")
		message("*****************************************************************")

		CHECK_INCLUDE_FILES("windows.h;wincrypt.h" HAVE_WINCRYPT_H)
		CHECK_INCLUDE_FILES("CommonCrypto/CommonCrypto.h" HAVE_COMMON_CRYPTO_H)

		if(HAVE_WINCRYPT_H)
			message("*****************************************************************")
			message("  As an alternative to OpenSSL the \"hash\" module functions will")
			message("  be provided through the Microsoft Crypto API.")
			message("*****************************************************************")
			set(USE_WINCRYPT_CRYPTO 1)
		elseif(HAVE_COMMON_CRYPTO_H)
			message("*****************************************************************")
			message("  As an alternative to OpenSSL the \"hash\" module functions will")
			message("  be provided through the MacOSX Common Crypto API.")
			message("*****************************************************************")
			set(USE_COMMONCRYPTO_CRYPTO 1)
		else()
			message(FATAL_ERROR " \
*****************************************************************\n \
  Could not find alternative APIs for hash functions.            \n \
*****************************************************************")
		endif()
	endif()
endif()

if(MAGIC_MODULE)
	find_package(Magic 5.18 REQUIRED)
endif()

if(YARA_JEMALLOC AND YARA_TCMALLOC)
	message(FATAL_ERROR "Cannot compile with both jemalloc and tcmalloc")
endif()

if(YARA_JEMALLOC)
	find_package(Jemalloc REQUIRED)
endif()

if(YARA_TCMALLOC OR YARA_CPU_PROFILER)
	find_package(GPerfTools REQUIRED)
endif()

add_subdirectory(libyara)

if(YARA_TOOLS)
	set(YARA_SOURCES
		args.c
		threading.c
		yara.c
	)
	add_executable(yara ${YARA_SOURCES})
	if(MSVC)
		target_compile_options(yara PRIVATE /W3)
	else()
		target_compile_options(yara PRIVATE -Wall -Werror)
	endif()
	target_link_libraries(yara libyara)
	set_target_properties(yara PROPERTIES VERSION ${PROJECT_VERSION})

	set(YARAC_SOURCES
		args.c
		threading.c
		yarac.c
	)
	add_executable(yarac ${YARAC_SOURCES})
	if(MSVC)
		target_compile_options(yara PRIVATE /W3)
	else()
		target_compile_options(yara PRIVATE -Wall -Werror)
	endif()
	target_link_libraries(yarac libyara)
	set_target_properties(yarac PROPERTIES VERSION ${PROJECT_VERSION})

	if(YARA_ADDRESS_SANITIZER)
		setup_address_sanitizer(yara)
		setup_address_sanitizer(yarac)
	endif()

	if(YARA_JEMALLOC)
		setup_custom_allocator(yara JEMALLOC Jemalloc::Jemalloc)
		setup_custom_allocator(yarac JEMALLOC Jemalloc::Jemalloc)
	endif()

	if(YARA_TCMALLOC)
		setup_custom_allocator(yara TCMALLOC GPerfTools::Tcmalloc)
		setup_custom_allocator(yarac TCMALLOC GPerfTools::Tcmalloc)
	endif()

	if(YARA_CPU_PROFILER)
		target_link_libraries(yara GPerfTools::Profiler)
		target_link_libraries(yarac GPerfTools::Profiler)
	endif()

	install(
		TARGETS yara yarac
		RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"
	)
	if(NOT MSVC)
		install(CODE
			"execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_INSTALL_PREFIX}/share/man/man1)
			execute_process(COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/yara.man ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_MANDIR}/man1/yara.1)
			execute_process(COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/yarac.man ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_MANDIR}/man1/yarac.1)
			message(\"-- Installing: ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_MANDIR}/man1/yara.1\")
			execute_process(COMMAND ${GZIP} -f ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_MANDIR}/man1/yara.1)
			message(\"-- Installing: ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_MANDIR}/man1/yarac.1\")
			execute_process(COMMAND ${GZIP} -f ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_MANDIR}/man1/yarac.1)"
		)
	endif()
endif()

if(YARA_TESTS)
	enable_testing()
	add_subdirectory(tests)
endif()
