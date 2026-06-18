# Codebase Concerns

**Analysis Date:** 2026-06-18

---

## Tech Debt

**Missing Prompt Files Referenced in README:**
- Issue: `README.md` lists four prompts in the repository structure section, but only two exist on disk
- Missing files: `.github/prompts/analyze-work-item.prompt.md`, `.github/prompts/explain-build-error.prompt.md`
- Present files: `.github/prompts/plan-al-change.prompt.md`, `.github/prompts/review-al-pr.prompt.md`
- Impact: Agents or users following the README structure will encounter 404-equivalent errors; the two most common entry-point prompts (work item analysis, build error explanation) are absent
- Fix approach: Create the two missing prompt files following the same YAML front-matter + templated structure as the existing ones

**Commented-Out `al_compile` Tool Without Explanation:**
- Issue: Both `.github/skills/al-build-validation/SKILL.md` (line 47) and `.github/agents/al-build-tester.agent.md` (line 20) contain `<!-- - al_compile -->` — a commented-out tool with no accompanying note explaining why it is disabled or when it might be re-enabled
- Impact: Future maintainers cannot tell whether `al_compile` is deprecated, temporarily unavailable, or should be selectively used. The agent text still says "Build/Compile ausführen" (step 5 in skill, description in agent) while the only available command is `al_build`, creating a mismatch
- Fix approach: Either remove the comment entirely and update text to say "Build" only, or document the condition under which `al_compile` would be used

**Thin AL Skill Implementations Compared to Instruction Depth:**
- Issue: The five AL-specific skills only contain a single `SKILL.md` with no `rules/` subdirectory
  - `al-code-review/SKILL.md` — 40 lines vs `al-review.instructions.md` — 265 lines
  - `al-test-design/SKILL.md` — 35 lines vs `al-testing.instructions.md` — 261 lines
  - `al-devops-workitem/SKILL.md` — 45 lines; no `rules/` to extend it
- Impact: Skills are thin wrappers that add minimal guidance beyond what the instruction files already cover; agents loading skills gain little additional context
- Fix approach: Add `rules/` subdirectories to skills with domain-specific lookup tables, decision trees, and examples pulled from the instruction files

**Duplicate Security and Policy Rules Across Multiple Files:**
- Issue: The same security prohibitions are restated in at least four places:
  - `.github/policies/agent-policy.md`
  - `.github/copilot-instructions.md`
  - `.github/instructions/al-coding-standards.instructions.md`
  - Individual agent files (e.g., `al-implementer.agent.md`, `al-build-tester.agent.md`)
- Impact: When policy evolves, all duplicates must be updated simultaneously; currently the "max 3 fix loops" rule exists in `agent-policy.md` but not enforced in every agent that could run build loops
- Fix approach: Establish `.github/policies/agent-policy.md` as the single source of truth and replace duplicates with `Lies und befolge: .github/policies/agent-policy.md`

**GSD Workflow Not Initialized:**
- Issue: The `.planning/` directory contains only an empty `codebase/` subfolder; no `STATE.md`, `ROADMAP.md`, `PROJECT.md`, or active milestone exists
- Impact: GSD commands like `/gsd-progress`, `/gsd-plan-phase`, and `/gsd-execute-phase` cannot function; the session hook (`gsd-session.json`) correctly warns about this at session start but nothing has been done to resolve it
- Fix approach: Run `/gsd-new-project` to initialize the planning workspace with PROJECT.md and ROADMAP.md

---

## Known Bugs / Errors

**`debug.log` Committed to Repository:**
- Symptoms: `debug.log` in the repo root contains a Chromium/VS Code crashpad error: `[0618/080329.828:ERROR:...crashpad...: CreateFile: Das System kann die angegebene Datei nicht finden. (0x2)]`
- Files: `debug.log`
- Trigger: VS Code / Electron crashpad failure on this machine; the file was likely created by VS Code and not excluded by a `.gitignore`
- Impact: Noise in the repository; no `.gitignore` prevents future crash logs from being committed
- Fix approach: Delete `debug.log`, create a `.gitignore` with `debug.log`, `*.log`

