# 🖼️ Conversão Automática de Imagens para WebP

Este repositório contém um script interativo para converter todas as imagens dos sites WordPress hospedados em `/var/www` para o formato `.webp`, recomendado pelo Google para melhor performance e ranqueamento.

O objetivo é ajudar devs, sysadmins e equipes de suporte a aplicarem boas práticas de otimização de imagens de forma automática e segura, com suporte a servidores Nginx e múltiplos domínios.

---

## 📜 Sobre o script

**Arquivo:** `converte-todos-para-webp.sh`  
**Criado por:** [Rarysson](https://github.com/RaryssonPereira)  
**Objetivo:** Localizar imagens em sites WordPress e convertê-las para `.webp`, atualizando somente as que forem novas ou modificadas, além de configurar o Nginx para servir essas imagens de forma otimizada.

---

## 🔧 O que o script faz?

1. Instala automaticamente o pacote `webp` se o comando `cwebp` não estiver disponível.
2. Localiza sites WordPress no caminho `/var/www/*/wp-content/uploads`.
3. Pergunta qual site deseja processar.
4. Converte todas as imagens `.jpg`, `.jpeg`, `.png`, `.gif` para `.webp` **somente se ainda não existirem** ou se estiverem desatualizadas.
5. Cria o arquivo `/etc/nginx/conf.d/webp.conf` com mapeamento de suporte ao formato `.webp` (caso não exista).
6. Lista todos os domínios configurados em `/etc/nginx/sites-enabled/` e permite escolher qual deseja alterar.
7. Insere o bloco `location` com regras de entrega de `.webp` dentro de todos os blocos `server` do domínio selecionado.
8. Testa a configuração com `nginx -t` e recarrega automaticamente (`nginx -s reload`) se estiver válida.

---

## 🚨 Requisitos antes de usar

- Servidor Linux com WordPress instalado em `/var/www`
- Nginx como servidor web (com arquivos em `/etc/nginx/sites-enabled/`)
- Acesso root ou permissão sudo
- Testado em Ubuntu Server (20.04 ou superior)

---

## ▶️ Como usar

### 1. Baixe o script

```bash
git clone https://github.com/RaryssonPereira/converte-todos-para-webp.git
cd converte-todos-para-webp
```

### 2. Torne o script executável

```bash
chmod +x converte-todos-para-webp.sh
```

### 3. Execute o script

```bash
./converte-todos-para-webp.sh
```

---

## 💡 Como funciona a conversão?

O script verifica cada imagem e aplica a lógica abaixo:

- ✅ Se **a versão `.webp` já existir e estiver atualizada**, a imagem é ignorada.
- 🔁 Se **a versão `.webp` existir mas estiver desatualizada**, ela é atualizada.
- 🆕 Se **a versão `.webp` ainda não existir**, ela será criada.

Tudo isso com suporte silencioso via `cwebp -quiet`.

---

## 🧩 Exemplo de configuração Nginx adicionada

```nginx
location ~*  \.(jpg|jpeg|png|gif)$ {
    add_header Vary Accept;
    try_files $uri$webp_extension $uri =404;
    expires 7d;
}
```

---

## ❤️ Contribuindo

Sinta-se à vontade para enviar sugestões ou Pull Requests com melhorias, suporte a outros diretórios ou novos formatos de imagem.

---

## 📜 Licença

Este projeto está sob a licença MIT.  
Você pode usar, modificar e distribuir como quiser.

---

## ✨ Créditos

Criado com 💡 por **Rarysson**,  
para ajudar sites WordPress a atingirem máxima performance com uso eficiente de imagens.
