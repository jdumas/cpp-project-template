include(@Project_Name@Boilerplate)

################################################################################
# Declare third-party dependencies here
################################################################################

@project_name@_declare(catch2           GIT_REPOSITORY https://github.com/catchorg/Catch2.git            GIT_TAG v2.11.0)
@project_name@_declare(cli11            GIT_REPOSITORY https://github.com/CLIUtils/CLI11.git             GIT_TAG v1.8.0)
@project_name@_declare(cppoptlib        GIT_REPOSITORY https://github.com/PatWie/CppNumericalSolvers.git GIT_TAG 2a0f98e7c54c35325641e05c035e43cafd570808)
@project_name@_declare(eigen            GIT_REPOSITORY https://github.com/eigenteam/eigen-git-mirror     GIT_TAG 3.3.7)
@project_name@_declare(ghc_filesystem   GIT_REPOSITORY https://github.com/gulrak/filesystem.git          GIT_TAG v1.2.10)
@project_name@_declare(fmt              GIT_REPOSITORY https://github.com/fmtlib/fmt                     GIT_TAG 6.0.0)
@project_name@_declare(json             GIT_REPOSITORY https://github.com/nlohmann/json                  GIT_TAG v3.7.3)
@project_name@_declare(libigl           GIT_REPOSITORY https://github.com/libigl/libigl.git              GIT_TAG 2ecb5fc85fc124ba4dd839c6b43a836a0d2a017e)
@project_name@_declare(nanoflann        GIT_REPOSITORY https://github.com/jlblancoc/nanoflann            GIT_TAG v1.3.1)
@project_name@_declare(pcg              GIT_REPOSITORY https://github.com/imneme/pcg-cpp.git             GIT_TAG b263c73ec965ad515de8be8286086d78c67c2f01)
@project_name@_declare(simple_svg       GIT_REPOSITORY https://github.com/adishavit/simple-svg.git       GIT_TAG 4b2fbfc0a6f98dc24e36f6269d5f4b7d49647589)
@project_name@_declare(spdlog           GIT_REPOSITORY https://github.com/gabime/spdlog                  GIT_TAG v1.4.2)
@project_name@_declare(tbb              GIT_REPOSITORY https://github.com/wjakob/tbb.git                 GIT_TAG 20357d83871e4cb93b2c724fe0c337cd999fd14f)
@project_name@_declare(tinyfiledialogs  GIT_REPOSITORY https://git.code.sf.net/p/tinyfiledialogs/code    GIT_TAG c5ea3d553f044e3c24655524736e0c084a964e25)
@project_name@_declare(windingnumber    GIT_REPOSITORY https://github.com/sideeffects/WindingNumber      GIT_TAG 1e6081e52905575d8e98fb8b7c0921274a18752f)

# Not supported yet
@project_name@_declare(amgcl            GIT_REPOSITORY https://github.com/ddemidov/amgcl.git          GIT_TAG a2fab1037946de87e448e5fc7539277cd6fb9ec3)
@project_name@_declare(geogram          GIT_REPOSITORY https://github.com/alicevision/geogram.git     GIT_TAG v1.7.2)
@project_name@_declare(hypre            GIT_REPOSITORY https://github.com/LLNL/hypre.git              GIT_TAG v2.15.1)
@project_name@_declare(mmg              GIT_REPOSITORY https://github.com/MmgTools/mmg.git            GIT_TAG 88e2dd6cc773c43141b137fd0972c0eb2f4bbd2a)
@project_name@_declare(nanosvg          GIT_REPOSITORY https://github.com/memononen/nanosvg.git       GIT_TAG 2b08deeb553c723d151f908d786c64136d26d576)
@project_name@_declare(osqp             GIT_REPOSITORY https://github.com/oxfordcontrol/osqp.git      GIT_TAG c60bb3c4569df8b93c761b6743022fdb4b8e1432)
@project_name@_declare(pybind11         GIT_REPOSITORY https://github.com/jdumas/pybind11.git         GIT_TAG a615b8fab7d2c172eba98beb6e15497f2e346c7d)
@project_name@_declare(sanitizers_cmake GIT_REPOSITORY https://github.com/arsenm/sanitizers-cmake.git GIT_TAG 6947cff3a9c9305eb9c16135dd81da3feb4bf87f)
@project_name@_declare(spectra          GIT_REPOSITORY https://github.com/yixuan/spectra.git          GIT_TAG v0.6.2)
@project_name@_declare(tetwild          GIT_REPOSITORY https://github.com/Yixin-Hu/TetWild.git        GIT_TAG 55d770a97df1364921e70cc3a65f6079e8c13732)
@project_name@_declare(tinyexpr         GIT_REPOSITORY https://github.com/polyfem/tinyexpr.git        GIT_TAG eb73c7e4005195bf5c0f1fa28dee3b489d59f821)
# clipper
# Autodiff
# tetwild
# geogram
# suitesparse (Cholmod/Umfpack/SuperLU)
# mkl

################################################################################
# Custom import functions for header-only libraries
################################################################################

@project_name@_header_only(eigen      TARGET Eigen3::Eigen)
@project_name@_header_only(cppoptlib  PREFIX "include" DEPENDS eigen)
@project_name@_header_only(nanoflann  PREFIX "include")
@project_name@_header_only(pcg        PREFIX "include")
@project_name@_header_only(simple_svg PREFIX "include")
@project_name@_header_only(nanosvg    PREFIX "src")

################################################################################
# Custom import functions
################################################################################

function(@project_name@_import_filesystem)
    if(NOT TARGET std::filesystem)
        find_package(Filesystem COMPONENTS Final Experimental)
        if(NOT Filesystem_FOUND)
            @project_name@_import(ghc_filesystem)
            add_library(std::filesystem ALIAS ghc_filesystem)
        endif()
    endif()
endfunction()

function(@project_name@_import_json)
    option(JSON_BuildTests      "Build the unit tests when BUILD_TESTING is enabled." OFF)
    option(JSON_MultipleHeaders "Use non-amalgamated version of the library."         ON)
    @project_name@_import_default(json)
endfunction()

function(@project_name@_import_libigl)
    @project_name@_import(eigen)
    if(NOT TARGET igl::core)
        option(LIBIGL_BUILD_TESTS            "Build libigl unit test"       OFF)
        option(LIBIGL_BUILD_TUTORIALS        "Build libigl tutorial"        OFF)
        option(LIBIGL_BUILD_PYTHON           "Build libigl python bindings" OFF)
        option(LIBIGL_EXPORT_TARGETS         "Export libigl CMake targets"  OFF)
        option(LIBIGL_USE_STATIC_LIBRARY     "Use libigl as static library" OFF)
        option(LIBIGL_WITH_COMISO            "Use CoMiso"                   OFF)
        option(LIBIGL_WITH_EMBREE            "Use Embree"                   OFF)
        option(LIBIGL_WITH_OPENGL            "Use OpenGL"                   ON)
        option(LIBIGL_WITH_OPENGL_GLFW       "Use GLFW"                     ON)
        option(LIBIGL_WITH_OPENGL_GLFW_IMGUI "Use ImGui"                    ON)
        option(LIBIGL_WITH_PNG               "Use PNG"                      ON)
        option(LIBIGL_WITH_TETGEN            "Use Tetgen"                   OFF)
        option(LIBIGL_WITH_TRIANGLE          "Use Triangle"                 OFF)
        option(LIBIGL_WITH_PREDICATES        "Use exact predicates"         OFF)
        option(LIBIGL_WITH_XML               "Use XML"                      OFF)

        # Download libigl
        @project_name@_fetch(libigl)
        FetchContent_GetProperties(libigl)

        # Import libigl targets
        list(APPEND CMAKE_MODULE_PATH "${libigl_SOURCE_DIR}/cmake")
        include(libigl)
    endif()
endfunction()

function(@project_name@_import_spdlog)
    @project_name@_import(fmt)
    option(SPDLOG_FMT_EXTERNAL "" ON)
    @project_name@_import_default(spdlog)
endfunction()

function(@project_name@_import_tbb)
    if(NOT TARGET tbb::tbb)
        # Download tbb
        @project_name@_fetch(tbb)
        FetchContent_GetProperties(tbb)

        # Create tbb:tbb target
        set(TBB_BUILD_STATIC          ON  CACHE BOOL " " FORCE)
        set(TBB_BUILD_SHARED          OFF CACHE BOOL " " FORCE)
        set(TBB_BUILD_TBBMALLOC       OFF CACHE BOOL " " FORCE)
        set(TBB_BUILD_TBBMALLOC_PROXY OFF CACHE BOOL " " FORCE)
        set(TBB_BUILD_TESTS           OFF CACHE BOOL " " FORCE)
        set(TBB_NO_DATE               ON  CACHE BOOL " " FORCE)

        add_subdirectory(${tbb_SOURCE_DIR} ${tbb_BINARY_DIR})
        set_target_properties(tbb_static PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${tbb_SOURCE_DIR}/include"
        )
        if(NOT MSVC)
            set_target_properties(tbb_static PROPERTIES
                COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-missing-field-initializers -Wno-unused-parameter -Wno-keyword-macro"
            )
            set_target_properties(tbb_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
        endif()
        add_library(tbb::tbb ALIAS tbb_static)
    endif()
endfunction()

function(@project_name@_import_tinyfiledialogs)
    if(NOT TARGET tinyfiledialogs::tinyfiledialogs)
        # Download tinyfiledialogs
        @project_name@_fetch(tinyfiledialogs)
        FetchContent_GetProperties(tinyfiledialogs)

        # Create tinyfiledialogs target
        add_library(tinyfiledialogs ${tinyfiledialogs_SOURCE_DIR}/tinyfiledialogs.c)
        add_library(tinyfiledialogs::tinyfiledialogs ALIAS tinyfiledialogs)
        target_include_directories(tinyfiledialogs SYSTEM INTERFACE ${tinyfiledialogs_SOURCE_DIR})
        set_target_properties(tinyfiledialogs PROPERTIES POSITION_INDEPENDENT_CODE ON)
    endif()
endfunction()

function(@project_name@_import_windingnumber)
    @project_name@_import(tbb)
    if(NOT TARGET windingnumber::windingnumber)
        # Download windingnumber
        @project_name@_fetch(windingnumber)
        FetchContent_GetProperties(windingnumber)

        # Create windingnumber target
        add_library(windingnumber
            ${windingnumber_SOURCE_DIR}/UT_Array.cpp
            ${windingnumber_SOURCE_DIR}/UT_SolidAngle.cpp
            ${windingnumber_SOURCE_DIR}/SYS_Math.h
            ${windingnumber_SOURCE_DIR}/SYS_Types.h
            ${windingnumber_SOURCE_DIR}/UT_Array.h
            ${windingnumber_SOURCE_DIR}/UT_ArrayImpl.h
            ${windingnumber_SOURCE_DIR}/UT_BVH.h
            ${windingnumber_SOURCE_DIR}/UT_BVHImpl.h
            ${windingnumber_SOURCE_DIR}/UT_FixedVector.h
            ${windingnumber_SOURCE_DIR}/UT_ParallelUtil.h
            ${windingnumber_SOURCE_DIR}/UT_SmallArray.h
            ${windingnumber_SOURCE_DIR}/UT_SolidAngle.h
            ${windingnumber_SOURCE_DIR}/VM_SIMD.h
            ${windingnumber_SOURCE_DIR}/VM_SSEFunc.h
        )

        target_include_directories(windingnumber PUBLIC ${windingnumber_SOURCE_DIR})
        target_link_libraries(windingnumber PUBLIC tbb::tbb)
        add_library(windingnumber::windingnumber ALIAS windingnumber)
    endif()
endfunction()

################################################################################
