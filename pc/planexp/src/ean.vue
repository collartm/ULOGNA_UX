-- $Id$
-- DESCRIPTION :
-- -------------
-- Ces vues sont utilisées par la fiche logistique
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
-- 03h,15.01.14,mnev   Prise en compte des typ_val_pc à 'S'.          
-- 03g,17.01.12,mnev   Calcul du code tournée via pc_ent_com          
-- 03f,03.05.11,alfl   Vue pour regrouper les conditions prise en compte pc_val_pc
-- 03e,01.02.10,tcho   Rajout du poids de la charge de la palette
-- 03d,11.03.09,mnev   simplification nom colonne ds pc_bas_get_col_adr
-- 03c,05.11.08,mnev   Ajout de CEIL() sur nb_col et nb_pce
-- 03b,06.10.08,mnev   change calcul de nb_uee
--                     SUM() au lieu de COUNT(distinct())
-- 03a,10.09.08,mnev   nouveau proto de pc_bas_get_col_adr
-- 02e,28.07.08,mnev   ajout info client final, cod_tra ... dans v_pc_ean_dtl
-- 02d,24.07.08,mnev   exclusion des cod_ut_sup NULL ...
-- 02c,04.07.08,mnev   réécriture v_pc_ean_base en UNION de 3 select.
-- 02b,28.05.08,mnev   Ajout du code lot dans v_pc_ean_base
-- 02a,16.05.08,mnev   Nouvelle vue v_pc_ean_base. Commande = CDE et non COM
-- 01a,11.07.07,jdre   version initiale
-- -------------------------------------------------------------------------

