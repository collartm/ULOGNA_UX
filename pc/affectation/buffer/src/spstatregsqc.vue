-- $Id$
-- DESCRIPTION :
-- -------------
-- Vue pour analyse régulation entrée/sortie séquenceur               
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
-- 01a,28.04.15,rbel   creation                                   
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW V_SP_STAT_REG_SQC AS
SELECT v.no_uee,
       v.cod_ops,
       v.no_com,
       v.dat_crea_com,
       v.dat_exp,
       v.cod_ut_sup,
       v.no_uee_ut_p1,
       v.dat_ordo,
       v.dat_reg_ent_sqc,
       v.no_sqc,
       v.dat_sortie_flexy,
       v.dat_tir_rp_ent_sqc,
       v.dat_ent_sqc,
       v.dat_reg_sor_sqc,
       v.dat_sor_sqc,
       v.dat_tir_robot,
       v.dat_der_tir_robot,
       v.ref_trf_1,
       v.cod_emp_flexy,
       v.flexy,
       v.cod_emp_sqc,
       v.ascenseur_sqc,
       v.no_sqm,
       v.no_ord_sqm,
       v.dat_crea_ord_sortie_flexy,
       v.nb_ut_utilise
  FROM table(sp_bas_stat_reg_sqc) v;
/
show errors;
