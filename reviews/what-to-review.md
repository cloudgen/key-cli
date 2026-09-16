# What to review — key-cli

**Living checklist** (review plan). Product: **key-cli** — backup/restore this login’s `~/.ssh` into `/var/key-cli`.  
**Class:** software-development · domain SSOT `requirement-domain-key` · online-install channel + TTY menu / non-TTY install-ensure.  
**Always load first:** `reviews/lessons.md`

**Last plan update:** 2026-09-16  
**Ship unit VERSION:** 2.0.3  
**Suite baseline:** see `reviews/test-plan.md`

---

## Pre-flight

| # | Check | Notes |
|---|--------|-------|
| P1 | Read `docs/requirements/index.md` | Class + shell + domain-key + config deposit + sudoers + LPU |
| P2 | Confirm ship unit `src/key-cli` / `./key-cli` | `APP_NAME` / `VERSION` hard-assign (**2.0.2**); same bytes |
| P3 | Load `reviews/lessons.md` and re-check open L-* that still apply | Skip L-SUDOERS / restore lessons as parent-only |
| P4 | Run `./tests/run.sh` | Record PASS/FAIL/SKIP in report |
| P5 | Confirm install **channel** is `cloudgen/key-cli` | `SCRIPT_URL` default raw GitHub |
| P6 | Confirm removed OpenSSH verbs stay unknown | start / dns / ssh / download / upload / wake-lock |
| P7 | Human-facing | Every REQ has §1.1; README Description is people language; help does not lead with Type 0 |
| P8 | Normal-user-only CLI | Termux / Git Bash / Windows cmd: no `sudo curl`, no OpenSSH `pkg`, no wake-lock |

---

## Product law surfaces

| Surface | Path | Review focus |
|---------|------|--------------|
| Class | `requirement-class-software-dev.md` | posix-sh; Termux sshd purpose; **project nature** |
| Domain | `requirement-domain-key.md` | backup/restore/auth-keys/setup/remove-lpu/menu; Termux hide; TTY unknown choice redisplay |
| CLI interface | `requirement-shell-cli-interface.md` | This-login + domain commands, flags, dispatch; dual mention |
| Empty argv | `requirement-shell-cli-zero-arguments.md` | TTY **menu** / non-TTY **install-ensure** |
| Self-management | `requirement-shell-self-management.md` | install / self-update / self-uninstall; companion **call site** |
| Path / shell-rc | `requirement-shell-path-and-shell-support.md` | PATH + profile; sibling unify; **TP-LC-20..22**; `rc-test` ship Gap |
| Output SSOT | `requirement-shell-output-requirements.md` | `out_*`; JSON errors |
| Modular design | `requirement-shell-modular-function-design.md` | domain prefix **`sshd_*`** |
| Idempotency | `requirement-shell-idempotency.md` | Re-install / pipe re-run (not TTY empty argv); bashrc exact-PATH no-op |
| Storage | `requirement-shell-cli-storage.md` | Isolation; Git Bash `/dev/shm` mkdir fail-soft → AppData Temp/`cache` |
| Interactive vs non-interactive | `requirement-shell-interactive-vs-noninteractive.md` | TTY ask vs pipe never-wait; unknown TTY menu redisplay |
| Script coding | `requirement-shell-script-coding.md` | `set -u`; do-not-capture-read |
| Automatic checksum | `requirement-shell-automatic-checksum.md` | Companion link/value/result; CHECKSUM not on help |
| Termux-ish | `requirement-shell-termux-ish.md` | Detect / named `pkg`; Android wake lock auto-acquire + `wake-lock`; Git Bash / Windows cmd |

**Do not review as this product’s law:** folder-archive backup, restore dest whitelist, sudoers-file emit (those remain on sibling **folder-backup**).

---

## Coverage honesty (this product)

| Claim | Truth |
|-------|--------|
| Online channel | **In scope** (`SCRIPT_URL`, `self-update`, `version-check`) |
| Empty argv | Split: TTY menu / non-TTY install-ensure |
| Checksum in Core CI | **TP-CSUM-01** (file:// link + PASS-or-warn); not TP-LC-01 |
| Domain TPs | Present for status Connect, menu, pkg, start-after-install, ssh/download/upload, TTY unknown-menu retry; full start/stop/port/keys behavior still residual |

---

## Human-readability gate

- [ ] Each registered `requirement-*.md` has **§1.1 Human-facing** (one sentence, three boxes, includes/excludes, practice)
- [ ] Lead is not only Type 0 / Type 1 / euid / F6
- [ ] §1.1 says **project nature**, not **project class**
- [ ] Product README Description uses the same voice pack; Features/Usage do not lead with catalog codes
- [ ] README does **not** recommend `sudo curl | sh` for Termux / Git Bash / Windows cmd
