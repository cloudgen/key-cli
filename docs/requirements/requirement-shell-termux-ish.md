**file**: docs/requirements/requirement-shell-termux-ish.md  
**Status**: Active (Version 2.0.0)  
**Area**: shell  
**Key**: `requirement-shell-termux-ish`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **shell Termux-ish** law for **key-cli**: detect Termux / Git Bash / Windows cmd as a command line for normal user only. Type 1 and Type 2 **MUST** stay unused on that class. This product **does not** wrap `pkg install openssh` and **does not** implement Android wake lock. Detect helpers stay so backup/restore fail closed honestly.

### 1.1 Human-facing

**In one sentence:** On Termux, Git Bash, or Windows cmd, `key-cli` still installs itself for this login — it does **not** install OpenSSH, and `backup` / `restore` / sudoers fail closed.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The Termux (or POSIX) login that typed the command | `key-cli install` |
| The other role | A POSIX Linux host that can write `/var/key-cli` | `key-cli backup` on Linux |
| Not this file | Which domain verbs exist; placing **this** CLI file | `requirement-domain-key.md` · `requirement-shell-self-management.md` |

| Includes | Excludes |
|----------|----------|
| Detect Termux-ish / Git Bash / Windows cmd; Type 1/2 unused | Linux `apt` / `dnf` / `yum`; in-tool `sudo` on this class |
| Fail closed on backup / restore / setup / sudoers | `pkg install -y openssh termux-auth`; `wake-lock` / `wake-unlock` |
| This-login `auth-keys list` (Type 0) | Treating OpenSSH sshd as a companion of `install` |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./key-cli` | Program | detect helpers; fail-closed elev |
| `key-cli help` | Command | no `wake-lock`; no OpenSSH pkg row |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Install on Termux | Place this program only (PATH / rc) | `key-cli install` |
| Try backup on Termux | Fail closed; Next names a POSIX Linux host | `key-cli backup` |
| Run the same command on Linux | Deposit into `/var/key-cli` after sudoer-adm | `key-cli backup` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Detect

**MUST** treat the host as Termux-ish when any of: `PREFIX` contains `com.termux`; `TERMUX_VERSION` is set; `/data/data/com.termux/files/usr` exists. Helper: `key_is_termux`.

Termux is a **command line for normal user only**. Git Bash and Windows cmd are the same class (`key_is_git_bash` · `key_is_windows_cmd`; union helper `key_is_normal_user_only_cli`). On that class, **admin privilege** and **dedicated system user privilege** **MUST** stay unused. Dual mention: `requirement-shell-cli-interface`.

Off detect: **MUST NOT** invoke `pkg`; **MUST NOT** wrap `apt` / `dnf` / `yum`. Git Bash **MUST NOT** invoke `pkg`.

### 2.2 No OpenSSH package companion

`install` and **non-interactive** empty-argv install-ensure **MUST** call `inst_ensure_companion` (PATH / rc only). **MUST NOT** run `pkg install openssh` (or `termux-auth`). Dual mention: `requirement-shell-self-management` · `requirement-domain-key`.

Interactive empty argv is the menu and **MUST NOT** run package ensure as a side effect (`requirement-shell-cli-zero-arguments`).

**MUST NOT** treat a missing OpenSSH package as a product defect on this class.

### 2.3 No Android wake lock

**MUST NOT** route `wake-lock` / `wake-unlock`. **MUST NOT** call `termux-wake-lock` / `termux-wake-unlock`. Help **MUST NOT** list those verbs. Dual mention: `requirement-domain-key`.

### 2.4 Elev fail closed

On Termux / Git Bash / Windows cmd: `backup` / `restore` / `setup` / `remove-lpu` / sudoers verbs **MUST** fail closed. TTY keys board **MUST** print `[INFO] backup and restore not available for termux` (or `gitbash` / `windows-cmd`) and omit backup / restore / sudoers / request rows. This-login `auth-keys` **list** remains Type 0; `auth-keys add` **MUST** fail closed because a global backup is required. `auth-keys request` / `pending` / `approve` / `reject` / `interactive` **MUST** fail closed (inbound is POSIX Linux). Dual mention: `requirement-shell-config-backup` · `requirement-domain-key`.

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `key-cli` 2.0.2 |
| Detect | `key_is_termux` |
| Class union | `key_is_normal_user_only_cli` (Termux **or** Git Bash **or** Windows cmd) |
| Git Bash | `key_is_git_bash` — no `pkg`; no `termux-wake-lock` |
| Windows cmd | `key_is_windows_cmd` — no `pkg`; no `termux-wake-lock` |
| Companion | `inst_ensure_companion` — PATH / rc only |
| Named OpenSSH list | **none** |
| Android wake lock | **none** |
| Linux | no-op (no `apt`) |
| In-tool sudo | unused on this class (`key_refuse_elev_on_nuser`) |

#### Worked samples (this project)

```sh
key_is_termux() {
    : "${PREFIX:=}"
    if [ -n "${PREFIX}" ] && [ -d "${PREFIX}/bin" ]; then
        case "${PREFIX}" in
            */com.termux/*) return 0 ;;
        esac
    fi
    if [ -n "${TERMUX_VERSION-}" ] || [ -d /data/data/com.termux/files/usr ]; then
        return 0
    fi
    return 1
}

key_is_normal_user_only_cli() {
    key_is_termux && return 0
    key_is_git_bash && return 0
    key_is_windows_cmd && return 0
    return 1
}
```

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): detect exists so elev fail-closed is honest; OpenSSH pkg is out.  
- **CIAO Principle 9 – Type 0/1/2** (https://github.com/cloudgen/ciao): Type 1/2 unused on this class.  
- **CIAO Principle 10 – Least privilege** (https://github.com/cloudgen/ciao): no sudo on Termux.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): fail closed on deposit.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: do not pretend `/var/key-cli` deposit works on Termux.  
- **Intentional**: detect is for fail-closed, not for wrapping `pkg`.  
- **Anti-fragile**: works when systemd and root are absent (Termux).  
- **Over-protect**: never wrap Linux `apt`; never unbounded `pkg`.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: CLI install as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path; wrap `pkg install openssh` |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `key_is_termux`, `key_is_git_bash`, `key_is_windows_cmd`, `key_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface`.

**This requirement:** no `pkg` and no `termux-wake-lock` on any class; Git Bash and Windows cmd are the same privilege class; **MUST NOT** invoke `systemctl` on this class.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Re-add `pkg install -y openssh termux-auth` as a companion of `install`.  
2. Route `wake-lock` / `wake-unlock` or call `termux-wake-lock`.  
3. Enable Type 1 or Type 2 on Termux, Git Bash, or Windows cmd.  
4. Wrap Linux `apt` / `dnf` / `yum`.  
5. Run unnamed `pkg` subcommands as this companion.  
6. Treat missing OpenSSH as a product install failure.  
7. Strip the **Under command line for normal user only** section.  
8. Deposit into `/var/key-cli` on this class.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-key.md` | Domain verbs; fail-closed elev |
| `docs/requirements/requirement-shell-self-management.md` | `inst_ensure_companion` call site |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `install`; Type 1/2 unused |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Interactive empty argv is not pkg-ensure |
| `docs/requirements/requirement-class-software-dev.md` | Class residual points here |
| `./key-cli` | Implementation |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-LC-15** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-16** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-18** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-19** | `tests/test_local_lifecycle.sh` | have |
| **TP-CLI-04** (no `wake-lock` in help) | `tests/test_cli.sh` | have |
| **TP-KEY-04** | `tests/test_cli.sh` | have |
| **TP-CFG-04** · **TP-CFG-12** · **TP-CFG-13** | `tests/test_config_backup.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-09-16  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
