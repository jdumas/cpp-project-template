# Download Catch2 unit test framework
@project_name@_import(catch2)
FetchContent_GetProperties(catch2)
list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/contrib)
set(PARSE_CATCH_TESTS_ADD_TO_CONFIGURE_DEPENDS ON)
include(Catch)

# Create test executable
add_executable(@project_name@_tests
    main.cpp
    test_fibonacci.cpp
)

target_link_libraries(@project_name@_tests
    PRIVATE
        warnings::all
        @project_name@::@project_name@
        Catch2::Catch2
)

catch_discover_tests(@project_name@_tests)
