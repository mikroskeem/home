{ stdenv, lib, chromium, writeShellScript }:
let
  script = writeShellScript "chromium-wrapper" ''
    params=()
    if [ -n "$WAYLAND_DISPLAY" ]; then
      params+=(--enable-features=UseOzonePlatform --ozone-platform=wayland)
      unset DISPLAY
    fi
    exec ${chromium}/bin/chromium "''${params[@]}" $@
  '';
in
stdenv.mkDerivation rec {
  pname = "${lib.strings.getName chromium.name}-wayland-wrapped";
  version = lib.strings.getVersion chromium.name;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cd $out && ln -s ${chromium}/share
    cd $out/bin && ln -s ${script} chromium
    cd $out/bin && ln -s ${script} chromium-browser
  '';
}
