**file**: docs/requirements/requirement-sudoer-json-file.md  
**Status**: Active (Version 2.0.0)  
**Area**: privilege  
**Key**: `requirement-sudoer-json-file`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement **points** at `requirement-shell-sudoer` for the JSON sudoer file body (grant verbs `backup` / `restore` and `--json` twins) and the text dual. Workflow (print/generate/submit) also lives there. Do **not** duplicate emit samples here.

### 1.1 Human-facing

**In one sentence:** the JSON file you generate says this login may run `/usr/local/bin/key-cli backup` and `restore` as root with no password — not `cp`, not `chmod`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Write a grant you can read | `key-cli generate-sudoer-request` |
| The other role | sudoer-adm approves the queued JSON | inbound `/var/sudoer-cli/sudoer-request` |
| Not this file | How the archive is deposited | `requirement-shell-config-backup` |

| Includes | Excludes |
|----------|----------|
| Compact JSON; `args: ["backup"]` plus restore/`*` / `--json` twins; NOPASSWD | OS-tool paths; `backup-config`; extra argv |

| Surface | What you open | What for |
|---------|---------------|----------|
| generated JSON | grant body | review then submit |
| sudoers(5) dual | fragment text | admin install |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Make a grant | Backup and restore of `~/.ssh` | `key-cli generate-sudoer-request` |

## 2. Core Rules / Requirements (Mandatory)

1. Grant **MUST** name only `key-cli` at `{{GLOBAL_BIN}}/key-cli`.  
2. `commands[].args` **MUST** include `["backup"]`, `["backup","*"]`, `["restore","*"]`, and `--json` twins.  
3. `commands[].runas` **MUST** be `root`; tags **MUST** include `NOPASSWD`.  
4. **MUST NOT** allowlist `cp`, `mkdir`, `chmod`, `chown`, `tar`, `rm`, shells.  
5. Single grant: **MAY** omit `kind`. **MUST NOT** label this deposit `login-hook-elev`.  
6. Filename grammar for queued requests:

```text
sudoer-{{YYYYMMDD}}-key-cli-{{username}}-{{action}}-{{n}}.json
```

**Worked sample basename (add):** `sudoer-20260916-key-cli-<id -un>-add-1.json`

**Complete sample JSON grant (add):**

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

**Equivalent text dual:**

```text
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/key-cli backup
```

Full twin list lives on `requirement-shell-sudoer`.

### 2.1 Implementation Notes (this project)

**SSOT:** `requirement-shell-sudoer` §2.2–2.6. Emit: `key_sudoers_json_text_compact` / `key_sudoers_fragment_text`. Tests **TP-CFG-06** · **TP-CFG-07**.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd, generate/submit/print-sudoers **MUST** fail closed (same as backup). **This requirement:** no JSON grant on that class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: refuse OS-tool grants.  
- **Intentional**: product command only.  
- **Anti-fragile**: compact JSON for sudoer-cli convert.  
- **Over-protect**: verify `"backup"` before submit.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add `cp`/`mkdir`/`chmod` to the grant.  
2. Revive `backup-config` as the grant verb.  
3. Grant `sync-config` (dropped).

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-06** | `tests/test_config_backup.sh` | have |
| **TP-CFG-07** | `tests/test_config_backup.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-sudoer.md` | **SSOT** — JSON + workflow + wrap |
| `docs/requirements/requirement-shell-config-backup.md` | Ops (depends on sudoer) |
| `./key-cli` | Ship unit |

**Last Updated**: 2026-09-16  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
