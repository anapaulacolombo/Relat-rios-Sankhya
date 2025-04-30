--ALTER SESSION SET CURRENT_SCHEMA=sankhya;


select cab.codemp, emp.NOMEFANTASIA, cab.nunota,cab.dtneg, 
       case when cab.CIF_FOB = 'C' then 'CIF' 
            when cab.CIF_FOB = 'F' then 'FOB'
            else ''
        end tipfrete,
        cab.codparc, par.nomeparc, dad.uf,
        cab.codtipoper, top.descroper,
        (SELECT trunc(max(l1.dt_log))
         FROM ad_statuscablog l1
         WHERE l1.descrlog = 'STATUS 6 - PEDIDO SEPARADO' and cab.nunota = l1.nunota)-
        (SELECT trunc(max(l2.dt_log))
           FROM ad_statuscablog l2
         WHERE l2.descrlog = 'STATUS 4 - PEDIDO APROVADO' and cab.nunota = l2.nunota) AS diascorridos, 
       var.nunota,
       cab_nf.numnota,
       ite.qtdneg,
       
       case when  conf.qtdvol > 0  then  ( conf.qtdvol||' - '|| conf.volume)
            else  ( cab.qtdvol ||' - '|| cab.volume)
       end  as volume,
       cab.vlrnota,
       nvl((select sum(qtdunitconf)  from ad_trasitemconf where nunota = cab.nunota),0) QtdConf,
       nvl((select sum(qtdneg) from tgfite nf_ite where nunota = cab_nf.nunota),0) Qtd_ite, 
       par.codtipparc,
       TPP.DESCRTIPPARC,
       log1.* from ( select dt_log, sta.descrlog, sta.nunota from ad_statuscablog sta)
       pivot
       ( max(dt_log) for descrlog in ('STATUS 1 - COTAÇÃO' as "COTACAO",
                        'STATUS 2 - PEDIDO CONFERIDO' as "PEDIDOCONFERIDO",
                        'STATUS 3 - PEDIDO CONFIRMADO' as "PEDIDOCONFIRMADO",
                        'STATUS 4 - PEDIDO APROVADO' as "PEDIDOAPROVADO",
                        'STATUS 5 - EM SEPARAÇÃO' as "EMSEPARACAO",
                        'STATUS 6 - PEDIDO SEPARADO' as "PEDIDOSEPARADO",
                        'STATUS 7 - LIBERADO FATURAMENTO' as "LIBERADOFATURAMENTO",
                        'STATUS 8 - FATURADO' as "FATURADO",
                        'STATUS 9 - COLETADO' as "COLETADO",
                        'STATUS 12 - AGENDADA COLETA TRANSPORTADORA' as "AGENDADACOLETA",
                        'STATUS 19 - Liberado Atendimento Parcial' as "LiberadoAtendimentoParcial",
                        'STATUS 20 - Liberado Atendimento Total' as "LiberadoAtendimentoTotal",
                        'STATUS 21 - Liberado Faturamento Parcial' as "LiberadoFaturamentoParcial",
                        'STATUS 22 - Liberado Faturamento Total' as "LiberadoFaturamentoTotal",
                        'STATUS 24 - Faturado Parcialmente' as "FaturadoParcialmente",
                        'STATUS 25 - Finalizado' as "Finalizado")
          )  log1,
          RB.RB_TOTAL, 
          RB.RB_PRODUTOS,
          RB.RB_SERVICOS
  
          
inner join tgfcab cab on cab.nunota = log1.nunota
inner join tgfnat nat on cab.codnat = nat.codnat
inner join (select sum(qtdneg) QtdNeg, nunota  from tgfite
            group by nunota
            ) ite on ite.nunota = cab.nunota
INNER JOIN TGFTOP TOP ON CAB.CODTIPOPER = TOP.CODTIPOPER AND CAB.DHTIPOPER = TOP.DHALTER
inner join tgfpar par on cab.codparc = par.codparc
left join tgfvar var on cab.nunota = var.nunotaorig and var.sequencia = 1
left join tgfcab cab_nf on var.nunota = cab_nf.nunota
inner join tsiemp emp on cab.codemp = emp.codemp
left  join tgftpp tpp on par.codtipparc = tpp.codtipparc
inner join DADOSPARCEIRO dad on cab.codparc = dad.codparc
left  join AD_TRASCONF conf on cab.nunota = conf.nunota
left join  RECEITA_BRUTA_PED  RB on RB.NUNOTA_PEDIDO = CAB.NUNOTA        
where cab.nunota= 834908

