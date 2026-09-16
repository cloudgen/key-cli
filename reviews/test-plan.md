# Test plan — key-cli

Maps **TP-*** coverage to `tests/`.  
**Suite entry:** `./tests/run.sh`  
**Ship unit:** `src/key-cli` / `./key-cli`  
**Product VERSION:** 2.2.1  
**Last plan update:** 2026-09-16  
**Last suite run:** PASS=372 FAIL=0 SKIP=0 (2026-09-16)

Status: **have** = automated today · **todo** = needed · **optional** · **n/a** · **skip** (environment)

---

## Baseline coverage

| Area | Status | Evidence |
|------|--------|----------|
| Syntax `sh -n` | have | TP-CLI-01 |
| version / help / about human + JSON | have | TP-CLI-02..06 · TP-KEY-02 · TP-KEY-03 |
| Empty argv: non-TTY install-ensure / TTY menu | have | TP-CLI-07, TP-CLI-14 |
| Unknown + quiet + set -u HOME | have | TP-CLI-08..11 |
| Storage isolation | have | TP-CLI-12 |
| Git Bash `/dev/shm` mkdir fail-soft → AppData Temp/`cache` | have | TP-CLI-19, TP-CLI-20 |
| `backup` / `restore` / `auth-keys` / sudoers grant | have | TP-CFG-01..24 |
| Channel verbs routed (`self-update`, `version-check`); no public network in CI | have | TP-CLI-04, TP-CLI-10 |
| Removed OpenSSH sshd/client verbs fail closed | have | TP-KEY-01 |
| Local install / idempotent / uninstall / mode 0755 / login rc | have | TP-LC-01..16, TP-LC-18..22, TP-LC-27..31 |
| Termux/Git Bash/Windows: no `pkg`; backup/restore fail closed | have | TP-LC-15/16/18/19 · TP-KEY-04..06 · TP-CFG-04/11/12/13/24 |
| TTY unknown menu / sudoers / restore picker redisplay | have | TP-KEY-16 · TP-CFG-17 · TP-CFG-22 |
| Automatic companion link on install (file://) | have | TP-CSUM-01 |
| OpenSSH sshd start/stop, `dns`/`ssh`/`download`/`upload`, wake-lock | n/a | Dropped with `requirement-domain-sshd` (superseded) |
| Online curl against public GitHub | n/a | Core suite stays offline; channel is `file://` in CI |

This product **is** online-installable (`SCRIPT_URL`, `self-update`, `version-check`, companion `.sha256`). Core CI does **not** hit the public network.

---

## TP rows

### TP-CLI (CLI surface)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-CLI-01 | `sh -n` ship unit | `tests/test_cli.sh` | requirement-shell-cli-interface | **have** |
| TP-CLI-02 | version human | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-03 | version JSON | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-04 | help lists Type 0 + domain verbs; no sshd start / backup-config / wake-lock / CHECKSUM | test_cli | requirement-shell-cli-interface · requirement-domain-key · requirement-shell-automatic-checksum | **have** |
| TP-CLI-18 | help lists `rc-test` under testers heading apart from operational verbs | test_cli | requirement-shell-cli-interface · requirement-shell-path-and-shell-support | **have** |
| TP-CLI-05 | help JSON short | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-06 | about JSON storage + `key_cli_root` / `key_adm`; no CHECKSUM / sshd_platform | test_cli | requirement-shell-cli-storage · requirement-domain-key | **have** |
| TP-CLI-07 | empty argv non-interactive install-ensure | test_cli | requirement-shell-cli-zero-arguments · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-CLI-08 | unknown fail-closed | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-09 | quiet suppresses version | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-10 | `self-update` / `version-check` are **known** commands (no network) | test_cli | requirement-shell-cli-interface · requirement-shell-self-management | **have** |
| TP-CLI-11 | env -u HOME version | test_cli | class / requirement-shell-script-coding | **have** |
| TP-CLI-12 | storage isolation | test_cli | requirement-shell-cli-storage | **have** |
| TP-CLI-19 | Git Bash: `/dev/shm` mkdir fail-soft → AppData Local Temp/`cache`; no storage ERROR | test_cli | requirement-shell-cli-storage | **have** |
| TP-CLI-20 | static: resolver names Git Bash Temp; no mid-chain mkdir `out_die` | test_cli | requirement-shell-cli-storage · requirement-shell-script-coding | **have** |
| TP-CLI-14 | empty argv interactive → front 1 keys / 8 self-management / 9 Exit; keys 11–15 | test_cli | requirement-shell-cli-default-interaction · requirement-shell-cli-zero-arguments · requirement-domain-key | **have** |
| TP-CLI-21 | TTY **82** / typed `version` run about; argv `version` stays thin JSON type | test_cli | requirement-shell-cli-default-interaction · requirement-shell-cli-interface · **INC-20260914-001** | **have** |

### TP-KEY (domain: SSH user-key backup/restore)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-KEY-01 | Removed OpenSSH sshd/client verbs unknown | test_cli | requirement-domain-key · requirement-shell-cli-interface | **have** |
| TP-KEY-02 | help lists `remove-lpu` | test_cli | requirement-domain-key · requirement-least-privilege-user | **have** |
| TP-KEY-03 | about JSON `key_adm_present` | test_cli | requirement-domain-key | **have** |
| TP-KEY-04 | Termux TTY keys: INFO + hide 11; auth-keys 13 stays | test_cli | requirement-domain-key · requirement-shell-cli-default-interaction · requirement-shell-termux-ish | **have** |
| TP-KEY-05 | Git Bash TTY keys: INFO + hide 11 | test_cli | requirement-domain-key · requirement-shell-cli-default-interaction | **have** |
| TP-KEY-06 | Windows cmd TTY keys: INFO + hide 11 | test_cli | requirement-domain-key · requirement-shell-cli-default-interaction | **have** |
| TP-KEY-07 | Normal login: on-behalf INFO; no live row 2 | test_cli | requirement-shell-cli-default-interaction · requirement-least-privilege-user | **have** |
| TP-KEY-08 | `menu --json` / non-TTY fail closed with named-command Next | test_cli | requirement-domain-key · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-KEY-09 | static: no `$()` of `prompt_ask` / `prompt_yes_no`; menu consumes `TTY` | test_cli | requirement-shell-cli-default-interaction · requirement-shell-script-coding | **have** |
| TP-KEY-16 | TTY unknown menu token warns and redisplays | test_cli | requirement-domain-key · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-KEY-10 | `auth-keys request` writes JSON into inbound (A may name B) | test_cli | requirement-domain-key | **have** |
| TP-KEY-11 | request with missing inbound fail-closed + Next setup | test_cli | requirement-domain-key | **have** |
| TP-KEY-12 | request does not refuse A naming B | test_cli | requirement-domain-key | **have** |
| TP-KEY-13 | `pending` lists basename when `KEY_ADM_USER` is this login | test_cli | requirement-domain-key · requirement-least-privilege-user | **have** |
| TP-KEY-14 | `approve` appends B `authorized_keys` and moves to accepted | test_cli | requirement-domain-key | **have** |
| TP-KEY-15 | `reject` moves to declined without appending | test_cli | requirement-domain-key | **have** |
| TP-KEY-17 | Termux `auth-keys request` fail-closed | test_cli | requirement-domain-key · requirement-shell-termux-ish | **have** |
| TP-KEY-18 | public-key line with `"` refused | test_cli | requirement-domain-key | **have** |
| TP-KEY-20 | TTY keys **15** on POSIX; hidden on Termux | test_cli | requirement-domain-key · requirement-shell-cli-default-interaction | **have** |
| TP-KEY-21 | request `n` walks accepted (second file is add-2) | test_cli | requirement-domain-key | **have** |
| TP-KEY-22 | approve of incorrect JSON fail-closed; inbound kept | test_cli | requirement-domain-key | **have** |
| TP-KEY-23 | interactive skips incorrect JSON; no yes/no | test_cli | requirement-domain-key | **have** |

### TP-HOOK (login doorbell)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-HOOK-01 | `rc-test --file hook --case create` plants snippet + `key-review-hook` | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-02 | missing `.profile` created and sources `.bashrc` | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-03 | existing `.profile` unchanged | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-04 | static: non-approver identity skip | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-05 | static: `--json` skip | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-06 | second heal noop | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-07 | `util_align_rc_owner` present | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-08 | symlink `key-review-hook` → `key-cli`; no reverse; rewrite old doorbell | test_cli | requirement-login-interactive-review-hook | **have** |
| TP-HOOK-09 | `auth-keys interactive` rewrites old product-binary doorbell | test_cli | requirement-login-interactive-review-hook | **have** |

### TP-CFG (archive deposit / restore / sudoers / auth-keys)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-CFG-01 | Type 0 `backup` into writable `KEY_CLI_ROOT`; archive mode 600 | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-02 | same-day second backup increments N | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-03 | missing source fail-closed + Next | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-04 | Termux backup fail-closed | test_config_backup | requirement-shell-config-backup · requirement-shell-termux-ish | **have** |
| TP-CFG-05 | restore without `--force` refuse; `--force` extracts | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-06 | `print-sudoers --allow-test-local` backup/restore (not OS tools) | test_config_backup | requirement-shell-sudoer | **have** |
| TP-CFG-07 | `generate-sudoer-request` JSON grant | test_config_backup | requirement-shell-sudoer | **have** |
| TP-CFG-08 | on-behalf other user refused for this login | test_config_backup | requirement-least-privilege-user · requirement-domain-key | **have** |
| TP-CFG-09 | `restore list` names archive | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-10 | `auth-keys add` this login takes a global backup first | test_config_backup | requirement-shell-config-backup · requirement-domain-key | **have** |
| TP-CFG-11 | Termux `auth-keys add` fail-closed | test_config_backup | requirement-shell-config-backup · requirement-shell-termux-ish | **have** |
| TP-CFG-12 | Git Bash backup fail-closed | test_config_backup | requirement-shell-config-backup · requirement-shell-termux-ish | **have** |
| TP-CFG-13 | Windows cmd backup fail-closed | test_config_backup | requirement-shell-config-backup · requirement-shell-termux-ish | **have** |
| TP-CFG-15 | `setup` non-root fail-closed | test_config_backup | requirement-least-privilege-user | **have** |
| TP-CFG-16 | `remove-lpu` non-root / `--force` off-TTY | test_config_backup | requirement-least-privilege-user | **have** |
| TP-CFG-17 | TTY sudoers submenu unknown choice warns and redisplays | test_config_backup | requirement-shell-cli-default-interaction · requirement-shell-interactive-vs-noninteractive · requirement-shell-sudoer | **have** |
| TP-CFG-18 | nested backup from `auth-keys add --json` is one JSON object | test_config_backup | requirement-shell-config-backup · requirement-shell-output-requirements | **have** |
| TP-CFG-19 | backup reports verify counts; does not extract to verify | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-20 | restore dest `.ssh` mode 0700 | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-21 | `auth-keys list` | test_config_backup | requirement-domain-key | **have** |
| TP-CFG-22 | TTY restore picker unknown choice warns and redisplays | test_config_backup | requirement-shell-config-backup · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-CFG-23 | path-unsafe username fail closed | test_config_backup | requirement-domain-key | **have** |
| TP-CFG-24 | Termux `print-sudoers` fail-closed | test_config_backup | requirement-shell-sudoer · requirement-shell-termux-ish | **have** |
| TP-CFG-25 | Termux `setup` / `remove-lpu` fail-closed | test_config_backup | requirement-least-privilege-user · requirement-shell-termux-ish | **have** |
| TP-CFG-26 | static key-adm F6 product Cmnds including auth-keys approve/pending; no ALL / tar | test_config_backup | requirement-least-privilege-user | **have** |
| TP-CFG-27 | static F7 `userdel -r`; does not `rm -rf` the store | test_config_backup | requirement-least-privilege-user | **have** |

### TP-LC (install lifecycle) · TP-CSUM

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-LC-01..10 | install / idempotent / uninstall / about / mode 0755 | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-11..14 | PATH / profile create / no duplicate / keep body | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-15 | not Termux: `pkg` not invoked | test_local_lifecycle | requirement-shell-termux-ish | **have** |
| TP-LC-16 | Termux mock: install without `pkg install openssh` | test_local_lifecycle | requirement-shell-termux-ish · requirement-domain-key | **have** |
| TP-LC-18 | Git Bash mock: `pkg` not invoked | test_local_lifecycle | requirement-shell-termux-ish | **have** |
| TP-LC-19 | Windows cmd mock: `pkg` not invoked | test_local_lifecycle | requirement-shell-termux-ish | **have** |
| TP-LC-20..22 | `BASHRC` env create / modify dongle / VERSION+PATH no-op | test_local_lifecycle | requirement-shell-path-and-shell-support · requirement-shell-idempotency | **have** |
| TP-LC-23 / 24 | `ZSHRC` env modify / no-op | — | requirement-shell-path-and-shell-support | **todo** (when `ZSHRC` env is honored) |
| TP-LC-25 / 26 | `PROFILE` env create / keep-body | — | requirement-shell-path-and-shell-support | **todo** (when `PROFILE` env is honored) |
| TP-LC-27..31 | sibling PATH / uninstall keep / heal / `rc-test` | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-CSUM-01 | companion **link** on install; PASS or missing-sidecar warn | test_local_lifecycle | requirement-shell-automatic-checksum | **have** |

**Dropped families (n/a):** **TP-SSHD-*** · **TP-DNS-*** · **TP-SSH-*** · **TP-DL-*** · **TP-UL-*** · **TP-TX-08..16**. Those proved OpenSSH sshd/client / Termux `pkg` / wake-lock. Current domain SSOT is `requirement-domain-key`.

**Honest todo (not Core this cut):** live root `setup`/`remove-lpu` host mutate; public-network curl; prefix-scan for modular-function-design.
