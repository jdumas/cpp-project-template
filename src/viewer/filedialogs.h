#pragma once

////////////////////////////////////////////////////////////////////////////////
#include <string>
#include <vector>
////////////////////////////////////////////////////////////////////////////////

namespace gazebo {

// -----------------------------------------------------------------------------

std::string open_filename(const std::string &defaultPath = "./.*",
                          const std::vector<std::string> &filters = {},
                          const std::string &desc = "");

std::string save_filename(const std::string &defaultPath = "./.*",
                          const std::vector<std::string> &filters = {},
                          const std::string &desc = "");

std::string open_folder(const std::string &defaultPath = ".");

// -----------------------------------------------------------------------------

}  // namespace gazebo
