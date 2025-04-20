#!/bin/bash
set -euo pipefail


# ⚙️ Verifica e instala automaticamente o pacote 'webp' se não estiver instalado
if ! command -v cwebp &> /dev/null; then
    echo "🔧 O pacote 'webp' não está instalado. Instalando automaticamente..."
    sudo apt update && sudo apt install -y webp
fi


# 📁 Verifica se o arquivo /etc/nginx/conf.d/webp.conf existe, se não, cria com conteúdo adequado
NGINX_WEBP_CONF="/etc/nginx/conf.d/webp.conf"
if [ ! -f "$NGINX_WEBP_CONF" ]; then
    echo "📝 Criando o arquivo de configuração Nginx para suporte a .webp: $NGINX_WEBP_CONF"
    sudo tee "$NGINX_WEBP_CONF" > /dev/null <<EOF
map $http_accept $webp_extension_accept {
    default "";
    "~*webp" ".webp";
}

map $http_user_agent $webp_extension {
    default $webp_extension_accept;
    "~Firefox" ".webp";
    "~iPhone" "";
}
EOF
else
    echo "✅ Arquivo Nginx para .webp já existe: $NGINX_WEBP_CONF"
fi


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

# 🌐 Busca diretórios WordPress em /var/www e permite ao usuário escolher qual processar
echo "🔍 Verificando sites em /var/www..."
mapfile -t SITES < <(find /var/www -maxdepth 2 -type d -name 'wp-content' -exec dirname {} \; | sort)

if [ ${#SITES[@]} -eq 0 ]; then
    echo "❌ Nenhum site WordPress encontrado em /var/www."
    exit 1
fi

echo "📋 Sites encontrados:"
for i in "${!SITES[@]}"; do
    echo "  [$i] ${SITES[$i]}"
done

read -rp "👉 Digite o número do site que deseja processar: " SITE_INDEX
DIRETORIO="${SITES[$SITE_INDEX]}/wp-content/uploads"

echo "✅ Diretório escolhido para conversão: $DIRETORIO"

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
