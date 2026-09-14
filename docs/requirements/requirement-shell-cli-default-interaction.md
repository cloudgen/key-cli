**file**: docs/requirements/requirement-shell-cli-default-interaction.md
**Status**: Active (Version 1.0.0)
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **independent product law** for the sshd-cli **TTY numbered main menu**: front board **1 client-side / 2 server-side / 8 self-management / 9 Exit**, child numbers that **keep the parent prefix** and **never repeat** a parent integer, **0 Back** on every submenu, and each command row printed as **number + bold short description + italic long description**.

Empty argv still follows `requirement-shell-cli-zero-arguments.md` (case 3: interactive empty argv and `menu`/`main` open this tree). Domain verbs (`status`, `dns`, `ssh`, …) stay owned by `requirement-domain-sshd.md`. This file owns **the numbered tree**, not those handlers.

### 1.1 Human-facing

**In one sentence:** On a real terminal, `sshd-cli` (or `sshd-cli menu`) shows three rooms — client-side, server-side, self-management — each with unique numbers; **0** walks back; **9** leaves.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Picking numbered boards on a keyboard | `sshd-cli` then `1` then `11` |
| The other role | Scripts and pipes that must not hang | `sshd-cli status` |
| Not this file | What `start` does to sshd; empty-argv install-ensure | Domain + zero-arguments peers |

| Includes | Excludes |
|----------|----------|
| Front **1 / 2 / 8 / 9**; client **11…**; server **21…**; self-management **81…**; dns **111…**; sudoers **171…**; **0** Back | Restarting a submenu at **1**; `help` / `rc-test` as numbered rows |
| Bold short + italic long on every command row | Help pages; JSON catalogs |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | ship unit | live menu |
| `sshd-cli menu` | command | same tree |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Open the front board | Three categories plus Exit | `sshd-cli` |
| Open SSH names | Client board then dns | `1` then `11` (or type `dns`) |
| Leave a side board | Back to the parent list | `0` |
| Leave the program | Front Exit | `9` |

## 2. Core Rules / Requirements (Mandatory)

**Claimed:** yes. **Case:** 3 (zero-argument requirement exists). Interactive empty argv and `menu`/`main` draw this tree. Non-interactive empty argv stays install-ensure. `menu` off-TTY fails closed (`menu needs a terminal`). Interactive `menu --json` still draws the tree.

### 2.1 Front board

| Number | Short | Long | Runs |
|--------|-------|------|------|
| **1** | client-side | this login OpenSSH client (`~/.ssh/config`, ssh, folders) | Client submenu |
| **2** | server-side | this host OpenSSH sshd (listen, keys, port) | Server submenu |
| **8** | self-management | this CLI install, version, update, uninstall | Self-management submenu |
| **9** | Exit | leave the program | Return 0 |

**MUST NOT** list install, version, about, self-update, self-uninstall, help, menu, or `rc-test` on this board.

### 2.2 Numbering

**MUST:**

1. Command numbers are **unique** in the whole tree.  
2. Child command numbers **start with the parent’s digits** (**11…** under **1**, **21…** under **2**, **81…** under **8**, **111…** under **11**, **171…** under **17**).  
3. Every submenu and data picker prints **0** Back (return to parent). Empty on a submenu **MUST** mean Back.  
4. Hidden rows keep their number (reserved). A hidden number is an unknown choice: warn and reprint **that** list. **MUST NOT** `out_die`.  
5. Host / folder / extra-setting pickers stay **1…N** plus **0** (item indexes).

**MUST NOT** restart a submenu at **1**. **MUST NOT** use **9** as submenu Exit.

### 2.3 Style

Every command row **MUST** print **number**, **bold** short description, *italic* long description (`out_menu_choice`). Header **MUST** be `**sshd-cli**(*VERSION*)`. Off-TTY / JSON: no CSI. README transcribes markdown bold/italic; **MUST NOT** paste raw CSI.

### 2.4 Client submenu (parent **1**)

