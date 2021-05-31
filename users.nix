{ config, lib, ... }: {
  users.mutableUsers = false;

  # vm installation, good luck.
  users.users.root.initialHashedPassword = "$6$0OpNUbBtQ$foMkIpnmY0D4TOisFc/pEy0TKJ5KI0AAEe6Bex28TODVDzrgfF121ZV/Tvi3lz1aq80679aX1Vw5GvseKXeU.1";
  users.users.mark.initialHashedPassword = "$6$.1G.0Q0KV$iXQK0dk3pDQh6zGnw9Ob2rgfE8Dfu.SZFfFbLWzWtdPZl7ew/lUlS1E75QC.guzPZueTg6rMn2u6lRKEAQFue0";

  users.users.mark.extraGroups = [ "docker" ];

  home-manager.useGlobalPkgs = true;

  home-manager.users.mark = let
    hasDesktop = config.programs.sway.enable;
  in { pkgs, config, ... }: {
    programs.home-manager.enable = true;
    programs.command-not-found.enable = true;

    home.packages = with pkgs;
      [ ripgrep fd
        zip unzip pigz zstd xz
        htop strace lsof ncdu file

        weechat
      ] ++ lib.optionals hasDesktop [
        hack-font fira-code gnome3.adwaita-icon-theme 
        (pkgs.callPackage ./pkgs/chromium-ozone-wrapper.nix { chromium = pkgs.ungoogled-chromium; })
      ];

    fonts.fontconfig.enable = lib.mkForce hasDesktop; # TODO: not sure why this needs mkForce

    programs.bash = {
      enable = true;
      shellAliases = {
        "ga" = "git add";
        "gs" = "git status";
	"gd" = "git diff";
	"gp" = "git push";
        "gl" = "git pull";
        "ssh" = "env TERM=xterm-256color ssh";
      };
    };

    programs.zsh = {
      enable = true;
    };

    programs.exa = {
      enable = true;
      enableAliases = true;
    };

    programs.git = {
      enable = true;
      userName = "Mark Vainomaa";
      userEmail = "mikroskeem@mikroskeem.eu";

      package = pkgs.gitFull;

      delta.enable = true;
      lfs.enable = true;

      signing = {
        signByDefault = true;
	key = "CC28AE6A4AB07CF5";
      };

      extraConfig.init.defaultBranch = "master";
      extraConfig.pull.ff = "only";
    };

    programs.gpg = {
      enable = true;
    };

    programs.direnv = {
      enable = true;
      enableNixDirenvIntegration = true;
    };

    programs.fzf.enable = true;
    programs.jq.enable = true;

    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      extraConfig = ''
        set-option -sg escape-time 10
        # neovim RGB
        set-option -sa terminal-overrides ',XXX:RGB'
      '';
    };

    programs.neovim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-nix
      ];
    };

    programs.emacs = {
      enable = true;
      package = if hasDesktop then pkgs.emacsGcc else (pkgs.emacsGcc.override {
        withX = false;
        withGTK2 = false;
        withGTK3 = false;
      }).overrideAttrs (oa: { name = "${oa.name}-nox"; });
      extraPackages = epkgs: [
        epkgs.vterm
      ];
    };

    services.gpg-agent = {
      enable = true;
      defaultCacheTtl = 7200;
    };
    services.gnome-keyring.enable = true;

    gtk = lib.optionalAttrs hasDesktop {
      enable = true;
      font = {
        package = pkgs.noto-fonts;
	name = "Noto Sans";
	size = 12;
      };

      iconTheme = {
        package = pkgs.gnome3.adwaita-icon-theme;
        name = "Adwaita-Dark";
      };

      theme = {
        name = "Adwaita-Dark";
      };
    };

    programs.firefox = lib.optionalAttrs hasDesktop {
      enable = true;
    };

    ## hacks
    # no better way of doing this?
    home.file = lib.optionalAttrs hasDesktop {
      ".icons/default".source = "${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita";
    };
  };
}
