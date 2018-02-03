if(DOWNLOAD_JANSSON)
    include(ExternalProject)

	set(JANSSON_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/jansson-install")

    ExternalProject_Add(jansson-external
        URL https://github.com/akheron/jansson/archive/v2.10.zip
        URL_HASH SHA256=4de7fd3099d8d1569c1973705184dfffaf1c3bf8483ae5c01c2c50f96714e40a
        PREFIX "jansson"
        CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX="${JANSSON_INSTALL_DIR}"
            -DJANSSON_BUILD_DOCS=OFF
    )

    add_library(Jansson INTERFACE)
	set_target_properties(Jansson PROPERTIES INTERFACE_LINK_LIBRARIES "${JANSSON_INSTALL_DIR}/lib/jansson$<$<CONFIG:Debug>:_d>.lib")
	target_include_directories(Jansson INTERFACE "${JANSSON_INSTALL_DIR}/include")
    add_dependencies(Jansson jansson-external)
endif()