-- conditions de prise en compte
CREATE OR REPLACE VIEW V_PC_CONDI_VAL_PC  AS
	SELECT  *
	FROM PC_VAL_PC
	WHERE (typ_val_pc='C' OR (typ_val_pc='S' AND nb_pce_val > 0)) AND 
	cod_err_pc_val_pc IS NULL AND
	su_bas_etat_val_num(etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('VALIDATION_PREPARATION','PC_VAL_PC');
    
    
CREATE OR REPLACE VIEW V_PC_EAN_BASE  AS
SELECT
			count(DISTINCT l.no_com) cpt_com,
			count(DISTINCT g.cod_pro_cde || g.cod_va_cde || g.cod_vl_cde) cpt_pro,
			count(DISTINCT p.cod_lot_stk) cpt_lot,
			SUM(p.nb_col_val) cpt_uee,
			MAX(l.no_com) no_com,
			MAX(g.cod_pro_cde) cod_pro,
			MAX(g.cod_va_cde) cod_va,
			MAX(g.cod_vl_cde) cod_vl,
			MAX(g.cod_vl_cde_pce) cod_vl_pce,
			c.cod_ut_sup cod_ut,
			c.typ_ut_sup typ_ut,
			MIN(p.dat_dlc) dat_dlc,
			MIN(p.cod_lot_stk) cod_lot,
            CEIL(SUM(p.nb_col_val)) nb_col,
            CEIL(SUM(p.nb_pce_val)) nb_pce,
            SUM(p.pds_net_val) pds_net,
			MIN(e.dat_prep) dat_prep,
			MIN(e.dat_liv) dat_liv,
            MAX(e.cod_adr_fou_p) cod_adr_fou_p,
            MIN(e.cod_tou) cod_tou,
            MIN(e.cod_cli) cod_cli,
            MIN(g.libre_pc_lig_cmd_11) cod_cnt_pal,
            MIN(p.ope_crea) ope_crea
			FROM pc_uee c, pc_uee_det d, vf_pc_lig_com l, pc_lig_cmd g, pc_ent_com e, v_pc_condi_val_pc p
			WHERE c.no_uee=d.no_uee
			AND d.no_com=l.no_com
			AND d.no_lig_com=l.no_lig_com
			AND l.no_com=e.no_com
			AND d.no_com=p.no_com
			AND d.no_lig_com=p.no_lig_com
			AND d.no_uee=p.no_uee
			AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
                        AND l.no_cmd = g.no_cmd AND l.no_lig_cmd = g.no_lig_cmd
			AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
			AND c.cod_ut_sup IS NOT NULL AND c.typ_ut_sup IS NOT NULL
			GROUP BY c.cod_ut_sup,c.typ_ut_sup
UNION ALL
SELECT
			count(DISTINCT l.no_com) cpt_com,
			count(DISTINCT g.cod_pro_cde || g.cod_va_cde || g.cod_vl_cde) cpt_pro,
			count(DISTINCT p.cod_lot_stk) cpt_lot,
			SUM(p.nb_col_val) cpt_uee,
			MAX(l.no_com) no_com,
			MAX(g.cod_pro_cde) cod_pro,
			MAX(g.cod_va_cde) cod_va,
			MAX(g.cod_vl_cde) cod_vl,
			MAX(g.cod_vl_cde_pce) cod_vl_pce,
			v1.cod_ut_sup cod_ut,
			v1.typ_ut_sup typ_ut,
			MIN(p.dat_dlc) dat_dlc,
			MIN(p.cod_lot_stk) cod_lot,
            SUM(p.nb_col_val) nb_col,
            SUM(p.nb_pce_val) nb_pce,
            SUM(p.pds_net_val) pds_net,
			MIN(e.dat_prep) dat_prep,
			MIN(e.dat_liv) dat_liv,
            MAX(e.cod_adr_fou_p) cod_adr_fou_p,
            MIN(e.cod_tou) cod_tou,
            MIN(e.cod_cli) cod_cli,
            MIN(g.libre_pc_lig_cmd_11) cod_cnt_pal,
            MIN(p.ope_crea) ope_crea
			FROM pc_ut v1, pc_uee c, pc_uee_det d, vf_pc_lig_com l, pc_lig_cmd g, pc_ent_com e, v_pc_condi_val_pc p
			WHERE c.no_uee=d.no_uee
			AND d.no_com=l.no_com
			AND d.no_lig_com=l.no_lig_com
			AND l.no_com=e.no_com
			AND d.no_com=p.no_com
			AND d.no_lig_com=p.no_lig_com
			AND d.no_uee=p.no_uee
			AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
                        AND l.no_cmd = g.no_cmd AND l.no_lig_cmd = g.no_lig_cmd
			AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
			AND c.cod_ut_sup = v1.cod_ut AND c.typ_ut_sup = v1.typ_ut
			AND v1.cod_ut_sup IS NOT NULL AND v1.typ_ut_sup IS NOT NULL
			GROUP BY v1.cod_ut_sup,v1.typ_ut_sup
UNION ALL
SELECT
			count(DISTINCT l.no_com) cpt_com,
			count(DISTINCT g.cod_pro_cde || g.cod_va_cde || g.cod_vl_cde) cpt_pro,
			count(DISTINCT p.cod_lot_stk) cpt_lot,
			SUM(p.nb_col_val) cpt_uee,
			MAX(l.no_com) no_com,
			MAX(g.cod_pro_cde) cod_pro,
			MAX(g.cod_va_cde) cod_va,
			MAX(g.cod_vl_cde) cod_vl,
			MAX(g.cod_vl_cde_pce) cod_vl_pce,
			v2.cod_ut_sup cod_ut,
			v2.typ_ut_sup typ_ut,
			MIN(p.dat_dlc) dat_dlc,
			MIN(p.cod_lot_stk) cod_lot,
            SUM(p.nb_col_val) nb_col,
            SUM(p.nb_pce_val) nb_pce,
            SUM(p.pds_net_val) pds_net,
			MIN(e.dat_prep) dat_prep,
			MIN(e.dat_liv) dat_liv,
            MAX(e.cod_adr_fou_p) cod_adr_fou_p,
            MIN(e.cod_tou) cod_tou,
            MIN(e.cod_cli) cod_cli,
            MIN(g.libre_pc_lig_cmd_11) cod_cnt_pal,
            MIN(p.ope_crea) ope_crea
			FROM pc_ut v1, pc_ut v2, pc_uee c, pc_uee_det d, vf_pc_lig_com l, pc_lig_cmd g, pc_ent_com e, v_pc_condi_val_pc p
			WHERE c.no_uee=d.no_uee
			AND d.no_com=l.no_com
			AND d.no_lig_com=l.no_lig_com
			AND l.no_com=e.no_com
			AND d.no_com=p.no_com
			AND d.no_lig_com=p.no_lig_com
			AND d.no_uee=p.no_uee
			AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
                        AND l.no_cmd = g.no_cmd AND l.no_lig_cmd = g.no_lig_cmd
			AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
			AND c.cod_ut_sup = v1.cod_ut AND c.typ_ut_sup = v1.typ_ut AND v1.cod_ut_sup = v2.cod_ut AND v1.typ_ut_sup = v2.typ_ut
			AND v2.cod_ut_sup IS NOT NULL AND v2.typ_ut_sup IS NOT NULL
			GROUP BY v2.cod_ut_sup,v2.typ_ut_sup
/

CREATE or REPLACE VIEW V_PC_EAN_V2_0 AS
SELECT p.cod_ut,
       p.typ_ut,
       a1.rs_1 lib_exp,
       a1.adr_1 adr1_exp,
       a1.adr_2 adr2_exp,
       a1.adr_3 adr3_exp,
       a1.cp cp_exp,
       a1.ville ville_exp,
       com.dat_liv dat_liv,
       decode(com.cpt_com,1,com.no_com,null) no_com,
       decode(com.cpt_pro,1,su_bas_rch_lib_pro (com.cod_pro, com.cod_va, com.cod_vl, NULL, '%'),null) lib_pro,
       decode(com.cpt_pro,1,pc_bas_ut_ean_get_id(p.cod_ut,p.typ_ut,'02'),null) cod_gtin,
       com.cpt_uee,
       decode(com.cpt_pro,1,com.dat_dlc,null) dat_dlc,
       p.id_sscc,
       com.dat_prep,
       com.cod_adr_fou_p,
       te.cod_tiers cod_tra,
       te.lib_tiers lib_tra,
       com.cpt_pro,
       p.mode_pal_ut,
       p.cod_usn,
       com.cod_tou,
       com.cod_cli,
       com.cod_cnt_pal,
       p.cod_emp_zp cod_emp_prise,
       p.no_ord_ds_tou,
       p.lib_zon_pal,
       p.no_rmp,
       p.no_cmd,
       p.lib_ut,
       d.ref_dpt_ext,
       d.cod_quai_rl,
       com.cod_pro,
       com.ope_crea,
       (select floor(sum(pds_brut_val)) from pc_uee where cod_ut_sup= p.cod_ut and typ_ut_sup=p.typ_ut) poids_charge
FROM pc_ut     p,
	 su_adr    a1,
	 su_tra	   tr,
	 su_tiers  te,
     v_pc_ean_base com,
     ex_ent_dpt d 
WHERE NVL(com.cod_adr_fou_p, su_bas_gcl_su_usn(p.cod_usn,'COD_ADR')) = a1.cod_adr
  AND d.cod_tra_dflt=tr.cod_tiers(+)
  AND NVL(tr.typ_tiers, 'T')='T' 
  AND tr.cod_tiers=te.cod_tiers(+)
  AND tr.typ_tiers=te.typ_tiers(+)
  AND p.cod_ut=com.cod_ut
  AND p.typ_ut=com.typ_ut
  AND d.no_dpt=p.no_dpt
/

CREATE or REPLACE VIEW V_PC_EAN AS
SELECT p.*,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,0,'RS_1') lib_des,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,0,'ADR_1') adr1_des,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,0,'ADR_2') adr2_des,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,0,'ADR_3') adr3_des,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,0,'CP') cp_des,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,0,'VILLE') ville_des,
       pc_bas_ut_ean_get_id(p.cod_ut,p.typ_ut,'402') n_exp,
       pc_bas_ut_ean_get_id(p.cod_ut,p.typ_ut,'403',p.cod_tra) cod_rout,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,1,'RS_1') lib_des_f,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,1,'ADR_1') adr1_des_f,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,1,'ADR_2') adr2_des_f,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,1,'ADR_3') adr3_des_f,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,1,'CP') cp_des_f,
       pc_mod_pal_pkg.pc_bas_ut_get_adr_des(p.cod_ut,p.typ_ut,p.mode_pal_ut,1,'VILLE') ville_des_f,
       pc_mod_pal_pkg.pc_bas_ut_ean_gen_cb(p.cod_usn,p.cod_ut,p.typ_ut,p.mode_pal_ut,'PRO') cc_pro,
       pc_mod_pal_pkg.pc_bas_ut_ean_gen_cb(p.cod_usn,p.cod_ut,p.typ_ut,p.mode_pal_ut,'TRA') cc_tra,
       pc_mod_pal_pkg.pc_bas_ut_ean_gen_cb(p.cod_usn,p.cod_ut,p.typ_ut,p.mode_pal_ut,'ID')  cc_id,
       su_bas_gcl_ex_tou(p.cod_tou,'LIB_TOU') lib_tou
