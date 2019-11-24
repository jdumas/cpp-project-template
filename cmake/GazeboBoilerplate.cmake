################################################################################
cmake_minimum_required(VERSION 3.11)

# Default path for downloading external dependencies
set(GAZEBO_EXTERNAL "${CMAKE_CURRENT_LIST_DIR}/../external")
set_property(GLOBAL PROPERTY __GAZEBO_EXTERNAL "${GAZEBO_EXTERNAL}")

# Name of the cache directory for external dependencies
set(GAZEBO_CACHE_DIR ".cache_${CMAKE_GENERATOR}")
string(REGEX REPLACE "[^A-Za-z0-9_.]" "_" GAZEBO_CACHE_DIR ${GAZEBO_CACHE_DIR})
string(TOLOWER ${GAZEBO_CACHE_DIR} GAZEBO_CACHE_DIR)

# Prefer git urls by default on non-Windows platforms
if(WIN32)
    option(GAZEBO_USE_GIT_URLS "Prefer git urls for private projects." OFF)
else()
    option(GAZEBO_USE_GIT_URLS "Prefer git urls for private projects." ON)
endif()

# Configure behavior of the FetchContent module
option(GAZEBO_SKIP_FETCHCONTENT    "Skip update check for external projects." OFF)
option(GAZEBO_VERBOSE_FETCHCONTENT "Make output of CMake FetchContent verbose." OFF)

################################################################################
# Wrapper around FetchContent_Declare
################################################################################

function(gazebo_declare name)
    # Convert git urls into https on Windows
    if(NOT GAZEBO_USE_GIT_URLS)
        cmake_parse_arguments(PARSE_ARGV 1 GAZEBO_DECL "" "GIT_REPOSITORY" "")
        if(GAZEBO_DECL_GIT_REPOSITORY)
            string(REPLACE "git@github.com:" "https://github.com/" TMP ${GAZEBO_DECL_GIT_REPOSITORY})
            set(ARGN GIT_REPOSITORY ${TMP} ${GAZEBO_DECL_UNPARSED_ARGUMENTS})
        endif()
    endif()

    # Declare content to fetch
    include(FetchContent)
    FetchContent_Declare(
        ${name}
        SOURCE_DIR   ${GAZEBO_EXTERNAL}/${name}
        DOWNLOAD_DIR ${GAZEBO_EXTERNAL}/${GAZEBO_CACHE_DIR}/${name}-download
        SUBBUILD_DIR ${GAZEBO_EXTERNAL}/${GAZEBO_CACHE_DIR}/${name}-build
        TLS_VERIFY OFF
        GIT_CONFIG advice.detachedHead=false
        GIT_PROGRESS ${GAZEBO_VERBOSE_FETCHCONTENT}
        ${ARGN}
    )
endfunction()

################################################################################
# Wrapper around FetchContent_Populate
################################################################################

function(gazebo_populate contentName)
    set(OLD_FETCHCONTENT_FULLY_DISCONNECTED ${FETCHCONTENT_FULLY_DISCONNECTED})
    if(GAZEBO_VERBOSE_FETCHCONTENT)
        set(FETCHCONTENT_QUIET OFF CACHE BOOL "" FORCE)
    else()
        set(FETCHCONTENT_QUIET ON CACHE BOOL "" FORCE)
    endif()

    string(TOLOWER ${contentName} contentNameLower)
    string(TOUPPER ${contentName} contentNameUpper)

    if(GAZEBO_SKIP_FETCHCONTENT)
        message(STATUS "Skipping update step for package: ${contentName}")
        set(OLD_FETCHCONTENT_FULLY_DISCONNECTED ${FETCHCONTENT_FULLY_DISCONNECTED})
        set(GAZEBO_SKIP_FETCHCONTENT ON CACHE BOOL "" FORCE)

        # For some reason, when called with FETCHCONTENT_FULLY_DISCONNECTED,
        # FetchContent_Populate assumes that ${contentName}_SOURCE_DIR is set
        # to the default path. So we override it by setting the cache variable
        # FETCHCONTENT_SOURCE_DIR_${contentNameUpper} to the default path that
        # we have set previously... unless explicitly set by the user (which
        # is why we do not FORCE it).
        get_property(GAZEBO_EXTERNAL GLOBAL PROPERTY __GAZEBO_EXTERNAL)
        set(FETCHCONTENT_SOURCE_DIR_${contentNameUpper} "${GAZEBO_EXTERNAL}/${name}" CACHE PATH
            "When not empty, overrides where to find pre-populated content for ${contentName}")
        FetchContent_Populate(${contentName})

        set(FETCHCONTENT_FULLY_DISCONNECTED ${OLD_FETCHCONTENT_FULLY_DISCONNECTED} CACHE BOOL "" FORCE)
    else()
        message(STATUS "Checking updates for package: ${contentName}")
        FetchContent_Populate(${contentName})
    endif()
    set(FETCHCONTENT_QUIET ${OLD_FETCHCONTENT_QUIET} CACHE BOOL "" FORCE)

    # Pass variables back to the caller. The variables passed back here
    # must match what FetchContent_GetProperties() sets when it is called
    # with just the content name.
    set(${contentNameLower}_SOURCE_DIR "${${contentNameLower}_SOURCE_DIR}" PARENT_SCOPE)
    set(${contentNameLower}_BINARY_DIR "${${contentNameLower}_BINARY_DIR}" PARENT_SCOPE)
    set(${contentNameLower}_POPULATED  True PARENT_SCOPE)
