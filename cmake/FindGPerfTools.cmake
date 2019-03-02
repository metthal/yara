# Finder for GPerfTools library.
#
# Imported targets:
# GPerfTools::Tcmalloc
# GPerfTools::Profiler
#
# Result variables:
# GPERFTOOLS_FOUND - System has found GPerfTools library (both part of it).
# GPERFTOOLS_TCMALLOC_LIBRARIES - Tcmalloc library files.
# GPERFTOOLS_PROFILER_LIBRARIES - Profiler library files.

if(UNIX)
	find_package(PkgConfig QUIET)
	pkg_check_modules(PKG_MAGIC QUIET tcmalloc)
	pkg_check_modules(PKG_MAGIC QUIET profiler)
endif()

find_library(
	GPERFTOOLS_TCMALLOC_LIBRARIES
	NAMES tcmalloc
	HINTS ${PKG_TCMALLOC_LIBDIR}
)

find_library(
	GPERFTOOLS_PROFILER_LIBRARIES
	NAMES profiler
	HINTS ${PKG_PROFILER_LIBDIR}
)

mark_as_advanced(GPERFTOOLS_TCMALLOC_LIBRARIES GPERFTOOLS_PROFILER_LIBRARIES)

if(GPERFTOOLS_TCMALLOC_LIBRARIES AND GPERFTOOLS_PROFILER_LIBRARIES)
	set(GPERFTOOL_FOUND 1)

	if(NOT TARGET GPerfTools::Tcmalloc)
		add_library(GPerfTools::Tcmalloc UNKNOWN IMPORTED)
		set_target_properties(GPerfTools::Tcmalloc PROPERTIES IMPORTED_LOCATION "${GPERFTOOLS_TCMALLOC_LIBRARIES}")
	endif()

	if(NOT TARGET GPerfTools::Profiler)
		add_library(GPerfTools::Profiler UNKNOWN IMPORTED)
		set_target_properties(GPerfTools::Profiler PROPERTIES IMPORTED_LOCATION "${GPERFTOOLS_PROFILER_LIBRARIES}")
	endif()
endif()

find_package_handle_standard_args(
	GPerfTools
	REQUIRED_VARS
		GPERFTOOLS_TCMALLOC_LIBRARIES
		GPERFTOOLS_PROFILER_LIBRARIES
)
