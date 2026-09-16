**file**: docs/requirements/requirement-sshd-config-backup.md  
**Status**: Active (Version 2.0.0)  
**Area**: backup  
**Key**: `requirement-sshd-config-backup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement **points** at `requirement-shell-config-backup` for depositing this login’s whole `~/.ssh` folder as dated `tar.gz` into `/var/key-cli/{{username}}/` (`backup` / `restore`). Elev wrap and JSON grant: `requirement-shell-sudoer`. Do **not** duplicate copy semantics here.

### 1.1 Human-facing

**In one sentence:** This file is a pointer — `key-cli backup` archives `/home/<user>/.ssh` into `/var/key-cli/<user>/`; `restore` extracts it. Law lives on `requirement-shell-config-backup`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Push or pull the `.ssh` folder | `key-cli backup` · `key-cli restore` |
| The other role | sudoer-adm approves passwordless `sudo key-cli backup` | JSON grant inbound |
| Not this file | Copy semantics; sudoers JSON schema | `requirement-shell-config-backup` · `requirement-shell-sudoer` |

| Includes | Excludes |
|----------|----------|
| Pointer to live backup/restore law | Re-owning tar semantics or sudoers JSON |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./key-cli` | ship unit | live verbs |
| `requirement-shell-config-backup.md` | SSOT | deposit / restore |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Archive this login’s `.ssh` | Dated tar.gz under `/var/key-cli` | `key-cli backup` |
| Put it back | Extract a named archive | `key-cli restore` |

## 2. Core Rules / Requirements (Mandatory)

**SSOT is `requirement-shell-config-backup`.** This file **MUST NOT** be read as a second copy of deposit law.

1. Source is `/home/{{username}}/.ssh`. Dest is `/var/key-cli/{{username}}/ssh-YYYYMMDD-N.tar.gz`.  
2. Elev wrap and JSON grant: `requirement-shell-sudoer`.  
3. On-behalf other users: `requirement-least-privilege-user` (key-adm).

## Under command line for normal user only

Deposit **MUST** fail closed on Termux / Git Bash / Windows cmd. **This requirement:** pointer only; details on `requirement-shell-config-backup`.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Intentional**: one ops SSOT; this file points.  
- **Caution**: do not treat a pointer as a second grant table.

## 4. Protection Rule (Sacred)

**MUST NOT** re-specify tar/elev rules here. **MUST NOT** revive `backup-config` / `sync-config` / `sync-from-remote` as live verbs.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-config-backup.md` | **SSOT** |
| `docs/requirements/requirement-shell-sudoer.md` | wrap + JSON |
| `docs/requirements/requirement-domain-key.md` | Dual mention catalog |
| `./key-cli` | Ship unit |

**Last Updated**: 2026-09-14  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
