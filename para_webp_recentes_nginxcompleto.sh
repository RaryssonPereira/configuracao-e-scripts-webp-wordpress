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
map \$http_accept \$webp_extension_accept {
    default "";
    "~*webp" ".webp";
}

map \$http_user_agent \$webp_extension {
    default \$webp_extension_accept;
    "~Firefox" ".webp";
    "~iPhone" "";
}
EOF
else
    echo "✅ Arquivo Nginx para .webp já existe: $NGINX_WEBP_CONF"
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

# 🖼️ Extensões de imagem suportadas
EXTENSOES="\.(png|jpg|jpeg|gif|PNG|JPG|JPEG|GIF)$"

# 🔍 Busca por arquivos modificados nos últimos 3 minutos
find "$DIRETORIO" -type f -cmin -3 | grep -E "$EXTENSOES" > "$TMP_IMAGENS"

# 📊 Conta o número total de imagens encontradas
TOTAL=$(wc -l < "$TMP_IMAGENS")
POS=0

# 🔁 Loop para processar cada imagem
while IFS= read -r IMG; do
    ((POS++))
    NOME=$(basename "$IMG")
    WEBP="${IMG}.webp"

    echo -e '\n########################################################################\n'
    echo "📂 Arquivo $POS de $TOTAL: $NOME"

    if [ -e "$WEBP" ]; then
        if [ "$IMG" -nt "$WEBP" ]; then
            echo "🔁 Atualizando versão .webp (imagem original mais recente)."
            cwebp "$IMG" -o "$WEBP"
        else
            echo "✔️ Versão .webp já está atualizada."
        fi
    else
        echo "🆕 Criando versão .webp de $NOME"
        cwebp "$IMG" -o "$WEBP"
    fi
    echo -e '\n########################################################################\n'
done < "$TMP_IMAGENS"

rm -f -- "$TMP_IMAGENS"

# 🌐 Listar domínios disponíveis em /etc/nginx/sites-enabled/
echo "🔍 Verificando arquivos de configuração em /etc/nginx/sites-enabled/"
mapfile -t NGINX_SITES < <(find /etc/nginx/sites-enabled -type f -name "*.conf" | sort)

if [ ${#NGINX_SITES[@]} -eq 0 ]; then
    echo "❌ Nenhuma configuração encontrada em /etc/nginx/sites-enabled/"
    exit 1
fi

echo "📋 Arquivos encontrados:"
for i in "${!NGINX_SITES[@]}"; do
    echo "  [$i] ${NGINX_SITES[$i]}"
done

read -rp "👉 Digite o número do arquivo de configuração que deseja modificar: " SITE_CONF_INDEX
SITE_CONF="${NGINX_SITES[$SITE_CONF_INDEX]}"

if grep -q "location ~\*  \\.(jpg|jpeg|png|gif)\$" "$SITE_CONF"; then
    echo "✅ Bloco 'location' para imagens já existe em: $SITE_CONF"
else
    echo "🛠️ Inserindo bloco 'location' em todos os blocos server do arquivo: $SITE_CONF"
    sudo cp "$SITE_CONF" "$SITE_CONF.bak"

    sudo awk '
    BEGIN { inside=0 }
    /server[ \t]*\{/ { inside=1; print; next }
    /\}/ {
        if (inside) {
            print "location ~*  \.(jpg|jpeg|png|gif)$ {
                add_header Vary Accept;
                try_files $uri$webp_extension $uri =404;
                expires 7d;
        }";
            inside=0
        }
    }
    { print }
    ' "$SITE_CONF.bak" | sudo tee "$SITE_CONF" > /dev/null

    echo "📦 Bloco adicionado com sucesso."
fi

echo "🔍 Testando configuração do Nginx..."
if sudo nginx -t; then
    echo "✅ Configuração válida. Recarregando Nginx..."
    sudo nginx -s reload
else
    echo "❌ Erro na configuração do Nginx. Arquivo original foi mantido em $SITE_CONF.bak"
fi
