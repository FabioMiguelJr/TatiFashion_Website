# TatiFashion_Website
Repositório dos elementos e componentes do Website "TatiFashion Modas".

Site estático (HTML, CSS e JavaScript, sem servidor), pensado primeiro para celular.

## Páginas
- `index.html`: início, com categorias e destaques
- `catalogo.html`: todos os produtos, com filtro por categoria, busca e ordenação
- `produto.html?id=...`: detalhes da peça, com escolha de tamanho e cor

## Como ver no computador
Abra `index.html` com dois cliques no navegador. Para simular o celular, aperte F12 e clique no ícone de celular.

## Como adicionar ou trocar produtos
1. Coloque a foto em `img/produtos/` (de preferência com no máximo 1200 px de altura).
2. Abra `data/produtos.js` e copie um bloco `{ ... }`, trocando nome, preço, tamanhos, cores e o caminho da foto.
3. Os dados da loja (Instagram e WhatsApp) ficam no fim do mesmo arquivo, em `window.LOJA`.
