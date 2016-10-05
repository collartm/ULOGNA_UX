-- $Id$
-- DESCRIPTION :
-- -------------
-- Vues utilisées pour l'écran PC_SQC_DET_UT
-- de visualisation des UT et des UEE de préparation de commandes
-- transitant par un séquenceur.
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
--  01c,12.03.15,mnev   ajout etat_pal_ut dans v_frm_pc_sqc_rch_best_ut.            
--  01b,02.03.15,mnev   mise à jour v_frm_pc_sqc_rch_best_ut
--  01a,06.10.14,croc   creation version prépa de commandes
-- -------------------------------------------------------------------------
--
-- Lecture des UT en attente de prise en charge par un sequenceur
-- ou déjà prises en charge (voir etat_atv_pc_ut) 
--
--
-- infos de confort (texte visualisé dans écran lg max de 100)
--
CREATE OR REPLACE VIEW v_pc_sqc_info_ut AS    
    SELECT c.cod_ut cod_ut,
           c.typ_ut typ_ut,
           cod_cli txt_01,
           cod_tou txt_02,
           no_cmd txt_03,
           no_com txt_04,
           TO_CHAR(TO_DATE(su_bas_gcl_ex_ent_dpt(c.no_dpt, 'DAT_EXP'), su_bas_get_date_format), 'DD/MM HH24:MI') txt_05    
     FROM pc_ut c;

--
-- infos de confort (texte visualisé dans écran lg max de 100)
--
CREATE OR REPLACE VIEW v_pc_sqc_info_cle AS    
    SELECT 
           a.no_uee cod_cle_sqc,
           a.no_com txt_01,
           NULL txt_02,
           NULL txt_03,
           NULL txt_04,
           NULL txt_05
    FROM pc_uee a;


-- 
-- vue 1 : vue des ut palettes pour visualisation écran PC_SQC_INTERFACE
--
CREATE OR REPLACE VIEW v_frm_pc_sqc_rch_best_ut AS
SELECT 
           v.cod_usn,
           v.lst_sqc,
           v.cod_ut,
           v.typ_ut,
           v.niv_prio,
           v.cle_tri,
           v.dat_crea dat_tri,
           v.lst_fct_lock,
           v.id_session_lock,
           v.etat_atv_pc_ut,
           v.cod_err_pc_ut,
           v.cod_pss_afc,
           v.dat_crea,
           v.etat_pal_ut,
           i.txt_01,
           i.txt_02,
           i.txt_03,
           i.txt_04,
           i.txt_05           
FROM v_pc_sqc_rch_best_ut_000 v,v_pc_sqc_info_ut i
WHERE  su_bas_rch_cle_atv_pss_2 (v.cod_pss_afc,'BFF','MODE_GES_BFF') = '2'
AND i.cod_ut = v.cod_ut
AND i.typ_ut = v.typ_ut
ORDER BY DECODE(etat_atv_pc_ut,'CREA',0,1), v.niv_prio, v.cle_tri, v.dat_tri;


--
-- Vue détail colis pour visualisation écran PC_SQC_INTERFACE
--
CREATE OR REPLACE VIEW v_frm_pc_sqc_lst_cle_ut AS
SELECT 
           v.cod_usn,
           v.cod_cle_sqc,
           v.cod_ut,
           v.typ_ut,
           v.cod_cnt_support,
           v.typ_haut_cnt,
           v.no_ord_cle,
           v.cod_pss_afc,
           v.etat_atv_pc_uee,
           v.cod_err_pc_uee,
           i.txt_01,
           i.txt_02,
           i.txt_03,
           i.txt_04,
           i.txt_05   
FROM v_pc_sqc_lst_cle_ut_000 v,v_pc_sqc_info_cle i
WHERE i.cod_cle_sqc = v.cod_cle_sqc
ORDER BY v.no_ord_cle;

-- a.no_ord_cle > 0 AND a.no_ord_cle < 999 AND a.etat_atv_pc_uee = 'ORDF' AND a.cod_err_pc_uee IS NULL;



--
-- ECRAN DYNAMIQUE PC_SUIVI_SQC
--
 
CREATE OR REPLACE VIEW v_frm_pc_sqc_ut_etat_purge AS
SELECT e.no_sqc,
       e.cod_ut_pal,
       e.typ_ut_pal,
       e.cod_usn,
       e.nb_dem,
       e.nb_dem_a_fac,
       e.nb_dem_a_trt,
       e.nb_cle,
       pc_bas_sqc_ut_lst_motif(e.cod_ut_pal,e.typ_ut_pal) lst_motif,
       e.nb_dem_att_rcy,
       e.nb_cle_cre,     
       e.nb_cle_sqm,     
       e.nb_cle_afv,     
       e.nb_cle_dmi,     
       e.nb_cle_chg,     
       e.nb_cle_dmo,
       f.ut_expedition,
       f.niv_prio,
       f.cle_tri,
       f.dat_tri,
       f.cod_err_pc_ut,
       DECODE(f.cod_err_pc_ut, NULL,'0','1') erreur,
       (SELECT min(b.dat_sel) 
          FROM pc_uee b 
         WHERE b.cod_ut_sup = f.cod_ut AND b.typ_ut_sup = f.typ_ut) dat_sel    
  FROM v_pc_sqc_ut_etat_purge e, v_pc_sqc_rch_best_ut_000 f
  WHERE e.cod_ut_pal = f.cod_ut AND e.typ_ut_pal = f.typ_ut;

  
