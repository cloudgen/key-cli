# Requirement ↔ test matrix — key-cli

**Updated:** 2026-09-16  
**Product VERSION:** 2.2.1  
**Suite:** `tests/run.sh`

| Requirement key | Area | TP families | Coverage notes |
|-----------------|------|-------------|----------------|
| requirement-class-software-dev | class | TP-CLI-01, TP-CLI-11 | Syntax + posix-sh stack |
| requirement-shell-cli-interface | shell | TP-CLI-* · TP-KEY-01/02 | Commands, flags, dispatch; domain verbs in help; Git Bash / Windows cmd; TTY **82** about (**TP-CLI-21**) |
| requirement-shell-cli-default-interaction | shell | TP-CLI-14 · **TP-CLI-21** · TP-KEY-04..07 · TP-KEY-16 · TP-KEY-20 · TP-CFG-17 · TP-CFG-22 | Numbered tree 1/2/8/9; keys **15**; on-behalf **24**/**25**; TTY **82** / typed `version` run about; unknown choice redisplay |
| requirement-shell-cli-zero-arguments | shell | TP-CLI-07, TP-CLI-14 | Non-TTY install-ensure; TTY menu |
| requirement-shell-self-management | shell | TP-LC-* (incl. **09/10** mode · **TP-LC-25**) · TP-CLI-10 | install / self-uninstall; dest **0755** (isolated `GLOBAL_BIN`); global self-update; companion **call site**; channel verbs routed. Rc bodies: `requirement-shell-path-and-shell-support` |
| requirement-shell-path-and-shell-support | shell | TP-LC-11–14 · TP-LC-20–22 · TP-LC-27–31 · TP-CLI-18 | PATH / profile; sibling; scoped uninstall; heal; `rc-test` routed |
| requirement-shell-output-requirements | shell | TP-CLI-03,05,08,09 · TP-CFG-18 | JSON / quiet / errors; nested backup is not a second JSON object |
| requirement-shell-modular-function-design | shell | (indirect) | `key_*` domain prefix; `app_main` / `out_*`; `inst_ensure_companion` — no dedicated prefix scan |
| requirement-shell-idempotency | shell | TP-LC-03,07,13,14,20,21,22 | Re-install / uninstall absent / PATH / profile; `BASHRC` create / dongle modify / VERSION+PATH no-op |
| requirement-shell-interactive-vs-noninteractive | shell | TP-LC-05 · TP-CLI-07 · TP-CLI-14 · TP-KEY-08 · TP-KEY-16 · TP-CFG-17 · TP-CFG-22 | self-uninstall confirm; empty-argv TTY vs pipe; TTY unknown menu / sudoers / restore picker redisplay; `menu --json` fail closed |
| requirement-shell-cli-storage | shell | TP-CLI-12, TP-CLI-06, TP-CLI-19, TP-CLI-20 | Isolation; about JSON storage fields; Git Bash `/dev/shm` mkdir fail-soft |
| requirement-shell-automatic-checksum | shell | TP-CSUM-01, TP-CLI-04, TP-CLI-06 | Companion **link** on install; CHECKSUM omitted from help/about. Not TP-LC-01. |
| requirement-login-interactive-review-hook | privilege | **TP-HOOK-01..09** | `key-review-hook` → `key-cli`; key-adm `.bashrc` starts `auth-keys interactive` |
| requirement-domain-key | domain | TP-CLI-04, TP-CLI-14, TP-CLI-21, **TP-KEY-01..09**, **TP-KEY-16**, **TP-KEY-10..15**, **TP-KEY-17**, **TP-KEY-18**, **TP-KEY-20..23**, **TP-CFG-01..27** | help rows; menu 1/2/8/9 + **15** request; file-based JSON approval for key-adm; Termux hide backup; archive deposit |
| requirement-domain-sshd | domain | — | **Superseded.** Suites that proved sshd/client (`TP-SSHD` / `TP-DNS` / `TP-SSH` / `TP-DL` / `TP-UL`) are **n/a** |
| requirement-shell-sudoer | shell | TP-CFG-06, TP-CFG-07, TP-CFG-17, TP-CFG-24 | JSON grant, print-sudoers, nuser hide, TTY sudoers unknown retry; wrap `util_sudo` |
| requirement-shell-config-backup | shell | TP-CFG-01..24 | `/var/key-cli` deposit; depends on shell-sudoer for 06/07 |
| requirement-sshd-config-backup | backup | TP-CFG-01..24 | Points at shell-config-backup |
| requirement-sudoer-json-file | privilege | TP-CFG-06, TP-CFG-07 | Points at shell-sudoer |
| requirement-three-layer-privilege-model | privilege | TP-CFG-06, TP-CFG-07 | Points sudoer verbs at shell-sudoer |
| requirement-least-privilege-user | privilege | TP-CFG-08, TP-CFG-15, TP-CFG-16, TP-CFG-25..27, TP-KEY-02, TP-KEY-07, TP-KEY-13 | on-behalf refuse; setup/remove-lpu root-only; Termux unused; F6 product Cmnds including queue review; F7 keeps store |
| requirement-shell-sudo-command | shell | TP-CFG-01, TP-CFG-06 | Points wrap at shell-sudoer |
| requirement-shell-termux-ish | shell | TP-LC-15, TP-LC-16, TP-LC-18, TP-LC-19, TP-KEY-04, TP-CLI-04 | not Termux: `pkg` not invoked; Termux mock: **no** `pkg install openssh`; no `wake-lock` in help |
| requirement-shell-script-coding | shell | TP-CLI-01, TP-CLI-11, TP-CLI-20, TP-KEY-09 | `sh -n`; `set -u` with HOME unset; mkdir fail-soft; no `$()` of prompt helpers |

**Absent by design (no TP Core):** folder-archive on Termux deposit, live root `useradd` for key-adm, public-network curl.

**Honest todo (not Core this cut):** `ZSHRC` / `PROFILE` env (**TP-LC-23..26**); prefix-scan for modular-function-design.
