#!/usr/bin/env bash
set -euo pipefail

flake="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"

if ! [ -f "${flake}/flake.nix" ]; then
	echo ">>> ERROR: no flake.nix in '${flake}'"
	exit 1
fi

machine="$(uname -s)"
configuration="$(hostname -s)"
elevate=(sudo --preserve-env=NIXOS_INSTALL_BOOTLOADER -H)
wrapper=(nice -n 5)

args=(
	--extra-experimental-features "nix-command flakes"
	--no-use-registries
	-L
)

no_activate=0
no_impure=0
dry_run=0
install_bootloader=0
impure_path="/etc/nixos"
tmpdir=""

if [ "${machine}" = "Darwin" ]; then
	no_impure=1
fi

while (( $# )); do
	case "${1}" in
		--no-activate)
			no_activate=1
			;;
		--dry-run)
			dry_run=1
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
		--impure-path)
			shift
			no_impure=0
			impure_path="${1}"
			;;
		--no-impure)
			no_impure=1
			;;
		--tmpdir)
			if [ "${machine}" = "Darwin" ]; then
				echo "option --tmpdir is not supported on ${machine}"
				exit 1
			fi
			shift
			tmpdir="${1}"
			;;
		*)
			echo "unsupported option: ${1}"
			;;
	esac
	shift
done

if [ "${no_impure}" = "0" ]; then
	if [ -f "${impure_path}" ] || [ -f "${impure_path}/default.nix" ]; then
		args+=(--override-input impure-local "path:${impure_path}")
	fi
fi

export NIXOS_INSTALL_BOOTLOADER="${install_bootloader}"

do_activate () {
	local res="${1}"
	pushd "${res}" >/dev/null

	profile=/nix/var/nix/profiles/system
	pathToConfig="$(realpath -- .)"

	echo "activating configuration '${pathToConfig}'"
	"${elevate[@]}" nix-env -p "${profile}" --set "${pathToConfig}"

	if [ "${machine}" = "Darwin" ] && [ -f ./activate-user ] && [ -x ./activate-user ]; then
		# TODO: ensure that user is not root
		"${elevate[@]}" ./activate
		./activate-user
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


store=""
if [ -n "${tmpdir}" ] && ! (( dry_run )); then
	export TMPDIR="${tmpdir}"
	store="${tmpdir}/nix-store"
	echo "using '${tmpdir}' as build directory and '${store}' as store"

	# NOTE: need to force impure & use custom store to bypass nix-daemon
	nix copy --to "${store}" $(nix flake archive --json | jq -r '.path,(.inputs|to_entries[].value.path)')
	args+=(--impure --store "${store}" --extra-substituters /)
fi

args+=(--out-link ./result)
if (( dry_run )); then
	args+=(--dry-run)
fi

"${wrapper[@]}" nix build "${args[@]}" "${flake}#${attr}"."${configuration}".config.system.build.toplevel
res="${?}"

if (( dry_run )); then
	exit "${res}"
fi

if [ -n "${tmpdir}" ]; then
	nix copy --no-check-sigs --from "${store}" "$(readlink ./result)"
fi

if [ "${no_activate}" = "1" ]; then
	echo "skipping activation as requested"
	exit 0
fi

do_activate ./result
