-- $Id$
-- DESCRIPTION :
-- -------------
-- Vue pour liste des uee en cours sur le T robot dans écran SP_VISU_TROBOT               
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
-- 01a,19.03.15,rbel   creation                                   
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW V_SP_UEE_TROBOT AS 
SELECT emp.cod_siemens_aut,
       emp.cod_emp_trans_pal,
       emp.lib_emp,
       u.no_rmp no_pool_robot,
       emp.imm_ut,
       emp.libre_su_emp_trans_pal_1,
       u.no_uee,
       ut_sup.cod_ut,
         u.no_uee_ut_p1
       + NVL (
            (SELECT SUM (LENGTH (intercalaire))
               FROM pc_uee
              WHERE     cod_ut_sup = u.cod_ut_sup
                    AND typ_ut_sup = u.typ_ut_sup
                    AND intercalaire IS NOT NULL
                    AND no_uee_ut_p1 <= u.no_uee_ut_p1),
            0)
          no_uee_ut_p1,
       u.etat_atv_pc_uee,
       su_bas_etat_val_num(NVL(u.etat_atv_pc_uee,'CREA'),'PC_UEE') etat_atv_pc_uee_num,
       ut_sup.cod_up,
       s.cod_pro,
       s.cod_vl,
       su_bas_rch_lib_pro_court (s.cod_pro, s.cod_va, s.cod_vl) lib_pro
  FROM su_emp_trans_pal emp,
       pc_pic p,
       pc_pic_uee pu,
       pc_uee u,
       pc_ut ut_sup,
       se_ut ut,
       se_stk s
 WHERE     p.cod_ut_stk(+) = emp.imm_ut
       AND pu.cod_pic(+) = p.cod_pic
       AND u.no_uee(+) = pu.no_uee
       AND ut_sup.cod_ut(+) = u.cod_ut_sup
       AND ut_sup.typ_ut(+) = u.typ_ut_sup
       AND ut.cod_ut(+) = u.cod_ut
       AND ut.typ_ut(+) = u.typ_ut
       AND s.cod_ut(+) = ut.cod_ut
       AND s.typ_ut(+) = ut.typ_ut;
/
show errors;
