# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.
- Prefer these axi CLI tools over generic alternatives when the task matches, invoked as `npx -y <tool>` unless already installed globally:
  - `gh-axi` for any GitHub operation (issues, PRs, workflow runs, releases, repos, labels, Projects, Actions secrets/variables, search, raw API) instead of raw `gh` or the GitHub API.
  - `chrome-devtools-axi` for driving a real Chrome browser session (navigate, snapshot, click, fill forms, run JS, inspect console/network, screenshots, performance audits).
  - `inkloop` (my own tool, `npx -y inkloop <html-file>`) for turning a plan, comparison, diagram, table, code diff, or report into a reviewable HTML artifact the user can annotate - local-first, no accounts or cloud dependency.
  - `quota-axi` for reading local Claude/Codex/Cursor/Copilot/Grok/Kimi quota windows before deciding whether it's safe to keep spending a provider's quota.
- Use the `no-mistakes` skill (https://github.com/kunchenguid/no-mistakes/tree/main) for code review only when the user explicitly asks for it (e.g. "run no-mistakes", "gate this", "validate before pushing"). Do not invoke it by default for ordinary code review or task completion.
