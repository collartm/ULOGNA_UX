-- $Id$
-- DESCRIPTION :
-- -------------
-- Vues utilis�es pour l'entr�e des UT et des UEE de pr�paration de commandes
-- dans un s�quenceur.
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
-- 02b,01.02.16,pluc   Correctif sur exclusion : test = au lieu de >0 pour 
--                     su_bas_lst_intersection.
-- 02a,28.02.16,yque   Ajout exclusion palette d'un s�quenceur suivant famille ( libre_pc_sqc_2).
-- 01d,22.07.15,mnev   utilisation standard de libre_pc_sqc_1 avant ajout 
--                     d'un nouveau champ.
-- 01c,02.04.15,mnev   v_pc_sqc_rch_best_ut : ajout test sur non presence UEE 
--                     dans sequenceur
-- 01b,24.12.14,mnev   calcul niv_prio via pc_uee_det
-- 01a,12.08.14,mnev   creation version pr�pa de commandes
-- -------------------------------------------------------------------------

--
-- Lecture des UT en attente de prise en charge par un sequenceur
-- **************************************************************
-- vue sans clause where pour visualisation �cran et traitement de controle
--
CREATE OR REPLACE VIEW v_pc_sqc_rch_best_ut_000 AS
    SELECT /* v_pc_sqc_rch_best_ut_000*/
           c.cod_usn cod_usn,
           ';' || (SELECT LISTAGG(a.no_sqc, ';') WITHIN GROUP (ORDER BY a.no_sqc) liste
                     FROM pc_sqc a, pc_pos b
                    WHERE a.no_pos = b.no_pos AND NVL(a.libre_pc_sqc_1,'1') = '1' AND 
                          (NVL(LENGTH(su_bas_lst_intersection(detpal.lst_fam,a.libre_pc_sqc_2)),0)=0 OR a.libre_pc_sqc_2 IS NULL) AND
                          INSTR(b.lst_pss, ';' || c.cod_pss_afc || ';') > 0) || ';' lst_sqc,
           c.cod_ut,
           c.typ_ut,
           c.cod_up,
           c.typ_up,
           c.no_dpt,
           (SELECT min(a.niv_prio) 
              FROM pc_uee_det a, pc_uee b 
             WHERE a.no_uee = b.no_uee AND 
                   b.cod_ut_sup = c.cod_ut AND b.typ_ut_sup = c.typ_ut) niv_prio,
           c.dat_crea dat_tri,
           c.lst_fct_lock,
           c.id_session_lock,
           c.etat_atv_pc_ut,
           c.cod_err_pc_ut,
           c.cod_pss_afc,
           c.dat_crea,
           c.etat_pal_ut,
           c.ut_expedition,
           pc_bas_sqc_tri_ut (c.cod_ut, c.typ_ut, c.no_dpt, c.dat_crea) cle_tri,
           (SELECT count(*) 
            FROM pc_uee a 
            WHERE a.cod_usn = c.cod_usn AND a.cod_ut_sup = c.cod_ut AND a.typ_ut_sup = c.typ_ut) nb_cle
    FROM vf_pc_ut c,
--$MOD YQUE 28012016 AJOUT EXCLUSION FAMILLES PAR POOL
     (SELECT e.cod_ut_sup,e.typ_ut_sup,concatcol(distinct p.cod_dim_pro) lst_fam 
                      FROM su_pro p 
                      JOIN pc_uee_det d ON p.cod_pro = d.cod_pro_res
                      JOIN pc_uee e ON e.no_uee = d.no_uee
                      group by e.cod_ut_sup,e.typ_ut_sup
                      ) detpal
    WHERE detpal.cod_ut_sup = c.cod_ut and detpal.typ_ut_sup = c.typ_ut;

--
-- UT EN ATTENTE DE PRISE EN CHARGE SEQUENCEUR
--
-- vue avec clause de filtrage pour le traitement d'entr�e des UT
--
CREATE OR REPLACE VIEW v_pc_sqc_rch_best_ut AS
    SELECT c.cod_usn,
           c.lst_sqc,
           c.cod_ut,
           c.typ_ut,
           c.cod_up,
           c.typ_up,
           niv_prio,
           c.dat_tri,
           c.cle_tri,
           c.lst_fct_lock,
           c.id_session_lock,
           c.etat_atv_pc_ut,
           c.cod_err_pc_ut,
           c.cod_pss_afc,
           c.dat_crea,
           c.nb_cle
    FROM v_pc_sqc_rch_best_ut_000 c, pc_up u
   WHERE c.etat_atv_pc_ut = 'CREA' AND c.cod_err_pc_ut IS NULL AND c.etat_pal_ut = '0' AND
         c.ut_expedition = '1' AND c.cod_up IS NOT NULL AND
         EXISTS (SELECT 1 FROM ex_ent_dpt d WHERE d.no_dpt = c.no_dpt AND d.dat_exp < SYSDATE + NVL(su_bas_rch_action_ctx('SQC_ACT_TRACE_CLE','X08'),9999)) AND
         su_bas_rch_cle_atv_pss_2 (c.cod_pss_afc,'BFF','MODE_GES_BFF') = '2' AND
         NOT EXISTS (SELECT '1'
                       FROM pc_uee u
                      WHERE u.cod_up = c.cod_up AND u.typ_up = c.typ_up AND
                            (u.etat_atv_pc_uee <> 'ORDF' OR u.cod_err_pc_uee IS NOT NULL)) AND
         NOT EXISTS (SELECT '1'
                       FROM pc_uee u
                      WHERE u.cod_up = c.cod_up AND u.typ_up = c.typ_up AND 
                            EXISTS (SELECT 1 FROM pc_sqc_cle WHERE cod_cle_sqc = u.no_uee)) AND
         c.cod_up = u.cod_up AND c.typ_up = u.typ_up AND u.etat_up_complete = '1'
    ORDER BY c.niv_prio, c.cle_tri, c.dat_tri;

