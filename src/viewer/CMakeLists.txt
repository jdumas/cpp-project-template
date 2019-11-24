################################################################################
# GazeboViewer
################################################################################

add_executable(GazeboViewer
	main.cpp
	filedialogs.cpp
	filedialogs.h
	viewer.cpp
	viewer.h
)

gazebo_import(libigl cli11 tinyfiledialogs)

target_link_libraries(GazeboViewer
	PRIVATE
		warnings::all
		gazebo::gazebo
		igl::opengl_glfw_imgui
		igl::png
		CLI11::CLI11
		tinyfiledialogs::tinyfiledialogs
)

# Use C++17
target_compile_features(GazeboViewer PUBLIC cxx_std_17)

# Generate position independent code
set_target_properties(GazeboViewer PROPERTIES POSITION_INDEPENDENT_CODE ON)
