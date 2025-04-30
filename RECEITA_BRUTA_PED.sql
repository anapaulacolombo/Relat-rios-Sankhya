--ALTER SESSION SET CURRENT_SCHEMA=sankhya;

CREATE OR REPLACE VIEW RECEITA_BRUTA_PED AS 
select sum(vlr_receita_bruta_total) as RB_TOTAL,
       sum(vlr_receita_bruta_produtos) as RB_PRODUTOS,
       sum(vlr_receita_bruta_servicos ) as RB_SERVICOS,
       NUNOTA_PEDIDO
FROM (       
select NUNOTA_PEDIDO, CODPROD,DESCRPROD,QTDNEG, 
      CASE WHEN  descr_natureza in ('VENDA FRANQUEADO') THEN 
             ROUND((NVL(CAST(vlrtot AS NUMERIC), 0) + NVL(CAST(valor_ipi AS NUMERIC), 0)) +
             (NVL(CAST(valor_nf AS NUMERIC), 0) / SUM(NVL(CAST(valor_nf AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER)))
            * SUM(NVL(CAST(royalties_taxa AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER))
           / (1 - NVL(CAST(valor_desconto AS NUMERIC) / NVL(CAST(vlrtot AS NUMERIC), 0), 0)),2) 
      END vlr_receita_bruta_total,
      CASE WHEN descr_natureza in ('VENDA FRANQUEADO') THEN
          ROUND((NVL(CAST(vlrtot AS NUMERIC), 0) + NVL(CAST(valor_ipi AS NUMERIC), 0)),2)
      END  vlr_receita_bruta_produtos,
      CASE WHEN descr_natureza in ('VENDA FRANQUEADO') THEN
        ROUND((NVL(CAST(valor_nf AS NUMERIC), 0) / SUM(NVL(CAST(valor_nf AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER)))
        * SUM(NVL(CAST(royalties_taxa AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER))
        / (1 - NVL(CAST(valor_desconto AS NUMERIC) / NULLIF(CAST(vlrtot AS NUMERIC), 0), 0)),2)
      END  vlr_receita_bruta_servicos      
   
from STATUS_PEDIDOS_SKU A  
WHERE A.DTNEG_PEDIDO >= '01/01/2025' ) TAB
GROUP BY NUNOTA_PEDIDO
