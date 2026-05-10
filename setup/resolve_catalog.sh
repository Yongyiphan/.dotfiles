#!/usr/bin/env bash

# Shared helpers for bootstrap/package manifest resolution.
# Can be sourced by setup scripts or executed for ad hoc inspection.

catalog_default_scaffold() {
  cat <<'EOF'
# id|manager|package|policy|version|required|note
# manager: auto|apt|brew|dnf|pacman|tar
# policy: exact|minimum|preferred|floating
# required: 1 or 0
# Examples:
# tmux|apt|tmux|minimum|3.3|1|core tmux runtime
# lazygit|brew|lazygit|preferred|0.41|0|optional git TUI
EOF
}

catalog_trim_line() {
  local line="$1"
  line="${line%%#*}"
  printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

catalog_parse_line() {
  local raw line fields id manager package policy version required note rest lhs rhs
  raw="$1"
  line="$(catalog_trim_line "$raw")"
  [ -n "$line" ] || return 1

  if [[ "$line" == *"|"* ]]; then
    IFS='|' read -r fields[0] fields[1] fields[2] fields[3] fields[4] fields[5] fields[6] rest <<< "$line"
    if [ -n "${fields[2]:-}" ] || [ -n "${fields[3]:-}" ] || [ -n "${fields[4]:-}" ] || [ -n "${fields[5]:-}" ] || [ -n "${fields[6]:-}" ] || [ -n "${rest:-}" ]; then
      id="${fields[0]}"
      manager="${fields[1]:-auto}"
      package="${fields[2]:-$id}"
      policy="${fields[3]:-preferred}"
      version="${fields[4]:--}"
      required="${fields[5]:-1}"
      note="${fields[6]:-}"
      if [ -n "${rest:-}" ]; then
        note="${note}|${rest}"
      fi
    else
      id="${fields[0]}"
      manager="auto"
      package="$id"
      policy="preferred"
      version="${fields[1]:--}"
      required="1"
      note=""
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$manager" "$package" "$policy" "$version" "$required" "$note"
    return 0
  fi

  if [[ "$line" == *":"* ]]; then
    lhs="${line%%:*}"
    rhs="${line#*:}"
    if [[ "$rhs" == *"="* ]]; then
      package="${rhs%%=*}"
      version="${rhs#*=}"
      policy="preferred"
    else
      package="$rhs"
      version="-"
      policy="floating"
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$package" "$lhs" "$package" "$policy" "$version" "1" ""
    return 0
  fi

  if [[ "$line" == *"="* ]]; then
    package="${line%%=*}"
    version="${line#*=}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$package" "auto" "$package" "preferred" "$version" "1" ""
    return 0
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$line" "auto" "$line" "floating" "-" "1" ""
}

catalog_emit_normalized() {
  local file="$1"
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    catalog_parse_line "$line" || true
  done < "$file"
}

catalog_merge_files() {
  local core_file="$1" profile_file="$2"
  local file source parsed id manager package policy version required note key
  declare -A rows=()
  declare -A seen=()
  local -a order=()

  for file in "$core_file" "$profile_file"; do
    [ -f "$file" ] || continue
    if [ "$file" = "$core_file" ]; then
      source="core"
    else
      source="profile"
    fi
    while IFS= read -r line || [ -n "$line" ]; do
      parsed="$(catalog_parse_line "$line")" || continue
      IFS=$'\t' read -r id manager package policy version required note <<< "$parsed"
      key="${id}|${manager}"
      if [ -z "${seen[$key]:-}" ]; then
        order+=("$key")
        seen[$key]=1
      fi
      rows[$key]="${id}"$'\t'"${manager}"$'\t'"${package}"$'\t'"${policy}"$'\t'"${version}"$'\t'"${required}"$'\t'"${note}"$'\t'"${source}"
    done < "$file"
  done

  for key in "${order[@]}"; do
    printf '%s\n' "${rows[$key]}"
  done
}

catalog_write_install_manifest() {
  local core_file="$1" profile_file="$2" out_file="$3"
  local id manager package policy version required note source active_manager
  active_manager="$(catalog_detect_manager)"
  : > "$out_file"
  while IFS=$'\t' read -r id manager package policy version required note source; do
    [ -n "${package:-}" ] || continue
    catalog_manager_applies "$manager" "$active_manager" || continue
    case "$manager" in
      auto|any)
        if [ -n "$version" ] && [ "$version" != "-" ]; then
          printf '%s=%s\n' "$package" "$version" >> "$out_file"
        else
          printf '%s\n' "$package" >> "$out_file"
        fi
        ;;
      *)
        if [ -n "$version" ] && [ "$version" != "-" ]; then
          printf '%s:%s=%s\n' "$manager" "$package" "$version" >> "$out_file"
        else
          printf '%s:%s\n' "$manager" "$package" >> "$out_file"
        fi
        ;;
    esac
  done < <(catalog_merge_files "$core_file" "$profile_file")
}

