
hostrun_runner_build_inject() {
  local host_line; host_line="$1"
  local pair
  local key
  local val
  for pair in $host_line; do
    key="${pair%%=*}"
    val="${pair#*=}"
    printf 'declare hostrun_%s=%q\n' "$key" "$val"
  done
}

hostrun_runner_build_env_inject() {
  local env_file; env_file="$1"
  [ -z "$env_file" ] && return 0
  if [ ! -f "$env_file" ]; then
    echo "hostrun: env file not found: $env_file" >&2
    return 1
  fi
  local line
  local key
  local val
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|\#*) continue ;; esac
    key="${line%%=*}"
    val="${line#*=}"
    case "$val" in
      \"*\") val="${val#\"}"; val="${val%\"}" ;;
      \'*\') val="${val#\'}"; val="${val%\'}" ;;
    esac
    printf 'declare %s=%q\n' "$key" "$val"
  done < "$env_file"
}

hostrun_runner_attach() {
  local host_line; host_line="$1"

  local host; host=$(hostrun_hosts_get_field "$host_line" "host")
  local user; user=$(hostrun_hosts_get_field "$host_line" "user")
  local password; password=$(hostrun_hosts_get_field "$host_line" "password")
  local name; name=$(hostrun_hosts_get_field "$host_line" "name")

  if [ -z "$user" ]; then
    user="$USER"
  fi

  if [ "$host" = "0.0.0.0" ] || [ "$name" = "local" ]; then
    exec bash --login
  fi

  local ssh_opts; ssh_opts="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

  if [ -n "$password" ]; then
    exec sshpass -p "$password" ssh -tt $ssh_opts "${user}@${host}"
  else
    exec ssh -tt $ssh_opts "${user}@${host}"
  fi
}

hostrun_runner_exec() {
  local host_line; host_line="$1"
  local script_file; script_file="$2"
  local mode; mode="${3:-script}"
  local env_file; env_file="$4"

  local host; host=$(hostrun_hosts_get_field "$host_line" "host")
  local user; user=$(hostrun_hosts_get_field "$host_line" "user")
  local password; password=$(hostrun_hosts_get_field "$host_line" "password")
  local name; name=$(hostrun_hosts_get_field "$host_line" "name")

  if [ -z "$user" ]; then
    user="$USER"
  fi

  local inject; inject=$(hostrun_runner_build_inject "$host_line")
  local env_inject; env_inject=$(hostrun_runner_build_env_inject "$env_file") || return 1

  if [ "$host" = "0.0.0.0" ] || [ "$name" = "local" ]; then
    { printf '%s\n' "$inject" "$env_inject"; cat "$script_file"; } | bash -s
    return $?
  fi

  local ssh_opts; ssh_opts="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  local payload
  payload=$({ printf '%s\n' "$inject" "$env_inject"; cat "$script_file"; } | base64 -w0)

  if [ -n "$password" ]; then
    sshpass -p "$password" ssh -tt $ssh_opts "${user}@${host}" "echo ${payload} | base64 -d | bash"
  else
    ssh -tt $ssh_opts "${user}@${host}" "echo ${payload} | base64 -d | bash"
  fi
}