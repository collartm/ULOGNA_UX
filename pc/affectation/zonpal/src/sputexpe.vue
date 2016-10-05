-- $Id$
-- DESCRIPTION :
-- -------------
-- Ces vues sont utilisées pour l'écran de rebut colis
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
--
-- 01a,10.07.2014,pluc   version initiale
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW V_SP_UT_EXPE AS
SELECT p.cod_ut, p.typ_ut, id_sscc, cod_cli, etat_atv_pc_ut, dat_top_ctl,
       su_bas_gcl_su_tiers ( cod_cli, 'C', 'LIB_TIERS') lib_des,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des (p.cod_ut,
                                             p.typ_ut,
                                             p.mode_pal_ut,
                                             0,
                                            'ADR_1') adr1_des,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des (p.cod_ut,
                                             p.typ_ut,
                                             p.mode_pal_ut,
                                             0,
                                             'VILLE') ville_des,
      typ_up, cod_ut_sup, typ_ut_sup, DECODE(typ_up, 'P2', 'MULTI', cod_pss_afc) cod_pss_afc, 
      p.dat_maj, s.dat_der_imp, p.lib_ut, p.lib_zon_pal,
      TO_DATE(su_bas_gcl_ex_ent_dpt( p.no_dpt, 'DAT_EXP'), su_bas_get_date_format) dat_exp,
      ( SELECT SUM(s.nb_col_val)
        FROM (SELECT e.cod_ut_sup, e.typ_ut_sup, e.nb_col_val
              FROM   pc_uee e
              WHERE e.etat_atv_pc_uee != 'PRP0'
              UNION ALL
              SELECT t.cod_ut_sup, t.typ_ut_sup, e.nb_col_val
              FROM   pc_uee e, pc_ut t
              WHERE  e.cod_ut_sup = t.cod_ut
              AND    e.typ_ut_sup = t.typ_ut
              AND    t.cod_ut_sup IS NOT NULL
              AND    e.etat_atv_pc_uee != 'PRP0' ) s
        WHERE s.cod_ut_sup = p.cod_ut
        AND   s.typ_ut_sup = p.typ_ut
        ) nb_colis
/*
         WHERE  (e.cod_ut_sup, e.typ_ut_sup) IN
                      (SELECT a.cod_ut, a.typ_ut
                       FROM pc_ut a
                       CONNECT BY PRIOR a.cod_ut = a.cod_ut_sup AND
                                  PRIOR a.typ_ut = a.typ_ut_sup
                        START WITH A.cod_ut = p.cod_ut AND A.typ_ut = p.typ_ut
                      )
               AND e.etat_atv_pc_uee != 'PRP0') nb_colis
               */
from pc_ut p, (SELECT r.val_par cod_ut, MAX(l.dat_crea) dat_der_imp
               FROM   su_spool l, su_spool_par r
               WHERE  l.no_spool = r.no_spool
               AND    r.cod_par  ='p_cod_ut'
               AND    r.typ_par  = 'DOC'
               GROUP BY r.val_par
              ) s
WHERE p.cod_ut  = s.cod_ut (+)
/
show errors;

CREATE OR REPLACE VIEW V_SP_DET_UT_EXPE AS
SELECT   a.cod_ut_sup, a.typ_ut_sup, b.cod_pro_res, c.lib_pro, b.cod_vl_res, 
         SUM(CASE WHEN su_bas_etat_val_num(a.etat_atv_pc_uee, 'PC_UEE') 
                       >= su_bas_etat_val_num('TEST_FIN_PREPA', 'PC_UEE') THEN a.nb_col_val ELSE 0 END) qte_prp,
         SUM(CASE WHEN su_bas_etat_val_num(a.etat_atv_pc_uee, 'PC_UEE') 
                       >= su_bas_etat_val_num('LIVRAISON', 'PC_UEE') THEN a.nb_col_val ELSE 0 END) qte_pal
FROM     pc_uee a, pc_uee_det b, su_pro c
WHERE    a.no_uee      = b.no_uee
AND      b.cod_pro_res = c.cod_pro
AND      a.etat_atv_pc_uee != 'PRP0'
GROUP BY a.cod_ut_sup, a.typ_ut_sup, b.cod_pro_res, c.lib_pro, b.cod_vl_res
UNION ALL
SELECT   t.cod_ut_sup, t.typ_ut_sup, b.cod_pro_res, c.lib_pro, b.cod_vl_res, 
         SUM(CASE WHEN su_bas_etat_val_num(a.etat_atv_pc_uee, 'PC_UEE') 
                       >= su_bas_etat_val_num('TEST_FIN_PREPA', 'PC_UEE') THEN a.nb_col_val ELSE 0 END) qte_prp,
         SUM(CASE WHEN su_bas_etat_val_num(a.etat_atv_pc_uee, 'PC_UEE') 
                       >= su_bas_etat_val_num('LIVRAISON', 'PC_UEE') THEN a.nb_col_val ELSE 0 END) qte_pal
FROM     pc_ut t, pc_uee a, pc_uee_det b, su_pro c
WHERE    a.no_uee      = b.no_uee
AND      b.cod_pro_res = c.cod_pro
AND      a.etat_atv_pc_uee != 'PRP0'
AND      a.cod_ut_sup  = t.cod_ut
AND      a.typ_ut_sup  = t.typ_ut
GROUP BY t.cod_ut_sup, t.typ_ut_sup, b.cod_pro_res, c.lib_pro, b.cod_vl_res
/
show errors;

