-- TatiFashion: carga inicial gerada por scripts/gerar-seed.js a partir de data/produtos.js
-- Não edite à mão: altere data/produtos.js e rode o script de novo.

insert into categorias (nome, slug, ordem) values
  ('Blusas', 'blusas', 1),
  ('Vestidos', 'vestidos', 2),
  ('Saias', 'saias', 3),
  ('Casacos', 'casacos', 4);

-- Cardigã de tricô off-white
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('cardiga-tricot-off-white', 'Cardigã de tricô off-white', (select id from categorias where slug = 'casacos'), 'Cardigã de tricô leve com botões, perfeito para as noites mais frescas.', 89.90, null, true, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'cardiga-tricot-off-white'), '20200809_153644.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'cardiga-tricot-off-white'), 'P', 'Off-white', 1, 'cardiga-tricot-off-white-p-off-white'),
  ((select id from produtos where slug = 'cardiga-tricot-off-white'), 'M', 'Off-white', 1, 'cardiga-tricot-off-white-m-off-white'),
  ((select id from produtos where slug = 'cardiga-tricot-off-white'), 'G', 'Off-white', 1, 'cardiga-tricot-off-white-g-off-white');

-- Blusa floral tropical
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-floral-tropical-clara', 'Blusa floral tropical', (select id from categorias where slug = 'blusas'), 'Blusa soltinha com estampa floral delicada em fundo claro.', 54.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-floral-tropical-clara'), '20200809_153908.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-floral-tropical-clara'), 'P', 'Off-white floral', 1, 'blusa-floral-tropical-clara-p-off-white-floral'),
  ((select id from produtos where slug = 'blusa-floral-tropical-clara'), 'M', 'Off-white floral', 1, 'blusa-floral-tropical-clara-m-off-white-floral'),
  ((select id from produtos where slug = 'blusa-floral-tropical-clara'), 'G', 'Off-white floral', 1, 'blusa-floral-tropical-clara-g-off-white-floral'),
  ((select id from produtos where slug = 'blusa-floral-tropical-clara'), 'GG', 'Off-white floral', 1, 'blusa-floral-tropical-clara-gg-off-white-floral');

-- Blusa estampada com amarração
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-amarracao-estampada', 'Blusa estampada com amarração', (select id from categorias where slug = 'blusas'), 'Estampa tropical vibrante e amarração na barra para um look moderno.', 59.90, null, true, true);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-amarracao-estampada'), '20200809_154022.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-amarracao-estampada'), 'P', 'Preto estampado', 1, 'blusa-amarracao-estampada-p-preto-estampado'),
  ((select id from produtos where slug = 'blusa-amarracao-estampada'), 'M', 'Preto estampado', 1, 'blusa-amarracao-estampada-m-preto-estampado'),
  ((select id from produtos where slug = 'blusa-amarracao-estampada'), 'G', 'Preto estampado', 1, 'blusa-amarracao-estampada-g-preto-estampado');

-- Blusa preta manga de tule poá
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-manga-tule-poa', 'Blusa preta manga de tule poá', (select id from categorias where slug = 'blusas'), 'Blusa preta com mangas longas em tule de poá e laço na gola.', 64.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-manga-tule-poa'), '20200809_154312.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-manga-tule-poa'), 'P', 'Preto', 1, 'blusa-manga-tule-poa-p-preto'),
  ((select id from produtos where slug = 'blusa-manga-tule-poa'), 'M', 'Preto', 1, 'blusa-manga-tule-poa-m-preto'),
  ((select id from produtos where slug = 'blusa-manga-tule-poa'), 'G', 'Preto', 1, 'blusa-manga-tule-poa-g-preto');

