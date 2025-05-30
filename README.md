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
sudo vim /etc/nginx/conf.d/webp.conf
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
sudo vim /etc/nginx/sites-enabled/dominio.com.conf
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

### 🛠️ 4. Script: `converte_webp_antes_3min.sh`

Este script tem como objetivo **converter automaticamente imagens recém-enviadas para o WordPress (com menos de 3 minutos de criação ou modificação)** em versões `.webp`. Ele é ideal para rodar via `cron` a cada 3 minutos, garantindo que as imagens novas sejam otimizadas rapidamente após o upload.

Ele verifica o diretório `/uploads` do WordPress (com base no ano e mês atual), identifica arquivos `.jpg`, `.jpeg`, `.png` e `.gif` modificados nos últimos 3 minutos e gera a versão `.webp` caso ainda não exista ou esteja desatualizada.

📄 **Criar o script no seu servidor:**

Salve o conteúdo do script em:

```
/opt/scripts/converte_webp_antes_3min.sh
```

🔗 [Clique aqui para abrir o arquivo `converte_webp_antes_3min.sh` no repositório](https://github.com/RaryssonPereira/script-de-conversao-para-webp.sh/blob/main/converte_webp_antes_3min.sh)

> ✅ Não esqueça de tornar o script executável:
> 
> ```bash
> chmod +x /opt/scripts/converte_webp_antes_3min.sh
> ```

---

### 🛠️ 5. Script: `converte_webp_apos_3min.sh`

O script `converte_webp_apos_3min.sh` é complementar ao anterior e tem como função garantir que **nenhuma imagem fique sem conversão para WebP**, mesmo que tenha sido enviada há mais de 3 minutos ou movida entre pastas.

Ele percorre o diretório completo de uploads do WordPress e procura por arquivos `.jpg`, `.jpeg`, `.png` e `.gif` que tenham sido modificados **há mais de 3 minutos**. Isso evita conflitos com o script anterior (que atua sobre arquivos muito recentes) e assegura que imagens antigas, restauradas ou esquecidas também sejam convertidas.

### 📄 Criar o script no seu servidor:

Salve o conteúdo do script no seguinte caminho:

```bash
/opt/scripts/converte_webp_apos_3min.sh
```

🔗 [Clique aqui para abrir o arquivo `converte_webp_apos_3min.sh` no repositório](https://github.com/RaryssonPereira/script-de-conversao-para-webp.sh/blob/main/converte_webp_apos_3min.sh)

✅ Torne o script executável:

```bash
chmod +x /opt/scripts/converte_webp_apos_3min.sh
```

---

### ⏱️ 6. Agendamento das tarefas com `cron`

Para que a conversão de imagens para WebP aconteça de forma automática, você pode utilizar o `cron` para executar os dois scripts em momentos diferentes, de forma complementar:

### 🕒 Explicação das crons

- **`converte_webp_antes_3min.sh`**  
  Este script será executado a **cada 3 minutos** e trata imagens recém-enviadas (modificadas há até 3 minutos). Ideal para capturar novos uploads no momento em que ocorrem.

- **`converte_webp_apos_3min.sh`**  
  Este script será executado **uma vez por dia, às 2h da manhã**, e percorre todo o diretório de uploads. Ele garante que imagens mais antigas, restauradas ou que tenham passado despercebidas, também sejam convertidas.

### 🧩 Como configurar

Abra o `crontab` do sistema ou adicione ao arquivo `/etc/cron.d/conversao-webp` o seguinte conteúdo:

```cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

# Converter imagens recém-modificadas para WebP a cada 3 minutos
# Para ativar, remova o # e edite o caminho do projeto corretamente:
#*/3 * * * * www-data /bin/bash /opt/scripts/converte_webp_antes_3min.sh /var/www/PROJETO/wp-content/uploads/$(date +\%Y)/$(date +\%m) > /dev/null 2>&1

# Converter imagens mais antigas (modificadas há mais de 3 minutos) para WebP
# Ideal para rodar 1x por dia no diretório inteiro de uploads:
#0 2 * * * www-data /bin/bash /opt/scripts/converte_webp_apos_3min.sh /var/www/PROJETO/wp-content/uploads > /dev/null 2>&1
```

📎 [Clique aqui para abrir o arquivo `cron-conversao-webp`](https://github.com/RaryssonPereira/script-de-conversao-para-webp.sh/blob/main/cron-conversao-webp)

### ⚠️ Importante

- **Descomente as linhas** removendo o `#` do início de cada uma.
- **Substitua `/PROJETO/`** pelo nome real do diretório onde seu WordPress está instalado.  
  Exemplo: `/var/www/meusite.com.br/wp-content/uploads`

> ✅ Essas tarefas automatizam completamente a geração de versões `.webp` no seu WordPress, cobrindo imagens novas e antigas com segurança e desempenho.

---

Na próxima (e última) parte, você pode adicionar uma conclusão e recomendações finais.


