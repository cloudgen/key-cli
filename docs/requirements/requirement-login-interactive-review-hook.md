**file**: docs/requirements/requirement-login-interactive-review-hook.md  
**Status**: Active (Version 1.0.0)  
**Area**: privilege  
**Key**: `requirement-login-interactive-review-hook`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement owns the **login-time review doorbell** for **key-adm**: a marker-guarded `.bashrc` snippet that once per TTY login runs `sudo -n /usr/local/bin/key-review-hook auth-keys interactive`. The labeled name **`key-review-hook`** is a **symlink to** `/usr/local/bin/key-cli` created only when missing. Domain handlers for that review verb stay on `requirement-domain-key`.

### 1.1 Human-facing

**In one sentence:** When **key-adm** opens a terminal, the login note rings the labeled bell `key-review-hook`, which is the same program as `key-cli`, and walks waiting public-key requests.

| Box | Meaning | Example |
|-----|---------|---------|
| You / key-adm | Login as the approver | `key-cli auth-keys interactive` starts from `.bashrc` |
| The other role | Root `setup` plants the note and the symlink | `sudo key-cli setup` |
| Not this file | What approve does to JSON | `requirement-domain-key.md` |

| Includes | Excludes |
|----------|----------|
| Snippet, heal, `key-review-hook` → `key-cli` symlink | Overwriting an existing `key-review-hook`; reverse-symlink of `key-cli` |
| Session / identity / scp guards | Empty argv as the review verb; hanging login on sudo fail |

| Surface | What you open | What for |
|---------|---------------|----------|
| `/usr/local/bin/key-review-hook` | Symlink | Labeled doorbell |
| `{{KEY_ADM_HOME}}/.bashrc` | Login note | Snippet |
| `key-cli rc-test` | Test-purpose | Fixture plant under `--root` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Create the operator | Root setup makes the account, F6, queue dirs, and the doorbell symlink | `key-cli setup` as root |
| Sit down as key-adm | Interactive login starts review | open a TTY as key-adm |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Labeled name

| Field | Product value |
|-------|----------------|
| Common login-hook name | **`key-review-hook`** |
| Production path | `/usr/local/bin/key-review-hook` |
| Symlink target | `/usr/local/bin/key-cli` (`ln -s {{GLOBAL_BIN}}/key-cli {{GLOBAL_BIN}}/key-review-hook`) |
| Review verb | `auth-keys interactive` |
| Approver | `key-adm` |
| Session flag | `KEY_CLI_LOGIN_HOOK_RAN` |
| Markers | `# BEGIN key-cli login hook` · `# END key-cli login hook` |

**MUST:** Type 1 `setup`, when `{{GLOBAL_BIN}}/key-cli` exists, **MUST** create the symlink if `key-review-hook` is absent. **MUST NOT** overwrite an existing `key-review-hook` (sibling retarget). **MUST NOT** make `key-cli` a symlink to `key-review-hook`. Test-mode **MUST NOT** write live `/usr/local/bin`. F7 **MUST NOT** unlink `key-review-hook`. Dual mention: `rc-test --root` (`requirement-shell-path-and-shell-support` · `requirement-shell-cli-interface`).

### 2.2 Complete snippet (normative)

The snippet **MUST** call `/usr/local/bin/key-review-hook` (not live `$GLOBAL_BIN`, not `key-cli`, not `key-cli-hook`). Empty argv **MUST NOT** be the review verb.

```sh
# BEGIN key-cli login hook
if [ -z "${KEY_CLI_LOGIN_HOOK_RAN:-}" ] \
    && [ -n "${PS1:-}" ] \
    && [ -t 0 ] && [ -t 1 ] \
    && case "$-" in *i*) true ;; *) false ;; esac \
    && [ "$(id -un)" = "key-adm" ] \
    && [ -z "${SSH_ORIGINAL_COMMAND:-}" ]; then
    KEY_CLI_LOGIN_HOOK_RAN=1
    export KEY_CLI_LOGIN_HOOK_RAN
    if ! sudo -n /usr/local/bin/key-review-hook auth-keys interactive; then
        printf '%s\n' "key-cli: login review hook skipped (sudo -n failed)" >&2
    fi
fi
# END key-cli login hook
```

