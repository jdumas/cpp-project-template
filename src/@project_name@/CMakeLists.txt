################################################################################
# @Project_Name@ library
################################################################################

add_library(@project_name@
	fibonacci.cpp
	fibonacci.h
	logger.cpp
	logger.h
	common.h
	filesystem.h
)

add_library(@project_name@::@project_name@ ALIAS @project_name@)

target_include_directories(@project_name@ PUBLIC ..)

@project_name@_import(libigl filesystem json spdlog tbb)

target_link_libraries(@project_name@
	PRIVATE
		warnings::all
	PUBLIC
		igl::core
		nlohmann_json::nlohmann_json
		spdlog::spdlog
		tbb::tbb
		std::filesystem
)

# Use C++17
target_compile_features(@project_name@ PUBLIC cxx_std_17)

# Generate position independent code
set_target_properties(@project_name@ PROPERTIES POSITION_INDEPENDENT_CODE ON)
