#!/usr/bin/env bash
set -euo pipefail

flake="$(dirname -- "${BASH_SOURCE[0]}")"

if ! [ -f "${flake}/flake.nix" ]; then
	echo ">>> ERROR: no flake.nix in '${flake}'"
	exit 1
fi

no_activate=0
while [ -n "${1:-}" ]; do
	arg="${1}"
	case "${arg}" in
		--no-activate)
			no_activate=1
			;;
		*)
			echo "unsupported option: ${arg}"
			;;
	esac
	shift;
done

export NIXOS_INSTALL_BOOTLOADER=0 # TODO

machine="$(uname -s)"
hostname="$(hostname -s)"
elevate=(sudo --preserve-env=NIXOS_INSTALL_BOOTLOADER)

args=(--flake "${flake}#${hostname}")
wrapper=(nice -n 5)

# Ensure this is always up to date
nix flake lock --update-input impure-local
trap 'do_cleanup' EXIT

do_activate () {
	if [ "${no_activate}" = "1" ]; then
		echo "skipping activation as requested"
		return 0
	fi
	local res="${1}"
	pushd "${res}" >/dev/null

	profile=/nix/var/nix/profiles/system
	pathToConfig="$(realpath -- .)"

	echo "activating configuration '${pathToConfig}'"
	"${elevate[@]}" nix-env -p "${profile}" --set "${pathToConfig}"

	if [ "${machine}" = "Darwin" ] && [ -f ./activate-user ] && [ -x ./activate-user ]; then
		# TODO: ensure that user is not root
		./activate-user
		"${elevate[@]}" ./activate
	elif [ "${machine}" = "Linux" ]; then
		if ! "${elevate[@]}" ./bin/switch-to-configuration switch; then
			echo "new configuration activation did not succeed cleanly"
		fi
	fi

	popd >/dev/null
}

do_cleanup () {
	git checkout -- flake.lock
}

case "${machine}" in
	Darwin)
		"${wrapper[@]}" darwin-rebuild build "${args[@]}"
		do_activate ./result
		;;
	Linux)
		if test -n "$(command -v doas &>/dev/null)"; then
			elevate=(doas env NIXOS_INSTALL_BOOTLOADER="${NIXOS_INSTALL_BOOTLOADER}")
		fi

		wrapper+=(chrt -i 0)
		"${wrapper[@]}" nixos-rebuild build "${args[@]}"
		do_activate ./result
		;;
	*)
		echo "unsupported machine: ${machine}"
		exit 1
		;;
esac
