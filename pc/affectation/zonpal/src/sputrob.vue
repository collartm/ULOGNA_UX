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

CREATE OR REPLACE VIEW V_SP_UT_ROB AS
SELECT p.cod_ut, p.typ_ut, p.id_sscc, p.no_rmp, p.no_dpt, t.dat_exp, p.cod_cli, p.etat_atv_pc_ut, 
       p.cod_tou, s.prio, p.no_cmd, p.no_com,
       --NVL(p.dat_reg_ap, p.dat_reg_av) dat_sel,
       p.dat_reg_av dat_sel,
       p.libre_pc_ut_3 no_rmp_exp,
      /*
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des (p.cod_ut,
                                             p.typ_ut,
                                             p.mode_pal_ut,
                                             0,
                                            'RS_1') lib_des,
                                           */
       su_bas_gcl_su_tiers ( p.cod_cli, 'C', 'LIB_TIERS') lib_des,
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
       CASE WHEN su_bas_etat_val_num(p.etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('SEL_REGUL_MODE2', 'PC_UT') THEN 'ECI'
       WHEN su_bas_etat_val_num(p.etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('REGULEE_MODE2', 'PC_UT') THEN 'CHG'
       WHEN s.nb_uee_eco > 0 THEN 'ECO'
       WHEN s.nb_uee_erb > 0 THEN 'EPAL' 
       ELSE 'FPAL' END etat_ut_robot,
       CASE WHEN p.cod_ut_sup IS NOT NULL THEN 'D' ELSE NULL END compl_debord,
       s.motif_purge_cle,
       s.nb_uee_eci,
       s.nb_uee_chg,
       s.nb_uee_eco,
       s.nb_uee_erb,
       s.nb_uee_pal,
       s.nb_uee,
       ROUND((s.nb_uee_pal / s.nb_uee) *100) pct_avct
FROM  ex_ent_dpt t, pc_ut p, (SELECT e.cod_ut_sup cod_ut, e.typ_ut_sup typ_ut, 
                       MIN(t.niv_prio) prio, MIN(e.dat_sel) dat_sel, 
                       MIN(NVL(s.motif_purge_cle, e.motif_purge_uee)) motif_purge_cle,
                       SUM(CASE WHEN su_bas_etat_val_num(NVL(s.etat_atv_pc_sqc_cle, 'DMO'), 'PC_SQC_CLE') <= su_bas_etat_val_num('SET_APPEL', 'PC_SQC_CLE') THEN 1 ELSE 0 END) nb_uee_eci,
                       SUM(DECODE(s.etat_atv_pc_sqc_cle,'CHG', 1, 0)) nb_uee_chg,
                       SUM(DECODE(s.etat_atv_pc_sqc_cle,'DMO', 1, 0)) nb_uee_eco,
                       SUM(CASE WHEN e.etat_atv_pc_uee ='PRPS' AND s.etat_atv_pc_sqc_cle IS NULL THEN 1 ELSE 0 END) nb_uee_erb,
                       SUM(DECODE(e.etat_atv_pc_uee, 'LVZP', 1, 'CPAL', 1, 0)) nb_uee_pal,
                       COUNT(e.no_uee) nb_uee
                FROM   pc_sqc_cle s, pc_uee_det t, pc_uee e
                WHERE  e.etat_atv_pc_uee != 'PRP0'
                AND e.no_uee = t.no_uee
                AND   e.no_uee = s.cod_cle_sqc(+)
                GROUP BY e.cod_ut_sup, e.typ_ut_sup) s
WHERE no_rmp IS NOT NULL
AND su_bas_etat_val_num(p.etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('CONSOLIDE', 'PC_UT')
AND p.etat_atv_pc_ut != 'PRP0'
AND p.cod_ut = s.cod_ut
AND p.typ_ut = s.typ_ut
AND p.no_dpt = t.no_dpt
/
show errors;

