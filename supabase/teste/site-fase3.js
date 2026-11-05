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
  let freteModo = 'ok', pedidosFrete = [];
  await pg.route('**/viacep.com.br/**', (r) => r.fulfill({ contentType: 'application/json', body: r.request().url().includes('99999999') ? '{"erro": true}' : JSON.stringify({ logradouro: 'Rua da Assembleia', bairro: 'Centro', localidade: 'Rio de Janeiro', uf: 'RJ' }) }));
  await pg.route('**/*supabase.co/**', (r) => {
    const u = r.request().url();
    if (u.includes('/functions/v1/calcular-frete')) {
      pedidosFrete.push(JSON.parse(r.request().postData()));
      if (freteModo === 'erro') return r.fulfill({ status: 404, body: '{"erro":"nao existe"}' });
      return r.fulfill({ contentType: 'application/json', body: JSON.stringify({ subtotal: 79.9, opcoes: [{ servico: 'PAC', valor: 23.1, prazo: 8 }, { servico: 'SEDEX', valor: 38.9, prazo: 3 }, { servico: 'Retirada', valor: 0, prazo: null }] }) });
    }
    if (u.includes('/storage/')) return r.fulfill({ status: 404, body: '' });
    return r.fulfill({ contentType: 'application/json', body: u.includes('config_loja') ? conf : prods });
  });
  let aberto = null;
  await ctx.exposeFunction('__abriu', (u) => { aberto = u; });
  await pg.addInitScript(() => { window.open = (u) => { if (u) window.__abriu(u); return { closed: false, location: { set href(x) { window.__abriu(x); } } }; }; });
  await pg.goto('http://localhost:8765/produto.html?id=vestido-preto-mullet');
  await pg.click('.opcao-btn[data-valor="M"]'); await pg.click('#comprar');
  await pg.goto('http://localhost:8765/sacola.html');
  await pg.waitForSelector('#cep');
  ok(await pg.isChecked('input[value="Receber pelos Correios"]'), 'Correios vem marcado');
  await pg.fill('#nome', 'Maria');
  await pg.type('#cep', '20010020');
  ok(await pg.inputValue('#cep') === '20010-020', 'máscara do CEP');
  await pg.waitForSelector('input[name=frete]');
  ok(await pg.inputValue('#rua') === 'Rua da Assembleia' && await pg.inputValue('#uf') === 'RJ', 'endereço preenchido pelo ViaCEP');
  ok(await pg.locator('input[name=frete]').count() === 2, 'mostra PAC e SEDEX (retirada fica nas opções de cima)');
  ok(pedidosFrete[0].cep === '20010020' && pedidosFrete[0].itens[0].id === 'vestido-preto-mullet', 'envia CEP e peças para calcular-frete');
  ok((await pg.textContent('#resumo')).includes('103,00'), 'PAC: total 79,90 + 23,10 = 103,00');
  await pg.check('input[name=frete][value=SEDEX]');
  ok((await pg.textContent('#resumo')).includes('118,80'), 'SEDEX: total 79,90 + 38,90 = 118,80');
  await pg.click('button[data-canal=whatsapp]');
  ok((await pg.textContent('#erro-numero')).includes('número'), 'pede o número');
  await pg.fill('#numero', '10');
  await pg.click('button[data-canal=whatsapp]');
  for (let i = 0; i < 50 && !aberto; i++) await pg.waitForTimeout(100);
  const msg = decodeURIComponent((aberto || '').split('text=')[1] || '').replace(/\u00a0/g, ' ');
  ok(msg.includes('*Frete:* SEDEX (3 dias úteis): R$ 38,90') && msg.includes('*Total: R$ 118,80*') && msg.includes('Rua da Assembleia, 10') && msg.includes('CEP 20010-020'), 'mensagem do WhatsApp com frete e endereço'); if (!msg.includes('Total')) console.log(msg); else console.log(msg.split('\n').slice(-8).join('\n'));
  await pg.screenshot({ path: S + '/f3-sacola.png', fullPage: true });
  // retirada
  await pg.click('#manter').catch(() => {});
  await pg.check('input[value="Retirar com a Tati"]');
  ok(await pg.locator('#cep').count() === 0 && await pg.locator('#local').count() === 1, 'retirada esconde o endereço');
  ok(!(await pg.textContent('#resumo')).includes('Frete'), 'retirada sem linha de frete');
  // função fora do ar
  freteModo = 'erro';
  await pg.evaluate(() => localStorage.removeItem('tf_comprador'));
  await pg.reload(); await pg.waitForSelector('#cep');
  await pg.fill('#nome', 'Ana'); await pg.type('#cep', '20010021');
  await pg.waitForSelector('#frete .nota:has-text("Não conseguimos")');
  ok(true, 'função fora do ar: aviso e frete a combinar');
  await pg.fill('#numero', '5'); aberto = null;
  await pg.click('button[data-canal=whatsapp]');
  for (let i = 0; i < 50 && !aberto; i++) await pg.waitForTimeout(100);
  ok(decodeURIComponent(aberto || '').includes('*Frete:* a combinar'), 'mensagem diz frete a combinar');
  // CEP inexistente
  await pg.click('#manter').catch(() => {});
  await pg.fill('#cep', ''); await pg.type('#cep', '99999999');
  await pg.waitForSelector('#frete .nota:has-text("CEP não encontrado")');
  ok(true, 'CEP inexistente avisado');
  ok(erros.length === 0, 'sem erros de JavaScript ' + erros.join(' | '));
  await b.close();
})();
