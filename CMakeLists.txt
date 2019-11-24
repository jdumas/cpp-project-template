################################################################################

cmake_minimum_required(VERSION 3.11)
project(@project_name@)

################################################################################
# Settings
################################################################################

# CMP0063: Honor visibility properties for all target types.
if(POLICY CMP0063)
    cmake_policy(SET CMP0063 NEW)
endif()

# Check whether this is a top-level project
get_directory_property(HAS_PARENT PARENT_DIRECTORY)
if(NOT HAS_PARENT)
    set(@PROJECT_NAME@_TOPLEVEL_PROJECT ON)
else()
    set(@PROJECT_NAME@_TOPLEVEL_PROJECT OFF)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

# Color output
include(UseColors)

# Extra compiler warnings
include(Warnings)

################################################################################
# Dependencies
################################################################################

include(@Project_Name@External)

################################################################################
# Subdirectories
################################################################################

add_subdirectory(src)

# Compile extras only if this is a top-level project
if(@PROJECT_NAME@_TOPLEVEL_PROJECT)
    # Unit tests
    include(CTest)
    enable_testing()
    add_subdirectory(tests)
endif()

# Set folders for Visual Studio/Xcode
include(@Project_Name@Folders)
@project_name@_set_folders()
