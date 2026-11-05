// TatiFashion: criar-pedido (Supabase Edge Function)
// Grava o pedido no banco (preço e frete recalculados aqui, nunca vindos do navegador) e,
// no canal "site", cria a order no Mercado Pago (API de Orders, Checkout Pro) e devolve o link de pagamento.
//
// Segredos (Edge Functions > Secrets):
//   TF_SECRET_KEY    Secret key do Supabase (sb_secret_...), para gravar pedidos
//   MP_ACCESS_TOKEN  Access Token do Mercado Pago (no teste: credencial de PRODUÇÃO da conta vendedora de teste)
//   SITE_URL         endereço do site, ex.: https://fabiomigueljr.github.io/TatiFashion_Website/
//   MP_MAX_PARCELAS  opcional, padrão 6
//
// Chamada: POST /functions/v1/criar-pedido  (header apikey = Publishable key)
// {
//   "canal": "site" | "whatsapp",
//   "entrega": "correios" | "retirada" | "feirinha",
//   "frete_servico": "PAC",
//   "cliente": { "nome": "...", "telefone": "...", "email": "...", "cpf": "...", "observacao": "..." },
//   "endereco": { "cep": "...", "rua": "...", "numero": "...", "complemento": "", "bairro": "...", "cidade": "...", "uf": "RJ" },
//   "itens": [{ "id": "saia-longa-azul", "tamanho": "M", "cor": "Azul marinho", "qtd": 1 }]
// }
// Resposta: { "pedido_id", "numero", "subtotal", "frete", "total", "pagar_url"? }

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
// deno-lint-ignore no-explicit-any
const g = globalThis as any;
const env = (k: string): string | undefined => (g.Deno ? g.Deno.env.get(k) : g.process?.env?.[k]) || undefined;
const responder = (corpo: unknown, status = 200) =>
  new Response(JSON.stringify(corpo), { status, headers: { ...CORS, "Content-Type": "application/json" } });
const dinheiro = (n: number) => (Math.round(n * 100) / 100).toFixed(2);
const texto = (v: unknown, max = 200) => String(v ?? "").trim().slice(0, max);

const ENTREGAS: Record<string, string> = { retirada: "Retirar com a Tati", feirinha: "Pegar na feirinha / igreja" };

function chaveSecreta() {
  return env("TF_SECRET_KEY") || env("SUPABASE_SERVICE_ROLE_KEY") || "";
}

async function banco(caminho: string, init: RequestInit = {}) {
  const chave = chaveSecreta();
  const headers: Record<string, string> = { apikey: chave, "Content-Type": "application/json", ...(init.headers as Record<string, string> || {}) };
  if (!chave.startsWith("sb_")) headers.Authorization = `Bearer ${chave}`; // chave antiga (JWT)
  const r = await fetch(`${env("SUPABASE_URL")}/rest/v1/${caminho}`, { ...init, headers });
  const corpo = await r.text();
  let json: unknown = null;
  try { json = corpo ? JSON.parse(corpo) : null; } catch { json = corpo; }
  if (!r.ok) {
    // deno-lint-ignore no-explicit-any
    const msg = (json as any)?.message || corpo;
    throw Object.assign(new Error(String(msg)), { status: r.status });
  }
  return json;
}

