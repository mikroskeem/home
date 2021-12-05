{ pkgs, lib, stdenv, config, ... }:

let
  # NOTE: original script checks if iptables modules are present, and fails hard.
  #       that doesn't make sense on modern kernels, iptables and nftables can co-exist
  #       just fine.
  nftablesStartScript = pkgs.writeScript "nftables-rules" ''
    #!${pkgs.nftables}/bin/nft -f
    flush ruleset
    include "${config.networking.nftables.rulesetFile}"
  '';
in
{
  systemd.services.nftables.serviceConfig.ExecStart = lib.mkForce nftablesStartScript;
  systemd.services.nftables.serviceConfig.ExecReload = lib.mkForce nftablesStartScript;
}
