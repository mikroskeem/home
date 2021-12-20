{ stdenvNoCC }:

stdenvNoCC.mkDerivation rec {
  name = "mac-docker-app-shell-completions";
  phases = [ "installPhase" ];

  app = "/Applications/Docker.app/Contents/Resources/etc";
  installPhase = ''
    runHook preInstall

    # NOTE: cannot use 'installShellCompletion', as it'll copy the contents
    zshd=$out/share/zsh/site-functions
    bashd=$out/share/bash-completion/completions
    fishd=$out/share/fish/vendor_completions.d

    mkdir -p $zshd/
    ln -s ${app}/docker-compose.zsh-completion  $zshd/_docker-compose
    ln -s ${app}/docker.zsh-completion          $zshd/_docker

    mkdir -p $bashd/
    ln -s ${app}/docker-compose.bash-completion $bashd/docker-compose
    ln -s ${app}/docker.bash-completion         $bashd/docker

    mkdir -p $fishd/
    ln -s ${app}/docker-compose.fish-completion $fishd/docker-compose.fish
    ln -s ${app}/docker.fish-completion         $fishd/docker.fish

    runHook postInstall
  '';
}
