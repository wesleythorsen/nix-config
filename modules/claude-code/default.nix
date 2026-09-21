{
  # Claude Code-specific assets (cross-tool skills live in modules/agent-skills).
  # Same out-of-store symlink idiom: edits in ~/.claude/agents land in this repo.
  # Future home for declaratively managed settings/hooks/commands if wanted;
  # settings.json stays unmanaged for now because Claude Code rewrites it
  # itself (permission approvals etc).
  flake.modules.homeManager.claude-code =
    { config, ... }:
    let
      assetsRoot = "${config.homeConfig.nixConfigPath}/modules/claude-code";
    in
    {
      home.file.".claude/agents/cody-coding-intern.md".source =
        config.lib.file.mkOutOfStoreSymlink "${assetsRoot}/agents/cody-coding-intern.md";
    };
}