| Number | Short | Who |
|--------|-------|-----|
| **11** dns | Host list | Always |
| **12** ssh | OpenSSH client | Always |
| **13** download | remote tar.gz | Always |
| **14** upload | local tar.gz | Reserved/hidden until the handler ships |
| **15** backup-config | | POSIX Linux only |
| **16** sync-config | | POSIX Linux only |
| **17** sudoers | | POSIX Linux only |
| **18** sync-from-remote | | Termux / Git Bash / Windows cmd numbered; POSIX Linux typed |
| **0** Back | | Always |

INFO before this list on Termux class: `backup-config and sync-config not available for …`.

### 2.5 Server submenu (parent **2**)

| Number | Short | Who |
|--------|-------|-----|
| **21** status | Always |
| **22** start | Termux class always; POSIX Linux root only (reserved hidden otherwise) |
| **23** stop | Same as **22** |
| **24** restart | Same as **22** |
| **0** Back | Always |

When **22–24** are hidden: INFO `start/stop/restart sshd features are not available for non-root in <OS-Name>` **before this list**. **MUST NOT** wrap `sudo` to unhide them.

### 2.6 Self-management submenu (parent **8**)

| Number | Short |
|--------|-------|
| **81** install |
| **82** version |
| **83** about |
| **84** version-check |
| **85** self-update |
| **86** self-uninstall |
| **0** Back |

### 2.7 Nested action boards

Dns (under **11**): **111** Edit, **112** Add, **113** Delete, **114** Unset, **0** Back.  
Sudoers (under **17**): **171** generate-sudoer-request, **172** submit-sudoer-request, **173** print-sudoers, **174** print-sudoers-install-script, **175** remove-project-sudoers, **0** Back.

Typed verb names still dispatch. Invalid choice: warn, reprint **this** layer, re-prompt. **MUST NOT** `$()` a `read` helper (choice is current-shell `read`).

### 2.1 Implementation Notes (this project)

| Field | Value |
|-------|--------|
| Claimed | yes |
| Case | 3 |
| Handler | `sshd_cmd_menu` · `sshd_cmd_menu_client` · `sshd_cmd_menu_server` · `sshd_cmd_menu_self` |
| Printer | `out_menu_choice` |
| Ship unit | `./sshd-cli` |
| Proof | `tests/test_cli.sh` **TP-CLI-14** · **TP-SSHD-03..05** · **TP-SSHD-16**; `tests/test_dns.sh` **TP-DNS-13** · **TP-DNS-20** · **TP-DNS-21** · **TP-DNS-47**; `tests/test_config_backup.sh` **TP-CFG-17** |
| Map | `reviews/test-plan.md` |

### 2.x Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): one owner for the numbered tree so domain law does not keep a second integer map.  
- **CIAO Principle 5 – SSOT of output**: `out_menu_choice` is the row printer.  
- **CIAO Principle 16 – Interactive**: no hang off-TTY; invalid choice retries this layer.

## Under command line for normal user only

When Termux, Git Bash, or Windows cmd is detected: Type 1/2 unused; no in-tool sudo. **This requirement:** client **15–17** stay hidden; server **22–24** stay visible for this login; self-management **81–86** stay Type 0. Git Bash and Windows cmd do not invoke Termux `pkg`.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: unique numbers so a typed integer cannot mean two boards.  
- **Intentional**: independent file; domain points here.  
- **Anti-fragile**: reserved hidden numbers; retry on this layer.  
- **Over-protect**: **0** Back on every submenu; do-not-capture-read.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

- Restart a submenu at **1** or reuse **1 / 2 / 8** on a child list.  
- Put install / version / about on the **front** board.  
- Own this tree only inside `requirement-domain-sshd.md`.  
- `out_die` on an unknown TTY menu number.  
- `$()` a `read` helper for the choice.  
- Print short unstyled or long unstyled on a TTY.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv owner |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `menu`/`main` |
| `docs/requirements/requirement-domain-sshd.md` | Domain handlers; points here for numbers |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | No hang; retry |
| `docs/requirements/requirement-shell-self-management.md` | install / self-update handlers |
| `./sshd-cli` | Implementation |

**Last Updated**: 2026-09-14  
**Owner**: {{OWNER}}  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
- **`PO-STAY-IN-PROJECT-SSOT`** — no silent sibling-project write without this-turn named root + notify-before-write (**`E-BLAST-09`**)
