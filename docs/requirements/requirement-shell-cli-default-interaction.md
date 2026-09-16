**file**: docs/requirements/requirement-shell-cli-default-interaction.md
**Status**: Active (Version 1.0.1)
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **independent product law** for the key-cli **TTY numbered main menu**: front board **1 keys / 2 on-behalf / 8 self-management / 9 Exit**, child numbers that **keep the parent prefix** and **never repeat** a parent integer, **0 Back** on every submenu, and each command row printed as **number + bold short description + italic long description**.

Empty argv still follows `requirement-shell-cli-zero-arguments.md` (case 3: interactive empty argv and `menu`/`main` open this tree). Domain verbs (`backup`, `restore`, `auth-keys`, …) stay owned by `requirement-domain-key.md`. This file owns **the numbered tree**, not those handlers.

### 1.1 Human-facing

**In one sentence:** On a real terminal, `key-cli` (or `key-cli menu`) shows keys, on-behalf (when you are key-adm), and self-management — each with unique numbers; **0** walks back; **9** leaves.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Picking numbered boards on a keyboard | `key-cli` then `1` then `11` |
| The other role | Scripts and pipes that must not hang | `key-cli backup` |
| Not this file | What `backup` writes; empty-argv install-ensure | Domain + zero-arguments peers |

