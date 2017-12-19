if(NOT USE_WINCRYPT)
    if(NOT DOWNLOAD_OPENSSL)
        find_package(OpenSSL REQUIRED)
    else()
        include(ExternalProject)

        if(MSVC_VERSION GREATER_EQUAL 1910 AND MSVC_VERSION LESS_EQUAL 1919)
            set(VS_VERSION 2017)
            set(ARCHIVE_HASH 81184374837a8ccfde58c732dc8472dd989da750fb4547c3481216e312c0c3bc)
        elseif(MSVC_VERSION EQUAL 1900)
            set(VS_VERSION 2015)
            set(ARCHIVE_HASH 0d7ceda54acbe7c84394a59b911fdc7aa8a0291862f40189055349f2dc4bd307)
        elseif(MSVC_VERSION EQUAL 1800)
            set(VS_VERSION 2013)
            set(ARCHIVE_HASH e1e3aeffea196b80e5ef95ea8377d8b582943a99bebcfd96cfc01a275fc39388)
        elseif(MSVC_VERSION EQUAL 1700)
            set(VS_VERSION 2012)
            set(ARCHIVE_HASH 29978387219a10cbf413f6a26b165bab9439a51dbf616996757751faab90045a)
        elseif(MSVC_VERSION EQUAL 1600)
            set(VS_VERSION 2010)
            set(ARCHIVE_HASH c26bf9a22f6d2cd2a94c84abd8aa92d3f367f4e2477e8487cbfa879b2fddf69e)
        else()
            message(FATAL_ERROR "OpenSSL: Unsupported MSVC version: ${MSVC_VERSION}")
        endif()

        ExternalProject_Add(openssl-external
            URL https://www.npcglib.org/~stathis/downloads/openssl-1.1.0f-vs${VS_VERSION}.7z
            URL_HASH SHA256=${ARCHIVE_HASH}
            PREFIX "openssl"
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
        )
        
        get_target_property(SOURCE_DIR openssl-external BINARY_DIR)

        add_library(crypto INTERFACE)
        set_target_properties(crypto PROPERTIES INTERFACE_LINK_LIBRARIES "${SOURCE_DIR}/openssl/src/openssl-external/lib64/libcryptoMT.lib")
        target_include_directories(crypto INTERFACE "${SOURCE_DIR}/openssl/src/openssl-external/include64")
        add_dependencies(crypto openssl-external)
        
        # We will fake OpenSSL::Crypto target provided by find_package(OpenSSL)
        # Since namespaced targets are reserved for IMPORTED and ALIAS targets, we created target 'crypto'
        # which we will alias as OpenSSL::Crypto.
        add_library(OpenSSL::Crypto ALIAS crypto)
    endif()
endif()