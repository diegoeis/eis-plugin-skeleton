# AGENTS.md

Repositório do plugin `eis-setup-plugin`. O plugin tem uma skill, `init`, que cria a estrutura de um projeto de plugin copiando um template.

Este repo segue a própria estrutura que o plugin cria.

## Onde fica cada coisa

- `src/` é a raiz do plugin. Só o que está aqui vai para o pacote e para o marketplace (`eis-plugins` aponta para `path: src`).
- `src/.claude-plugin/plugin.json` é o manifest e a única fonte da versão.
- `src/skills/init/SKILL.md` é a skill.
- `src/skills/init/assets/folder-template/` é o template copiado para o projeto do usuário. Mudou a estrutura padrão? Mude aqui.
- `scripts/pack.sh` empacota este plugin em `dist/`. É uma cópia de `src/skills/init/assets/folder-template/scripts/pack.sh`: ao alterar um, altere o outro igual.
- `docs/` guarda especificações e decisões. Não vai para o pacote.
- `dist/` é gerado e fica fora do git.

## Regras

- O template tem placeholders `{{PLUGIN_NAME}}`, `{{PLUGIN_DESCRIPTION}}` e `{{AUTHOR_NAME}}`. Se criar um novo, documente-o na tabela do passo 4 do `SKILL.md`.
- Mantenha o `.gitkeep` das pastas vazias do template (`docs/`, `src/skills/`): sem ele, o git não versiona a pasta e ela some na instalação.
- Antes de publicar, suba `version` em `src/.claude-plugin/plugin.json`. O marketplace não fixa versão; com `version` no manifest, quem instalou só recebe atualização quando esse número muda.
- Rode `claude plugin validate ./src` antes do push.
- Siga a documentação oficial: https://code.claude.com/docs/en/plugins-reference
