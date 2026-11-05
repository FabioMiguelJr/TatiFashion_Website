-- Testes do banco. Rodar depois de simular-supabase.sql + instalar-tudo.sql:
--   psql -v ON_ERROR_STOP=1 -f supabase/teste/testes.sql
\set QUIET on
\pset format unaligned
\pset tuples_only on

create function pg_temp.ok(cond boolean, nome text) returns void language plpgsql as $$
begin
  if not coalesce(cond, false) then raise exception 'FALHOU: %', nome; end if;
  raise notice 'ok: %', nome;
end $$;

select pg_temp.ok((select count(*) from produtos) = 27, '27 produtos carregados');
select pg_temp.ok((select count(*) from variantes) = 103, '103 variantes carregadas');
select pg_temp.ok((select count(*) from produto_fotos) = 27, '27 fotos carregadas');

-- Visitante (anon): vê catálogo, não vê pedidos, não chama criar_pedido
set role anon;
select pg_temp.ok((select count(*) from produtos) = 27, 'visitante lê o catálogo');
select pg_temp.ok((select count(*) from pedidos) = 0, 'visitante não vê pedidos');
do $$ begin
  begin
    insert into produtos (slug, nome, categoria_id, preco) values ('x', 'x', 1, 1);
    raise exception 'FALHOU: visitante conseguiu criar produto';
  exception when insufficient_privilege then raise notice 'ok: visitante não cria produto';
  end;
  begin
    perform criar_pedido('{}', '{}', '[]', 'site', '{}');
    raise exception 'FALHOU: visitante chamou criar_pedido';
  exception when insufficient_privilege then raise notice 'ok: visitante não chama criar_pedido';
  end;
  begin
    update variantes set estoque = 99;
    if (select max(estoque) from variantes) = 99 then raise exception 'FALHOU: visitante mudou estoque'; end if;
    raise notice 'ok: visitante não muda estoque';
  end;
end $$;
reset role;

-- Produto inativo some para o visitante
update produtos set ativo = false where slug = 'tshirt-tie-dye';
set role anon;
select pg_temp.ok((select count(*) from produtos) = 26, 'produto inativo some do site');
reset role;
update produtos set ativo = true where slug = 'tshirt-tie-dye';

-- Servidor (service_role): cria pedido com preço do banco
set role service_role;
create temp table t_pedido as
select * from criar_pedido(
  '{"nome":"Maria Teste","telefone":"21999990000","email":"maria@exemplo.com"}',
  '{"cep":"20000-000","rua":"Rua A","numero":"10","bairro":"Centro","cidade":"Rio de Janeiro","uf":"rj"}',
  (select jsonb_agg(jsonb_build_object('variante_id', v.id, 'quantidade', 1, 'preco', 0.01))
     from variantes v join produtos p on p.id = v.produto_id
    where p.slug in ('saia-longa-azul', 'blusa-rosa-gola-renda') and v.tamanho = 'M'),
  'site', '{"valor": 21.50, "servico": "PAC", "prazo": 6}');
select pg_temp.ok((select subtotal from t_pedido) = 144.80, 'subtotal usa o preço do banco (79,90 + 64,90)');
select pg_temp.ok((select total from t_pedido) = 166.30, 'total = subtotal + frete');
select pg_temp.ok((select numero from t_pedido) = 1001, 'primeiro pedido é o nº 1001');
select pg_temp.ok((select uf from pedidos where id = (select pedido_id from t_pedido)) = 'RJ', 'UF em maiúsculas');

-- Sem estoque: quantidade maior que o estoque é recusada e nada fica gravado
do $$ begin
  perform criar_pedido('{"nome":"Ana","telefone":"21988887777"}', '{}',
    (select jsonb_agg(jsonb_build_object('variante_id', id, 'quantidade', 5)) from variantes limit 1),
    'whatsapp', '{}');
  raise exception 'FALHOU: aceitou pedido sem estoque';
exception when raise_exception then
  if sqlerrm like 'FALHOU%' then raise; end if;
  raise notice 'ok: recusa sem estoque (%)', sqlerrm;
end $$;
select pg_temp.ok((select count(*) from clientes) = 1, 'pedido recusado não deixa cliente gravado');

-- Pagamento aprovado baixa o estoque; cancelar devolve
update pedidos set status = 'pago' where id = (select pedido_id from t_pedido);
select pg_temp.ok((select sum(v.estoque) from variantes v join itens_pedido i on i.variante_id = v.id
                    where i.pedido_id = (select pedido_id from t_pedido)) = 0, 'pago baixa o estoque');
select pg_temp.ok((select pago_em is not null from pedidos where id = (select pedido_id from t_pedido)), 'pago_em preenchido');
update pedidos set status = 'cancelado' where id = (select pedido_id from t_pedido);
select pg_temp.ok((select sum(v.estoque) from variantes v join itens_pedido i on i.variante_id = v.id
                    where i.pedido_id = (select pedido_id from t_pedido)) = 2, 'cancelar pedido pago devolve o estoque');
reset role;

-- A Tati (admin logada) vê os pedidos; outra pessoa logada não
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'tati@exemplo.com'),
  ('22222222-2222-2222-2222-222222222222', 'outra@exemplo.com');
insert into admins (user_id, nome) values ('11111111-1111-1111-1111-111111111111', 'Tati');
set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
select pg_temp.ok((select count(*) from pedidos) = 0, 'usuária comum não vê pedidos');
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
select pg_temp.ok((select count(*) from pedidos) = 1, 'Tati vê os pedidos');
update produtos set preco = 84.90 where slug = 'saia-longa-azul';
select pg_temp.ok((select preco from produtos where slug = 'saia-longa-azul') = 84.90, 'Tati muda preço');
select pg_temp.ok((select preco_unitario from itens_pedido where nome_produto = 'Saia longa azul marinho') = 79.90, 'pedido antigo mantém o preço da compra');
reset role;

-- Consultas do painel rodam
select pg_temp.ok((select count(*) from (
  select p.nome, v.tamanho, v.cor, v.estoque from variantes v join produtos p on p.id = v.produto_id
  where p.ativo and v.estoque <= 2) x) = 103, 'consulta de estoque baixo');

\echo TODOS OS TESTES PASSARAM
