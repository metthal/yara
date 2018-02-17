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
		COMMAND ${PROJECT_BINARY_DIR}/tests/test-${name}
		WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
	)
endmacro()

### Utility test library.
# We don't want to compile util.c with every single test.
# It's better to just create static library and link it
# against every single test.
add_library(test-util STATIC util.c)
target_link_libraries(test-util libyara)
# Post build step for `test-util` target.
# This will copy 'data' directory to current build directory.
# We need this in order to run tests.
add_custom_command(
	TARGET test-util
	POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E copy_directory data "${CMAKE_CURRENT_BINARY_DIR}/data"
	COMMENT "Copying data for testing"
	WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
)

create_test(alignment)
create_test(api)
create_test(elf)
create_test(exception)
create_test(macho)
create_test(pe)
create_test(rules)
create_test(version)