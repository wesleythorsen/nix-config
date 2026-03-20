# {
#   config,
#   lib,
#   pkgs,
#   ...
# }:

# let
#   cfg = config.programs.ts-cli;

#   tsCliPkg = pkgs.python3Packages.buildPythonApplication rec {
#     pname = "tetrascience-cli";
#     version = "1.7.1";

#     # sdist: tetrascience_cli-1.7.1.tar.gz
#     src = pkgs.python3Packages.fetchPypi {
#       inherit pname version;
#       hash = "sha256-k4vT4bzcIdDnhebZGKj+HcKz2cInWwfQnv/9msuQtbY=";
#     };

#     # The project’s docs indicate it’s Poetry-based; using PEP-517 build.
#     pyproject = true;

#     # If protocol-validation extra is needed, ts-cli expects npm present *at install time*.
#     nativeBuildInputs = lib.optionals cfg.withProtocolValidation [
#       pkgs.nodejs
#     ];

#     # NOTE: PyPI doesn’t expose dependency metadata in the rendered HTML page.
#     # This list covers the common runtime deps for a CLI like this.
#     # If you hit a runtime "No module named X", add the missing package here.
#     propagatedBuildInputs = with pkgs.python3Packages; [
#       requests
#       pyyaml
#       rich
#       packaging
#       jsonschema
#       platformdirs
#     ];

#     doCheck = false;

#     meta = with lib; {
#       description = "TetraScience CLI (ts-cli) from the tetrascience-cli PyPI package";
#       homepage = "https://pypi.org/project/tetrascience-cli/";
#       license = licenses.asl20;
#       mainProgram = "ts-cli";
#       platforms = platforms.unix;
#     };
#   };
# in
# {
#   options.programs.ts-cli = {
#     enable = lib.mkEnableOption "Install TetraScience ts-cli";

#     withProtocolValidation = lib.mkOption {
#       type = lib.types.bool;
#       default = false;
#       description = ''
#         Install-time support for ts-cli protocol validation extra.
#         Upstream notes npm is needed at install time for this mode.
#       '';
#     };
#   };

#   config = lib.mkIf cfg.enable {
#     home.packages = [ tsCliPkg ];
#   };
# }
