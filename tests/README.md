# Tests — key-cli

## Run

```sh
./tests/run.sh
# or
sh tests/run.sh
```

Exit **0** when all assertions pass; **1** on failure; **2** if ship unit missing.

## Layout

| File | Focus | TP families |
|------|--------|-------------|
| `run.sh` | Entrypoint | — |
| `helpers.sh` | Asserts + isolated HOME | — |
| `test_cli.sh` | CLI surface, empty argv, domain help, TTY unknown menu retry, auth-key request/approve queue, login doorbell, removed sshd/client verbs | **TP-CLI-*** · **TP-KEY-*** · **TP-HOOK-*** |
| `test_local_lifecycle.sh` | install / self-uninstall / about / login rc / `BASHRC` fixture / `rc-test` | **TP-LC-*** · **TP-CSUM-01** |
| `test_config_backup.sh` | `backup` / `restore` / `auth-keys` / sudoers grant; Termux/Git Bash/Windows fail-closed; on-behalf refuse; LPU F6/F7 | **TP-CFG-01..27** |

## Isolation

- Temp `HOME` + `USER_BIN` + redirected `GLOBAL_BIN` for install tests  
- **`BASHRC`** redirected to a random temp folder for **TP-LC-20..22** (create / modify dongle / no-op)  
- **`KEY_HOME_ROOT` / `KEY_CLI_ROOT`** redirected for archive tests (never this-login `/home/<user>/.ssh`)  
- **No** public network  
