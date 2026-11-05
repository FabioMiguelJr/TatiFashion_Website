/* TatiFashion — código compartilhado por todas as páginas */
(function () {
  const PRODUTOS = window.PRODUTOS || [];
  const LOJA = window.LOJA || { nome: "TatiFashion Modas" };

  const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const reais = (v) => Number(v).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  const categorias = () => [...new Set(PRODUTOS.map((p) => p.categoria))];

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
    const selo = p.precoAntigo ? '<span class="selo promo">Promo</span>' : p.novo ? '<span class="selo">Novo</span>' : "";
    return `
      <a class="card" href="produto.html?id=${encodeURIComponent(p.id)}">
        <div class="card-foto">
          <img src="${esc(p.foto)}" alt="${esc(p.nome)}" loading="lazy" decoding="async">
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

  window.TF = { PRODUTOS, LOJA, esc, reais, categorias, cardProduto, avisar, Sacola, lerJSON, gravarJSON };
  document.addEventListener("DOMContentLoaded", () => { montarTopo(); montarRodape(); });
})();
