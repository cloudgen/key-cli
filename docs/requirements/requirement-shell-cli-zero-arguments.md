**file**: docs/requirements/requirement-shell-cli-zero-arguments.md  
**Status**: Active (Version 1.3.2)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

When you run `key-cli` with **nothing after the name**, a **terminal** opens the numbered keys menu; a **pipe** (`curl … | sh`) installs the program (or says it is already there). It must not print help.

Catalog: interactive empty argv → menu; non-interactive → Type O install-ensure (not Type N help).

### 1.0 Product type (template dual-model)

| Field | Value for key-cli |
|-------|------------------------|
| **Empty-argv type** | **Split:** interactive → domain **menu**; non-interactive → **Type O install-ensure** (not Type N help) |
| **Rationale** | Product advertises `curl … \| sh` one-liner install (pipe = no TTY). On a real terminal, no arguments opens the numbered keys menu. |

Type N (non-online-install → empty argv = help) does **not** apply to this product.

It defines what happens when the tool is invoked with **no command and no flags**, including the classic one-liner:

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli | /bin/sh
```

**Non-interactive** empty argv (pipe, CI, `--quiet` / `--json` env, no TTY) means **install-ensure** for three detect cases. **Interactive** empty argv (real terminal on stdin and stdout, not quiet/json) means the domain **menu** (`key_cmd_menu`) — dual mention `requirement-domain-sshd`.

| Case | Meaning |
|------|---------|
| **Not installed** | No managed binary at the resolved install path(s) |
| **Installed (local)** | Managed binary at the user path (`USER_BIN` / `${HOME}/.local/bin/key-cli`) |
| **Installed (global)** | Managed binary at the global path (`GLOBAL_BIN` / `/usr/local/bin/key-cli`) |

**Scope:** Empty-argv routing, detect cases (global / local / absent), messages, force boundary, exit status, interaction with TTY / quiet / json.  
**Out of scope (own requirements):** Full command catalog (`requirement-shell-cli-interface.md`); download/checksum detail (`requirement-shell-automatic-checksum.md`); full self-update/uninstall lifecycle (`requirement-shell-self-management.md`); output function catalog (`requirement-shell-output-requirements.md`); general idempotency matrix beyond empty-argv rows (`requirement-shell-idempotency.md`).

### 1.1 Human-facing

**In one sentence:** If you run `key-cli` with **no arguments** on a **terminal**, you get the numbered keys menu; if you run it from a **pipe** (`curl … | sh`), it **places itself** (or says it is already installed) — it must not print help.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | A person at a terminal, or a `curl \| sh` pipe with nobody to answer | `key-cli` on a TTY · `curl -fsSL …/key-cli \| /bin/sh` |
| The other role | Explicit verbs: help, force reinstall, uninstall, `menu` | `key-cli help` · `key-cli install --force` · `key-cli menu` |
| Not this file | Full command list, checksum, update/uninstall, output printers | `requirement-shell-cli-interface.md` and peers |

| Includes | Excludes |
|----------|----------|
| Zero tokens (`$# -eq 0`): pipe one-liner, `./key-cli` with nothing after the name | `key-cli --json` / `key-cli --quiet` (those have argv; default command stays help unless you also pass `install`) |
| Interactive empty argv → numbered domain menu; non-interactive → install-ensure | Type N help-default; hanging a menu under a pipe |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./key-cli` | Program file people install | Live empty-argv behavior |
| `key-cli` with no args | Command | Terminal → menu; pipe → install-ensure |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First install from the internet | No program is on disk yet. The pipe has no human to answer a question, so the tool **places itself** (user bin for a normal login; system bin if you already ran as root). Failure must be a real error, not a fake success. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/key-cli/main/key-cli \| /bin/sh` |
| Run it on a terminal with no arguments | You get the numbered keys menu (same as `key-cli menu`). It must **not** install-ensure and must **not** dump help. | `key-cli` (no arguments, real terminal) |
| Quiet or JSON with **no arguments** | No yes/no question and no menu. The tool still **places** the program (or no-ops if already installed). A helper that returns success without placing is a defect. | Environment already `JSON=1` or `QUIET=1`, then `key-cli` with empty argv — **not** `key-cli --json` alone |

