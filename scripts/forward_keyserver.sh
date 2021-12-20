#!/usr/bin/env bash
set -euo pipefail

umask 077
sopspid=""
sockdir="$(mktemp -d)"
sock="${sockdir}/sops.sock"

cleanup () {
	if [ -n "${sopspid}" ]; then
		kill -INT "${sopspid}" || true
		wait "${sopspid}"
	fi

	rm -rf "${sockdir}" || true
}
trap cleanup EXIT

sshopts=(
	-N
	-o BatchMode=yes
	-o Compression=yes
	-o ExitOnForwardFailure=yes
	-o ServerAliveInterval=30
	-R "127.0.0.1:3764:${sock}" # TODO: random port?
)

sops keyservice --verbose --network unix --address "${sock}" &
sopspid="${!}"

ssh "${sshopts[@]}" "${@}"
