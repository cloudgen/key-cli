**file**: docs/requirements/requirement-shell-config-backup.md  
**Status**: Active (Version 2.0.0)  
**Area**: shell  
**Key**: `requirement-shell-config-backup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the operations Single Source of Truth for depositing this login’s whole `~/.ssh` folder as a dated `tar.gz` into `/var/key-cli/{{username}}/` (`backup`) and extracting it back (`restore`). It **is** folder-archive tar.gz. It is **not** a single-file copy of `~/.ssh/config`.

**Depends on `requirement-shell-sudoer`:** elev is `sudo -n /usr/local/bin/key-cli backup` (and `restore *`) through `util_sudo`. JSON grant and print/generate/submit live there. This file **MUST NOT** invent a second wrap or grant.

### 1.1 Human-facing

**In one sentence:** `backup` archives `/home/<user>/.ssh` into `/var/key-cli/<user>/ssh-YYYYMMDD-N.tar.gz` as root after a passwordless grant; `restore` extracts that archive back.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Push or pull the `.ssh` folder | `key-cli backup` · `key-cli restore` |
| The other role | sudoer-adm approves passwordless `sudo key-cli backup` | JSON grant — `requirement-shell-sudoer` |
| Not this file | Host list edit; sudoers JSON schema; key-adm identity | `requirement-domain-key` · `requirement-shell-sudoer` · `requirement-least-privilege-user` |

| Includes | Excludes |
|----------|----------|
| Source `/home/{{username}}/.ssh`; dest `/var/key-cli/{{username}}/ssh-YYYYMMDD-N.tar.gz`; SUDO_USER when elevated; archive `root:root` `0600`; restore with `--force` | Copying only `config`; `sync-from-remote`; Termux / Git Bash / Windows cmd **deposit** |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./key-cli` | ship unit | live verbs |
| `/var/key-cli/<user>/` | durable store | backup dest / restore source |
| `key-cli backup` | command | elevated archive |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Keep a copy of this login’s keys | Archive `.ssh` into the host store as root | `key-cli backup` |
| Put them back | Extract a dated archive | `key-cli restore list` then `key-cli restore ssh-YYYYMMDD-N.tar.gz` |
| If sudo is refused | Queue the grant first (sudoer SSOT) | `key-cli generate-sudoer-request` then `key-cli submit-sudoer-request` |

## 2. Core Rules / Requirements (Mandatory)

### 2.0 Dependency on sudoer features (sacred)

1. `backup` / `restore` **MUST** re-exec through `util_sudo` owned by `requirement-shell-sudoer` when the production dest needs elev.  
2. Grant **MUST** be that file’s allow table (`backup`, `backup *`, `restore *`, and `--json` twins).  
3. Refused sudo **MUST** tell the operator to use `generate-sudoer-request` / `submit-sudoer-request`.  
4. **MUST NOT** duplicate JSON emit, fragment emit, or a second wrap in this file.

### 2.1 Source and dest

1. Source **MUST** be `{{KEY_HOME_ROOT}}/{{username}}/.ssh` (default `/home/{{username}}/.ssh`). When the process is root via sudo, invoking username **MUST** be `SUDO_USER` unless an on-behalf operand is allowed.  
2. Default dest root **MUST** be `/var/key-cli`. Override `KEY_CLI_ROOT` (tests / non-production). Archive **MUST** be `{{KEY_CLI_ROOT}}/{{username}}/ssh-{{YYYYMMDD}}-{{N}}.tar.gz`.  
3. **MUST** archive the whole `.ssh` directory (including private keys). Archive mode **MUST** be `0600`, owner `root:root` after elevated deposit.  
4. Missing source **MUST** fail closed. Next: create that login’s `.ssh` folder, then `key-cli backup`.  
5. Same-day re-run **MUST** increment `N` (never overwrite).

### 2.2 backup (elevated deposit)