FROM v_pc_ean_v2_0 p
/

CREATE or REPLACE VIEW V_PC_EAN_DTL AS
SELECT
    d.no_com,
    d.no_lig_com,
    g.cod_pro_cde cod_pro,
    g.cod_vl_cde cod_vl,
    l.no_cmd,
    l.no_lig_cmd,
    su_bas_rch_lib_pro (g.cod_pro_cde, g.cod_va_cde, g.cod_vl_cde) lib_pro,
    g.cod_va_cde cod_va,
    c.cod_ut_sup,
    c.typ_ut_sup,
    su_bas_gcl_pc_ut(c.cod_ut_sup,
                     c.typ_ut_sup,
                     'MODE_PAL_UT') mode_pal,
    su_bas_gcl_pc_ut(c.cod_ut_sup,
                     c.typ_ut_sup,
                     'NO_DPT') no_dpt,
    ex_bas_gcl_tra_dpt (su_bas_gcl_pc_ut(c.cod_ut_sup,
                        c.typ_ut_sup,
                        'NO_DPT')) cod_tra,
    nvl(p.dlc_imp,p.dat_dlc) dat_dlc,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','RS_1') rs_1_exp_a,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','CP') cp_exp_a,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','VILLE') ville_exp_a,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','RS_1') rs_1_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','CP') cp_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','VILLE') ville_final,
    su_bas_gcl_pc_ent_com (d.no_com, 'COD_CLI') cod_cli,
    l.cod_cli_final,
    SUM(p.nb_col_val) nb_uee,
    SUM(p.pds_brut_val) pds_brut_val,
    SUM(p.pds_net_val) pds_net_val,
    SUM(p.pds_net_val) pds_affiche
    FROM  pc_uee c, pc_uee_det d, vf_pc_lig_com l, pc_lig_cmd g,v_pc_condi_val_pc p
    WHERE c.no_uee=d.no_uee
    AND d.no_com=l.no_com
    AND d.no_lig_com=l.no_lig_com
    AND d.no_com=p.no_com
    AND d.no_lig_com=p.no_lig_com
    AND d.no_uee=p.no_uee
    AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
    AND l.no_cmd = g.no_cmd
    AND l.no_lig_cmd = g.no_lig_cmd
    AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
    AND c.cod_ut_sup IS NOT NULL AND c.typ_ut_sup IS NOT NULL
    GROUP BY c.cod_ut_sup,c.typ_ut_sup,d.no_lig_com,d.no_com,l.no_cmd,l.no_lig_cmd,nvl(p.dlc_imp,p.dat_dlc),g.cod_pro_cde,g.cod_va_cde,g.cod_vl_cde,l.cod_cli_final