-- Blusa canelada com botões
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-botoes-canelada', 'Blusa canelada com botões', (select id from categorias where slug = 'blusas'), 'Blusa canelada com botões decorativos. Disponível em duas cores.', 44.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-botoes-canelada'), 'dsc03396.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-botoes-canelada'), 'P', 'Verde', 1, 'blusa-botoes-canelada-p-verde'),
  ((select id from produtos where slug = 'blusa-botoes-canelada'), 'P', 'Vermelho', 1, 'blusa-botoes-canelada-p-vermelho'),
  ((select id from produtos where slug = 'blusa-botoes-canelada'), 'M', 'Verde', 1, 'blusa-botoes-canelada-m-verde'),
  ((select id from produtos where slug = 'blusa-botoes-canelada'), 'M', 'Vermelho', 1, 'blusa-botoes-canelada-m-vermelho'),
  ((select id from produtos where slug = 'blusa-botoes-canelada'), 'G', 'Verde', 1, 'blusa-botoes-canelada-g-verde'),
  ((select id from produtos where slug = 'blusa-botoes-canelada'), 'G', 'Vermelho', 1, 'blusa-botoes-canelada-g-vermelho');

-- T-shirt mescla com estampa
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('tshirt-estampa-cinza', 'T-shirt mescla com estampa', (select id from categorias where slug = 'blusas'), 'T-shirt com manga bufante e estampa fotográfica.', 39.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'tshirt-estampa-cinza'), 'dsc03399.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'tshirt-estampa-cinza'), 'P', 'Cinza mescla', 1, 'tshirt-estampa-cinza-p-cinza-mescla'),
  ((select id from produtos where slug = 'tshirt-estampa-cinza'), 'M', 'Cinza mescla', 1, 'tshirt-estampa-cinza-m-cinza-mescla'),
  ((select id from produtos where slug = 'tshirt-estampa-cinza'), 'G', 'Cinza mescla', 1, 'tshirt-estampa-cinza-g-cinza-mescla'),
  ((select id from produtos where slug = 'tshirt-estampa-cinza'), 'GG', 'Cinza mescla', 1, 'tshirt-estampa-cinza-gg-cinza-mescla');

-- T-shirt preta com estampa
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('tshirt-estampa-preta', 'T-shirt preta com estampa', (select id from categorias where slug = 'blusas'), 'T-shirt preta com manga bufante e estampa frontal.', 39.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'tshirt-estampa-preta'), 'dsc03401.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'tshirt-estampa-preta'), 'P', 'Preto', 1, 'tshirt-estampa-preta-p-preto'),
  ((select id from produtos where slug = 'tshirt-estampa-preta'), 'M', 'Preto', 1, 'tshirt-estampa-preta-m-preto'),
  ((select id from produtos where slug = 'tshirt-estampa-preta'), 'G', 'Preto', 1, 'tshirt-estampa-preta-g-preto'),
  ((select id from produtos where slug = 'tshirt-estampa-preta'), 'GG', 'Preto', 1, 'tshirt-estampa-preta-gg-preto');

-- Camisa azul turquesa
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('camisa-azul-turquesa', 'Camisa azul turquesa', (select id from categorias where slug = 'blusas'), 'Camisa de manga longa com bolsos, cor vibrante para qualquer ocasião.', 69.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'camisa-azul-turquesa'), 'dsc03403.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'camisa-azul-turquesa'), 'P', 'Azul turquesa', 1, 'camisa-azul-turquesa-p-azul-turquesa'),
  ((select id from produtos where slug = 'camisa-azul-turquesa'), 'M', 'Azul turquesa', 1, 'camisa-azul-turquesa-m-azul-turquesa'),
  ((select id from produtos where slug = 'camisa-azul-turquesa'), 'G', 'Azul turquesa', 1, 'camisa-azul-turquesa-g-azul-turquesa');

-- Bata floral com detalhes
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('bata-floral-bordada', 'Bata floral com detalhes', (select id from categorias where slug = 'blusas'), 'Bata leve com estampa floral e detalhes em botões na gola.', 54.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'bata-floral-bordada'), 'dsc03406.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'bata-floral-bordada'), 'M', 'Nude floral', 1, 'bata-floral-bordada-m-nude-floral'),
  ((select id from produtos where slug = 'bata-floral-bordada'), 'G', 'Nude floral', 1, 'bata-floral-bordada-g-nude-floral'),
  ((select id from produtos where slug = 'bata-floral-bordada'), 'GG', 'Nude floral', 1, 'bata-floral-bordada-gg-nude-floral');

