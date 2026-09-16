**file**: docs/requirements/requirement-shell-sudoer.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-sudoer`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the Single Source of Truth for **all sudoer-related features** on key-cli: JSON grant body, sudoers(5) text dual, Type 0 print/generate/submit/remove workflow, and the one in-tool wrap `util_sudo`. Type 1 on this product is the approved passwordless `sudo key-cli backup` / `restore` grant (this login). Type 2 is **key-adm** (`requirement-least-privilege-user`).

Copy/deposit of `~/.ssh` is **not** this file — that is `requirement-shell-config-backup`, which **depends on** this requirement.

### 1.1 Human-facing

**In one sentence:** you generate a JSON grant so sudoer-adm can let this login run `/usr/local/bin/key-cli backup` and `restore` as root with no password — not `cp`, not a raw `tar` sudoers line.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Write and queue the grant | `key-cli generate-sudoer-request` then `key-cli submit-sudoer-request` |
| The other role | sudoer-adm or a root login | approve inbound, or install the printed fragment |
| Not this file | How the file is copied | `requirement-shell-config-backup` |

| Includes | Excludes |
|----------|----------|
| print-sudoers; generate; submit; install-script; remove draft; `util_sudo`; JSON `args: ["backup"]` plus restore/`--json` twins | Writing `/etc` as a normal login; mkdir inbound; OS-tool paths |

| Surface | What you open | What for |
|---------|---------------|----------|
| `key-cli generate-sudoer-request` | command | local JSON |
| inbound | queued JSON | approval |
| `util_sudo` | wrap | only sudo call site |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Ask for the grant | JSON then queue | `key-cli generate-sudoer-request` · `key-cli submit-sudoer-request` |
| Install as root | Admin script | `key-cli print-sudoers-install-script` then `sudo sh FILE install` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Verbs (dual mention with `requirement-shell-cli-interface`)

| Verb | Behavior |
|------|----------|
| `print-sudoers [path]` | Emit fragment; no `/etc` write. Production or `--allow-test-local` |
| `print-sudoers-install-script [path]` | Write admin script; does not run as root |
| `generate-sudoer-request [path]` | Local JSON grant; not inbound |
| `submit-sudoer-request [file]` | Type 0 compose into inbound; does not mkdir inbound |
| `remove-project-sudoers [path]` | Delete user draft only |

Samples:

```text
key-cli print-sudoers
key-cli print-sudoers --allow-test-local "$HOME/.config/key-cli/sudoers.fragment-$(id -un)"
key-cli generate-sudoer-request
key-cli submit-sudoer-request
key-cli print-sudoers-install-script
key-cli remove-project-sudoers
```

### 2.2 Grant

1. Grant **MUST** name only `{{GLOBAL_BIN}}/key-cli`.  
2. `commands[].args` **MUST** include `["backup"]`, `["backup","*"]`, `["restore","*"]`, and `--json` twins.  
3. `runas` **MUST** be `root`; tags **MUST** include `NOPASSWD`.  
4. **MUST NOT** allowlist `cp`, `mkdir`, `chmod`, `chown`, `tar`, `rm`, shells.  
5. Single grant: **MAY** omit `kind`. **MUST NOT** label this deposit `login-hook-elev`.  
6. **MUST NOT** grant `auth-keys` on the Type 0 self fragment (self `auth-keys` is Type 0; on-behalf is key-adm F6).

Filename grammar:

```text
sudoer-{{YYYYMMDD}}-key-cli-{{username}}-{{action}}-{{n}}.json
```

Worked sample basename (add): `sudoer-20260912-key-cli-<id -un>-add-1.json`

Complete sample JSON (add):

```json
{
  "schema_version": 1,
  "purpose": "Allow <id -un> to run key-cli backup and restore as root.",
  "username": "<id -un>",
  "service": "key-cli",
  "action": "add",
  "commands": [
    {
      "runas": "root",
      "tags": ["NOPASSWD"],
      "path": "/usr/local/bin/key-cli",
      "args": ["backup"]
    }
  ]
}
```

Equivalent text dual:

```text
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/key-cli backup
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/key-cli backup *
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/key-cli restore *
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/key-cli --json backup
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/key-cli --json backup *
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/key-cli --json restore *
```

### 2.3 Paths and trust tier

| Kind | Path |
|------|------|
| Installed fragment | `/etc/sudoers.d/key-cli-{{username}}` |
| Draft | `{{HOME}}/.config/key-cli/sudoers.fragment-{{username}}` |
| Local JSON | `{{HOME}}/.config/key-cli/sudoer-request-{{username}}.json` |
| Inbound | `/var/sudoer-cli/sudoer-request` (must already exist) |

production = readable+executable `{{GLOBAL_BIN}}/key-cli`. test_local = only `{{USER_BIN}}`. Non-production emit **MUST** fail closed unless `--allow-test-local` or `ALLOW_TEST_LOCAL_SUDOERS=1`. Type 0 **MUST NOT** write `/etc`. **MUST NOT** mkdir inbound.

### 2.4 Wrap + sudo allow table (studied)

1. **MUST** keep one wrap `util_sudo`. **MUST NOT** scatter raw `sudo`.  
2. Already-root **MUST** run argv without sudo.  
3. Non-root production dest **MUST** use `sudo -n` matching the table.  
4. **MUST NOT** probe `sudo true` / `sudo mkdir` / `sudo cp`.

| Binary | Verb | Operand | Fragment dest | NOPASSWD? | This wrap? | Study evidence |
|--------|------|---------|---------------|-----------|------------|----------------|
| `{{GLOBAL_BIN}}/key-cli` | `backup` | none and `*` | `/etc/sudoers.d/key-cli-{{username}}` | yes | yes | this product `print-sudoers` emit |
| `{{GLOBAL_BIN}}/key-cli` | `restore` | `*` | `/etc/sudoers.d/key-cli-{{username}}` | yes | yes | this product `print-sudoers` emit |

### 2.5 Consumer

`requirement-shell-config-backup` **MUST** call `util_sudo` and this grant. **MUST NOT** invent a second wrap.

### 2.6 Implementation Notes (this project)

Handlers: `key_cmd_print_sudoers` · `key_cmd_generate_sudoer_request` · `key_cmd_submit_sudoer_request` · `key_cmd_print_sudoers_install_script` · `key_cmd_remove_project_sudoers` · `key_sudoers_json_text_compact` · `key_sudoers_fragment_text` · `util_sudo`. Call site of wrap: `key_elev_reexec` / `key_cmd_backup`. Tests **TP-CFG-06** · **TP-CFG-07** · **TP-CFG-17** · **TP-CFG-24**.

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 9 – Type 0/1/2** (https://github.com/cloudgen/ciao): Type 0 emit; Type 1 is the approved product command.  
- **CIAO Principle 10 – Least privilege** (https://github.com/cloudgen/ciao): one verb; no OS tools.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd these verbs **MUST** fail closed and the TTY menu **MUST** omit the sudoers row. `util_sudo` **MUST NOT** run. **This requirement:** no sudoer workflow on that class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Type 0 never writes `/etc`; refuse OS-tool grants.  
- **Intentional**: one wrap; one verb.  
- **Anti-fragile**: `--allow-test-local` for CI.  
- **Over-protect**: per-user fragment suffix; verb-only argv.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add `cp`/`mkdir`/`chmod` to the grant.  
2. Omit the `--json` twins or OS-tool Cmnds.  
3. Grant `sync-config`.  
4. Write `/etc/sudoers.d` from Type 0.  
5. Mkdir inbound.  
6. Guess dest as `/etc/{{username}}/key-cli` when print-sudoers says `/etc/sudoers.d/key-cli-{{username}}`.  
7. Probe `sudo true`.  
8. Split a second sudoer SSOT on the config-backup file.

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-06** | `tests/test_config_backup.sh` | have |
| **TP-CFG-07** | `tests/test_config_backup.sh` | have |
| **TP-CFG-17** · **TP-CFG-24** | `tests/test_config_backup.sh` | have |

**Matrix:** `docs/reviews/requirement-test-matrix.md`  
**Map:** `docs/reviews/test-plan.md`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-config-backup.md` | Deposit consumer (depends on this file) |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention |
| `docs/requirements/requirement-shell-sudo-command.md` | Points here (wrap slice) |
| `docs/requirements/requirement-sudoer-json-file.md` | Points here (JSON slice) |
| `docs/requirements/requirement-three-layer-privilege-model.md` | Type 0/1/2; sudoer verbs point here |
| `./key-cli` | Ship unit |

**Last Updated**: 2026-09-12  
**Owner**: key-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
