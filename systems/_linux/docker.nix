{ wrapIntoOwnNamespace ? true
, hostVethName ? "dockernet"
, hostAddr ? "10.0.0.1/24"
, nsAddr ? "10.0.0.100/24"
}:

{ pkgs
, lib
, config
, ...
}:

# https://wiki.archlinux.org/title/Nftables#Working_with_Docker
let
  hostip = "${pkgs.util-linux}/bin/nsenter --target 1 --net -- ${ip}";
  ip = "${pkgs.iproute2}/bin/ip";

  nsNetworkSetupScript = pkgs.writeShellScript "docker-netns-setup" ''
    set -exuo pipefail

    # clean up previous veth interface, if exists
    ${hostip} link delete ${hostVethName} || true

    # create veth
    ${hostip} link add ${hostVethName} type veth peer name ${hostVethName}_ns
    ${hostip} link set ${hostVethName}_ns netns "$BASHPID"
    ${ip} link set ${hostVethName}_ns name eth0

    # bring host veth pair online
    ${hostip} addr add ${hostAddr} dev ${hostVethName}
    ${hostip} link set ${hostVethName} up

    # bring ns veth pair online
    ${ip} addr add ${nsAddr} dev eth0
    ${ip} link set eth0 up
    ${ip} route add default via ${lib.head (lib.splitString "/" hostAddr)} dev eth0
  '';

  nsNetworkTeardownScript = pkgs.writeShellScript "docker-netns-teardown" ''
    set -exuo pipefail

    ${hostip} link delete ${hostVethName} || true
  '';
in
{
  virtualisation.docker.enable = true;
} // lib.optionalAttrs wrapIntoOwnNamespace {
  systemd.services.docker.serviceConfig.PrivateNetwork = true;
  systemd.services.docker.serviceConfig.ExecStartPre = [
    ""
    "${nsNetworkSetupScript}"
  ];
  systemd.services.docker.serviceConfig.ExecStopPost = [
    ""
    "${nsNetworkTeardownScript}"
  ];
}
