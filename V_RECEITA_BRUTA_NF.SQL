--ALTER SESSION SET CURRENT_SCHEMA=sankhya;


CREATE OR REPLACE VIEW V_RECEITA_BRUTA_NF  AS

select sum(vlr_receita_bruta_total) as RB_TOTAL,
       sum(vlr_receita_bruta_produtos) as RB_PRODUTOS,
       sum(vlr_receita_bruta_servicos ) as RB_SERVICOS,
       NUNOTA,
       PEDIDO
FROM (  
      SELECT NUNOTA, PEDIDO, CODPROD, SEQUENCIA, DESCRPROD,QTDNEG, 
           CASE WHEN DESCRNAT IN ('VENDA FRANQUEADO','VENDA SITE') THEN 
                ROUND(NVL((CAST(ROYALTIES_TAXA AS NUMERIC)/NVL(1- NVL(CAST(vlrdesc AS NUMERIC)/NVL(CAST(netprice AS NUMERIC),0),0),0)) ,0) + (CAST(netprice AS NUMERIC) + NVL(CAST(vlripi AS NUMERIC),0)),2) 
                ELSE 0
           END as vlr_receita_bruta_total,
           CASE WHEN  DESCRNAT IN ('VENDA FRANQUEADO','VENDA SITE') THEN
             (CAST(netprice AS NUMERIC) + NVL(CAST(vlripi AS NUMERIC),0))
             ELSE 0
           END as vlr_receita_bruta_produtos,
           CASE WHEN  DESCRNAT IN ('VENDA FRANQUEADO','VENDA SITE') THEN
                 NVL((CAST(ROYALTIES_TAXA AS NUMERIC)/ NVL(1- NVL(CAST(vlrdesc AS NUMERIC)/NVL(CAST(netprice AS NUMERIC),0),0),0)  ),0)
                 ELSE 0
           END  as vlr_receita_bruta_servicos
                    
      FROM V_NOTAS_VENDAS A  
      WHERE A.DTENTSAI >= '12/03/2025' 
      AND   NVL(PEDIDO,0) > 0
      AND DESCRNAT IN ('VENDA FRANQUEADO','VENDA SITE')
) TAB
GROUP BY NUNOTA, PEDIDO ;

