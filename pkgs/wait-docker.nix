{ stdenvNoCC, lib, writeShellScriptBin, docker-client }:

let
  isDarwin = stdenvNoCC.isDarwin;
  dockerBin = if (isDarwin) then "/usr/local/bin/docker" else "${docker-client}/bin/docker";
in
writeShellScriptBin "wait-docker" (lib.optionalString isDarwin ''
  if ! pgrep -q "com.docker.virtualization"; then
    # TODO: still opens this shitty desktop UI
    /usr/bin/open --hide --background -a Docker.app
  fi
'' + ''
  while ! ${dockerBin} system info &>/dev/null; do sleep 1; done
  if [ -n "$*" ]; then
    exec "$@"
  fi
'')
