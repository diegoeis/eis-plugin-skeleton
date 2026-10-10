---
name: init
description: Cria do zero a pasta de um novo projeto de plugin para Claude Code e Cowork, com a estrutura src/ (raiz do plugin), docs/, scripts/pack.sh (empacota em dist/vX.Y.Z/ e dist/vX.Y.Z.zip), README.md, AGENTS.md e CLAUDE.md, pronta para o usuário colocar as skills dentro de src/. Use sempre que o usuário disser "cria um plugin novo", "inicia um projeto de plugin", "setup de plugin", "scaffold de plugin", "monta a estrutura de pastas do plugin", "quero começar um plugin", "new plugin project", ou rodar /eis-setup-plugin:init, mesmo que não fale em estrutura de pastas. Não reorganiza plugins que já existem; nesse caso avise que esse modo ainda não existe.
argument-hint: "[caminho-da-pasta]"
---

# init

Cria a estrutura inicial de um projeto de plugin copiando o template em `${CLAUDE_SKILL_DIR}/assets/folder-template/`. O template é a fonte da verdade: copie os arquivos dele, não os reescreva de memória. É isso que garante que todo projeto saia igual.

A ideia da estrutura é separar o que é projeto do que é plugin. `src/` é a raiz do plugin e a única coisa que vai para o pacote. `docs/`, `scripts/`, `README.md`, `AGENTS.md` e `CLAUDE.md` são do projeto e ficam fora do zip.

## 1. Pasta de destino

Se o usuário passou um caminho como argumento, use-o. Se não, pergunte onde o projeto vai ficar. Peça um caminho absoluto; se vier relativo, resolva a partir do diretório atual e confirme o caminho completo com ele.

Se você não tiver acesso a essa pasta na sessão (Cowork, por exemplo), peça acesso antes de continuar.

Depois verifique o estado da pasta, sem criar nada ainda:

- Não existe, ou existe vazia, ou só tem `.git/` e `.DS_Store`: siga.
- Existe com outros arquivos: pare. Diga quais arquivos encontrou e que organizar um plugin existente ainda não é suportado por esta skill. Não copie nada por cima, porque o template sobrescreveria arquivos do usuário.

## 2. Dados do plugin

Pergunte numa única mensagem, sugerindo valores padrão:

- **Nome do plugin**: sugira o nome da pasta de destino, se ele for um nome válido (regras abaixo); se não for, não sugira nada.
- **Descrição**: uma frase, numa linha só, sobre o que o plugin faz.
- **Autor**: nome do autor. Se `git config user.name` retornar algo, sugira; se vier vazio, só pergunte.

A versão inicial é sempre `0.1.0`; não pergunte.

Valide o nome antes de criar qualquer arquivo. Exija kebab-case (só minúsculas, números e hífens): o Claude Code aceita outros formatos só com aviso, mas a sincronização com o marketplace do Claude.ai e o Cowork exigem kebab-case. Além disso, o `claude plugin validate` rejeita com erro nomes que:

- começam com `claude-`, `anthropic-`, `anthropics-` ou `cc-plugin-`;
- são exatamente `claude`, `anthropic`, `anthropics`, `claude-code` ou `claude-mods`;
- põem `official` junto de `claude` ou `anthropic` (ex.: `official-claude-tools`).

Se o nome cair numa dessas regras, explique o motivo e peça outro. Se o usuário insistir, não crie o projeto: o plugin não passaria na validação. O nome não precisa ser igual ao da pasta.

## 3. Copiar o template

Só agora crie a pasta (se não existir) e copie:

```bash
mkdir -p "<destino>"
cp -R "${CLAUDE_SKILL_DIR}/assets/folder-template/." "<destino>/"
mkdir -p "<destino>/docs" "<destino>/src/skills"
cp "<destino>/scripts/pii-patterns.example.txt" "<destino>/scripts/pii-patterns.txt"
chmod +x "<destino>/scripts/pack.sh"
```

O `pii-patterns.txt` é a cópia local da lista de termos proibidos no pacote. Ele está no `.gitignore` do template, para a lista do usuário nunca ir para o repositório.

O `/.` no fim da origem é o que copia também os arquivos ocultos (`.gitignore`, `.claude-plugin/`, `.gitkeep`). O `mkdir -p` garante as pastas vazias caso a instalação do plugin tenha descartado os `.gitkeep`, e o `chmod` garante o script executável caso a instalação tenha perdido a permissão.

## 4. Preencher os placeholders

Três arquivos têm placeholders: `README.md`, `AGENTS.md` e `src/.claude-plugin/plugin.json`. Substitua:

| Placeholder | Valor |
| --- | --- |
| `{{PLUGIN_NAME}}` | nome do plugin |
| `{{PLUGIN_DESCRIPTION}}` | descrição |
| `{{AUTHOR_NAME}}` | autor |

Use a ferramenta de edição de arquivos; se ela não alcançar o destino, use um script que faça substituição literal de texto. Não use `sed`: descrições com `/`, `&` ou aspas quebram `sed`. No `plugin.json`, os valores precisam sair como strings JSON válidas (aspas e barras invertidas escapadas); se tiver `jq`, confira com `jq . "<destino>/src/.claude-plugin/plugin.json"`.

Depois confirme que nada ficou para trás:

```bash
grep -rn "{{" "<destino>" --exclude-dir=.git
```

O comando não deve retornar nada.

## 5. Git

Se o destino ainda não estiver dentro de um repositório git (`git -C "<destino>" rev-parse --is-inside-work-tree` falha), rode `git init` nele. Não faça commit: o primeiro commit é do usuário.

## 6. Validar

Se o comando `claude` existir, rode:

```bash
claude plugin validate "<destino>/src"
```

Deve passar. Se der erro, corrija antes de entregar; se der aviso, mostre ao usuário.

## 7. Entregar

Mostre a árvore criada (`find "<destino>" -not -path '*/.git/*' | sort` ou `tree -a -I .git`) e os próximos passos, curtos:

1. Coloque as skills em `src/skills/<nome-da-skill>/SKILL.md` (e agents, hooks etc. dentro de `src/`).
2. Preencha `scripts/pii-patterns.txt` com o que não pode vazar no pacote (caminhos locais, e-mails, nomes internos). Esse arquivo fica só na máquina dele, fora do git.
3. Teste com `claude --plugin-dir ./src`.
4. Para gerar uma versão, rode `./scripts/pack.sh`. Sai em `dist/vX.Y.Z/` e `dist/vX.Y.Z.zip`. O primeiro pacote sai como `0.1.0`; a partir do segundo, suba `version` em `src/.claude-plugin/plugin.json` antes.
