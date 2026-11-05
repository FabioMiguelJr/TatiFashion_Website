-- ===== 20261105000001_tabelas.sql =====
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


-- ===== 20261105000002_seguranca.sql =====
-- TatiFashion: regras de acesso (RLS) e pasta de fotos
-- Sem uma regra que permita, ninguém lê nem grava nada.

alter table categorias    enable row level security;
alter table produtos      enable row level security;
alter table produto_fotos enable row level security;
alter table variantes     enable row level security;
alter table clientes      enable row level security;
alter table pedidos       enable row level security;
alter table itens_pedido  enable row level security;
alter table pagamentos    enable row level security;
alter table config_loja   enable row level security;
alter table admins        enable row level security;

-- Verdadeiro quando quem está logado está na tabela admins (a Tati).
create function eh_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from admins where user_id = auth.uid());
$$;

-- Visitantes do site leem o catálogo.
create policy leitura_publica on categorias    for select using (true);
create policy leitura_publica on produtos      for select using (ativo or eh_admin());
create policy leitura_publica on produto_fotos for select using (true);
create policy leitura_publica on variantes     for select using (true);
create policy leitura_publica on config_loja   for select using (true);

-- A Tati, logada no painel, faz tudo.
create policy admin_tudo on categorias    for all using (eh_admin()) with check (eh_admin());
create policy admin_tudo on produtos      for all using (eh_admin()) with check (eh_admin());
create policy admin_tudo on produto_fotos for all using (eh_admin()) with check (eh_admin());
create policy admin_tudo on variantes     for all using (eh_admin()) with check (eh_admin());
create policy admin_tudo on clientes      for all using (eh_admin()) with check (eh_admin());
create policy admin_tudo on pedidos       for all using (eh_admin()) with check (eh_admin());
create policy admin_tudo on itens_pedido  for all using (eh_admin()) with check (eh_admin());
create policy admin_le   on pagamentos    for select using (eh_admin());
create policy admin_tudo on config_loja   for all using (eh_admin()) with check (eh_admin());
create policy admin_le   on admins        for select using (eh_admin());

-- Pasta pública de fotos no Storage: todos veem, só a Tati envia ou apaga.
insert into storage.buckets (id, name, public)
values ('produtos', 'produtos', true)
on conflict (id) do nothing;

create policy fotos_leitura on storage.objects
  for select using (bucket_id = 'produtos');
create policy fotos_admin on storage.objects
  for all using (bucket_id = 'produtos' and public.eh_admin())
  with check (bucket_id = 'produtos' and public.eh_admin());


-- ===== 20261105000003_funcoes.sql =====
-- TatiFashion: funções do banco
-- criar_pedido só pode ser chamada pelas funções de servidor (chave secreta).

-- Atualiza produtos.atualizado_em sozinho.
create function marcar_atualizado() returns trigger language plpgsql as $$
begin
  new.atualizado_em := now();
  return new;
end $$;

create trigger produtos_atualizado before update on produtos
for each row execute function marcar_atualizado();

-- Grava cliente, pedido e itens de uma vez (ou nada, se der erro).
-- O preço vem sempre do banco, nunca do navegador.
-- p_itens: [{"variante_id": 12, "quantidade": 1}, ...]
-- p_frete: {"valor": 21.50, "servico": "PAC", "prazo": 6}
create function criar_pedido(p_cliente jsonb, p_endereco jsonb, p_itens jsonb,
                             p_canal canal_pedido, p_frete jsonb)
returns table (pedido_id uuid, numero int, subtotal numeric, total numeric)
language plpgsql security definer set search_path = public as $$
declare
  v_cliente  uuid;
  v_pedido   uuid;
  v_subtotal numeric(10,2) := 0;
  v_qtd      int;
  it         jsonb;
  v          record;