Jargon: **Type O** (letter) means “no arguments = install-ensure” for **non-interactive** runs. That is **not** Type **0** (digit: you run as yourself). On a TTY, no arguments is the **menu**.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Definitions (portable + project)

| Term | Definition for key-cli |
|------|----------------------------|
| **Type O** | Online-install empty-argv product type: **non-interactive** empty argv = install-ensure (this product). |
| **Type N** | Non-online-install empty-argv type: empty argv = help — **out of scope** for key-cli. |
| **Empty argv / zero-arg** | `$# -eq 0` at entry to `app_main` (no command tokens; classic `curl \| sh` with no trailing args). |
| **Interactive empty argv** | `TTY=1` and not quiet/json: route to `key_cmd_menu`. |
| **Install-ensure** | Converge to “managed `key-cli` binary present”; either perform install or success no-op. **Non-interactive empty argv only.** |
| **Not installed** | `inst_is_installed` returns false (`inst_get_version` → `not installed`). |
| **Installed (local)** | Executable at `${USER_BIN}/key-cli` (default `USER_BIN=${HOME}/.local/bin`) observed by install-detect SSOT. |
| **Installed (global)** | Executable at `${GLOBAL_BIN}/key-cli` (default `GLOBAL_BIN=/usr/local/bin`) observed by install-detect SSOT. |
| **Force / reinstall** | `FORCE_REINSTALL=1` from `--force` (and related force wiring in `app_main`). Required only for deliberate replace, not for ensure. |

### 2.2 Split meaning of empty argv

1. When **argv is empty** and the run is **interactive** (`TTY=1`, `JSON=0`, `QUIET=0`), `app_main` **MUST** call `key_cmd_menu` — **MUST NOT** install-ensure and **MUST NOT** route to `app_help`.  
2. When **argv is empty** and the run is **non-interactive** (no TTY, or `JSON=1`, or `QUIET=1`), `app_main` **MUST** run **install-ensure** — **MUST NOT** open the menu and **MUST NOT** route to `app_help`.  
3. Explicit `key-cli help` remains the only full-usage path for help text. Explicit `key-cli menu` remains the named menu verb (same handler).  
4. Bootstrap **MUST** always call `app_main "$@"` so pipe one-liners reach this contract (no `${0##*/}` product-name gate).  
5. Non-interactive empty argv **MUST NOT** require the user to pass `install` or `install --force` merely because a previous ensure already succeeded.

### 2.2.1 Specializee contract (bootstrap origin → specialized B)

When this product is used as **bootstrap origin A** for a specialized product **B** (A→B only; never reverse-copy):

| Rule | MUST | MUST NOT |
|------|------|----------|
| Empty argv on B | Keep **non-interactive Type O install-ensure**; interactive empty argv **MAY** be a TTY menu when claimed | Hijack **non-interactive** empty argv for domain full-setup / host mutation; hang a menu under `curl \| sh` |
| Domain setup verb | Use an explicit command (e.g. `run`, `setup`, domain verb catalog) | Treat bare `curl \| sh` as host domain install |
| Case A helper | If B copies `inst_maybe_install` as first-install SSOT, quiet/json **MUST** call `inst_perform_install` and return its status | Copy a helper that `return 0` under quiet/json without placing the binary |
| Tests | Isolate `HOME`, `USER_BIN`, and **`GLOBAL_BIN`** so host `/usr/local/bin/${APP_NAME}` does not shadow lifecycle CI | Assume empty `HOME` alone hides a real global install |

**Rationale:** Specializees that rebind empty argv to interactive host setup break the online-install contract and confuse install-ensure with domain ops. Host-mutating domain work belongs under explicit verbs with privilege gates (see CLI interface specializee contract).

### 2.3 Normative case matrix

**Interactive empty argv** (before this matrix): `key_cmd_menu`; **does not** apply Cases A/B/C.

**Non-interactive** empty argv, `FORCE_REINSTALL=0`:

