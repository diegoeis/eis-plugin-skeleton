---
name: skel-migrate
description: Moves an existing project folder (a plugin, a skill, scripts, anything) into the skel structure (src/ as the plugin root, docs/, scripts/pack.sh, dist/, README.md, AGENTS.md, CLAUDE.md). Reads README, AGENTS and CLAUDE for context, shows a short plan with the moves and the final tree, waits for approval, then only moves existing files and creates the missing ones. Use whenever the user says "migrate my plugin", "migrate this folder", "reorganize my plugin folder", "move my project into src", "organiza a pasta do meu plugin", "migra meu plugin", "migra essa pasta", "reorganiza o plugin que já existe", "coloca meu projeto nessa estrutura", or runs /eis-plugin-skeleton:skel-migrate, even if they don't say "skel". For a brand-new project, use skel-init instead.
argument-hint: "[folder-path]"
---

# skel-migrate

Moves the contents of an existing folder into the skel structure:

```
<project>/
├── src/                    plugin root: everything that isn't a project file
│   ├── .claude-plugin/plugin.json
│   └── ...
├── docs/
├── scripts/
│   ├── pack.sh
│   ├── pii-patterns.example.txt
│   └── pii-patterns.txt    local, out of git
├── dist/                   generated, out of git
├── .gitignore
├── AGENTS.md
├── CLAUDE.md
└── README.md
```

The user already decided to migrate. Your job is to execute that decision well: don't judge whether the folder should be migrated, don't explain the merits of the structure, don't recommend alternatives, and don't refuse because the folder isn't a Claude plugin yet (if there's no `plugin.json`, you create one). If something will need attention after the move, state it as a fact in one line.

**Existing files are only moved, never edited or deleted.** Moving is easy to undo; editing the user's content isn't. Missing files are created from the template at `${CLAUDE_PLUGIN_ROOT}/templates/project/`.

Talk to the user in the language they are using.

## 1. Find the folder

Use the path the user gave or mentioned. If there's none, ask which folder to migrate. If you don't have access to it in this session (in Cowork, for example), request access.

## 2. Read the context

Read only what tells you what the project is:

