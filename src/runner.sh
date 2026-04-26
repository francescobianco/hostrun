
hostrun_runner_exec() {
  local host_line; host_line="$1"
  local script_file; script_file="$2"

  local host; host=$(hostrun_hosts_get_field "$host_line" "host")
  local user; user=$(hostrun_hosts_get_field "$host_line" "user")
  local password; password=$(hostrun_hosts_get_field "$host_line" "password")
  local name; name=$(hostrun_hosts_get_field "$host_line" "name")

  if [ -z "$user" ]; then
    user="$USER"
  fi

  if [ "$host" = "0.0.0.0" ] || [ "$name" = "local" ]; then
    bash "$script_file"
    return $?
  fi

  local ssh_opts; ssh_opts="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

  if [ -n "$password" ]; then
    sshpass -p "$password" ssh $ssh_opts "${user}@${host}" 'bash -s' < "$script_file"
  else
    ssh $ssh_opts -o BatchMode=yes "${user}@${host}" 'bash -s' < "$script_file"
  fi
}