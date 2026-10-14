-- VIRADA · passo (e) · Portal (banco do Departamento Pessoal / fbxelwhdiisfmnwrerbl, schema core)
-- Aponta os 5 aplicativos do Tributário e Fiscal para os endereços novos. Volta: volta_destinos.sql.
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/tributario-fiscal/analise-tributaria-pro/', atualizado_em = now() where id = 'atp';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/tributario-fiscal/classificacao-rtc/',     atualizado_em = now() where id = 'rtc';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/tributario-fiscal/incorporacao/',          atualizado_em = now() where id = 'incorporacao';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/tributario-fiscal/imobiliario/',           atualizado_em = now() where id = 'imobiliario';
update core.apps set destino_url = 'https://arteconartescontabeis-design.github.io/tributario-fiscal/ncm-pro/',               atualizado_em = now() where id = 'ncm';
select id, destino_url from core.apps where area_id = 'tributario' order by ordem;
