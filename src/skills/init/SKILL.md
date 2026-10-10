---
name: init
description: Creates a new plugin project folder for Claude Code and Cowork from scratch, with src/ (the plugin root), docs/, scripts/pack.sh (packs into dist/vX.Y.Z/ and dist/vX.Y.Z.zip), README.md, AGENTS.md and CLAUDE.md, ready for the user to drop their skills into src/. Use whenever the user says "new plugin project", "start a plugin", "scaffold a plugin", "set up a plugin folder", "plugin setup", "cria um plugin novo", "inicia um projeto de plugin", "setup de plugin", "monta a estrutura de pastas do plugin", or runs /eis-setup-plugin:init, even if they don't mention folder structure. Does not reorganize existing plugins; in that case, say this mode isn't available yet.
argument-hint: "[folder-path]"
---

# init

Creates the initial structure of a plugin project by copying the template at `${CLAUDE_SKILL_DIR}/assets/folder-template/`. The template is the source of truth: copy its files, don't rewrite them from memory. That is what guarantees every project comes out the same.

The point of the structure is to separate what belongs to the project from what belongs to the plugin. `src/` is the plugin root and the only thing that goes into the package. `docs/`, `scripts/`, `README.md`, `AGENTS.md` and `CLAUDE.md` belong to the project and stay out of the zip.

Talk to the user in the language they are using, and write the project files in that language too (step 5).

## 1. Destination folder

If the user passed a path as an argument, use it. Otherwise, ask where the project should live. Ask for an absolute path; if you get a relative one, resolve it from the current directory and confirm the full path with the user.

If you don't have access to that folder in this session (in Cowork, for example), request access before going on.

Then check the folder's state, without creating anything yet:

- Doesn't exist, exists and is empty, or only contains `.git/` and `.DS_Store`: go on.
- Exists with other files: stop. Tell the user which files you found and that organizing an existing plugin isn't supported by this skill yet. Don't copy anything over it, because the template would overwrite the user's files.

## 2. Plugin details

Ask in a single message, suggesting defaults:

- **Plugin name**: suggest the destination folder's name if it's a valid name (rules below); if it isn't, don't suggest anything.
- **Description**: one sentence, on a single line, about what the plugin does.
- **Author**: the author's name. If `git config user.name` returns something, suggest it; if it's empty, just ask.

The initial version is always `0.1.0`; don't ask.

Validate the name before creating any file. Require kebab-case (lowercase letters, digits and hyphens only): Claude Code accepts other formats with just a warning, but Claude.ai marketplace sync and Cowork require kebab-case. On top of that, `claude plugin validate` fails with an error on names that:

- start with `claude-`, `anthropic-`, `anthropics-` or `cc-plugin-`;
- are exactly `claude`, `anthropic`, `anthropics`, `claude-code` or `claude-mods`;
- put `official` next to `claude` or `anthropic` (e.g. `official-claude-tools`).

If the name breaks one of these rules, explain why and ask for another. If the user insists, don't create the project: the plugin wouldn't pass validation. The name doesn't have to match the folder name.

## 3. Copy the template

Only now create the folder (if it doesn't exist) and copy:

```bash
mkdir -p "<destination>"
cp -R "${CLAUDE_SKILL_DIR}/assets/folder-template/." "<destination>/"
mkdir -p "<destination>/docs" "<destination>/src/skills"
cp "<destination>/scripts/pii-patterns.example.txt" "<destination>/scripts/pii-patterns.txt"
chmod +x "<destination>/scripts/pack.sh"
```

`pii-patterns.txt` is the local copy of the list of terms forbidden in the package. It's in the template's `.gitignore`, so the user's list never reaches the repository.

The `/.` at the end of the source is what also copies hidden files (`.gitignore`, `.claude-plugin/`, `.gitkeep`). The `mkdir -p` guarantees the empty folders in case the plugin install dropped the `.gitkeep` files, and the `chmod` keeps the script executable in case the install lost the permission.

## 4. Fill in the placeholders

Three files have placeholders: `README.md`, `AGENTS.md` and `src/.claude-plugin/plugin.json`. Replace:

| Placeholder | Value |
| --- | --- |
| `{{PLUGIN_NAME}}` | plugin name |
| `{{PLUGIN_DESCRIPTION}}` | description |
| `{{AUTHOR_NAME}}` | author |

Use the file edit tool; if it can't reach the destination, use a script that does literal text replacement. Don't use `sed`: descriptions with `/`, `&` or quotes break `sed`. In `plugin.json`, values must end up as valid JSON strings (quotes and backslashes escaped); if `jq` is available, check with `jq . "<destination>/src/.claude-plugin/plugin.json"`.

## 5. Match the user's language

The project files are for the user, so they must be written in the language the user is using with you in this session. The template ships in English. If the user is writing in another language (Portuguese, Spanish, etc.), translate the prose in these files after filling in the placeholders:

- `README.md`
- `AGENTS.md`
- `scripts/pii-patterns.example.txt`: translate it, then copy it over `scripts/pii-patterns.txt` again so both match. Every line in it is a `#` comment, including the examples; translate the illustrative words in the examples too (e.g. `your-username` → `seu-usuario`).

Translate headings, sentences and the comments in the folder trees. Keep unchanged anything that is code or a name the tooling depends on: file and folder names, paths, commands, code blocks, JSON keys and the values the user gave. Keep URLs as they are, including the `/docs/en/` links; don't guess localized doc URLs. If in doubt, leave it as is.

Don't translate `scripts/pack.sh`, `CLAUDE.md` (it only contains `@AGENTS.md`), `.gitignore` or `plugin.json`. The script and config files are code: changing them risks breaking them, and their messages are short.

If the user is writing in English, keep the files as they are.

Then confirm nothing was left behind:

```bash
grep -rn "{{" "<destination>" --exclude-dir=.git
```

The command should return nothing.

## 6. Git

If the destination isn't inside a git repository yet (`git -C "<destination>" rev-parse --is-inside-work-tree` fails), run `git init` there. Don't commit: the first commit belongs to the user.

## 7. Validate

If the `claude` command exists, run:

```bash
claude plugin validate "<destination>/src"
```

It should pass. If it reports an error, fix it before handing off; if it reports a warning, show it to the user.

## 8. Hand off

Show the created tree (`find "<destination>" -not -path '*/.git/*' | sort` or `tree -a -I .git`) and the next steps, briefly:

1. Put skills in `src/skills/<skill-name>/SKILL.md` (and agents, hooks etc. inside `src/`).
2. Fill `scripts/pii-patterns.txt` with what must not leak into the package (local paths, emails, internal names). This file stays on their machine only, out of git.
3. Test with `claude --plugin-dir ./src`.
4. To build a version, run `./scripts/pack.sh`. Output goes to `dist/vX.Y.Z/` and `dist/vX.Y.Z.zip`. The first package is `0.1.0`; from the second one on, bump `version` in `src/.claude-plugin/plugin.json` first.
