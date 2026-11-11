---
name: agent-desktop
description: Read and operate native desktop apps (macOS, Windows, Linux) through the OS accessibility tree with the agent-desktop CLI - snapshot UI, click, type, fill forms, navigate menus, take screenshots, manage windows, and drive Electron/Chromium app internals together with agent-browser. Use when developing, testing, or debugging a desktop app (Electron, Tauri, native) or when any task needs a GUI outside the browser.
---

# agent-desktop

The full, version-matched skill is compiled into the `agent-desktop` binary, so this file only bootstraps it. Do not copy its contents here; a static copy goes stale after a CLI upgrade.

## First run

1. `agent-desktop status` - platform, permissions, supported surfaces. If `accessibility` is `denied`, run `agent-desktop permissions --guide` and ask the user to grant it to the terminal app that launches the agent.
2. `agent-desktop skills get desktop` - the core observe/act/verify loop, refs, and retry rules. Follow it.
3. `agent-desktop skills get platform` - OS-specific notes (macOS, Windows, Linux).
4. Load references only when needed: `agent-desktop skills get desktop <commands-observation|commands-interaction|commands-system|workflows>`.

If the binary is missing: `npm install -g agent-desktop`.

## When to use which tool

- Native window chrome, menus, dialogs, menu bar extras, or any non-web UI: `agent-desktop`.
- Web content (pages, or the renderer of an Electron/Chromium app launched with a DevTools port): `agent-browser` or `chrome-devtools-axi`. See https://agent-browser.dev/desktop/guides/chromium-and-electron.
- UIs that publish no accessibility tree are invisible to it; fall back to screenshots.

Docs: https://agent-browser.dev/desktop - source: https://github.com/vercel-labs/agent-desktop