1. The tree: `find "<folder>" -maxdepth 2 -not -path '*/.git/*' -not -path '*/node_modules/*' | sort`.
2. `README.md`, `AGENTS.md` and `CLAUDE.md`, if they exist.
3. Any `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, if they exist.

Don't open skills, agents, commands or scripts. You don't need their content to move them.

## 3. Build the plan

**Stays at the project root:** `README.md`, `AGENTS.md`, `CLAUDE.md`, `LICENSE`, `CHANGELOG.md`, `.git/`, `.github/`, `.gitignore`, `docs/`, `dist/`, `node_modules/`, `.DS_Store`, and `.claude-plugin/marketplace.json` (a marketplace file must stay at the repo root).

**Moves into `src/`:** everything else, keeping its internal layout. If the plugin already lives in a subfolder that holds `.claude-plugin/plugin.json` (`plugin/`, for example), move that subfolder's contents into `src/` instead of the subfolder itself.

**Conflict with an existing `src/`** that isn't already the plugin root: nest it, so the old `src/` becomes `src/src/` and paths that point into it keep working. Say so in the plan.

**Created from the template, only if missing:** `src/.claude-plugin/plugin.json`, `scripts/pack.sh`, `scripts/pii-patterns.example.txt`, `scripts/pii-patterns.txt`, `.gitignore`, `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`.

**References to update** (for the plan's last line, not a judgment): find files that mention the moved folders as relative paths, so absolute or home paths like `~/.tool/scripts/` don't count. For example, with `skill/` and `scripts/` moving: `grep -rlE '(^|[^~/.[:alnum:]_-])(skill|scripts)/' "<folder>" --exclude-dir=.git --exclude-dir=node_modules`. List the files, one line each. Add `marketplace.json` entries that point to the old location, if any. If nothing matches, leave the line out.

**Author**: take it from the existing `plugin.json`, else `git config user.name`, else the author of the last commit (`git -C "<folder>" log -1 --format=%an`). If none of these exists, ask in the plan, so execution doesn't stop after approval.

## 4. Show the plan and wait

Keep it short, ideally under 30 lines: the tree goes two levels deep at most. In this order:

1. **Project**: one sentence on what it is, from the README/AGENTS.
2. **Moves**: a table `from → to`.
3. **New files**: the list from the template.
4. **Final tree**.
5. **References to update after the move** (only if the grep found any): file names, one line each, no commentary.

If the folder is a git repository with uncommitted changes, add one line saying so (committing first keeps the migration as a separate change). Don't block on it.

Wait for approval. If the user comments, adjust the plan, show what changed and wait again.

## 5. Execute

1. **Record checksums** of every existing file:

   ```bash
   CHK="$(mktemp -d)"; echo "$CHK"
   cd "<folder>" && find . -type f -not -path './.git/*' -not -path './node_modules/*' -exec shasum {} + > "$CHK/before.txt"
   ```

2. **Move.** Use `git mv` in a git repository, `mv` otherwise. Create destination folders first, and include hidden files. To nest an existing `src/`: `git mv src src.skel-tmp && mkdir src && git mv src.skel-tmp src/src`. Then remove the source folders the moves left empty with `rmdir` (it only removes empty folders).

3. **Create what's missing**, copying from `${CLAUDE_PLUGIN_ROOT}/templates/project/` only to paths that don't exist, never over an existing file:
   - `src/.claude-plugin/plugin.json`: copy `src/.claude-plugin/plugin.json.template` and rename it to `plugin.json`. Skip it if the project already has a `plugin.json`.
   - Fill `{{PLUGIN_NAME}}` (kebab-case; from the existing `plugin.json`, else the folder name), `{{PLUGIN_DESCRIPTION}}` (from the existing `plugin.json`, else one sentence from the README) and `{{AUTHOR_NAME}}` (as found in step 3) in the files you created. Use the file edit tool or a literal text replacement, not `sed`.
   - Skip `src/skills/.gitkeep` when `src/` already has content.
   - `scripts/pii-patterns.txt`: copy it from `scripts/pii-patterns.example.txt`, but only if git will ignore it. With the template's `.gitignore`, it will. With the project's own `.gitignore`, check `git -C "<folder>" check-ignore -q scripts/pii-patterns.txt`; if it isn't ignored, create only the example and say in the report that `scripts/pii-patterns.txt` needs to be added to `.gitignore`.
   - `chmod +x scripts/pack.sh` if you created it.
   - If the user isn't writing in English, translate the prose of the `README.md`, `AGENTS.md` and pii-patterns comments you created into their language, keeping names, paths, commands, code blocks and URLs as they are.

## 6. Verify

- **Nothing edited or lost**: every checksum from before must still exist afterwards.

  ```bash
  cd "<folder>" && find . -type f -not -path './.git/*' -not -path './node_modules/*' -exec shasum {} + > "$CHK/after.txt"
  awk 'NR==FNR{a[$1]++; next} {b[$1]++} END{for (h in a) if (b[h] < a[h]) print h}' "$CHK/before.txt" "$CHK/after.txt"
  ```

  The `awk` must print nothing. If it prints a checksum, find it in `$CHK/before.txt` and tell the user which file changed or went missing.
- **No placeholders left**: `grep -rn "{{" "<folder>" --exclude-dir=.git --exclude-dir=node_modules` returns nothing.
- If the `claude` command exists, run `claude plugin validate "<folder>/src/.claude-plugin/plugin.json"` and report the result as is.

Don't commit. The user reviews and commits.

## 7. Report

Short:

1. **Done**: how many items moved, which files were created, and that the checksum check passed.
2. **Still to do by hand** (only what applies): the references to update, `.gitignore` lines, a `marketplace.json` path.
3. **Other skills in this plugin**:
   - `/eis-plugin-skeleton:skel-init`: creates a new project with this structure from scratch.
   - `/eis-plugin-skeleton:skel-build`: bumps the version and runs `scripts/pack.sh` to build `dist/vX.Y.Z/` and the zip.
