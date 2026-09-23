{
  # Claude Code-specific assets (cross-tool skills live in modules/agent-skills).
  # Same out-of-store symlink idiom: edits in ~/.claude/agents land in this repo.
  # settings.json stays unmanaged because Claude Code rewrites it itself
  # (permission approvals etc). Hooks are therefore registered by hand:
  #   jq -s '.[0] * {hooks: .[1]}' ~/.claude/settings.json hooks/hooks.json
  # The hook scripts themselves are managed here and symlinked into ~/.claude/hooks.
  flake.modules.homeManager.claude-code =
    { config, ... }:
    let
      assetsRoot = "${config.homeConfig.nixConfigPath}/modules/claude-code";
      link = path: config.lib.file.mkOutOfStoreSymlink "${assetsRoot}/${path}";
    in
    {
      home.file = {
        ".claude/agents/cody-coding-intern.md".source = link "agents/cody-coding-intern.md";
        ".claude/hooks/vigil".source = link "hooks/vigil";
      };
    };
}