**No `.gitignore` in Framework Repository:**
- Symptoms: Any VS Code-generated file, debug output, or accidental AL artifact (`.alpackages/`, `.altestrunner/`, `.snapshots/`) can be committed to the framework repo
- Files: (none — file is absent)
- Impact: `debug.log` has already been committed; `.altestrunner/config.json` with empty credential fields is committed; empty `.alpackages/` and `.snapshots/` directories are tracked
- Fix approach: Create `.gitignore` to exclude `debug.log`, `*.log`, `.alpackages/`, `.snapshots/`, `*.app` (AL compiled binaries)

**`.altestrunner/config.json` Contains Sensitive Field Names at Empty Values:**
- Symptoms: `.altestrunner/config.json` contains fields `securePassword`, `vmSecurePassword`, `vmUserName`, `userName`, all set to empty strings; the file is committed to the repo
- Files: `.altestrunner/config.json`
- Impact: The directory policy says AL projects must be outside the framework repo, but this config was created inside it (likely by a prior AL project that has since been removed per commit `aa620ec: chore: Remove FahrzeugVerwaltung subproject`). The file is a residual artifact with credential-shaped fields that could confuse agents or tools reading it
- Fix approach: Delete `.altestrunner/` from the framework repo and add to `.gitignore`

---

## Security Considerations

**`al-auto-dev` Uses `session_store_sql` Tool Without Documentation:**
- Risk: The `al-auto-dev.agent.md` tool list includes `session_store_sql` — a tool with SQL in its name that could interact with databases — but this tool is not documented anywhere in the framework
- Files: `.github/agents/al-auto-dev.agent.md`
- Current mitigation: None; tool scope is undefined
- Recommendations: Document what `session_store_sql` is permitted to do; define whether it can write to production databases or only read from development environments; enforce that this aligns with the "Keine produktiven Kundendaten in Prompts" rule from `agent-policy.md`

**`launch.json` Template Only Shows `UserPassword` Authentication (OnPrem):**
- Risk: The template in `.github/skills/al-build-validation/SKILL.md` hardcodes `environmentType: "OnPrem"` and `authentication: "UserPassword"`. BC SaaS (Business Central Online) requires `environmentType: "Sandbox"` and different auth flows (OAuth2, AAD). An agent following this template for a SaaS environment could create a broken or misconfigured `launch.json`
- Files: `.github/skills/al-build-validation/SKILL.md`
- Current mitigation: Description says "BC OnPrem / SaaS" but template only covers OnPrem
- Recommendations: Add a separate SaaS/cloud variant to the launch.json example, or add conditional instructions distinguishing OnPrem vs SaaS configuration

**Policy Does Not Enforce Credential Non-Storage at the Framework-Repo Level:**
- Risk: The policy correctly forbids writing credentials to files, but `al-build-tester.agent.md` leaves `launch.json` creation to the agent ("Lege danach die Datei automatisch an"). An agent could create `launch.json` files inside the framework repo (violating directory policy) or inside an AL project repo and commit them
- Files: `.github/agents/al-build-tester.agent.md`, `.github/skills/al-build-validation/SKILL.md`
- Current mitigation: Instructions say "Credentials niemals selbst in Dateien schreiben"; `launch.json` is not in `.gitignore` of target AL projects
- Recommendations: Add explicit `.gitignore` guidance for AL project `launch.json` files; note that `launch.json` should be gitignored in all AL project repos

---

## Fragile Areas

**Orchestrator Agent Relies on `runSubagent` Without Fallback:**
- Files: `.github/agents/al-auto-dev.agent.md`
- Why fragile: The entire automated pipeline (`al-planner → al-codebase-analyst → al-implementer → al-build-tester → al-reviewer → al-documenter`) depends on `runSubagent` calls. If the AI environment doesn't support sub-agent spawning (e.g., GitHub Copilot Chat vs GitHub Copilot coding agents), the entire orchestration fails silently with no fallback instructions
- Safe modification: Add a manual execution path to `al-auto-dev.agent.md` describing how to invoke each sub-agent step-by-step when `runSubagent` is unavailable
- Test coverage: No test scenarios validate that the orchestration chain produces correct outputs end-to-end

