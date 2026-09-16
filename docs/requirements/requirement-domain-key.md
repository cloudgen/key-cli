**file**: docs/requirements/requirement-domain-key.md  
**Status**: Active (Version 2.0.0)  
**Area**: domain  
**Key**: `requirement-domain-key`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **one Active domain SSOT** for **key-cli**. The product **purpose** is to **backup and restore this login’s `~/.ssh` folder** as a dated `tar.gz` under `/var/key-cli`, and to let the least-privilege operator **key-adm** do the same **on behalf of other users** and **append `authorized_keys`**. It does **not** install or run OpenSSH sshd, and it does **not** wrap the OpenSSH client (`dns` / `ssh` / `download` / `upload`).

Type 0 install/self-update/self-uninstall stay on the shell lifecycle requirements. This file owns specialized subcommands, features, help rows, and about fields.

### 1.1 Human-facing

**In one sentence:** You use `key-cli` so backing up `/home/<user>/.ssh` into `/var/key-cli/<user>/ssh-YYYYMMDD-N.tar.gz` (and restoring it) is one command, with `key-adm` able to do that for someone else.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person whose keys are archived, or the operator | `key-cli backup` · `key-cli restore` |
| The other role | `key-adm` (on-behalf) and sudoer-adm (grant) | `key-cli backup alice` as key-adm |
| Not this file | Installing *this CLI* binary | `requirement-shell-self-management.md` |

