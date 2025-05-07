--ALTER SESSION SET CURRENT_SCHEMA=sankhya;

CREATE OR REPLACE VIEW V_RECEITA_BRUTA_PED_SKU   AS
select NUNOTA_PEDIDO,SEQ,  CODPROD,DESCRPROD,QTDNEG, 
      CASE WHEN  descr_natureza in ('VENDA FRANQUEADO') AND (NVL(vlrtot,0)>0) THEN 
             ROUND((NVL(CAST(vlrtot AS NUMERIC), 0) + NVL(CAST(valor_ipi AS NUMERIC), 0)) +
             (NVL(CAST(valor_nf AS NUMERIC), 0) / SUM(NVL(CAST(valor_nf AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER)))
            * SUM(NVL(CAST(royalties_taxa AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER))
           / (1 - NVL(CAST(valor_desconto AS NUMERIC) / NVL(CAST(vlrtot AS NUMERIC), 0), 0)),2) 
          ELSE 0 
      END RB_TOTAL,
      CASE WHEN descr_natureza in ('VENDA FRANQUEADO') THEN
          ROUND((NVL(CAST(vlrtot AS NUMERIC), 0) + NVL(CAST(valor_ipi AS NUMERIC), 0)),2)
          ELSE 0
      END  RB_PRODUTOS,
      CASE WHEN descr_natureza in ('VENDA FRANQUEADO') AND (NVL(vlrtot,0)>0)  THEN
        ROUND((NVL(CAST(valor_nf AS NUMERIC), 0) / SUM(NVL(CAST(valor_nf AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER)))
        * SUM(NVL(CAST(royalties_taxa AS NUMERIC), 0)) OVER (PARTITION BY CAST(nunota_pedido AS INTEGER))
        / (1 - NVL(CAST(valor_desconto AS NUMERIC) / NULLIF(CAST(vlrtot AS NUMERIC), 0), 0)),2)
        ELSE 0
      END  RB_SERVICOS      
   
from STATUS_PEDIDOS_SKU A  
WHERE A.DTNEG_PEDIDO >= '01/01/2025' 
