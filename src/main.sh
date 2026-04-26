module hosts
module runner

main() {
  if [ "$1" = "--list" ]; then
    hostrun_hosts_list
    return $?
  fi

  local host_name; host_name="$1"
  local script_file
  local tmp_script
  local mode; mode="script"
  local env_file

  if [ -z "$host_name" ]; then
    echo "Usage: hostrun <hostname> <script.sh> [--env-file <file>]" >&2
    echo "       hostrun <hostname> -c \"command;\" [--env-file <file>]" >&2
    echo "       hostrun <hostname> --attach" >&2
    echo "       hostrun --list" >&2
    exit 1
  fi

  if [ "$2" = "--attach" ]; then
    local host_line
    host_line=$(hostrun_hosts_find "$host_name") || exit 1
    hostrun_runner_attach "$host_line"
    return $?
  fi

  if [ "$2" = "-c" ]; then
    if [ -z "$3" ]; then
      echo "hostrun: -c requires a command string" >&2
      exit 1
    fi
    tmp_script=$(mktemp /tmp/hostrun.XXXXXX)
    echo "$3" > "$tmp_script"
    script_file="$tmp_script"
    mode="command"
    [ "$4" = "--env-file" ] && env_file="$5"
  else
    script_file="$2"
    if [ -z "$script_file" ]; then
      echo "Usage: hostrun <hostname> <script.sh> [--env-file <file>]" >&2
      exit 1
    fi
    if [ ! -f "$script_file" ]; then
      echo "hostrun: script file not found: $script_file" >&2
      exit 1
    fi
    [ "$3" = "--env-file" ] && env_file="$4"
  fi

  local host_line
  host_line=$(hostrun_hosts_find "$host_name") || exit 1

  hostrun_runner_exec "$host_line" "$script_file" "$mode" "$env_file"
  local exit_code; exit_code=$?

  [ -n "$tmp_script" ] && rm -f "$tmp_script"

  return $exit_code
}