const { chromium } = require('playwright');
const fs = require('fs');
const S = process.argv[2];
const prods = fs.readFileSync(S + '/mock-produtos.json', 'utf8');
const conf = fs.readFileSync(S + '/mock-config.json', 'utf8');
(async () => {
  const b = await chromium.launch();
  const ok = (c, m) => { console.log((c ? 'ok: ' : 'FALHOU: ') + m); if (!c) process.exitCode = 1; };
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
  const pg = await ctx.newPage();
  const erros = []; pg.on('pageerror', (e) => erros.push(e.message));
  let pedidoCorpo = null, criarModo = 'ok', statusMP = 'pago', conferencias = 0;
  await pg.route('**/viacep.com.br/**', (r) => r.fulfill({ contentType: 'application/json', body: JSON.stringify({ logradouro: 'Rua A', bairro: 'Centro', localidade: 'Rio de Janeiro', uf: 'RJ' }) }));
  await pg.route('**/*mercadopago.com.br/**', (r) => r.fulfill({ contentType: 'text/html', body: '<h1>Mercado Pago (simulado)</h1>' }));
  await pg.route('**/*supabase.co/**', (r) => {
    const u = r.request().url();
    if (u.includes('calcular-frete')) return r.fulfill({ contentType: 'application/json', body: JSON.stringify({ subtotal: 1, opcoes: [{ servico: 'PAC', valor: 23.1, prazo: 8 }, { servico: 'SEDEX', valor: 38.9, prazo: 3 }] }) });
    if (u.includes('criar-pedido')) {
      pedidoCorpo = JSON.parse(r.request().postData());
      if (criarModo === 'estoque') return r.fulfill({ status: 409, contentType: 'application/json', body: '{"erro":"Sem estoque: Vestido preto mullet (M / Preto)"}' });
      return r.fulfill({ contentType: 'application/json', body: JSON.stringify({ pedido_id: '9b2f1c4e-1111-4222-8333-444455556666', numero: 1001, total: 103, pagar_url: 'https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=1' }) });
    }
    if (u.includes('webhook-mercadopago')) { conferencias++; return r.fulfill({ contentType: 'application/json', body: JSON.stringify({ numero: 1001, status: statusMP === 'pago' ? 'pago' : 'aguardando_pagamento', pagamento: statusMP }) }); }
    if (u.includes('/storage/')) return r.fulfill({ status: 404, body: '' });
    return r.fulfill({ contentType: 'application/json', body: u.includes('config_loja') ? conf : prods });
  });
  await pg.goto('http://localhost:8765/produto.html?id=vestido-preto-mullet');
  ok((await pg.textContent('.parcelas')).includes('Mercado Pago'), 'produto mostra PIX/cartão pelo Mercado Pago');
  await pg.click('.opcao-btn[data-valor="M"]'); await pg.click('#comprar');
  await pg.goto('http://localhost:8765/sacola.html');
  await pg.waitForSelector('#pagar');
  await pg.fill('#nome', 'Maria Silva'); await pg.type('#cep', '20010020');
  await pg.waitForSelector('input[name=frete]'); await pg.fill('#numero', '10');
  await pg.click('#pagar');
  ok((await pg.textContent('#erro-telefone')).includes('DDD'), 'Pagar agora exige telefone');
  await pg.fill('#telefone', '(21) 98888-7777'); await pg.fill('#email', 'maria@exemplo');
  await pg.click('#pagar');
  ok((await pg.textContent('#erro-email')).includes('e-mail'), 'confere o e-mail');
  await pg.fill('#email', 'maria@exemplo.com');
  criarModo = 'estoque';
  await pg.click('#pagar');
  await pg.waitForSelector('.toast.visivel');
  ok((await pg.textContent('.toast')).includes('Sem estoque'), 'mostra erro de estoque');
  ok(!(await pg.isDisabled('#pagar')), 'botão volta a funcionar depois do erro');
  criarModo = 'ok';
  await Promise.all([pg.waitForURL('**/*mercadopago.com.br/**'), pg.click('#pagar')]);
  ok(true, 'vai para o Mercado Pago');
  ok(pedidoCorpo.canal === 'site' && pedidoCorpo.entrega === 'correios' && pedidoCorpo.frete_servico === 'PAC', 'pedido com canal, entrega e frete');
  ok(pedidoCorpo.itens[0].id === 'vestido-preto-mullet' && pedidoCorpo.itens[0].tamanho === 'M' && pedidoCorpo.endereco.cep === '20010-020', 'pedido com peça, tamanho e CEP');
  ok(pedidoCorpo.cliente.telefone === '(21) 98888-7777' && !('preco' in pedidoCorpo.itens[0]), 'telefone enviado e nenhum preço vindo do navegador');
  // volta do Mercado Pago, aprovado
  await pg.goto('http://localhost:8765/obrigado.html?pedido=9b2f1c4e-1111-4222-8333-444455556666&n=1001&r=ok');
  await pg.waitForSelector('h1:has-text("aprovado")');
  ok((await pg.textContent('main')).includes('nº 1001'), 'obrigado: pagamento aprovado com o número');
  ok(await pg.evaluate(() => JSON.parse(localStorage.getItem('tf_sacola')).length) === 0, 'sacola esvaziada depois de pagar');
  await pg.screenshot({ path: S + '/f4-obrigado.png' });
  // PIX pendente: confere algumas vezes e mostra pendente
  statusMP = 'pendente'; conferencias = 0;
  await pg.goto('http://localhost:8765/obrigado.html?pedido=9b2f1c4e-1111-4222-8333-444455556666&n=1001&r=pendente');
  await pg.waitForSelector('h1:has-text("recebido")');
  ok(conferencias === 1, 'pendente: mostra na hora, sem esperar');
  statusMP = 'recusado';
  await pg.goto('http://localhost:8765/obrigado.html?pedido=9b2f1c4e-1111-4222-8333-444455556666&n=1001&r=falha');
  await pg.waitForSelector('h1:has-text("não aprovado")');
  ok(true, 'recusado: oferece tentar de novo');
  ok(erros.length === 0, 'sem erros de JavaScript ' + erros.join(' | '));
  await b.close();
})();
