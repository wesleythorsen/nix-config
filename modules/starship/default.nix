{
  ...
}:

{
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;

      git_branch = {
        symbol = "🌱 ";
        format = "[$symbol$branch(:$remote_branch)]($style) ";
        style = "bold cyan";
        always_show_remote = false;
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "bold yellow";
        stashed = "📦 \${count}";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        up_to_date = "";
        diverged = "⇡\${ahead_count}⇣\${behind_count}";
        conflicted = "⚠️ \${count}";
        deleted = "🗑️ \${count}";
        renamed = "🔀 \${count}";
        modified = "📝 \${count}";
        staged = "✅ \${count}";
        untracked = "❓ \${count}";
      };
    };
  };
}