-- Vestido camiseta mescla
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('vestido-camiseta-mescla', 'Vestido camiseta mescla', (select id from categorias where slug = 'vestidos'), 'Vestido curto estilo camiseta com estampa brilhante.', 69.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'vestido-camiseta-mescla'), 'dsc03410.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'vestido-camiseta-mescla'), 'P', 'Cinza chumbo', 1, 'vestido-camiseta-mescla-p-cinza-chumbo'),
  ((select id from produtos where slug = 'vestido-camiseta-mescla'), 'M', 'Cinza chumbo', 1, 'vestido-camiseta-mescla-m-cinza-chumbo'),
  ((select id from produtos where slug = 'vestido-camiseta-mescla'), 'G', 'Cinza chumbo', 1, 'vestido-camiseta-mescla-g-cinza-chumbo');

-- Blusa com babado no ombro
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-babado-ombro', 'Blusa com babado no ombro', (select id from categorias where slug = 'blusas'), 'Blusa básica com babados nas mangas. Disponível em preto e verde.', 42.90, null, true, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-babado-ombro'), 'dsc03415.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-babado-ombro'), 'P', 'Preto', 1, 'blusa-babado-ombro-p-preto'),
  ((select id from produtos where slug = 'blusa-babado-ombro'), 'P', 'Verde', 1, 'blusa-babado-ombro-p-verde'),
  ((select id from produtos where slug = 'blusa-babado-ombro'), 'M', 'Preto', 1, 'blusa-babado-ombro-m-preto'),
  ((select id from produtos where slug = 'blusa-babado-ombro'), 'M', 'Verde', 1, 'blusa-babado-ombro-m-verde'),
  ((select id from produtos where slug = 'blusa-babado-ombro'), 'G', 'Preto', 1, 'blusa-babado-ombro-g-preto'),
  ((select id from produtos where slug = 'blusa-babado-ombro'), 'G', 'Verde', 1, 'blusa-babado-ombro-g-verde');

-- Saia longa azul marinho
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('saia-longa-azul', 'Saia longa azul marinho', (select id from categorias where slug = 'saias'), 'Saia longa evasê em malha, com bolsos e cós confortável.', 79.90, null, true, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'saia-longa-azul'), 'dsc03416.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'saia-longa-azul'), 'P', 'Azul marinho', 1, 'saia-longa-azul-p-azul-marinho'),
  ((select id from produtos where slug = 'saia-longa-azul'), 'M', 'Azul marinho', 1, 'saia-longa-azul-m-azul-marinho'),
  ((select id from produtos where slug = 'saia-longa-azul'), 'G', 'Azul marinho', 1, 'saia-longa-azul-g-azul-marinho'),
  ((select id from produtos where slug = 'saia-longa-azul'), 'GG', 'Azul marinho', 1, 'saia-longa-azul-gg-azul-marinho');

-- Blusa marinho manga de tule
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-marinho-manga-tule', 'Blusa marinho manga de tule', (select id from categorias where slug = 'blusas'), 'Blusa ampla com mangas curtas em tule de poá.', 59.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-marinho-manga-tule'), 'dsc03419.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-marinho-manga-tule'), 'P', 'Azul marinho', 1, 'blusa-marinho-manga-tule-p-azul-marinho'),
  ((select id from produtos where slug = 'blusa-marinho-manga-tule'), 'M', 'Azul marinho', 1, 'blusa-marinho-manga-tule-m-azul-marinho'),
  ((select id from produtos where slug = 'blusa-marinho-manga-tule'), 'G', 'Azul marinho', 1, 'blusa-marinho-manga-tule-g-azul-marinho');

-- Blusa rosa com gola de renda
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-rosa-gola-renda', 'Blusa rosa com gola de renda', (select id from categorias where slug = 'blusas'), 'Blusa delicada com mangas bufantes de tule e gola em renda.', 64.90, 74.90, true, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-rosa-gola-renda'), 'dsc03421.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-rosa-gola-renda'), 'P', 'Rosa', 1, 'blusa-rosa-gola-renda-p-rosa'),
  ((select id from produtos where slug = 'blusa-rosa-gola-renda'), 'M', 'Rosa', 1, 'blusa-rosa-gola-renda-m-rosa'),
  ((select id from produtos where slug = 'blusa-rosa-gola-renda'), 'G', 'Rosa', 1, 'blusa-rosa-gola-renda-g-rosa');

