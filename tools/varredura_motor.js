#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════════════════
//  Varredura do motor — recalcula uma bateria de casos pelo motor de um
//  index.html dado e grava um JSON canônico, para comparar duas versões
//  byte a byte. Uso:
//    node varredura_motor.js <caminho/index.html> <saida.json>
//  A bateria cobre: os 4 casos do lacre, os 2 fixtures-gabarito da suíte e
//  18 casos sintéticos (anexos I–V, Fator R dos dois lados, ST/mono/retenção,
//  sublimite, limite, LC 224 ligada/desligada, 2025/2026, início de atividade,
//  perfis de fornecedor na Reforma). Para cada caso grava TODOS os números do
//  resultado (totais, 12 meses × DAS/LP/LR/decomposição, cenários da Reforma
//  2026–2033 com sensibilidade) com 2 casas, mais lacreRodar().
// ═══════════════════════════════════════════════════════════════════════════
const fs = require('fs'), path = require('path'), vm = require('vm');
const ARQ = process.argv[2], SAIDA = process.argv[3];
if (!ARQ || !SAIDA) { console.error('uso: node varredura_motor.js <index.html> <saida.json>'); process.exit(2); }
const html = fs.readFileSync(ARQ, 'utf8');
const js = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(x => x[1]).join('\n');

// sandbox mínimo (mesmo da suíte oficial tests/run.js)
const mkEl = () => { const el = { innerHTML:'', textContent:'', _v:'', style:{}, classList:{add(){},remove(){},toggle(){}},
  selectedOptions:[{text:'Mensal'}], addEventListener(){}, appendChild(){}, setAttribute(){}, getContext:()=>({}),
  remove(){}, removeAttribute(){}, removeChild(){}, insertAdjacentHTML(){}, focus(){}, click(){}, closest:()=>null,
  options:[], checked:true, files:[], dataset:{}, querySelector:()=>mkEl(), querySelectorAll:()=>[] };
  Object.defineProperty(el,'value',{ get(){return el._v;}, set(v){el._v=String(v);} }); return el; };
const els = {};
const doc = { getElementById:id=>els[id]||(els[id]=mkEl()), querySelector:()=>mkEl(), querySelectorAll:()=>[],
  createElement:()=>mkEl(), addEventListener(){}, body:mkEl(), head:mkEl() };
const ctx = { document:doc, window:{ addEventListener(){}, print(){} },
  localStorage:{getItem:()=>null,setItem(){},removeItem(){}}, sessionStorage:{getItem:()=>null,setItem(){}},
  fetch:async()=>({ok:true,json:async()=>({}),text:async()=>''}), navigator:{}, console:{...console,log(){},error(){}},
  setTimeout, clearTimeout, alert(){}, confirm:()=>true, prompt:()=>'varredura', URL, atob:s=>s, btoa:s=>s, AbortController, AbortSignal };
ctx.window.document = doc; vm.createContext(ctx);
try { vm.runInContext(js, ctx); } catch(e) { /* init sem DOM real */ }
const g = ctx;

const AD = vm.runInContext('ANEXOS_DEFAULT', ctx), FD = vm.runInContext('FOLHA_PERC_DEFAULT', ctx);
const clone = o => JSON.parse(JSON.stringify(o));
const z = () => Array(12).fill(0);
const mk = (rec, rbt, cfgx) => ({ cfg: Object.assign({ ano:2025, iss:.05, icmsV:.17, icmsC:.12, ipiV:0, ipiC:0,
    rbt12Direto:0, rbt12Lanc:Array(12).fill(rbt/12), folha12Lanc:Array(12).fill(20000),
    lpBaseServ:.32, lpBaseCom:.08, adicionalIR:'off', sublimite:'auto' }, cfgx||{}),
  receitas: Object.assign(Object.fromEntries(['a1_semst','a1_red','a1_red_pct','a1_mono','a1_mono_pct','a1_comst','a1_comst_mono','a2_semst','a2_red','a2_red_pct','a2_mono','a2_comst','a2_comst_mono','a3_semret','a3_retiss','a3_retissinss','a4','a5r','fin','comtransp'].map(k=>[k,z()])), rec),
  folha:{ prolabore:Array(12).fill(5000), salarios:Array(12).fill(20000), baseFgts:Array(12).fill(20000), prov13:z(), provFerias:z() },
  compras: Object.fromEntries(['semst','baixaSemst','mono','baixaMono','comst','baixaComst','comstMono','baixaComstMono','baseIpiCred'].map(k=>[k,z()])),
  icms:{cred:null,deb:null}, ipi:{cred:null,deb:null}, folha13:{prolabore13:0,salarios13:0,baseFgts13:0},
  despesas: Object.fromEntries(['adm','vendas','fiscais','financeiras','outras','credLR'].map(k=>[k,z()])) });

