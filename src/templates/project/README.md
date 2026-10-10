# {{PLUGIN_NAME}}

{{PLUGIN_DESCRIPTION}}

## Structure

```
{{PLUGIN_NAME}}/
├── src/                    plugin root: only what goes into the package
│   ├── .claude-plugin/plugin.json
│   └── skills/
├── docs/                   project specs and documentation
├── scripts/
│   ├── pack.sh             builds the package into dist/
│   ├── pii-patterns.example.txt   template for the pattern list
│   └── pii-patterns.txt    patterns forbidden in src/ (local, out of git)
├── dist/                   generated builds (out of git)
├── AGENTS.md
├── CLAUDE.md
└── README.md
```

## Develop

Put skills, agents, hooks and other plugin files inside `src/`, following the [standard plugin layout](https://code.claude.com/docs/en/plugins-reference#standard-layout).

To test without packaging:

```
claude --plugin-dir ./src
```

## Package

1. From the second package on, bump the version in `src/.claude-plugin/plugin.json`: `version`, or `metadata.release` if the project uses that instead (the first one is `0.1.0`).
2. Run:

```
./scripts/pack.sh
```

The script validates the plugin with `claude plugin validate`, searches `src/` for the patterns listed in `scripts/pii-patterns.txt` and builds:

- `dist/vX.Y.Z/` — a clean copy of `src/`
- `dist/vX.Y.Z.zip` — the zip of that folder, ready to import

It stops if the version already exists in `dist/`. Without a version in `plugin.json`, it builds `dist/<name>/` and `dist/<name>.zip` instead, replacing them on every build.

`scripts/pii-patterns.txt` stays out of git, so your list of sensitive terms never reaches the repository. Anyone who clones the project creates their own from `scripts/pii-patterns.example.txt`.
