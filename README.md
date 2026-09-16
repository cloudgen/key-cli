# key-cli - Backup and restore SSH user keys

![Version](https://img.shields.io/badge/Version-2.1.1-blue?style=flat-square)
[![Stars](https://img.shields.io/github/stars/cloudgen/key-cli?style=flat-square)](https://github.com/cloudgen/key-cli)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)

**key-cli** archives this login’s **`~/.ssh` folder** into a dated `tar.gz` under `/var/key-cli`, restores it, lets login **A** queue a public key for account **B**, and lets the least-privilege operator **key-adm** approve that request (or do the same backup/append **on behalf of other users**). It does **not** install or run OpenSSH sshd.

| You | The other role | Not this |
|-----|----------------|----------|
| A POSIX Linux login that wants a durable copy of `~/.ssh` | `key-adm` (on-behalf) and sudoer-adm (passwordless grant) | An sshd installer, an SSH client Host editor, or a `sudo tar` wrapper |

| Includes | Excludes |
|----------|----------|
| Dated `tar.gz` of `/home/<user>/.ssh` as `root:root` mode `0600` | OpenSSH sshd start/stop; Termux `pkg install openssh` |
| Restore into `/home/<user>/.ssh`; this-login `authorized_keys add` | `dns` / `ssh` / `download` / `upload`; world-readable key archives |
| key-adm: backup another user; append their `authorized_keys`; approve queued public keys | `ALL=(ALL) ALL`; OS-tool sudoers (`tar`/`cp`/`mkdir`) |

| Step | What it means | What you type |
|------|---------------|---------------|
| Install the helper | Puts `key-cli` on your PATH | `curl -fsSL https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli \| sh` |
| Ask for elev | Queue a JSON grant for sudoer-adm | `key-cli generate-sudoer-request` then `key-cli submit-sudoer-request` |
| Archive this login | sudo of the product command writes `/var/key-cli/<user>/ssh-YYYYMMDD-N.tar.gz` | `key-cli backup` |
| Put it back | Extract a named archive | `key-cli restore list` then `key-cli --force restore ssh-YYYYMMDD-N.tar.gz` |

Runtime version SSOT: `VERSION="2.1.1"` in `./key-cli`. Install channel SSOT: `SCRIPT_URL` default `https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli`. Philosophy: **[CIAO](https://github.com/cloudgen/ciao) v2.10.2** with [CIAO-Lite](https://github.com/cloudgen/ciao-lite). Specialized from bootstrap origin **selfmanaged** (A → B only).

## Features

- One file you can run or install with `curl | sh` / `wget`
- Places itself for this login (`~/.local/bin`) or, on a **root login**, under `/usr/local/bin` (Termux: `$PREFIX/bin`)
- On a **terminal**, no arguments opens a numbered **menu**; under a **pipe** (`curl | sh`, quiet, json) it **installs itself** (not help)
- Purpose: **backup / restore SSH user keys** (`backup`, `restore`, `auth-keys`)
- On POSIX Linux, `backup` archives `/home/<user>/.ssh` to `/var/key-cli/<user>/ssh-YYYYMMDD-N.tar.gz` (same-day `N` increments; never overwrite). Deposit uses passwordless `sudo /usr/local/bin/key-cli backup` after sudoer-adm. Archives are **`root:root` mode `0600`**.
- `restore` extracts an archive back into `/home/<user>/.ssh` (non-empty dest needs `--force` or a TTY confirm)
- This login `auth-keys add <file>` appends one public-key line after a **global** `backup` of that user’s `.ssh` (then backups again so the store has the new key)
- This login `auth-keys request <user> <file>` queues JSON under `/var/key-cli/auth-key-request/` so **key-adm** can let you SSH as that account (`pending` / `approve` / `reject` / `interactive`)
- **key-adm** (UID 1666, home `/etc/key-adm`): `backup <user>`, `auth-keys add <user> <file>`, and review of queued public-key requests via sudo of the product command. Create with `key-cli setup` as **root**
- Termux / Git Bash / Windows cmd: backup/restore/sudoers fail closed (Type 1/2 unused). This-login `auth-keys` still works
- Online install / self-update fetches a SHA-256 sidecar (`${SCRIPT_URL}.sha256`) and tells you link, value, and result
- Built under **[CIAO](https://github.com/cloudgen/ciao) v2.10.*** (fail closed; one printer family for messages)

## Quick Installation

### Online (recommended)

**Per-user (non-root):**

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli | sh
```

**POSIX Linux, already a root login.** Same one-liner **as root**:

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli | sh
```

Then verify:

```sh
key-cli about
key-cli help
```

Default companion:

```text
https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli.sha256
```

### From a local checkout

```sh
chmod +x ./key-cli
./key-cli install
key-cli about
```

After install, on a terminal (no arguments opens the menu):

```text
$ key-cli
[INFO] **key-cli**(*2.1.1*)
1. **keys**: *this login ~/.ssh backup, restore, authorized_keys*
8. **self-management**: *this CLI install, version, update, uninstall*
9. Exit
Choose a number, or type the command name:
```

`1` opens keys (POSIX Linux):

```text
[INFO] **key-cli**(*2.1.1*) — keys
11. **backup**: *archive this login ~/.ssh into /var/key-cli*
12. **restore**: *extract an archive back into this login ~/.ssh*
13. **auth-keys**: *this login authorized_keys*
14. **sudoers**: *grant and drafts for passwordless sudo*
15. **request**: *queue a public key so key-adm can let you log in as another account*
0. Back
```

On Termux / Git Bash / Windows cmd the backup/restore/sudoers rows are omitted and an INFO line names that class. Front **2 on-behalf** appears only as **key-adm** (or root). **0** goes back. **9** on the front board leaves.

## Usage

```sh
key-cli help
key-cli version
key-cli about
key-cli backup
key-cli restore list
key-cli restore ssh-20260914-1.tar.gz
key-cli --force restore alice ssh-20260914-1.tar.gz
key-cli auth-keys
key-cli auth-keys add ./laptop.pub
key-cli auth-keys add alice ./laptop.pub
key-cli auth-keys request bob ./alice.pub
key-cli auth-keys pending
key-cli auth-keys approve authkey-20260916-bob-alice-add-1.json
key-cli generate-sudoer-request
key-cli submit-sudoer-request
key-cli setup          # root: create key-adm
key-cli remove-lpu --force
key-cli menu
```

## Least-privilege operator (key-adm)

| Field | Value |
|-------|--------|
| Username | `key-adm` |
| UID / GID | 1666 |
| Home | `/etc/key-adm` |
| Sudoers | `/etc/key-adm/sudoers` (`backup *`, `restore *`, `auth-keys add/pending/approve/reject/interactive`, `--json` twins) |

Create as root: `key-cli setup`. Day-to-day: login as `key-adm`, then `key-cli backup alice` or `key-cli auth-keys pending`. A normal login **cannot** backup another user, and **cannot** approve queued keys.

## Tests

```sh
sh tests/run.sh
```

## License

MIT. See [LICENSE.md](LICENSE.md).
