add_library(gazebo
	fibonacci.cpp
	fibonacci.h
	logger.cpp
	logger.h
	common.h
	filesystem.h
)

add_library(gazebo::gazebo ALIAS gazebo)

target_include_directories(gazebo PUBLIC ..)

gazebo_import(libigl json spdlog tbb)

find_package(Filesystem REQUIRED COMPONENTS Final Experimental)

target_link_libraries(gazebo
	PRIVATE
		warnings::all
	PUBLIC
		igl::core
		nlohmann_json::nlohmann_json
		spdlog::spdlog
		tbb::tbb
		std::filesystem
)

# Alias std::experimental::filesystem if needed
target_compile_definitions(gazebo
	PUBLIC
		GAZEBO_FILESYSTEM_HEADER=<${CXX_FILESYSTEM_HEADER}>
		GAZEBO_FILESYSTEM_NAMESPACE=${CXX_FILESYSTEM_NAMESPACE}
)

# Use C++17
target_compile_features(gazebo PUBLIC cxx_std_17)

# Generate position independent code
set_target_properties(gazebo PROPERTIES POSITION_INDEPENDENT_CODE ON)
