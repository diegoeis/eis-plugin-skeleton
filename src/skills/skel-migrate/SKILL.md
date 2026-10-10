---
name: skel-migrate
description: Migrates an existing Claude Code or Cowork plugin folder to the skel structure (src/ as the plugin root, docs/, scripts/pack.sh, dist/, README.md, AGENTS.md, CLAUDE.md). Reads the folder, proposes a plan with every move and the final tree, waits for approval, then only moves existing files and creates the missing ones; changes to existing files are suggested, never applied. Use whenever the user says "migrate my plugin", "reorganize my plugin folder", "convert this plugin to the skel structure", "move my plugin into src", "organiza a pasta do meu plugin", "migra meu plugin", "reorganiza o plugin que já existe", "coloca meu plugin nessa estrutura", or runs /eis-plugin-skeleton:skel-migrate, even if they don't say "skel". For new plugins, use skel-init instead.
argument-hint: "[folder-path]"
---

# skel-migrate

Moves an existing plugin project into the skel structure:

```
<project>/
├── src/                    plugin root: only what goes into the package
│   ├── .claude-plugin/plugin.json
│   └── skills/, agents/, hooks/, ...
├── docs/                   specs and project documentation
├── scripts/
│   ├── pack.sh             builds dist/vX.Y.Z/ and dist/vX.Y.Z.zip
│   ├── pii-patterns.example.txt
│   └── pii-patterns.txt    local, out of git
├── dist/                   generated, out of git
├── .gitignore
├── AGENTS.md
├── CLAUDE.md               only "@AGENTS.md"
└── README.md
```

The template for the files this structure needs is at `${CLAUDE_PLUGIN_ROOT}/templates/project/`. Copy from it; don't write those files from memory.

**The one rule that matters most: files that already exist are only moved, never edited or deleted.** A move keeps the file name; changing a file's name is only done when the user asks for it (for example, to settle a conflict). The user's content is theirs. When an existing file needs a change (a `.gitignore` missing `dist/`, a `marketplace.json` pointing to the old path), you suggest it in the report and leave the decision to the user. Moving is safe to undo; editing someone's file isn't.

Talk to the user in the language they are using.

## 1. Find the folder

- If the user passed a path, or mentioned one in the chat, use it.
- Otherwise, if the session has a folder selected (the working directory, or a connected folder in Cowork) and it looks like a plugin project (it has a `.claude-plugin/` somewhere in the first levels), propose it and ask the user to confirm.
- Otherwise, ask which folder to migrate.

If you don't have access to that folder in this session (in Cowork, for example), request access before going on.

## 2. Understand the project

Read as little as you need, starting with what explains the project:

1. The top-level listing and a shallow tree: `find "<folder>" -maxdepth 3 -not -path '*/.git/*' -not -path '*/node_modules/*' | sort`.
2. `README.md`, `AGENTS.md` and `CLAUDE.md`, if they exist.
3. Every `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` you find.
4. `hooks/hooks.json`, `.mcp.json` and `.lsp.json`, if they exist, to see which files the plugin runs.

Don't open skills, agents or commands unless you need to settle a specific question (for example, whether a script folder is used by the plugin). To find references, prefer `grep` over reading files: `grep -rn 'CLAUDE_PLUGIN_ROOT' "<folder>"` shows which files the plugin itself uses.

From that, answer:

- **Where is the plugin root?** The folder that contains `.claude-plugin/plugin.json`. It can be the project root itself, or a subfolder (`plugin/`, `<name>/`, etc.).
- **Is it already skel?** If the plugin root is already `src/` and the project files are around it, say so, and the plan is only to create what's missing.
- **More than one plugin?** If you find several `plugin.json` files (a marketplace repo with many plugins), stop: this skill migrates one plugin per project. Ask which one, or explain that a marketplace repo should stay as it is.
- **Is it valid today?** If the `claude` command exists, run `claude plugin validate "<plugin root>/.claude-plugin/plugin.json"` and note the result. Pass the `plugin.json` path, not the folder: when a `marketplace.json` sits in the same `.claude-plugin/`, validating the folder checks the marketplace instead of the plugin. If there is a `marketplace.json`, validate it too (`claude plugin validate "<its folder's parent>"`). Problems that already exist are reported, not fixed, so they aren't blamed on the migration.

## 3. Classify every top-level item

Sort each file and folder into one of these groups.

