-- DEPOIS DA VIRADA (e da conferência) · banco do departamento (analise-tributaria-pro)
-- Apaga a área de transferência. Sem ela o comando "copiar-ncm" se recusa a rodar — é a trava
-- que impede uma nova cópia apagar o que já foi gravado no NCM novo.
drop schema if exists migracao_ncm cascade;
