# AGENTS.md

Repository of the `eis-setup-plugin` plugin. The plugin has one skill, `init`, which creates the structure of a plugin project by copying a template.

This repo follows the same structure the plugin creates.

## Where things live

- `src/` is the plugin root. Only what is here goes into the package and the marketplace (`eis-plugins` points to `path: src`).
- `src/.claude-plugin/plugin.json` is the manifest and the single source of the version.
- `src/skills/init/SKILL.md` is the skill.
- `src/skills/init/assets/folder-template/` is the template copied into the user's project. Changing the default structure? Change it here.
- `scripts/pack.sh` packages this plugin into `dist/`. It is a copy of `src/skills/init/assets/folder-template/scripts/pack.sh`: when you change one, change the other the same way.
- `scripts/pii-patterns.txt` is local and out of git. The versioned template is `scripts/pii-patterns.example.txt`. Never copy its contents into versioned files.
- `docs/` holds specs and decisions. It doesn't go into the package.
- `dist/` is generated and stays out of git.

## Rules

- Write everything in English: docs, template files, skill instructions and script messages.
- The template has the placeholders `{{PLUGIN_NAME}}`, `{{PLUGIN_DESCRIPTION}}` and `{{AUTHOR_NAME}}`. If you add a new one, document it in the table in step 4 of `SKILL.md`.
- Keep the `.gitkeep` files in the template's empty folders (`docs/`, `src/skills/`): without them git doesn't track the folder and it disappears on install.
- Before publishing, bump `version` in `src/.claude-plugin/plugin.json`. The marketplace doesn't pin a version; with `version` in the manifest, users only get an update when that number changes.
- Run `claude plugin validate ./src` before pushing.
- Follow the official documentation: https://code.claude.com/docs/en/plugins-reference
