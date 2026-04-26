
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

  local host; host=$(hostrun_hosts_get_field "$host_line" "host")
  local user; user=$(hostrun_hosts_get_field "$host_line" "user")
  local password; password=$(hostrun_hosts_get_field "$host_line" "password")
  local name; name=$(hostrun_hosts_get_field "$host_line" "name")

  if [ -z "$user" ]; then
    user="$USER"
  fi

  local inject; inject=$(hostrun_runner_build_inject "$host_line")

  if [ "$host" = "0.0.0.0" ] || [ "$name" = "local" ]; then
    { printf '%s\n' "$inject"; cat "$script_file"; } | bash -s
    return $?
  fi

  local ssh_opts; ssh_opts="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  local tty_flag; tty_flag=""
  [ "$mode" = "command" ] && tty_flag="-tt"

  if [ -n "$password" ]; then
    { printf '%s\n' "$inject"; cat "$script_file"; } | \
      sshpass -p "$password" ssh $tty_flag $ssh_opts "${user}@${host}" 'bash -s'
  else
    { printf '%s\n' "$inject"; cat "$script_file"; } | \
      ssh $tty_flag $ssh_opts "${user}@${host}" 'bash -s'
  fi
}