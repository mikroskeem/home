#!/usr/bin/env bash
set -euo pipefail

log () {
	local f="${FUNCNAME[1]}"
	echo "[${f}] ${*}" >&2
}

gen_machine_id () {
	local dir="${1}"

	local id="$(dd if=/dev/urandom count=1024 status=none | md5sum - | cut -d' ' -f1)"
	echo "${id}" | install -D -m 0444 /dev/stdin "${dir}/etc/machine-id"
}

gen_ssh_keys () {
	local dir="${1}"
	local keys=(rsa ed25519)

	mkdir -p "${dir}/etc/ssh"
	for key in "${keys[@]}"; do
		log "generating ${key} key"
		ssh-keygen -N "" -C "" -q -t "${key}" -f "${dir}/etc/ssh/ssh_host_${key}_key"
	done
}

gen_age_key () {
	local dir="${1}"

	log "generating age key"
	keytype="ed25519"

	local t="${dir}/state/age.key"

	echo -n "# age public key: " | install -D -m 0400 /dev/stdin "${t}"
	ssh-to-age -i "${dir}/etc/ssh/ssh_host_${keytype}_key.pub" -o - >> "${t}"
	ssh-to-age -private-key -i "${dir}/etc/ssh/ssh_host_${keytype}_key" -o - >> "${t}"

	chmod 444 "${t}"
}

gen_impure_config () {
	local dir="${1}"
	local conf="${dir}/etc/nixos"

	echo -e "{ ... }: {\n  imports = [\n    # add your local config here\n  ];\n}" \
		| install -D -m 0644 /dev/stdin "${conf}/default.nix"


	local expected_hash="sha256-6pJ2Ev9tyW6cLAwqqqb5+VUhqvlVne1+IlB9DtFc0Fo="
	local actual_hash="$(nix hash path --base32 --type sha256 --sri "${conf}")"

	if ! [ "${actual_hash}" = "${expected_hash}" ]; then
		log "generated impure config hash mismatch (expected: '${expected_hash}', actual: '${actual_hash}')"
		return 1
	fi
}

pack_root () {
	local dir="${1}"

	local tar_args=(
		--numeric-owner --owner=0 --group=0
		--no-recursion
		--mtime='UTC 1970-01-01 00:00:00'
		--sort=none
	)

	local size="$(du -sb "${dir}" | cut -d $'\t' -f 1)"

	log "packing (${size} bytes)"
	pushd "${dir}" >/dev/null
	find -L . -print0 \
		| LC_ALL=C sort -z \
		| tar "${tar_args[@]}" --null -T - -cf -
	popd >/dev/null
}


target="${1}"
test -d "${target}"

fns=(gen_machine_id gen_ssh_keys gen_age_key gen_impure_config)
root="$(mktemp -d)"

for fn in "${fns[@]}"; do
	log "running ${fn}"
	"${fn}" "${root}"
done

pack_root "${root}" | tar -C "${target}" -xf -
rm -rf "${root}"