-- Jaqueta matelassê preta
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('jaqueta-matelasse-preta', 'Jaqueta matelassê preta', (select id from categorias where slug = 'casacos'), 'Jaqueta matelassê com zíper e bolsos frontais.', 119.90, null, true, true);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'jaqueta-matelasse-preta'), 'dsc03423.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'jaqueta-matelasse-preta'), 'P', 'Preto', 1, 'jaqueta-matelasse-preta-p-preto'),
  ((select id from produtos where slug = 'jaqueta-matelasse-preta'), 'M', 'Preto', 1, 'jaqueta-matelasse-preta-m-preto'),
  ((select id from produtos where slug = 'jaqueta-matelasse-preta'), 'G', 'Preto', 1, 'jaqueta-matelasse-preta-g-preto');

-- Vestido tropical gola polo
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('vestido-tropical-gola-polo', 'Vestido tropical gola polo', (select id from categorias where slug = 'vestidos'), 'Vestido soltinho com estampa de folhagens e gola polo.', 89.90, null, true, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'vestido-tropical-gola-polo'), 'dsc03424.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'vestido-tropical-gola-polo'), 'P', 'Preto tropical', 1, 'vestido-tropical-gola-polo-p-preto-tropical'),
  ((select id from produtos where slug = 'vestido-tropical-gola-polo'), 'M', 'Preto tropical', 1, 'vestido-tropical-gola-polo-m-preto-tropical'),
  ((select id from produtos where slug = 'vestido-tropical-gola-polo'), 'G', 'Preto tropical', 1, 'vestido-tropical-gola-polo-g-preto-tropical'),
  ((select id from produtos where slug = 'vestido-tropical-gola-polo'), 'GG', 'Preto tropical', 1, 'vestido-tropical-gola-polo-gg-preto-tropical');

-- Bata rosê com botões
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('bata-rose-botoes', 'Bata rosê com botões', (select id from categorias where slug = 'blusas'), 'Bata com botões frontais e amarração nas mangas.', 49.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'bata-rose-botoes'), 'dsc03426.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'bata-rose-botoes'), 'P', 'Rosê', 1, 'bata-rose-botoes-p-rose'),
  ((select id from produtos where slug = 'bata-rose-botoes'), 'M', 'Rosê', 1, 'bata-rose-botoes-m-rose'),
  ((select id from produtos where slug = 'bata-rose-botoes'), 'G', 'Rosê', 1, 'bata-rose-botoes-g-rose');

-- Bata com botões e laço
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('bata-botoes-duas-cores', 'Bata com botões e laço', (select id from categorias where slug = 'blusas'), 'Mesma modelagem da bata rosê, também disponível em coral.', 49.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'bata-botoes-duas-cores'), 'dsc03428.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'bata-botoes-duas-cores'), 'P', 'Rosê', 1, 'bata-botoes-duas-cores-p-rose'),
  ((select id from produtos where slug = 'bata-botoes-duas-cores'), 'P', 'Coral', 1, 'bata-botoes-duas-cores-p-coral'),
  ((select id from produtos where slug = 'bata-botoes-duas-cores'), 'M', 'Rosê', 1, 'bata-botoes-duas-cores-m-rose'),
  ((select id from produtos where slug = 'bata-botoes-duas-cores'), 'M', 'Coral', 1, 'bata-botoes-duas-cores-m-coral'),
  ((select id from produtos where slug = 'bata-botoes-duas-cores'), 'G', 'Rosê', 1, 'bata-botoes-duas-cores-g-rose'),
  ((select id from produtos where slug = 'bata-botoes-duas-cores'), 'G', 'Coral', 1, 'bata-botoes-duas-cores-g-coral');

