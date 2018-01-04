macro(create_test name)
	add_executable(test-${name} test-${name}.c)
	target_link_libraries(test-${name} test-util)

	add_test(
		NAME test-${name}
		COMMAND ${PROJECT_BINARY_DIR}/tests/test-${name}
		WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
	)
endmacro()

add_library(test-util STATIC util.c)
target_link_libraries(test-util libyara)

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
if(MACHO_MODULE)
	create_test(macho)
endif()
create_test(pe)
create_test(rules)
create_test(version)