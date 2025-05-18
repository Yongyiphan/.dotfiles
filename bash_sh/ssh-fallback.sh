#!/usr/bin/env bash
#
# ssh-fallback — scan ~/.ssh for keys and retry until one works
set -euo pipefail

# 1) gather all your private keys in ~/.ssh
mapfile -t keys < <(
  find "$HOME/.ssh" -maxdepth 1 -type f \
    -name 'id_*' ! -name '*.pub' \
    -perm /u=r | sort
)

# no keys? bail
if [ ${#keys[@]} -eq 0 ]; then
  echo "No SSH keys found in ~/.ssh (id_* excluding .pub)" >&2
  exit 1
fi

# 2) try them one by one
last_output=""
last_status=0
for key in "${keys[@]}"; do
  # attempt with this key, capture stderr/stdout
  output=$(ssh -i "$key" -o IdentitiesOnly=yes "$@" 2>&1) || status=$?
  
  # if ssh returns 255, it never got to auth → try next key
  if [ "${status:-0}" -eq 255 ]; then
    last_output="$output"
    last_status=$status
    continue
  fi

  # if GitHub says "Permission to ... denied", retry
  if grep -q "Permission to .\+ denied" <<<"$output"; then
    last_output="$output"
    last_status=$status
    continue
  fi

  # otherwise, either success or some other error → pass it through
  echo "$output" >&2
  exit $status
done

# if we get here, every key failed; replay last error
echo "$last_output" >&2
exit $last_status

