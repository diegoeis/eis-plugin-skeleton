# AGENTS.md

Repository of the `eis-setup-plugin` plugin. The plugin's skills are prefixed `skel-` (from skeleton): `skel-init` creates a plugin project from a template, `skel-migrate` moves an existing plugin into that structure, and `skel-build` bumps the version and runs `scripts/pack.sh` in such a project.

This repo follows the same structure the plugin creates.

## Where things live

- `src/` is the plugin root. Only what is here goes into the package and the marketplace (`eis-plugins` points to `path: src`).
- `src/.claude-plugin/plugin.json` is the manifest and the single source of the version.
- `src/skills/skel-*/SKILL.md` are the skills. New skills keep the `skel-` prefix.
- `src/templates/project/` is the project template, shared by `skel-init` and `skel-migrate` through `${CLAUDE_PLUGIN_ROOT}/templates/project/`. Changing the default structure? Change it here, and check that both skills still describe it correctly.
- `scripts/pack.sh` packages this plugin into `dist/`. It is a copy of `src/templates/project/scripts/pack.sh`: when you change one, change the other the same way.
- `scripts/pii-patterns.txt` is local and out of git. The versioned template is `scripts/pii-patterns.example.txt`. Never copy its contents into versioned files.
- `docs/` holds specs and decisions. It doesn't go into the package.
- `dist/` is generated and stays out of git.

## Rules

- Write everything in this repo in English: docs, template files, skill instructions and script messages. The template stays in English; the `skel-init` skill translates the generated project's prose files (README.md, AGENTS.md, pii-patterns comments) into the user's language at creation time (step 5 of `SKILL.md`).
- The template has the placeholders `{{PLUGIN_NAME}}`, `{{PLUGIN_DESCRIPTION}}` and `{{AUTHOR_NAME}}`. If you add a new one, document it in the table in step 4 of `SKILL.md`.
- When you add, remove or rename a skill, update the README table and the "Other skills" list at the end of `skel-migrate`'s `SKILL.md`.
- Keep the `.gitkeep` files in the template's empty folders (`docs/`, `src/skills/`): without them git doesn't track the folder and it disappears on install.
- Before publishing, bump `version` in `src/.claude-plugin/plugin.json`. The marketplace doesn't pin a version; with `version` in the manifest, users only get an update when that number changes.
- Run `claude plugin validate ./src` before pushing.
- Follow the official documentation: https://code.claude.com/docs/en/plugins-reference
