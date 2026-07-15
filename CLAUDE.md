# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal fork of [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) — a Neovim 0.12+ configuration living at `~/.config/nvim`. Plugins are managed with the built-in `vim.pack`; `nvim-pack-lock.json` is deliberately tracked (unlike upstream) to pin plugin revisions, so commit it whenever plugin versions change.

## Commands

- **Format**: `stylua .` — run before every commit. Style comes from `.stylua.toml` (160 columns, 2-space indent, single quotes, no call parentheses, collapsed simple statements). Check without writing: `stylua --check .` Note: stylua is not on the shell PATH; it is installed by Mason at `~/.local/share/nvim/mason/bin/stylua`.
- **Smoke test**: `nvim --headless +qa!` must exit 0 with no error output after any config change. For LSP/plugin-level checks, open a real file headless and inspect `:messages`.
- **Health check**: `:checkhealth` inside Neovim for deeper diagnosis (Mason installs, clipboard provider, treesitter).
- **Plugin updates**: `:lua vim.pack.update()` (inspect pending first with `:lua vim.pack.update(nil, { offline = true })`). Tool/LSP installs go through `:Mason`.

## Architecture

- `init.lua` — the entire core config, organized into 10 labeled `SECTION` blocks (options → keymaps → vim.pack intro/build hooks → UI plugins → Telescope → LSP → formatting/conform → completion/blink.cmp → treesitter → extras). Each block is a `do ... end` scope. Find a feature by section header, not by file.
- `init-portable.lua` — a parallel copy of `init.lua` annotated with `PORT:` comments marking machine-specific assumptions (Nerd Font, truecolor, clipboard provider, mason system runtimes). **Sync rule (critical): every change to `init.lua` must be mirrored into `init-portable.lua`**, adding a `PORT:` note when the change embeds a machine-specific assumption. These two files are expected to stay functionally identical otherwise; drift between them is a bug.
- `lua/custom/plugins/` — personal plugin modules, auto-loaded by `lua/custom/plugins/init.lua` (which requires every other `*.lua` file/symlink in the directory — dropping a new file there is all that's needed). Currently `extras.lua` (oil.nvim, autotag, colorizer) and `dap.lua` (full debug setup for Python/JS/TS/C/C++/Rust/Go). These are shared by both init files and need no mirroring.
- `lua/kickstart/` and `doc/` — upstream-owned optional examples; the `kickstart.plugins.*` requires in init.lua are intentionally commented out (`custom/plugins/dap.lua` replaces kickstart's `debug.lua`).

## Upstream-owned files — do not modify

Do not edit `.github/`, `doc/`, or `lua/kickstart/`: keeping them byte-identical to upstream avoids conflicts when `custom` is rebased onto `master`. In particular, `.github/workflows/stylua.yml` never runs on this fork (it is gated to the upstream repo) — this is intentional; formatting is enforced locally with `stylua .` instead.

## Git workflow

- `master` mirrors upstream (`upstream` remote = `nvim-lua/kickstart.nvim`). **Never commit directly to `master`**; it is only updated via `git fetch upstream master && git merge upstream/master`, then pushed to `origin`.
- `custom` is the real config: `master` + personal commits, periodically rebased onto `master` and pushed with `--force-with-lease`.
- All work happens on feature branches cut from an up-to-date `custom` (`git checkout custom && git pull origin custom && git checkout -b feature/<topic>`), merged back into `custom` via GitHub PR, after which the branch is deleted.
- Commit message style: `<area>/<topic>: Past-tense description.` — e.g. `init.lua/background: Set the background explicitly before loading Nordic.`