| Includes | Excludes |
|----------|----------|
| `backup` / `restore` / `auth-keys` / `setup` / `remove-lpu` / menu | OpenSSH sshd start/stop/port/host-keys; `dns` / `ssh` / `download` / `upload`; Termux `pkg install openssh` |
| Dated `tar.gz` of the whole `.ssh` folder, owner `root:root`, mode `0600` | Copying only `~/.ssh/config`; world-readable archives |
| key-adm on-behalf backup and `authorized_keys` append | `ALL=(ALL) ALL`; OS-tool sudoers (`tar`/`cp`/`mkdir`) |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./key-cli` | Program | Live domain verbs |
| `key-cli help` | Command | Domain rows after Type 0 |
| `/var/key-cli/<user>/` | Store | Dated archives |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Archive this login’s keys | sudo of the product command writes a dated tar.gz as root | `key-cli backup` |
| Put them back | Extract a named archive into `/home/<user>/.ssh` | `key-cli restore` · `key-cli restore list` |
| Allow a laptop key | Append one public-key file to this login | `key-cli auth-keys add ./laptop.pub` |
| Act for another user | Login as key-adm (or root) | `key-cli backup alice` · `key-cli auth-keys add alice ./laptop.pub` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Specialized CLI subcommands

| Verb | Operands | Handler | Privilege | Errors |
|------|----------|---------|-----------|--------|
| `backup` | optional `user` | `key_cmd_backup` | This login (self) via `sudo -n {{GLOBAL_BIN}}/key-cli backup`; other user only as key-adm or root | Missing `.ssh` / sudo refused / this-login-only host → `out_die` |
| `restore` | `list [user]` or `[user] [archive]` | `key_cmd_restore` | Same as backup | Missing archive / overwrite without `--force` / sudo refused → `out_die` |
| `auth-keys` | `list` (default) or `add [user] <pubkey-file>` | `key_cmd_auth_keys` | This login Type 0 for self; other user only as key-adm or root | Missing file / no key line / on-behalf refused → `out_die` |
| `setup` | none | `key_cmd_setup` | Root login (admin privilege) | Non-root / this-login-only host / UID collision → `out_die` |
| `remove-lpu` | none | `key_cmd_remove_lpu` | Root login | Non-root / missing `--force` off-TTY → `out_die` |
| `menu` / `main` | none | `key_cmd_menu` | TTY only | `--json` / quiet / non-TTY → `out_die` with named-command hint |

**Routing:** `app_main` parses these verbs in the same pass as Type 0. Operands after `backup` / `restore` / `auth-keys` are domain operands. **Numbered tree SSOT:** `requirement-shell-cli-default-interaction`.

**MUST:** `backup` / `restore` ops SSOT is `requirement-shell-config-backup` (depends on `requirement-shell-sudoer`). Sudoers JSON, print/generate/submit, and `util_sudo` SSOT is `requirement-shell-sudoer`. key-adm identity SSOT is `requirement-least-privilege-user`. This domain file **points**; it does not re-own copy or grant emit.

**MUST:** TTY menu on Termux / Git Bash / Windows cmd **MUST** print `[INFO] backup and restore not available for termux` (or `gitbash` / `windows-cmd`) **before** the keys numbered list and omit backup / restore / sudoers. Front Exit is **9**. Dual mention: `requirement-shell-cli-default-interaction`.

**MUST:** Each verb above is also named on `requirement-shell-cli-interface` (dual mention).

**MUST:** Interactive empty argv (`TTY=1`, not quiet/json) **MUST** call `key_cmd_menu`. Dual mention: `requirement-shell-cli-zero-arguments`.

**MUST NOT:** Open this menu on **non-interactive** empty argv (`curl | sh`, quiet, json, no TTY) — that path stays install-ensure.

**MUST NOT** route `start` / `stop` / `restart` / `status` / `port` / `config` / `host-keys` / `dns` / `ssh` / `download` / `upload` / `wake-lock` / `backup-config` / `sync-config` / `sync-from-remote`. Those are unknown commands.

### 2.1.1 Install companion

`install` and **non-interactive** empty-argv install-ensure **MUST** call `inst_ensure_companion` (PATH / rc only). **MUST NOT** run `pkg install openssh`. **MUST NOT** start sshd. Dual mention: `requirement-shell-self-management`.

**`self-update` is CLI-only.** After a successful CLI place it **MUST NOT** start sshd or rewrite `/etc/ssh/sshd_config`.

### 2.2 Specialized features

**Path resolve:**

| Field | Value |
|-------|--------|
| Source folder | `{{KEY_HOME_ROOT}}/{{username}}/.ssh` (default `KEY_HOME_ROOT=/home`) |
| Dest directory | `{{KEY_CLI_ROOT}}/{{username}}/` (default `KEY_CLI_ROOT=/var/key-cli`) |
| Archive basename | `ssh-{{YYYYMMDD}}-{{N}}.tar.gz` (`N` starts at 1; same-day re-run increments; never overwrite) |
| Archive owner/mode | `root:root` / `0600` after elevated deposit |
| Dest dir owner/mode | `root:root` / `0750` |
| Store root owner/mode | `root:root` / `0755` |
| This-login auth-keys | `{{HOME}}/.ssh/authorized_keys` (Type 0) |
| On-behalf auth-keys | `{{KEY_HOME_ROOT}}/{{username}}/.ssh/authorized_keys` |

**Filename grammar (archives):**

```text
{{KEY_CLI_ROOT}}/{{username}}/ssh-{{YYYYMMDD}}-{{N}}.tar.gz
```

Example: `/var/key-cli/alice/ssh-20260914-1.tar.gz`

**On-behalf rule:** If the operand username is not the invoking login (`SUDO_USER` when elevated), the command **MUST** fail closed unless the invoker is **key-adm** or a **root login** (no `SUDO_USER`, or `SUDO_USER` is `root` or `key-adm`). **MUST NOT** let a normal login `sudo key-cli backup otheruser`.

**Global backup before mutate:** `auth-keys add` and `restore` (when dest `.ssh` already exists) **MUST** call `backup` for that user into `{{KEY_CLI_ROOT}}` **before** writing. Fail closed if that backup cannot run (including Termux / Git Bash / Windows cmd). After a successful `auth-keys add` that actually appended a line, **MUST** `backup` again so the store holds the new key. Nested backup **MUST NOT** emit a second JSON object.

**Restore dest:** Extract with `tar -C` the parent of that user’s `.ssh`. After extract, directory mode `0700`. As root, `chown` the restored tree to that username. Non-empty dest **MUST** require `--force` (or a TTY yes/no). TTY with no archive: numbered picker; unknown number **MUST** warn and redisplay (**MUST NOT** `out_die`).

**Verify:** After backup, report `source_files` (find -type f), tar member count, and size. **MUST NOT** extract during verify.

**Non-goals:** OpenSSH sshd install/start/stop; systemd units; Termux `pkg` of openssh; SSH client Host list; `ssh`/`scp`/`download`/`upload`; wrapping `apt`; copying only `config`; world-readable key archives.

### 2.3 Specialized project help items

`help` **MUST** keep Type 0 rows, then a **Domain commands (SSH user keys):** section listing `backup`, `restore`, `auth-keys`, `setup`, `remove-lpu`, sudoers verbs, and `menu`.

Help **MUST** list `rc-test` under a heading **apart** from operational verbs.

**MUST NOT** list `start` / `dns` / `ssh` / `wake-lock`.

### 2.4 Specialized project about items

Human `about` **MUST** add after storage lines: key store path family and whether `key-adm` is present.  
JSON `about` **MUST** add `key_cli_root`, `key_adm`, `key_adm_present`.  
**MUST NOT** put `sshd_platform` / `sshd_bin` / `sshd_port` on about. **MUST NOT** put `CHECKSUM` on about.

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `key-cli` 2.0.3 |
| Domain prefix | `key_*` |
| Channel | `https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli` |
| LPU | `key-adm` UID/GID **1666**, home `/etc/key-adm`, F6 `/etc/key-adm/sudoers` |
| Store | `/var/key-cli` (`KEY_CLI_ROOT`) |
| Tests | `tests/test_config_backup.sh` **TP-CFG-01..24** · `tests/test_cli.sh` **TP-KEY-*** |

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional**: backup of the whole `.ssh` folder is named; sshd/client verbs are out.  
- **CIAO Principle 10 – Least privilege**: elev is the product command; key-adm is the only on-behalf operator.  
- **CIAO Principle 12 – Right backup**: dated non-overwriting `tar.gz`, `root:root` `0600`.  
- **CIAO Principle 9 – Type 0/1/2**: Type 0 self keys; Type 1 sudo of the product command; Type 2 key-adm.

## Under command line for normal user only

When the ship unit detects Termux, Git Bash, Windows cmd, or the same class: Type 1 and Type 2 **MUST** stay unused. `backup` / `restore` / `setup` / `remove-lpu` / sudoers **MUST** fail closed. `auth-keys` for **this login** remains Type 0.

**This requirement:** host deposit is POSIX Linux; this-login `authorized_keys` is every class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Fail closed on missing `.ssh`, bad username, refused sudo, on-behalf by a normal login.  
- **Intentional**: One domain SSOT; dual mention on the CLI-interface file.  
- **Anti-fragile**: `KEY_CLI_ROOT` / `KEY_HOME_ROOT` for tests.  
- **Over-protect**: Archives `0600`; never OS-tool sudoers.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Drop Type 0 routes while adding domain verbs.  
2. Open the menu on **non-interactive** empty argv.  
3. Re-add OpenSSH sshd start/stop/port/host-keys or client `dns`/`ssh`/`download`/`upload`.  
4. Grant `tar`/`cp`/`mkdir` in sudoers.  
5. Deposit world-readable key archives (`0644`).  
6. Let a normal login backup another user’s `.ssh`.  
7. Use `/root/.ssh` when `SUDO_USER` is set.  
8. Wrap `sudo` on Termux / Git Bash / Windows cmd.  
9. `$()` a `read` helper for the menu or restore picker.  
10. `out_die` solely because a TTY numbered choice was unknown.  
11. Append `authorized_keys` or extract a restore over an existing `.ssh` without a global `backup` of that user first.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-config-backup.md` | Archive deposit / restore ops |
| `docs/requirements/requirement-shell-sudoer.md` | Grant + `util_sudo` |
| `docs/requirements/requirement-least-privilege-user.md` | key-adm F1–F7 |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention of domain verbs |
| `./key-cli` | Implementation |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-04**, **TP-CLI-14**, **TP-CLI-21**, **TP-KEY-01** .. **TP-KEY-09**, **TP-KEY-16** | `tests/test_cli.sh` | have |
| **TP-CFG-01** .. **TP-CFG-24** | `tests/test_config_backup.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-09-14  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
