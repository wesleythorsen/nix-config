{ config, inputs, ... }:
{
  configurations.nixos.w530 = {
    system = "x86_64-linux";
    primaryUser = "wes";

    module =
      { pkgs, ... }:
      let
        toLua = str: "lua << EOF\n${str}\nEOF\n";
      in
      {
        imports = [
          ./_hardware-configuration.nix
          config.flake.modules.nixos.base
        ];

        networking.hostName = "w530";

        systemd = {
          defaultUnit = "multi-user.target";

          services.fetch-tailscale-key = {
            description = "Fetch Tailscale auth key from Mac (temporary bootstrap)";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            requiredBy = [ "tailscaled.service" ];
            before = [ "tailscaled.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "fetch-tailscale-key" ''
                set -euo pipefail
                install -d -m 700 /run/keys
                ${pkgs.curl}/bin/curl -fsS "http://crackbookpro.local/tailscale_key" \
                  -o /run/keys/tailscale_key
                chmod 600 /run/keys/tailscale_key
              '';
            };
            wantedBy = [ "multi-user.target" ];
            unitConfig.ConditionPathExists = "!/run/keys/tailscale_key";
          };
        };

        security.sudo = {
          enable = true;
          wheelNeedsPassword = false; # FIXME: not safe
        };

        users.users = {
          wes = {
            isNormalUser = true;
            extraGroups = [
              # FIXME: move unnecessary perms to dev-shell
              "wheel"
              "docker"
              "kvm"
              "libvirtd"
              "networkmanager"
              "systemd-journal"
              "video"
            ];
            shell = pkgs.zsh;
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2Mwvc/ia3Gtu0RQ6WmkoPVI1E+EKAd1akze0SJqA8c wes@crackbookpro"
            ];
          };
        };

        environment = {
          systemPackages = with pkgs; [
            curl
            jq
            unzip
            wget
          ];
        };

        services = {
          iperf3.enable = true;

          tailscale = {
            enable = true;
            openFirewall = true;
            authKeyFile = "/run/keys/tailscale_key";
            useRoutingFeatures = "server";
            extraUpFlags = [
              "--ssh"
            ];
            extraSetFlags = [
              "--advertise-exit-node"
            ];
          };
        };

        programs = {
          git.enable = true;

          tmux = {
            enable = true;
            keyMode = "vi";
            terminal = "screen-256color";
            shortcut = "Space";
            baseIndex = 1;
            newSession = true;
            escapeTime = 1000;
            extraConfigBeforePlugins = ''
              set -ga terminal-overrides ",*256col*:Tc"
              set -g set-clipboard on
              set -g mouse on
              set -g status-interval 2
              set -g detach-on-destroy off
              set -g renumber-windows on

              # copy-mode-vi tweaks (no mac pbcopy here; rely on OSC52)
              bind -T copy-mode-vi v send -X begin-selection
              bind -T copy-mode-vi y send -X copy-selection-and-cancel
              unbind -T copy-mode-vi MouseDragEnd1Pane
            '';
          };

          neovim = {
            enable = true;
            defaultEditor = true;
            configure = {
              customLuaRC = toLua ''
                vim.g.mapleader = " "
                require("init")
              '';
            };
            runtime = {
              "lua/settings.lua".text = builtins.readFile ../../nvim/config/settings.lua;
              "lua/keymaps.lua".text = builtins.readFile ../../nvim/config/keymaps.lua;
              "lua/init.lua".text = ''
                require("settings")
                require("keymaps")
              '';
            };
          };
        };

        specialisation.dev-shell.configuration = {
          security.sudo.extraRules = [
            # FIXME: not safe
            {
              users = [ "wes" ];
              commands = [
                {
                  command = "ALL";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];

          environment = {
            systemPackages = with pkgs; [
              btop
              cmake
              ethtool
              eza
              fd
              lsof
              lua-language-server
              nftables
              nixd
              nmap
              # nodejs_24
              # nodePackages.typescript
              # nodePackages.typescript-language-server
              pciutils
              ripgrep
              rsync
              strace
              usbutils
              zip
            ];

            # REVIEW: creates immutable copy of the source config (this repo)
            etc."nix-config".source = inputs.self.outPath;
          };

          programs = {
            bat.enable = true;
            iftop.enable = true;
            iotop.enable = true;
            mtr.enable = true;
            nexttrace.enable = true;

            zsh = {
              enable = true;
              enableBashCompletion = true;
              enableCompletion = true;
              enableGlobalCompInit = true;
              enableLsColors = true;
              autosuggestions = {
                enable = true;
                async = true;
              };
              syntaxHighlighting = {
                enable = true;
              };
              ohMyZsh = {
                enable = true;
                theme = "minimal";
                # TODO: setup to match home-manager
                # plugins = [
                #   "git-open"
                #   "deno"
                # ];
                # custom = [
                #   "${config.home.homeDirectory}/.oh-my-zsh-custom"
                # ];
              };
              shellAliases = {
                c = "clear";
                l = "eza -la";
                lt = "eza -laT -I=.git";
              };
            };

            git = {
              enable = true;
              prompt.enable = true;
              config = {
                user = {
                  name = "wesleythorsen";
                  email = "wesley.thorsen@gmail.com";
                  signingkey = "FAE484F021AE49E5";
                };
                alias = {
                  co = "checkout";
                  logl = "log --oneline --graph --all";
                  pf = "push --force-with-lease";
                };
                core = {
                  editor = "nvim";
                  repositoryformatversion = 0;
                  filemode = true;
                  bare = false;
                  logallrefupdates = true;
                  ignorecase = false;
                  precomposeunicode = true;
                };
                credential = {
                  # TODO: confirm this works
                  helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
                  "https://github.com/".useHttpPath = true;
                };
                push = {
                  autoSetupRemote = true;
                };
              };
            };

            tmux = {
              enable = true;
              plugins = with pkgs.tmuxPlugins; [
                tmux-powerline
                resurrect
                continuum
              ];
              extraConfig = ''
                # load the plugin
                # source-file #{?TMUX_PLUGIN_MANAGER_PATH,,""}${pkgs.tmuxPlugins.tmux-powerline}/share/tmux-plugins/powerline/main.tmux

                # (optional) if you want to override its defaults, copy its example and source your own:
                # run-shell "cp -n ${pkgs.tmuxPlugins.tmux-powerline}/share/tmux-plugins/powerline/powerline.conf.example ~/.tmux-powerline.conf"
                # source-file ~/.tmux-powerline.conf
                # source-file ${pkgs.tmuxPlugins.tmux-powerline}/share/tmux-powerline/powerline.conf

                set -g @resurrect-capture-pane-contents 'on'
                set -g @continuum-restore 'on'
                set -g status-right '#(${pkgs.gitmux}/bin/gitmux "#{pane_current_path}")'
              '';
            };

            neovim = {
              enable = true;
              configure = {
                packages.myVimPackage = with pkgs.vimPlugins; {
                  start = [
                    nvim-lspconfig
                    nvim-treesitter.withAllGrammars
                    telescope-nvim
                    telescope-fzf-native-nvim
                    nvim-cmp
                    cmp-nvim-lsp
                    cmp-buffer
                    cmp-path
                    luasnip
                    cmp_luasnip
                    vim-fugitive
                    undotree
                    gitsigns-nvim
                    lualine-nvim
                    nvim-web-devicons
                    snacks-nvim
                  ];
                  opt = [ ];
                };
              };
              runtime = {
                "lua/treesitter.lua".text = builtins.readFile ../../nvim/plugins/treesitter.lua;
                "lua/telescope.lua".text = builtins.readFile ../../nvim/plugins/telescope.lua;
                "lua/completion.lua".text = builtins.readFile ../../nvim/plugins/completion.lua;
                "lua/lsp.lua".text = builtins.readFile ../../nvim/plugins/lsp.lua;
                "lua/snacks.lua".text = builtins.readFile ../../nvim/plugins/snacks.lua;
                "lua/init.lua".text = ''
                  require("settings")
                  require("keymaps")
                  require("treesitter")
                  require("telescope")
                  require("completion")
                  require("lsp")
                  require("snacks")
                  -- Yazi quick-open (uses tmux if present, else terminal)
                  vim.keymap.set("n","<leader>yy", function()
                    if os.getenv("TMUX") then
                      vim.fn.system('tmux split-window -v "yazi"')
                    else
                      vim.cmd("terminal yazi")
                    end
                  end, { desc = "Yazi in split/terminal" })
                '';
              };
            };

            yazi = {
              enable = true;
            };

            fzf = {
              fuzzyCompletion = true;
              keybindings = true;
            };
          };
        };
      };
  };
}
