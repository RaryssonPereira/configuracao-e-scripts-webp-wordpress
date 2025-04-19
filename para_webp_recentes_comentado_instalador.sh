#!/bin/bash
set -euo pipefail

# ⚙️ Verifica se o comando 'cwebp' está instalado no sistema
if ! command -v cwebp &> /dev/null; then
    echo "⚠️ O comando 'cwebp' não foi encontrado. Ele é necessário para converter imagens para o formato .webp."
    read -rp "❓ Deseja instalar o pacote 'webp' agora? (s/n): " resposta
    if [[ "$resposta" =~ ^[Ss]$ ]]; then
        sudo apt update && sudo apt install -y webp
    else
        echo "❌ Não foi possível continuar sem o 'cwebp'."
        exit 1
    fi
fi


# 📂 Verifica se o usuário forneceu um diretório como argumento
if [ $# -ne 1 ]; then
    echo "❌ Uso: $0 <diretório>"
    exit 1
fi

DIRETORIO="$1"

# 🧾 Cria um arquivo temporário para armazenar os caminhos das imagens encontradas
TMP_IMAGENS=$(mktemp /tmp/webp_imgs.XXXXXX)

# 🖼️ Extensões de imagem suportadas (case insensitive)
EXTENSOES="\.(png|jpg|jpeg|gif|PNG|JPG|JPEG|GIF)$"

# 🔍 Busca por arquivos com extensões válidas modificados nos últimos 3 minutos
find "$DIRETORIO" -type f -cmin -3 | grep -E "$EXTENSOES" > "$TMP_IMAGENS"

# 📊 Conta o número total de imagens encontradas
TOTAL=$(wc -l < "$TMP_IMAGENS")
POS=0

# 🔁 Loop para processar cada imagem
while IFS= read -r IMG; do
    ((POS++))  # Incrementa a posição atual
    NOME=$(basename "$IMG")
    WEBP="${IMG}.webp"  # Nome do arquivo de saída com extensão .webp

    echo -e '\n########################################################################\n'
    echo "📂 Arquivo $POS de $TOTAL: $NOME"

    # ✅ Verifica se já existe uma versão .webp
    if [ -e "$WEBP" ]; then
        # 🔄 Verifica se a imagem original é mais recente que a .webp
        if [ "$IMG" -nt "$WEBP" ]; then
            echo "🔁 Atualizando versão .webp (imagem original mais recente)."
            cwebp "$IMG" -o "$WEBP"
        else
            echo "✔️ Versão .webp já está atualizada."
        fi
    else
        # 🆕 Cria a versão .webp da imagem
        echo "🆕 Criando versão .webp de $NOME"
        cwebp "$IMG" -o "$WEBP"
    fi
    echo -e '\n########################################################################\n'
done < "$TMP_IMAGENS"

# 🧹 Remove o arquivo temporário
rm -f -- "$TMP_IMAGENS"
