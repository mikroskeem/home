{ stdenv, lib, chromium, writeShellScript }:

let
  script = writeShellScript "chromium-wrapper" ''
    params=()
    if [ -n "$WAYLAND_DISPLAY" ]; then
      params+=(--enable-features=UseOzonePlatform --enable-features=WebRTCPipeWireCapturer --ozone-platform=wayland --enable-usermedia-screen-capturing)

      # mm yes, masochism
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

  meta = chromium.meta // {
    description = chromium.meta.description + " - forced to run using Ozone platform when under Wayland";
  };
}
