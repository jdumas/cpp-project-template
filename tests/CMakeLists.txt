# Download Catch2 unit test framework
gazebo_import(catch2)
FetchContent_GetProperties(catch2)
list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/contrib)
set(PARSE_CATCH_TESTS_ADD_TO_CONFIGURE_DEPENDS ON)
include(Catch)

# Create test executable
add_executable(gazebo_tests
	main.cpp
	test_fibonacci.cpp
)

target_link_libraries(gazebo_tests
	PRIVATE
		warnings::all
		gazebo::gazebo
		Catch2::Catch2
)

catch_discover_tests(gazebo_tests)
