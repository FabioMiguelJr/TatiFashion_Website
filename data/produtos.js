/*
  CATÁLOGO DE PRODUTOS DA TATIFASHION
  -----------------------------------
  Para adicionar um produto, copie um bloco { ... } e altere os campos:
    id         -> identificador único, sem espaços nem acentos (ex.: "blusa-floral-01")
    nome       -> nome que aparece no site
    categoria  -> "Blusas", "Vestidos", "Saias" ou "Casacos" (ou crie uma nova)
    preco      -> preço em reais, com ponto no lugar da vírgula (ex.: 59.90)
    precoAntigo-> opcional: preço "de" para mostrar promoção
    tamanhos   -> lista de tamanhos disponíveis
    cores      -> lista de cores disponíveis
    foto       -> caminho da foto dentro da pasta img/produtos
    descricao  -> texto curto sobre a peça
    destaque   -> true para aparecer na página inicial
    novo       -> true para mostrar o selo "Novo"

  ATENÇÃO: os preços abaixo são apenas exemplos para teste.
*/
window.PRODUTOS = [
  { id: "cardiga-tricot-off-white", nome: "Cardigã de tricô off-white", categoria: "Casacos", preco: 89.90, tamanhos: ["P","M","G"], cores: ["Off-white"], foto: "img/produtos/20200809_153644.jpg", descricao: "Cardigã de tricô leve com botões, perfeito para as noites mais frescas.", destaque: true },
  { id: "blusa-floral-tropical-clara", nome: "Blusa floral tropical", categoria: "Blusas", preco: 54.90, tamanhos: ["P","M","G","GG"], cores: ["Off-white floral"], foto: "img/produtos/20200809_153908.jpg", descricao: "Blusa soltinha com estampa floral delicada em fundo claro." },
  { id: "blusa-amarracao-estampada", nome: "Blusa estampada com amarração", categoria: "Blusas", preco: 59.90, tamanhos: ["P","M","G"], cores: ["Preto estampado"], foto: "img/produtos/20200809_154022.jpg", descricao: "Estampa tropical vibrante e amarração na barra para um look moderno.", destaque: true, novo: true },
  { id: "blusa-manga-tule-poa", nome: "Blusa preta manga de tule poá", categoria: "Blusas", preco: 64.90, tamanhos: ["P","M","G"], cores: ["Preto"], foto: "img/produtos/20200809_154312.jpg", descricao: "Blusa preta com mangas longas em tule de poá e laço na gola." },
  { id: "blusa-botoes-canelada", nome: "Blusa canelada com botões", categoria: "Blusas", preco: 44.90, tamanhos: ["P","M","G"], cores: ["Verde","Vermelho"], foto: "img/produtos/dsc03396.jpg", descricao: "Blusa canelada com botões decorativos. Disponível em duas cores." },
  { id: "tshirt-estampa-cinza", nome: "T-shirt mescla com estampa", categoria: "Blusas", preco: 39.90, tamanhos: ["P","M","G","GG"], cores: ["Cinza mescla"], foto: "img/produtos/dsc03399.jpg", descricao: "T-shirt com manga bufante e estampa fotográfica." },
  { id: "tshirt-estampa-preta", nome: "T-shirt preta com estampa", categoria: "Blusas", preco: 39.90, tamanhos: ["P","M","G","GG"], cores: ["Preto"], foto: "img/produtos/dsc03401.jpg", descricao: "T-shirt preta com manga bufante e estampa frontal." },
  { id: "camisa-azul-turquesa", nome: "Camisa azul turquesa", categoria: "Blusas", preco: 69.90, tamanhos: ["P","M","G"], cores: ["Azul turquesa"], foto: "img/produtos/dsc03403.jpg", descricao: "Camisa de manga longa com bolsos, cor vibrante para qualquer ocasião." },
  { id: "bata-floral-bordada", nome: "Bata floral com detalhes", categoria: "Blusas", preco: 54.90, tamanhos: ["M","G","GG"], cores: ["Nude floral"], foto: "img/produtos/dsc03406.jpg", descricao: "Bata leve com estampa floral e detalhes em botões na gola." },
  { id: "vestido-camiseta-mescla", nome: "Vestido camiseta mescla", categoria: "Vestidos", preco: 69.90, tamanhos: ["P","M","G"], cores: ["Cinza chumbo"], foto: "img/produtos/dsc03410.jpg", descricao: "Vestido curto estilo camiseta com estampa brilhante." },
  { id: "blusa-babado-ombro", nome: "Blusa com babado no ombro", categoria: "Blusas", preco: 42.90, tamanhos: ["P","M","G"], cores: ["Preto","Verde"], foto: "img/produtos/dsc03415.jpg", descricao: "Blusa básica com babados nas mangas. Disponível em preto e verde.", destaque: true },
  { id: "saia-longa-azul", nome: "Saia longa azul marinho", categoria: "Saias", preco: 79.90, tamanhos: ["P","M","G","GG"], cores: ["Azul marinho"], foto: "img/produtos/dsc03416.jpg", descricao: "Saia longa evasê em malha, com bolsos e cós confortável.", destaque: true },
  { id: "blusa-marinho-manga-tule", nome: "Blusa marinho manga de tule", categoria: "Blusas", preco: 59.90, tamanhos: ["P","M","G"], cores: ["Azul marinho"], foto: "img/produtos/dsc03419.jpg", descricao: "Blusa ampla com mangas curtas em tule de poá." },
  { id: "blusa-rosa-gola-renda", nome: "Blusa rosa com gola de renda", categoria: "Blusas", preco: 64.90, precoAntigo: 74.90, tamanhos: ["P","M","G"], cores: ["Rosa"], foto: "img/produtos/dsc03421.jpg", descricao: "Blusa delicada com mangas bufantes de tule e gola em renda.", destaque: true },
  { id: "jaqueta-matelasse-preta", nome: "Jaqueta matelassê preta", categoria: "Casacos", preco: 119.90, tamanhos: ["P","M","G"], cores: ["Preto"], foto: "img/produtos/dsc03423.jpg", descricao: "Jaqueta matelassê com zíper e bolsos frontais.", destaque: true, novo: true },
  { id: "vestido-tropical-gola-polo", nome: "Vestido tropical gola polo", categoria: "Vestidos", preco: 89.90, tamanhos: ["P","M","G","GG"], cores: ["Preto tropical"], foto: "img/produtos/dsc03424.jpg", descricao: "Vestido soltinho com estampa de folhagens e gola polo.", destaque: true },
  { id: "bata-rose-botoes", nome: "Bata rosê com botões", categoria: "Blusas", preco: 49.90, tamanhos: ["P","M","G"], cores: ["Rosê"], foto: "img/produtos/dsc03426.jpg", descricao: "Bata com botões frontais e amarração nas mangas." },
  { id: "bata-botoes-duas-cores", nome: "Bata com botões e laço", categoria: "Blusas", preco: 49.90, tamanhos: ["P","M","G"], cores: ["Rosê","Coral"], foto: "img/produtos/dsc03428.jpg", descricao: "Mesma modelagem da bata rosê, também disponível em coral." },
  { id: "vestido-chemise-listrado", nome: "Vestido chemise listrado", categoria: "Vestidos", preco: 99.90, tamanhos: ["P","M","G"], cores: ["Verde e branco"], foto: "img/produtos/dsc03430.jpg", descricao: "Chemise listrado com cinto, elegante para o dia a dia e para o culto.", novo: true },
  { id: "saia-midi-bege", nome: "Saia midi bege", categoria: "Saias", preco: 74.90, tamanhos: ["36","38","40","42","44"], cores: ["Bege"], foto: "img/produtos/dsc03434.jpg", descricao: "Saia midi evasê em sarja com cinto." },
  { id: "blusa-decote-ilhoses", nome: "Blusa com decote de ilhoses", categoria: "Blusas", preco: 44.90, tamanhos: ["P","M","G"], cores: ["Azul royal","Verde petróleo"], foto: "img/produtos/dsc03436.jpg", descricao: "Blusa básica com detalhe de ilhoses no decote." },
  { id: "tshirt-preta-foto", nome: "T-shirt preta estampa foto", categoria: "Blusas", preco: 39.90, tamanhos: ["P","M","G","GG"], cores: ["Preto"], foto: "img/produtos/dsc03437.jpg", descricao: "T-shirt com manga bufante e estampa fotográfica." },
  { id: "tshirt-gatinho-strass", nome: "T-shirt gatinho com strass", categoria: "Blusas", preco: 42.90, tamanhos: ["P","M","G"], cores: ["Preto"], foto: "img/produtos/dsc03438.jpg", descricao: "T-shirt divertida com estampa de gatinho e aplicações." },
  { id: "vestido-preto-mullet", nome: "Vestido preto mullet", categoria: "Vestidos", preco: 79.90, tamanhos: ["P","M","G","GG"], cores: ["Preto"], foto: "img/produtos/dsc03439.jpg", descricao: "Vestido básico com barra mullet, curinga no guarda-roupa." },
  { id: "vestido-marinho-mullet", nome: "Vestido marinho mullet", categoria: "Vestidos", preco: 79.90, tamanhos: ["P","M","G","GG"], cores: ["Azul marinho"], foto: "img/produtos/dsc03440.jpg", descricao: "Vestido básico com barra mullet em azul marinho." },
  { id: "tshirt-tie-dye", nome: "T-shirt tie-dye", categoria: "Blusas", preco: 44.90, precoAntigo: 52.90, tamanhos: ["P","M","G"], cores: ["Tie-dye colorido"], foto: "img/produtos/dsc03442.jpg", descricao: "T-shirt com estampa tie-dye colorida e alegre.", novo: true },
  { id: "blusa-listrada-lilas", nome: "Blusa listrada lilás", categoria: "Blusas", preco: 49.90, tamanhos: ["P","M","G"], cores: ["Lilás e branco"], foto: "img/produtos/dsc03443.jpg", descricao: "Blusa de malha listrada com babado nas mangas." }
];

/* Dados da loja usados em todo o site */
window.LOJA = {
  nome: "TatiFashion Modas",
  instagram: "https://www.instagram.com/",   // troque pelo link do Instagram da loja
  whatsapp: ""                                 // número com DDI e DDD, só dígitos (ex.: "5511999999999") — usado no passo 2
};
