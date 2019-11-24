################################################################################
cmake_minimum_required(VERSION 3.11)

# Default path for downloading external dependencies
set(@PROJECT_NAME@_EXTERNAL "${CMAKE_CURRENT_LIST_DIR}/../external")
set_property(GLOBAL PROPERTY __@PROJECT_NAME@_EXTERNAL "${@PROJECT_NAME@_EXTERNAL}")

# Name of the cache directory for external dependencies
set(@PROJECT_NAME@_CACHE_DIR ".cache_${CMAKE_GENERATOR}")
string(REGEX REPLACE "[^A-Za-z0-9_.]" "_" @PROJECT_NAME@_CACHE_DIR ${@PROJECT_NAME@_CACHE_DIR})
string(TOLOWER ${@PROJECT_NAME@_CACHE_DIR} @PROJECT_NAME@_CACHE_DIR)

# Prefer git urls by default on non-Windows platforms
if(WIN32)
    option(@PROJECT_NAME@_USE_GIT_URLS "Prefer git urls for private projects." OFF)
else()
    option(@PROJECT_NAME@_USE_GIT_URLS "Prefer git urls for private projects." ON)
endif()

# Configure behavior of the FetchContent module
option(@PROJECT_NAME@_SKIP_FETCHCONTENT    "Skip update check for external projects." OFF)
option(@PROJECT_NAME@_VERBOSE_FETCHCONTENT "Make output of CMake FetchContent verbose." OFF)

################################################################################
# Wrapper around FetchContent_Declare
################################################################################

function(@project_name@_declare name)
    # Convert git urls into https on Windows
    if(NOT @PROJECT_NAME@_USE_GIT_URLS)
        cmake_parse_arguments(PARSE_ARGV 1 @PROJECT_NAME@_DECL "" "GIT_REPOSITORY" "")
        if(@PROJECT_NAME@_DECL_GIT_REPOSITORY)
            string(REPLACE "git@github.com:" "https://github.com/" TMP ${@PROJECT_NAME@_DECL_GIT_REPOSITORY})
            set(ARGN GIT_REPOSITORY ${TMP} ${@PROJECT_NAME@_DECL_UNPARSED_ARGUMENTS})
        endif()
    endif()

    # Declare content to fetch
    include(FetchContent)
    FetchContent_Declare(
        ${name}
        SOURCE_DIR   ${@PROJECT_NAME@_EXTERNAL}/${name}
        DOWNLOAD_DIR ${@PROJECT_NAME@_EXTERNAL}/${@PROJECT_NAME@_CACHE_DIR}/${name}-download
        SUBBUILD_DIR ${@PROJECT_NAME@_EXTERNAL}/${@PROJECT_NAME@_CACHE_DIR}/${name}-build
        TLS_VERIFY OFF
        GIT_CONFIG advice.detachedHead=false
        GIT_PROGRESS ${@PROJECT_NAME@_VERBOSE_FETCHCONTENT}
        ${ARGN}
    )
endfunction()

################################################################################
# Wrapper around FetchContent_Populate
################################################################################

