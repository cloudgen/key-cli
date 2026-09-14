# sshd-cli - Simplify Termux to install sshd

![Version](https://img.shields.io/badge/Version-1.20.0-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/sshd-cli?style=flat-square)](https://github.com/cloudgen/sshd-cli)

**sshd-cli** makes it simple on **Termux** to install and run OpenSSH **sshd**. One program, one login, no systemd.

| You | The other role | Not this |
|-----|----------------|----------|
| A Termux login that wants SSH *into* this phone | OpenSSH `sshd` and its files under `$PREFIX/etc/ssh` | A systemd unit editor, a `termux-services` wrapper, a `sudo` wrapper, or an SSH session mux / ProxyJump helper |

| Includes | Excludes |
|----------|----------|
| Install this helper, then start sshd as a **background daemon** (Termux often listens on **8022**) | Wrapping `sudo` inside the CLI; systemd / termux-services / cron-as-service |
| Host keys and this login’s `authorized_keys` | Dropbear-only hosts; wrapping `apt` on Linux; firewall changes; a Termux:Boot installer |
| This login’s `~/.ssh/config` Host list (`dns`); `ssh` / `download` using those Host aliases | `/etc/hosts`; `Host *`; SSH session mux |

| Step | What it means | What you type |
|------|---------------|---------------|
| Install the helper | Puts `sshd-cli` on your PATH so later sshd steps are one command. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli \| sh` |
| Install OpenSSH on Termux | Termux does not ship `sshd` until you ask. | `sshd-cli install` (runs `pkg install openssh termux-auth`) |
| Start sshd | OpenSSH **forks itself** so a laptop can connect. Default Termux port is often **8022**. This is not a boot service. | `sshd-cli start` then `ssh -p 8022 user@host` |
| After a reboot | The daemon is gone. Start again. Termux:Boot is **your** hook if you want listen-after-reboot. | `sshd-cli start` |

Runtime version SSOT: `VERSION="1.20.0"` in `./sshd-cli`. Install channel SSOT: `SCRIPT_URL` default `https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli`. Philosophy: **[CIAO](https://github.com/cloudgen/ciao) v2.10.2** with [CIAO-Lite](https://github.com/cloudgen/ciao-lite). Specialized from bootstrap origin **selfmanaged** (A → B only).

## Features

- One file you can run or install with `curl | sh` / `wget`
- Places itself for this login (`~/.local/bin`) or, on a **root login**, under `/usr/local/bin` (Termux: `$PREFIX/bin`)
- On a **terminal**, no arguments opens a numbered **menu**; under a **pipe** (`curl | sh`, quiet, json) it **installs itself** (not help)
- Purpose: **simplify Termux to install sshd** (`status`, `start`, `stop`, `restart`, `port`, `config`, `host-keys`, `auth-keys`)
- On POSIX Linux (not Termux / Git Bash / Windows cmd), the TTY menu shows **start / stop / restart** (rows **2** / **3** / **4**) **only as root**. A non-root login sees an INFO line naming this OS, then rows **1**, **5**, **6** (`ssh`), **7** (`download`), **8**–**10**, **99**. Typed `start` / `stop` / `restart` still fail closed without wrapping `sudo`
- `start` launches OpenSSH sshd as a **background daemon** (`sshd -f`) on Termux and on Linux with **no** distro unit. On POSIX Linux with a loaded `ssh.service` / `sshd.service`, `start` / `stop` / `restart` call **`systemctl`** as a **root login** (no in-tool `sudo`; no `sshd-cli systemctl` verb)
- On Termux, `start` also acquires an **Android wake lock** so sshd can keep listening with the screen off. Acquire again with `sshd-cli wake-lock` if Android dropped it. `wake-unlock` is optional and does **not** run on `stop`
- After a reboot on Termux, run `sshd-cli start` again. Listen-after-reboot on Termux is **Termux:Boot** (you own `~/.termux/boot/`) — not a `sshd-cli` verb. On POSIX Linux, listen-after-reboot is the distro sshd unit
- This login’s `~/.ssh/config` **Host** list (`dns`, TTY menu row **5**): action menu **Edit / Add / Delete / Unset**, then a Host pick; TTY **as Termux (Y/n)** (Port 8022, simpler Ciphers/MACs, keep-alives — some Termux sshd versions otherwise **corrupt** the session), **identity-file** / **identities-only**, **Old OpenSSH (Y/n)** (`ssh-rsa` / `ssh-dss`); `""` means empty; `dns unset <name> user` drops extra settings (not the Host name or address); `--json` / pipes list or `set` / `delete` / `unset` without hanging
- **`ssh`** (TTY menu row **6**): pick a Host from that numbered list, then **user** with default (Host `User`, else this login). **`download`** (row **7**): pick a Host, then **user** with the same default, then a remote folder (numbered previous paths for that Host, or type a new path — absolute, relative, or `~/folder`); tar.gz over ssh and extract into the current directory
- On POSIX Linux, `backup-config` copies this login `~/.ssh/config` to `/var/sshd-cli`; `sync-config` copies it back (mode 600). `sync-from-remote` scp’s that store from another host. Termux / Git Bash / Windows cmd hide those rows and print an INFO line
- Termux-first paths (`PREFIX`); Linux system sshd is a second home and asks for a **root login** instead of wrapping `sudo`
- Online install / self-update fetches a SHA-256 sidecar (`${SCRIPT_URL}.sha256`) and tells you link, value, and result
- Built under **[CIAO](https://github.com/cloudgen/ciao) v2.10.*** (fail closed; one printer family for messages)

## Quick Installation

### Online (recommended)

**Per-user (non-root):**

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli | sh
```

**POSIX Linux, already a root login** (not Termux, Git Bash, or Windows cmd). Same one-liner **as root** — do **not** use `sudo curl | sh` on Termux:

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli | sh
```

Then verify:

```sh
sshd-cli about
sshd-cli status
```

### Integrity (automatic checksum)

The program downloads the companion digest **itself**. You do **not** set `CHECKSUM` for normal online install or self-update.

| Mode | When | Algorithm | What happens |
|------|------|-----------|--------------|
| **Automatic (default)** | `CHECKSUM` **unset** | **SHA-256** via `sha256sum` | Fetch `${SCRIPT_URL}.sha256`. Human mode shows companion **link**, expected **value**, and **result**. **Match** → continue. **Mismatch** → **abort**. **Sidecar missing** → **warning**, continue. |
| **Strict pin (optional)** | `CHECKSUM` set to an out-of-band hex digest | **SHA-256** | Must match the pin; mismatch aborts. CI / freeze only. |

Default companion:

```text
https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli.sha256
```

In this repository the companion file is **`sshd-cli.sha256`**. Same-channel SHA-256 proves **consistency** of the two files on that channel; it is not a substitute for signed releases.

### From a local checkout

```sh
chmod +x ./sshd-cli
./sshd-cli install
sshd-cli about
```

On Termux, `install` also ensures OpenSSH and `termux-auth` (`pkg install -y openssh termux-auth`), creates `~/.bashrc` if missing (PATH), and creates `~/.profile` if missing so an SSH login sources `~/.bashrc`. If you will use a password to SSH in, set one with `passwd`. Tests/CI may set `BASHRC` to a file path (default `~/.bashrc`) so PATH ensure does not touch this login's real interactive rc. The test-purpose verb `sshd-cli rc-test --root <dir> --file bashrc --case create` proves the same helpers against a throw-away folder.

After install, on a terminal (no arguments opens the menu). Front board (every host):

```text
$ sshd-cli
[INFO] **sshd-cli**(*1.20.0*)
1. **client-side**: *this login OpenSSH client (~/.ssh/config, ssh, folders)*
2. **server-side**: *this host OpenSSH sshd (listen, keys, port)*
8. **self-management**: *this CLI install, version, update, uninstall*
9. Exit
Choose a number, or type the command name:
```

`1` opens client-side (Termux class):

```text
[INFO] **sshd-cli**(*1.20.0*) — client-side
[INFO] backup-config and sync-config not available for termux
11. **dns**: *this login ~/.ssh/config Host list*
12. **ssh**: *OpenSSH client to a Host from this login ~/.ssh/config*
13. **download**: *tar.gz a remote folder into this directory*
18. **sync-from-remote**: *copy /var/sshd-cli/config from user@host (or host)*
0. Back
```

POSIX Linux client-side numbers **15 backup-config**, **16 sync-config**, **17 sudoers** (type `sync-from-remote`). `11` then opens dns **111 Edit / 112 Add / 113 Delete / 114 Unset**, **0** Back.

`2` opens server-side (Termux class shows **22 start / 23 stop / 24 restart**). POSIX Linux non-root:

```text
[INFO] **sshd-cli**(*1.20.0*) — server-side
[INFO] start/stop/restart sshd features are not available for non-root in Ubuntu
21. **status**: *running, port, and paths*
0. Back
```

`8` opens self-management (**81 install** … **86 self-uninstall**). **0** goes back. **9** on the front board leaves. A wrong number reprints **that** list.

## Usage

```sh
sshd-cli help
sshd-cli version
sshd-cli about
sshd-cli status
sshd-cli start
sshd-cli wake-lock
sshd-cli wake-unlock
sshd-cli stop
sshd-cli restart
sshd-cli port
sshd-cli port 8022
sshd-cli config
sshd-cli host-keys generate
sshd-cli auth-keys add ./laptop.pub
sshd-cli dns
sshd-cli dns list
sshd-cli dns show 1
sshd-cli dns set 1 ip 192.168.1.10 user "" port 8022
sshd-cli dns add dns phone ip 192.168.1.10 termux yes old-openssh yes
sshd-cli dns delete 1
sshd-cli dns unset 1 user
sshd-cli ssh
sshd-cli ssh 1
sshd-cli download
sshd-cli download phone /opt/app
sshd-cli download phone ~/box/app
sshd-cli backup-config
sshd-cli sync-config
sshd-cli sync-from-remote
sshd-cli sync-from-remote user@host
sshd-cli menu
```

Self-management (this login, no OS package manager): `install`, `version-check`, `self-update`, `self-uninstall`.

Global flags: `--quiet` / `-q`, `--json`, `--debug`, `--force`.

## Examples

```sh
# See whether sshd is running (Termux often listens on 8022)
sshd-cli status

# Start it (OpenSSH forks into the background), then connect from a laptop
sshd-cli start
ssh -p 8022 "$(id -un)"@192.0.2.10

# If Android dropped the wake lock (screen off killed Termux), acquire again
sshd-cli wake-lock

# Allow a laptop public key
sshd-cli auth-keys add ./laptop.pub

# After a reboot, start the daemon again (this CLI is not a boot service)
sshd-cli start

# Optional: Termux:Boot — you own ~/.termux/boot/; this CLI has no enable-service verb
mkdir -p ~/.termux/boot
printf '%s\n' 'sshd-cli start' > ~/.termux/boot/start-sshd
chmod +x ~/.termux/boot/start-sshd

# This login's SSH names (OpenSSH client ~/.ssh/config)
sshd-cli dns list
sshd-cli dns show 1
sshd-cli dns set 1 ip 192.168.1.10 user "" port 8022
sshd-cli dns add dns phone ip 192.168.1.10 termux yes old-openssh yes identity-file '~/.ssh/phone' identities-only yes
sshd-cli dns delete 1
sshd-cli dns unset 1 user
sshd-cli ssh phone
sshd-cli download phone /opt/app
sshd-cli download phone ~/box/app
sshd-cli backup-config
sshd-cli sync-config
sshd-cli sync-from-remote user@host
```

`--json` prints machine objects (`sshd-cli --json status`).

## Platform Compatibility

| Platform | Status |
|----------|--------|
| Termux (Android, OpenSSH via `pkg install openssh`) | Primary target — this login only; no `sudo curl` |
| POSIX Linux with OpenSSH server | Supported; system sshd start/stop/port/host-keys need a **root login** |
| Git Bash / Windows cmd | Same “this login only” class as Termux: no `pkg`, no in-tool `sudo` |
| Windows OpenSSH (host) | Companion script: install sshd and allow a **normal (non-admin) user** to SSH in, with Git Bash or PowerShell as the session shell |
| Other UNIX with `/bin/sh`, `sha256sum`, `mktemp` | CLI install as this login should work; sshd paths follow POSIX defaults |

On **Termux**, `sshd-cli start` is a **background daemon for this session** (OpenSSH forks itself). Leaving the shell is fine. A reboot, or Android killing Termux, ends the daemon — run `start` again. `start` also acquires an Android wake lock so the CPU can stay awake with the screen off; if Android dropped it, run `sshd-cli wake-lock`. Listen-after-reboot is **Termux:Boot** (operator hook).

On a **Linux** server with a loaded distro unit (`ssh.service` or `sshd.service`), `sshd-cli start` / `stop` / `restart` as **root** call `systemctl` on that unit. Listen-after-reboot is the distro unit. There is no `sshd-cli systemctl` command and no in-tool `sudo`. Non-root logins fail closed: re-run as root.

### Windows OpenSSH (normal user + Git Bash)

Windows OpenSSH is **not** a `sshd-cli` verb. Use the companion script so a **non-admin** local user can SSH in (Administrators use a different authorized_keys file under ProgramData). The script is host setup: it self-elevates with UAC.

**PowerShell:**

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup-windows-ssh-server.ps1
```

**Git Bash** (same folder):

```sh
./setup-windows-ssh-server.sh
# or:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w ./setup-windows-ssh-server.ps1)"
```

Named arguments (still UAC):

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup-windows-ssh-server.ps1 -User sshuser -Shell GitBash -PublicKeyFile %USERPROFILE%\.ssh\id_ed25519.pub -SkipPause
```

`-Shell` is `GitBash` (Git for Windows `bash.exe`, not `git-bash.exe`), `PowerShell`, `Pwsh`, `Cmd`, or `Ask`. After setup, from Linux or another Git Bash: `ssh <user>@<windows-lan-ip>`.

On **Git Bash** (detect: `MSYSTEM` or `uname` MINGW/MSYS — not `$0=/bin/bash`, not `[ -d /c/ ]`), native Windows console programs need **winpty**: `winpty grok`, `winpty powershell.exe`. Do not wrap `git` or piped/`--json` runs. `HOME` looking like `/c/…` is typical after detect, not the check.

## Related Projects

- [selfmanaged](https://github.com/cloudgen/selfmanaged) — bootstrap origin (install / self-update / self-uninstall as this login)
- [CIAO](https://github.com/cloudgen/ciao) — defensive programming philosophy
- [CIAO-Lite](https://github.com/cloudgen/ciao-lite) — agent contract

## Contributing

Keep CIAO Protection Zones. Do not reverse-copy this product onto `selfmanaged`. Run `./tests/run.sh` before claiming a change done. Product law lives under `docs/requirements/`.

## License

MIT. See [`LICENSE.md`](./LICENSE.md). Copyright (c) 2026 Cloudgen Wong.

## Last Update

2026-09-14 — 1.20.0: TTY menu is a tree (1 client-side, 2 server-side, 8 self-management; children keep the parent number; 0 Back). 2026-09-13 — 1.19.2: a wrong TTY menu number warns and shows the same list again. 2026-09-12 — 1.19.1: `download` accepts `~/folder` (remote login home). 2026-09-12 — 1.19.0: TTY `download` asks user with default (same as `ssh`). 2026-09-12 — 1.18.0: TTY menu numbers `ssh` (6) and `download` (7); `ssh` asks user with default. 2026-09-12 — 1.17.0: `ssh` picks a Host from this login `~/.ssh/config`; `download` tar.gz a remote folder into the current directory (remembers paths per Host). 2026-09-12 — 1.16.0: `dns unset` drops extra `~/.ssh/config` settings (user, port, …) without deleting the Host or HostName. 2026-09-11 — 1.15.0: `sync-from-remote` pulls `/var/sshd-cli/config` via scp and remembers last user@host. 2026-09-11 — 1.14.0: `backup-config` / `sync-config` for this-login `~/.ssh/config` (`/var/sshd-cli`); sudoers grant `sudo sshd-cli backup-config`; Termux/Git Bash/Windows cmd hide + INFO. 2026-09-11 — 1.13.4: Git Bash `/dev/shm` mkdir fail-soft; use AppData Local Temp/`cache` with no extra `[ERROR]`. 2026-09-10 — 1.13.3: Windows companion `setup-windows-ssh-server.ps1` (+ Git Bash `.sh` launcher); Git Bash detect is `MSYSTEM`/`uname` (not `$0` or `/c/`); `winpty grok` for Windows consoles. 2026-09-09 — 1.13.2: dns tests mint Host/IP (do not copy this-login LAN identity). 1.13.1: `self-update` is CLI-only (does not fail on `/etc/ssh/sshd_config` / `/run/sshd`). 1.13.0: `rc-test` proves PATH/profile ensure in a temp folder; uninstall keeps a shared PATH while other tools remain.
