{ pkgs
, lib
, ...
}:

let
  pinentryWrapper = pkgs.writeShellScriptBin "pinentry-macos" ''
    if ${pkgs.gnugrep}/bin/grep -q -F "USE_CURSES=1" <<< "''${PINENTRY_USER_DATA:-}"; then
      exec ${pkgs.pinentry-curses}/bin/pinentry-curses "''${@}"
    fi

    exec ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac "''${@}"
  '';
in
{
  home.file = lib.optionalAttrs pkgs.stdenv.isDarwin {
    ".gnupg/gpg-agent.conf".text = ''
      pinentry-program ${pinentryWrapper}/bin/pinentry-macos
    '';
  };
}