| Case | Detect condition (project) | Empty argv, `FORCE_REINSTALL=0` | Empty argv / install with force |
|------|----------------------------|--------------------------------|---------------------------------|
| **A. Not installed** | `inst_is_installed` false | Install into privilege-correct path (§2.4) | Same first-time install |
| **B. Installed — local** | User binary present via detect SSOT | Success no-op: already installed; no re-download; **no help**; **no menu** | `inst_perform_install` re-download/replace (user path when non-root) |
| **C. Installed — global** | Global binary present via detect SSOT | Success no-op: already installed; no re-download; **no help**; **no menu** | Re-download/replace (global path when root / global binary policy) |

**Already-installed rules (Cases B and C, force off):**

1. Exit status **MUST** be `0`.  
2. Human mode **MUST** use `out_success` with an **already installed** message (via `inst_perform_install` no-op path).  
3. Human mode **MAY** add `out_info` tips that `--force` / `self-update` are for **deliberate** reinstall or upgrade — **MUST NOT** imply force is required for a normal one-liner re-run.  
4. JSON mode **MUST** use structured success (`out_json` success type) with already-installed message — **MUST NOT** emit help JSON.  
5. Detect **MUST** treat either global or local managed binary as installed when that is how `inst_is_installed` / `inst_get_version` resolve paths (project SSOT today prefers global when executable there, else user path).

### 2.4 Case A — not installed (modes)

When **no managed binary** is present, **non-interactive** empty argv **MUST** place the program (or fail closed). **Interactive** empty argv **MUST** open the menu and **MUST NOT** place as a side effect.

| Mode | What a person sees | What MUST happen |
|------|--------------------|------------------|
| **Interactive** (real terminal on stdin+stdout, not quiet/json) | Numbered domain menu | `key_cmd_menu`; empty choice / Exit → 0; **no** install-ensure |
| **Non-interactive** (no terminal / `curl \| sh`) | An auto-install message | Place the program (`inst_maybe_install` non-TTY branch → `inst_perform_install`) |
| **Quiet or JSON** | No question; no menu | `inst_perform_install` (no prompt). Failure **MUST** be non-zero. **MUST NOT** return success without placing. |
| **Failure** (network, checksum, I/O) on install-ensure | An error | Non-zero exit; no fake success; no help-only output |

**Dispatcher vs helper (same outcome):**

| Path | Quiet / JSON, not installed | Human TTY | Pipe, not installed |
|------|-----------------------------|--------------------------|---------------------|
| `app_main` empty argv | **MUST** call `inst_perform_install` directly | **MUST** call `key_cmd_menu` (not install) | **MUST** auto-install (helper non-TTY branch or direct place) |
| `inst_maybe_install` itself | **MUST** call `inst_perform_install` and return its status. **MUST NOT** `return 0` without placing | Unreachable from empty argv (menu owns TTY) | Auto-install message + place |

Empty-argv quiet/json in `app_main` is **not** a license for the helper to no-op. Products copied from this bootstrap that route Case A **only** through the helper **MUST** still place the binary under quiet/json.

**Placement privilege:**

| Invoker | Target |
|---------|--------|
| root (`id -u` 0), e.g. `curl … \| sudo sh` | `${GLOBAL_BIN}/key-cli` → `/usr/local/bin/key-cli` |
| non-root | `${USER_BIN}/key-cli` → `${HOME}/.local/bin/key-cli` |

### 2.5 Equivalence to explicit `install`

| Invocation | Contract |
|------------|----------|
| Empty argv (non-interactive) | Same ensure semantics as `install` for Cases A/B/C |
| Empty argv (interactive) | Same as `menu` |
| `install` | Explicit ensure; same detect / no-op / force |
| `install --force` | Deliberate reinstall |
| `help` | Usage only — **not** empty-argv default |

### 2.6 Forbidden empty-argv outcomes

1. Dump full help when Case B or C applies.  
2. Silent success when Case A should install (or when Case B/C should acknowledge already installed).  
3. Require `--force` solely because detect says installed.  
4. Blind re-download every empty-argv run without force.  
5. Basename-gate main so `curl \| sh` never hits the empty-argv branch.  
6. Detect only one of global/local incorrectly so a present local install is treated as Case A (or the reverse) contrary to `inst_*` SSOT.  
7. Silent success from `inst_maybe_install` under quiet/json when Case A should place the binary.

