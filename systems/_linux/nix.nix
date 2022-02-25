{ config, lib, pkgs, ... }:

# https://github.com/serokell/serokell.nix/blob/acb4b992f9023b1feffd7b6dc939d55465f9cced/modules/nix-gc.nix

let
  cfg = config.nix.gc;
in
with lib;
{
  options.nix.gc.keep-gb = mkOption {
    type = types.int;
    description = "Amount of free space (in GB) to keep on the disk by running garbage collection";
    default = 30;
  };

  config = {
    nix.gc = {
      automatic = true;

      # delete so there is ${keep-gb} GB free, and delete very old generations
      # delete-older-than by itself will still delete all non-referenced packages (ie build dependencies)
      options =
        let
          cur-avail-cmd = "df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }'";
          # free `${keep-gb} - ${cur-avail}` of space
          max-freed-expression = "${toString cfg.keep-gb} * 1024**3 - 1024 * $(${cur-avail-cmd})";
        in
        mkDefault ''--delete-older-than 7d --max-freed "$((${max-freed-expression}))"'';
    };
  };
}