UNION ALL
    SELECT
    d.no_com,
    d.no_lig_com,
    g.cod_pro_cde cod_pro,
    g.cod_vl_cde cod_vl,
    l.no_cmd,
    l.no_lig_cmd,
    su_bas_rch_lib_pro (g.cod_pro_cde, g.cod_va_cde, g.cod_vl_cde) lib_pro,
    g.cod_va_cde cod_va,
    v1.cod_ut_sup cod_ut_sup,
    v1.typ_ut_sup typ_ut_sup,
    su_bas_gcl_pc_ut(v1.cod_ut_sup,
                     v1.typ_ut_sup,
                     'MODE_PAL_UT') mode_pal,
    su_bas_gcl_pc_ut(v1.cod_ut_sup,
                     v1.typ_ut_sup,
                     'NO_DPT') no_dpt,
    ex_bas_gcl_tra_dpt (su_bas_gcl_pc_ut(v1.cod_ut_sup,
                                         v1.typ_ut_sup,
                                         'NO_DPT')) cod_tra,
    nvl(p.dlc_imp,p.dat_dlc) dat_dlc,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','RS_1') rs_1_exp_a,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','CP') cp_exp_a,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','VILLE') ville_exp_a,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','RS_1') rs_1_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','CP') cp_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','VILLE') ville_final,
    su_bas_gcl_pc_ent_com (d.no_com, 'COD_CLI') cod_cli,
    l.cod_cli_final,
    SUM(p.nb_col_val) nb_uee,
    SUM(p.pds_brut_val) pds_brut_val,
    SUM(p.pds_net_val) pds_net_val,
    SUM(p.pds_net_val) pds_affiche
    FROM pc_ut v1,  pc_uee c, pc_uee_det d, vf_pc_lig_com l, pc_lig_cmd g,v_pc_condi_val_pc p
    WHERE c.no_uee=d.no_uee
    AND d.no_com=l.no_com
    AND d.no_lig_com=l.no_lig_com
    AND d.no_com=p.no_com
    AND d.no_lig_com=p.no_lig_com
    AND d.no_uee=p.no_uee
    AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
    AND l.no_cmd = g.no_cmd
    AND l.no_lig_cmd = g.no_lig_cmd
    AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
    AND c.cod_ut_sup = v1.cod_ut AND c.typ_ut_sup = v1.typ_ut
    AND v1.cod_ut_sup IS NOT NULL AND v1.typ_ut_sup IS NOT NULL
    GROUP BY v1.cod_ut_sup,v1.typ_ut_sup,d.no_lig_com,d.no_com,l.no_cmd,l.no_lig_cmd,nvl(p.dlc_imp,p.dat_dlc),g.cod_pro_cde,g.cod_va_cde,g.cod_vl_cde,l.cod_cli_final