--
-- Etat purge alvéoles
--

CREATE OR REPLACE VIEW v_frm_pc_sqc_alv_etat_purge
AS
   SELECT 
       e.no_sqc,
       e.no_elv,
       e.no_alv,
       e.cod_usn,
       e.nb_dem,
       e.nb_dem_a_trt,
       e.nb_cle,
       e.granul,
       e.motif,
       e.no_ord_min,
       a.no_sqm,
       a.cod_emp,
       a.nb_cle_att,
       a.dat_vid,
       a.dat_aff,
       a.dat_eci,
       a.dat_chg,a.dat_eco,
       a.tot_cle_ent_raz,
       a.tot_cle_sor_raz,
       a.tot_err_raz,
       a.etat_mar_arr_alv,
       a.etat_atv_pc_sqc_alv,
       a.qte_atv,
       a.qte_ref_atv,
       a.cod_pss_afc,
       a.cod_err_pc_sqc_alv
     FROM v_pc_sqc_alv_etat_purge e, vf_pc_sqc_alv a
    WHERE A.NO_SQC = e.no_sqc AND A.NO_ELV = e.no_elv AND A.NO_ALV = e.no_alv;  

--
-- Etat purge alvéoles
--

CREATE OR REPLACE VIEW v_frm_pc_sqc_lst_cle_detail
AS
SELECT 
   c.cod_cle_sqc,
   c.cod_ut_pal,
   c.typ_ut_pal,
   c.cod_cnt_support,
   c.typ_haut_cnt,
   c.no_sqc,
   c.no_elv,
   c.no_alv,
   c.no_sqm,
   c.no_ord_trait_cle,
   c.tx_occ,
   c.no_ord_ent_alv,
   c.dat_sqm,
   c.etat_atv_pc_sqc_cle,
   c.qte_atv,
   c.qte_ref_atv,
   c.cod_pss_afc,
   c.cod_err_pc_sqc_cle,
   c.motif_purge_cle,
   c.cod_usn,
   NVL(d.etat_atv_externe,(SELECT etat_atv_pc_uee 
                             FROM pc_uee 
                            WHERE no_uee = c.cod_cle_sqc)) etat_atv_externe,
   d.cod_ut_pic,
   d.typ_ut_pic,
   d.cod_ut_stk,
   d.typ_ut_stk,
   d.cod_pic,
   d.cod_ops,
   d.cod_dem_trf_in,
   d.cod_ord_trf_in,
   d.cod_dem_trf_out,
   d.cod_ord_trf_out
 FROM vf_pc_sqc_cle c,v_pc_sqc_lst_cle_detail d
 WHERE c.cod_cle_sqc = d.cod_cle_sqc(+);


--
-- ECRAN PC_SQC_ACTION
--
CREATE OR REPLACE VIEW v_frm_pc_sqc_action AS
SELECT 
       v.cod_ut_pal,
       v.typ_ut_pal,
       (SELECT a.txt_02 FROM v_pc_sqc_info_ut a WHERE a.cod_ut = v.cod_ut_pal AND a.typ_ut = v.typ_ut_pal) lib_ut, 
       SUM(DECODE(etat_atv_pc_sqc_cle,'CRE',1,'SQM',1,'AFV',1,0)) nb_cle_att,
       SUM(DECODE(etat_atv_pc_sqc_cle,'DMI',1,0)) nb_cle_dmi,
       SUM(DECODE(etat_atv_pc_sqc_cle,'CHG',1,0)) nb_cle_chg,
       SUM(DECODE(etat_atv_pc_sqc_cle,'DMO',1,0)) nb_cle_dmo 
FROM vf_pc_sqc_cle v
GROUP BY v.cod_ut_pal, v.typ_ut_pal;

--
-- ECRAN PC_SQC_ACTION_ALV
--
CREATE OR REPLACE VIEW v_frm_pc_sqc_action_alv AS
SELECT 
       v.no_sqc,
       v.no_elv,
       v.no_alv,
       NULL lib_alv, 
       nb_cle_att,
       nb_cle_tot,
       etat_atv_pc_sqc_alv,
       etat_mar_arr_alv 
FROM vf_pc_sqc_alv v;

--
-- ECRAN PC_SQC_ACTION_CLE
--
CREATE OR REPLACE VIEW v_frm_pc_sqc_action_cle AS
SELECT 
       v.no_sqc,
       v.no_elv,
       v.no_alv,
       NULL lib_cle, 
       cod_ut_trf,
       typ_ut_trf,
       etat_atv_pc_sqc_cle,
       cod_cle_sqc         
FROM vf_pc_sqc_cle v;

--
-- ECRAN GRAPHIQUE     
--
CREATE OR REPLACE VIEW v_frm_pc_sqc_etat AS
SELECT 
       su_bas_gcl_pc_sqc (no_sqc, 'COD_USN') cod_usn, 
       no_sqc, 
       SUM(DECODE(etat_atv_pc_sqc_alv,'VID',1,0)) nb_alv_vid,
       SUM(DECODE(etat_atv_pc_sqc_alv,'ECI',1,0)) nb_alv_eci,
       SUM(DECODE(etat_atv_pc_sqc_alv,'CHG',1,0)) nb_alv_chg,
       SUM(DECODE(etat_atv_pc_sqc_alv,'ECO',1,0)) nb_alv_eco,
       COUNT(*) nb_alv_tot
FROM vf_pc_sqc_alv v
GROUP BY  no_sqc;





