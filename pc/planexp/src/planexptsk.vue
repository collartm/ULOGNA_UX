-- $Id$
-- DESCRIPTION :
-- -------------
-- Ces vues sont utilis�es dans pc_plan_exp_tsk_pkg
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
-- 02a,16.06.14   s�pcif systeme U
-- 01a,31.07.13   version initiale
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW V_PEXPTSK_UEE AS
    select  c.no_dpt,
            c.cod_usn,
            c.no_com,
            c.etat_atv_pc_ent_com,
            c.cod_tou,
            c.cod_soc,
            c.cod_tra_1,
            c.cod_ptp_1,
            c.cod_ptp_2,
            c.cod_cli,
            m.autor_prepa_n3,
            l.no_lig_com,
            pc_mod_pal_pkg.pc_bas_rch_cle_mode_pal
                 (  l.mode_pal_1,
                    c.no_dpt,
                    c.cod_tou,
                    c.cod_tra_1,
                    c.cod_ptp_1,
                    c.cod_ptp_2,
                    c.cod_cli,
                    c.no_com       ,
                    l.no_cmd       ,
                    l.cod_pro      ,
                    l.no_lig_cmd,
                    l.cod_adr_final
                 ) cle_mode_pal_1,
            l.mode_pal_1,
            l.typ_pal_1,
            l.cod_cfg_pal_1,
            l.cle_rgp_pal_1,
            l.no_cmd       ,
            l.cod_pro      ,
            l.cod_va      ,
            l.cod_vl      ,
            l.no_lig_cmd,
            l.cod_adr_final,
            e.no_uee,
            e.etat_atv_pc_uee,
            e.nb_col_theo*e.vol_theo *su_bas_to_number(su_bas_rch_par_usn('SP_PLANEXP_FOIS_PSS',e.cod_usn,e.cod_pss_afc)) vol,
         pc_mod_pal_pkg.pc_bas_sgn_pal (
                    l.mode_pal_1,
                    l.typ_pal_1       ,
                    c.cod_usn       ,
                    c.cod_soc       ,
                    c.no_dpt        ,
                    c.cod_tou       ,
                    c.cod_tra_1       ,
                    c.cod_ptp_1     ,
                    c.cod_ptp_2     ,
                    c.cod_cli       ,
                    c.no_com        ,
                    l.no_cmd        ,
                    l.cod_pro       ,
                    l.cod_va        ,
                    l.cod_vl        ,
                    l.no_lig_cmd    ,
                    l.cle_rgp_pal_1   ,
                    l.cod_cfg_pal_1   ,
                    0 ,
                    null
                    ) sgn,
        l.cle_rgp_pal_2,
         decode(l.cle_rgp_pal_2,NULL,NULL,L.cle_rgp_pal_2,pc_mod_pal_pkg.pc_bas_sgn_pal (   -- signature d�grad�e
                    l.mode_pal_1,
                    l.typ_pal_1       ,
                    c.cod_usn       ,
                    c.cod_soc       ,
                    c.no_dpt        ,
                    c.cod_tou       ,
                    c.cod_tra_1       ,
                    c.cod_ptp_1     ,
                    c.cod_ptp_2     ,
                    c.cod_cli       ,
                    c.no_com        ,
                    l.no_cmd        ,
                    l.cod_pro       ,
                    l.cod_va        ,
                    l.cod_vl        ,
                    l.no_lig_cmd    ,
                    l.cle_rgp_pal_2   ,
                    l.cod_cfg_pal_1   ,
                    0 ,
                    null
                    )) sgn2,
            l.lst_fct_lock lst_fct_lock_lig,
            e.lst_fct_lock lst_fct_lock_uee,
            e.cod_pss_afc
      from pc_ent_cmd m,pc_ent_com c,pc_lig_com l,pc_uee_det d,pc_uee e
      where c.no_com=l.no_com
        and l.no_com=d.no_com
        AND l.no_cmd=m.no_cmd
        and l.no_lig_com=d.no_lig_com
        and e.no_uee=d.no_uee
        AND e.cod_err_pc_uee IS NULL
        AND c.no_dpt IS NOT NULL
        AND e.typ_uee='CC'      -- uniquement CC pour le moment
        AND l.typ_pal_1='HETER' -- uniquement h�t�rog�ne pour le moment
