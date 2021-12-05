{ config, lib, ... }:

{
  # DNS
  services.unbound =
    let
      dnsServers = [
        # Cloudflare DNS
        "1.1.1.1@853#cloudflare-dns.com"
        "2606:4700:4700::1111@853#cloudflare-dns.com"
        "1.0.0.1@853#cloudflare-dns.com"
        "2606:4700:4700::1001@853#cloudflare-dns.com"
      ];
    in
    {
      enable = true;

      settings = {
        #server.access-control = [ "0.0.0.0/0 allow" "::/0 allow" ];
        server.interface = [ "127.0.0.1" "::1" ];

        # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/ca.nix
        server.tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";

        forward-zone = [
          {
            name = ".";
            forward-tls-upstream = true;
            forward-addr = dnsServers;
          }
        ];
      };
    };

  # TODO: Anything in its own network namespace does not like this
  networking.nameservers = [ "127.0.0.1" "::1" ];
  environment.etc."resolv.conf".text = ''
    ${lib.concatMapStringsSep "\n" (n: "nameserver ${n}") config.networking.nameservers}
  '';
}
