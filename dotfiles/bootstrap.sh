#!/usr/bin/env bash
# First-time setup entry point: fixes up the hardcoded username in flake.nix
# for this machine (if needed), then hands off to rebuild.sh.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

current_user="$(whoami)"
configured_user="$(sed -n 's/^ *user = "\(.*\)";.*/\1/p' "$DIR/flake.nix")"

if [[ -z "$configured_user" ]]; then
  echo "error: could not find the 'user = \"...\";' line in $DIR/flake.nix" >&2
  exit 1
fi

if [[ "$current_user" != "$configured_user" ]]; then
  echo "flake.nix is configured for user '$configured_user', but this machine's user is '$current_user'."
  read -r -p "Rewrite flake.nix to use '$current_user'? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    sed -i '' "s/user = \"$configured_user\";/user = \"$current_user\";/" "$DIR/flake.nix"
    echo "Updated flake.nix: user = \"$current_user\";"
  else
    echo "Leaving flake.nix as-is. Edit the 'user' line yourself before continuing." >&2
    exit 1
  fi
fi

exec "$DIR/rebuild.sh"