--
-- Lecture des cles (colis) � traiter
-- ********************************** 
-- vue sans clause where pour visualisation �cran et traitement de controle
--
CREATE OR REPLACE VIEW v_pc_sqc_lst_cle_ut_000 AS
    SELECT
           a.cod_usn,
           a.no_uee cod_cle_sqc,
           ';' || (SELECT LISTAGG(c.no_sqc, ';') WITHIN GROUP (ORDER BY c.no_sqc) liste
                     FROM pc_sqc c, pc_pos b
                    WHERE c.no_pos = b.no_pos AND
                          INSTR(b.lst_pss, ';' || a.cod_pss_afc || ';') > 0) || ';' lst_sqc,
           a.cod_ut_sup cod_ut,
           a.typ_ut_sup typ_ut,
           a.cod_up,
           a.typ_up,
           (SELECT MIN(b.cod_cnt_trf)
              FROM pc_pic b, pc_pic_uee c
             WHERE b.cod_pic = c.cod_pic AND c.no_uee = a.no_uee) cod_cnt_support,
           (SELECT MIN(SUBSTR(n.lst_typ_haut_cnt,NVL(INSTR(n.lst_typ_haut_cnt,';',1,1),0) + 1, NVL(INSTR(n.lst_typ_haut_cnt,';',1,2),0) - NVL(INSTR(n.lst_typ_haut_cnt,';',1,1),0) - 1))
              FROM su_cnt n, pc_pic b, pc_pic_uee c, su_cnt d
             WHERE n.cod_cnt = DECODE(d.typ_contenu,'I',b.cod_cnt_trf,a.cod_cnt) AND b.cod_cnt_trf = d.cod_cnt AND b.cod_pic = c.cod_pic AND c.no_uee = a.no_uee) typ_haut_cnt,
           a.no_uee_ut_p1 no_ord_cle,
           a.cod_pss_afc cod_pss_afc,
           a.no_uee_ut_p1,
           a.etat_atv_pc_uee,
           a.cod_err_pc_uee
    FROM vf_pc_uee a;

--
-- CLE EN ATTENTE DE PRISE EN CHARGE SEQUENCEUR
--
-- vue avec clause de filtrage pour le traitement d'entr�e des cles 
--
CREATE OR REPLACE VIEW v_pc_sqc_lst_cle_ut AS
    SELECT
           a.cod_usn,
           a.cod_cle_sqc,
           a.lst_sqc,
           a.cod_ut,
           a.typ_ut,
           a.cod_up,
           a.typ_up,
           a.cod_cnt_support,
           a.typ_haut_cnt,
           a.no_ord_cle,
           a.cod_pss_afc,
           a.etat_atv_pc_uee,
           a.cod_err_pc_uee
    FROM v_pc_sqc_lst_cle_ut_000 a
    WHERE a.no_ord_cle > 0 AND a.no_ord_cle < 999 AND a.etat_atv_pc_uee = 'ORDF' AND a.cod_err_pc_uee IS NULL;

--
-- Donnees externes concernant les cles
-- ************************************
--
CREATE OR REPLACE VIEW v_pc_sqc_lst_cle_detail AS
    SELECT a.cod_usn,
           a.no_uee cod_cle_sqc,
           a.etat_atv_pc_uee etat_atv_externe,
           c.cod_ut_stk cod_ut_pic,
           c.typ_ut_stk typ_ut_pic,
           a.cod_ut cod_ut_stk,
           a.typ_ut typ_ut_stk,
           a.cod_ut_sup cod_ut_sup,
           a.typ_ut_sup typ_ut_sup,
           c.cod_pic,
           c.cod_ops,
           (SELECT MAX(cod_dem_trf) cod_dem_trf
              FROM se_dem_trf
             WHERE ref_trf_5 = c.cod_ops AND etat_dem_trf < '900')
              cod_dem_trf_in,
           (SELECT MAX(cod_ord_trf) cod_ord_trf
              FROM se_ord_trf
             WHERE ref_trf_5 = c.cod_ops)
              cod_ord_trf_in,
           (SELECT MAX(cod_dem_trf) cod_dem_trf
              FROM se_dem_trf s
             WHERE s.cod_ut_orig = a.cod_ut AND s.typ_ut_orig = a.typ_ut)
              cod_dem_trf_out,
           (SELECT MAX(cod_ord_trf) cod_ord_trf
              FROM se_ord_trf s
             WHERE s.cod_ut_orig = a.cod_ut AND s.typ_ut_orig = a.typ_ut)
              cod_ord_trf_out
      FROM vf_pc_uee a, pc_pic_uee b, pc_pic c
     WHERE -- su_bas_rch_cle_atv_pss_2 (NVL(a.cod_pss_avant_iter, a.cod_pss_afc), 'BFF', 'MODE_GES_BFF') = '2' AND 
           a.no_uee = b.no_uee AND b.cod_pic = c.cod_pic;




