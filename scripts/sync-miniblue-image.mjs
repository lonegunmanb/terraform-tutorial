#!/usr/bin/env node

/**
 * Propagates the canonical miniblue image tag (defined in miniblue-image.mjs)
 * into every place that references it:
 *   - terraform-tutorial/*\/assets/docker-compose.yml
 *   - terraform-tutorial/*\/init/background.sh   (the inline heredoc fallback)
 *   - .github/copilot-instructions.md            (the docs reference)
 *
 * Usage: node scripts/sync-miniblue-image.mjs
 */

import { readdirSync, readFileSync, writeFileSync, existsSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

import { MINIBLUE_IMAGE, MINIBLUE_IMAGE_REGEX } from './miniblue-image.mjs'

const __dirname = fileURLToPath(new URL('.', import.meta.url))
const root = join(__dirname, '..')
const killercodaDir = join(root, 'terraform-tutorial')

const targets = []

// Scenario assets and init scripts.
for (const name of readdirSync(killercodaDir)) {
  const scenarioDir = join(killercodaDir, name)
  if (!statSync(scenarioDir).isDirectory()) continue
  for (const candidate of [
    join(scenarioDir, 'assets', 'docker-compose.yml'),
    join(scenarioDir, 'init', 'background.sh'),
  ]) {
    if (existsSync(candidate)) targets.push(candidate)
  }
}

// Docs reference.
targets.push(join(root, '.github', 'copilot-instructions.md'))

let updatedFiles = 0
let totalReplacements = 0

for (const file of targets) {
  const original = readFileSync(file, 'utf-8')
  let fileReplacements = 0
  const updated = original.replace(MINIBLUE_IMAGE_REGEX, (match) => {
    if (match !== MINIBLUE_IMAGE) fileReplacements++
    return MINIBLUE_IMAGE
  })
  if (fileReplacements > 0) {
    writeFileSync(file, updated)
    const rel = file.slice(root.length + 1)
    console.log(`  ✔ ${rel} (${fileReplacements} replacement${fileReplacements === 1 ? '' : 's'})`)
    updatedFiles++
    totalReplacements += fileReplacements
  }
}

if (updatedFiles === 0) {
  console.log(`  ✔ All miniblue image references already pinned to ${MINIBLUE_IMAGE}.`)
} else {
  console.log(`  → Updated ${totalReplacements} reference(s) across ${updatedFiles} file(s) to ${MINIBLUE_IMAGE}.`)
}