// ── bateria ──
const casos = [];
// 4 casos do lacre (embutidos no app)
const LC = vm.runInContext('LACRE_CASOS', ctx);
for (const c of LC) casos.push(['lacre · '+c.nome, clone(c.inp)]);
// fixtures-gabarito da suíte
const RAIZ_TESTES = path.join(__dirname, '..', 'tests', 'fixtures');
for (const f of ['caso1','caso2']) {
  const p = path.join(RAIZ_TESTES, f + '.json');
  if (fs.existsSync(p)) casos.push(['fixture · '+f, JSON.parse(fs.readFileSync(p,'utf8')).inp]);
}
// sintéticos
casos.push(['sint · Anexo I puro', mk({a1_semst:Array(12).fill(100000)},1200000)]);
casos.push(['sint · Anexo II indústria c/ IPI', mk({a2_semst:Array(12).fill(90000)},1080000,{ipiV:.1,ipiC:.05})]);
casos.push(['sint · Anexo III Fator R ≥28%', mk({a3_semret:Array(12).fill(50000)},600000,{folha12Lanc:Array(12).fill(17000)})]);
casos.push(['sint · Anexo V Fator R <28%', mk({a5r:Array(12).fill(50000)},600000,{folha12Lanc:Array(12).fill(5000)})]);
casos.push(['sint · Anexo IV construção', mk({a4:Array(12).fill(50000)},600000)]);
casos.push(['sint · Misto ST/mono/retenção/IV', mk({a1_semst:Array(12).fill(80000),a1_comst:Array(12).fill(30000),a1_mono:Array(12).fill(10000),a1_mono_pct:Array(12).fill(1),a3_retiss:Array(12).fill(40000),a4:Array(12).fill(20000)},2400000)]);
casos.push(['sint · Sublimite > 3,6 mi', mk({a1_semst:Array(12).fill(200000),a3_semret:Array(12).fill(150000)},4200000)]);
casos.push(['sint · Acima do limite 4,8 mi', mk({a1_semst:Array(12).fill(500000)},7200000)]);
casos.push(['sint · Retenção ISS+INSS', mk({a3_retissinss:Array(12).fill(60000)},720000)]);
casos.push(['sint · Receita financeira + transporte', mk({a1_semst:Array(12).fill(70000),fin:Array(12).fill(2000),comtransp:Array(12).fill(15000)},1000000)]);
casos.push(['sint · 2026 LP > 5 mi (LC 224 aplicada)', mk({a1_semst:Array(12).fill(600000)},7200000,{ano:2026,adicionalIR:'trimestral'})]);
(() => { const c = mk({a1_semst:Array(12).fill(600000)},7200000,{ano:2026,adicionalIR:'trimestral'}); c.cfg.lc224 = false;
  casos.push(['sint · 2026 LP > 5 mi (LC 224 DESLIGADA)', c]); })();
