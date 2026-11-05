// Testes de criar-pedido e webhook-mercadopago (sem rede, tudo simulado). Rodar:
//   cp supabase/functions/criar-pedido/index.ts /tmp/cp.mts
//   cp supabase/functions/webhook-mercadopago/index.ts /tmp/wh.mts
//   node --experimental-strip-types supabase/teste/teste-pagamento.mjs /tmp/cp.mts /tmp/wh.mts
process.env.SUPABASE_URL = 'https://x.supabase.co';
process.env.TF_SECRET_KEY = 'sb_secret_x';
process.env.MP_ACCESS_TOKEN = 'APP_USR-x';
process.env.SITE_URL = 'https://loja.exemplo/';
const ok = (c, m) => { console.log((c ? 'ok: ' : 'FALHOU: ') + m); if (!c) process.exitCode = 1; };
const log = [];
const db = { pedidos: [], pagamentos: [] };
let mpCreate = 'ok', mpOrder = null, freteOk = true;
const j = (b, s = 200) => new Response(b === undefined ? null : JSON.stringify(b), { status: s });
globalThis.fetch = async (url, op = {}) => {
  url = String(url); const corpo = op.body ? JSON.parse(op.body) : null; log.push({ url, op, corpo });
  if (url.includes('/rest/v1/variantes')) return j([
    { id: 11, tamanho: 'M', cor: 'Azul marinho', produtos: { slug: 'saia-longa-azul', nome: 'Saia longa azul marinho', preco: 79.9 } },
    { id: 12, tamanho: 'M', cor: 'Rosa', produtos: { slug: 'blusa-rosa-gola-renda', nome: 'Blusa rosa', preco: 64.9 } }]);
  if (url.includes('/functions/v1/calcular-frete')) return freteOk ? j({ subtotal: 1, opcoes: [{ servico: 'PAC', valor: 21.5, prazo: 6 }, { servico: 'SEDEX', valor: 39, prazo: 2 }] }) : j({ erro: 'x' }, 502);
  if (url.includes('/rpc/criar_pedido')) {
    if (corpo.p_itens[0].quantidade > 5) return j({ message: 'Sem estoque: Saia (M / Azul)' }, 400);
    const sub = corpo.p_itens.reduce((s, i) => s + (i.variante_id === 11 ? 79.9 : 64.9) * i.quantidade, 0);
    const p = { id: '9b2f1c4e-1111-4222-8333-' + String(444455556666 + db.pedidos.length), numero: 1001 + db.pedidos.length, status: 'aguardando_pagamento', mp_order_id: null, canal: corpo.p_canal };
    db.pedidos.push(p);
    return j([{ pedido_id: p.id, numero: p.numero, subtotal: sub, total: Math.round((sub + Number(corpo.p_frete.valor)) * 100) / 100 }]);
  }
  if (url.includes('/rest/v1/pedidos')) {
    const id = (url.match(/id=eq\.([^&]+)/) || [])[1], mp = (url.match(/mp_order_id=eq\.([^&]+)/) || [])[1], num = (url.match(/numero=eq\.(\d+)/) || [])[1];
    const achados = db.pedidos.filter((p) => (id && p.id === id) || (mp && p.mp_order_id === decodeURIComponent(mp)) || (num && p.numero === Number(num)));
    if (op.method === 'PATCH') { achados.forEach((p) => Object.assign(p, corpo)); return j(undefined, 204); }
    return j(achados.map((p) => ({ ...p })));
  }
  if (url.includes('/rest/v1/pagamentos')) { db.pagamentos = db.pagamentos.filter((x) => x.provedor_id !== corpo.provedor_id); db.pagamentos.push(corpo); return j(undefined, 201); }
  if (url.endsWith('api.mercadopago.com/v1/orders')) {
    if (mpCreate === 'erro') return j({ errors: [{ code: 'internal_error' }] }, 500);
    if (mpCreate === 'sem-processing' && corpo.processing_mode) return j({ errors: [{ code: 'unsupported_properties' }] }, 400);
    return j({ id: 'ORDTST01', status: 'created', checkout_url: 'https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=1' }, 201);
  }
  if (url.includes('api.mercadopago.com/v1/orders/')) return mpOrder ? j(mpOrder) : j({}, 404);
  throw new Error('fetch inesperado ' + url);
};
const { handler: criar } = await import(process.argv[2]);
const { handler: webhook, situacao } = await import(process.argv[3]);
const req = (b, h = {}) => new Request('https://x/f', { method: 'POST', headers: { apikey: 'sb_publishable_x', 'content-type': 'application/json', ...h }, body: JSON.stringify(b) });
const base = {
  canal: 'site', entrega: 'correios', frete_servico: 'PAC',
  cliente: { nome: 'Maria da Silva', telefone: '(21) 99999-0000', email: 'maria@exemplo.com', cpf: '123.456.789-09' },
  endereco: { cep: '20010-020', rua: 'Rua A', numero: '10', bairro: 'Centro', cidade: 'Rio de Janeiro', uf: 'RJ' },
  itens: [{ id: 'saia-longa-azul', tamanho: 'M', cor: 'Azul marinho', qtd: 1 }, { id: 'blusa-rosa-gola-renda', tamanho: 'M', cor: 'Rosa', qtd: 2 }],
};

