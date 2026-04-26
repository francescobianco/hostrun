# hostrun

Low-level provisioning over SSH. Run bash scripts on remote hosts with zero dependencies on the target — only `bash` and `sshd` required.

## Philosophy

Most provisioning tools demand something from the target: Ansible needs Python, Salt needs a daemon, Puppet needs an agent. When you're managing a handful of VPS instances, a homelab, or ARM single-board computers, installing and maintaining that overhead defeats the purpose.

`hostrun` takes the opposite approach: the only thing a host needs is a running SSH server and bash. Scripts are piped via stdin and executed in memory — no files are copied, no agents are installed, no state is maintained on the target.

This makes `hostrun` the right tool for **low-level provisioning**: bootstrapping bare servers, managing small fleets (1–20 hosts), running maintenance tasks on heterogeneous environments, or any situation where keeping the infrastructure simple is a requirement, not a compromise.

It is intentionally **not** designed for large-scale provisioning. If you're managing dozens of nodes, need idempotency guarantees, or want a full declarative model, reach for [Ansible](https://www.ansible.com) or [Terraform](https://www.terraform.io). `hostrun` is what you use before you need those tools — or instead of them, when you never do.

## Installation

```bash
mush build --release
cp target/release/hostrun /usr/local/bin/hostrun
```

## The `.hosts` file

`hostrun` reads host definitions from `~/.hosts`. Each line defines one host as a sequence of `key=value` pairs separated by spaces.

```
host=0.0.0.0        name=local
host=192.168.1.10   name=webserver  user=deploy    password=changeme
host=192.168.1.20   name=dbserver
host=203.0.113.5    name=vps        user=root      password=changeme
host=203.0.113.6    name=vps2       user=root      password=changeme  client_id=42
```

Lines without a `name=` key are ignored by `hostrun`.

### Reserved keys

| Key        | Description                                              |
|------------|----------------------------------------------------------|
| `host`     | IP address or hostname                                   |
| `name`     | Identifier used on the command line (required)           |
| `user`     | SSH username (defaults to the current local user)        |
| `password` | SSH password — uses `sshpass` under the hood             |

If `password` is absent, `hostrun` falls back to key-based authentication.

The special host `name=local` (or `host=0.0.0.0`) runs scripts locally without SSH.

### Multi-line entries

Long host lines can be split across multiple lines using a trailing backslash:

```
host=203.0.113.6  name=vps2  user=root  password=changeme \
  client_id=42    env=production        region=eu-west
```

The backslash must be the last character of the line (no trailing space). The continuation line is joined and parsed as a single entry.

### Custom keys and variable injection

Any extra key on a host line is automatically available inside your scripts as `hostrun_<key>`:

```
host=203.0.113.6  name=vps2  user=root  password=changeme  client_id=42  env=production
```

Inside `deploy.sh` running on that host:

```bash
echo "Deploying to $hostrun_env (client $hostrun_client_id) on $hostrun_host"
```

The standard keys (`host`, `name`, `user`, `password`) are injected too:

| Variable              | Value from example   |
|-----------------------|----------------------|
| `$hostrun_host`       | `203.0.113.6`        |
| `$hostrun_name`       | `vps2`               |
| `$hostrun_user`       | `root`               |
| `$hostrun_client_id`  | `42`                 |
| `$hostrun_env`        | `production`         |

Variables are declared via a `declare` header prepended to your script before it is piped to the remote bash process. No boilerplate required in your scripts.

### Limitation: no spaces in values

Variable values **cannot contain spaces**. This is an intentional design constraint — the `.hosts` format is deliberately kept simple and parseable with basic tools. If your use case requires values with spaces or complex data structures, `hostrun` is not the right tool for that part of the job.

## Usage

```bash
# Run a script file on a remote host
hostrun <hostname> <script.sh>

# Run an inline command (allocates a PTY — interactive commands work)
hostrun <hostname> -c "command; command;"

# List all named hosts
hostrun --list
```

### Examples

```bash
# Run a provisioning script on a VPS
hostrun proxy setup.sh

# Check disk usage interactively
hostrun tools -c "df -h"

# Run htop on a remote host
hostrun orangepi -c "htop"

# List all configured hosts
hostrun --list
```

## How it works

Scripts are never copied to the remote host. They are streamed via stdin and executed directly:

```bash
# Under the hood (password-based)
sshpass -p "$password" ssh user@host 'bash -s' < script.sh

# Key-based
ssh user@host 'bash -s' < script.sh
```

Before the script content, `hostrun` prepends a block of `declare` statements for every variable on the host line:

```bash
declare hostrun_host=74.208.245.19
declare hostrun_name=proxy
declare hostrun_user=root
declare hostrun_client_id=42
# ... then your script follows
```

For inline commands (`-c`), SSH is invoked with `-tt` to force pseudo-terminal allocation, enabling interactive programs like `top`, `htop`, or `vim` to work correctly even when stdin is a pipe.

## Built with

- [Mush](https://mush.javanile.org) — shell package manager