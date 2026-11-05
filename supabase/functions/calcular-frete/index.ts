// TatiFashion: calcular-frete (Supabase Edge Function)
// Recebe o CEP e as peças da sacola e devolve PAC, SEDEX e retirada, com preço e prazo.
// O preço do frete vem do Melhor Envio; peso e medidas vêm da tabela produtos.
//
// Segredos (Edge Functions > Secrets no painel do Supabase):
//   ME_TOKEN       token do Melhor Envio (obrigatório)
//   ME_AMBIENTE    "sandbox" (padrão, testes) ou "producao"
//   ME_USER_AGENT  opcional, ex.: "TatiFashion Modas (contato@loja.com.br)"
//
// Chamada: POST /functions/v1/calcular-frete  (header apikey = Publishable key)
//   { "cep": "20040-020", "itens": [{ "id": "saia-longa-azul", "qtd": 1 }] }
// Resposta:
//   { "subtotal": 79.9, "opcoes": [{ "servico": "PAC", "valor": 21.5, "prazo": 6 }, ...] }

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

const soDigitos = (s: unknown) => String(s ?? "").replace(/\D/g, "");

type Item = { id: string; qtd: number };
type Opcao = { servico: string; valor: number; prazo: number | null; nota?: string };

async function lerBanco(caminho: string, apikey: string) {
  const r = await fetch(`${env("SUPABASE_URL")}/rest/v1/${caminho}`, { headers: { apikey } });
  if (!r.ok) throw new Error(`Banco respondeu ${r.status}`);
  return await r.json();
}

export async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return responder({ erro: "Use POST" }, 405);

  let corpo: { cep?: string; itens?: Item[] };
  try { corpo = await req.json(); } catch { return responder({ erro: "Corpo inválido" }, 400); }

  const cep = soDigitos(corpo.cep);
  if (cep.length !== 8) return responder({ erro: "CEP inválido" }, 400);
  const itens = (corpo.itens || []).filter((i) => i && typeof i.id === "string" && Number(i.qtd) > 0);
  if (!itens.length || itens.length > 50) return responder({ erro: "Sacola vazia" }, 400);

  const apikey = req.headers.get("apikey") || env("SUPABASE_ANON_KEY") || "";
  const slugs = [...new Set(itens.map((i) => i.id))];
  const lista = slugs.map((s) => `"${s.replace(/"/g, "")}"`).join(",");

  let produtos, config;
  try {
    [produtos, config] = await Promise.all([
      lerBanco(`produtos?select=slug,preco,peso_g,altura_cm,largura_cm,comprimento_cm&ativo=eq.true&slug=in.(${encodeURIComponent(lista)})`, apikey),
      lerBanco("config_loja?select=cep_origem,frete_gratis_acima,retirada_ativa,retirada_texto", apikey),
    ]);
  } catch (e) {
    return responder({ erro: "Não foi possível ler o catálogo", detalhe: String(e) }, 502);
  }
  const loja = config[0];
  if (!loja) return responder({ erro: "Loja sem configuração (config_loja)" }, 500);

  const porSlug = new Map(produtos.map((p: { slug: string }) => [p.slug, p]));
  let subtotal = 0;
  const pacotes = [];
  for (const i of itens) {
    // deno-lint-ignore no-explicit-any
    const p: any = porSlug.get(i.id);
    if (!p) return responder({ erro: `Peça não encontrada: ${i.id}` }, 400);
    const qtd = Math.min(Math.floor(Number(i.qtd)), 20);
    subtotal += Number(p.preco) * qtd;
    pacotes.push({
      id: p.slug,
      width: p.largura_cm, height: p.altura_cm, length: p.comprimento_cm,
      weight: p.peso_g / 1000,
      insurance_value: Number(p.preco),
      quantity: qtd,
    });
  }
  subtotal = Math.round(subtotal * 100) / 100;

  const token = env("ME_TOKEN");
  if (!token) return responder({ erro: "Frete não configurado (falta ME_TOKEN)" }, 500);
  const base = env("ME_AMBIENTE") === "producao" ? "https://melhorenvio.com.br" : "https://sandbox.melhorenvio.com.br";

  let cotacao;
  try {
    const r = await fetch(`${base}/api/v2/me/shipment/calculate`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
        "User-Agent": env("ME_USER_AGENT") || "TatiFashion Modas (site)",
      },
      body: JSON.stringify({
        from: { postal_code: soDigitos(loja.cep_origem) },
        to: { postal_code: cep },
        products: pacotes,
        options: { receipt: false, own_hand: false },
        services: "1,2", // 1 = PAC, 2 = SEDEX (Correios)
      }),
    });
    cotacao = await r.json();
    if (!r.ok) throw new Error(`Melhor Envio respondeu ${r.status}: ${JSON.stringify(cotacao).slice(0, 300)}`);
  } catch (e) {
    return responder({ erro: "Não foi possível calcular o frete agora", detalhe: String(e) }, 502);
  }

  const opcoes: Opcao[] = (Array.isArray(cotacao) ? cotacao : [])
    // deno-lint-ignore no-explicit-any
    .filter((s: any) => !s.error && (s.custom_price ?? s.price))
    // deno-lint-ignore no-explicit-any
    .map((s: any) => ({
      servico: s.name,
      valor: Number(s.custom_price ?? s.price),
      prazo: Number(s.custom_delivery_time ?? s.delivery_time) || null,
    }))
    .sort((a: Opcao, b: Opcao) => a.valor - b.valor);

  const gratis = loja.frete_gratis_acima ? Number(loja.frete_gratis_acima) : null;
  if (gratis !== null && subtotal >= gratis && opcoes.length) {
    opcoes[0] = { ...opcoes[0], valor: 0, nota: "Frete grátis" };
  }
  if (loja.retirada_ativa) {
    opcoes.push({ servico: "Retirada", valor: 0, prazo: null, nota: loja.retirada_texto || "Retirar com a Tati" });
  }
  if (!opcoes.length) return responder({ erro: "Nenhuma opção de frete para este CEP" }, 422);

  return responder({ subtotal, opcoes });
}

if (g.Deno) g.Deno.serve(handler);