begin
  if p_itens is null or jsonb_array_length(p_itens) = 0 then
    raise exception 'Pedido sem itens';
  end if;
  if coalesce(trim(p_cliente->>'nome'), '') = '' or coalesce(trim(p_cliente->>'telefone'), '') = '' then
    raise exception 'Nome e telefone são obrigatórios';
  end if;

  insert into clientes (nome, email, telefone, cpf)
  values (trim(p_cliente->>'nome'), nullif(trim(p_cliente->>'email'), ''),
          trim(p_cliente->>'telefone'), nullif(trim(p_cliente->>'cpf'), ''))
  returning id into v_cliente;

  insert into pedidos (cliente_id, canal, frete_valor, frete_servico, frete_prazo_dias,
                       cep, rua, numero_end, complemento, bairro, cidade, uf, observacao)
  values (v_cliente, p_canal,
          coalesce((p_frete->>'valor')::numeric, 0), p_frete->>'servico', (p_frete->>'prazo')::int,
          p_endereco->>'cep', p_endereco->>'rua', p_endereco->>'numero', p_endereco->>'complemento',
          p_endereco->>'bairro', p_endereco->>'cidade', upper(p_endereco->>'uf'),
          nullif(trim(p_cliente->>'observacao'), ''))
  returning id into v_pedido;

  for it in select * from jsonb_array_elements(p_itens) loop
    v_qtd := (it->>'quantidade')::int;
    if v_qtd is null or v_qtd < 1 then
      raise exception 'Quantidade inválida';
    end if;

    select va.id, va.tamanho, va.cor, va.estoque, pr.nome, pr.preco into v
    from variantes va join produtos pr on pr.id = va.produto_id
    where va.id = (it->>'variante_id')::bigint and pr.ativo;

    if v.id is null then
      raise exception 'Peça não encontrada: %', it->>'variante_id';
    end if;
    if v.estoque < v_qtd then
      raise exception 'Sem estoque: % (% / %)', v.nome, v.tamanho, v.cor;
    end if;

    insert into itens_pedido (pedido_id, variante_id, nome_produto, tamanho, cor, preco_unitario, quantidade)
    values (v_pedido, v.id, v.nome, v.tamanho, v.cor, v.preco, v_qtd);
    v_subtotal := v_subtotal + v.preco * v_qtd;
  end loop;

  update pedidos p
     set subtotal = v_subtotal,
         total    = v_subtotal + p.frete_valor - p.desconto
   where p.id = v_pedido;

  return query select p.id, p.numero, p.subtotal, p.total from pedidos p where p.id = v_pedido;
end $$;

revoke execute on function criar_pedido(jsonb, jsonb, jsonb, canal_pedido, jsonb) from public, anon, authenticated;
grant  execute on function criar_pedido(jsonb, jsonb, jsonb, canal_pedido, jsonb) to service_role;

-- Baixa o estoque quando o pedido vira "pago" e devolve se um pedido pago for cancelado.
create function ajustar_estoque() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.status = 'aguardando_pagamento' and new.status = 'pago' then
    update variantes va set estoque = greatest(va.estoque - i.quantidade, 0)
    from itens_pedido i where i.pedido_id = new.id and i.variante_id = va.id;
    new.pago_em := coalesce(new.pago_em, now());
  elsif new.status = 'cancelado' and old.status in ('pago', 'em_separacao') then
    update variantes va set estoque = va.estoque + i.quantidade
    from itens_pedido i where i.pedido_id = new.id and i.variante_id = va.id;
  end if;
  if new.status = 'enviado' and old.status <> 'enviado' then
    new.enviado_em := coalesce(new.enviado_em, now());
  end if;
  return new;
end $$;

create trigger pedidos_estoque before update of status on pedidos
for each row when (old.status is distinct from new.status)
execute function ajustar_estoque();

-- Cancela pedidos não pagos depois de 3 dias (rodar 1 vez por dia).
create function cancelar_pedidos_vencidos() returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  update pedidos set status = 'cancelado'
  where status = 'aguardando_pagamento' and criado_em < now() - interval '3 days';
  get diagnostics n = row_count;
  return n;
end $$;

revoke execute on function cancelar_pedidos_vencidos() from public, anon, authenticated;
grant  execute on function cancelar_pedidos_vencidos() to service_role;


-- ===== 20261105000004_mercadopago_orders.sql =====
-- TatiFashion: guarda o id da order do Mercado Pago (API de Orders) em cada pedido
alter table pedidos add column mp_order_id text unique;
alter table pedidos add column mp_status text;  -- último status visto no Mercado Pago
create index pedidos_external_idx on pedidos (numero);


-- ===== seed.sql =====
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
