{ stdenvNoCC, lib, chromium, runtimeShell }:

stdenvNoCC.mkDerivation rec {
  pname = "${lib.strings.getName chromium.name}-wayland-wrapped";
  version = lib.strings.getVersion chromium.name;

  phases = [ "installPhase" ];

  wrapperScript = ''
    #!${runtimeShell}
    set -e
    params=()
    if [ -n "$WAYLAND_DISPLAY" ]; then
      params+=(--enable-features=UseOzonePlatform --enable-features=WebRTCPipeWireCapturer --ozone-platform=wayland --enable-usermedia-screen-capturing)

      # mm yes, masochism
      unset DISPLAY
    fi
    exec ${chromium}/bin/chromium "''${params[@]}" $@
  '';

  passAsFile = [ "wrapperScript" ];

  installPhase = ''
    mkdir -p $out/bin
    cd $out && ln -s ${chromium}/share
    install -D -m 755 $wrapperScriptPath $out/bin/chromium
    ln -s chromium $out/bin/chromium-browser
  '';

  meta = chromium.meta // {
    description = chromium.meta.description + " - forced to run using Ozone platform when under Wayland";
  };
}
