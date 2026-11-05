/* TatiFashion — código compartilhado por todas as páginas */
(function () {
  const PRODUTOS = (window.PRODUTOS || []).slice();
  const LOJA = window.LOJA || { nome: "TatiFashion Modas" };
  const SUPA = window.SUPABASE || {};
  const ORDEM_CAT = {};

  const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const reais = (v) => Number(v).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  const categorias = () => [...new Set(PRODUTOS.map((p) => p.categoria))]
    .sort((a, b) => (ORDEM_CAT[a] ?? 99) - (ORDEM_CAT[b] ?? 99));

  /* ---------- Catálogo: lê do banco (Supabase) e, se falhar, usa o data/produtos.js ---------- */
  const CACHE = "tf_catalogo_v1", CACHE_MIN = 5;
  const fotoBanco = (caminho) => SUPA.url + "/storage/v1/object/public/produtos/" + encodeURIComponent(caminho);
  function converter(r) {
    const fotos = (r.produto_fotos || []).slice().sort((a, b) => a.ordem - b.ordem);
    const variantes = (r.variantes || []).slice().sort((a, b) => a.id - b.id);
    ORDEM_CAT[r.categorias.nome] = r.categorias.ordem;
    return {
      id: r.slug,
      nome: r.nome,
      categoria: r.categorias.nome,
      preco: Number(r.preco),
      precoAntigo: r.preco_antigo ? Number(r.preco_antigo) : undefined,
      descricao: r.descricao || "",
      destaque: r.destaque,
      novo: r.novo,
      foto: fotos.length ? fotoBanco(fotos[0].caminho) : "img/flor.svg",
      fotoReserva: fotos.length ? "img/produtos/" + fotos[0].caminho : "",
      fotos: fotos.map((f) => fotoBanco(f.caminho)),
      variantes,
      tamanhos: [...new Set(variantes.map((v) => v.tamanho))],
      cores: [...new Set(variantes.map((v) => v.cor))],
      esgotado: variantes.length > 0 && variantes.every((v) => v.estoque <= 0)
    };
  }
  async function buscar(caminho) {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 6000);
    try {
      const r = await fetch(SUPA.url + "/rest/v1/" + caminho, { headers: { apikey: SUPA.chave }, signal: ctrl.signal });
      if (!r.ok) throw new Error("Banco respondeu " + r.status);
      return await r.json();
    } finally { clearTimeout(t); }
  }
  async function carregarCatalogo() {
    if (!SUPA.url || !SUPA.chave) return "arquivo";
    let dados = null;
    try {
      const c = JSON.parse(sessionStorage.getItem(CACHE));
      if (c && Date.now() - c.em < CACHE_MIN * 60000) dados = c.dados;
    } catch {}
    try {
      if (!dados) {
        const [produtos, config] = await Promise.all([
          buscar("produtos?select=slug,nome,descricao,preco,preco_antigo,destaque,novo," +
                 "categorias(nome,ordem),produto_fotos(caminho,ordem),variantes(id,tamanho,cor,estoque)" +
                 "&ativo=eq.true&order=nome.asc"),
          buscar("config_loja?select=whatsapp,instagram,frete_gratis_acima,retirada_ativa,retirada_texto")
        ]);
        dados = { produtos, config: config[0] || null };
        try { sessionStorage.setItem(CACHE, JSON.stringify({ em: Date.now(), dados })); } catch {}
      }
      if (!dados.produtos.length) throw new Error("Banco sem produtos");
      PRODUTOS.splice(0, PRODUTOS.length, ...dados.produtos.map(converter));
      if (dados.config) {
        if (dados.config.whatsapp) LOJA.whatsapp = dados.config.whatsapp;
        if (dados.config.instagram) LOJA.instagram = dados.config.instagram;
        LOJA.config = dados.config;
      }
      return "banco";
    } catch (e) {
      console.warn("TatiFashion: usando data/produtos.js porque o banco não respondeu.", e);
      return "arquivo";
    }
  }
  const carregando = carregarCatalogo().then((f) => { TF.fonte = f; document.documentElement.dataset.fonte = f; });
  const domPronto = new Promise((ok) => document.readyState === "loading" ? document.addEventListener("DOMContentLoaded", ok) : ok());
  const fila = [];
  let liberado = false;
  Promise.all([carregando, domPronto]).then(() => { liberado = true; fila.splice(0).forEach((fn) => fn()); });
  /* Use TF.pronto(() => { ... }) nas páginas: roda quando a página e o catálogo estiverem prontos. */
  const pronto = (fn) => (liberado ? fn() : fila.push(fn));
  /* Estoque de uma combinação (Infinity quando o catálogo veio do arquivo e não tem estoque). */
  const estoque = (p, tamanho, cor) => {
    if (!p.variantes) return Infinity;
    const v = p.variantes.find((x) => x.tamanho === tamanho && x.cor === cor);
    return v ? v.estoque : 0;
  };
  /* Foto do banco que não carregou: troca pela cópia em img/produtos */
  document.addEventListener("error", (e) => {
    const img = e.target;
    if (img.tagName === "IMG" && img.dataset.reserva && img.getAttribute("src") !== img.dataset.reserva) img.src = img.dataset.reserva;
  }, true);

  /* ---------- Sacola (fica salva no navegador do cliente) ---------- */
  const CHAVE = "tf_sacola";
  const lerJSON = (k, padrao) => { try { return JSON.parse(localStorage.getItem(k)) ?? padrao; } catch { return padrao; } };
  const gravarJSON = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} };
  const Sacola = {
    itens() {
      // descarta itens de produtos que saíram do catálogo
      return lerJSON(CHAVE, []).filter((i) => PRODUTOS.some((p) => p.id === i.id));
    },
    salvar(itens) { gravarJSON(CHAVE, itens); atualizarContador(); },
    adicionar(id, tamanho, cor, qtd = 1) {
      const itens = Sacola.itens();
      const existente = itens.find((i) => i.id === id && i.tamanho === tamanho && i.cor === cor);
      if (existente) existente.qtd = Math.min(existente.qtd + qtd, 20);
      else itens.push({ id, tamanho, cor, qtd });
      Sacola.salvar(itens);
    },
    alterar(indice, qtd) {
      const itens = Sacola.itens();
      if (!itens[indice]) return;
      if (qtd <= 0) itens.splice(indice, 1); else itens[indice].qtd = Math.min(qtd, 20);
      Sacola.salvar(itens);
    },
    limpar() { Sacola.salvar([]); },
    produto: (id) => PRODUTOS.find((p) => p.id === id),
    quantidade() { return Sacola.itens().reduce((s, i) => s + i.qtd, 0); },
    total() { return Sacola.itens().reduce((s, i) => s + i.qtd * Sacola.produto(i.id).preco, 0); }
  };
  function atualizarContador() {
    const el = document.getElementById("contador-sacola");
    if (!el) return;
    const n = Sacola.quantidade();
    el.textContent = n > 9 ? "9+" : String(n);
    el.hidden = n === 0;
  }
  window.addEventListener("storage", (e) => { if (e.key === CHAVE) atualizarContador(); });

  const LOGO = (cls = "logo") => `<span class="${cls}"><img src="img/flor.svg" alt=""><span class="logo-texto">TatiFashion<small>Modas</small></span></span>`;
  const ICONES = {
    menu: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>',
    sacola: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M5 8h14l-1 12H6L5 8z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/></svg>',
    busca: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>'
  };

  function montarTopo() {
    const topo = document.getElementById("topo");
    if (!topo) return;
    const links = categorias().map((c) => `<a href="catalogo.html?categoria=${encodeURIComponent(c)}">${esc(c)}</a>`).join("");
    topo.outerHTML = `
      <header class="topo">
        <div class="container">
          <button class="icone-btn" id="abrir-menu" aria-label="Abrir menu">${ICONES.menu}</button>
          <a href="index.html" aria-label="TatiFashion Modas, início">${LOGO()}</a>
          <div class="topo-acoes">
            <a class="icone-btn" href="catalogo.html#busca" aria-label="Buscar">${ICONES.busca}</a>
            <a class="icone-btn" href="sacola.html" aria-label="Sacola">${ICONES.sacola}<span class="contador" id="contador-sacola" hidden>0</span></a>
          </div>
        </div>
      </header>
      <nav class="menu" id="menu" aria-hidden="true">
        <div class="menu-fundo" data-fechar></div>
        <div class="menu-painel">
          <span style="padding:0 20px 16px;border-bottom:1px solid var(--borda)">${LOGO()}</span>
          <a href="index.html">Início</a>
          <a href="catalogo.html">Todos os produtos</a>
          <a href="sacola.html">Minha sacola</a>
          ${links}
          ${LOJA.instagram ? `<a href="${esc(LOJA.instagram)}" target="_blank" rel="noopener">Instagram</a>` : ""}
        </div>
      </nav>`;
    const menu = document.getElementById("menu");
    const abrir = (v) => { menu.classList.toggle("aberto", v); menu.setAttribute("aria-hidden", String(!v)); };
    document.getElementById("abrir-menu").addEventListener("click", () => abrir(true));
    menu.querySelector("[data-fechar]").addEventListener("click", () => abrir(false));
    atualizarContador();
  }

  function montarRodape() {
    const r = document.getElementById("rodape");
    if (!r) return;
    r.outerHTML = `
      <footer class="rodape">
        <div class="container">
          ${LOGO()}
          <p>Moda feminina com carinho, do nosso jeito.</p>
          <p>Encontre a gente nas feirinhas, igrejas e eventos da região.</p>
          ${LOJA.instagram ? `<p><a href="${esc(LOJA.instagram)}" target="_blank" rel="noopener">Siga no Instagram</a></p>` : ""}
          <p style="margin-top:14px;opacity:.7">© ${new Date().getFullYear()} TatiFashion Modas</p>
        </div>
      </footer>`;
  }

  function cardProduto(p) {
    const selo = p.esgotado ? '<span class="selo esgotado">Esgotado</span>' : p.precoAntigo ? '<span class="selo promo">Promo</span>' : p.novo ? '<span class="selo">Novo</span>' : "";
    return `
      <a class="card" href="produto.html?id=${encodeURIComponent(p.id)}">
        <div class="card-foto">
          <img src="${esc(p.foto)}"${p.fotoReserva ? ` data-reserva="${esc(p.fotoReserva)}"` : ""} alt="${esc(p.nome)}" loading="lazy" decoding="async">
          ${selo}
        </div>
        <div class="card-info">
          <span class="card-nome">${esc(p.nome)}</span>
          <span class="preco">${p.precoAntigo ? `<s>${reais(p.precoAntigo)}</s>` : ""}${reais(p.preco)}</span>
        </div>
      </a>`;
  }

  let toastTimer;
  function avisar(msg, link) {
    let t = document.querySelector(".toast");
    if (!t) { t = document.createElement("div"); t.className = "toast"; t.setAttribute("role", "status"); document.body.appendChild(t); }
    t.innerHTML = esc(msg) + (link ? ` <a href="${esc(link.href)}">${esc(link.texto)}</a>` : "");
    t.classList.add("visivel");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.classList.remove("visivel"), link ? 4000 : 2600);
  }

  const TF = window.TF = { PRODUTOS, LOJA, esc, reais, categorias, cardProduto, avisar, Sacola, lerJSON, gravarJSON, pronto, estoque, fonte: null };
  pronto(() => { montarTopo(); montarRodape(); });
})();
