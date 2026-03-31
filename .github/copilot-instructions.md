# Copilot Instructions — terraform-tutorial

## Project Overview

This is an interactive Terraform tutorial website built with **VitePress** (Markdown-driven static site generator) and **Killercoda** (cloud sandbox provider). The tutorial content is written in Chinese (zh-CN).

- **Frontend**: VitePress site under `docs/`, deployed to GitHub Pages via GitHub Actions.
- **Sandbox scenarios**: Killercoda scenario definitions under `terraform-tutorial/`, each providing a real Linux terminal with Terraform + LocalStack pre-installed.
- **CI/CD**: `.github/workflows/deploy.yml` — pushes to `main` trigger `npm run build` → deploy to GitHub Pages.

## Repository Structure

```
docs/                              # VitePress content (Markdown files)
  index.md                         # Homepage (layout: home), NOT a tutorial chapter
  intro.md                         # Chapter: course introduction
  basics.md                        # Chapter: Init / Plan / Apply
  state.md                         # Chapter: state management
  tflint.md                        # Chapter: TFLint linting
  modules.md                       # Chapter: module patterns
  .vitepress/
    config.mjs                     # VitePress config (sidebar auto-managed)
    theme/index.js                 # Custom theme — registers global Vue components
    components/
      KillercodaEmbed.vue          # <KillercodaEmbed> component (link button, NOT iframe)

terraform-tutorial/                # Killercoda scenario definitions
  structure.json                   # Lists all scenarios for Killercoda discovery
  terraform-basics/                # One directory per scenario
    index.json                     # Scenario metadata, step list, asset mapping, init scripts
    init/
      background.sh               # Silent setup (sources setup-common.sh, seeds files)
      foreground.sh               # User-facing progress messages
      init.md                     # Intro page shown before Step 1
    step1/text.md                 # Each step is a directory with text.md
    step2/text.md
    step3/text.md
    finish/finish.md              # Completion page
    assets/                       # Files copied into the student's environment
      setup-common.sh             # AUTO-GENERATED — do not edit (copied by sync-setup)
      main.tf
      docker-compose.yml

scripts/
  setup-common.sh                  # Shared setup functions (SOURCE OF TRUTH)
  sync-setup-common.mjs            # Copies setup-common.sh into every scenario's assets/
  sync-sidebar.mjs                 # Auto-generates sidebar from docs/*.md frontmatter

.github/workflows/deploy.yml      # GitHub Pages deployment pipeline
```

## Key Conventions

### Adding a New Tutorial Chapter

1. Create `docs/<slug>.md` with required frontmatter:
   ```markdown
   ---
   order: <number>       # Sidebar sort order (lower = higher)
   title: <display text> # Sidebar label (falls back to first H1 heading)
   ---
   ```
2. If the chapter has a hands-on lab, link to the sandbox:
   ```markdown
   <KillercodaEmbed src="https://killercoda.com/lonegunman/course/terraform-tutorial/<SCENARIO_NAME>" />
   ```
   Note: Killercoda blocks iframe embedding (`X-Frame-Options: DENY`), so the component renders a link button that opens in a new tab.
3. Run `npm run sync-sidebar` (or it runs automatically during `npm run build` via the `prebuild` hook). This updates the `// @auto-sidebar-start ... // @auto-sidebar-end` block in `config.mjs`.

### Adding a New Killercoda Scenario

Follow the structure in `https://github.com/killercoda/scenarios-istio`.

1. Create a new directory under `terraform-tutorial/<scenario-name>/`.
2. Add the scenario to `terraform-tutorial/structure.json`:
   ```json
   { "path": "<scenario-name>" }
   ```
3. Every scenario MUST use this directory layout:
   ```
   <scenario-name>/
     index.json
     init/
       background.sh
       foreground.sh
       init.md
     step1/text.md
     step2/text.md
     ...
     finish/finish.md
     assets/
       setup-common.sh            # AUTO-GENERATED — do not edit
       main.tf
       docker-compose.yml
   ```
4. The `index.json` MUST reference init scripts in the `intro` block:
   ```json
   {
     "details": {
       "intro": {
         "text": "init/init.md",
         "background": "init/background.sh",
         "foreground": "init/foreground.sh"
       },
       "steps": [
         { "title": "...", "text": "step1/text.md" }
       ],
       "finish": { "text": "finish/finish.md" },
       "assets": {
         "host01": [
           { "file": "setup-common.sh", "target": "/root", "chmod": "+x" },
           { "file": "main.tf", "target": "/root/workspace" }
         ]
       }
     },
     "backend": { "imageid": "ubuntu" },
     "interface": { "layout": "editor-terminal" }
   }
   ```
   - Steps use `stepN/text.md` paths (directory-based, NOT flat `stepN.md`)
   - Assets use filenames relative to the `assets/` directory (NOT `workspace/main.tf`)
   - The `background` and `foreground` keys under `intro` are what make the scripts execute
   - `setup-common.sh` MUST be the first asset, targeted to `/root` with `chmod: "+x"`
