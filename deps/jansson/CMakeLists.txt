if(NOT DOWNLOAD_JANSSON)
    find_package(Jansson REQUIRED)
else()
    include(ExternalProject)

    ExternalProject_Add(jansson-external
        URL https://github.com/akheron/jansson/archive/v2.10.zip
        URL_HASH SHA256=4de7fd3099d8d1569c1973705184dfffaf1c3bf8483ae5c01c2c50f96714e40a
        PREFIX "jansson"
        CMAKE_ARGS
            -DJANSSON_BUILD_DOCS=OFF
        INSTALL_COMMAND ""
    )
        
    get_target_property(SOURCE_DIR jansson-external BINARY_DIR)

    add_library(Jansson INTERFACE)
    set_target_properties(Jansson PROPERTIES INTERFACE_LINK_LIBRARIES "${SOURCE_DIR}/jansson/src/jansson-external-build/lib/$<CONFIG>/jansson$<$<CONFIG:Debug>:_d>.lib")
    target_include_directories(Jansson INTERFACE "${SOURCE_DIR}/jansson/src/jansson-external-build/include")
    add_dependencies(Jansson jansson-external)
endif()