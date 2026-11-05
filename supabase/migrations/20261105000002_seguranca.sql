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
