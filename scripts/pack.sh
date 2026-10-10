#!/usr/bin/env bash
#
# pack.sh — empacota o plugin para distribuição.
#
# A pasta src/ é a raiz do plugin e a única fonte do que vai para o pacote.
# Tudo fora dela (docs/, scripts/, README, AGENTS.md, CLAUDE.md, .git) fica de fora.
#
# Saída, a partir da raiz do projeto:
#   dist/vX.Y.Z/       cópia limpa de src/
#   dist/vX.Y.Z.zip    zip dessa pasta, pronto para importar
#
# A versão vem da chave "version" de src/.claude-plugin/plugin.json.
# Se dist/vX.Y.Z já existir, o script para: suba a versão antes de empacotar.
#
# Uso:
#   ./scripts/pack.sh

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
SRC="$ROOT/src"
DIST="$ROOT/dist"
MANIFEST="$SRC/.claude-plugin/plugin.json"
PII_FILE="$SCRIPTS_DIR/pii-patterns.txt"

die() { echo "Erro: $*" >&2; exit 1; }

[[ -d "$SRC" ]] || die "pasta src/ não encontrada em $ROOT"
[[ -f "$MANIFEST" ]] || die "manifest não encontrado em src/.claude-plugin/plugin.json"

# Lê uma chave string de nível superior do plugin.json.
# Usa jq quando existe; sem jq, cai num grep que pega a primeira ocorrência.
read_key() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$key" '.[$k] // empty' "$MANIFEST"
  else
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$MANIFEST" | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/'
  fi
}

NAME="$(read_key name)"
VERSION="$(read_key version)"
[[ -n "$NAME" ]] || die "\"name\" vazio ou ausente em plugin.json"
[[ -n "$VERSION" ]] || die "\"version\" vazio ou ausente em plugin.json"

OUT_DIR="$DIST/v$VERSION"
OUT_ZIP="$DIST/v$VERSION.zip"

if [[ -e "$OUT_DIR" || -e "$OUT_ZIP" ]]; then
  die "dist/v$VERSION já existe. Suba \"version\" em src/.claude-plugin/plugin.json antes de empacotar."
fi

# Valida o plugin com o CLI oficial, quando disponível.
if command -v claude >/dev/null 2>&1; then
  echo "Validando src/ com 'claude plugin validate'..."
  claude plugin validate "$SRC" || die "validação falhou. Corrija antes de empacotar."
else
  echo "Aviso: CLI 'claude' não encontrado; pulando 'claude plugin validate'." >&2
fi

# Auditoria de dados pessoais: um padrão (regex estendida) por linha em
# scripts/pii-patterns.txt. Linhas vazias e começadas por # são ignoradas.
# O arquivo é local (fica no .gitignore); o modelo é scripts/pii-patterns.example.txt.
# plugin.json fica de fora porque o autor aparece ali legitimamente.
if [[ ! -f "$PII_FILE" ]]; then
  echo "Aviso: scripts/pii-patterns.txt não existe; pulando a auditoria de dados pessoais." >&2
  echo "       Copie scripts/pii-patterns.example.txt para scripts/pii-patterns.txt e preencha." >&2
else
  # tr -d '\r' evita que um arquivo salvo com quebra de linha do Windows anule os padrões.
  PATTERNS="$(tr -d '\r' < "$PII_FILE" | grep -vE '^[[:space:]]*(#|$)' || true)"
  if [[ -n "$PATTERNS" ]]; then
    if MATCHES="$(grep -rnIE -f <(printf '%s\n' "$PATTERNS") "$SRC" \
          --exclude=plugin.json --exclude=.DS_Store)"; then
      echo "Erro: encontrei dados pessoais em src/:" >&2
      echo "$MATCHES" >&2
      exit 1
    fi
  fi
fi

echo "Empacotando $NAME v$VERSION..."

mkdir -p "$DIST"
# Se algo falhar daqui em diante, não deixa versão pela metade em dist/.
trap 'rm -rf "$OUT_DIR" "$OUT_ZIP"' ERR

mkdir "$OUT_DIR"
# Copia src/ inteira (com arquivos ocultos como .claude-plugin/ e .mcp.json),
# sem .DS_Store nem os .gitkeep que só servem para o git versionar pastas vazias.
(cd "$SRC" && tar cf - --exclude='.DS_Store' --exclude='.gitkeep' .) | (cd "$OUT_DIR" && tar xf -)

(cd "$OUT_DIR" && zip -rqX "$OUT_ZIP" .)

trap - ERR

echo "  dist/v$VERSION/"
echo "  dist/v$VERSION.zip  ($(du -h "$OUT_ZIP" | cut -f1))"
echo ""
echo "Instalação:"
echo "  Claude Code:  claude --plugin-dir \"$OUT_DIR\""
echo "  Cowork:       Claude Desktop > Skills > Personal plugins > + > upload do dist/v$VERSION.zip"
