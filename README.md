# TatiFashion_Website
Repositório dos elementos e componentes do Website "TatiFashion Modas".

Site estático (HTML, CSS e JavaScript, sem servidor), pensado primeiro para celular.

## Páginas
- `index.html`: início, com categorias e destaques
- `catalogo.html`: todos os produtos, com filtro por categoria, busca e ordenação
- `produto.html?id=...`: detalhes da peça, com escolha de tamanho e cor
- `sacola.html`: sacola de compras e envio do pedido pelo WhatsApp

## Como funciona o pedido
A sacola fica salva no navegador do cliente. Ao tocar em "Enviar pedido pelo WhatsApp", o site abre o WhatsApp da loja com a lista de peças, tamanhos, cores, quantidades, total e os dados do comprador. O pagamento e a entrega são combinados na conversa.

Para trocar o número que recebe os pedidos, edite `whatsapp` em `window.LOJA`, no fim de `data/produtos.js` (só dígitos, com 55 e DDD).

## Como ver no computador
Abra `index.html` com dois cliques no navegador. Para simular o celular, aperte F12 e clique no ícone de celular.

## Como adicionar ou trocar produtos
1. Coloque a foto em `img/produtos/` (de preferência com no máximo 1200 px de altura).
2. Abra `data/produtos.js` e copie um bloco `{ ... }`, trocando nome, preço, tamanhos, cores e o caminho da foto.
3. Os dados da loja (Instagram e WhatsApp) ficam no fim do mesmo arquivo, em `window.LOJA`.

## Como publicar o site

O site não precisa de servidor: qualquer hospedagem de arquivos estáticos serve. Todos os links são relativos, então ele funciona em qualquer endereço.

### GitHub Pages (repositório público)
1. No GitHub, abra **Settings > Pages**.
2. Em **Build and deployment**, escolha **Deploy from a branch**, branch `main`, pasta `/ (root)`, e clique em **Save**.
3. Em 1 ou 2 minutos o site fica no ar em `https://fabiomigueljr.github.io/TatiFashion_Website/`.
4. A cada alteração enviada para a `main`, o site se atualiza sozinho.

### Netlify (repositório privado)
1. Crie uma conta grátis em netlify.com entrando com o GitHub.
2. **Add new site > Import an existing project > GitHub** e escolha `TatiFashion_Website`.
3. Deixe o comando de build vazio e a pasta de publicação como `.`, e clique em **Deploy**.
4. Em **Site configuration > Change site name** dá para escolher algo como `tatifashion.netlify.app`.

## Dia a dia: atualizar produtos
1. Coloque as fotos novas em `img/produtos/`.
2. Edite `data/produtos.js` (pode ser pelo próprio site do GitHub, no ícone de lápis).
3. Salve (commit) na `main`. O site publicado se atualiza em poucos minutos.

Dica: antes de subir, reduza as fotos para no máximo 1200 px de altura (por exemplo em squoosh.app) para o site continuar rápido no celular.