1. On Termux, Git Bash, or Windows cmd **MUST** fail closed. Next: use a POSIX Linux host.  
2. Writing the production dest as a non-root login **MUST** re-exec `sudo -n {{GLOBAL_BIN}}/key-cli backup` through `util_sudo` (with `--json` when JSON mode).  
3. If that sudo is refused, **MUST** fail closed. Next: `key-cli generate-sudoer-request && key-cli submit-sudoer-request`.  
4. As root, the ship unit **MUST** `mkdir` the dest if needed, `tar czf` from the parent of `.ssh`, `chown root:root`, `chmod 0600` the archive and `0750` the user dest dir.  
5. **MUST NOT** grant OS tools in sudoers; those run inside the elevated product command.  
6. A writable `KEY_CLI_ROOT` outside `/var/key-cli` **MAY** accept Type 0 deposit for tests. Production dest **MUST NOT** skip elev just because it happens to be writable.  
7. After deposit, **MUST** report verify counts (`source_files`, members, size). **MUST NOT** extract to verify.

### 2.3 restore

1. `restore` **MUST** elevate the same way as `backup` when reading the production dest.  
2. `restore list [user]` **MUST** list `ssh-*.tar.gz` basenames for that user.  
3. Extract dest **MUST** be that user’s `.ssh` (`{{KEY_HOME_ROOT}}/{{username}}/.ssh` on POSIX Linux). Non-empty dest **MUST** require `--force` or a TTY confirm.  
4. As root, **MUST** `chown` the restored tree to that username and `chmod 0700` the directory.  
5. When dest `.ssh` already exists, `restore` **MUST** `backup` that user globally **before** extract (fail closed if backup cannot run).

### 2.3a auth-keys add (depends on backup)

1. `auth-keys add` **MUST** take a global `backup` of that user’s `.ssh` **before** appending. If `.ssh` is missing, create it (`0700`) then backup.  
2. After a successful append (not a duplicate no-op), **MUST** `backup` again so the store includes the new line.  
3. Nested backup **MUST NOT** emit a second JSON object.  
4. On Termux / Git Bash / Windows cmd this **MUST** fail closed (deposit is not available).

### 2.4 Invocation samples

```text
key-cli backup
key-cli backup alice
key-cli restore list
key-cli restore ssh-20260914-1.tar.gz
key-cli --force restore alice ssh-20260914-1.tar.gz
key-cli generate-sudoer-request
key-cli submit-sudoer-request
```

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Store | `/var/key-cli` (`KEY_CLI_ROOT`) |
| Source | `{{KEY_HOME_ROOT}}/{{username}}/.ssh` |
| Elev argv | `sudo -n /usr/local/bin/key-cli backup` (`requirement-shell-sudoer`) |
| Handlers | `key_cmd_backup` · `key_cmd_restore` |
| Tests | `tests/test_config_backup.sh` **TP-CFG-01..24** |

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 10 – Least privilege**: elev is the product command only (sudoer SSOT).  
- **CIAO Principle 12 – Right backup**: dated non-overwriting archives; private keys stay `0600`.  
- **CIAO Principle 22 – File modes**: archive 0600; `.ssh` dir 0700.

## Under command line for normal user only

When the ship unit detects Termux, Git Bash, Windows cmd, or the same class: **MUST NOT** deposit into `/var/key-cli` or wrap `sudo`. Direct `backup` / `restore` **MUST** fail closed. TTY menu **MUST** print `[INFO] backup and restore not available for termux` / `gitbash` / `windows-cmd` **before** the numbered keys list and **MUST** omit those rows (and sudoers).

**This requirement:** host deposit is POSIX Linux.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: SUDO_USER; private-key archives are not world-readable.  
- **Intentional**: `backup` vs `restore` vs sudoer workflow.  
- **Anti-fragile**: `KEY_CLI_ROOT` / `KEY_HOME_ROOT` for tests.  
- **Over-protect**: fail closed on this-login-only hosts; on-behalf only as key-adm.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Copy only `~/.ssh/config` and call that `backup`.  
2. Name the pull verb `sync-config` / `sync-from-remote`.  
3. Grant `cp`/`mkdir`/`chmod`/`tar` in sudoers.  
4. Enable **deposit** on Termux / Git Bash / Windows cmd.  
5. Use `/root/.ssh` when `SUDO_USER` is set.  
6. Leave archives mode `0644`.  
7. Invent a second `util_sudo` or JSON grant — compose `requirement-shell-sudoer`.  
8. Overwrite an existing same-day archive basename.

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-01..24** | `tests/test_config_backup.sh` | have |

**Last Updated**: 2026-09-14  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