5. The `init/background.sh` script should:
   - Log to `/tmp/background.log` with `exec > /tmp/background.log 2>&1` and `set -x` for debugging
   - `source /root/setup-common.sh` to load shared functions
   - Create `/root/workspace` and seed files as fallback (wrapped in `if [ ! -f ... ]`)
   - Call shared functions: `install_terraform`, `start_localstack`, `install_theia_plugin`, `finish_setup`
   - Optionally call `install_awscli` (AWS CLI v2 + `awslocal` wrapper) for scenarios that need AWS CLI verification
   - Optionally call `install_tflint` (only in scenarios that need it)
   - For scenarios needing pre-applied state, call `terraform init` / `terraform apply` before `finish_setup`
   - **Debugging**: All output is captured in `/tmp/background.log`. When a Killercoda scenario fails during environment setup (e.g. `terraform apply` errors like "connection refused", tools not found), ask the user to run `cat /tmp/background.log` in the Killercoda terminal and share the output. This log contains the full trace (`set -x`) of every command executed during setup, which is essential for diagnosing issues like failed downloads, missing packages, or services not starting.
6. The `init/foreground.sh` polls `while [ ! -f /tmp/.setup-done ]` and prints progress messages.
7. The `assets/main.tf` must configure the AWS provider to use LocalStack endpoints (`http://localhost:4566`) with fake credentials (`access_key = "test"`, `secret_key = "test"`), skip credential validation, and set `s3_use_path_style = true`.
8. The `assets/docker-compose.yml` must use `localstack/localstack:3` image, expose port 4566, set `SERVICES` to only the needed AWS services, and limit memory to 1536M.

### Shared Setup Script (`setup-common.sh`)

- **Source of truth**: `scripts/setup-common.sh` — edit ONLY this file for shared logic.
- **Auto-copied**: `scripts/sync-setup-common.mjs` copies it into every `terraform-tutorial/*/assets/` directory.
- Run `npm run sync-setup` after editing, or it runs automatically via `prebuild`.
- Do NOT edit `terraform-tutorial/*/assets/setup-common.sh` directly — changes will be overwritten.
- Available functions: `install_terraform`, `install_awscli`, `install_tflint`, `start_localstack`, `install_theia_plugin`, `finish_setup`.
- `install_awscli` installs AWS CLI v2 (official binary) and creates an `awslocal` shell wrapper that sets `--endpoint-url=http://localhost:4566` automatically.
- `start_localstack` auto-installs Docker Compose v2 plugin if missing before running `docker compose up -d`.
- Versions can be overridden via env vars: `TERRAFORM_VERSION`, `TFLINT_VERSION`.

### Sidebar Auto-Sync

- The sidebar in `config.mjs` is managed by `scripts/sync-sidebar.mjs`. **Never edit the sidebar block manually** — it will be overwritten.
- The script reads frontmatter `order` and `title` from each `docs/*.md` file (excluding `index.md`).
- Setting `sidebar: false` in frontmatter hides a page from the sidebar.
- The managed region is delimited by `// @auto-sidebar-start` and `// @auto-sidebar-end` comments in `config.mjs`. Do NOT remove or modify these markers.

### KillercodaEmbed Component

- Registered globally in `docs/.vitepress/theme/index.js`.
- Renders as a styled **link button** (opens Killercoda in a new tab) because Killercoda blocks iframe embedding via `X-Frame-Options: DENY`.
- Props: `src` (required, must be `https://...killercoda.com...`), `title` (optional), `height` (optional, default `"70vh"`).
- The component validates URLs — only `https://*.killercoda.com` origins are allowed.

## Build & Development Commands

| Command | Purpose |
|---------|---------|
| `npm run dev` | Start VitePress dev server with hot reload. Does NOT run sidebar sync — run `npm run sync-sidebar` manually after adding/removing `.md` files. |
| `npm run build` | Production build. Automatically runs `prebuild` (sidebar sync + setup sync) first. Output: `docs/.vitepress/dist/` |
| `npm run preview` | Preview the production build locally. |
| `npm run sync-sidebar` | Manually sync sidebar config from `docs/*.md` frontmatter. |
| `npm run sync-setup` | Manually copy `scripts/setup-common.sh` into every scenario's `assets/`. |

## Content Guidelines

- All tutorial prose is written in **Chinese (zh-CN)**.
- Code comments in Terraform files may be in English or Chinese.
- Use VitePress Markdown extensions: `::: tip`, `::: warning`, `::: info` for callout blocks.
- Each Killercoda step should be completable in **3–5 minutes**.
- `background.sh` logs to `/tmp/background.log` — check this file in Killercoda terminal for debugging.

## Things to Avoid

- Do NOT edit the sidebar block in `config.mjs` by hand.
- Do NOT remove the `// @auto-sidebar-start` / `// @auto-sidebar-end` markers.
- Do NOT put real AWS credentials anywhere — all scenarios use LocalStack with `test`/`test` fake credentials.
- Do NOT add services to LocalStack's `SERVICES` env var unless the chapter actually uses them (memory is limited to 1.5GB).
- Do NOT skip the `touch /tmp/.setup-done` signal at the end of `background.sh` — `foreground.sh` depends on it.
- Do NOT use `docker-compose` (v1) — use `docker compose` (v2 plugin) instead.
- Do NOT place `background.sh`/`foreground.sh` at the scenario root — they must be in `init/` and referenced in `index.json`'s `intro` block, otherwise they will not execute.
- Do NOT use flat step files (`step1.md`) — must be `step1/text.md` directory format.
- Do NOT edit `terraform-tutorial/*/assets/setup-common.sh` directly — it is auto-generated from `scripts/setup-common.sh` and will be overwritten by `npm run sync-setup`.
