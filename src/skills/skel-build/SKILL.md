---
name: skel-build
description: Builds a new version of a plugin project created by skel-init. Bumps the plugin version, kept in plugin.json as "version" or "metadata.release" (patch by default, suggests minor or major when the changes call for it, or uses the exact version the user asks for) and runs scripts/pack.sh, which validates the plugin, audits src/ for personal data and writes dist/vX.Y.Z/ and dist/vX.Y.Z.zip (or dist/<name>/ and dist/<name>.zip when the plugin has no version). Use whenever the user says "build the plugin", "package the plugin", "make a new version", "bump and build", "generate the zip", "builda o plugin", "empacota o plugin", "gera uma versão nova", "gera o zip", "sobe a versão", or runs /eis-plugin-skeleton:skel-build, even if they don't mention versions or scripts.
argument-hint: "[version]"
---

# skel-build

Builds a new version of a plugin project that follows the skel structure: `src/` is the plugin root, `src/.claude-plugin/plugin.json` holds the version (in `version` or `metadata.release`), and `scripts/pack.sh` does the packaging. This skill decides the version, writes it to `plugin.json` and runs the script. The script does the rest (validation, personal-data audit, `dist/` output); don't reimplement any of it.

Talk to the user in the language they are using.

## 1. Find the project

Use the path the user gave, or the current directory. From there, walk up until you find a folder that has both `scripts/pack.sh` and `src/.claude-plugin/plugin.json`. That folder is the project root.

If no such folder exists, stop. Say the project doesn't follow the skel structure and that `/eis-plugin-skeleton:skel-init` creates one. Don't try to package anything else, because without that structure there's no way to know what belongs in the package.

## 2. Read the versions

- **Version field**: the field that holds the version in `src/.claude-plugin/plugin.json`. It's `version` when that key exists; otherwise `metadata.release` when that one exists; otherwise there's none. Always read from and write to this same field: never add `version` to a plugin that uses `metadata.release`, or the other way around. Some projects leave `version` out on purpose, because a `version` in the manifest holds back updates in Claude Code until it changes.
- **Manifest version**: the value of that field.
- **Latest build**: the highest `vX.Y.Z` folder in `dist/`, compared as versions, not as text. This prints it without the `v` and the trailing slash: `ls -d dist/v[0-9]*/ 2>/dev/null | sed 's#dist/v##; s#/##' | sort -V | tail -1` (the `[0-9]` keeps unversioned builds such as `dist/vault-plugin/` out). None if it prints nothing.

Versions are `MAJOR.MINOR.PATCH`. If the manifest version isn't in that format, show it to the user and ask which version to build.

**No version field at all**: don't bump and don't block. Skip to step 5: `pack.sh` builds `dist/<name>/` and `dist/<name>.zip`, replacing the previous unversioned build. The exception is when the user asks for a specific version: then write it to `metadata.release`, adding a `"metadata": {"release": "X.Y.Z"}` object to `plugin.json` if it doesn't exist, and go on as a versioned build. Tell the user that from now on the plugin builds as `dist/vX.Y.Z/`; the old `dist/<name>/` build stays where it is.

## 3. Decide the version to build

Go through these cases in order and use the first that applies:

1. **The user asked for a specific version** (as an argument or in the message): use it, and write it in step 4. If it isn't higher than the latest build, warn that it goes backwards and ask for confirmation. If `dist/v<that version>` already exists, it can't be built: say so and ask for another.
2. **The manifest version hasn't been built yet** (no `dist/v<manifest version>`) and is higher than the latest build, or there's no build at all: build it as it is, without bumping. This covers the first build and the case where the user already bumped by hand. It's also what happens after a failed build: the version was bumped, the build failed, the user fixed it and runs again.
3. **Otherwise, bump.** Start from the higher of the manifest version and the latest build, and pick the level:
   - Compare `src/` with the latest build: `diff -rq "dist/v<latest>" src -x .DS_Store -x .gitkeep`. `diff` exits with code 1 when it finds differences; that's the expected result, not an error.
   - **major**: a skill, agent or command was removed or renamed, or a skill's arguments changed in a way that breaks how people call it. Those changes break whoever already uses the plugin.
   - **minor**: a new skill, agent, command, hook or MCP server was added, or an existing one gained a new capability.
   - **patch**: everything else (fixes, wording, internal adjustments).

   Patch is the default: if the changes only justify a patch, bump and go on without asking. If they justify minor or major, tell the user what you found (the specific files or skills) and suggest that level, but let them choose between your suggestion and patch. The suggestion is a judgment call, so the user has the final word.

   Bumping resets the lower parts: patch `1.2.3` → `1.2.4`, minor → `1.3.0`, major → `2.0.0`.

## 4. Write the new version

Change only the value of the version field (`version` or `metadata.release`, as found in step 2) in `src/.claude-plugin/plugin.json`, using the file edit tool, and keep the rest of the file as it is. In case 2 it's already right; leave it.

If the project root has a `CHANGELOG.md`, add an entry for the new version at the top, following the format the file already uses, summarizing what changed. Base the summary on the diff against the latest build (run the same `diff` as in step 3 if you haven't); if there's no previous build, write that it's the first release. Skip this if the file doesn't exist (don't create it), or if it already has an entry for this version, which happens when a build failed and is being run again.

The version lives only in `plugin.json`, so there's nothing else to update. If you see the old version number written somewhere else in the project (README, docs), mention it to the user instead of changing it, because you can't tell whether it refers to the current version or to history.

## 5. Run the build

From the project root:

```bash
./scripts/pack.sh
```

`claude plugin validate` warns "No version specified" when the plugin has no `version` key. That's expected for projects that use `metadata.release` or no version: pass it on, but never add `version` to silence it.

If it fails, show the user the script's error and what it means:

- **Validation failed**: `claude plugin validate` found a problem in `src/`. Show the errors.
- **Personal data found**: the script lists the file and line that matched a pattern in `scripts/pii-patterns.txt`. The user needs to remove that content from `src/` (or, if it's a false positive, adjust the pattern).
- **Version already exists**: shouldn't happen after step 3; if it does, re-read the versions and decide again.

Don't revert the version bump after a failure. Once the user fixes the problem and runs the skill again, case 2 in step 3 builds the same version without bumping twice.

If the script prints a warning that `scripts/pii-patterns.txt` doesn't exist, pass it on: the build went through, but without the personal-data audit.

## 6. Report

Tell the user, briefly:

- the version built, and the previous one;
- the outputs the script printed: `dist/vX.Y.Z/` and `dist/vX.Y.Z.zip`, or `dist/<name>/` and `dist/<name>.zip` for an unversioned build (with the size);
- how to install it: `claude --plugin-dir <output folder>` in Claude Code, or upload the zip in Cowork.

If the project is a git repository and you changed the version, remind the user that the change in `plugin.json` still needs to be committed. Don't commit for them.