UNION ALL
    SELECT
    d.no_com,
    d.no_lig_com,
    g.cod_pro_cde cod_pro,
    g.cod_vl_cde cod_vl,
    l.no_cmd,
    l.no_lig_cmd,
    su_bas_rch_lib_pro (g.cod_pro_cde, g.cod_va_cde, g.cod_vl_cde) lib_pro,
    g.cod_va_cde cod_va,
    v2.cod_ut_sup cod_ut_sup,
    v2.typ_ut_sup typ_ut_sup,
    su_bas_gcl_pc_ut(v2.cod_ut_sup,
                     v2.typ_ut_sup,
                     'MODE_PAL_UT') mode_pal,
    su_bas_gcl_pc_ut(v2.cod_ut_sup,
                     v2.typ_ut_sup,
                     'NO_DPT') no_dpt,
    ex_bas_gcl_tra_dpt (su_bas_gcl_pc_ut(v2.cod_ut_sup,
                                         v2.typ_ut_sup,
                                         'NO_DPT')) cod_tra,
    nvl(p.dlc_imp,p.dat_dlc) dat_dlc,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','RS_1') rs_1_exp_a,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','CP') cp_exp_a,
    pc_bas_get_col_adr (d.no_com,'0',0,'ADR_EXP_A','VILLE') ville_exp_a,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','RS_1') rs_1_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','CP') cp_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL','VILLE') ville_final,
    su_bas_gcl_pc_ent_com (d.no_com, 'COD_CLI') cod_cli,
    l.cod_cli_final,
    SUM(p.nb_col_val) nb_uee,
    SUM(p.pds_brut_val) pds_brut_val,
    SUM(p.pds_net_val) pds_net_val,
    SUM(p.pds_net_val) pds_affiche
    FROM pc_ut v1, pc_ut v2,  pc_uee c, pc_uee_det d, vf_pc_lig_com l, pc_lig_cmd g,v_pc_condi_val_pc p
    WHERE c.no_uee=d.no_uee
    AND d.no_com=l.no_com
    AND d.no_lig_com=l.no_lig_com
    AND d.no_com=p.no_com
    AND d.no_lig_com=p.no_lig_com
    AND d.no_uee=p.no_uee
    AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
    AND l.no_cmd = g.no_cmd
    AND l.no_lig_cmd = g.no_lig_cmd
    AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
    AND c.cod_ut_sup = v1.cod_ut AND c.typ_ut_sup = v1.typ_ut AND v1.cod_ut_sup = v2.cod_ut AND v1.typ_ut_sup = v2.typ_ut
    AND v2.cod_ut_sup IS NOT NULL AND v2.typ_ut_sup IS NOT NULL
    GROUP BY v2.cod_ut_sup,v2.typ_ut_sup,d.no_lig_com,d.no_com,l.no_cmd,l.no_lig_cmd,nvl(p.dlc_imp,p.dat_dlc),g.cod_pro_cde,g.cod_va_cde,g.cod_vl_cde,l.cod_cli_final
