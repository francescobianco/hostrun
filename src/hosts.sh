
hostrun_hosts_get_field() {
  local line; line="$1"
  local field; field="$2"
  echo "$line" | grep -oP "(?<=${field}=)\S+"
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
  done < "$hosts_file"

  echo "hostrun: host not found: $name" >&2
  return 1
}