**Plugin: moves into `src/`.** Everything Claude Code loads from the plugin root (see https://code.claude.com/docs/en/plugins-reference#standard-layout): `.claude-plugin/plugin.json`, `skills/`, `commands/`, `agents/`, `hooks/`, `.mcp.json`, `.lsp.json`, `output-styles/`, `themes/`, `monitors/`, `workflows/`, `bin/`, `settings.json`. Also any file or folder that the plugin references through `${CLAUDE_PLUGIN_ROOT}` (scripts called by hooks, an MCP server's code, assets): they must stay inside the plugin, or the plugin breaks.

**Project: stays where it is.** `README.md`, `AGENTS.md`, `CLAUDE.md`, `LICENSE`, `CHANGELOG.md`, `.git/`, `.github/`, `.gitignore`, `docs/`, and other repo files.

**A `marketplace.json` stays at `<project>/.claude-plugin/marketplace.json`** even when it shares `.claude-plugin/` with the plugin's `plugin.json`. That's where Claude Code looks for a repo's marketplace. Move only `plugin.json` into `src/.claude-plugin/`, and leave the marketplace file where it is. Its plugin entry will point to the wrong place afterwards: that goes in the suggestions as the most important one, because installs from that marketplace break until the user fixes it. `claude plugin validate` doesn't catch it (it still passes), so tell the user to confirm the fix with a real install: `claude plugin marketplace add <folder>` and then `claude plugin install <plugin>@<marketplace>`.

**Project, but in the wrong place: moves to the matching folder.** Specs, notes and documentation files lying at the root move to `docs/`. Scripts that maintain the project (release, lint, sync) move to `scripts/`, keeping their names. The exception is an existing packaging script: it's replaced in practice by the template's `scripts/pack.sh`, so leave it where it is and ask the user what to do with it (keep it, or move it under another name such as `scripts/pack.legacy.sh`).

**When the plugin root is a subfolder** (`plugin/`, for example), its contents move to `src/`, keeping their internal layout. If that subfolder also contains project files like a README, they stay with the plugin (it's the plugin's own README) unless the user decides otherwise.

**Unclear: ask.** A `scripts/` folder that isn't referenced through `${CLAUDE_PLUGIN_ROOT}` but might be called by a skill, a second README, a `marketplace.json` next to the plugin, a folder you can't place. Don't guess; put it in the plan as a question.

**Leave alone:** `.git/`, `node_modules/`, existing build outputs, `.DS_Store`.

**Conflicts.** If a destination already exists and isn't the same thing, don't overwrite or merge. Put it in the plan as a question with options. The common ones:

- **A `src/` that isn't the plugin root** (an MCP server's source code, for example). If it belongs to the plugin, the option that needs no edits is to nest it: the old `src/` becomes `src/src/`, so paths like `${CLAUDE_PLUGIN_ROOT}/src/server.js` keep resolving. A folder can't be moved into itself, so do it in three steps: `git mv src src.skel-tmp && mkdir src && git mv src.skel-tmp src/src` (plain `mv` outside git). The other options are for the user to rename it and update the references themselves, or to stop the migration.
- **A `scripts/pack.sh` that already exists**: leave it. The template's `pack.sh` goes in only if `scripts/pack.sh` is free; otherwise say the user won't have the skel `pack.sh` until they decide.

## 4. Check what will break

Moving the plugin root changes paths that other files point to. Look for them and list them as suggestions, without editing:

- **Marketplace entries** whose `source` points to the old plugin root (`"./"`, `"./plugin"`, `"path": "plugin"`), in this repo or in a marketplace repo the user mentions. They'll need to point to `src`.
- **Relative paths that leave the plugin root** (`../`) in `plugin.json`, `hooks/hooks.json` or `.mcp.json`: after the move they'll point somewhere else.
- **Docs and scripts** that mention the old paths. Search for the old plugin root's folder name as a whole word, not only followed by `/`, so commands like `cd plugin` show up too: `grep -rnw '<old root folder name>' "<folder>" --exclude-dir=.git --exclude-dir=node_modules`. When the plugin was at the project root, search for the moved folder names instead (`skills/`, `hooks/`...).
- **Missing `version`** in `plugin.json`: `scripts/pack.sh` needs it to build.
- **`.gitignore`** without `dist/` or `scripts/pii-patterns.txt`. The second one matters: `scripts/pii-patterns.txt` holds the user's list of sensitive terms and must never be committed.
- **`CLAUDE.md`** with content of its own and no `@AGENTS.md` import.

## 5. Present the plan and wait

Show the user, in this order:

