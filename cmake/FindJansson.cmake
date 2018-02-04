# Finder for Jansson library.
#
# Imported targets:
# Jansson
#
# Result variables:
# JANSSON_FOUND - System has found Jansson library.
# JANSSON_INCLUDE_DIR - Jansson include directory.
# JANSSON_LIBRARIES - Jansson library files.
# JANSSON_VERSION - Version of Jansson library.
#
# Hint variables:
# JANSSON_ROOT_DIR - Root directory of jansson (contains include and lib directories)

if(UNIX)
    find_package(PkgConfig QUIET)
    pkg_check_modules(PKG_JANSSON QUIET jansson)
endif()

find_path(JANSSON_INCLUDE_DIR
    NAMES jansson.h
	HINTS
		${JANSSON_ROOT_DIR}
		${PKG_JANSSON_INCLUDEDIR}
	PATH_SUFFIXES
		include)

find_library(JANSSON_LIBRARIES
    NAMES jansson
    HINTS
		${JANSSON_ROOT_DIR}
		${PKG_JANSSON_LIBDIR}
	PATH_SUFFIXES
		lib)

mark_as_advanced(JANSSON_INCLUDE_DIR JANSSON_LIBRARIES)

if(JANSSON_INCLUDE_DIR AND JANSSON_LIBRARIES)
    set(JANSSON_FOUND 1)

    file(STRINGS "${JANSSON_INCLUDE_DIR}/jansson.h" JANSSON_VERSION_DEFINE REGEX "^#[ \t]*define[ \t]+JANSSON_VERSION[ \t]+\"[^\"]+\"")
    string(REGEX REPLACE "^#[ \t]*define[ \t]+JANSSON_VERSION[ \t]+\"([^\"]+)\"" "\\1" JANSSON_VERSION "${JANSSON_VERSION_DEFINE}")

    if(NOT TARGET Jansson)
        add_library(Jansson UNKNOWN IMPORTED)
        set_target_properties(Jansson PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${JANSSON_INCLUDE_DIR}")
        set_target_properties(Jansson PROPERTIES IMPORTED_LOCATION "${JANSSON_LIBRARIES}")
    endif()
endif()

find_package_handle_standard_args(Jansson
    REQUIRED_VARS
        JANSSON_LIBRARIES
        JANSSON_INCLUDE_DIR
    VERSION_VAR
        JANSSON_VERSION)