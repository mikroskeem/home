#!/usr/bin/env bash
set -euo pipefail

keyfile=/etc/ssh/ssh_host_ed25519_key.pub
pubkey="$(ssh-to-age -i "${keyfile}")"

echo "\"${pubkey}\" # $(hostname -s) $(date +%Y-%m-%d)"
