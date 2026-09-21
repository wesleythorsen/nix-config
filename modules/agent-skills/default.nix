{
  # Cross-tool Agent Skills (https://agentskills.io): every sibling directory
  # of this file is one skill (SKILL.md + assets). Skills are deployed as
  # out-of-store symlinks into BOTH discovery locations:
  #   ~/.agents/skills/<name>  - the open-standard shared dir (any agent)
  #   ~/.claude/skills/<name>  - Claude Code's personal skills dir
  # Out-of-store means agents can edit skills in place and the change lands
  # directly in this repo (same idiom as the vscode/charm settings symlinks).
  # Adding a skill = adding a directory here; no nix changes needed.
  flake.modules.homeManager.agent-skills =
    { config, lib, ... }:
    let
      skillNames = lib.attrNames (
        lib.filterAttrs (_name: type: type == "directory") (builtins.readDir ./.)
      );

      skillsRoot = "${config.homeConfig.nixConfigPath}/modules/agent-skills";

      linksFor =
        prefix:
        lib.listToAttrs (
          map (name: {
            name = "${prefix}/${name}";
            value.source = config.lib.file.mkOutOfStoreSymlink "${skillsRoot}/${name}";
          }) skillNames
        );
    in
    {
      home.file = linksFor ".agents/skills" // linksFor ".claude/skills";
    };
}
