{ config, pkgs, lib, intelPkgs, ... }:
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
          htop
          coreutils
          fd
          file
          findutils
          lsof
          moreutils
          ncdu
          pigz
          ripgrep
          gnused
          tig
          unzip
          wakatime
          xz
          zip
          zstd
          openssh
          nixpkgs-fmt
          weechat

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

          # Games
          quakespasm
        ] ++ lib.optionals pkgs.stdenv.isDarwin [
          lima

          (pkgs.stdenv.mkDerivation rec {
            name = "docker-app-shell-completions";
            phases = [ "installPhase" ];

            app = "/Applications/Docker.app/Contents/Resources/etc";
            installPhase = ''
              runHook preInstall

              # NOTE: cannot use 'installShellCompletion', as it'll copy the contents
              zshd=$out/share/zsh/site-functions
              bashd=$out/share/bash-completion/completions
              fishd=$out/share/fish/vendor_completions.d

              mkdir -p $zshd/
              ln -s ${app}/docker-compose.zsh-completion  $zshd/_docker-compose
              ln -s ${app}/docker.zsh-completion          $zshd/_docker

              mkdir -p $bashd/
              ln -s ${app}/docker-compose.bash-completion $bashd/docker-compose
              ln -s ${app}/docker.bash-completion         $bashd/docker

              mkdir -p $fishd/
              ln -s ${app}/docker-compose.fish-completion $fishd/docker-compose.fish
              ln -s ${app}/docker.fish-completion         $fishd/docker.fish

              runHook postInstall
            '';
          })
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
      vim-nix
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
}
