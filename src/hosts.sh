
hostrun_hosts_get_field() {
  local line; line="$1"
  local field; field="$2"
  echo "$line" | grep -oP "(?<=${field}=)\S+" || true
}

hostrun_hosts_parse() {
  local hosts_file; hosts_file="${HOME}/.hosts"
  awk '/\\$/ { sub(/\\$/, ""); printf "%s", $0; next } 1' "$hosts_file"
}

hostrun_hosts_list() {
  local hosts_file; hosts_file="${HOME}/.hosts"

  if [ ! -f "$hosts_file" ]; then
    echo "hostrun: hosts file not found: $hosts_file" >&2
    return 1
  fi

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local name; name=$(hostrun_hosts_get_field "$line" "name")
    local host; host=$(hostrun_hosts_get_field "$line" "host")
    local user; user=$(hostrun_hosts_get_field "$line" "user")
    [ -n "$name" ] && printf "%-20s %s\n" "$name" "${user:+${user}@}${host}"
  done < <(hostrun_hosts_parse)
}

hostrun_hosts_find() {
  local name; name="$1"
  local hosts_file; hosts_file="${HOME}/.hosts"

  if [ ! -f "$hosts_file" ]; then
    echo "hostrun: hosts file not found: $hosts_file" >&2
    return 1
  fi

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local entry_name; entry_name=$(hostrun_hosts_get_field "$line" "name")
    if [ "$entry_name" = "$name" ]; then
      echo "$line"
      return 0
    fi
  done < <(hostrun_hosts_parse)

  echo "hostrun: host not found: $name" >&2
  return 1
}