# Finder for Jansson library.
#
# Imported targets:
# Jansson::Jansson
#
# Result variables:
# JANSSON_FOUND - System has found Jansson library.
# JANSSON_INCLUDE_DIR - Jansson include directory.
# JANSSON_LIBRARY - Jansson library files.
# JANSSON_VERSION - Version of Jansson library.
#
# Hint variables:
# JANSSON_ROOT_DIR - Root directory of jansson (contains include and lib directories)

if(UNIX)
	find_package(PkgConfig QUIET)
	pkg_check_modules(PKG_JANSSON QUIET jansson)
endif()

find_path(
	JANSSON_INCLUDE_DIR
	NAMES jansson.h
	HINTS
		${JANSSON_ROOT_DIR}
		${PKG_JANSSON_INCLUDEDIR}
	PATH_SUFFIXES
		include
)

if(MSVC)
	find_library(
		JANSSON_LIBRARY_RELEASE
		NAMES jansson
		HINTS
			${JANSSON_ROOT_DIR}
		PATH_SUFFIXES
			lib
	)

	find_library(
		JANSSON_LIBRARY_DEBUG
		NAMES jansson_d
		HINTS
			${JANSSON_ROOT_DIR}
		PATH_SUFFIXES
			lib
	)

	include(SelectLibraryConfigurations)
    select_library_configurations(JANSSON)

	mark_as_advanced(JANSSON_LIBRARY_RELEASE JANSSON_LIBRARY_DEBUG)
else()
	find_library(
		JANSSON_LIBRARY
		NAMES jansson
		HINTS
			${JANSSON_ROOT_DIR}
			${PKG_JANSSON_LIBDIR}
		PATH_SUFFIXES
			lib
	)
endif()

mark_as_advanced(JANSSON_INCLUDE_DIR JANSSON_LIBRARY)

if(JANSSON_INCLUDE_DIR AND JANSSON_LIBRARY)
	set(JANSSON_FOUND 1)

	file(STRINGS "${JANSSON_INCLUDE_DIR}/jansson.h" JANSSON_VERSION_DEFINE REGEX "^#[ \t]*define[ \t]+JANSSON_VERSION[ \t]+\"[^\"]+\"")
	string(REGEX REPLACE "^#[ \t]*define[ \t]+JANSSON_VERSION[ \t]+\"([^\"]+)\"" "\\1" JANSSON_VERSION "${JANSSON_VERSION_DEFINE}")

	if(NOT TARGET Jansson::Jansson)
		add_library(Jansson::Jansson UNKNOWN IMPORTED)
		set_target_properties(Jansson::Jansson PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${JANSSON_INCLUDE_DIR}")
		if(EXISTS "${JANSSON_LIBRARY}")
			set_target_properties(Jansson::Jansson PROPERTIES IMPORTED_LOCATION "${JANSSON_LIBRARY}")
		endif()
		if(EXISTS "${JANSSON_LIBRARY_RELEASE}")
			set_property(TARGET Jansson::Jansson APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
			set_target_properties(Jansson::Jansson PROPERTIES IMPORTED_LOCATION_RELEASE "${JANSSON_LIBRARY_RELEASE}")
		endif()
		if(EXISTS "${JANSSON_LIBRARY_DEBUG}")
			set_property(TARGET Jansson::Jansson APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
			set_target_properties(Jansson::Jansson PROPERTIES IMPORTED_LOCATION_DEBUG "${JANSSON_LIBRARY_DEBUG}")
		endif()
	endif()
endif()

find_package_handle_standard_args(
	Jansson
	REQUIRED_VARS
		JANSSON_LIBRARY
		JANSSON_INCLUDE_DIR
	VERSION_VAR
		JANSSON_VERSION
)
