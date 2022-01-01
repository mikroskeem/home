{ config, ... }:

{
  users.users.deploy = {
    description = "deploy-rs user";
    group = "deploy";
    isSystemUser = true;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrsI8dOTbtlw4oYeUCcCkJRLWrfNnLqJW+G2P4wgaN+"
    ];
  };

  users.groups.deploy = {};

  security.sudo.extraRules = [
    {
      users = [ config.users.users.deploy.name ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