let r = await criar(req(base)); let d = await r.json();
ok(r.status === 200 && d.pagar_url.includes('mercadopago'), 'site: devolve o link de pagamento');
ok(d.total === 231.2 && d.frete === 21.5, 'total = 79,90 + 2 x 64,90 + frete 21,50 = ' + d.total);
const rpc = log.find((l) => l.url.includes('criar_pedido'));
ok(rpc.op.headers.apikey === 'sb_secret_x' && !rpc.op.headers.Authorization, 'grava com a Secret key nova (sem Bearer)');
ok(rpc.corpo.p_frete.valor === 21.5 && rpc.corpo.p_itens[1].variante_id === 12, 'frete e variantes resolvidos no servidor');
const mp = log.find((l) => l.url.endsWith('/v1/orders'));
ok(mp.op.headers['X-Idempotency-Key'].startsWith(d.pedido_id), 'X-Idempotency-Key = id do pedido');
ok(mp.corpo.total_amount === '231.20' && mp.corpo.items.reduce((s, i) => s + Number(i.unit_price) * i.quantity, 0).toFixed(2) === '231.20', 'itens somam o total (com frete)');
ok(mp.corpo.payer.identification.number === '12345678909', 'CPF só com dígitos');
ok(mp.corpo.config.online.success_url.startsWith('https://loja.exemplo/obrigado.html?pedido='), 'volta para obrigado.html');
ok(mp.corpo.notification_url === 'https://x.supabase.co/functions/v1/webhook-mercadopago', 'notification_url aponta para o webhook');
ok(db.pedidos[0].mp_order_id === 'ORDTST01', 'guarda o id da order');

log.length = 0; mpCreate = 'sem-processing';
r = await criar(req(base)); d = await r.json();
ok(r.status === 200 && log.filter((l) => l.url.endsWith('/v1/orders')).length === 2, 'tenta outro formato se o Mercado Pago recusar o corpo');
mpCreate = 'erro';
r = await criar(req(base)); d = await r.json();
ok(r.status === 502 && db.pedidos.at(-1).status === 'cancelado', 'falha no Mercado Pago: pedido cancelado e erro claro');
mpCreate = 'ok';

r = await criar(req({ ...base, itens: [{ ...base.itens[0], qtd: 9 }] })); d = await r.json();
ok(r.status === 409 && d.erro.includes('estoque'), 'sem estoque: 409 com a mensagem');
r = await criar(req({ ...base, itens: [{ ...base.itens[0], cor: 'Verde' }] })); ok(r.status === 409, 'cor que não existe: 409');
r = await criar(req({ ...base, cliente: { nome: 'Ana', telefone: '123' } })); ok(r.status === 400, 'site exige telefone');
freteOk = false;
r = await criar(req(base)); ok(r.status === 502, 'site: frete não confirmado = não cobra');
log.length = 0;
r = await criar(req({ ...base, canal: 'whatsapp', cliente: { nome: 'Ana' } })); d = await r.json();
ok(r.status === 200 && d.numero && !d.pagar_url && !log.some((l) => l.url.includes('mercadopago')), 'whatsapp: grava sem Mercado Pago, frete a combinar');
freteOk = true;
log.length = 0;
r = await criar(req({ ...base, entrega: 'retirada', endereco: {} })); d = await r.json();
ok(r.status === 200 && d.frete === 0 && !log.some((l) => l.url.includes('calcular-frete')), 'retirada: sem frete e sem endereço');

// webhook
ok(situacao({ status: 'processed' }) === 'pago', 'order processed = pago');
ok(situacao({ status: 'created', transactions: { payments: [{ status: 'processed', status_detail: 'accredited' }] } }) === 'pago', 'pagamento accredited = pago');
ok(situacao({ status: 'created', transactions: { payments: [{ status: 'action_required' }] } }) === 'pendente', 'PIX aguardando = pendente');
ok(situacao({ status: 'created', transactions: { payments: [{ status: 'failed' }] } }) === 'recusado', 'cartão recusado = recusado');

const p0 = db.pedidos[0];
mpOrder = { id: 'ORDTST01', status: 'created', external_reference: String(p0.numero), total_amount: '231.20', transactions: { payments: [{ id: 'PAY01', status: 'action_required', amount: '231.20', payment_method: { id: 'pix', type: 'bank_transfer' } }] } };
r = await webhook(req({ type: 'order', action: 'order.action_required', data: { id: 'ORDTST01' } })); d = await r.json();
ok(d.pagamento === 'pendente' && p0.status === 'aguardando_pagamento' && db.pagamentos[0].metodo === 'bank_transfer', 'aviso de PIX pendente registrado');
mpOrder.status = 'processed'; mpOrder.transactions.payments[0].status = 'processed'; mpOrder.transactions.payments[0].status_detail = 'accredited';
r = await webhook(req({ type: 'order', data: { id: 'ORDTST01' } })); d = await r.json();
ok(p0.status === 'pago' && db.pagamentos.length === 1 && db.pagamentos[0].status === 'processed/accredited', 'aviso de pagamento aprovado: pedido pago, sem duplicar');
r = await webhook(new Request('https://x/f?data.id=ORDTST01&type=order', { method: 'POST', body: '{}' })); ok(r.status === 200, 'aceita id pela URL');
r = await webhook(req({ pedido_id: p0.id })); d = await r.json();
ok(d.status === 'pago' && d.numero === p0.numero, 'obrigado.html confere o pagamento');
r = await webhook(req({ pedido_id: 'nao-e-uuid' })); ok(r.status === 400, 'pedido_id inválido recusado');
// aviso antes de gravar o mp_order_id
const p1 = db.pedidos[1]; p1.mp_order_id = null;
mpOrder = { id: 'ORDTST02', status: 'processed', external_reference: String(p1.numero) };
r = await webhook(req({ data: { id: 'ORDTST02' } })); d = await r.json();
ok(p1.mp_order_id === 'ORDTST02' && p1.status === 'pago', 'acha o pedido pelo número quando o aviso chega antes');
mpOrder = null;
r = await webhook(req({ data: { id: 'FALSO' } })); d = await r.json(); ok(r.status === 200 && d.ignorado, 'aviso falso é ignorado (order não existe no Mercado Pago)');
