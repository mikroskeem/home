{ lib, ... }:

# helper options
{
  options = {
    vendoredConfig.hasDesktop = lib.mkEnableOption "headful or headless huh?";
  };
}
