const { chromium } = require('playwright');
const fs = require('fs');
const S = process.argv[2];
const prods = fs.readFileSync(S + '/mock-produtos.json', 'utf8');
const conf = fs.readFileSync(S + '/mock-config.json', 'utf8');
(async () => {
  const b = await chromium.launch();
  const ok = (c, m) => { console.log((c ? 'ok: ' : 'FALHOU: ') + m); if (!c) process.exitCode = 1; };
  async function pagina(modo) {
    const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
    const pg = await ctx.newPage();
    const erros = []; pg.on('pageerror', (e) => erros.push(e.message));
    let chave = null;
    await pg.route('**/*supabase.co/**', (r) => {
      const u = r.request().url();
      if (modo === 'fora') return r.abort();
      if (u.includes('/storage/')) return r.fulfill({ status: 404, body: '' });
      chave = r.request().headers()['apikey'];
      return r.fulfill({ status: 200, contentType: 'application/json', body: u.includes('config_loja') ? conf : prods });
    });
    return { ctx, pg, erros, chaveUsada: () => chave };
  }
  // 1. banco respondendo
  let { ctx, pg, erros, chaveUsada } = await pagina('ok');
  await pg.goto('http://localhost:8765/catalogo.html');
  await pg.waitForSelector('.card');
  ok(await pg.evaluate(() => document.documentElement.dataset.fonte) === 'banco', 'catálogo lido do banco');
  ok(chaveUsada() && chaveUsada().startsWith('sb_publishable_'), 'envia a publishable key');
  ok(await pg.locator('.card').count() === 27, '27 peças no catálogo');
  ok(await pg.locator('.selo.esgotado').count() === 1, 'jaqueta aparece esgotada');
  await pg.waitForTimeout(800);
  const quebradas = await pg.evaluate(() => [...document.images].filter((i) => i.complete && i.naturalWidth === 0).length);
  ok(quebradas === 0, 'fotos sem o Storage usam a cópia local (' + quebradas + ' quebradas)');
  const chips = await pg.locator('.chip').allTextContents();
  ok(chips.join(',') === 'Todos,Blusas,Vestidos,Saias,Casacos', 'categorias na ordem do banco: ' + chips.join(','));
  await pg.goto('http://localhost:8765/produto.html?id=jaqueta-matelasse-preta');
  ok(await pg.locator('#comprar').isDisabled(), 'botão desativado na peça esgotada');
  await pg.goto('http://localhost:8765/produto.html?id=saia-longa-azul');
  await pg.waitForSelector('.opcao-btn');
  ok(await pg.locator('.opcao-btn.esgotado').allTextContents().then((t) => t.join()) === 'P', 'tamanho P da saia riscado');
  await pg.click('.opcao-btn[data-valor="P"]');
  ok((await pg.textContent('#aviso')).includes('esgotada'), 'aviso de combinação esgotada');
  await pg.click('.opcao-btn[data-valor="M"]');
  ok((await pg.textContent('#aviso')).includes('Últimas'), 'aviso de últimas peças');
  await pg.click('#comprar'); await pg.click('#comprar');
  ok((await pg.textContent('#aviso')).includes('todas as peças disponíveis'), 'não deixa passar do estoque');
  await pg.goto('http://localhost:8765/sacola.html');
  ok(await pg.locator('text=Saia longa azul marinho').count() > 0, 'sacola mostra a peça');
  await pg.screenshot({ path: S + '/f2-sacola.png' });
  ok(erros.length === 0, 'sem erros de JavaScript ' + erros.join(' | '));
  await ctx.close();
  // 2. banco fora do ar
  ({ ctx, pg, erros } = await pagina('fora'));
  await pg.goto('http://localhost:8765/index.html');
  await pg.waitForSelector('.card');
  ok(await pg.evaluate(() => document.documentElement.dataset.fonte) === 'arquivo', 'banco fora: usa data/produtos.js');
  ok(await pg.locator('#destaques .card').count() > 0, 'banco fora: destaques aparecem');
  ok(erros.length === 0, 'sem erros de JavaScript (banco fora) ' + erros.join(' | '));
  await ctx.close();
  await b.close();
})();
