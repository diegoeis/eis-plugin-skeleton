# Decisões

- **Template como arquivos reais** em `src/skills/init/assets/folder-template/`, copiados com `cp -R`. Dá o mesmo resultado sempre; gerar a partir de texto no SKILL.md variaria a cada execução.
- **Versão só em `version` do `plugin.json`.** É a chave oficial (https://code.claude.com/docs/en/plugins-reference#version). `metadata` é livre e o Claude Code não lê.
- **`dist/` acumula versões** (`vX.Y.Z/` + `vX.Y.Z.zip`) e fica no `.gitignore`. O `pack.sh` recusa versão existente para forçar a subida de versão.
- **Plugin isolado em `src/`.** `CLAUDE.md`, `AGENTS.md` e `README.md` ficam na raiz do projeto: um `CLAUDE.md` na raiz do plugin não é carregado e gera aviso no `claude plugin validate`.
- **`CLAUDE.md` só importa `@AGENTS.md`.** Conteúdo num lugar só.
- **Auditoria de dados pessoais por arquivo** (`scripts/pii-patterns.txt`), configurável por projeto.
- **Só Claude Code e Cowork** por enquanto.
- **Fora do escopo da v0.1.0:** reorganizar um plugin que já existe.
