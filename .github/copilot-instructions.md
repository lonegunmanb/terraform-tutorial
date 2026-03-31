# Copilot Instructions — terraform-tutorial

## Project Overview

This is an interactive Terraform tutorial website built with **VitePress** (Markdown-driven static site generator) and **Killercoda** (cloud sandbox provider). The tutorial content is written in Chinese (zh-CN).

- **Frontend**: VitePress site under `docs/`, deployed to GitHub Pages via GitHub Actions.
- **Sandbox scenarios**: Killercoda scenario definitions under `killercoda/`, each providing a real Linux terminal with Terraform + LocalStack pre-installed.
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
      KillercodaEmbed.vue          # <KillercodaEmbed> component for iframe embeds

killercoda/                        # Killercoda scenario definitions
  terraform-basics/                # One directory per scenario
    index.json                     # Scenario metadata and step list
    background.sh                  # Silent setup (install tools, start LocalStack)
    foreground.sh                  # User-facing progress messages
    intro.md / step*.md / finish.md
    workspace/                     # Files copied into the student's working directory
      main.tf
      docker-compose.yml

scripts/
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
2. If the chapter has a hands-on lab, embed the sandbox:
   ```markdown
   <KillercodaEmbed src="https://killercoda.com/<USERNAME>/scenario/<SCENARIO_NAME>~embed" />
   ```
3. Run `npm run sync-sidebar` (or it runs automatically during `npm run build` via the `prebuild` hook). This updates the `// @auto-sidebar-start ... // @auto-sidebar-end` block in `config.mjs`.

### Adding a New Killercoda Scenario

1. Create a new directory under `killercoda/<scenario-name>/`.
2. Every scenario MUST contain:
   - `index.json` — title, description, step definitions, `"backend": {"imageid": "ubuntu"}`, `"interface": {"layout": "editor-terminal"}`
   - `background.sh` — installs Terraform CLI, optionally TFLint, starts LocalStack via `docker-compose up -d`, waits for health check, then `touch /tmp/.setup-done`
   - `foreground.sh` — polls `while [ ! -f /tmp/.setup-done ]` and prints a friendly progress message, then shows a welcome banner
   - `intro.md`, `step1.md` through `stepN.md`, `finish.md`
   - `workspace/` directory with pre-seeded files (`main.tf`, `docker-compose.yml`, etc.)
3. The `workspace/main.tf` must configure the AWS provider to use LocalStack endpoints (`http://localhost:4566`) with fake credentials (`access_key = "test"`, `secret_key = "test"`) and skip credential validation.
4. The `workspace/docker-compose.yml` must use `localstack/localstack:3` image, expose port 4566, set `SERVICES` to only the needed AWS services, and limit memory to 1536M.

### Sidebar Auto-Sync

- The sidebar in `config.mjs` is managed by `scripts/sync-sidebar.mjs`. **Never edit the sidebar block manually** — it will be overwritten.
- The script reads frontmatter `order` and `title` from each `docs/*.md` file (excluding `index.md`).
- Setting `sidebar: false` in frontmatter hides a page from the sidebar.
- The managed region is delimited by `// @auto-sidebar-start` and `// @auto-sidebar-end` comments in `config.mjs`. Do NOT remove or modify these markers.

### KillercodaEmbed Component

- Registered globally in `docs/.vitepress/theme/index.js`.
- Props: `src` (required, must be `https://...killercoda.com...`), `title` (optional), `height` (optional, default `"70vh"`).
- The component validates URLs — only `https://*.killercoda.com` origins are allowed; anything else renders `about:blank`.

## Build & Development Commands

| Command | Purpose |
|---------|---------|
| `npm run dev` | Start VitePress dev server with hot reload. Does NOT run sidebar sync — run `npm run sync-sidebar` manually after adding/removing `.md` files. |
| `npm run build` | Production build. Automatically runs `prebuild` (sidebar sync) first. Output: `docs/.vitepress/dist/` |
| `npm run preview` | Preview the production build locally. |
| `npm run sync-sidebar` | Manually sync sidebar config from `docs/*.md` frontmatter. |

## Content Guidelines

- All tutorial prose is written in **Chinese (zh-CN)**.
- Code comments in Terraform files may be in English or Chinese.
- Use VitePress Markdown extensions: `::: tip`, `::: warning`, `::: info` for callout blocks.
- Each Killercoda step should be completable in **3–5 minutes**.
- Keep `background.sh` scripts idempotent and silent (redirect verbose output to `/dev/null`).

## Things to Avoid

- Do NOT edit the sidebar block in `config.mjs` by hand.
- Do NOT remove the `// @auto-sidebar-start` / `// @auto-sidebar-end` markers.
- Do NOT put real AWS credentials anywhere — all scenarios use LocalStack with `test`/`test` fake credentials.
- Do NOT add services to LocalStack's `SERVICES` env var unless the chapter actually uses them (memory is limited to 1.5GB).
- Do NOT skip the `touch /tmp/.setup-done` signal at the end of `background.sh` — `foreground.sh` depends on it.
