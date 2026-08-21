# {
#   config,
#   pkgs,
#   ...
# }: 

# {
#   home = {
#     packages = with pkgs; [
#       podman
#       podman-desktop
#     ];

#     shellAliases = {
#       docker = "podman";
#     };
#   };
# }
