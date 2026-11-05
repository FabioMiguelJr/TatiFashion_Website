-- TatiFashion: tabelas do banco de dados
-- Rode este arquivo primeiro (SQL Editor do Supabase ou "supabase db push").

create type status_pedido as enum
  ('aguardando_pagamento', 'pago', 'em_separacao', 'enviado', 'entregue', 'cancelado');
create type canal_pedido as enum ('site', 'whatsapp');

-- ---------- Catálogo ----------

create table categorias (
  id     smallint generated always as identity primary key,
  nome   text not null,
  slug   text not null unique,
  ordem  smallint not null default 0
);

create table produtos (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,              -- ex.: blusa-rosa-gola-renda
  nome           text not null,
  categoria_id   smallint not null references categorias(id),
  descricao      text,
  preco          numeric(10,2) not null check (preco > 0),
  preco_antigo   numeric(10,2) check (preco_antigo is null or preco_antigo > preco),
  peso_g         int not null default 300 check (peso_g > 0),   -- usado no frete
  altura_cm      int not null default 5   check (altura_cm > 0),
  largura_cm     int not null default 20  check (largura_cm > 0),
  comprimento_cm int not null default 30  check (comprimento_cm > 0),
  destaque       boolean not null default false,
  novo           boolean not null default false,
  ativo          boolean not null default true,
  criado_em      timestamptz not null default now(),
  atualizado_em  timestamptz not null default now()
);

create table produto_fotos (
  id          bigint generated always as identity primary key,
  produto_id  uuid not null references produtos(id) on delete cascade,
  caminho     text not null,                        -- nome do arquivo no bucket "produtos"
  ordem       smallint not null default 0
);

create table variantes (
  id          bigint generated always as identity primary key,
  produto_id  uuid not null references produtos(id) on delete cascade,
  tamanho     text not null,
  cor         text not null,
  estoque     int not null default 0 check (estoque >= 0),
  sku         text unique,
  unique (produto_id, tamanho, cor)
);

-- ---------- Vendas ----------

create table clientes (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null,
  email      text,
  telefone   text not null,
  cpf        text,
  criado_em  timestamptz not null default now()
);

create table pedidos (
  id                uuid primary key default gen_random_uuid(),
  numero            int generated always as identity (start with 1001) unique,  -- número que a cliente vê
  cliente_id        uuid not null references clientes(id),
  canal             canal_pedido not null,
  status            status_pedido not null default 'aguardando_pagamento',
  subtotal          numeric(10,2) not null default 0,
  frete_valor       numeric(10,2) not null default 0 check (frete_valor >= 0),
  frete_servico     text,                           -- PAC, SEDEX, Retirada
  frete_prazo_dias  int,
  desconto          numeric(10,2) not null default 0 check (desconto >= 0),
  total             numeric(10,2) not null default 0,
  cep               text,
  rua               text,
  numero_end        text,
  complemento       text,
  bairro            text,
  cidade            text,
  uf                char(2),
  mp_preference_id  text,
  me_envio_id       text,
  codigo_rastreio   text,
  observacao        text,
  criado_em         timestamptz not null default now(),
  pago_em           timestamptz,
  enviado_em        timestamptz
);

create table itens_pedido (
  id              bigint generated always as identity primary key,
  pedido_id       uuid not null references pedidos(id) on delete cascade,
  variante_id     bigint references variantes(id) on delete set null,
  nome_produto    text not null,                    -- cópia no momento da compra
  tamanho         text not null,
  cor             text not null,
  preco_unitario  numeric(10,2) not null,
  quantidade      int not null check (quantidade > 0)
);

create table pagamentos (
  id           bigint generated always as identity primary key,
  pedido_id    uuid not null references pedidos(id),
  provedor     text not null default 'mercadopago',
  provedor_id  text not null unique,                -- id do pagamento no Mercado Pago
  status       text not null,                       -- approved, pending, rejected...
  metodo       text,                                -- pix, credit_card, ticket
  valor        numeric(10,2),
  resposta     jsonb,
  criado_em    timestamptz not null default now()
);

-- ---------- Loja e acesso ----------

create table config_loja (
  id                  boolean primary key default true check (id),   -- só 1 linha
  cep_origem          text not null,
  whatsapp            text not null,
  instagram           text,
  frete_gratis_acima  numeric(10,2),
  retirada_ativa      boolean not null default true,
  retirada_texto      text default 'Retirar com a Tati (combinar pelo WhatsApp)'
);

create table admins (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  nome     text
);

-- ---------- Índices ----------

create index produtos_categoria_idx   on produtos (categoria_id) where ativo;
create index produto_fotos_prod_idx   on produto_fotos (produto_id, ordem);
create index variantes_produto_idx    on variantes (produto_id);
create index pedidos_status_idx       on pedidos (status, criado_em desc);
create index pedidos_cliente_idx      on pedidos (cliente_id);
create index itens_pedido_pedido_idx  on itens_pedido (pedido_id);
create index pagamentos_pedido_idx    on pagamentos (pedido_id);
