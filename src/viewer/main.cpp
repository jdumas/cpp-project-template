////////////////////////////////////////////////////////////////////////////////
#include <@project_name@/filesystem.h>

#include <igl/read_triangle_mesh.h>
#include <@project_name@/disable_warnings.h>
#include <CLI/CLI.hpp>
#include <@project_name@/enable_warnings.h>

#include <vector>
////////////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[])
{
    // Default arguments
    struct {
        std::string input = "input.obj";
    } args;

    // Parse arguments
    CLI::App app{"viewer"};
    app.add_option("input,-i,--input", args.input, "Input mesh.")
        ->required()
        ->check(CLI::ExistingFile);
    try {
        app.parse(argc, argv);
    }
    catch (const CLI::ParseError &e) {
        return app.exit(e);
    }

    // Load mesh
    Eigen::MatrixXd V;
    Eigen::MatrixXi F;
    igl::read_triangle_mesh(args.input, V, F);

    return 0;
}
