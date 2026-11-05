// TatiFashion: webhook-mercadopago (Supabase Edge Function)
// 1. Recebe os avisos do Mercado Pago (notification_url das orders).
// 2. Também é chamada pela página obrigado.html com { "pedido_id": "..." } para conferir o pagamento.
// Nos dois casos a função NÃO confia no conteúdo recebido: ela consulta a order direto na API
// do Mercado Pago (GET /v1/orders/{id}) com o Access Token e só então atualiza o pedido.
//
// Segredos: TF_SECRET_KEY, MP_ACCESS_TOKEN (os mesmos da criar-pedido)

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-signature, x-request-id",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};
// deno-lint-ignore no-explicit-any
const g = globalThis as any;
const env = (k: string): string | undefined => (g.Deno ? g.Deno.env.get(k) : g.process?.env?.[k]) || undefined;
const responder = (corpo: unknown, status = 200) =>
  new Response(JSON.stringify(corpo), { status, headers: { ...CORS, "Content-Type": "application/json" } });
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function chaveSecreta() { return env("TF_SECRET_KEY") || env("SUPABASE_SERVICE_ROLE_KEY") || ""; }
async function banco(caminho: string, init: RequestInit = {}) {
  const chave = chaveSecreta();
  const headers: Record<string, string> = { apikey: chave, "Content-Type": "application/json", ...(init.headers as Record<string, string> || {}) };
  if (!chave.startsWith("sb_")) headers.Authorization = `Bearer ${chave}`;
  const r = await fetch(`${env("SUPABASE_URL")}/rest/v1/${caminho}`, { ...init, headers });
  const t = await r.text();
  if (!r.ok) throw new Error(`Banco ${r.status}: ${t.slice(0, 300)}`);
  return t ? JSON.parse(t) : null;
}

async function buscarOrder(id: string) {
  const r = await fetch(`https://api.mercadopago.com/v1/orders/${encodeURIComponent(id)}`, {
    headers: { Authorization: `Bearer ${env("MP_ACCESS_TOKEN")}`, Accept: "application/json" },
  });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error(`Mercado Pago ${r.status}: ${(await r.text()).slice(0, 300)}`);
  return await r.json();
}

// deno-lint-ignore no-explicit-any
export function situacao(order: any): "pago" | "pendente" | "recusado" | "cancelado" {
  // deno-lint-ignore no-explicit-any
  const pagamentos: any[] = order?.transactions?.payments || [];
  const pagoTotal = Number(order?.total_paid_amount || 0) >= Number(order?.total_amount || Infinity) - 0.001;
  const algumAprovado = pagamentos.some((p) => p.status === "processed" && (!p.status_detail || p.status_detail === "accredited"));
  if (order?.status === "processed" || algumAprovado || pagoTotal) return "pago";
  if (["canceled", "cancelled", "expired", "refunded", "charged_back"].includes(order?.status)) return "cancelado";
  if (pagamentos.length && pagamentos.every((p) => ["failed", "rejected", "canceled", "cancelled"].includes(p.status))) return "recusado";
  return "pendente";
}

// deno-lint-ignore no-explicit-any
async function processar(pedido: any) {
  if (!pedido.mp_order_id) return { numero: pedido.numero, status: pedido.status, pagamento: "sem_order" };
  const order = await buscarOrder(pedido.mp_order_id);
  if (!order) return { numero: pedido.numero, status: pedido.status, pagamento: "order_nao_encontrada" };
  const s = situacao(order);

  // registra cada pagamento visto (uma linha por id do Mercado Pago)
  for (const p of order.transactions?.payments || []) {
    if (!p.id) continue;
    await banco("pagamentos?on_conflict=provedor_id", {
      method: "POST",
      headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify({
        pedido_id: pedido.id, provedor: "mercadopago", provedor_id: String(p.id),
        status: [p.status, p.status_detail].filter(Boolean).join("/"),
        metodo: p.payment_method?.type || p.payment_method?.id || null,
        valor: p.amount ? Number(p.amount) : null, resposta: p,
      }),
    });
  }

  const mudanca: Record<string, unknown> = { mp_status: [order.status, order.status_detail].filter(Boolean).join("/") };
  if (s === "pago" && pedido.status === "aguardando_pagamento") mudanca.status = "pago";
  if (s === "cancelado" && pedido.status === "aguardando_pagamento") mudanca.status = "cancelado";
  await banco(`pedidos?id=eq.${pedido.id}`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify(mudanca) });
  return { numero: pedido.numero, status: (mudanca.status as string) || pedido.status, pagamento: s };
}

const CAMPOS = "id,numero,status,mp_order_id";

export async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (!chaveSecreta() || !env("MP_ACCESS_TOKEN")) return responder({ erro: "Servidor sem TF_SECRET_KEY ou MP_ACCESS_TOKEN" }, 500);
  const url = new URL(req.url);
  // deno-lint-ignore no-explicit-any
  let corpo: any = {};
  if (req.method === "POST") corpo = await req.json().catch(() => ({}));

  try {
    // Conferência pedida pelo site (obrigado.html)
    if (corpo.pedido_id) {
      if (!UUID.test(corpo.pedido_id)) return responder({ erro: "pedido_id inválido" }, 400);
      const [pedido] = await banco(`pedidos?select=${CAMPOS}&id=eq.${corpo.pedido_id}`);
      if (!pedido) return responder({ erro: "Pedido não encontrado" }, 404);
      return responder(await processar(pedido));
    }

    // Aviso do Mercado Pago: o id da order vem em data.id (corpo ou URL)
    const id = String(corpo?.data?.id || url.searchParams.get("data.id") || url.searchParams.get("id") || corpo?.id || "");
    if (!id) return responder({ ok: true, ignorado: "sem id" });
    let [pedido] = await banco(`pedidos?select=${CAMPOS}&mp_order_id=eq.${encodeURIComponent(id)}`);
    if (!pedido) {
      // aviso chegou antes de gravarmos o id: procura pelo número (external_reference)
      const order = await buscarOrder(id);
      const numero = Number(order?.external_reference);
      if (!order || !numero) return responder({ ok: true, ignorado: "order desconhecida" });
      [pedido] = await banco(`pedidos?select=${CAMPOS}&numero=eq.${numero}`);
      if (!pedido) return responder({ ok: true, ignorado: "pedido desconhecido" });
      await banco(`pedidos?id=eq.${pedido.id}`, { method: "PATCH", body: JSON.stringify({ mp_order_id: id }) });
      pedido.mp_order_id = id;
    }
    return responder({ ok: true, ...(await processar(pedido)) });
  } catch (e) {
    console.error(e);
    return responder({ erro: String(e) }, 500); // 500 faz o Mercado Pago tentar de novo depois
  }
}

if (g.Deno) g.Deno.serve(handler);