catalog_version_ge() {
  local left="$1" right="$2"
  if command -v dpkg >/dev/null 2>&1; then
    dpkg --compare-versions "$left" ge "$right"
    return $?
  fi
  [ "$(printf '%s\n%s\n' "$right" "$left" | sort -V | head -n1)" = "$right" ]
}

catalog_version_eq() {
  [ "$1" = "$2" ]
}

catalog_detect_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    printf 'apt\n'
    return
  fi
  if command -v dnf >/dev/null 2>&1; then
    printf 'dnf\n'
    return
  fi
  if command -v pacman >/dev/null 2>&1; then
    printf 'pacman\n'
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    printf 'brew\n'
    return
  fi
  printf 'unknown\n'
}

catalog_manager_applies() {
  local manager="$1" active="$2"
  case "$manager" in
    auto|any) return 0 ;;
    "$active") return 0 ;;
    *) return 1 ;;
  esac
}

catalog_installed_version() {
  local manager="$1" package="$2"
  case "$manager" in
    apt)
      command -v dpkg-query >/dev/null 2>&1 || { printf ''; return 0; }
      dpkg-query -W -f='${Version}\n' "$package" 2>/dev/null || true
      ;;
    brew)
      [ "${CATALOG_SKIP_BREW:-0}" = "1" ] && { printf ''; return 0; }
      command -v brew >/dev/null 2>&1 || { printf ''; return 0; }
      HOMEBREW_NO_AUTO_UPDATE=1 brew list --versions "$package" 2>/dev/null | awk '{print $2}'
      ;;
    dnf)
      command -v rpm >/dev/null 2>&1 || { printf ''; return 0; }
      rpm -q --qf '%{VERSION}-%{RELEASE}\n' "$package" 2>/dev/null || true
      ;;
    pacman)
      command -v pacman >/dev/null 2>&1 || { printf ''; return 0; }
      pacman -Q "$package" 2>/dev/null | awk '{print $2}'
      ;;
    *)
      printf ''
      ;;
  esac
}

catalog_resolve_auto_entry() {
  local package="$1" version
  for manager in apt brew dnf pacman; do
    case "$manager" in
      apt) command -v dpkg-query >/dev/null 2>&1 || continue ;;
      brew) command -v brew >/dev/null 2>&1 || continue ;;
      dnf) command -v rpm >/dev/null 2>&1 || continue ;;
      pacman) command -v pacman >/dev/null 2>&1 || continue ;;
    esac
    version="$(catalog_installed_version "$manager" "$package")"
    if [ -n "$version" ]; then
      printf '%s\t%s\n' "$manager" "$version"
      return 0
    fi
  done
  printf 'auto\t\n'
}