/


CREATE or REPLACE VIEW V_PC_EAN_DTL_CLI AS
SELECT
    d.no_com,
	d.no_lig_com,	
    c.cod_ut_sup,
    c.typ_ut_sup,
    su_bas_gcl_pc_ut(c.cod_ut_sup,
                     c.typ_ut_sup,
                     'MODE_PAL_UT') mode_pal,
    su_bas_gcl_pc_ut(c.cod_ut_sup,
                     c.typ_ut_sup,
                     'NO_DPT') no_dpt,
    ex_bas_gcl_tra_dpt (Su_Bas_Gcl_Pc_Ut(c.cod_ut_sup,
                        c.typ_ut_sup,
                        'NO_DPT')) cod_tra,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','RS_1') rs_1_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','CP')   cp_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','VILLE') ville_final,
    su_bas_gcl_pc_ent_com (d.no_com, 'COD_CLI') cod_cli,
    l.cod_cli_final,
    SUM(p.nb_col_val) nb_uee,
    SUM(p.pds_brut_val) pds_brut_val,
    SUM(p.pds_net_val) pds_net_val,
    SUM(p.pds_net_val) pds_affiche
    FROM  pc_uee c, pc_uee_det d, vf_pc_lig_com l,v_pc_condi_val_pc p
    WHERE c.no_uee=d.no_uee
    AND d.no_com=l.no_com
    AND d.no_lig_com=l.no_lig_com
    AND d.no_com=p.no_com
    AND d.no_lig_com=p.no_lig_com
    AND d.no_uee=p.no_uee
    AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
    AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
    AND c.cod_ut_sup IS NOT NULL AND c.typ_ut_sup IS NOT NULL
    GROUP BY c.cod_ut_sup, c.typ_ut_sup, d.no_lig_com, d.no_com, l.no_cmd, l.no_lig_cmd, l.cod_cli_final
 UNION ALL
    SELECT
    d.no_com,
	d.no_lig_com,	
    v1.cod_ut_sup cod_ut_sup,
    v1.typ_ut_sup typ_ut_sup,
    su_bas_gcl_pc_ut(v1.cod_ut_sup,
                     v1.typ_ut_sup,
                     'MODE_PAL_UT') mode_pal,
    su_bas_gcl_pc_ut(v1.cod_ut_sup,
                     v1.typ_ut_sup,
                     'NO_DPT') no_dpt,
    ex_bas_gcl_tra_dpt (su_bas_gcl_pc_ut(v1.cod_ut_sup,
                        v1.typ_ut_sup,
                        'NO_DPT')) cod_tra,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','RS_1') rs_1_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','CP')   cp_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','VILLE') ville_final,
    su_bas_gcl_pc_ent_com (d.no_com, 'COD_CLI') cod_cli,
    l.cod_cli_final,
    SUM(p.nb_col_val) nb_uee,
    SUM(p.pds_brut_val) pds_brut_val,
    SUM(p.pds_net_val) pds_net_val,
    SUM(p.pds_net_val) pds_affiche
    FROM pc_ut v1,  pc_uee c, pc_uee_det d, vf_pc_lig_com l,v_pc_condi_val_pc p
    WHERE c.no_uee=d.no_uee
    AND d.no_com=l.no_com
    AND d.no_lig_com=l.no_lig_com
    AND d.no_com=p.no_com
    AND d.no_lig_com=p.no_lig_com
    AND d.no_uee=p.no_uee
    AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
    AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
    AND c.cod_ut_sup = v1.cod_ut AND c.typ_ut_sup = v1.typ_ut
    AND v1.cod_ut_sup IS NOT NULL AND v1.typ_ut_sup IS NOT NULL
    GROUP BY v1.cod_ut_sup, v1.typ_ut_sup, d.no_lig_com, d.no_com, l.no_cmd, l.no_lig_cmd, l.cod_cli_final
 UNION ALL
    SELECT
    d.no_com,
	d.no_lig_com,	
    v2.cod_ut_sup cod_ut_sup,
    v2.typ_ut_sup typ_ut_sup,
    su_bas_gcl_pc_ut(v2.cod_ut_sup,
                     v2.typ_ut_sup,
                     'MODE_PAL_UT') mode_pal,
    su_bas_gcl_pc_ut(v2.cod_ut_sup,
                     v2.typ_ut_sup,
                     'NO_DPT') no_dpt,
    ex_bas_gcl_tra_dpt (su_bas_gcl_pc_ut(v2.cod_ut_sup,
                        v2.typ_ut_sup,
                        'NO_DPT')) cod_tra,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','RS_1') rs_1_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','CP')   cp_final,
    pc_bas_get_col_adr (d.no_com,l.no_cmd,l.no_lig_cmd,'ADR_FINAL_OU_ADR_EXP_A','VILLE') ville_final,
    su_bas_gcl_pc_ent_com (d.no_com, 'COD_CLI') cod_cli,
    l.cod_cli_final,
    SUM(p.nb_col_val) nb_uee,
    SUM(p.pds_brut_val) pds_brut_val,
    SUM(p.pds_net_val) pds_net_val,
    SUM(p.pds_net_val) pds_affiche
    FROM pc_ut v1, pc_ut v2,  pc_uee c, pc_uee_det d, vf_pc_lig_com l ,v_pc_condi_val_pc p
    WHERE c.no_uee=d.no_uee
    AND d.no_com=l.no_com
    AND d.no_lig_com=l.no_lig_com
    AND d.no_com=p.no_com
    AND d.no_lig_com=p.no_lig_com
    AND d.no_uee=p.no_uee
    AND su_bas_etat_val_num(p.etat_atv_pc_val_pc,'PC_VAL_PC') >= su_bas_etat_val_num('BL_EXPE_BN_MIN','PC_VAL_PC')
    AND su_bas_etat_val_num(c.etat_atv_pc_uee,'PC_UEE') >= su_bas_etat_val_num('CONTROLE','PC_UEE')
    AND c.cod_ut_sup = v1.cod_ut AND c.typ_ut_sup = v1.typ_ut AND v1.cod_ut_sup = v2.cod_ut AND v1.typ_ut_sup = v2.typ_ut
    AND v2.cod_ut_sup IS NOT NULL AND v2.typ_ut_sup IS NOT NULL
    GROUP BY v2.cod_ut_sup, v2.typ_ut_sup, d.no_lig_com, d.no_com, l.no_cmd, l.no_lig_cmd, l.cod_cli_final
/

CREATE or REPLACE VIEW V_PC_EAN_DTL_CLI_TOTAL AS
SELECT no_com,
	   cod_ut_sup,
	   typ_ut_sup,
	   mode_pal,
	   no_dpt,
	   cod_tra,
	   rs_1_final,
	   cp_final,
	   ville_final,	
       NVL(cod_cli_final, cod_cli) cod_cli_final,
	   SUM(nb_uee)       nb_uee,
	   SUM(pds_brut_val) pds_brut_val,
	   SUM(pds_net_val)  pds_net_val,
	   SUM(pds_affiche)  pds_affiche
       FROM v_pc_ean_dtl_cli
       GROUP BY no_com,
       	        cod_ut_sup,
	            typ_ut_sup,
	            mode_pal,
	            no_dpt,
	            cod_tra,
	            rs_1_final,
	            cp_final,
	            ville_final,	
                NVL(cod_cli_final, cod_cli)
/

