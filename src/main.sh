module hosts
module runner

main() {
  local host_name; host_name="$1"
  local script_file
  local tmp_script

  if [ -z "$host_name" ]; then
    echo "Usage: hostrun <hostname> <script.sh>" >&2
    echo "       hostrun <hostname> -c \"command; command;\"" >&2
    exit 1
  fi

  if [ "$2" = "-c" ]; then
    if [ -z "$3" ]; then
      echo "hostrun: -c requires a command string" >&2
      exit 1
    fi
    tmp_script=$(mktemp /tmp/hostrun.XXXXXX)
    echo "$3" > "$tmp_script"
    script_file="$tmp_script"
  else
    script_file="$2"
    if [ -z "$script_file" ]; then
      echo "Usage: hostrun <hostname> <script.sh>" >&2
      echo "       hostrun <hostname> -c \"command; command;\"" >&2
      exit 1
    fi
    if [ ! -f "$script_file" ]; then
      echo "hostrun: script file not found: $script_file" >&2
      exit 1
    fi
  fi

  local host_line
  host_line=$(hostrun_hosts_find "$host_name") || exit 1

  hostrun_runner_exec "$host_line" "$script_file"
  local exit_code; exit_code=$?

  [ -n "$tmp_script" ] && rm -f "$tmp_script"

  return $exit_code
}