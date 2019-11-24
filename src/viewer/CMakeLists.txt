################################################################################
# @Project_Name@Viewer
################################################################################

add_executable(@Project_Name@Viewer
    main.cpp
    filedialogs.cpp
    filedialogs.h
    viewer.cpp
    viewer.h
)

@project_name@_import(libigl cli11 tinyfiledialogs)

target_link_libraries(@Project_Name@Viewer
    PRIVATE
        warnings::all
        @project_name@::@project_name@
        igl::opengl_glfw_imgui
        igl::png
        CLI11::CLI11
        tinyfiledialogs::tinyfiledialogs
)

# Use C++17
target_compile_features(@Project_Name@Viewer PUBLIC cxx_std_17)

# Generate position independent code
set_target_properties(@Project_Name@Viewer PROPERTIES POSITION_INDEPENDENT_CODE ON)
