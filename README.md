# Conversão automática de imagens para WebP em sites WordPress

### 👤 Autor

**Rarysson Pereira**  
Analista de Desenvolvimento de Sistemas e Infraestrutura  
🗓️ Criado em: 29/05/2025  
[LinkedIn](https://www.linkedin.com/in/rarysson-pereira?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app) • [Instagram](https://www.instagram.com/raryssonpereira?igsh=MXhhb3N2MW1yNzl3cA==)

---

## 🧠 Por que converter imagens para WebP?

Você provavelmente já ouviu falar dos formatos **JPEG** e **PNG**, que são amplamente utilizados na internet para exibir imagens. Embora populares, esses formatos **não são os mais eficientes** quando o assunto é **desempenho e otimização de carregamento** em sites modernos.

Com o crescimento da exigência por **velocidade de carregamento**, **experiência do usuário** e **bom ranqueamento no Google**, surgiu a necessidade de utilizar **formatos de imagem mais leves** sem perder qualidade visual. Entre os formatos mais modernos recomendados, estão:

- **JPEG 2000**
- **JPEG XR**
- **WebP**

De acordo com o [Google PageSpeed Insights](https://web.dev/serve-images-webp/), o **WebP é o formato com maior compatibilidade entre navegadores**, além de oferecer uma **compactação superior**, reduzindo significativamente o tamanho das imagens.

### ✅ Vantagens do WebP

- **Tamanho reduzido**: imagens menores sem perda perceptível de qualidade.
- **Compatibilidade ampla**: suportado pela maioria dos navegadores modernos (Chrome, Firefox, Edge, Opera, etc.).
- **Recomendação do Google**: melhora a pontuação no PageSpeed e SEO técnico.
- **Ideal para WordPress**: acelera o carregamento de páginas e melhora a performance geral do site.

> 💡 **Conclusão**: Utilizar o formato WebP é essencial para quem busca **mais performance, melhor experiência de navegação** e **boas práticas de SEO** em portais WordPress.

---

## ⚙️ Instalação e configuração do suporte a WebP

Antes de automatizar a conversão de imagens, é necessário garantir que o servidor possua suporte à geração do formato **WebP** e que o **Nginx** esteja configurado para entregar corretamente essas imagens aos navegadores que as suportam.

### 📦 1. Instale o conversor `cwebp`

Execute o comando abaixo para instalar a ferramenta de conversão `cwebp`, que faz parte do pacote `webp`:

```bash
apt install -y webp
# ou, se preferir:
apt-get install -y webp
```

Essa ferramenta será usada pelos scripts para converter imagens JPEG, PNG e GIF para `.webp`.

### 🌐 2. Configure o Nginx para servir WebP automaticamente

Crie um novo arquivo de configuração para o Nginx:

```bash
sudo nano /etc/nginx/conf.d/webp.conf
```

Cole o conteúdo abaixo no arquivo:

```nginx
# Define a variável $webp_extension_accept com base no cabeçalho "Accept" enviado pelo cliente.
# Se o cliente aceitar WebP, a extensão será ".webp", caso contrário, será vazia.
map $http_accept $webp_extension_accept {
    default "";
    "~*webp" ".webp";  # Se o cabeçalho Accept contiver "webp", define como .webp
}

# Define a variável final $webp_extension com base no User-Agent.
# Essa regra sobrepõe a anterior caso o acesso seja feito por bots ou navegadores específicos.
map $http_user_agent $webp_extension {
    default $webp_extension_accept;   # Usa o valor da verificação do Accept como padrão

    "~Firefox"              ".webp";  # Força .webp para Firefox (que aceita mesmo sem declarar no Accept)
    "~iPhone"               "";       # Força a não usar .webp em iPhones (melhora compatibilidade)

    # Força o uso da imagem tradicional (.jpg/.png) para bots que não suportam WebP:
    "~facebookexternalhit" "";       # Facebook (usado para preview de links)
    "~Slackbot"             "";       # Slack
    "~Twitterbot"           "";       # Twitter
    "~WhatsApp"             "";       # WhatsApp
    "~TelegramBot"          "";       # Telegram
    "~LinkedInBot"          "";       # LinkedIn
    "~Googlebot"            "";       # Googlebot (melhora indexação de imagens)
}
```

💡 Essas regras garantem que navegadores modernos recebam a versão `.webp`, enquanto bots e navegadores com baixa compatibilidade continuem recebendo `.jpg` ou `.png`. Isso ajuda na indexação correta e melhora o desempenho.

### 🚀 3. Habilite o uso de imagens WebP no bloco do site

Após configurar o suporte a WebP no Nginx via `webp.conf`, é necessário aplicar essa lógica no bloco de configuração do site para que as imagens convertidas em `.webp` sejam servidas corretamente quando o navegador for compatível.

Abra o arquivo de configuração do domínio dentro de `/etc/nginx/sites-enabled/`:

```bash
sudo nano /etc/nginx/sites-enabled/dominio.com.conf
```

Adicione (ou edite) o seguinte bloco dentro da diretiva `server`:

```nginx
location ~* \.(jpg|jpeg|png|gif)$ {
    add_header Vary Accept;
    try_files $uri$webp_extension $uri =404;
    expires 7d;
}
```

### 🔍 O que esse bloco faz?

- `location ~* \.(jpg|jpeg|png|gif)$`: Intercepta todas as requisições de imagens nos formatos tradicionais.
- `add_header Vary Accept;`: Informa ao navegador e à CDN (caso exista) que o conteúdo pode variar dependendo do cabeçalho `Accept` (ou seja, se o navegador aceita WebP).
- `try_files $uri$webp_extension $uri =404;`: 
  - Primeiro, tenta servir a imagem com a extensão `.webp` (caso o navegador aceite);
  - Se não existir ou não for compatível, serve a imagem original (`$uri`);
  - Se nenhuma estiver disponível, retorna erro 404.
- `expires 7d;`: Adiciona um cabeçalho de cache para o navegador manter a imagem por 7 dias, otimizando o carregamento.

> 💡 Essa configuração garante que o Nginx escolha automaticamente a melhor versão da imagem com base no navegador do visitante, sem necessidade de alterar o código HTML do site.

### ✅ Verifique a sintaxe do Nginx antes de aplicar

Antes de recarregar o Nginx, é recomendável testar se a sintaxe está correta:

```bash
sudo nginx -t
```

Se a saída indicar que a configuração está correta, aplique as mudanças com:

```bash
sudo systemctl reload nginx
```

---

Na próxima parte, explicaremos os dois scripts de conversão automática (`converte_webp_antes_3min.sh` e `converte_webp_apos_3min.sh`) e como agendá-los via `cron`.

