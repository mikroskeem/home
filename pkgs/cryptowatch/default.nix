{ stdenv
, lib
, fetchurl
, dpkg
, patchelf
, makeDesktopItem
, dbus
, udev
, libglvnd
, libnotify
, libsecret
, libX11
, libXcursor
, libXi
, libXrandr
}:

stdenv.mkDerivation rec {
  pname = "cryptowatch";
  version = "0.4.4";

  src = fetchurl {
    url = "https://cryptowat.ch/desktop/download/debian/${version}";
    sha256 = "sha256-QmUvYJn47JiFkklSNXjKPhmzAesGJVBShG0EH1BMrdU=";
  };

  nativeBuildInputs = [
    dpkg
    patchelf
  ];

  buildInputs = [
    dbus
    udev
  ];

  unpackPhase = ''
    runHook preUnpack

    mkdir pkg
    dpkg-deb -x $src pkg
    sourceRoot=pkg

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -D -m 755 usr/bin/cryptowatch $out/bin/cryptowatch
    install -D -m 644 usr/share/pixmaps/cryptowatch.png $out/share/pixmaps/cryptowatch.png
    install -D -m 644 usr/share/doc/cryptowatch/copyright $out/share/doc/cryptowatch/copyright

    runHook postInstall
  '';

  postFixup =
    let
      libPath = lib.makeLibraryPath [
        dbus
        udev
        libglvnd
        libsecret
        libnotify
        libX11
        libXcursor
        libXi
        libXrandr
      ];
    in
    ''
      patchelf \
        --set-interpreter "$(< $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${libPath}" \
        $out/bin/cryptowatch
    '';

  desktopItems = [
    (makeDesktopItem {
      type = "Application";
      name = "Cryptowatch Desktop";
      desktopName = "Cryptowatch Desktop";
      exec = "cryptowatch %u";
      icon = "cryptowatch";
      comment = "Build your own real-time crypto market dashboards with any combination of candle charts, order books, time & sales feeds, and more.";
      terminal = false;
      mimeType = "x-scheme-handler/cryptowatch";
    })
  ];
}
