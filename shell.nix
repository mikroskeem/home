let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  compat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  };
  compat' = import compat { src = ./.; };
in
compat'.shellNix
