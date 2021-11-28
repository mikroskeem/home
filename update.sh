#!/usr/bin/env bash
set -euo pipefail

flake="$(dirname -- "${BASH_SOURCE[0]}")"

if ! [ -f "${flake}/flake.nix" ]; then
	echo ">>> ERROR: no flake.nix in '${flake}'"
	exit 1
fi

machine="$(uname -s)"

case "${machine}" in
	Darwin)
		darwin-rebuild switch --flake "${flake}"

		# NOTE: https://github.com/LnL7/nix-darwin/issues/375
		[ -L ./result ] && rm result
		;;
	Linux)
		# TODO
		echo "unsupported machine: ${machine}"
		exit 1
		;;
	*)
		echo "unsupported machine: ${machine}"
		exit 1
		;;
esac
