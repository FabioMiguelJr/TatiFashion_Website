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

## Fase 3: frete (Melhor Envio)

1. Crie a conta de teste em **https://sandbox.melhorenvio.com.br** e gere um token
   (veja `Passo-a-passo-contas.md`, parte 3), marcando só estas permissões:
   - `shipping-calculate` (cotação de fretes)
   - `shipping-companies` (consulta de transportadoras)
   - `cart-read` e `cart-write` (carrinho de etiquetas)
   - `shipping-checkout` (compra da etiqueta com o saldo da carteira)
   - `shipping-generate`, `shipping-preview` e `shipping-print` (gerar, ver e imprimir a etiqueta)
   - `shipping-tracking` (rastreio)
   - `shipping-cancel` (cancelar etiqueta)
   - `orders-read` (ver as etiquetas)

   Não marque as outras. A cotação, usada agora na fase 3, só precisa de `shipping-calculate`. As demais servem para a Tati gerar e imprimir as etiquetas pelo painel, na fase 5.

   Copie o token.
2. No Supabase, abra **Edge Functions** > **Secrets** e adicione:
   - `ME_TOKEN` = o token do Melhor Envio
   - `ME_AMBIENTE` = `sandbox` (só troque para `producao` na fase 6)
3. Abra **Edge Functions** > **Deploy a new function** > **Via Editor**.
   - Nome da função: `calcular-frete` (exatamente assim)
   - Apague o código de exemplo e cole todo o conteúdo de `supabase/functions/calcular-frete/index.ts`
   - Clique em **Deploy function**
4. Na função criada, abra **Details** (ou **Settings**) e **desligue** a opção **Verify JWT** (ou "Enforce JWT
   verification"). Salve. Sem isso o site recebe erro 401, porque ele usa a Publishable key.
5. Confira se o CEP de origem já está gravado (item 8 da fase 1).
6. Teste: abra `sacola.html` com uma peça na sacola, escolha "Receber pelos Correios" e digite um CEP.
   Devem aparecer PAC e SEDEX com preço e prazo.

Peso e medidas: cada peça começa com 300 g e caixa de 30 x 20 x 5 cm. Para mudar uma peça, edite as colunas
`peso_g`, `altura_cm`, `largura_cm` e `comprimento_cm` em **Table Editor** > **produtos**.
Frete grátis a partir de um valor: `update config_loja set frete_gratis_acima = 199.90;`

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
