**file**: docs/requirements/requirement-shell-sudo-command.md  
**Status**: Active (Version 2.0.0)  
**Area**: shell  
**Key**: `requirement-shell-sudo-command`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement **points** at `requirement-shell-sudoer` for in-tool sudo: one wrapping function `util_sudo`, check before sudo, and the studied allow table for `backup` / `restore`. Do **not** duplicate the wrap body here.

### 1.1 Human-facing

**In one sentence:** when you are not root, `backup` asks passwordless sudo to run the same program again as root — only that product command.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Run backup | `key-cli backup` |
| The other role | sudoer-adm already approved the grant | `/etc/sudoers.d/key-cli-<id -un>` |
| Not this file | JSON body; archive semantics | `requirement-shell-sudoer` · `requirement-shell-config-backup` |

| Includes | Excludes |
|----------|----------|
| `util_sudo`; already-root skip; `sudo -n` exact argv | Scattered raw `sudo`; `sudo true` probes |

| Surface | What you open | What for |
|---------|---------------|----------|
| `util_sudo` | wrap | only sudo call site |
| allow table | this file | dest + argv |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Archive keys as yourself | The CLI re-execs the global binary | `key-cli backup` |

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** keep one wrap `util_sudo`. **MUST NOT** scatter raw `sudo` for product elev.  
2. Already-root **MUST** run argv without sudo (C5).  
3. Non-root production dest **MUST** use `sudo -n` matching the allow table (NOPASSWD). **MUST NOT** default `sudo -n` for other verbs.  
4. **MUST NOT** probe with `sudo true` / `sudo mkdir` / `sudo cp`.  
5. Probe for skip: `id -u` = 0, or dest is a writable `KEY_CLI_ROOT` outside `/var/key-cli`. **MUST NOT** use `[ -O dest]` to skip a `/var/key-cli` deposit.

### 2.1 Sudo allow table (studied)

| Binary | Verb | Operand | Fragment dest | NOPASSWD? | This wrap? | Study evidence |
|--------|------|---------|---------------|-----------|------------|----------------|
| `{{GLOBAL_BIN}}/key-cli` | `backup` | none and `*` | `/etc/sudoers.d/key-cli-{{username}}` | yes | yes | this product `print-sudoers` emit |
| `{{GLOBAL_BIN}}/key-cli` | `restore` | `*` | `/etc/sudoers.d/key-cli-{{username}}` | yes | yes | this product `print-sudoers` emit |
| `{{GLOBAL_BIN}}/key-cli` | `auth-keys` | `add *` / `pending` / `pending *` / `approve *` / `reject *` / `interactive` / `interactive *` | `/etc/key-adm/sudoers` (F6) | yes | yes | this product `key_lpu_sudoers_fragment_text` |
| `{{GLOBAL_BIN}}/key-review-hook` | `auth-keys` | `interactive` | `/etc/key-adm/sudoers` (F6) | yes | yes | login doorbell; symlink to `key-cli` |

### 2.2 Implementation Notes (this project)

**SSOT:** `requirement-shell-sudoer` §2.4. `util_sudo` in `./key-cli`. Call site: `key_elev_reexec` / `key_cmd_backup` / `key_cmd_restore`. Dual mention: `requirement-shell-config-backup`.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd, `util_sudo` **MUST NOT** run: those verbs fail closed first. **This requirement:** wrap exists for POSIX Linux only.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: C0–C6.  
- **Intentional**: one wrap.  
- **Anti-fragile**: already-root path.  
- **Over-protect**: studied argv.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Guess dest as `/etc/{{username}}/key-cli` when print-sudoers says `/etc/sudoers.d/key-cli-{{username}}`.  
2. Wrap `sync-config` / `backup-config`.  
3. Probe `sudo true`.

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-01** | `tests/test_config_backup.sh` | have |
| **TP-CFG-06** | `tests/test_config_backup.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-sudoer.md` | **SSOT** — wrap + allow table + JSON |
| `docs/requirements/requirement-shell-config-backup.md` | Ops (depends on sudoer) |
| `docs/requirements/requirement-shell-script-coding.md` | Points at sudoer SSOT |
| `./key-cli` | Ship unit |

**Last Updated**: 2026-09-16  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