/

CREATE OR REPLACE VIEW V_PEXPTSK_UEE_LOCK AS
    select  *
      from V_PEXPTSK_UEE
      where lst_fct_lock_lig IS NULL
        AND lst_fct_lock_uee IS NULL
        AND ( su_bas_rch_cle_atv_pss_2 (cod_pss_afc, 'POR', 'MODE_CAL_COORD_UEE') = '1'
               AND cod_cli NOT IN (SELECT cod_cli         -- attendre la fin de la purge sur le s�quenceur pour ne pas g�n�rer n petites UP
                                     FROM pc_ent_com c,pc_uee e
                                     WHERE e.no_com=c.no_com
                                     AND c.cod_cli != 'S'   --$MODGQUI  03042015, ne pas prendre en compte le client desimplantation
                                     AND e.motif_purge_uee IS NOT NULL
                                     )
              OR su_bas_rch_cle_atv_pss_2 (cod_pss_afc, 'POR', 'MODE_CAL_COORD_UEE') = '0')
/

CREATE OR REPLACE VIEW V_PEXPTSK_UEE_DET AS
    select  l.no_com,
            l.no_lig_com,
            nvl(l.cle_rgp_pal_pref_A_1,'NULL') cle_rgp_pal_pref_A_1,
            nvl(l.cle_rgp_pal_pref_B_1,'NULL') cle_rgp_pal_pref_B_1,
            l.cle_rgp_pal_pref_C_1,
            e.no_uee,
            e.typ_uee,
            e.nb_col_theo,
            e.nb_col_theo*e.vol_theo*su_bas_to_number(su_bas_rch_par_usn('SP_PLANEXP_FOIS_PSS',e.cod_usn,e.cod_pss_afc)) vol,
            e.nb_col_theo*e.pds_theo pds,
            e.cod_cnt,
            e.etat_atv_pc_uee,
            e.id_session_lock,
            e.cod_up,
            e.cod_pss_afc,
            (nvl(su_bas_rch_action_det('PORTAB_UL',n.portab_cnt),0)*e.nb_col_theo*e.vol_theo)/100 vol_instab,
            n.haut_cnt_plein haut  ,
            n.portab_cnt,
            nvl(su_bas_rch_action_det('PORTAB_UL',n.portab_cnt),0) taux_instab,
            ';'||nvl(l.cle_rgp_pal_pref_A_1,'#NULL#')||';'||e.cod_pss_afc||';' lst_grp,
            e.libre_pc_uee_4
      from pc_lig_com l,pc_uee_det d,pc_uee e,su_cnt n
      where l.no_com=d.no_com
        and l.no_lig_com=d.no_lig_com
        AND n.cod_cnt=e.cod_cnt
        and e.no_uee=d.no_uee
        AND e.cod_err_pc_uee IS NULL
        AND e.typ_uee='CC'      -- uniquement CC pour le moment
        AND l.typ_pal_1='HETER' -- uniquement h�t�rog�ne pour le moment
/

CREATE OR REPLACE VIEW V_PEXPTSK_CFG_PAL AS
    select c.*,
           (c.haut_std-NVL(n.haut_cnt_vide,0))*(1-(NVL(c.tol_min,0)/100)) haut_min,
           c.vol_std*(1-(NVL(c.tol_min,0)/100)) vol_min,
           (c.haut_std-NVL(n.haut_cnt_vide,0))*(1+(NVL(c.tol_max,0)/100)) haut_max,
           c.vol_std*(1+(NVL(c.tol_max,0)/100)) vol_max,
           su_bas_rch_action_det('MODE_CALC_NO_ORD_PAL',c.mode_calc_no_ord_pal) order_by,
           c.vol_std*(nvl(c.SEUIL_MULTI,0)/100) vol_seuil    -- volume pour d�gradation solution
    from su_cnt n,pc_cfg_pal c
    where n.cod_cnt=c.cod_cnt_pal
/

