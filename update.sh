#!/usr/bin/env bash
set -euo pipefail

flake="$(dirname -- "${BASH_SOURCE[0]}")"

if ! [ -f "${flake}/flake.nix" ]; then
	echo ">>> ERROR: no flake.nix in '${flake}'"
	exit 1
fi

machine="$(uname -s)"
elevate="sudo"

case "${machine}" in
	Darwin)
		darwin-rebuild switch --flake "${flake}"

		# NOTE: https://github.com/LnL7/nix-darwin/issues/375
		[ -L ./result ] && rm result
		;;
	Linux)
		if test -n "$(command -v doas &>/dev/null)"; then
			elevate="doas"
		fi

		"${elevate}" nixos-rebuild switch --flake "${flake}"
		;;
	*)
		echo "unsupported machine: ${machine}"
		exit 1
		;;
esac