### 2.7 Implementation Notes (this project)

| Item | Value for key-cli |
|------|------------------------|
| **Empty-argv type** | Interactive → `key_cmd_menu`; non-interactive → **Type O** install-ensure (not Type N help-default) |
| **Product / binary** | `key-cli` (`APP_NAME`) |
| **Ship unit** | Repo root `./key-cli` |
| **Dispatcher** | `app_main` — empty-argv block **before** flag/command parse default help |
| **Interactive empty argv** | `TTY=1` and not quiet/json → `key_cmd_menu` |
| **Install ensure** | `inst_perform_install` (quiet/json and already-installed no-op) — **non-interactive** empty argv |
| **Friendly first install** | `inst_maybe_install` (non-TTY auto) when not installed and not quiet/json. Quiet/JSON **MUST** call `inst_perform_install` (SM-BUG-01 fixed 2026-09-02). |
| **Detect SSOT** | `inst_is_installed` ← `inst_get_version` |
| **Global path** | `GLOBAL_BIN` default `/usr/local/bin` |
| **Local path** | `USER_BIN` default `${HOME}/.local/bin` |
| **Force wiring** | `--force` → `FORCE=1` and `FORCE_REINSTALL=1` in `app_main` |
| **Output SSOT** | `out_success` / `out_info` / `out_json` / errors via `out_*` |
| **Channel** | `SCRIPT_URL` (compose from `REPO_USER` / `REPO_NAME` / `APP_NAME`) for download path inside install |
| **Tests** | `tests/test_cli.sh` (**TP-CLI-07** non-TTY empty argv; **TP-CLI-14** TTY menu); `tests/test_local_lifecycle.sh` (**TP-LC-10** mode heal `0711` → `0755`; quiet/json empty argv still places). |

#### Dispatcher algorithm (normative sketch)

```sh
# Consume process TTY (measured once at startup). Overlay flags-only is still empty argv
# after parse; this product uses $# -eq 0 at the top of app_main (before flag parse).
if [ $# -eq 0 ]; then
    if [ "${TTY}" -eq 1 ] && [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
        key_cmd_menu
        exit $?
    fi
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        inst_perform_install
        exit $?
    elif inst_is_installed; then
        inst_perform_install
        exit $?
    else
        inst_maybe_install
        exit $?
    fi
fi
```

This product: `--json` with no command is **Type O install-ensure** (not JSON help). Portable mold special-case JSON help **MUST NOT** override this specialized empty-argv law.

#### Message contract (already installed, human)

- Success: `${APP_NAME} is already installed.` (or equivalent via `out_success`)  
- Optional info: force / `self-update` only for deliberate reinstall or upgrade  
- **MUST NOT** print the full `app_help` usage body on this path

### 2.8 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): One-liner re-runs must not look like broken install or force unnecessary reinstall.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Empty argv has one meaning for not-installed, local, and global.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Dual install paths + `curl \| sh` + TTY.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` owns empty-argv before help default.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): Case A auto under pipe; optional TTY confirm.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protection Rule against help-fallback regression.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Real failures non-zero; healthy re-runs success with clear text.  
- **Intentional:** Help is never the empty-argv default; interactive no-args is the menu; pipe no-args is install-ensure.  
- **Anti-fragile:** Global and local detect; idempotent second one-liner.  
- **Over-protect:** Do not “simplify” empty-argv back to `COMMAND:=help` after first install.  
- **SSOT:** `inst_is_installed` / `inst_perform_install` / `inst_maybe_install` / `out_*`.  
- **Idempotent ensure:** Case B/C force off → already installed, exit 0.

