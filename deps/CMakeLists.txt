if(CUCKOO_MODULE)
    add_subdirectory(jansson)
endif()

if(HASH_MODULE)
    add_subdirectory(openssl)
endif()

if(MAGIC_MODULE)
    find_package(Magic REQUIRED)
endif()