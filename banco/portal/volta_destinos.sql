-- VOLTA ATRÁS · Portal (banco do Departamento Pessoal / fbxelwhdiisfmnwrerbl, schema core)
-- Endereços em uso até a virada (lidos do banco em 14/10/2026).
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/analise-tributaria-pro/',                  atualizado_em = now() where id = 'atp';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/analise-tributaria-pro/classificacao.html', atualizado_em = now() where id = 'rtc';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/analise-tributaria-pro/incorporacao.html',  atualizado_em = now() where id = 'incorporacao';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/analise-tributaria-pro/imobiliaria.html',   atualizado_em = now() where id = 'imobiliario';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/ncm-pro/',                                  atualizado_em = now() where id = 'ncm';
select id, destino_url from core.apps where area_id = 'tributario' order by ordem;