### 2.3 Complete `.profile` create sample (only when absent)

```sh
# BEGIN key-cli profile source-bashrc
# Created so a bash login shell sources interactive rc (hook lives in .bashrc).
if [ -n "${BASH_VERSION:-}" ]; then
    if [ -f "${HOME}/.bashrc" ]; then
        . "${HOME}/.bashrc"
    fi
fi
# END key-cli profile source-bashrc
```

### 2.4 Heal

When interactive (`TTY=1`) **or** `KEY_CLI_TEST_HEAL_RC=1`, JSON is not 1, and `id -un` equals `key-adm` (or `KEY_ADM_USER`):

1. Plant the snippet in `{{HOME}}/.bashrc` if markers are missing. Rewrite an old `sudo -n /usr/local/bin/key-cli auth-keys interactive` or `key-cli-hook` line to `key-review-hook`.  
2. Create `.profile` only if absent (sample above). **MUST NOT** overwrite an existing `.profile`.  
3. **MUST NOT** write another user’s home. **MUST NOT** write when `HOME` is `/tmp` or under `/dev/shm`.  
4. After create/rewrite: `chown` to the corresponding user (fail closed if that account exists).  
5. Type 1 `setup` **MUST** run the same plant on `{{KEY_ADM_HOME}}` and **MUST** ensure the symlink.  
6. `auth-keys interactive` **MUST** rewrite an old product-binary / `key-cli-hook` line in key-adm’s rc to `key-review-hook`; already-common **MUST NOT** rewrite.

Call heal from `app_main` after parse (before dispatch) **and** from `setup`. Heal is silent in human help/version.

### 2.5 Live grant

F6 **MUST** allowlist:

```text
{{GLOBAL_BIN}}/key-review-hook auth-keys interactive
{{GLOBAL_BIN}}/key-review-hook --json auth-keys interactive
```

Type 0 `generate-sudoer-request` **MUST NOT** label that grant `login-hook-elev` (that JSON remains backup/restore). Dual mention: `requirement-least-privilege-user` · `requirement-shell-sudo-command`.

### 2.6 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Handlers | `key_hook_block` · `key_heal_login_rc` · `key_ensure_login_hook_symlink` · `util_align_rc_owner` |
| Env | `KEY_REVIEW_HOOK_NAME` (default `key-review-hook`) · `KEY_CLI_TEST_HEAL_RC` · `KEY_ADM_HOME` |
| Tests | **TP-HOOK-01** .. **TP-HOOK-09** in `tests/test_cli.sh` |

### 2.x Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 10 – Least privilege**: only key-adm’s login; `sudo -n` of the labeled hook.  
- **CIAO Principle 16 – Interactive**: skip scp / non-TTY; sudo fail does not exit the login.  
- **CIAO Principle 9 – Type 0/1/2**: Type 1 setup plants; Type 2 day-to-day as key-adm.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd: Type 1/2 unused. **This requirement:** do not plant the hook; do not `ln` `key-review-hook`; `setup` already fail-closed.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: no reverse-symlink; no overwrite of an existing doorbell.  
- **Intentional**: one labeled name `key-review-hook`.  
- **Anti-fragile**: rewrite old `key-cli` / `key-cli-hook` lines.  
- **Over-protect**: session flag before sudo; forbidden HOME.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Plant `sudo -n /usr/local/bin/key-cli auth-keys interactive` as the live doorbell.  
2. Invent `key-cli-hook` as a second live alias.  
3. Overwrite an existing `key-review-hook`.  
4. Reverse-symlink `key-cli` → `key-review-hook`.  
5. `ln` in test-mode into live `/usr/local/bin`.  
6. Unlink `key-review-hook` on F7.  
7. Hijack empty argv as the review verb.  
8. Exit the login shell on `sudo -n` fail.  
9. Heal under `/tmp` or `/dev/shm` (except Type 0 `rc-test --root`).

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-key.md` | Review verb handlers |
| `docs/requirements/requirement-least-privilege-user.md` | F6 hook Cmnds |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `auth-keys interactive` · `rc-test` |
| `docs/requirements/requirement-shell-path-and-shell-support.md` | `rc-test --root` fixture |
| `./key-cli` | Implementation |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-HOOK-01** .. **TP-HOOK-09** | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-09-16  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