| Includes | Excludes |
|----------|----------|
| Front **1 / 2 / 8 / 9**; keys **11…**; on-behalf **21…**; self-management **81…**; sudoers **141…**; **0** Back | Restarting a submenu at **1**; `help` / `rc-test` as numbered rows |
| Bold short + italic long on every command row | Help pages; JSON catalogs |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./key-cli` | ship unit | live menu |
| `key-cli menu` | command | same tree |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Open the front board | Keys, on-behalf, self-management plus Exit | `key-cli` |
| Open backup | Keys board then backup | `1` then `11` (or type `backup`) |
| Leave a side board | Back to the parent list | `0` |
| Leave the program | Front Exit | `9` |

## 2. Core Rules / Requirements (Mandatory)

**Claimed:** yes. **Case:** 3 (zero-argument requirement exists). Interactive empty argv and `menu`/`main` draw this tree. Non-interactive empty argv stays install-ensure. `menu` off-TTY fails closed (`menu needs a terminal`). Interactive `menu --json` still draws the tree.

### 2.1 Front board

| Number | Short | Long | Runs |
|--------|-------|------|------|
| **1** | keys | this login `~/.ssh` backup, restore, authorized_keys | Keys submenu |
| **2** | on-behalf | as key-adm: backup/restore/auth-keys for other users | On-behalf submenu (hidden unless key-adm or root) |
| **8** | self-management | this CLI install, version, update, uninstall | Self-management submenu |
| **9** | Exit | leave the program | Return 0 |

**MUST NOT** list install, version, about, self-update, self-uninstall, help, menu, or `rc-test` on this board.

### 2.2 Numbering

**MUST:**

1. Command numbers are **unique** in the whole tree.  
2. Child command numbers **start with the parent’s digits** (**11…** under **1**, **21…** under **2**, **81…** under **8**, **141…** under **14**).  
3. Every submenu and data picker prints **0** Back (return to parent). Empty on a submenu **MUST** mean Back.  
4. Hidden rows keep their number (reserved). A hidden number is an unknown choice: warn and reprint **that** list. **MUST NOT** `out_die`.  
5. Restore archive pickers stay **1…N** plus **0** (item indexes).

**MUST NOT** restart a submenu at **1**. **MUST NOT** use **9** as submenu Exit.

### 2.3 Style

Every command row **MUST** print **number**, **bold** short description, *italic* long description (`out_menu_choice`). Header **MUST** be `**key-cli**(*VERSION*)`. Off-TTY / JSON: no CSI. README transcribes markdown bold/italic; **MUST NOT** paste raw CSI.

### 2.4 Keys submenu (parent **1**)

| Number | Short | Who |
|--------|-------|-----|
| **11** backup | POSIX Linux only |
| **12** restore | POSIX Linux only |
| **13** auth-keys | Always |
| **14** sudoers | POSIX Linux only |
| **0** Back | Always |

INFO before this list on Termux class: `backup and restore not available for …`.

### 2.5 On-behalf submenu (parent **2**)

| Number | Short | Who |
|--------|-------|-----|
| **21** backup | key-adm or root only |
| **22** restore | Same as **21** |
| **23** auth-keys | Same as **21** |
| **0** Back | Always |

When the invoker is not key-adm or root: omit row **2** on the front board (or print INFO `on-behalf features are not available except as key-adm`) and **MUST NOT** dispatch **21–23**. **MUST NOT** wrap `sudo` to unhide them.

### 2.6 Self-management submenu (parent **8**)

| Number | Short | TTY |
|--------|-------|-----|
| **81** | install | Place / ensure |
| **82** | version | Runs **about** (diagnostics). Argv `version` stays a one-liner. **INC-20260914-001**. |
| **83** | about | Same diagnostics as **82** on TTY |
| **84** | version-check | Local vs remote |
| **85** | self-update | Channel replace |
| **86** | self-uninstall | Remove |
| **0** | Back | Return to front |

### 2.7 Nested action boards

Sudoers (under **14**): **141** generate-sudoer-request, **142** submit-sudoer-request, **143** print-sudoers, **144** print-sudoers-install-script, **145** remove-project-sudoers, **0** Back.

Typed verb names still dispatch. Invalid choice: warn, reprint **this** layer, re-prompt. **MUST NOT** `$()` a `read` helper (choice is current-shell `read`).

### 2.1 Implementation Notes (this project)

| Field | Value |
|-------|--------|
| Claimed | yes |
| Case | 3 |
| Handler | `key_cmd_menu` · `key_cmd_menu_keys` · `key_cmd_menu_on_behalf` · `key_cmd_menu_self` |
| Printer | `out_menu_choice` |
| Ship unit | `./key-cli` |
| Proof | `tests/test_cli.sh` **TP-CLI-14** · **TP-CLI-21** · **TP-KEY-04..07** · **TP-KEY-16**; `tests/test_config_backup.sh` **TP-CFG-17** · **TP-CFG-22** |
| Map | `reviews/test-plan.md` |

### 2.x Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): one owner for the numbered tree so domain law does not keep a second integer map.  
- **CIAO Principle 5 – SSOT of output**: `out_menu_choice` is the row printer.  
- **CIAO Principle 16 – Interactive**: no hang off-TTY; invalid choice retries this layer.

## Under command line for normal user only

When Termux, Git Bash, or Windows cmd is detected: Type 1/2 unused; no in-tool sudo. **This requirement:** keys **11 / 12 / 14** stay hidden (INFO first); **13** auth-keys stays; on-behalf **2** stays hidden; self-management **81–86** stay Type 0. Git Bash and Windows cmd do not invoke Termux `pkg`.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: unique numbers so a typed integer cannot mean two boards.  
- **Intentional**: independent file; domain points here.  
- **Anti-fragile**: reserved hidden numbers; retry on this layer.  
- **Over-protect**: **0** Back on every submenu; do-not-capture-read.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

- Restart a submenu at **1** or reuse **1 / 2 / 8** on a child list.  
- Put install / version / about on the **front** board.  
- Treat TTY **82 version** as done when it only reprints the board header; TTY **82** and typed `version` on a numbered board **MUST** run `about`. Argv `version` stays thin.  
- Own this tree only inside `requirement-domain-key.md`.  
- `out_die` on an unknown TTY menu number.  
- `$()` a `read` helper for the choice.  
- Print short unstyled or long unstyled on a TTY.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv owner |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `menu`/`main` |
| `docs/requirements/requirement-domain-key.md` | Domain handlers; points here for numbers |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | No hang; retry |
| `docs/requirements/requirement-shell-self-management.md` | install / self-update handlers |
| `./key-cli` | Implementation |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-14** · **TP-CLI-21** | `tests/test_cli.sh` | have |
| **TP-KEY-04** .. **TP-KEY-07** · **TP-KEY-16** | `tests/test_cli.sh` | have |
| **TP-CFG-17** · **TP-CFG-22** | `tests/test_config_backup.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-09-14  
**Owner**: {{OWNER}}  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
- **`PO-STAY-IN-PROJECT-SSOT`** — no silent sibling-project write without this-turn named root + notify-before-write (**`E-BLAST-09`**)
