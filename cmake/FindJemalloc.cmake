# Finder for Jemalloc library.
#
# Imported targets:
# Jemalloc::Jemalloc
#
# Result variables:
# JEMALLOC_FOUND - System has found Jemalloc library.
# JEMALLOC_INCLUDE_DIR - Jemalloc include directory.
# JEMALLOC_LIBRARIES - Jemalloc library files.
# JEMALLOC_VERSION - Version of Jemalloc library.

if(UNIX)
	find_package(PkgConfig QUIET)
	pkg_check_modules(PKG_MAGIC QUIET jemalloc)
endif()

find_path(
	JEMALLOC_INCLUDE_DIR
	NAMES jemalloc.h
	HINTS ${PKG_JEMALLOC_INCLUDEDIR}
	PATH_SUFFIXES
		jemalloc
)

find_library(
	JEMALLOC_LIBRARIES
	NAMES jemalloc
	HINTS ${PKG_JEMALLOC_LIBDIR}
)

mark_as_advanced(JEMALLOC_INCLUDE_DIR JEMALLOC_LIBRARIES)

if(JEMALLOC_INCLUDE_DIR AND JEMALLOC_LIBRARIES)
	set(JEMALLOC_FOUND 1)

	file(STRINGS "${JEMALLOC_INCLUDE_DIR}/jemalloc.h" JEMALLOC_VERSION_DEFINE REGEX "^#[ \t]*define[ \t]+JEMALLOC_VERSION[ \t]+\"[^\"]+\"")
	string(REGEX REPLACE "^#[ \t]*define[ \t]+JEMALLOC_VERSION[ \t]+\"([0-9]+\.[0-9]+\.[0-9]+)[^\"]*\"" "\\1" JEMALLOC_VERSION "${JEMALLOC_VERSION_DEFINE}")

	if(NOT TARGET Jemalloc::Jemalloc)
		add_library(Jemalloc::Jemalloc UNKNOWN IMPORTED)
		set_target_properties(Jemalloc::Jemalloc PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${JEMALLOC_INCLUDE_DIR}")
		set_target_properties(Jemalloc::Jemalloc PROPERTIES IMPORTED_LOCATION "${JEMALLOC_LIBRARIES}")
	endif()
endif()

find_package_handle_standard_args(
	Jemalloc
	REQUIRED_VARS
		JEMALLOC_LIBRARIES
		JEMALLOC_INCLUDE_DIR
	VERSION_VAR
		JEMALLOC_VERSION
)