endfunction()

################################################################################
# Wrapper around FetchContent_GetProperties
################################################################################

# Default fetch function (fetch only)
function(gazebo_fetch)
    include(FetchContent)
    foreach(name IN ITEMS ${ARGN})
        FetchContent_GetProperties(${name})
        if(NOT ${name}_POPULATED)
            gazebo_populate(${name})
        endif()
    endforeach()
endfunction()

################################################################################
# Generic import behavior
################################################################################

# Default import function (fetch + add_subdirectory)
function(gazebo_import_default name)
    include(FetchContent)
    FetchContent_GetProperties(${name})
    if(NOT ${name}_POPULATED)
        gazebo_populate(${name})
        add_subdirectory(${${name}_SOURCE_DIR} ${${name}_BINARY_DIR})
    endif()
endfunction()

file(WRITE ${CMAKE_BINARY_DIR}/GazeboImport.cmake.in
    "if(COMMAND gazebo_import_@NAME@)\n\tgazebo_import_@NAME@()\nelse()\n\tgazebo_import_default(@NAME@)\nendif()"
)

# Use some meta-programming to call gazebo_import_foo if such a function is user-defined,
# otherwise, we defer to the default behavior which is to call gazebo_import_default(foo)
function(gazebo_import)
    foreach(NAME IN ITEMS ${ARGN})
        set(__import_file "${CMAKE_BINARY_DIR}/gazebo_import_${NAME}.cmake")
        configure_file("${CMAKE_BINARY_DIR}/GazeboImport.cmake.in" "${__import_file}" @ONLY)
        include("${__import_file}")
    endforeach()
endfunction()

################################################################################
# Wrapper to create a target for a header-only library
################################################################################

file(WRITE ${CMAKE_BINARY_DIR}/GazeboHeaderOnly.cmake.in
"function(gazebo_import_\@ARGS_NAME\@)\n\
    gazebo_import(\@ARGS_DEPENDS\@)\n\
    if(NOT TARGET \@ARGS_TARGET\@)\n\
        # Download \@ARGS_NAME\@\n\
        gazebo_fetch(\@ARGS_NAME\@)\n\
        FetchContent_GetProperties(\@ARGS_NAME\@)\n\
\n\
        # Create \@ARGS_TARGET\@ target\n\
        add_library(\@ARGS_NAME\@ INTERFACE)\n\
        add_library(\@ARGS_TARGET\@ ALIAS \@ARGS_NAME\@)\n\
        target_include_directories(\@ARGS_NAME\@ SYSTEM INTERFACE \"${\@ARGS_NAME\@_SOURCE_DIR}/\"\@ARGS_PREFIX\@)\n\
    endif()\n\
endfunction()\n\
")

# This needs to be a macro in order to populate the current scope with a new function
macro(gazebo_header_only name)
    cmake_parse_arguments(ARGS "" "PREFIX TARGET" "DEPENDS" ${ARGN})
    set(ARGS_NAME ${name})
    if(NOT ARGS_PREFIX)
        set(ARGS_PREFIX "")
    endif()
    if(NOT ARGS_TARGET)
        set(ARGS_TARGET ${name}::${name})
    endif()
    if(NOT ARGS_DEPENDS)
        set(ARGS_DEPENDS)
    endif()
    set(__import_file "${CMAKE_BINARY_DIR}/gazebo_header_only_${name}.cmake")
    configure_file("${CMAKE_BINARY_DIR}/GazeboHeaderOnly.cmake.in" "${__import_file}" @ONLY)
    include("${__import_file}")
endmacro()

################################################################################
# Utilities functions to copy DLLs
################################################################################

