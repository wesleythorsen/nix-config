{
  pkgs,
  ...
}:

let
  toLua = str: "lua << EOF\n${str}\nEOF\n";
  toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";

  nvimConfig = pkgs.stdenv.mkDerivation {
    name = "nvim-config";
    src = ./config;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
in
{
  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    withNodeJs = false; # temp disable, nodejs 20.19 issue

    # search all vimPlugins: nix-env -f '<nixpkgs>' -qaP -A vimPlugins
    plugins = with pkgs.vimPlugins; [
      vim-visual-multi

      {
        plugin = comment-nvim;
        config = toLua ''require("Comment").setup()'';
      }

      {
        plugin = nvim-lspconfig;
        config = toLuaFile ./plugins/lsp.lua;
      }

      cmp-nvim-lsp-signature-help

      {
        plugin = onedark-nvim;
        config = toLuaFile ./plugins/onedark.lua;
      }

      {
        plugin = telescope-nvim;
        config = toLuaFile ./plugins/telescope.lua;
      }

      # telescope-fzf-native provides the sorter; it is loaded *from telescope.lua*
      # so no separate config block is needed here. Just ensure it’s built.
      telescope-fzf-native-nvim

      {
        plugin = vim-fugitive;
        config = toLuaFile ./plugins/fugitive.lua;
      }

      {
        plugin = undotree;
        config = toLuaFile ./plugins/undotree.lua;
      }

      # Status line with git info and file stats
      {
        plugin = lualine-nvim;
        config = toLuaFile ./plugins/lualine.lua;
      }

      # Git signs in gutter
      {
        plugin = gitsigns-nvim;
        config = toLuaFile ./plugins/gitsigns.lua;
      }

      # Better syntax highlighting
      {
        plugin = nvim-treesitter.withAllGrammars;
        config = toLuaFile ./plugins/treesitter.lua;
      }

      # Icons for file explorer and status line
      nvim-web-devicons

      # Formatting with ESLint and Prettier
      {
        plugin = conform-nvim;
        config = toLuaFile ./plugins/conform.lua;
      }

      # completion engine + sources
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip

      {
        plugin = nvim-cmp;
        config = toLuaFile ./plugins/completion.lua;
      }

      {
        plugin = snacks-nvim;
        config = toLuaFile ./plugins/snacks.lua;
      }

      {
        plugin = render-markdown-nvim;
        config = toLuaFile ./plugins/render-markdown.lua;
      }
    ];

    extraLuaConfig = ''
      vim.g.mapleader = " "

      -- Make the Lua config directory discoverable by `require()`
      package.path = package.path .. ";" .. "${nvimConfig}/?.lua"

      require("init")
    '';

    extraPackages = with pkgs; [
      # Lua LSP
      lua-language-server

      # TypeScript/JS LSP
      nodejs_20
      nodePackages.typescript
      nodePackages.typescript-language-server

      # Nix LSP
      nixd

      # Formatting tools
      nodePackages.prettier
      nodePackages.eslint
      stylua # Lua formatter
      nixfmt # Nix formatter
    ];

  };
}
