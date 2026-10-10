# AGENTS.md

Projeto do plugin `{{PLUGIN_NAME}}` para Claude Code e Cowork.

{{PLUGIN_DESCRIPTION}}

## Onde fica cada coisa

- `src/` é a raiz do plugin. Só o que está aqui vai para o pacote. Arquivos do plugin (skills, agents, hooks, `.mcp.json`) ficam sempre dentro de `src/`, seguindo o layout padrão: https://code.claude.com/docs/en/plugins-reference#standard-layout
- `src/.claude-plugin/plugin.json` é o manifest e a única fonte da versão (chave `version`).
- `docs/` guarda especificações, decisões e documentação do projeto. Nada aqui vai para o pacote.
- `scripts/` guarda scripts do projeto. `pack.sh` empacota; `pii-patterns.txt` lista padrões que não podem aparecer em `src/`; é local e fica fora do git (o modelo versionado é `pii-patterns.example.txt`). Nunca copie o conteúdo dele para arquivos versionados.
- `dist/` é gerado por `scripts/pack.sh` e fica fora do git. Não edite nada lá.
- `AGENTS.md`, `CLAUDE.md` e `README.md` ficam na raiz do projeto, nunca em `src/`. Um `CLAUDE.md` na raiz do plugin não é carregado como contexto e gera aviso no `claude plugin validate`.

## Regras

- Não crie arquivos de projeto (notas, rascunhos, specs) dentro de `src/`.
- A cada novo pacote (depois do primeiro), suba `version` em `src/.claude-plugin/plugin.json`. O `pack.sh` recusa versão que já existe em `dist/`.
- Para empacotar, rode `./scripts/pack.sh` a partir da raiz do projeto.
- Para testar localmente sem empacotar: `claude --plugin-dir ./src`.
- Consulte a documentação oficial de plugins antes de criar componentes: https://code.claude.com/docs/en/plugins-reference
