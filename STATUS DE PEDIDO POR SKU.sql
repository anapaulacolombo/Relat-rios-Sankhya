--ALTER SESSION SET CURRENT_SCHEMA=sankhya;SELECT T.*, CASE WHEN T.NUMNOTA IS NULL THEN 'Não' ELSE 'Sim' END AS FATURADO,
CASE WHEN CONTROLE <> ' ' THEN NULL ELSE
(SELECT SUM(I.QTDNEG - I.QTDCONFERIDA) FROM TGFITE I WHERE I.NUNOTA = T.NUNOTA AND I.CONTROLE = ' ' AND I.CODPROD = T.CODPROD) END AS QTDLIBERADA
FROM
(select cab.codemp,
       tgfite.controle,
       tsiemp.razaosocial,
       cab.nunota,
       cab.dtneg,
       cab.AD_DHAPROVACAO,
       cab.codparc,
       par.nomeparc,
       parmat.codparc as codparcmatriz,
       parmat.nomeparc as nomeparcmatriz,
       par.ad_percservicos,
       cab.codvend,
       ven.apelido,
       t.grupo,
        cab.codtipoper,
       t.descroper,
       cab.codnat,
       tgfnat.descrnat,
       par.codtipparc,
       tgftpp.descrtipparc,
       cab.pendente,
      round(((TGFITE.Vlrtot + TGFITE.VLRIPI + TGFITE.VLRSUBST) - TGFITE.VLRDESC) + 
      case when cab.tipfrete = 'N' THEN 0 ELSE round(cab.vlrfrete / (select count(1) from tgfite where nunota = cab.nunota),2) end,2) VALOR_NF , 
      cab.vlrfrete VALOR_FRETE,
      DIN.VLRICMS VALOR_ICMS,  
      IMP.IPI VALOR_IPI,
      IMP.ST VALOR_ST,
      TGFITE.VLRDESC VALOR_DESCONTO,
      DIN.BASEICMS vlr_nf_sem_imp , 
     (TGFITE.Vlrtot - TGFITE.VLRDESC) VLR_LIQ_ITEM,
      CASE WHEN cab.codtipoper in (3119) then 0       
           ELSE round(( TGFITE.Vlrtot)  *  nvl(PAR.AD_PERCSERVICOS,0),2) 
      END Royalties_Taxa,
      null as numnota, null as dt_faturamento, 
      cab.ad_statusped || ' -' ||
      (select p.opcao from tddopc p
         where p.nucampo in
               (select c.nucampo
                  from tddcam c
                 where c.nometab = 'TGFCAB'
                   and lower(c.nomecampo) = 'ad_statusped')
           and p.valor = cab.ad_statusped) AS STATUS,
       tgfite.sequencia SEQ,
       tgfite.codprod, tgfpro.descrprod,tgfpro.marca, 
       tgfite.qtdneg, tgfite.vlrunit, tgfite.vlrtot,
       RB.RB_TOTAL, 
       RB.RB_PRODUTOS,
       RB.RB_SERVICOS

  from tgfcab cab 
  INNER JOIN tgfpar par ON cab.codparc  = par.codparc
  INNER JOIN tgfven ven ON cab.codvend  = ven.codvend
  INNER JOIN tgftop t ON  cab.codtipoper   = t.codtipoper and cab.dhtipoper  = t.dhalter 
  INNER JOIN tsiemp ON cab.codemp       = tsiemp.codemp
  INNER JOIN tgfnat ON cab.codnat       = tgfnat.codnat
  INNER JOIN tgftpp ON par.codtipparc   = tgftpp.codtipparc
  LEFT JOIN tgfpar parmat ON par.codparcmatriz = parmat.codparc
  INNER JOIN tgfite ON cab.nunota       = tgfite.nunota and cab.codemp = tgfite.codemp
  INNER JOIN tgfpro ON tgfite.codprod   = tgfpro.codprod
  LEFT  JOIN (SELECT SUM(BASERED) BASEICMS, SUM(VALOR) VLRICMS,            
            CODIMP, SEQUENCIA, NUNOTA
            FROM TGFDIN
            GROUP BY CODIMP, SEQUENCIA, NUNOTA
   ) DIN ON cab.NUNOTA = DIN.NUNOTA AND DIN.SEQUENCIA = TGFITE.SEQUENCIA AND DIN.CODIMP = 1
  LEFT JOIN OutrosImpostosPV IMP on TGFite.nunota = IMP.nunota and TGFite.sequencia = imp.sequencia  
  LEFT JOIN V_RECEITA_BRUTA_PED_SKU RB on RB.NUNOTA_PEDIDO = CAB.NUNOTA AND RB.CODPROD = TGFITE.CODPROD AND RB.SEQ = TGFITE.SEQUENCIA
   where t.AD_RELANALFAT  = 'S'
   and cab.tipmov         = 'P'
   and tgfite.pendente    = 'S'
   and t.ativo            =  'S'
   and tgftpp.codtipparc not in ('10101011')
   --and cab.ad_statusped <= 7   
   and (cab.ad_statusped IN :STATUS )
   and (cab.codemp         =:CODEMP OR :CODEMP IS NULL)
   and cab.dtneg between    :DATA and :DATAFIM
   and (cab.nunota         =:NUNOTA OR :NUNOTA IS NULL) 
   and (cab.codparc        =:CODPARC OR :CODPARC IS NULL)
 

union all

select distinct cab.codemp,
    tgfite.controle,
       tsiemp.razaosocial,
       cab.nunota,
       cab.dtneg,
       cab.AD_DHAPROVACAO,
       cab.codparc,
       par.nomeparc,
       parmat.codparc as codparcmatriz,
       parmat.nomeparc as nomeparcmatriz,
       nvl(PAR.AD_PERCSERVICOS,0) AD_PERCSERVICOS,
       cab.codvend,
       ven.apelido,
       t.grupo,
       cab.codtipoper,
       t.descroper,
       cab.codnat,
       tgfnat.descrnat,
       par.codtipparc,
       tgftpp.descrtipparc,
       cab.pendente,
      round(((TGFITE.Vlrtot + TGFITE.VLRIPI + TGFITE.VLRSUBST) - TGFITE.VLRDESC) + 
      case when nf.tipfrete = 'N' THEN 0 ELSE round(nf.vlrfrete / (select count(1) from tgfite where nunota = nf.nunota),2) end,2) VALOR_NF , 
      case when nf.tipfrete = 'N' THEN 0 ELSE round(nf.vlrfrete / (select count(1) from tgfite where nunota = nf.nunota),2) end VALOR_FRETE, 
      DIN.VLRICMS VALOR_ICMS,  
      IMP.IPI VALOR_IPI,
      IMP.ST VALOR_ST,
      round(TGFITE.VLRDESC,2) VALOR_DESCONTO,
      DIN.BASEICMS vlr_nf_sem_imp ,
     (TGFITE.Vlrtot - TGFITE.VLRDESC) VLR_LIQ_ITEM,
      CASE WHEN cab.codtipoper in (3119) then 0       
           ELSE round((TGFITE.Vlrtot) * PAR.AD_PERCSERVICOS,2) 
      END Royalties_Taxa,
      nf.numnota, nf.dtentsai dt_faturamento, 
      cab.ad_statusped || ' -' ||
       (select p.opcao
          from tddopc p
          where p.nucampo in
               (select c.nucampo
                  from tddcam c
                  where c.nometab = 'TGFCAB'
                  and lower(c.nomecampo) = 'ad_statusped')
          and p.valor = cab.ad_statusped) status,
      tgfite.sequencia AS SEQ, 
      tgfite.codprod, tgfpro.descrprod, tgfpro.marca, 
      tgfite.qtdneg, tgfite.vlrunit, tgfite.vlrtot,
      RB.RB_TOTAL, 
      RB.RB_PRODUTOS,
      RB.RB_SERVICOS      
  from tgfcab cab
  INNER JOIN tgfpar par ON cab.codparc  = par.codparc
  INNER JOIN tgfven ven ON cab.codvend  = ven.codvend
  INNER JOIN tgftop t ON  cab.codtipoper   = t.codtipoper and cab.dhtipoper  = t.dhalter 
  INNER JOIN tsiemp ON cab.codemp       = tsiemp.codemp
  INNER JOIN tgfnat ON cab.codnat       = tgfnat.codnat
  INNER JOIN tgftpp ON par.codtipparc   = tgftpp.codtipparc
  INNER JOIN tgfvar ON cab.nunota       = tgfvar.nunotaorig
  INNER JOIN tgfcab nf ON tgfvar.nunota    = nf.nunota
  LEFT JOIN tgfpar parmat ON par.codparcmatriz = parmat.codparc
  INNER JOIN tgfite ON nf.nunota       = tgfite.nunota and nf.codemp = tgfite.codemp
  INNER JOIN tgfpro ON tgfite.codprod   = tgfpro.codprod
  LEFT  JOIN (SELECT SUM(BASERED) BASEICMS, SUM(VALOR) VLRICMS,            
            CODIMP, SEQUENCIA, NUNOTA
            FROM TGFDIN
            GROUP BY CODIMP, SEQUENCIA, NUNOTA
   ) DIN ON NF.NUNOTA = DIN.NUNOTA AND DIN.SEQUENCIA = TGFITE.SEQUENCIA AND DIN.CODIMP = 1
  LEFT JOIN OutrosImpostosPV IMP on TGFite.nunota = IMP.nunota and TGFite.sequencia = imp.sequencia
  LEFT JOIN (select sum(vlrnota) VLR_SERVICOS, ad_nunotaorig 
            from tgfcab 
            where tipmov = 'V'
            group by ad_nunotaorig
           ) Serv on Serv.Ad_Nunotaorig = cab.nunota 
LEFT JOIN V_RECEITA_BRUTA_PED_SKU RB on RB.NUNOTA_PEDIDO = CAB.NUNOTA AND RB.CODPROD = TGFITE.CODPROD AND RB.SEQ = TGFITE.SEQUENCIA
 where t.ativo          = 'S'
   and t.AD_RELANALFAT  = 'S'
   and cab.tipmov       = 'P'
   and tgftpp.codtipparc not in ('10101011')
   and cab.ad_statusped >= 8
   and (cab.ad_statusped IN :STATUS )
   and (cab.codemp         =:CODEMP OR :CODEMP IS NULL)
   and cab.dtneg  between   :DATA and :DATAFIM
   and (cab.nunota         =:NUNOTA OR :NUNOTA IS NULL)
   and (cab.codparc        =:CODPARC OR :CODPARC IS NULL)
) T