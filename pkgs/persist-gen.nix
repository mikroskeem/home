{ lib, stdenvNoCC, rage, bash, coreutils, gnutar, makeWrapper, openssh }:

stdenvNoCC.mkDerivation {
  name = "persistgen";
  src = ../scripts/init_persist.sh;

  buildInputs = [
    rage
    bash
    coreutils
    gnutar
    openssh
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preBuild

    install -D -m 755 $src $out/bin/init-persist
    wrapProgram $out/bin/init-persist \
      --prefix PATH : ${lib.makeBinPath [ rage coreutils gnutar openssh ]}

    runHook postBuild
  '';
}
