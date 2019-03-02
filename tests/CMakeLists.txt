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
create_test(dex)
create_test(elf)
create_test(exception)
create_test(macho)
create_test(math)
create_test(pe)
create_test(rules)
create_test(stack)
create_test(version)