-- Vestido chemise listrado
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('vestido-chemise-listrado', 'Vestido chemise listrado', (select id from categorias where slug = 'vestidos'), 'Chemise listrado com cinto, elegante para o dia a dia e para o culto.', 99.90, null, false, true);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'vestido-chemise-listrado'), 'dsc03430.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'vestido-chemise-listrado'), 'P', 'Verde e branco', 1, 'vestido-chemise-listrado-p-verde-e-branco'),
  ((select id from produtos where slug = 'vestido-chemise-listrado'), 'M', 'Verde e branco', 1, 'vestido-chemise-listrado-m-verde-e-branco'),
  ((select id from produtos where slug = 'vestido-chemise-listrado'), 'G', 'Verde e branco', 1, 'vestido-chemise-listrado-g-verde-e-branco');

-- Saia midi bege
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('saia-midi-bege', 'Saia midi bege', (select id from categorias where slug = 'saias'), 'Saia midi evasê em sarja com cinto.', 74.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'saia-midi-bege'), 'dsc03434.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'saia-midi-bege'), '36', 'Bege', 1, 'saia-midi-bege-36-bege'),
  ((select id from produtos where slug = 'saia-midi-bege'), '38', 'Bege', 1, 'saia-midi-bege-38-bege'),
  ((select id from produtos where slug = 'saia-midi-bege'), '40', 'Bege', 1, 'saia-midi-bege-40-bege'),
  ((select id from produtos where slug = 'saia-midi-bege'), '42', 'Bege', 1, 'saia-midi-bege-42-bege'),
  ((select id from produtos where slug = 'saia-midi-bege'), '44', 'Bege', 1, 'saia-midi-bege-44-bege');

-- Blusa com decote de ilhoses
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-decote-ilhoses', 'Blusa com decote de ilhoses', (select id from categorias where slug = 'blusas'), 'Blusa básica com detalhe de ilhoses no decote.', 44.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-decote-ilhoses'), 'dsc03436.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-decote-ilhoses'), 'P', 'Azul royal', 1, 'blusa-decote-ilhoses-p-azul-royal'),
  ((select id from produtos where slug = 'blusa-decote-ilhoses'), 'P', 'Verde petróleo', 1, 'blusa-decote-ilhoses-p-verde-petroleo'),
  ((select id from produtos where slug = 'blusa-decote-ilhoses'), 'M', 'Azul royal', 1, 'blusa-decote-ilhoses-m-azul-royal'),
  ((select id from produtos where slug = 'blusa-decote-ilhoses'), 'M', 'Verde petróleo', 1, 'blusa-decote-ilhoses-m-verde-petroleo'),
  ((select id from produtos where slug = 'blusa-decote-ilhoses'), 'G', 'Azul royal', 1, 'blusa-decote-ilhoses-g-azul-royal'),
  ((select id from produtos where slug = 'blusa-decote-ilhoses'), 'G', 'Verde petróleo', 1, 'blusa-decote-ilhoses-g-verde-petroleo');

-- T-shirt preta estampa foto
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('tshirt-preta-foto', 'T-shirt preta estampa foto', (select id from categorias where slug = 'blusas'), 'T-shirt com manga bufante e estampa fotográfica.', 39.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'tshirt-preta-foto'), 'dsc03437.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'tshirt-preta-foto'), 'P', 'Preto', 1, 'tshirt-preta-foto-p-preto'),
  ((select id from produtos where slug = 'tshirt-preta-foto'), 'M', 'Preto', 1, 'tshirt-preta-foto-m-preto'),
  ((select id from produtos where slug = 'tshirt-preta-foto'), 'G', 'Preto', 1, 'tshirt-preta-foto-g-preto'),
  ((select id from produtos where slug = 'tshirt-preta-foto'), 'GG', 'Preto', 1, 'tshirt-preta-foto-gg-preto');

-- T-shirt gatinho com strass
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('tshirt-gatinho-strass', 'T-shirt gatinho com strass', (select id from categorias where slug = 'blusas'), 'T-shirt divertida com estampa de gatinho e aplicações.', 42.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'tshirt-gatinho-strass'), 'dsc03438.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'tshirt-gatinho-strass'), 'P', 'Preto', 1, 'tshirt-gatinho-strass-p-preto'),
  ((select id from produtos where slug = 'tshirt-gatinho-strass'), 'M', 'Preto', 1, 'tshirt-gatinho-strass-m-preto'),
  ((select id from produtos where slug = 'tshirt-gatinho-strass'), 'G', 'Preto', 1, 'tshirt-gatinho-strass-g-preto');

