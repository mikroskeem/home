{ config, lib, ... }:

{
  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/var/log"

      # systemd machines
      "/etc/containers"
      "/var/lib/containers"
    ] ++ lib.optionals config.networking.wireless.iwd.enable [
      "/var/lib/iwd"
    ] ++ lib.optionals config.services.chrony.enable [
      "/var/lib/chrony"
    ] ++ lib.optionals config.services.k3s.enable [
      "/etc/rancher"
      "/var/lib/kubelet"
      "/var/lib/rancher"
    ] ++ lib.optionals config.services.mysql.enable [
      {
        directory = config.services.mysql.dataDir;
        user = "mysqld";
        group = "mysqld";
        mode = "u=rwx,g=,o=";
      }
    ] ++ lib.optionals config.virtualisation.docker.enable [
      "/var/lib/docker"
    ] ++ lib.optionals (config ? declared-secrets) [
      config.declared-secrets.directory
    ];

    files = [
      "/etc/machine-id"
    ];
  };
}
