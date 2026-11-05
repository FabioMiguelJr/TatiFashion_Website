# Banco de dados da TatiFashion (Supabase)

O desenho completo (tabelas, diagrama, regras de acesso e consultas) está no documento
"TatiFashion: banco de dados".

## Arquivos

| Arquivo | O que é |
| --- | --- |
| `migrations/20261105000001_tabelas.sql` | As 10 tabelas e os índices |
| `migrations/20261105000002_seguranca.sql` | Regras de acesso (RLS) e a pasta de fotos `produtos` |
| `migrations/20261105000003_funcoes.sql` | `criar_pedido`, baixa de estoque ao pagar, cancelamento de pedidos vencidos |
| `seed.sql` | As 27 peças atuais (gerado a partir de `data/produtos.js`) |
| `instalar-tudo.sql` | Tudo acima num arquivo só, para colar no Supabase |
| `teste/` | Testes automáticos (só para rodar num PostgreSQL local) |

## Passo a passo no Supabase (fase 1)

1. Crie o projeto (veja `Passo-a-passo-contas.md`): nome `tatifashion`, região São Paulo, plano Free.
2. No menu da esquerda, abra **SQL Editor** e clique em **New query**.
3. Abra o arquivo `supabase/instalar-tudo.sql` no Bloco de Notas, copie tudo (Ctrl+A, Ctrl+C),
   cole no SQL Editor e clique em **Run**. Deve aparecer "Success. No rows returned".
4. Abra **Storage**, entre na pasta **produtos** e arraste para lá todas as fotos de `img/produtos/`.
5. Abra **Authentication** > **Users** > **Add user** > **Create new user** e cadastre o e-mail e uma senha
   da Tati (marque "Auto Confirm User"). Repita para você, se quiser entrar no painel também.
6. Volte ao **SQL Editor** e rode, trocando o e-mail:
   ```sql
   insert into admins (user_id, nome)
   select id, 'Tati' from auth.users where email = 'email-da-tati@exemplo.com';
   ```
7. Copie a **Project URL** (botão verde **Connect** no topo, ou **Project Settings** > **Data API**) e a
   **Publishable key** (`sb_publishable_...`, em **Project Settings** > **API Keys**) e mande no chat.
   A **Secret key** (`sb_secret_...`) não deve ser enviada para ninguém. As chaves "legacy" (anon e service_role) não são usadas.
8. Troque o CEP de origem (está `00000-000`):
   ```sql
   update config_loja set cep_origem = '00000-000';  -- coloque o CEP de onde os pacotes saem
   ```

## Quando mudar os produtos em `data/produtos.js`

Rode `node scripts/gerar-seed.js` para gerar de novo `seed.sql` e `instalar-tudo.sql`.
Depois que o banco estiver no ar, os produtos passam a ser editados pelo painel da Tati.

## Rodar os testes (para desenvolvedores)

Num PostgreSQL 16 vazio:

```bash
createdb tati
psql -d tati -f supabase/teste/simular-supabase.sql
psql -d tati -f supabase/instalar-tudo.sql
psql -d tati -v ON_ERROR_STOP=1 -f supabase/teste/testes.sql   # termina com "TODOS OS TESTES PASSARAM"
```
