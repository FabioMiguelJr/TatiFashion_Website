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
