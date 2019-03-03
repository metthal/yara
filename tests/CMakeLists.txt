# Creates new test with specified name. Source file test-<name>.c
# needs to exist.
#
# name - Name of the test.
#
# Example:
# create_test(pe)
macro(create_test name)
	add_executable(test-${name} test-${name}.c)
	target_link_libraries(test-${name} test-util)

	add_test(
		NAME test-${name}
		COMMAND ${CMAKE_CURRENT_BINARY_DIR}/test-${name}
		WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
	)

	if(YARA_ADDRESS_SANITIZER)
		setup_address_sanitizer(test-${name})
	endif()

	if(YARA_JEMALLOC)
		setup_custom_allocator(test-${name} JEMALLOC Jemalloc::Jemalloc)
	endif()

	if(YARA_TCMALLOC)
		setup_custom_allocator(test-${name} TCMALLOC GPerfTools::Tcmalloc)
	endif()

	if(YARA_CPU_PROFILER)
		target_link_libraries(test-${name} GPerfTools::Profiler)
	endif()
endmacro()

### Utility test library.
# We don't want to compile util.c with every single test.
# It's better to just create static library and link it
# against every single test.
add_library(test-util STATIC util.c)
target_link_libraries(test-util libyara)

create_test(alignment)
create_test(api)
create_test(atoms)
create_test(bitmask)
if(DEX_MODULE)
	create_test(dex)
endif()
create_test(elf)
if(UNIX AND NOT CYGWIN)
	if(NOT YARA_ADDRESS_SANITIZER)
		create_test(exception)
	endif()
endif()
if(MACHO_MODULE)
	create_test(macho)
endif()
create_test(math)
create_test(pe)
create_test(rules)
create_test(stack)