1. **What the project is**: one or two sentences, from what you read.
2. **Moves**: a table `from → to` with every item that moves.
3. **New files**: what will be created from the template (only what's missing: `scripts/pack.sh`, `scripts/pii-patterns.example.txt` and `scripts/pii-patterns.txt`, `.gitignore`, `README.md`, `AGENTS.md`, `CLAUDE.md`, empty `docs/`).
4. **Stays as it is**: what you're deliberately not touching.
5. **Questions**: the unclear items and conflicts from step 3.
6. **Suggestions**: the changes to existing files from step 4, which you won't make.
7. **Final tree**.

If the folder is a git repository with uncommitted changes, say so and recommend committing first, so the migration is a separate, easy-to-review change. Don't block on it; it's the user's call.

Then wait. Don't move anything until the user approves. If they comment or change something, update the plan and show the parts that changed. Repeat until they approve.

## 6. Execute

**Record a checksum of every existing file first**, so you can prove at the end that nothing was edited. Use a fresh temporary folder, so runs don't collide:

```bash
CHK="$(mktemp -d)"; echo "$CHK"
cd "<folder>" && find . -type f -not -path './.git/*' -not -path './node_modules/*' -exec shasum {} + > "$CHK/before.txt"
```

Keep the printed path; you need it in step 7.

**Move.** In a git repository, use `git mv` so history follows the files. Otherwise, use `mv`. Create destination folders with `mkdir -p` first. Move hidden files too (`.claude-plugin/`, `.mcp.json`).

**Remove the source folders that the moves left empty** (`rmdir`, which only removes empty folders). They held nothing but the files you moved, so this isn't deleting user content. Never remove a folder that still has anything in it.

**Create what's missing** by copying from `${CLAUDE_PLUGIN_ROOT}/templates/project/`, only for paths that don't exist yet. Never copy over an existing file. Skip `src/.claude-plugin/plugin.json.template`: the plugin being migrated already has its own `plugin.json`. Then:

- Fill the placeholders `{{PLUGIN_NAME}}`, `{{PLUGIN_DESCRIPTION}}` and `{{AUTHOR_NAME}}` in the files you created, with values from the existing `plugin.json` (`name`, `description`, `author.name`). If a value is missing, or is clearly not a real description (a single letter, "TODO"), ask. Use the file edit tool or a literal text replacement, not `sed`.
- **`scripts/pii-patterns.txt` only when git will ignore it.** If you created `.gitignore` from the template, it already does. If the project had its own `.gitignore`, check with `git -C "<folder>" check-ignore -q scripts/pii-patterns.txt`; if it isn't ignored, don't create `pii-patterns.txt`. Create only the example and tell the user to add `scripts/pii-patterns.txt` to `.gitignore` before copying the example over. Otherwise the user's list of sensitive terms could be committed by the next `git add -A`.
- `chmod +x scripts/pack.sh` if you created it.
- If you created `README.md` or `AGENTS.md` and the user isn't writing in English, translate their prose (headings, sentences, tree comments) into the user's language. These are new files, so rewriting their prose is fine. Keep file names, paths, commands, code blocks and URLs as they are. The same goes for the comment lines of the pii-patterns files you created.
- Create `docs/` with `mkdir -p` if it doesn't exist.

## 7. Verify

- **Nothing was edited or lost.** Every checksum from before must still exist afterwards, at least as many times as it did before (so a lost file can't hide behind an identical copy):

  ```bash
  cd "<folder>" && find . -type f -not -path './.git/*' -not -path './node_modules/*' -exec shasum {} + > "$CHK/after.txt"
  awk 'NR==FNR{a[$1]++; next} {b[$1]++} END{for (h in a) if (b[h] < a[h]) print h}' "$CHK/before.txt" "$CHK/after.txt"
  ```

  The `awk` must print nothing. If it prints a checksum, find it in `$CHK/before.txt`: that file was changed or lost. Stop and tell the user which one.
- **The plugin still validates.** Run `claude plugin validate "<folder>/src/.claude-plugin/plugin.json"` if `claude` exists. Compare with the result from step 2: new errors are caused by the migration and must be explained; old ones were already there. A marketplace may still pass validation while its entry points to the old path, so don't read a passing marketplace as a sign that it's fine.
- **No placeholders left** in the files you created: `grep -rn "{{" "<folder>" --exclude-dir=.git --exclude-dir=node_modules`.

Don't commit. The user reviews and commits.

## 8. Report

Keep it short:

1. **What was done**: how many items moved, which files were created, and the verification results.
2. **Suggestions still open**: the list from step 4 that the user needs to apply by hand, most important first (marketplace path, `.gitignore` lines, missing `version`, etc.).
3. **Other skills in this plugin**, one line each:
   - `/eis-plugin-skeleton:skel-init`: creates a new plugin project with this structure from scratch.
   - `/eis-plugin-skeleton:skel-build`: bumps the version and runs `scripts/pack.sh` to build `dist/vX.Y.Z/` and the zip.