casos.push(['sint · 2026 serviços LP (CSLL 32%)', mk({a3_semret:Array(12).fill(500000)},6000000,{ano:2026,adicionalIR:'trimestral',folha12Lanc:Array(12).fill(120000)})]);
casos.push(['sint · 2025 (ano anterior à LC 224)', mk({a1_semst:Array(12).fill(600000)},7200000,{ano:2025,adicionalIR:'trimestral'})]);
(() => { const c = mk({a5r:[0,0,36000,31000,32000,33000,34000,34000,34000,34000,34000,34000]},0,{ano:2026,inicioAtividade:'2026-02'});
  casos.push(['sint · Início de atividade fev/2026', c]); })();
(() => { const c = mk({a1_semst:Array(12).fill(100000)},1200000); c.compras.semst = Array(12).fill(60000);
  casos.push(['sint · Compras sem perfil de fornecedor', c]); })();
(() => { const c = mk({a1_semst:Array(12).fill(100000)},1200000); c.compras.semst = Array(12).fill(60000);
  c.composicao = { semst:{ regular:0.6, simples:0.3, mei:0.1 } };
  casos.push(['sint · Compras com composição (regular/simples/MEI)', c]); })();
casos.push(['sint · Redução de base + mono com pct', mk({a1_red:Array(12).fill(40000),a1_red_pct:Array(12).fill(.4),a1_mono:Array(12).fill(20000),a1_mono_pct:Array(12).fill(.5)},720000)]);

// ── execução ──
const r2 = v => (typeof v === 'number' && isFinite(v)) ? Math.round(v*100)/100 : v;
const podar = (o, prof) => {  // só números, arrays e objetos — com 2 casas; nada de strings longas/HTML
  if (prof > 8) return undefined;
  if (typeof o === 'number') return r2(o);
  if (typeof o === 'boolean' || o === null) return o;
  if (typeof o === 'string') return o.length > 60 ? o.slice(0,57)+'...' : o;
  if (Array.isArray(o)) return o.map(x => podar(x, prof+1));
  if (typeof o === 'object') { const s = {};
    for (const k of Object.keys(o).sort()) { const v = podar(o[k], prof+1); if (v !== undefined) s[k] = v; }
    return s; }
  return undefined; };

const saida = { arquivo: path.basename(path.dirname(ARQ)) + '/' + path.basename(ARQ),
  app_versao: vm.runInContext('APP_VERSAO', ctx), lacre: null, casos: {} };
const lac = vm.runInContext('lacreRodar()', ctx);
saida.lacre = { hash: lac.hash, ok: lac.ok, n: lac.n, resumo: podar(lac.resumo, 0) };

for (const [nome, inp] of casos) {
  let reg = {};
  try {
    const r = g.calcular(clone(inp), clone(AD), {...FD});
    reg.totais = podar(r.totais, 0);
    reg.meses = r.meses.map(M => podar({ das:M.das, subIcms:M.subIcms, subIss:M.subIss, inssPatr:M.inssPatr,
      issRetido:M.issRetido, dasTrib:M.dasTrib, simples:M.simples && M.simples.total, lp:M.lp && M.lp.total,
      lr:M.lr && M.lr.total, lpDet:M.lp, lrDet:M.lr }, 0));
    const cen = g.calcCenariosReforma(r, inp.composicao ? { composicao: inp.composicao } : null);
    const linhas = (cen.linhas || cen.REF || []);
    reg.reforma = linhas.map(L => podar({ ano:L.ano, dentro:L.dentro, hib:L.hib, regular:L.regular, deb:L.deb,
      cred:L.cred, liq:L.liq, is:L.is, sens:L.sens }, 0));
    reg.reformaFlags = podar({ proxyCompras: cen.proxyCompras, semPerfil: cen.semPerfil }, 0);
  } catch(e) { reg.erro = String(e && e.message || e); }
  saida.casos[nome] = reg;
}
fs.writeFileSync(SAIDA, JSON.stringify(saida, null, 1));
const nums = JSON.stringify(saida).match(/-?\d+\.?\d*/g) || [];
console.log(`varredura: ${casos.length} casos · APP_VERSAO ${saida.app_versao} · lacre ${saida.lacre.hash} (${saida.lacre.ok?'ÍNTEGRO':'VIOLADO'}) · ${nums.length} números → ${SAIDA}`);
