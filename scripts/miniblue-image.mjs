/**
 * Single source of truth for the miniblue container image tag used by every
 * Azure-flavoured Killercoda scenario.
 *
 * To bump miniblue:
 *   1. Edit MINIBLUE_IMAGE below.
 *   2. Run `npm run sync-miniblue` (also runs automatically via prebuild).
 *
 * The sync script propagates the new tag into:
 *   - terraform-tutorial/*\/assets/docker-compose.yml
 *   - terraform-tutorial/*\/init/background.sh   (heredoc fallback)
 *   - .github/copilot-instructions.md            (the docs reference)
 *
 * Never edit those references by hand — they are managed.
 */

export const MINIBLUE_IMAGE = 'ghcr.io/lonegunmanb/miniblue:sha-fcbf8f6'

// Loose-but-anchored regex matching only the lonegunmanb miniblue image with
// any tag, so we never accidentally rewrite unrelated lines.
export const MINIBLUE_IMAGE_REGEX = /ghcr\.io\/lonegunmanb\/miniblue:[\w.-]+/g
