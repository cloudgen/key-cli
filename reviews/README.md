# Reviews — key-cli

Public product review surface (peer of `tests/`).

| File | Role |
|------|------|
| `what-to-review.md` | Living review plan / checklist |
| `test-plan.md` | TP-* status map |
| `requirement-test-matrix.md` | Requirement → TP families |
| `lessons.md` | Durable failure modes to re-check |
| `index.md` | Report index |
| `reports/` | Dated review run reports |

**Ship unit:** `src/key-cli` / `./key-cli` (**VERSION 2.0.3**)  
**Suite:** `./tests/run.sh`  
**Last suite baseline:** see `test-plan.md`

**Review focus:** backup / restore of this login’s `~/.ssh` into `/var/key-cli`; key-adm on-behalf; Type 0 self-install.
