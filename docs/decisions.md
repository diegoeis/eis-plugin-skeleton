# Decisions

- **Template as real files** in `src/templates/project/`, copied with `cp -R`. It always gives the same result; generating from text in SKILL.md would vary on every run.
- **Version only in `plugin.json`'s `version`.** It's the official key (https://code.claude.com/docs/en/plugins-reference#version). `metadata` is free-form and Claude Code doesn't read it.
- **`dist/` accumulates versions** (`vX.Y.Z/` + `vX.Y.Z.zip`) and is in `.gitignore`. `pack.sh` refuses an existing version to force a version bump.
- **Plugin isolated in `src/`.** `CLAUDE.md`, `AGENTS.md` and `README.md` live at the project root: a `CLAUDE.md` at the plugin root isn't loaded and makes `claude plugin validate` warn.
- **`CLAUDE.md` only imports `@AGENTS.md`.** Content lives in one place.
- **Personal-data audit driven by a file** (`scripts/pii-patterns.txt`), configurable per project. The file is local and in `.gitignore`: the list of sensitive terms must not reach a public repository. The repo only versions `pii-patterns.example.txt`. Without the local file, `pack.sh` warns and continues.
- **Plain-text pattern file instead of a JSON config.** Regex inside JSON needs every backslash doubled, and reading JSON from bash would add a `jq` dependency. Revisit when a second local setting is actually needed; if so, avoid the name `settings.local.json`, which is Claude Code's own file.
- **Claude Code and Cowork only** for now.
- **English** for all docs, template files, skill instructions and script messages in this repo.
- **Generated projects follow the user's language.** The `skel-init` skill translates README.md, AGENTS.md and the pii-patterns comments into the language the user is using. `pack.sh`, `CLAUDE.md`, `.gitignore` and `plugin.json` stay as they are: they are code or config, and translating them risks breaking them.
- **Skill prefix `skel-`** (from skeleton): the plugin builds the skeleton of a plugin project. Skill names: `skel-init`, `skel-build`.
- **`skel-build` bumps the version for the user.** Default is patch; it suggests minor or major when the diff against the last build calls for it, and uses an explicit version when the user asks for one. The only versioned field it changes is `version` in `plugin.json` (plus a `CHANGELOG.md` entry if that file exists). The script stays `pack.sh`.
- **Template shared at `src/templates/project/`**, referenced with `${CLAUDE_PLUGIN_ROOT}`, because `skel-init` and `skel-migrate` both use it. The official docs recommend `${CLAUDE_PLUGIN_ROOT}` for resources shared between a plugin's skills.
- **`skel-migrate` only moves existing files.** Missing files are created from the template; changes to existing files (marketplace paths, `.gitignore` lines, a missing `version`) are suggested, never applied. Moving is easy to undo; editing the user's content isn't. A checksum of every file before and after proves nothing was edited.
- **`skel-migrate` handles one plugin per project.** A marketplace repo with several plugins is out of scope.
- **Manifest template outside any `.claude-plugin/` folder** (`src/templates/plugin.json.template`). Claude.ai's marketplace sync skipped the plugin because it found `templates/project/src/.claude-plugin/plugin.json` nested inside it ("plugin.json must be at .claude-plugin/plugin.json at the plugin root"). `claude plugin validate` passes in that case, so `pack.sh` now checks for nested manifests itself.
