-- TatiFashion: guarda o id da order do Mercado Pago (API de Orders) em cada pedido
alter table pedidos add column mp_order_id text unique;
alter table pedidos add column mp_status text;  -- último status visto no Mercado Pago
create index pedidos_external_idx on pedidos (numero);
