**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Active (Version 1.1.0)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This file is the single home for **where scratch and cache live** for a run of `key-cli`: one per-user folder, one resolver, wired from `app_main` and shown on `about`.

**Scope:** Resolve priority chain; isolation; `util_resolve_storage` contract; `EFFECTIVE_STORAGE_DIR` / `TMPDIR` export; about human + JSON fields.  
**Out of scope (cited, not re-owned):** Binary install paths (`USER_BIN` / `GLOBAL_BIN`); domain project trees (key-cli does not keep a separate project tree; only scratch/cache); companion checksum; PATH shell-rc (`requirement-shell-path-and-shell-support`).

### 1.1 Human-facing

**In one sentence:** Scratch and cache for this run live in **one per-user folder** the tool picks (RAM disk if it can, then `/tmp`, then a cache under your home) — not a shared dump that mixes you with someone else.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The Unix login running the CLI | `key-cli about` shows the chosen folder |
| The other role | Another login on the same host | Their cache **must not** be this login’s folder |
| Not this file | Where the **program binary** is installed (`~/.local/bin` vs `/usr/local/bin`) | Install-path law on zero-arguments / self-management |

| Includes | Excludes |
|----------|----------|
| One resolver; `about` fields for the chosen path | Domain project trees (key-cli does not keep a separate project tree; only scratch/cache) |
| Temp downloads under that root | Hard-coded `/tmp/key-cli` dumps |

| Surface | What you open | What for |
|---------|---------------|----------|
| `key-cli about` | Command | Human + JSON storage fields |
| `./key-cli` | Program file | `util_resolve_storage` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| See where scratch went | About names the effective folder and the persistent cache fallback. Two logins must not share one directory. | `key-cli about` · `key-cli --json about` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Single resolver SSOT

