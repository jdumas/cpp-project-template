#pragma once

#if __has_include(<filesystem>)
#include <filesystem>
#elif __has_include(<experimental/filesystem>)
#include <experimental/filesystem>
#else
#include <ghc/filesystem.hpp>
#endif

namespace gazebo {

#if __has_include(<filesystem>)
namespace fs = std::filesystem;
#elif __has_include(<experimental/filesystem>)
namespace fs = std::experimental::filesystem;
#else
namespace fs = ghc::filesystem;
#endif

}  // namespace gazebo