// Cria a order no Mercado Pago. Se a API recusar algum campo (400 unsupported_properties /
// required_properties), removemos o campo citado no erro e tentamos de novo (até 4 vezes).
// deno-lint-ignore no-explicit-any
function removerCampo(obj: any, caminho: string) {
  const partes = caminho.replace(/^\$\.?/, "").split(".").filter(Boolean);
  let alvo = obj;
  for (let i = 0; i < partes.length - 1; i++) {
    alvo = alvo?.[partes[i].replace(/\[\d+\]$/, "")];
    if (!alvo) return false;
  }
  const ultimo = partes.at(-1)?.replace(/\[\d+\]$/, "");
  if (!ultimo || !(ultimo in alvo)) return false;
  delete alvo[ultimo];
  return true;
}
// deno-lint-ignore no-explicit-any
async function criarOrderMP(base: any, idempotencia: string) {
  const corpo = JSON.parse(JSON.stringify(base));
  let ultimoErro = "";
  for (let i = 0; i < 4; i++) {
    const r = await fetch("https://api.mercadopago.com/v1/orders", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${env("MP_ACCESS_TOKEN")}`,
        "X-Idempotency-Key": `${idempotencia}-${i}`,
      },
      body: JSON.stringify(corpo),
    });
    // deno-lint-ignore no-explicit-any
    const resp: any = await r.json().catch(() => ({}));
    if (r.ok) return resp;
    ultimoErro = `${r.status} ${JSON.stringify(resp).slice(0, 500)}`;
    console.error("Mercado Pago recusou a order (tentativa " + (i + 1) + "):", ultimoErro);
    if (r.status !== 400) break;
    let mudou = false;
    for (const e of resp.errors || []) {
      for (const d of e.details || []) {
        const m = String(d).match(/'(\$[^']*)'/);
        if (!m) continue;
        // campo não aceito: remove; campo obrigatório faltando dentro de transactions: remove o bloco transactions
        if (e.code === "unsupported_properties") mudou = removerCampo(corpo, m[1]) || mudou;
        if (e.code === "required_properties" && m[1].startsWith("$.transactions")) mudou = removerCampo(corpo, "$.transactions") || mudou;
      }
    }
    if (!mudou) break;
  }
  throw new Error("Mercado Pago: " + ultimoErro);
}

export async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return responder({ erro: "Use POST" }, 405);
  if (!chaveSecreta()) return responder({ erro: "Servidor sem TF_SECRET_KEY" }, 500);

  // deno-lint-ignore no-explicit-any
  let e: any;
  try { e = await req.json(); } catch { return responder({ erro: "Corpo inválido" }, 400); }

  const canal = e.canal === "whatsapp" ? "whatsapp" : "site";
  const entrega = ["correios", "retirada", "feirinha"].includes(e.entrega) ? e.entrega : "correios";
  const cliente = {
    nome: texto(e.cliente?.nome, 120),
    telefone: texto(e.cliente?.telefone, 30),
    email: texto(e.cliente?.email, 120),
    cpf: texto(e.cliente?.cpf, 20).replace(/\D/g, ""),
    observacao: texto(e.cliente?.observacao, 500),
  };
  if (!cliente.nome) return responder({ erro: "Informe o nome" }, 400);
  if (canal === "site" && cliente.telefone.replace(/\D/g, "").length < 10) return responder({ erro: "Informe o telefone com DDD" }, 400);
  if (!cliente.telefone) cliente.telefone = "não informado";
  const endereco = Object.fromEntries(["cep", "rua", "numero", "complemento", "bairro", "cidade", "uf"].map((k) => [k, texto(e.endereco?.[k], 120)]));
  if (entrega === "correios" && (!endereco.cep || !endereco.rua || !endereco.numero || !endereco.cidade || !endereco.uf)) {
    return responder({ erro: "Endereço incompleto" }, 400);
  }

  const itens = (Array.isArray(e.itens) ? e.itens : []).slice(0, 50)
    // deno-lint-ignore no-explicit-any
    .map((i: any) => ({ id: texto(i?.id, 100), tamanho: texto(i?.tamanho, 30), cor: texto(i?.cor, 60), qtd: Math.min(Math.floor(Number(i?.qtd) || 0), 20) }))
    // deno-lint-ignore no-explicit-any
    .filter((i: any) => i.id && i.qtd > 0);
  if (!itens.length) return responder({ erro: "Sacola vazia" }, 400);

  // 1. Acha a variante (tamanho + cor) de cada peça
  // deno-lint-ignore no-explicit-any
  const slugs = [...new Set(itens.map((i: any) => i.id))].map((s) => `"${String(s).replace(/"/g, "")}"`).join(",");
  // deno-lint-ignore no-explicit-any
  let variantes: any[];
  try {
    // deno-lint-ignore no-explicit-any
    variantes = await banco(`variantes?select=id,tamanho,cor,produtos!inner(slug,nome,preco)&produtos.slug=in.(${encodeURIComponent(slugs)})`) as any[];
  } catch (err) {
    return responder({ erro: "Não foi possível ler o catálogo", detalhe: String(err) }, 502);
  }
  const pItens = [];
  for (const i of itens) {
    const v = variantes.find((x) => x.produtos.slug === i.id && x.tamanho === i.tamanho && x.cor === i.cor);
    if (!v) return responder({ erro: `Peça indisponível: ${i.id} (${i.tamanho} / ${i.cor})` }, 409);
    pItens.push({ variante_id: v.id, quantidade: i.qtd });
  }

  // 2. Frete recalculado aqui
  let frete = { valor: 0, servico: ENTREGAS[entrega] || "Retirada", prazo: null as number | null };
  if (entrega === "correios") {
    const servico = texto(e.frete_servico, 40);
    let cotacao = null;
    try {
      const r = await fetch(`${env("SUPABASE_URL")}/functions/v1/calcular-frete`, {
        method: "POST",
        headers: { "Content-Type": "application/json", apikey: req.headers.get("apikey") || "" },
        // deno-lint-ignore no-explicit-any
        body: JSON.stringify({ cep: endereco.cep, itens: itens.map((i: any) => ({ id: i.id, qtd: i.qtd })) }),
      });
      cotacao = r.ok ? await r.json() : null;
    } catch { cotacao = null; }
    // deno-lint-ignore no-explicit-any
    const opcao = cotacao?.opcoes?.find((o: any) => o.servico === servico && o.servico !== "Retirada");
    if (opcao) frete = { valor: Number(opcao.valor), servico: opcao.servico, prazo: opcao.prazo };
    else if (canal === "site") return responder({ erro: "Não foi possível confirmar o frete. Tente de novo ou feche pelo WhatsApp." }, 502);
    else frete = { valor: 0, servico: "Correios (a combinar)", prazo: null };
  }

  // 3. Grava o pedido (a função do banco confere estoque e usa o preço do banco)
  // deno-lint-ignore no-explicit-any
  let pedido: any;
  try {
    const linhas = await banco("rpc/criar_pedido", {
      method: "POST",
      body: JSON.stringify({ p_cliente: cliente, p_endereco: endereco, p_itens: pItens, p_canal: canal, p_frete: frete }),
    // deno-lint-ignore no-explicit-any
    }) as any[];
    pedido = linhas[0];
  } catch (err) {
    const msg = String((err as Error).message || err);
    return responder({ erro: /estoque|encontrada/i.test(msg) ? msg : "Não foi possível gravar o pedido", detalhe: msg }, /estoque|encontrada/i.test(msg) ? 409 : 500);
  }
  const resposta = {
    pedido_id: pedido.pedido_id, numero: pedido.numero,
    subtotal: Number(pedido.subtotal), frete: frete.valor, frete_servico: frete.servico, frete_prazo: frete.prazo,
    total: Number(pedido.total),
  };
  if (canal === "whatsapp") return responder(resposta);

  // 4. Cria a order de pagamento no Mercado Pago
  if (!env("MP_ACCESS_TOKEN")) return responder({ ...resposta, erro: "Pagamento online não configurado (MP_ACCESS_TOKEN)" }, 500);
  const site = (env("SITE_URL") || "https://fabiomigueljr.github.io/TatiFashion_Website/").replace(/\/?$/, "/");
  const volta = (s: string) => `${site}obrigado.html?pedido=${pedido.pedido_id}&n=${pedido.numero}&r=${s}`;
  // deno-lint-ignore no-explicit-any
  const itensMP = variantes.length ? pItens.map((pi: any) => {
    const v = variantes.find((x) => x.id === pi.variante_id);
    return { external_code: String(v.id), title: `${v.produtos.nome} (${v.tamanho} / ${v.cor})`.slice(0, 250), unit_price: dinheiro(Number(v.produtos.preco)), quantity: pi.quantidade };
  }) : [];
  if (frete.valor > 0) itensMP.push({ external_code: "frete", title: `Frete ${frete.servico}`, unit_price: dinheiro(frete.valor), quantity: 1 });
  const [primeiro, ...resto] = cliente.nome.split(/\s+/);

  const corpoMP = {
    type: "online",
    processing_mode: "manual",
    total_amount: dinheiro(resposta.total),
    external_reference: String(pedido.numero),
    description: `TatiFashion Modas - pedido ${pedido.numero}`,
    payer: {
      ...(cliente.email ? { email: cliente.email } : {}),
      first_name: primeiro, ...(resto.length ? { last_name: resto.join(" ") } : {}),
      ...(cliente.cpf.length === 11 ? { identification: { type: "CPF", number: cliente.cpf } } : {}),
    },
    items: itensMP,
    // notification_url e transactions não são aceitos no Checkout Pro (o aviso é configurado na aplicação do Mercado Pago)
    expiration_time: "P3D",
    config: {
      online: { success_url: volta("ok"), pending_url: volta("pendente"), failure_url: volta("falha"), auto_return: "approved" },
      payment_method: { max_installments: Number(env("MP_MAX_PARCELAS") || 6) },
    },
  };

  // deno-lint-ignore no-explicit-any
  let order: any;
  try {
    order = await criarOrderMP(corpoMP, pedido.pedido_id);
  } catch (err) {
    await banco(`pedidos?id=eq.${pedido.pedido_id}`, { method: "PATCH", body: JSON.stringify({ status: "cancelado", observacao: "Falha ao criar pagamento: " + String(err).slice(0, 300) }) }).catch(() => {});
    return responder({ erro: "Não foi possível abrir o pagamento agora. Tente de novo ou feche pelo WhatsApp.", detalhe: String(err) }, 502);
  }
  const pagar_url = order.checkout_url || order.checkout_pro?.init_point || order.init_point;
  await banco(`pedidos?id=eq.${pedido.pedido_id}`, {
    method: "PATCH",
    body: JSON.stringify({ mp_order_id: order.id, mp_status: order.status || null }),
  }).catch((err) => console.error("Não gravou mp_order_id:", err));
  if (!pagar_url) return responder({ ...resposta, erro: "Mercado Pago não devolveu o link de pagamento" }, 502);
  return responder({ ...resposta, pagar_url });
}

if (g.Deno) g.Deno.serve(handler);
