{ config
, pkgs
, lib
, intelPkgs
, hasDesktop
, ...
}:
rec {
  imports = [
    ./mark-macgpg.nix
  ];

  programs.home-manager.enable = true;
  programs.command-not-found.enable = true;

  home.stateVersion = "22.05";
  home.packages = with pkgs;
    [
      colima
      coreutils
      curl
      (docker-client.override {
        withBtrfs = false;
        withLvm = false;
        withSeccomp = false;
        withSystemd = false;
      })
      fd
      file
      findutils
      gh
      git-branchless
      git-trim
      gnused
      htop
      k3d
      kubernetes-helm
      kubectl
      lima
      lsof
      moreutils
      mosh
      ncdu
      nixpkgs-fmt
      openssh
      pigz
      procps
      pv
      ripgrep
      tig
      tree
      unzip
      vault
      wakatime
      xz
      zip
      zstd
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      strace
    ] ++ lib.optionals (hasDesktop && pkgs.stdenv.isLinux) [
      hack-font
      fira-code
      gnome3.adwaita-icon-theme
      (pkgs.callPackage ../pkgs/chromium-ozone-wrapper.nix { chromium = pkgs.ungoogled-chromium; })

      alacritty
      ripcord
    ];

  home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isDarwin
    {
      HOMEBREW_NO_ENV_HINTS = "1";
      HOMEBREW_NO_INSTALL_CLEANUP = "1";
    } // lib.optionalAttrs config.programs.neovim.enable
    {
      "EDITOR" = "nvim";
      "VISUAL" = "nvim";
    };

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.deno/bin"
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
      "gco" = "git checkout";
      "grh" = "git reset --hard HEAD";
      "ssh" = "env TERM=xterm-256color ssh";
      "issh" = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
      "mkdir" = "mkdir -p";
      "k" = "kubectl";
    };

    plugins = [
      {
        file = "powerlevel10k.zsh-theme";
        name = "powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
      }
      {
        file = "zsh-syntax-highlighting.zsh";
        name = "zsh-syntax-highlighting";
        src = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
      }
      {
        file = "zsh-autosuggestions.zsh";
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      }
    ];

    localVariables = {
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=8";
    };

    initExtraBeforeCompInit = ''
      bindkey -e

      # p10k instant prompt
      P10K_INSTANT_PROMPT="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"
      [[ ! -r "$P10K_INSTANT_PROMPT" ]] || source "$P10K_INSTANT_PROMPT"

      if [[ -f ~/.p10k.zsh ]]; then
        source ~/.p10k.zsh
      else
        source ${./p10k.zsh}
      fi
    '';

    initExtra = ''
      # Fix prompt swallowing output without a newline
      setopt prompt_cr prompt_percent prompt_sp

      # cd ... => cd ../..
      function __rationalise-dot () {
          local MATCH
          if [[ $LBUFFER =~ '(^|/| |      |'$'\n'''|\||;|&)\.\.$' ]]; then
              LBUFFER+='/..'
          else
              zle self-insert
          fi
      }

      zle -N __rationalise-dot
      bindkey . __rationalise-dot
    '' + lib.optionalString pkgs.stdenv.isDarwin ''
      # $LANG is horribly broken on MacOS
      if [ -n "$INSIDE_EMACS" ]; then
        unset LANG
      fi

      if [ -n "$SSH_CONNECTION" ] || [ -n "$TMUX" ]; then
        export PINENTRY_USER_DATA="USE_CURSES=1"
      fi

      export GPG_TTY="$(tty)"
      if pgrep -q gpg-agent; then
        ${config.programs.gpg.package}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
      fi

      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv | grep '^export HOMEBREW_')"
        #export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin''${PATH+:$PATH}";
        export PATH="$(printf '%s' "$PATH" | ${pkgs.gnused}/bin/sed 's#:\(/usr/local/bin\):#:\1:'"$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin"':#')"
        export MANPATH="$HOMEBREW_PREFIX/share/man''${MANPATH+:$MANPATH}";
        export INFOPATH="$HOMEBREW_PREFIX/share/info''${INFOPATH+:$INFOPATH}";
      fi
    '' + ''
      [ -f ~/.zshrc.local ] && source ~/.zshrc.local
    '';
  };

  programs.bash = {
    enable = true;
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "monokai_pro_octagon";
    };
  };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      cmp-buffer
      cmp-cmdline
      cmp-nvim-lsp
      cmp-path
      cmp-vsnip
      editorconfig-nvim
      nvim-cmp
      nvim-lspconfig
      rust-vim
      vim-nix
      vim-terraform
      vim-vsnip
      vim-which-key

      #(pkgs.vimUtils.buildVimPlugin {
      #  name = "Sierra";
      #  src = pkgs.fetchFromGitHub {
      #    owner = "AlessandroYorba";
      #    repo = "Sierra";
      #    rev = "461dc4bd1ac161b6a14f4a3194363d89abe75401";
      #    sha256 = "sha256-k4PENXu+QDL2OPM4623QvDLCs7CtaUzBJakBYxR7zb8=";
      #  };
      #})
    ];

    extraConfig = builtins.concatStringsSep "\n\n" [
      ''
        set completeopt=menu,menuone,noselect
        set eol
        set termguicolors

        highlight ExtraWhitespace ctermbg=red guibg=red
        match ExtraWhitespace /\s\+\%#\@<!$/
      ''
      ''
        lua <<EOF
          -- Setup nvim-cmp.
          local cmp = require'cmp'

          cmp.setup({
            snippet = {
              -- REQUIRED - you must specify a snippet engine
              expand = function(args)
                vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
                -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
              end,
            },
            window = {
              -- completion = cmp.config.window.bordered(),
              -- documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<C-e>'] = cmp.mapping.abort(),
              ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            }),
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'vsnip' }, -- For vsnip users.
              -- { name = 'luasnip' }, -- For luasnip users.
              -- { name = 'ultisnips' }, -- For ultisnips users.
              -- { name = 'snippy' }, -- For snippy users.
            }, {
              { name = 'buffer' },
            })
          })

          -- Set configuration for specific filetype.
          -- cmp.setup.filetype('gitcommit', {
          --   sources = cmp.config.sources({
          --     { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
          --   }, {
          --     { name = 'buffer' },
          --   })
          -- })

          cmp.setup.cmdline('/', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = 'buffer' }
            }
          })

          -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
          -- cmp.setup.cmdline(':', {
          --   mapping = cmp.mapping.preset.cmdline(),
          --   sources = cmp.config.sources({
          --     { name = 'path' }
          --   }, {
          --     { name = 'cmdline' }
          --   })
          -- })

          -- Setup lspconfig.
          local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

          local servers = { 'ansiblels', 'gopls', 'rnix', 'rust_analyzer', 'zls' };
          for _, srv in ipairs(servers) do
            require('lspconfig')[srv].setup {
              capabilities = capabilities
            }
          end

        EOF
      ''
    ];
  };

  programs.bat.enable = true;

  programs.eza = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Mark Vainomaa";
    userEmail = "mikroskeem@mikroskeem.eu";

    package = pkgs.gitFull;

    lfs.enable = true;

    delta = {
      enable = true;
      options = {
        side-by-side = true;
      };
    };
    iniContent.diff = {
      "colorMoved" = "default";
    };

    signing = {
      signByDefault = true;
      key = "CC28AE6A4AB07CF5";
    };

    extraConfig = {
      advice.detachedHead = false;
      am.threeWay = true;
      init.defaultBranch = "master";
      merge.autoStash = true;
      merge.ff = false;
      merge.conflictStyle = "diff3";
      pull.ff = "only";
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      rerere.enabled = true;
      trim.bases = lib.concatStringsSep "," [
        "master"
        "main"
        "trunk"
        "mainnet"
        "testnet"
        "staging"
        "production"
      ];

      url."ssh://git@github.com/".pushinsteadof = "https://github.com/";
      url."ssh://git@gitlab.com/".pushinsteadof = "https://gitlab.com/";
    };
  };

  programs.gpg = {
    enable = true;

    scdaemonSettings = lib.optionalAttrs pkgs.stdenv.isLinux {
      disable-ccid = true;
    };
  };

  services.gpg-agent = lib.optionalAttrs pkgs.stdenv.isLinux {
    enable = true;
    enableExtraSocket = true;
    enableSshSupport = true;
    #enableScDaemon = true;
    defaultCacheTtl = 7200;
    pinentryFlavor = "curses";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;
  programs.jq.enable = true;

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    extraConfig = ''
      set-option -sg escape-time 10
      # neovim RGB
      set-option -sa terminal-overrides ',XXX:RGB'
    '';
  };

  programs.firefox = lib.optionalAttrs (pkgs.stdenv.isLinux && hasDesktop) {
    enable = true;
  };

  programs.vscode = {
    enable = hasDesktop && pkgs.stdenv.isLinux;
    package = pkgs.vscodium;
  };
}
