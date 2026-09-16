**file**: docs/requirements/requirement-least-privilege-user.md  
**Status**: Active (Version 1.0.0)  
**Area**: privilege  
**Key**: `requirement-least-privilege-user`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the product law for the **key-adm** least-privilege user: the dedicated non-root operator who may **backup another user’s `.ssh` folder** and **append that user’s `authorized_keys`** using sudo of `key-cli` (not a root shell).

Type 0 user grants for *self* backup stay on `requirement-shell-sudoer`. This file owns F1–F7 for **key-adm**, `setup`, and `remove-lpu`.

### 1.1 Human-facing

**In one sentence:** `key-adm` is the named badge that may run `sudo key-cli backup alice` and `sudo key-cli auth-keys add alice ./laptop.pub` — not “everything as root.”

| Box | Meaning | Example |
|-----|---------|---------|
| You / host admin | Create or remove the badge | `sudo key-cli setup` · `sudo key-cli remove-lpu --force` |
| The other role | key-adm day-to-day | `key-cli backup alice` |
| Not this file | This-login self backup grant | `requirement-shell-sudoer` |

| Includes | Excludes |
|----------|----------|
| Account identity, home, F6 sudoers, setup/remove | Approving sudoers JSON (that is sudoer-adm) |
| On-behalf backup and authorized_keys append | `ALL=(ALL) ALL`; writing `/etc/passwd` by hand |

| Surface | What you open | What for |
|---------|---------------|----------|
| `id key-adm` | host probe | live account |
| `/etc/key-adm/sudoers` | F6 | elev list |
| `key-cli setup` | command | Type 1 create |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Create the operator | Root login creates UID 1666 and F6 | `key-cli setup` as root |
| Use it | Login as key-adm, then backup another user | `key-cli backup alice` |
| Tear it down | Root removes the account; archives stay | `key-cli remove-lpu --force` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Canonical identity (F1–F7)

| Field | Product value |
|-------|----------------|
| Username / group | `key-adm` |
| F1 UID | **1666** (fixed; collision fail closed) |
| F2 GID | **1666** (fixed) |
| Shell | `/bin/bash` |
| F3 home | `/etc/key-adm` (selection: preferred-/etc) |
| F4 symlinks | **none** |
| F5 affected folders | **none** (bare home excluded; `/var/key-cli` stays `root:root` and is **not** this account’s tree) |
| F6 sudoers | `/etc/key-adm/sudoers` mode `0440` `root:root` |
| F7 remove | `key-cli remove-lpu` as root: backup F6 → remove include drop-in → `userdel -r` → `groupdel`. **MUST NOT** delete `/var/key-cli` archives. Type 0 `self-uninstall` is **not** F7. |

### 2.2 F6 Cmnds (Table A)

`key-adm` **MUST** be allowed only:

```text
{{GLOBAL_BIN}}/key-cli backup *
{{GLOBAL_BIN}}/key-cli restore *
{{GLOBAL_BIN}}/key-cli auth-keys add *
{{GLOBAL_BIN}}/key-cli --json backup *
{{GLOBAL_BIN}}/key-cli --json restore *
{{GLOBAL_BIN}}/key-cli --json auth-keys add *
```

**MUST NOT** allowlist `tar`, `cp`, `mkdir`, `chmod`, `chown`, shells, or `ALL`.

Type 1 `setup` **MUST** write F6 and, when `/etc/sudoers.d` exists, a `#include /etc/key-adm/sudoers` drop-in named `key-adm` (no dots). **MUST NOT** write `/etc/passwd` by editing the file; **MUST** call `useradd`.

### 2.3 Verbs (dual mention with `requirement-shell-cli-interface`)

```text
key-cli setup
key-cli remove-lpu --force
```

### 2.4 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Handlers | `key_cmd_setup` · `key_cmd_remove_lpu` |
| Env | `KEY_ADM_USER` · `KEY_ADM_UID` · `KEY_ADM_GID` · `KEY_ADM_HOME` |
| Tests | on-behalf refuse **TP-CFG-08**; setup / remove-lpu root-only **TP-CFG-15** · **TP-CFG-16**; help **TP-KEY-02**; on-behalf hide **TP-KEY-07** |

### 2.5 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 10 – Least privilege**: one operator, six Cmnds.  
- **CIAO Principle 9 – Type 0/1/2**: Type 1 creates; Type 2 is day-to-day as key-adm via sudo of the product command.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd: Type 2 **MUST** stay unused. `setup` / `remove-lpu` **MUST** fail closed. **This requirement:** no key-adm on that class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: UID collision fail closed.  
- **Intentional**: F3 home is not F5.  
- **Anti-fragile**: `remove-lpu` keeps user archives.  
- **Over-protect**: F6 never `ALL`.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Skip F4/F5/F6.  
2. List bare `/etc/key-adm` as an affected folder.  
3. Delete `/var/key-cli` on F7.  
4. Treat `self-uninstall` as F7.  
5. Widen F6 to a shell.  
6. Change UID 1666 without explicit user order.  
7. Let a non-key-adm Type 0 login backup another user.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-key.md` | On-behalf verbs |
| `docs/requirements/requirement-shell-sudoer.md` | Type 0 self grant |
| `docs/requirements/requirement-three-layer-privilege-model.md` | Type map |
| `./key-cli` | Implementation |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-08** | `tests/test_config_backup.sh` | have |
| **TP-CFG-15** · **TP-CFG-16** | `tests/test_config_backup.sh` | have |
| **TP-KEY-02** · **TP-KEY-07** | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-14  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
