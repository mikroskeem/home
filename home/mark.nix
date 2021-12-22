{ config
, pkgs
, lib
, intelPkgs
, hasDesktop
, ...
}:
let
  packageWorkarounds = {
    aarch64-darwin = {
      weechat = onlyIntel "weechat";
    };
  };

  usePackageWorkaround = p:
    let
      replacement = lib.attrByPath [ pkgs.system (lib.head (lib.splitVersion p.name)) ] null packageWorkarounds;
      final = if (replacement != null) then lib.warn "using Intel package: ${replacement.name}" replacement else p;
    in
    final;

  onlyIntel = n: if (pkgs.stdenv.isDarwin && intelPkgs != null) then intelPkgs.${n} else null;

in
rec {
  programs.home-manager.enable = true;
  programs.command-not-found.enable = true;

  home.packages =
    let
      chosen = with pkgs;
        [
          coreutils
          fd
          file
          findutils
          gh
          gnused
          htop
          lima
          lsof
          moreutils
          ncdu
          nixpkgs-fmt
          openssh
          pigz
          pv
          ripgrep
          tig
          tree
          unzip
          wakatime
          weechat
          xz
          zip
          zstd

          (pkgs.writeShellScriptBin "wait-docker" (lib.optionalString pkgs.stdenv.isDarwin ''
            if ! pgrep -q "com.docker.virtualization"; then
              # TODO: still opens this shitty desktop UI
              open --hide --background -a Docker.app
            fi
          '' + ''
            while ! docker system info &>/dev/null; do sleep 1; done
            if [ -n "$*" ]; then
              exec "$@"
            fi
          ''))
        ] ++ lib.optionals pkgs.stdenv.isLinux [
          strace
        ] ++ lib.optionals pkgs.stdenv.isDarwin [
          (pkgs.callPackage ../pkgs/mac-docker-app-shell-completions.nix { })
        ] ++ lib.optionals hasDesktop [
          # Games
          quakespasm
        ] ++ lib.optionals (hasDesktop && pkgs.stdenv.isLinux) [
          hack-font
          fira-code
          gnome3.adwaita-icon-theme
          (pkgs.callPackage ../pkgs/chromium-ozone-wrapper.nix { chromium = pkgs.ungoogled-chromium; })

          alacritty
          ripcord
        ];
    in
    map usePackageWorkaround chosen;

  home.sessionVariables = lib.optionalAttrs config.programs.neovim.enable {
    "EDITOR" = "nvim";
    "VISUAL" = "nvim";
  };

  home.sessionPath = [
    "$HOME/bin"
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    "/usr/local/zfs/bin"
  ];

  gtk = lib.optionalAttrs (hasDesktop && pkgs.stdenv.isLinux) {
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

  # no better way of doing this?
  home.file = lib.optionalAttrs (hasDesktop && pkgs.stdenv.isLinux) {
    ".icons/default".source = "${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita";
  };

  fonts.fontconfig.enable = lib.mkForce hasDesktop; # TODO: not sure why this needs mkForce

  programs.zsh = {
    enable = true;
    shellAliases = {
      "ga" = "git add";
      "gs" = "git status";
      "gd" = "git diff";
      "gp" = "git push";
      "gl" = "git pull";
      "ssh" = "env TERM=xterm-256color ssh";
      "mkdir" = "mkdir -p";
    };

    initExtra = lib.optionalString pkgs.stdenv.isDarwin ''
      # $LANG is horribly broken on MacOS
      if [ -n "$INSIDE_EMACS" ]; then
        unset LANG
      fi
    '';
  };

  programs.bash = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      vim-nix
      vim-terraform
    ];
  };

  programs.bat.enable = true;

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

  services.gpg-agent = lib.optionalAttrs pkgs.stdenv.isLinux {
    enable = true;
    enableExtraSocket = true;
    enableSshSupport = true;
    #enableScDaemon = true;
    defaultCacheTtl = 7200;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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

  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [
      epkgs.magit
      epkgs.vterm
    ];
  };

  programs.firefox = lib.optionalAttrs pkgs.stdenv.isLinux {
    enable = true;
  };
}