---

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** Type O empty-argv install-ensure stays Type 0 (this-login place + Termux `pkg` companion); **MUST NOT** become a sudo/apt install path.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Route **non-interactive** empty argv to `app_help` or to the domain **menu** when Case A/B/C should install-ensure.  
1b. Route **interactive** empty argv to install-ensure or to `app_help` instead of `key_cmd_menu`.  
2. Require `--force` for a healthy already-installed **non-interactive** empty-argv re-run (local or global).  
3. Handle only Case A and leave B/C as accidental help fallthrough.  
4. Break dual-path detect so local or global installs are misclassified.  
5. Blindly reinstall on every empty-argv run without `FORCE_REINSTALL`.  
6. Exit 0 with no install and no already-installed acknowledgment when detect says installed.  
7. Reintroduce a basename-only gate that skips `app_main` under `curl \| sh`.  
8. Bypass `out_*` for empty-argv user messages.  
9. Contradict this file in peer requirements by documenting “already installed → help” as normative empty-argv behavior.  
10. Let `inst_maybe_install` return success under quiet/json when Case A should place the binary (silent skip). Empty-argv bypass in `app_main` does **not** excuse a helper that no-ops.  
11. Copy this helper into a specialized product as Case A SSOT while keeping a quiet/json `return 0` without `inst_perform_install`.  
12. Strip the **Under command line for normal user only** section, or turn empty-argv ensure into a Type 1 install on that class.

**Violating this rule is a critical zero-arg / online-install regression.**

---

## 5. Definition of done

This requirement is satisfied when all of the following hold:

1. Non-interactive empty argv + not installed → Case A install path (pipe / quiet / json auto). Quiet/json through the helper **MUST** place or fail closed — not `return 0` without install.  
1b. Interactive empty argv → `key_cmd_menu`; **MUST NOT** place the binary as a side effect.  
2. Non-interactive empty argv + local install present + force off → already-installed success; not help; not menu; no re-download.  
3. Non-interactive empty argv + global install present + force off → already-installed success; not help; not menu; no re-download.  
4. Empty argv + install failure → non-zero exit.  
5. `--force` only for deliberate reinstall; not required for ensure.  
6. `help` works when invoked explicitly.  
7. Tests cover Case A failure (not installed, bad channel) and already-installed not-help for local (Case B) and global (Case C).  
8. **TP-CLI-07:** not installed + QUIET/JSON empty argv places or fail closed (not a silent `return 0`).  
9. Changes cite `requirement-shell-cli-zero-arguments`.

### Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** non-interactive empty argv install-ensure | `tests/test_cli.sh` | have |
| **TP-CLI-14** interactive empty argv menu | `tests/test_cli.sh` | have |
| **TP-LC-01** / **TP-LC-03** already-installed no-op | `tests/test_local_lifecycle.sh` | have |

**Map:** `reviews/test-plan.md`

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Full command surface; empty-argv row must match this SSOT |
| `docs/requirements/requirement-domain-sshd.md` | Menu handler and rows; dual mention of interactive empty argv |
| `docs/requirements/requirement-shell-idempotency.md` | Ensure re-run / force boundary |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY vs pipe for Case A |
| `docs/requirements/requirement-shell-self-management.md` | self-update / uninstall (not empty-argv default) |
| `docs/requirements/requirement-shell-output-requirements.md` | out_* / JSON purity |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Integrity on install download path |
| Repo root `./key-cli` | Implementation (`app_main`, `inst_*`) |
| `tests/test_cli.sh`, `tests/test_local_lifecycle.sh` | Regression coverage |

---

## 7. Revision history

| Date | Change | Author / agent |
|------|--------|----------------|
| 2026-07-14 | Initial Active v1.0.0: empty argv = install-ensure for not-installed / local / global; forbid help fallthrough | Grok (owner request) |
| 2026-07-14 | v1.1.0: Classify product as Type O (online-install) under dual-type empty-argv template model | Grok |
| 2026-08-11 | v1.2.0: Specializee contract — empty argv stays Type O; domain setup uses explicit verbs; test GLOBAL_BIN isolation | Grok |
| 2026-09-05 | v1.3.0: Interactive empty argv → domain menu; non-interactive empty argv stays Type O install-ensure | Grok (owner request) |
| 2026-09-05 | v1.3.1: Section **Under command line for normal user only** (Type O ensure stays Type 0 on Termux/Git Bash) | Grok (owner request) |
| 2026-09-06 | v1.3.2: People-language Purpose; DTV points at live `tests/test_local_lifecycle.sh` (drop ghost `test_install_lifecycle.sh` / `TP-INST-MAYBE-01`) | Grok |

---

**Last Updated**: 2026-09-06  
**Owner**: key-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 6, 16, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).