**Confidence Scoring Has No Calibration Basis:**
- Files: `.github/policies/agent-policy.md`
- Why fragile: The confidence thresholds (0.80, 0.60, 0.40, 0.00) are defined as hard thresholds with no documented methodology for how agents should calculate their own confidence score. Two agents may rate the same task at 0.72 and 0.55 respectively and take different actions
- Safe modification: Add an example rubric for common task types (e.g., "adding a field to a TableExtension = 0.90; changing posting logic with no acceptance criteria = 0.25")
- Test coverage: None

**Fix-Loop Limit Has No Documented Escalation Path:**
- Files: `.github/policies/agent-policy.md`, `.github/agents/al-build-tester.agent.md`
- Why fragile: The policy defines "maximal 3 Fix-Schleifen" but does not specify what happens after 3 failures — whether to halt, report, block the PR, or ask the user. The `al-build-tester.agent.md` says "bei Fehlern maximal 3 Korrekturschleifen zulassen" and stops there
- Safe modification: Add an explicit "after 3 loops: create a blocker report and stop" instruction to both `agent-policy.md` and `al-build-tester.agent.md`
- Test coverage: None

**`applyTo: "**/*.al"` Instructions Active in Framework Repo:**
- Files: `.github/instructions/al-coding-standards.instructions.md`, `.github/instructions/al-testing.instructions.md`, `.github/instructions/al-review.instructions.md`
- Why fragile: All three AL instruction files use `applyTo: "**/*.al"` in their front-matter. Since the framework repo is supposed to contain zero `.al` files, this glob never fires for the framework repo itself. However, if any `.al` file is accidentally placed inside the framework repo, the instructions would activate unexpectedly — providing instructions targeted at AL development rather than framework maintenance
- Safe modification: Consider changing `applyTo` to explicitly reference the external AL project paths, or document that these instructions are intentionally cross-repo

---

## Missing Documentation

**No BC Version or Runtime Version Compatibility Statement:**
- Problem: The framework has no documented minimum BC version, AL runtime version, or `app.json` constraint. BC AL code is version-sensitive (runtime 8.0 vs 12.0+ have significant differences). The `launch.json` template says `environmentType: "OnPrem"` but gives no minimum server version
- Impact: Agents may generate code incompatible with the target BC version; no guidance exists for what happens when symbols from a newer BC version don't match an older AL runtime
- Files affected: `.github/skills/al-build-validation/SKILL.md`, `.github/instructions/al-coding-standards.instructions.md`

**No Language Policy for AL Labels and Documentation:**
- Problem: All framework documentation is in German. The `al-coding-standards.instructions.md` provides code examples with English captions (`'External Reference'`, `'Specifies the external reference...'`) while all narrative text is German. There is no rule defining whether AL captions/labels/comments should be in German or English
- Impact: AI agents will produce inconsistently-languaged code; some agents may output German labels, others English
- Files affected: `.github/instructions/al-coding-standards.instructions.md`

