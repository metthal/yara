# Finder for Magic library.
#
# Imported targets:
# Magic::Magic
#
# Result variables:
# MAGIC_FOUND - System has found Jansson library.
# MAGIC_INCLUDE_DIR - Jansson include directory.
# MAGIC_LIBRARIES - Jansson library files.
# MAGIC_VERSION - Version of Jansson library.

if(UNIX)
	find_package(PkgConfig QUIET)
	pkg_check_modules(PKG_MAGIC QUIET magic)
endif()

find_path(
	MAGIC_INCLUDE_DIR
	NAMES magic.h
	HINTS ${PKG_MAGIC_INCLUDEDIR}
)

find_library(
	MAGIC_LIBRARIES
	NAMES magic
	HINTS ${PKG_MAGIC_LIBDIR}
)

mark_as_advanced(MAGIC_INCLUDE_DIR MAGIC_LIBRARIES)

if(MAGIC_INCLUDE_DIR AND MAGIC_LIBRARIES)
	set(MAGIC_FOUND 1)

	file(STRINGS "${MAGIC_INCLUDE_DIR}/magic.h" MAGIC_VERSION_DEFINE REGEX "^#[ \t]*define[ \t]+MAGIC_VERSION[ \t]+[0-9]+")
	string(REGEX REPLACE "^#[ \t]*define[ \t]+MAGIC_VERSION[ \t]+([0-9])([0-9]+).*" "\\1;\\2" MAGIC_VERSION_LIST "${MAGIC_VERSION_DEFINE}")
	list(GET MAGIC_VERSION_LIST 0 MAGIC_VERSION_MAJOR)
	list(GET MAGIC_VERSION_LIST 1 MAGIC_VERSION_MINOR)
	set(MAGIC_VERSION "${MAGIC_VERSION_MAJOR}.${MAGIC_VERSION_MINOR}")

	if(NOT TARGET Magic::Magic)
		add_library(Magic::Magic UNKNOWN IMPORTED)
		set_target_properties(Magic::Magic PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${MAGIC_INCLUDE_DIR}")
		set_target_properties(Magic::Magic PROPERTIES IMPORTED_LOCATION "${MAGIC_LIBRARIES}")
	endif()
endif()

find_package_handle_standard_args(
	Magic
	REQUIRED_VARS
		MAGIC_LIBRARIES
		MAGIC_INCLUDE_DIR
	VERSION_VAR
		MAGIC_VERSION
)
