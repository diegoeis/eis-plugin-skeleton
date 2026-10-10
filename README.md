# eis-plugin-skeleton

Plugin for Claude Code and Cowork that creates the folder structure of a plugin project, keeping what belongs to the project apart from what belongs to the plugin.

## Install

```
/plugin marketplace add diegoeis/eis-plugins
/plugin install eis-plugin-skeleton@eis-plugins
```

## Skills

| Skill | What it does |
| --- | --- |
| [`skel-init`](src/skills/skel-init) | Creates a new plugin project from the template: `src/`, `docs/`, `scripts/pack.sh`, README, AGENTS.md and CLAUDE.md. |
| [`skel-migrate`](src/skills/skel-migrate) | Moves an existing project folder into this structure: shows a short plan, waits for approval, only moves existing files and creates the missing ones (including `plugin.json`). |
| [`skel-build`](src/skills/skel-build) | Bumps the plugin version (patch by default) and runs `scripts/pack.sh` to build `dist/vX.Y.Z/` and `dist/vX.Y.Z.zip`. |

Usage:

```
/eis-plugin-skeleton:skel-init [folder-path]
/eis-plugin-skeleton:skel-migrate [folder-path]
/eis-plugin-skeleton:skel-build [version]
```

## The structure it creates

```
my-plugin/
├── src/                    plugin root: only what goes into the package
│   ├── .claude-plugin/plugin.json
│   └── skills/
├── docs/                   project specs and documentation
├── scripts/
│   ├── pack.sh             builds the package into dist/
│   ├── pii-patterns.example.txt   template for the pattern list
│   └── pii-patterns.txt    patterns forbidden in src/ (local, out of git)
├── dist/                   builds (out of git)
│   ├── vX.Y.Z/
│   └── vX.Y.Z.zip
├── AGENTS.md
├── CLAUDE.md               imports AGENTS.md
└── README.md
```

`pack.sh` reads `name` and the version (`version`, else `metadata.release`) from `src/.claude-plugin/plugin.json`, runs `claude plugin validate`, searches `src/` for the patterns in `scripts/pii-patterns.txt` (a local file, out of git; the template is `pii-patterns.example.txt`) and builds `dist/vX.Y.Z/` and `dist/vX.Y.Z.zip`. It stops if the version already exists. Without any version, it builds `dist/<name>/` and `dist/<name>.zip`.

This repository uses the same structure: the plugin lives in `src/`.

## Developing this plugin

```
claude --plugin-dir ./src     # test
./scripts/pack.sh             # package
```
