# Banco de dados da TatiFashion (Supabase)

O desenho completo (tabelas, diagrama, regras de acesso e consultas) está no documento
"TatiFashion: banco de dados".

## Arquivos

| Arquivo | O que é |
| --- | --- |
| `migrations/20261105000001_tabelas.sql` | As 10 tabelas e os índices |
| `migrations/20261105000002_seguranca.sql` | Regras de acesso (RLS) e a pasta de fotos `produtos` |
| `migrations/20261105000003_funcoes.sql` | `criar_pedido`, baixa de estoque ao pagar, cancelamento de pedidos vencidos |
| `migrations/20261105000004_mercadopago_orders.sql` | Colunas do Mercado Pago (API de Orders) no pedido |
| `functions/` | Funções de servidor: `calcular-frete`, `criar-pedido`, `webhook-mercadopago` |
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
3. Crie a função:
   1. No Supabase, abra **Edge Functions** > **Functions** > **Deploy a new function** > **Via Editor**.
      Abre a tela "Create new edge function", com um arquivo `index.ts` de exemplo.
   2. No seu computador, abra `TatyFashion\calcular-frete.txt` no Bloco de Notas (é o mesmo código de
      `TatiFashionWeb\supabase\functions\calcular-frete\index.ts`; o `.ts` o Windows pode tentar abrir como vídeo).
      Copie tudo com Ctrl+A e Ctrl+C.
   3. Volte ao Supabase, clique dentro do código de exemplo, apague tudo com Ctrl+A e Delete e cole com Ctrl+V.
   4. Embaixo, em **Function name**, troque o nome sugerido (ex.: `smooth-action`) por `calcular-frete`.
   5. Clique em **Deploy function** e espere aparecer que a função foi publicada.
4. Desligue a verificação de JWT: na página da função `calcular-frete`, abra **Details** e desligue
   **Verify JWT with legacy secret** (ou "Enforce JWT verification"). Clique em **Save changes**.
   Sem isso o site recebe erro 401, porque ele usa a Publishable key.
5. Confira se o CEP de origem já está gravado (item 8 da fase 1).
6. Teste: abra `sacola.html` com uma peça na sacola, escolha "Receber pelos Correios" e digite um CEP.
   Devem aparecer PAC e SEDEX com preço e prazo.

Peso e medidas: cada peça começa com 300 g e caixa de 30 x 20 x 5 cm. Para mudar uma peça, edite as colunas
`peso_g`, `altura_cm`, `largura_cm` e `comprimento_cm` em **Table Editor** > **produtos**.
Frete grátis a partir de um valor: `update config_loja set frete_gratis_acima = 199.90;`

## Fase 4: pagamento (Mercado Pago, API de Orders)

O site cria o pedido no banco e manda a cliente para a página segura do Mercado Pago (PIX, cartão em até 6x
ou boleto). Quando o pagamento é aprovado, o Mercado Pago avisa a função `webhook-mercadopago`, o pedido vira
"pago" e o estoque baixa sozinho. O botão do WhatsApp continua funcionando, e agora também grava o pedido.

1. **Banco:** no SQL Editor, rode o arquivo `TatyFashion\fase4-banco.sql`
   (é o `supabase/migrations/20261105000004_mercadopago_orders.sql`). Não rode o `instalar-tudo.sql` de novo.
2. **Contas de teste do Mercado Pago:** na sua aplicação em **Suas integrações**, abra **Contas de teste** e crie
   uma conta **Vendedor** e uma **Comprador**, as duas do Brasil. Anote o usuário e a senha de cada uma.
3. **Access Token de teste:** a API de Orders não aceita as "credenciais de teste". O jeito certo de testar é
   usar as **credenciais de produção da conta Vendedor de teste**:
   1. Abra uma janela anônima (Ctrl+Shift+N), entre em **https://www.mercadopago.com.br** com o usuário e a
      senha da conta **Vendedor** de teste. Aparece a tela inicial da conta "Test", com saldo de R$ 1.000.
   2. Nessa mesma janela, digite na barra de endereço **https://www.mercadopago.com.br/developers/panel/app**
      e aperte Enter. Abre o painel **Suas integrações** da conta de teste.
   3. Clique em **Criar aplicação**: solução **Checkout Pro**, tipo de API **API de Orders**,
      nome `TatiFashion Teste`, marque a autorização e clique em **Criar aplicação**.
   4. Dentro da aplicação, no menu da esquerda, clique em **Credenciais de produção**. Se pedir para ativar,
      preencha o ramo (**Vestuário** ou parecido) e o site `https://fabiomigueljr.github.io/TatiFashion_Website/`.
   5. Copie o **Access Token** (começa com `APP_USR-`). Não mande no chat.
4. **Segredos no Supabase** (Edge Functions > Secrets):
   - `TF_SECRET_KEY` = a **Secret key** do Supabase (`sb_secret_...`, em Project Settings > API Keys)
   - `MP_ACCESS_TOKEN` = o Access Token do passo 3
   - `SITE_URL` = `https://fabiomigueljr.github.io/TatiFashion_Website/`
5. **Publicar as duas funções**, do mesmo jeito que a `calcular-frete`:
   - `criar-pedido`: cole o conteúdo de `TatyFashion\criar-pedido.txt`
   - `webhook-mercadopago`: cole o conteúdo de `TatyFashion\webhook-mercadopago.txt`
   - Nas duas, desligue **Verify JWT with legacy secret** em Details e salve.
6. **Testar uma compra:**
   1. Abra `TatiFashionWeb\sacola.html` com uma peça, preencha nome, telefone e endereço e toque em **Pagar agora**.
   2. Na página do Mercado Pago, entre com a conta **Comprador** de teste (ou pague como visitante) e use o cartão
      de teste Mastercard `5480 8328 0103 3311`, código `123`, validade `11/30`, nome do titular `APRO`
      e CPF `12345678909`. O nome `OTHE` simula um cartão recusado.
   3. No Supabase, abra **Table Editor** > **pedidos**: o pedido deve estar com status `pago`, e em
      **pagamentos** deve aparecer o pagamento.
   4. Enquanto o branch não estiver publicado (fase 6), a volta do Mercado Pago cai numa página "404" do site,
      porque a página `obrigado.html` ainda não existe no site publicado. Isso é esperado e o pagamento vale mesmo assim.

Quando der algum erro, abra **Edge Functions** > a função > **Logs** e me mande um print.

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
