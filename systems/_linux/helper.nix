{ lib, ... }:

# helper options
{
  options = with lib; {
    vendoredConfig.hasDesktop = mkEnableOption "headful or headless huh?";

    vendoredConfig.firewallBackend = mkOption {
      description = "iptables or nftables";
      default = "iptables";
      type = types.enum [ "iptables" "nftables" ];
    };
  };
}
