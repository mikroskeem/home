{ config
, pkgs
, lib
, intelPkgs
, hasDesktop
, ...
}:
let
  packageWorkarounds = { };

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
          colima
          coreutils
          curl
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
          procps
          pv
          ripgrep
          tig
          tree
          unzip
          wakatime
          xz
          zip
          zstd

          (pkgs.callPackage ../pkgs/wait-docker.nix { })
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
      "issh" = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
      "mkdir" = "mkdir -p";
    };

    plugins = [
      #{
      #  file = "powerlevel10k.zsh-theme";
      #  name = "powerlevel10k";
      #  src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
      #}
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
    }; # // import ./p10k.nix;

    initExtraBeforeCompInit = ''
      # p10k instant prompt
      #P10K_INSTANT_PROMPT="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"
      #[[ ! -r "$P10K_INSTANT_PROMPT" ]] || source "$P10K_INSTANT_PROMPT"

      #[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    '';

    initExtra = ''
      # Fix prompt swallowing output without a newline
      setopt prompt_cr prompt_percent prompt_sp
    '' + lib.optionalString pkgs.stdenv.isDarwin ''
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
      cmp-buffer
      cmp-cmdline
      cmp-nvim-lsp
      cmp-path
      cmp-vsnip
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
          local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

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

    scdaemonSettings = {
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
