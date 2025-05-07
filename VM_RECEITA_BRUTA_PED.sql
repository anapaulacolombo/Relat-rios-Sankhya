
CREATE MATERIALIZED VIEW VM_RECEITA_BRUTA_PED
BUILD IMMEDIATE
REFRESH ON DEMAND AS

--CREATE OR REPLACE VIEW V_RECEITA_BRUTA_PED AS
select sum(vlr_receita_bruta_total) as RB_TOTAL,
       sum(vlr_receita_bruta_produtos) as RB_PRODUTOS,
       sum(vlr_receita_bruta_servicos ) as RB_SERVICOS,
       NUNOTA_PEDIDO,  GRUPO_TOP, COD_NATUREZA
FROM (
select NUNOTA_PEDIDO, A.SEQ, CODPROD,DESCRPROD, GRUPO_TOP, COD_NATUREZA,
      CASE WHEN  descr_natureza in ('VENDA FRANQUEADO') AND (NVL(vlrtot,0)>0)  THEN
             ROUND((NVL(CAST(vlrtot AS NUMERIC), 0) + NVL(CAST(valor_ipi AS NUMERIC), 0)) +
             (NVL(CAST(valor_nf AS NUMERIC), 0) / SUM(NVL(CAST(valor_nf AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER)))
            * SUM(NVL(CAST(royalties_taxa AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER))
           / (1 - NVL(CAST(valor_desconto AS NUMERIC) / NVL(CAST(vlrtot AS NUMERIC), 0), 0)),2)
           ELSE 0
      END vlr_receita_bruta_total,
      CASE WHEN descr_natureza in ('VENDA FRANQUEADO') THEN
          ROUND((NVL(CAST(vlrtot AS NUMERIC), 0) + NVL(CAST(valor_ipi AS NUMERIC), 0)),2)
          ELSE 0
      END  vlr_receita_bruta_produtos,
      CASE WHEN descr_natureza in ('VENDA FRANQUEADO') AND (NVL(vlrtot,0)>0) THEN
        ROUND((NVL(CAST(valor_nf AS NUMERIC), 0) / SUM(NVL(CAST(valor_nf AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER)))
        * SUM(NVL(CAST(royalties_taxa AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER))
        / (1 - NVL(CAST(valor_desconto AS NUMERIC) / NVL(CAST(vlrtot AS NUMERIC), 0), 0)),2)
        ELSE 0
      END  vlr_receita_bruta_servicos

from STATUS_PEDIDOS_SKU A
WHERE A.DTNEG_PEDIDO >= '01/01/2024'
AND A.COD_NATUREZA = 1010101
AND A.GRUPO_TOP = 'Vendas'

) TAB
GROUP BY NUNOTA_PEDIDO, GRUPO_TOP, COD_NATUREZA;

CREATE INDEX IDX_VM_RECEITA_BRUTA_PED_FILTER
ON VM_RECEITA_BRUTA_PED ( COD_NATUREZA, GRUPO_TOP);


CREATE INDEX IDX_VM_RECEITA_BRUTA_PED_FILTER2
ON VM_RECEITA_BRUTA_PED ( NUNOTA_PEDIDO, COD_NATUREZA, GRUPO_TOP);