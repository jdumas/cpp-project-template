///////////////////////////////////////////////////////////////////////////////
#include "filedialogs.h"
#include <tinyfiledialogs.h>
#include <memory>
#include <vector>
#include <iostream>
////////////////////////////////////////////////////////////////////////////////

namespace gazebo {

// -----------------------------------------------------------------------------

std::string open_filename(const std::string &defaultPath,
                          const std::vector<std::string> &filters,
                          const std::string &desc)
{
    int n = static_cast<int>(filters.size());
    std::vector<char const *> filterPatterns(n);
    for (int i = 0; i < n; ++i) {
        filterPatterns[i] = filters[i].c_str();
    }
    char const *select = tinyfd_openFileDialog("Open File", defaultPath.c_str(), n,
                                               filterPatterns.data(), desc.c_str(), 0);
    if (select == nullptr) {
        return "";
    }
    else {
        return std::string(select);
    }
}

// -----------------------------------------------------------------------------

std::string save_filename(const std::string &defaultPath,
                          const std::vector<std::string> &filters,
                          const std::string &desc)
{
    int n = static_cast<int>(filters.size());
    std::vector<char const *> filterPatterns(n);
    for (int i = 0; i < n; ++i) {
        filterPatterns[i] = filters[i].c_str();
    }
    char const *select = tinyfd_saveFileDialog("Save File", defaultPath.c_str(), n,
                                               filterPatterns.data(), desc.c_str());
    if (select == nullptr) {
        return "";
    }
    else {
        return std::string(select);
    }
}

// -----------------------------------------------------------------------------

std::string open_folder(const std::string &defaultPath)
{
    char const *select = tinyfd_selectFolderDialog("Open Folder", defaultPath.c_str());
    if (select == nullptr) {
        return "";
    }
    else {
        return std::string(select);
    }
}

// -----------------------------------------------------------------------------

}  // namespace gazebo
