#!/usr/bin/env bash
set -euo pipefail

flake="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"

if ! [ -f "${flake}/flake.nix" ]; then
	echo ">>> ERROR: no flake.nix in '${flake}'"
	exit 1
fi

machine="$(uname -s)"
configuration="$(hostname -s)"
elevate=(sudo --preserve-env=NIXOS_INSTALL_BOOTLOADER)
wrapper=(nice -n 5)

impure_path="/etc/nixos"
if ! [ -d "${impure_path}" ]; then
	impure_path="${flake}/impure-local"
fi

args=(
	--override-input impure-local "path:${impure_path}"
	--extra-experimental-features "nix-command flakes"
	--no-use-registries
)

no_activate=0
install_bootloader=0
while (( $# )); do
	case "${1}" in
		--no-activate)
			no_activate=1
			;;
		--install-bootloader)
			install_bootloader=1
			;;
		--show-trace)
			args+=(--show-trace)
			;;
		--configuration)
			shift
			configuration="${1}"
			;;
		*)
			echo "unsupported option: ${1}"
			;;
	esac
	shift
done

export NIXOS_INSTALL_BOOTLOADER="${install_bootloader}"

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

attr=""
case "${machine}" in
	Darwin)
		attr="darwinConfigurations"
		;;
	Linux)
		if test -n "$(command -v doas &>/dev/null)"; then
			elevate=(doas env NIXOS_INSTALL_BOOTLOADER="${NIXOS_INSTALL_BOOTLOADER}")
		fi

		wrapper=(chrt -i 0)
		attr="nixosConfigurations"
		;;
	*)
		echo "unsupported machine: ${machine}"
		exit 1
		;;
esac

args+=(--out-link ./result)
"${wrapper[@]}" nix build "${args[@]}" "${flake}#${attr}"."${configuration}".config.system.build.toplevel
do_activate ./result
