-- $Id$
-- DESCRIPTION :
-- -------------
-- Vue pour liste des ordre de transfert finaux vers un robot dans écran SP_VISU_TROBOT               
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
-- 01a,19.03.15,rbel   creation                                   
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW V_SP_ORD_VERS_TROBOT AS 
SELECT o.cod_ord_trf,
       o.cod_mag_dest,
       uee.no_uee,
       uee.cod_ut,
         uee.no_uee_ut_p1
       + NVL (
            (SELECT SUM (LENGTH (intercalaire))
               FROM pc_uee
              WHERE     cod_ut_sup = uee.cod_ut_sup
                    AND typ_ut_sup = uee.typ_ut_sup
                    AND intercalaire IS NOT NULL
                    AND no_uee_ut_p1 <= uee.no_uee_ut_p1),
            0)
          no_uee_ut_p1,
       uee.cod_ut_sup,
       s.cod_pro,
       s.cod_vl,
       su_bas_rch_lib_pro_court (s.cod_pro, s.cod_va, s.cod_vl) lib_pro,
       uee.no_train_seq,
       o.dat_crea,
       ut.dat_reg_ap,
       j.no_rmp
  FROM se_ord_trf o, pc_uee uee, se_stk s, pc_ut ut, pc_jtn_exp j
 WHERE o.cod_mag_trf IS NULL
   AND s.cod_ut = o.cod_ut_orig
   AND s.typ_ut = o.typ_ut_orig
   AND uee.cod_ut = o.cod_ut_orig
   AND uee.typ_ut = o.typ_ut_orig
   AND ut.cod_ut = uee.cod_ut_sup
   AND ut.typ_ut = uee.typ_ut_sup
   AND j.cod_emp = o.cod_emp_dest;
/
show errors;