1. **MUST** keep **one** authoritative storage-resolve helper: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` under a path it returned) — **MUST NOT** introduce parallel hard-coded `/tmp/key-cli` dumps.  
3. Resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture (data return — not product UI).  
4. User-visible failure about storage **MUST** use Output SSOT (`out_die` / structured error as mode requires).

### 2.2 Live resolve priority (normative for this product)

Walk the chain. Parent **must exist** before `mkdir` of a `cache` leaf (except Termux `$PREFIX/tmp`, which may be created). **`mkdir` of one leaf is a probe** — fail-soft: `mkdir -p` then re-test `-d` and `-w`. **MUST NOT** abort, `out_die`, or print `[ERROR]` / `[WARN]` because one leaf failed while later roots remain. Isolation (`${APP_NAME}-${USERNAME}`) lives **under** the chosen cache root.

| Order | Condition | Path shape |
|-------|-----------|------------|
| 1 | `/dev/shm` exists | `/dev/shm/${APP_NAME}-${USERNAME}` (mkdir fail-soft) |
| 2a | Termux (`key_is_termux`) | `${PREFIX}/tmp/${APP_NAME}-${USERNAME}` |
| 2b | Git Bash (`key_is_git_bash`) | `${HOME}/AppData/Local/Temp/cache/${APP_NAME}-${USERNAME}` when that Temp parent exists; else `/c/Users/${USERNAME}/AppData/Local/Temp/cache/${APP_NAME}-${USERNAME}` |
| 3 | `$TEMP` defined and exists | `${TEMP}/cache/${APP_NAME}-${USERNAME}` |
| 4 | `/tmp` exists | `/tmp/cache/${APP_NAME}-${USERNAME}`; else `/tmp/${APP_NAME}-${USERNAME}` |
| 5 | Fallback | `STORAGE_DIR` (`${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}`, env-overridable) |

**MUST NOT** use `$HOME/.cache` as the Git Bash **volatile** root when `$HOME/AppData/Local/Temp` or `/c/Users/${USERNAME}/AppData/Local/Temp` exists.

**Create before return:** only print a path after that root exists and is writable. Failure of **one** mkdir **MUST NOT** `out_die`. Failure to obtain **any** usable root **MUST** fail closed via `out_die` with an operator-readable Next (`set STORAGE_DIR` to a writable folder). **MUST NOT** return a path without creating it.

### 2.3 Isolation

1. Paths **MUST** include **`${APP_NAME}`** and **`${USERNAME}`** (with safe defaults when unset).  
2. **MUST NOT** rewrite the resolver to a single shared world-writable directory for all users.  
3. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so `mktemp -t` install staging inherits the isolated root.

### 2.4 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; export `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR`, `TMPDIR` |
| `app_about` JSON | Include `effective_storage` and `storage_dir` (no CHECKSUM) |
| `app_about` human | Show effective storage (and config fallback field) |

### 2.5 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `key-cli` |
| **Resolver** | `util_resolve_storage` in `./key-cli` |
| **Config fallback** | `: "${STORAGE_DIR:=${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}}"` |
| **Call sites** | `app_main` (resolve + TMPDIR); `app_about` (human + JSON) |
| **Not used for** | Domain project trees (bootstrap has none) |
| **Tests** | `tests/test_cli.sh` — about storage fields, isolation, dir exists; Git Bash `/dev/shm` mkdir fail-soft → AppData Local Temp/cache (**TP-CLI-19** · **TP-CLI-20**) |

### 2.6 Why This Requirement Exists (CIAO)

- **Caution:** Multi-user / sudo / containers — never mix users’ scratch.  
- **Intentional:** One resolver; explicit tiers; wired from main.  
- **Anti-fragile:** Missing or unusable `/dev/shm` (Git Bash fake shm) still works via AppData Temp / `/tmp` / cache with no extra error.  
- **Over-protect:** Forbid “simplify” to shared dumps; create fail-closed.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile first, user cache last for **scratch**.  
- Isolation before convenience.  
- Soft-`mkdir` of the effective root is forbidden; create is fail-closed in the resolver.

---

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `key_is_termux`, `key_is_git_bash`, `key_is_windows_cmd`, `key_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** scratch/cache resolve stays this-login (`$PREFIX` / Git Bash AppData Temp / user cache); **MUST NOT** write `/etc` dests or Type 2 homes. **MUST NOT** die on `/dev/shm` mkdir when a later this-login cache still works.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Remove `${APP_NAME}` / `${USERNAME}` isolation from `util_resolve_storage`.  
2. Replace the fallback chain with a single shared world-writable path.  
3. Scatter new hard-coded `/tmp/${APP_NAME}` roots outside the resolver.  
4. Leave the resolver as dead code with no call sites while claiming storage is product law.  
5. Echo a tier path **without** creating it (or without fail-closed create of the **chosen** root).  
6. Bypass Output SSOT for storage failure messages.  
7. Put CHECKSUM in about storage diagnostics.  
8. Strip the **Under command line for normal user only** section, or resolve scratch into `/etc` on that class.  
9. `out_die` / print `[ERROR]` because `mkdir` of `/dev/shm/${APP_NAME}-${USERNAME}` (or any one cache leaf) failed while later roots remain untried.  
10. Use `$HOME/.cache` as the Git Bash volatile root when `$HOME/AppData/Local/Temp` or `/c/Users/${USERNAME}/AppData/Local/Temp` exists.  

**Violating this rule is a critical storage isolation regression.**

---

## 5. Definition of done (shell CLI storage)

Storage resolve work for key-cli is **not done** if any of the following fail:

1. Exactly one authoritative resolver (`util_resolve_storage`) returns the chosen path on stdout after `mkdir -p` of that root.  
2. Resolve priority matches this requirement (`/dev/shm` fail-soft → Termux `$PREFIX/tmp` / Git Bash AppData Temp/`cache` → `$TEMP/cache` → `/tmp/cache` → `STORAGE_DIR`). Mid-chain mkdir failure does not abort.  
3. Paths include `${APP_NAME}` and `${USERNAME}` isolation; no shared world-writable single dump for all users.  
4. `app_main` sets `EFFECTIVE_STORAGE_DIR` / exports `TMPDIR` from the resolver once early.  
5. `app_about` human + JSON expose effective storage fields and **omit** `CHECKSUM`.  
6. User-visible storage failures use Output SSOT (`out_die` / structured error).  
7. Tests cover about storage fields / isolation / Git Bash shm fail-soft (`tests/test_cli.sh` **TP-CLI-12** · **TP-CLI-19** · **TP-CLI-20**).  
8. Implementation changes cite this requirement key `requirement-shell-cli-storage`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-modular-function-design.md` | `util_*` ownership |
| `docs/requirements/requirement-shell-output-requirements.md` | about JSON via `out_json` |
| `docs/requirements/requirement-shell-self-management.md` | about lifecycle |
| `./key-cli` | Implementation under test |
| `tests/test_cli.sh` | Storage diagnostics tests |

---

**Last Updated**: 2026-09-11  
**Owner**: key-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 4, 5, 11, 19, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