-- Vestido preto mullet
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('vestido-preto-mullet', 'Vestido preto mullet', (select id from categorias where slug = 'vestidos'), 'Vestido básico com barra mullet, curinga no guarda-roupa.', 79.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'vestido-preto-mullet'), 'dsc03439.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'vestido-preto-mullet'), 'P', 'Preto', 1, 'vestido-preto-mullet-p-preto'),
  ((select id from produtos where slug = 'vestido-preto-mullet'), 'M', 'Preto', 1, 'vestido-preto-mullet-m-preto'),
  ((select id from produtos where slug = 'vestido-preto-mullet'), 'G', 'Preto', 1, 'vestido-preto-mullet-g-preto'),
  ((select id from produtos where slug = 'vestido-preto-mullet'), 'GG', 'Preto', 1, 'vestido-preto-mullet-gg-preto');

-- Vestido marinho mullet
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('vestido-marinho-mullet', 'Vestido marinho mullet', (select id from categorias where slug = 'vestidos'), 'Vestido básico com barra mullet em azul marinho.', 79.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'vestido-marinho-mullet'), 'dsc03440.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'vestido-marinho-mullet'), 'P', 'Azul marinho', 1, 'vestido-marinho-mullet-p-azul-marinho'),
  ((select id from produtos where slug = 'vestido-marinho-mullet'), 'M', 'Azul marinho', 1, 'vestido-marinho-mullet-m-azul-marinho'),
  ((select id from produtos where slug = 'vestido-marinho-mullet'), 'G', 'Azul marinho', 1, 'vestido-marinho-mullet-g-azul-marinho'),
  ((select id from produtos where slug = 'vestido-marinho-mullet'), 'GG', 'Azul marinho', 1, 'vestido-marinho-mullet-gg-azul-marinho');

-- T-shirt tie-dye
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('tshirt-tie-dye', 'T-shirt tie-dye', (select id from categorias where slug = 'blusas'), 'T-shirt com estampa tie-dye colorida e alegre.', 44.90, 52.90, false, true);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'tshirt-tie-dye'), 'dsc03442.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'tshirt-tie-dye'), 'P', 'Tie-dye colorido', 1, 'tshirt-tie-dye-p-tie-dye-colorido'),
  ((select id from produtos where slug = 'tshirt-tie-dye'), 'M', 'Tie-dye colorido', 1, 'tshirt-tie-dye-m-tie-dye-colorido'),
  ((select id from produtos where slug = 'tshirt-tie-dye'), 'G', 'Tie-dye colorido', 1, 'tshirt-tie-dye-g-tie-dye-colorido');

-- Blusa listrada lilás
insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ('blusa-listrada-lilas', 'Blusa listrada lilás', (select id from categorias where slug = 'blusas'), 'Blusa de malha listrada com babado nas mangas.', 49.90, null, false, false);
insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = 'blusa-listrada-lilas'), 'dsc03443.jpg', 0);
insert into variantes (produto_id, tamanho, cor, estoque, sku) values
  ((select id from produtos where slug = 'blusa-listrada-lilas'), 'P', 'Lilás e branco', 1, 'blusa-listrada-lilas-p-lilas-e-branco'),
  ((select id from produtos where slug = 'blusa-listrada-lilas'), 'M', 'Lilás e branco', 1, 'blusa-listrada-lilas-m-lilas-e-branco'),
  ((select id from produtos where slug = 'blusa-listrada-lilas'), 'G', 'Lilás e branco', 1, 'blusa-listrada-lilas-g-lilas-e-branco');

-- Dados da loja. Troque o CEP de origem pelo CEP de onde os pacotes saem.
insert into config_loja (cep_origem, whatsapp, instagram) values ('00000-000', '5521996095743', 'https://www.instagram.com/');
