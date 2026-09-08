# Project ECC surface (DAILY)

This directory is the **DAILY** set from the ECC analysis, not a full ECC install.

Installed:

- skills: `rust-patterns`, `rust-testing`, `cpp-coding-standards`, `security-review`
- agents: `rust-reviewer`, `cpp-reviewer`, `security-reviewer`
- rules: `rules/ecc/rust`, `rules/ecc/cpp`, plus the common files those rules link

Hardware safety still comes from `MSI-Linux-Center-AGENTS.md` and `CLAUDE.md`.
Those outrank generic ECC web-app security checklists when they conflict.

Do not run `install-apply.js --profile` or language `rust cpp` against this repo:
those copy Django/Angular/workflow-quality files this project does not use.

Intent record: `ecc-install.json`.