**No Scaffold or Template for New AL Extension Projects:**
- Problem: The policy says AL extensions must be created as sibling directories outside the framework repo (e.g., `C:\Users\dloewe\{Kunde}\{ExtensionName}\`), but no `app.json` template, project scaffold, or startup checklist is provided
- Impact: Agents must guess the initial project structure; no consistency guaranteed across different customer AL extension projects
- Files affected: `.github/policies/agent-policy.md`, `.github/copilot-instructions.md`

**No Multi-Tenant or BC SaaS Guidance:**
- Problem: The framework focuses exclusively on OnPrem configuration (evidenced by `launch.json` template). BC SaaS (Business Central Online), sandboxes, per-tenant extensions (PTE), and AppSource extensions have different deployment rules, permission models, and AL restrictions
- Impact: Agents cannot correctly handle work items for SaaS tenants; no guidance on `access` property requirements for AppSource, `dataClassification` enforcement in cloud, or `environmentType: "Sandbox"` configuration
- Files affected: `.github/skills/al-build-validation/SKILL.md`, `.github/instructions/al-coding-standards.instructions.md`

**`AGENTS.md` Contains Only GSD Boilerplate:**
- Problem: The `AGENTS.md` file at the repository root (the file Copilot agents read for project context) contains only the GSD configuration block — it does not describe the BC AL Agentic Development Kit framework, its agents, or how to use them
- Impact: A new agent session starting from `AGENTS.md` gains no project context; it only learns how to invoke GSD commands
- Files: `AGENTS.md`
- Fix approach: Replace or supplement the boilerplate with a brief project description, the key agent roles, and a link to `README.md` and `agent-policy.md`

**No Branch Protection or Git Workflow Documentation:**
- Problem: `agent-policy.md` and `azure-devops.instructions.md` state that agents must not commit to `main`, but there is no documentation on how this is enforced at the repository level (e.g., branch protection rules, required reviewers, CI gates) in the actual AL project repos
- Impact: The prohibition is a soft rule relying entirely on agent compliance; any misconfigured agent or direct CLI push bypasses it
- Files: `.github/policies/agent-policy.md`, `.github/instructions/azure-devops.instructions.md`

---

## Test Coverage Gaps

**No Validation Scenarios for Agents Themselves:**
- What's not tested: There are no sample inputs and expected outputs to verify that agents (`al-planner`, `al-implementer`, etc.) behave correctly on representative AL tasks
- Files: All `.github/agents/al-*.md`
- Risk: Agent regressions (e.g., after a skill update) are undetected until a real work item produces wrong results
- Priority: High

**No Integration Test for the Full `al-auto-dev` Orchestration Pipeline:**
- What's not tested: The chain `al-planner → al-codebase-analyst → al-implementer → al-build-tester → al-reviewer → al-documenter` has no documented happy path example or test trace
- Files: `.github/agents/al-auto-dev.agent.md`
- Risk: If any sub-agent's output format changes, the downstream agent may misparse it without any alert
- Priority: High

**Build Validation Skill Has No Fallback Test for Unavailable AL Tools:**
- What's not tested: What happens when `al_downloadsymbols`, `al_build`, or `al_getdiagnostics` are unavailable (e.g., VS Code AL extension not installed, BC server unreachable)
- Files: `.github/skills/al-build-validation/SKILL.md`, `.github/agents/al-build-tester.agent.md`
- Risk: Agent may silently claim build success or enter an infinite retry loop
- Priority: Medium

---

## Dependencies at Risk

**`ado/*` Tool Namespace Used Without Documentation:**
- Risk: The `al-auto-dev.agent.md` lists `"ado/*"` in its tools array — a wildcard namespace for Azure DevOps tools. The exact tools available under this namespace, their permissions, and side effects are not documented anywhere in the framework
- Impact: An agent invoking `ado/work-items/update` could accidentally change Work Item states, assignees, or comments in Azure DevOps without the user's awareness
- Migration plan: Replace `"ado/*"` with an explicit allowlist of specific `ado/` tool names; document each tool's scope

**GSD Core at Version 1.5.0 (Externally Managed):**
- Risk: The `.github/gsd-core/` directory is managed by the GSD installer (noted in `gsd-install-state.json`). The GSD framework is at version `1.5.0` (`.github/gsd-core/VERSION`). GSD updates may overwrite, migrate, or add files without review of impact on the custom AL agents and skills
- Files: `.github/gsd-install-state.json`, `.github/gsd-core/VERSION`
- Current mitigation: Migration journal at `.github/gsd-migration-journal/` records actions; only one migration entry exists (baseline scan from 2026-06-18)
- Migration plan: Before running GSD updates, verify that AL-specific agents and skills (marked `classification: "user-owned"` in migration journal) are not overwritten; add a pre-update review step

---

*Concerns audit: 2026-06-18*