catalog_entry_status() {
  local policy="$1" requested="$2" resolved="$3" required="$4"

  if [ -z "$resolved" ]; then
    if [ "${required:-1}" = "1" ]; then
      printf 'missing\terror\tinstall\n'
    else
      printf 'unavailable\twarn\treview\n'
    fi
    return 0
  fi

  case "$policy" in
    exact)
      if catalog_version_eq "$resolved" "$requested"; then
        printf 'matched\tinfo\tnone\n'
      else
        printf 'version_mismatch\terror\tpin\n'
      fi
      ;;
    minimum)
      if catalog_version_ge "$resolved" "$requested"; then
        if catalog_version_eq "$resolved" "$requested"; then
          printf 'matched\tinfo\tnone\n'
        else
          printf 'newer_ok\tinfo\tnone\n'
        fi
      else
        printf 'below_minimum\terror\tinstall\n'
      fi
      ;;
    preferred)
      if [ -z "$requested" ] || [ "$requested" = "-" ]; then
        printf 'matched\tinfo\tnone\n'
      elif catalog_version_eq "$resolved" "$requested"; then
        printf 'matched\tinfo\tnone\n'
      else
        printf 'preferred_miss\twarn\treview\n'
      fi
      ;;
    floating|*)
      printf 'matched\tinfo\tnone\n'
      ;;
  esac
}

catalog_write_audit_outputs() {
  local core_file="$1" profile_file="$2" apt_file="$3" brew_file="$4" resolved_out="$5" report_out="$6"
  local id manager package policy requested required note source resolved_manager resolved_version status level action resolved_for_status active_manager
  declare -A tracked_keys=()
  active_manager="$(catalog_detect_manager)"

  {
    printf 'id\tmanager\tpackage\tpolicy\trequested_version\tresolved_version\trequired\tsource\tstatus\n'
    while IFS=$'\t' read -r id manager package policy requested required note source; do
      [ -n "${package:-}" ] || continue
      catalog_manager_applies "$manager" "$active_manager" || continue
      if [ "$manager" = "auto" ] || [ "$manager" = "any" ]; then
        IFS=$'\t' read -r resolved_manager resolved_version <<< "$(catalog_resolve_auto_entry "$package")"
      else
        resolved_manager="$manager"
        resolved_version="$(catalog_installed_version "$manager" "$package")"
      fi
      IFS=$'\t' read -r status level action <<< "$(catalog_entry_status "$policy" "$requested" "$resolved_version" "$required")"
      if [ -n "$resolved_version" ] && [ "$resolved_manager" != "auto" ]; then
        tracked_keys["${resolved_manager}|${package}"]=1
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$id" "$resolved_manager" "$package" "$policy" "$requested" "${resolved_version:--}" "$required" "$source" "$status"
    done < <(catalog_merge_files "$core_file" "$profile_file")
  } > "$resolved_out"

  set +e
  {
    printf 'level\tid\tmanager\tpackage\tpolicy\trequested_version\tresolved_version\tstatus\taction\n'
    while IFS=$'\t' read -r id manager package policy requested resolved_version required source status; do
      [ "$id" = "id" ] && continue
      resolved_for_status="$resolved_version"
      [ "$resolved_for_status" = "-" ] && resolved_for_status=""
      IFS=$'\t' read -r _ level action <<< "$(catalog_entry_status "$policy" "$requested" "$resolved_for_status" "$required")"
      if [ "$status" != "matched" ] && [ "$status" != "newer_ok" ]; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "$level" "$id" "$manager" "$package" "$policy" "$requested" "$resolved_version" "$status" "$action"
      fi
    done < "$resolved_out"

    if [ -f "$apt_file" ]; then
      while read -r package version _; do
        [ -n "${package:-}" ] || continue
        if [ -z "${tracked_keys["apt|$package"]:-}" ]; then
          printf 'warn\t%s\tapt\t%s\tfloating\t-\t%s\textra_untracked\tadd-manifest\n' \
            "$package" "$package" "${version:-present}"
        fi
      done < "$apt_file"
    fi

    if [ -f "$brew_file" ]; then
      while read -r package version _; do
        [ -n "${package:-}" ] || continue
        if [ -z "${tracked_keys["brew|$package"]:-}" ]; then
          printf 'warn\t%s\tbrew\t%s\tfloating\t-\t%s\textra_untracked\tadd-manifest\n' \
            "$package" "$package" "${version:-present}"
        fi
      done < "$brew_file"
    fi
  } > "$report_out"
  set -e
  return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  core="${1:-}"
  profile="${2:-}"
  if [ -z "$core" ]; then
    printf 'usage: %s <core-catalog> [profile-catalog]\n' "$(basename "$0")" >&2
    exit 2
  fi
  catalog_merge_files "$core" "$profile"
fi