# https://stackoverflow.com/questions/32183975/how-to-print-all-the-properties-of-a-target-in-cmake
function(gazebo_print_target_properties tgt)
    if(NOT TARGET ${tgt})
      message("There is no target named '${tgt}'")
      return()
    endif()

    execute_process(COMMAND cmake --help-property-list OUTPUT_VARIABLE CMAKE_PROPERTY_LIST)

    # Convert command output into a CMake list
    string(REGEX REPLACE ";" "\\\\;" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")
    string(REGEX REPLACE "\n" ";" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")

    foreach (prop ${CMAKE_PROPERTY_LIST})
        string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${prop})
        # Fix https://stackoverflow.com/questions/32197663/how-can-i-remove-the-the-location-property-may-not-be-read-from-target-error-i
        if(prop STREQUAL "LOCATION" OR prop MATCHES "^LOCATION_" OR prop MATCHES "_LOCATION$")
            continue()
        endif()
        # message("Checking ${prop}")
        get_property(propval TARGET ${tgt} PROPERTY ${prop} SET)
        if (propval)
            get_target_property(propval ${tgt} ${prop})
            message("${tgt} ${prop} = ${propval}")
        endif()
    endforeach(prop)
endfunction()

# Transitively list all link libraries of a target (recursive call)
function(gazebo_get_link_libraries_recursive OUTPUT_LIST_RELEASE OUTPUT_LIST_DEBUG TARGET)
    get_target_property(IMPORTED ${TARGET} IMPORTED)
    get_target_property(TYPE ${TARGET} TYPE)
    if(IMPORTED OR (TYPE STREQUAL "INTERFACE_LIBRARY"))
        get_target_property(LIBS ${TARGET} INTERFACE_LINK_LIBRARIES)
    else()
        get_target_property(LIBS ${TARGET} LINK_LIBRARIES)
    endif()
    set(LIB_FILES_RELEASE "")
    set(LIB_FILES_DEBUG "")
    foreach(LIB IN ITEMS ${LIBS})
        if(TARGET "${LIB}")
            if(NOT (LIB IN_LIST VISITED_TARGETS))
                list(APPEND VISITED_TARGETS ${LIB})
                set(VISITED_TARGETS ${VISITED_TARGETS} PARENT_SCOPE)
                get_target_property(IMPORTED ${LIB} IMPORTED)
                get_target_property(TYPE ${TARGET} TYPE)
                # Somehow on Ubuntu Cosmic, Threads::Threads has type `STATIC_LIBRARY`
                # is in fact an `INTERFACE_LIBRARY`, which will cause the
                # `get_target_property(... LOCATION)` to fail...
                if(IMPORTED AND NOT (TYPE STREQUAL "INTERFACE_LIBRARY")
                    AND NOT (LIB STREQUAL "Threads::Threads"))
                    get_target_property(LIB_FILE_RELEASE ${LIB} LOCATION_RELEASE)
                    get_target_property(LIB_FILE_DEBUG ${LIB} LOCATION_DEBUG)
                else()
                    set(LIB_FILE_RELEASE "")
                    set(LIB_FILE_DEBUG "")
                endif()
                gazebo_get_link_libraries_recursive(LINK_LIB_FILES_RELEASE LINK_LIB_FILES_DEBUG ${LIB})
                list(APPEND LIB_FILES_RELEASE ${LIB_FILE_RELEASE} ${LINK_LIB_FILES_RELEASE})
                list(APPEND LIB_FILES_DEBUG ${LIB_FILE_DEBUG} ${LINK_LIB_FILES_DEBUG})
            endif()
        endif()
    endforeach()
    set(${OUTPUT_LIST_RELEASE} ${LIB_FILES_RELEASE} PARENT_SCOPE)
    set(${OUTPUT_LIST_DEBUG} ${LIB_FILES_DEBUG} PARENT_SCOPE)
endfunction()

# Transitively list all link libraries of a target
function(gazebo_get_link_libraries OUTPUT_LIST_RELEASE OUTPUT_LIST_DEBUG TARGET)
    set(VISITED_TARGETS "")
    set(LIB_FILES_RELEASE "")
    set(LIB_FILES_DEBUG "")
    gazebo_get_link_libraries_recursive(LIB_FILES_RELEASE LIB_FILES_DEBUG ${TARGET})
    set(${OUTPUT_LIST_RELEASE} ${LIB_FILES_RELEASE} PARENT_SCOPE)
    set(${OUTPUT_LIST_DEBUG} ${LIB_FILES_DEBUG} PARENT_SCOPE)
endfunction()

# For each target given in argument to this function, copy all dlls of imported
# targets against which it is linked into the destination folder where the input
# target will be built.
function(gazebo_copy_dlls)
    foreach(target IN ITEMS ${ARGN})
        gazebo_get_link_libraries(LIB_FILES_RELEASE LIB_FILES_DEBUG ${target})
        function(gazebo_copy_for_release KEEP_RELEASE)
            foreach(location IN ITEMS ${ARGN})
                string(REGEX MATCH "^(.*)\\.[^.]*$" dummy ${location})
                set(location "${CMAKE_MATCH_1}.dll")
                if(EXISTS "${location}" AND location MATCHES "^.*\\.dll$")
                    message(STATUS "Creating rule to copy dll: ${location}")
                    set(cmd ";copy_if_different;${location};$<TARGET_FILE_DIR:${target}>")
                    set(cmd "$<IF:$<EQUAL:$<BOOL:${KEEP_RELEASE}>,$<CONFIG:Release>>,${cmd},echo>")
                    add_custom_command(TARGET ${target} POST_BUILD
                        COMMAND "${CMAKE_COMMAND};-E;${cmd}" COMMAND_EXPAND_LISTS)
                endif()
            endforeach()
        endfunction()
        gazebo_copy_for_release(YES ${LIB_FILES_RELEASE})
        gazebo_copy_for_release(NO ${LIB_FILES_DEBUG})
    endforeach()
endfunction()
