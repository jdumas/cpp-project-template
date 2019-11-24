# Sort projects inside the solution
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

function(@project_name@_folder_targets FOLDER_NAME)
    foreach(target IN ITEMS ${ARGN})
        if(TARGET ${target})
            set_target_properties(${target} PROPERTIES FOLDER "${FOLDER_NAME}")
        endif()
    endforeach()
endfunction()

function(@project_name@_set_folders)

@project_name@_folder_targets("ThirdParty/tbb"
    tbb_static
    tbb_def_files
    tbb_asm
)

@project_name@_folder_targets("ThirdParty"
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

@project_name@_folder_targets("Lib"
    @project_name@
)

@project_name@_folder_targets("App"
    @Project_Name@Viewer
)

endfunction()
