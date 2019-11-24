# C++ Project Template

[![Build Status](https://dev.azure.com/jdumas-github/cpp-project-template/_apis/build/status/jdumas.cpp-project-template?branchName=master)](https://dev.azure.com/jdumas-github/cpp-project-template/_build/latest?definitionId=1&branchName=master)

Template repository for C++ projects using CMake, libigl, etc.

### Available libraries

| FetchContent name | Target name | Url |
| --- | --- | --- |
| `catch2`           | `Catch2::Catch2`                   | [Catch2](https://github.com/catchorg/Catch2.git)                         |
| `cli11`            | `CLI11::CLI11`                     | [CLI11](https://github.com/CLIUtils/CLI11.git)                           |
| `cppoptlib`        | `cppoptlib::cppoptlib`             | [CppNumericalSolvers](https://github.com/PatWie/CppNumericalSolvers.git) |
| `eigen`            | `Eigen3::Eigen`                    | [Eigen](https://github.com/eigenteam/eigen-git-mirror)                   |
| `ghc_filesystem`   | `ghc::filesystem`                  | [Filesystem](https://github.com/gulrak/filesystem.git)                   |
| `fmt`              | `fmt::fmt`                         | [{fmt}](https://github.com/fmtlib/fmt)                                   |
| `json`             | `nlohmann_json::nlohmann_json`     | [JSON](https://github.com/nlohmann/json)                                 |
| `libigl`           | `igl::core`, ...                   | [libigl](https://github.com/libigl/libigl.git)                           |
| `nanoflann`        | `nanoflann::nanoflann`             | [nanoflann](https://github.com/jlblancoc/nanoflann)                      |
| `pcg`              | `pcg::pcg`                         | [PCG](https://github.com/imneme/pcg-cpp.git)                             |
| `simple_svg`       | `simple_svg::simple_svg`           | [simple-svg](https://github.com/adishavit/simple-svg.git)                |
| `spdlog`           | `spdlog::spdlog`                   | [spdlog](https://github.com/gabime/spdlog)                               |
| `tbb`              | `tbb::tbb`                         | [Threading Building Blocks](https://github.com/wjakob/tbb.git)           |
| `tinyfiledialogs`  | `tinyfiledialogs::tinyfiledialogs` | [tiny file dialogs](https://sourceforge.net/projects/tinyfiledialogs/)   |
| `windingnumber`    | `windingnumber::windingnumber`     | [WindingNumber](https://github.com/sideeffects/WindingNumber)            |

### Continuous Integration

It is a good idea to ensure that your code always builds, and does so on all platforms (Windows, Linux, macOS). You do not want to push code that might leave your coworkers unhappy because they cannot build the project anymore. To that end, we use continuous integration via the following services:

- [Travis CI](https://docs.travis-ci.com/user/tutorial/)
- [Azure Pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github)

Both support Windows, Linux and macOS. Feel free to adapt existing scripts to your needs. Travis can be used for private projects if you have an education account.

<!-- TODO: Add continuous integration with Github Actions -->

### Notes

##### Libigl

By default, we use libigl in header-only mode, single building in static mode takes a long time. However, as your project grows, you might want to switch the CMake option `LIBIGL_USE_STATIC_LIBRARY` to `ON` to accelerate incremental builds (this is especially useful in combination with a caching compiler such as `ccache`).

##### Filesystem

With C++17, in theory the `<filesystem>` header from the Standard Template Library provides a cross-platform filesystem library. Unfortunately, compiler support is still lacking, in particular on macOS -- you need at least Xcode 11 and macOS 10.15, which may not be supported by our CI platforms yet. To that end, we define an alias target `std::filesystem`. This target will add the necessary linking flags if `<filesystem>` or `<experimental/filesystem>` are supported on your system. If not, it will download [ghc::filesystem](https://github.com/gulrak/filesystem) and use that as an alias. Automatic namespace forwarding is implemented in [filesystem.h](https://github.com/jdumas/cpp-project-template/blob/master/src/gazebo/filesystem.h) so you can use it directly.

### Useful links

- [An Introduction to Modern CMake](https://cliutils.gitlab.io/modern-cmake/)
