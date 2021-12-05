{ config, lib, ... }:

{
  services.chrony =
    let
      pools = [
        "0.ee.pool.ntp.org"
        "1.ee.pool.ntp.org"
        "2.ee.pool.ntp.org"
        "3.ee.pool.ntp.org"
        "time.cloudflare.com"
      ];
    in
    {
      enable = true;
      servers = [ ]; # Kept empty because I want to specify pools rather than servers
      extraConfig = ''
        # Define pools
        ${lib.concatMapStringsSep "\n" (it: "pool ${it} iburst") pools}
      '';
    };
}
