{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.endlessh;
in
{
  options = {
    services.endlessh = {
      enable = mkEnableOption "endlessh daemon";

      port = mkOption {
        type = types.port;
        default = 2222;
        description = ''
          Specifies on which port the Endlessh daemon listens.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to automatically open the specified ports in the firewall.
        '';
      };

      bindFamily = mkOption {
        type = types.enum [ "0" "4" "6" ];
        default = "0";
        description = ''
          Set the family of the listening socket.
            0 = Use IPv4 Mapped IPv6 (Both v4 and v6, default)
            4 = Use IPv4 only
            6 = Use IPv6 only
        '';
      };

      delay = mkOption {
        type = types.ints.positive;
        default = 10000;
        description = ''
          The endless banner is sent one line at a time. This is the delay
          in milliseconds between individual lines
        '';
      };

      maxLineLength = mkOption {
        type = types.ints.positive;
        default = 32;
        description = ''
          The length of each line is randomized. This controls the maximum
          length of each line. Shorter lines may keep clients on for longer if
          they give up after a certain number of bytes.
        '';
      };

      maxClients = mkOption {
        type = types.ints.positive;
        default = 4096;
        description = ''
          Maximum number of connections to accept at a time. Connections beyond
          this are not immediately rejected, but will wait in the queue.
        '';
      };

      logLevel = mkOption {
        type = types.enum [ "0" "1" "2" ];
        default = "0";
        description = ''
          Set the detail level for the log.
            0 = Quiet
            1 = Standard, useful log messages
            2 = Very noisy debugging information
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.endlessh;
        defaultText = literalExpression "pkgs.endlessh";
        description = ''
          Which package to use for endlessh.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Verbatim contents of endlessh config";
      };
    };
  };


  config = mkIf cfg.enable {
    environment.etc = {
      "endlessh/config".source = pkgs.writeText "endlessh-config" cfg.extraConfig;
    };

    systemd.services.endlessh = {
      description = "Endlessh Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartTriggers = [
        config.environment.etc."endlessh/config".source
      ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/endlessh -f /etc/endlessh/config";
        Type = "simple";
        Restart = "always";
        RestartSec = "30sec";
        KillSignal = "SIGTERM";

        AmbientCapabilities = optional (cfg.port < 1024) "CAP_NET_BIND_SERVICE";
        DynamicUser = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "full";
        ProtectHome = true;
        #InaccessiblePaths = "/run /var";
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        MemoryDenyWriteExecute = true;
      };

      unitConfig = {
        StartLimitInterval = "5min";
        StartLimitBurst = 4;
      };
    };

    networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.port;

    services.endlessh.extraConfig = mkOrder 0 ''
      Port ${toString cfg.port}
      Delay ${toString cfg.delay}
      MaxLineLength ${toString cfg.maxLineLength}
      MaxClients ${toString cfg.maxClients}
      LogLevel ${cfg.logLevel}
      BindFamily ${cfg.bindFamily}
    '';
  };
}
