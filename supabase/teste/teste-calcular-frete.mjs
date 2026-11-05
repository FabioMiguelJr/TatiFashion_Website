// Testes da função calcular-frete (sem rede). Rodar:
//   cp supabase/functions/calcular-frete/index.ts /tmp/cf.mts && node --experimental-strip-types supabase/teste/teste-calcular-frete.mjs /tmp/cf.mts
process.env.SUPABASE_URL = 'https://x.supabase.co';
process.env.ME_TOKEN = 'tok';
const chamadas = [];
let configLoja = [{ cep_origem: '21000-000', frete_gratis_acima: null, retirada_ativa: true, retirada_texto: 'Retirar com a Tati' }];
let meResposta = [
  { id: 1, name: 'PAC', price: '25.40', custom_price: '23.10', delivery_time: 7, custom_delivery_time: 8, company: { name: 'Correios' } },
  { id: 2, name: 'SEDEX', price: '41.00', custom_price: '38.90', delivery_time: 2, custom_delivery_time: 3, company: { name: 'Correios' } },
];
globalThis.fetch = async (url, op = {}) => {
  chamadas.push({ url: String(url), op });
  const j = (b, s = 200) => new Response(JSON.stringify(b), { status: s });
  if (String(url).includes('/rest/v1/produtos')) return j([
    { slug: 'saia-longa-azul', preco: 79.9, peso_g: 300, altura_cm: 5, largura_cm: 20, comprimento_cm: 30 },
    { slug: 'blusa-rosa-gola-renda', preco: 64.9, peso_g: 250, altura_cm: 5, largura_cm: 20, comprimento_cm: 30 }]);
  if (String(url).includes('config_loja')) return j(configLoja);
  if (String(url).includes('melhorenvio')) return j(meResposta);
};
const { handler } = await import(process.argv[2]);
const ok = (c, m) => { console.log((c ? 'ok: ' : 'FALHOU: ') + m); if (!c) process.exitCode = 1; };
const post = (b) => handler(new Request('https://x/functions/v1/calcular-frete', { method: 'POST', headers: { apikey: 'sb_publishable_x', 'content-type': 'application/json' }, body: JSON.stringify(b) }));
const itens = [{ id: 'saia-longa-azul', qtd: 1 }, { id: 'blusa-rosa-gola-renda', qtd: 2 }];

let r = await post({ cep: '20040-020', itens }); let d = await r.json();
ok(r.status === 200, 'responde 200');
ok(d.subtotal === 209.7, 'subtotal 79,90 + 2 x 64,90 = ' + d.subtotal);
ok(d.opcoes.map((o) => o.servico).join() === 'PAC,SEDEX,Retirada', 'PAC, SEDEX e Retirada');
ok(d.opcoes[0].valor === 23.1 && d.opcoes[0].prazo === 8, 'usa preço e prazo com desconto do Melhor Envio');
const me = chamadas.find((c) => c.url.includes('melhorenvio'));
const corpo = JSON.parse(me.op.body);
ok(me.url.startsWith('https://sandbox.'), 'usa o sandbox por padrão');
ok(me.op.headers.Authorization === 'Bearer tok', 'envia o token');
ok(corpo.from.postal_code === '21000000' && corpo.to.postal_code === '20040020', 'CEPs só com dígitos');
ok(corpo.products[1].quantity === 2 && corpo.products[1].weight === 0.25, 'peso em kg e quantidade');
ok(chamadas[0].op.headers.apikey === 'sb_publishable_x', 'lê o banco com a publishable key');

configLoja[0].frete_gratis_acima = 200;
d = await (await post({ cep: '20040020', itens })).json();
ok(d.opcoes[0].valor === 0 && d.opcoes[0].nota === 'Frete grátis', 'frete grátis acima de R$ 200');
configLoja[0].frete_gratis_acima = null; configLoja[0].retirada_ativa = false;

r = await post({ cep: '123', itens }); ok(r.status === 400, 'CEP inválido recusado');
r = await post({ cep: '20040020', itens: [] }); ok(r.status === 400, 'sacola vazia recusada');
r = await post({ cep: '20040020', itens: [{ id: 'nao-existe', qtd: 1 }] }); ok(r.status === 400, 'peça desconhecida recusada');
meResposta = [{ id: 1, name: 'PAC', error: 'Serviço indisponível' }];
r = await post({ cep: '20040020', itens }); ok(r.status === 422, 'sem opções de frete: 422');
r = await handler(new Request('https://x', { method: 'OPTIONS' })); ok(r.headers.get('Access-Control-Allow-Origin') === '*', 'CORS liberado');
delete process.env.ME_TOKEN;
r = await post({ cep: '20040020', itens }); ok(r.status === 500, 'sem token: erro claro');
