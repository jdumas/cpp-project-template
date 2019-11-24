# Sort projects inside the solution
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

function(gazebo_folder_targets FOLDER_NAME)
    foreach(target IN ITEMS ${ARGN})
        if(TARGET ${target})
            set_target_properties(${target} PROPERTIES FOLDER "${FOLDER_NAME}")
        endif()
    endforeach()
endfunction()

function(gazebo_set_folders)

gazebo_folder_targets("ThirdParty/tbb"
    tbb_static
    tbb_def_files
    tbb_asm
)

gazebo_folder_targets("ThirdParty"
    catch2
    cli11
    cppoptlib
    fmt
    json
    libigl
    nanoflann
    pcg
    simple_svg
    spdlog
    windingnumber
)

gazebo_folder_targets("Lib"
    gazebo
)

gazebo_folder_targets("App"
    GazeboViewer
)

endfunction()