function(@project_name@_populate contentName)
    set(OLD_FETCHCONTENT_FULLY_DISCONNECTED ${FETCHCONTENT_FULLY_DISCONNECTED})
    if(@PROJECT_NAME@_VERBOSE_FETCHCONTENT)
        set(FETCHCONTENT_QUIET OFF CACHE BOOL "" FORCE)
    else()
        set(FETCHCONTENT_QUIET ON CACHE BOOL "" FORCE)
    endif()

    string(TOLOWER ${contentName} contentNameLower)
    string(TOUPPER ${contentName} contentNameUpper)

    if(@PROJECT_NAME@_SKIP_FETCHCONTENT)
        message(STATUS "Skipping update step for package: ${contentName}")
        set(OLD_FETCHCONTENT_FULLY_DISCONNECTED ${FETCHCONTENT_FULLY_DISCONNECTED})
        set(@PROJECT_NAME@_SKIP_FETCHCONTENT ON CACHE BOOL "" FORCE)

        # For some reason, when called with FETCHCONTENT_FULLY_DISCONNECTED,
        # FetchContent_Populate assumes that ${contentName}_SOURCE_DIR is set
        # to the default path. So we override it by setting the cache variable
        # FETCHCONTENT_SOURCE_DIR_${contentNameUpper} to the default path that
        # we have set previously... unless explicitly set by the user (which
        # is why we do not FORCE it).
        get_property(@PROJECT_NAME@_EXTERNAL GLOBAL PROPERTY __@PROJECT_NAME@_EXTERNAL)
        set(FETCHCONTENT_SOURCE_DIR_${contentNameUpper} "${@PROJECT_NAME@_EXTERNAL}/${name}" CACHE PATH
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
function(@project_name@_fetch)
    include(FetchContent)
    foreach(name IN ITEMS ${ARGN})
        FetchContent_GetProperties(${name})
        if(NOT ${name}_POPULATED)
            @project_name@_populate(${name})
        endif()
    endforeach()
endfunction()

################################################################################
# Generic import behavior
################################################################################

# Default import function (fetch + add_subdirectory)
function(@project_name@_import_default name)
    include(FetchContent)
    FetchContent_GetProperties(${name})
    if(NOT ${name}_POPULATED)
        @project_name@_populate(${name})
        add_subdirectory(${${name}_SOURCE_DIR} ${${name}_BINARY_DIR})
    endif()
endfunction()

file(WRITE ${CMAKE_BINARY_DIR}/@Project_Name@Import.cmake.in
    "if(COMMAND @project_name@_import_@NAME@)\n\t@project_name@_import_@NAME@()\nelse()\n\t@project_name@_import_default(@NAME@)\nendif()"
)

# Use some meta-programming to call @project_name@_import_foo if such a function is user-defined,
# otherwise, we defer to the default behavior which is to call @project_name@_import_default(foo)
function(@project_name@_import)
    foreach(NAME IN ITEMS ${ARGN})
        set(__import_file "${CMAKE_BINARY_DIR}/@project_name@_import_${NAME}.cmake")
        configure_file("${CMAKE_BINARY_DIR}/@Project_Name@Import.cmake.in" "${__import_file}" @ONLY)
        include("${__import_file}")
    endforeach()
endfunction()

################################################################################
# Wrapper to create a target for a header-only library
################################################################################

file(WRITE ${CMAKE_BINARY_DIR}/@Project_Name@HeaderOnly.cmake.in
"function(@project_name@_import_\@ARGS_NAME\@)\n\
    @project_name@_import(\@ARGS_DEPENDS\@)\n\
    if(NOT TARGET \@ARGS_TARGET\@)\n\
        # Download \@ARGS_NAME\@\n\
        @project_name@_fetch(\@ARGS_NAME\@)\n\
        FetchContent_GetProperties(\@ARGS_NAME\@)\n\
\n\
        # Create \@ARGS_TARGET\@ target\n\
        add_library(\@ARGS_NAME\@ INTERFACE)\n\
        add_library(\@ARGS_TARGET\@ ALIAS \@ARGS_NAME\@)\n\
        target_include_directories(\@ARGS_NAME\@ SYSTEM INTERFACE \"\${\@ARGS_NAME\@_SOURCE_DIR}/\@ARGS_PREFIX\@\")\n\
    endif()\n\
endfunction()\n\
")

# This needs to be a macro in order to populate the current scope with a new function
macro(@project_name@_header_only name)
    cmake_parse_arguments(ARGS "" "PREFIX;TARGET" "DEPENDS" ${ARGN})
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
    set(__import_file "${CMAKE_BINARY_DIR}/@project_name@_header_only_${name}.cmake")
    configure_file("${CMAKE_BINARY_DIR}/@Project_Name@HeaderOnly.cmake.in" "${__import_file}" @ONLY)
    include("${__import_file}")
    message(STATUS "Creating header-only target ${ARGS_TARGET} for library ${ARGS_NAME}")
endmacro()

################################################################################
# Utilities functions to copy DLLs
################################################################################

# https://stackoverflow.com/questions/32183975/how-to-print-all-the-properties-of-a-target-in-cmake
function(@project_name@_print_target_properties tgt)
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
function(@project_name@_get_link_libraries_recursive OUTPUT_LIST_RELEASE OUTPUT_LIST_DEBUG TARGET)
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
                @project_name@_get_link_libraries_recursive(LINK_LIB_FILES_RELEASE LINK_LIB_FILES_DEBUG ${LIB})
                list(APPEND LIB_FILES_RELEASE ${LIB_FILE_RELEASE} ${LINK_LIB_FILES_RELEASE})
                list(APPEND LIB_FILES_DEBUG ${LIB_FILE_DEBUG} ${LINK_LIB_FILES_DEBUG})
            endif()
        endif()
    endforeach()
    set(${OUTPUT_LIST_RELEASE} ${LIB_FILES_RELEASE} PARENT_SCOPE)
    set(${OUTPUT_LIST_DEBUG} ${LIB_FILES_DEBUG} PARENT_SCOPE)
endfunction()

# Transitively list all link libraries of a target
function(@project_name@_get_link_libraries OUTPUT_LIST_RELEASE OUTPUT_LIST_DEBUG TARGET)
    set(VISITED_TARGETS "")
    set(LIB_FILES_RELEASE "")
    set(LIB_FILES_DEBUG "")
    @project_name@_get_link_libraries_recursive(LIB_FILES_RELEASE LIB_FILES_DEBUG ${TARGET})
    set(${OUTPUT_LIST_RELEASE} ${LIB_FILES_RELEASE} PARENT_SCOPE)
    set(${OUTPUT_LIST_DEBUG} ${LIB_FILES_DEBUG} PARENT_SCOPE)
endfunction()

# For each target given in argument to this function, copy all dlls of imported
# targets against which it is linked into the destination folder where the input
# target will be built.
function(@project_name@_copy_dlls)
    foreach(target IN ITEMS ${ARGN})
        @project_name@_get_link_libraries(LIB_FILES_RELEASE LIB_FILES_DEBUG ${target})
        function(@project_name@_copy_for_release KEEP_RELEASE)
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
        @project_name@_copy_for_release(YES ${LIB_FILES_RELEASE})
        @project_name@_copy_for_release(NO ${LIB_FILES_DEBUG})
    endforeach()
endfunction()
