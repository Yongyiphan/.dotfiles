#!/usr/bin/env bash
# Load SSH keys into ssh-agent.
# - Respect ~/.ssh/config IdentityFile entries when present
# - Otherwise, add detected private keys under ~/.ssh (excluding .pem/.pub)
# - Idempotent and CRLF-safe


# Enable strict mode only when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

SSH_DIR="$HOME/.ssh"
CFG="$SSH_DIR/config"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR" 2>/dev/null || true

# ---- agent bootstrap (stable socket) ----
start_agent() {
 # If an agent is already usable (e.g., forwarded), reuse it
 if [ -n "${SSH_AUTH_SOCK:-}" ] && ssh-add -l >/dev/null 2>&1; then
   export EGA_LOCAL_AGENT=0
   return
 fi
 # Start our own agent on a stable socket
 local sock="$SSH_DIR/agent.sock"
 rm -f "$sock"
 eval "$(ssh-agent -a "$sock")" >/dev/null
 export SSH_AUTH_SOCK="$sock"
 export EGA_LOCAL_AGENT=1
}
start_agent

# Only manage keys if we control the local agent we just started
if [ "${EGA_LOCAL_AGENT:-0}" = 1 ] && [ "${SSH_AUTH_SOCK:-}" = "$SSH_DIR/agent.sock" ]; then
  # start clean so unwanted keys don't linger
  ssh-add -D >/dev/null 2>&1 || true
fi

# ---- helpers ----

# Expand ~ and strip trailing CR if present
expand_clean() {
  local p="$1"
  # expand ~ (and quotes) safely
  # shellcheck disable=SC2086
  p="$(eval printf '%s' "$p")"
  # strip trailing CR from CRLF files
  printf '%s' "${p%$'\r'}"
}

# Add a single key if not already loaded; skip .pub and .pem (case-insensitive)
add_key() {
  local key_raw="$1"
  local key="$(expand_clean "$key_raw")"
  [ -f "$key" ] || return 0

  # case-insensitive extension check
  local key_lc="${key,,}"
  [[ "$key_lc" == *.pub ]] && return 0
  [[ "$key_lc" == *.pem ]] && return 0

  chmod 600 "$key" 2>/dev/null || true

  local fp
  fp="$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')"
  [ -n "$fp" ] || return 0

  if ! ssh-add -l 2>/dev/null | grep -qF "$fp"; then
    echo "Adding SSH key: $key"
    ssh-add "$key" >/dev/null
  fi
}

# ---- load from ~/.ssh/config if present ----
load_from_config() {
  [ -f "$CFG" ] || return 1

  # Extract IdentityFile lines, ignore comments; strip CR
  mapfile -t idlines < <(
    awk '
      { sub(/\r$/,"") }                         # strip CR if present
      /^[[:space:]]*#/ { next }                 # skip comments
      tolower($1)=="identityfile" {             # capture IdentityFile ...
        $1=""; sub(/^[ \t]+/,""); print        # ... rest of the line
      }
    ' "$CFG" 2>/dev/null
  )

  ((${#idlines[@]})) || return 1

  # Some configs may put multiple paths on one line; split by whitespace
  for raw in "${idlines[@]}"; do
    for token in $raw; do
      # normalize relative paths to ~/.ssh
      token="$(expand_clean "$token")"
      [[ "$token" = /* ]] || token="$SSH_DIR/${token#./}"
      add_key "$token"
    done
  done
  return 0
}

# ---- fallback: scan ~/.ssh for typical private keys (exclude .pem/.pub) ----
fallback_load_all() {
  while IFS= read -r key; do
    add_key "$key"
  done < <(find "$SSH_DIR" -maxdepth 1 -type f \( \
             -name 'id_rsa'      -o -name 'id_rsa_*'      -o \
             -name 'id_ed25519'  -o -name 'id_ed25519_*'  -o \
             -name 'id_ecdsa'    -o -name 'id_ecdsa_*'    -o \
             -name '*.key' \
           \) ! -iname '*.pub' ! -iname '*.pem' 2>/dev/null)
}

if [ "${EGA_LOCAL_AGENT:-0}" = 1 ] && [ "${SSH_AUTH_SOCK:-}" = "$SSH_DIR/agent.sock" ]; then
  if load_from_config; then :; else
    echo "No IdentityFile entries found in ~/.ssh/config — loading detected keys (excluding .pem)."
    fallback_load_all
  fi
fi

# Show what's loaded (optional)
ssh-add -l 2>/dev/null || true
