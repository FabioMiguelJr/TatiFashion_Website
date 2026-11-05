// Gera supabase/seed.sql a partir de data/produtos.js
// e junta tudo em supabase/instalar-tudo.sql (para colar no SQL Editor do Supabase).
// Uso: node scripts/gerar-seed.js
const fs = require('fs');
const path = require('path');

const raiz = path.join(__dirname, '..');
global.window = {};
require(path.join(raiz, 'data', 'produtos.js'));
const produtos = window.PRODUTOS;
const loja = window.LOJA;

const ESTOQUE_INICIAL = 1; // até a Tati contar as peças
const q = (v) => (v === undefined || v === null ? 'null' : `'${String(v).replace(/'/g, "''")}'`);
const slugify = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
  .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

const ORDEM = ['Blusas', 'Vestidos', 'Saias', 'Casacos'];
const categorias = [...new Set(produtos.map((p) => p.categoria))]
  .sort((a, b) => (ORDEM.indexOf(a) + 1 || 99) - (ORDEM.indexOf(b) + 1 || 99));
const linhas = [];
linhas.push('-- TatiFashion: carga inicial gerada por scripts/gerar-seed.js a partir de data/produtos.js');
linhas.push('-- Não edite à mão: altere data/produtos.js e rode o script de novo.', '');
linhas.push('insert into categorias (nome, slug, ordem) values');
linhas.push(categorias.map((c, i) => `  (${q(c)}, ${q(slugify(c))}, ${i + 1})`).join(',\n') + ';', '');

for (const p of produtos) {
  linhas.push(`-- ${p.nome}`);
  linhas.push(
    'insert into produtos (slug, nome, categoria_id, descricao, preco, preco_antigo, destaque, novo) values ' +
    `(${q(p.id)}, ${q(p.nome)}, (select id from categorias where slug = ${q(slugify(p.categoria))}), ` +
    `${q(p.descricao)}, ${p.preco.toFixed(2)}, ${p.precoAntigo ? p.precoAntigo.toFixed(2) : 'null'}, ` +
    `${!!p.destaque}, ${!!p.novo});`
  );
  const foto = path.basename(p.foto);
  linhas.push(`insert into produto_fotos (produto_id, caminho, ordem) values ((select id from produtos where slug = ${q(p.id)}), ${q(foto)}, 0);`);
  const vars = [];
  for (const t of p.tamanhos) for (const c of p.cores) {
    const sku = `${p.id}-${slugify(t)}-${slugify(c)}`;
    vars.push(`  ((select id from produtos where slug = ${q(p.id)}), ${q(t)}, ${q(c)}, ${ESTOQUE_INICIAL}, ${q(sku)})`);
  }
  linhas.push('insert into variantes (produto_id, tamanho, cor, estoque, sku) values\n' + vars.join(',\n') + ';', '');
}

linhas.push('-- Dados da loja. Troque o CEP de origem pelo CEP de onde os pacotes saem.');
linhas.push(`insert into config_loja (cep_origem, whatsapp, instagram) values ('00000-000', ${q(loja.whatsapp)}, ${q(loja.instagram)});`, '');

const seed = linhas.join('\n');
fs.writeFileSync(path.join(raiz, 'supabase', 'seed.sql'), seed);

const pasta = path.join(raiz, 'supabase', 'migrations');
const partes = fs.readdirSync(pasta).filter((f) => f.endsWith('.sql')).sort()
  .map((f) => `-- ===== ${f} =====\n` + fs.readFileSync(path.join(pasta, f), 'utf8'));
partes.push('-- ===== seed.sql =====\n' + seed);
fs.writeFileSync(path.join(raiz, 'supabase', 'instalar-tudo.sql'), partes.join('\n\n'));

const nVar = produtos.reduce((s, p) => s + p.tamanhos.length * p.cores.length, 0);
console.log(`${categorias.length} categorias, ${produtos.length} produtos, ${nVar} variantes`);
