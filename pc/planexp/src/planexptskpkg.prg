/* $Id$ */
CREATE OR REPLACE
PACKAGE BODY pc_plan_exp_tsk_pkg AS

g_etat_uee      varchar2(10);
g_etat_uee_tmp  varchar2(10);
g_etat_uee_fin  varchar2(10);
g_etat_com_num  number;        -- commande pr�par�e ou sold�e
g_etat_up       varchar2(10);

g_uee           ueeset_list;
g_cod_usn       su_usn.cod_usn%TYPE;
g_cfg_pal       v_pexptsk_cfg_pal%ROWTYPE;
g_dat_ana       date;
g_no_session_ora number;
g_uee_ref       v_pexptsk_uee%ROWTYPE;
type t_order_by is table of varchar2(4000) index by varchar2(30);
g_order_by      t_order_by;

g_vol_seuil_min number;
g_vol_seuil_max number;
g_nb_pal        number;
g_tol_max      number;
g_vol_reste     number;
g_is_deg        number; -- signature en cours d�gradable

g_taux_remp     number:=nvl(su_bas_to_number(su_bas_rch_par_usn('SP_PLANEXP_TAUX_REMP','%'))/100,0.75); -- taux de remplissage moyen d'une palette

/*
****************************************************************************
* pc_bas_plan_exp_err - Mise en erreur des UEE
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de mettre les UEE en erreurs
--
-- PARAMETRES :
-- ------------
--  code usine
--  exclsivit� (d�part, cl� / mode pal, typ pal,cle_rgp_pal,
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_plan_exp_err (p_cod_err varchar2)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'su_bas_dia_usn';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-51';
    err_except          EXCEPTION;

    v_ret               varchar2(100);

BEGIN
    v_etape:='Mise en erreur des UEE';
    forall i in g_uee.first..g_uee.last
        update pc_uee
        set cod_err_pc_uee=p_cod_err,
            lst_fct_lock=null,
            id_session_lock=null
        where no_uee =g_uee(i)
          and etat_atv_pc_uee=g_etat_uee
          and cod_err_pc_uee is null;

    commit;

EXCEPTION
    WHEN OTHERS THEN
        rollback;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_cod_usn         => g_cod_usn,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
END;

/*
****************************************************************************
* pc_bas_calc_seuils - Calcul des seuils
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de lancer la palettisation pour une usine,
-- et pour un regroupement pr�f�rentiel
--
-- PARAMETRES :
-- ------------
--  volume � palettiser
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01c,19.10.15,tcho    Inversion sens de la comparaison du mode 92
-- 01b,15.10.15,pluc    Envoi tol max � cubeiq si pas de rajout de palette en testant le volume max.
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_calc_seuils (p_vol              number)
return varchar2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01c $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calc_seuils';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-51';
    err_except          EXCEPTION;

    v_ret               varchar2(100);

BEGIN
    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 7 THEN
        su_bas_put_debug( v_nom_obj ||' : Vol='||p_vol||' Mode='||g_cfg_pal.mode_calc_seuil_vol);
        IF su_global_pkv.v_niv_dbg >= 9 THEN
            su_bas_put_debug( v_nom_obj ||' : Cfg Min='||g_cfg_pal.vol_min||' Max='||g_cfg_pal.vol_max||' Std='||g_cfg_pal.vol_std);
        END IF;
    END IF;
    -- on prend les vol_min � la place des vol_std,et vol_std pour vol_max pour tenir compte des trous
    g_tol_max:=0;
    v_etape:='Calcul des seuils';
    if g_cfg_pal.mode_calc_seuil_vol='90' then  -- SUO : UP cible
        g_nb_pal:=ceil(p_vol/g_cfg_pal.vol_min);
        g_vol_seuil_min:=g_cfg_pal.vol_min;
        g_vol_seuil_max:=g_cfg_pal.vol_std;
    elsif g_cfg_pal.mode_calc_seuil_vol='91' then  -- SUO : UP cible / last max
        if p_vol<= least(g_cfg_pal.vol_std,g_cfg_pal.vol_max*g_taux_remp) then
            g_nb_pal:=1;
            g_vol_seuil_min:=g_cfg_pal.vol_std;
            g_vol_seuil_max:=g_cfg_pal.vol_std;
            g_tol_max:=g_cfg_pal.tol_max;
        else
            g_nb_pal:=ceil(p_vol/g_cfg_pal.vol_min);
            g_vol_seuil_min:=least(g_cfg_pal.vol_min,g_cfg_pal.vol_max*g_taux_remp);
            g_vol_seuil_max:=least(g_cfg_pal.vol_std,g_cfg_pal.vol_max*g_taux_remp);
        end if;
    elsif g_cfg_pal.mode_calc_seuil_vol='92' then  -- SUO : r�partie cible
        g_nb_pal:=trunc(p_vol/least(g_cfg_pal.vol_min,g_cfg_pal.vol_std*g_taux_remp));
        if g_nb_pal=0 or g_nb_pal*g_cfg_pal.vol_max*g_taux_remp<p_vol then -- $MOD 01c : si volume � palettiser > volume max alors rajouter une palette
            g_nb_pal:=g_nb_pal+1;
        ELSE
            -- $MOD,pluc Envoi tol max � cubeiq si pas de rajout de palette en testant le volume max.
            g_tol_max:=g_cfg_pal.tol_max;
        end if;
        if g_nb_pal=1 then -- s'il ne reste qu'une palette, prendre UP max
            g_vol_seuil_min:=g_cfg_pal.vol_std;
            g_vol_seuil_max:=g_cfg_pal.vol_std;
            g_tol_max:=g_cfg_pal.tol_max;
        else
            g_vol_seuil_min:=p_vol/g_nb_pal;
            g_vol_seuil_max:=least(g_cfg_pal.vol_std,g_cfg_pal.vol_max*g_taux_remp);
        end if;
    elsif g_cfg_pal.mode_calc_seuil_vol='50' then  -- On laisse Cube-IQ faire le travail
        g_nb_pal:=1;
        g_vol_seuil_min:=99999999999;
        g_vol_seuil_max:=99999999999;
    else
        v_etape:='Mode de calcul non g�r�';
        raise err_except;
    end if;

    IF su_global_pkv.v_niv_dbg >= 7 THEN
        su_bas_put_debug( v_nom_obj ||' : Seuil Min='||g_vol_seuil_min||' Max='||g_vol_seuil_max||' Nb pal='||g_nb_pal);
    END IF;

    return 'OK';

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_cod_usn         => g_cod_usn,
                        p_lib_ano_1       => 'Vol',
                        p_par_ano_1       => p_vol,
                        p_lib_ano_2       => 'Mode',
                        p_par_ano_2       => g_cfg_pal.mode_calc_seuil_vol,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;

/*
****************************************************************************
* pc_bas_cre_new_up - Cr�ation d'une nouvelle UP
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de cr�er une nouvelle UP par rapport � une uee de r�f�rence
--
-- PARAMETRES :
-- ------------
--  Uee de r�f�rence
--  utilisation des pr�f�rences 1 � 3
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 02b,23.07.14,tcho    gestion typ UP
-- 02a,16.06.14,tcho    Sp�cif SUO
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_cre_new_up (p_grp varchar2,p_cod_up out varchar2,p_typ_up varchar2 default 'P1')
return varchar2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_cre_new_up';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-55';
    err_except          EXCEPTION;

    v_ret               varchar2(100);
    v_ctx               su_ctx_pkg.tt_ctx;

    v_cod_up            pc_up.cod_up%TYPE;


BEGIN
    savepoint my_pc_bas_cre_new_up;

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 5 THEN
        su_bas_put_debug( v_nom_obj ||' : Uee='||g_uee_ref.no_uee||' Grp='||p_grp);
    END IF;

    v_etape := 'Calcul n� UP' ;
    IF su_ctx_pkg.su_bas_set_char( v_ctx, 'TYP_UP', p_typ_up ) THEN
        v_ret := su_cc_pkg.su_bas_make_cc('NO_PC_UP',
                                           v_ctx,
                                           v_cod_up);

        IF v_ret != 'OK' THEN
          RAISE err_except;
        END IF;
    else
        RAISE err_except;
    END if;

    v_etape:='Cr�ation UP';
    v_ret:=su_bas_ins_pc_up(
        p_cod_up                        => v_cod_up,
        p_typ_up                        => p_typ_up,
--        p_cod_up_sup                    PC_UP.COD_UP_SUP%TYPE DEFAULT NULL,
--        p_typ_up_sup                    PC_UP.TYP_UP_SUP%TYPE DEFAULT NULL,
--        p_sgn_pal_up                    PC_UP.SGN_PAL_UP%TYPE DEFAULT NULL,
        p_mode_pal_up                   => g_uee_ref.mode_pal_1,
        p_typ_pal_up                    => g_uee_ref.typ_pal_1,
        p_cod_cfg_pal_up                => g_uee_ref.cod_cfg_pal_1,
        p_no_var_cfg_pal_up             => 0,
        p_cle_rgp_pal_up                => g_uee_ref.cle_rgp_pal_1,
        p_cod_cnt_up                    => g_cfg_pal.cod_cnt_pal,
        p_haut_std                      => g_cfg_pal.haut_std,
        p_tol_min                       => g_cfg_pal.tol_min,
        p_tol_max                       => g_tol_max,    -- prendre la tol�rance max pour Cube-IQ
        p_seuil_mono                    => g_cfg_pal.SEUIL_MONO,
        p_seuil_multi                   => g_cfg_pal.SEUIL_MULTI,
        p_nb_max_pro                    => g_cfg_pal.NB_MAX_PRO,
        p_nb_max_cli                    => g_cfg_pal.NB_MAX_CLI,
        p_nb_max_ptp                    => g_cfg_pal.NB_MAX_PTP,
--        p_nb_max_util                   PC_UP.NB_MAX_UTIL%TYPE DEFAULT NULL,
        p_nb_reel                       => 0,
        p_pds_brut_reel                 => 0,
        p_vol_std                       => g_cfg_pal.VOL_STD,
        p_vol_reel                      => 0,
        p_no_dpt                        => g_uee_ref.NO_DPT,
        p_cod_tra                       => g_uee_ref.COD_TRA_1,
        p_cod_tou                       => g_uee_ref.COD_TOU,
        p_cod_soc                       => g_uee_ref.COD_SOC,
        p_cod_usn                       => g_uee_ref.COD_USN,
        p_cod_ptp_1                     => g_uee_ref.COD_PTP_1,
        p_cod_ptp_2                     => g_uee_ref.COD_PTP_2,
        p_cod_cli                       => g_uee_ref.COD_CLI,
        p_no_cmd                        => g_uee_ref.NO_CMD,
        p_no_lig_cmd                    => g_uee_ref.NO_LIG_CMD,
        p_cod_pro                       => g_uee_ref.COD_PRO,
--        p_cod_va                        => g_uee_ref.COD_VA,
--        p_cod_vl                        => g_uee_ref.COD_VL,
        p_nb_uee                        => 0,
--        p_taux_theo                     PC_UP.TAUX_THEO%TYPE DEFAULT NULL,
        p_etat_up_complete              => 1,
--        p_cod_elm_up                    PC_UP.COD_ELM_UP%TYPE DEFAULT NULL,
--        p_no_ord_ds_tou                 => g_uee_ref.NO_ORD_DS_TOU,
--        p_no_ord_ds_zg                  => g_uee_ref.NO_ORD_DS_ZG,
--        p_cod_zg                        => g_uee_ref.COD_ZG,
        p_etat_atv_pc_up                => g_etat_up,
--        p_qte_atv                       PC_UP.QTE_ATV%TYPE DEFAULT NULL,
--        p_qte_ref_atv                   PC_UP.QTE_REF_ATV%TYPE DEFAULT NULL,
--        p_cod_pss_afc                   PC_UP.COD_PSS_AFC%TYPE DEFAULT NULL,
--        p_cod_err_pc_up                 PC_UP.COD_ERR_PC_UP%TYPE DEFAULT NULL,
        p_no_com                        => g_uee_ref.NO_COM,
--        p_cod_mcnt                      PC_UP.COD_MCNT%TYPE DEFAULT NULL,
--        p_no_var_mcnt                   PC_UP.NO_VAR_MCNT%TYPE DEFAULT NULL,
--        p_lst_bcnt_qte_cours            PC_UP.LST_BCNT_QTE_COURS%TYPE DEFAULT NULL,
--        p_lst_bcnt_qte_vois             PC_UP.LST_BCNT_QTE_VOIS%TYPE DEFAULT NULL,
--        p_is_porteuse                   PC_UP.IS_PORTEUSE%TYPE DEFAULT NULL,
--        p_haut_moy                      PC_UP.HAUT_MOY%TYPE DEFAULT NULL,
--        p_haut_disp                     PC_UP.HAUT_DISP%TYPE DEFAULT NULL,
--        p_note                          PC_UP.NOTE%TYPE DEFAULT NULL,
--        p_sgn_pal_up_sup                PC_UP.SGN_PAL_UP_SUP%TYPE DEFAULT NULL,
--        p_mode_pal_up_sup               PC_UP.MODE_PAL_UP_SUP%TYPE DEFAULT NULL,
--        p_typ_pal_up_sup                PC_UP.TYP_PAL_UP_SUP%TYPE DEFAULT NULL,
--        p_cod_cfg_pal_up_sup            PC_UP.COD_CFG_PAL_UP_SUP%TYPE DEFAULT NULL,
--        p_no_var_cfg_pal_up_sup         PC_UP.NO_VAR_CFG_PAL_UP_SUP%TYPE DEFAULT NULL,
--        p_cle_rgp_pal_up_sup            PC_UP.CLE_RGP_PAL_UP_SUP%TYPE DEFAULT NULL,
--        p_haut_reel                     PC_UP.HAUT_REEL%TYPE DEFAULT NULL,
--        p_no_ord_up                     PC_UP.NO_ORD_UP%TYPE DEFAULT NULL,
--        p_cle_rgp_pal_pref_a          => p_cle_pref_A,
--        p_cle_rgp_pal_pref_b          => p_cle_pref_B,
--        p_cle_rgp_pal_pref_c          => p_cle_pref_C --,
--        p_id_session_lock               PC_UP.ID_SESSION_LOCK%TYPE DEFAULT NULL,
--        p_lst_fct_lock                  PC_UP.LST_FCT_LOCK%TYPE DEFAULT NULL,
--        p_dat_lock                      PC_UP.DAT_LOCK%TYPE DEFAULT NULL,
--        p_ope_lock                      PC_UP.OPE_LOCK%TYPE DEFAULT NULL,
--        p_usr_lock                      PC_UP.USR_LOCK%TYPE DEFAULT NULL,
        p_libre_pc_up_1                 => p_grp
--        p_libre_pc_up_2                 PC_UP.LIBRE_PC_UP_2%TYPE DEFAULT NULL,
--        p_libre_pc_up_3                 PC_UP.LIBRE_PC_UP_3%TYPE DEFAULT NULL,
--        p_libre_pc_up_4                 PC_UP.LIBRE_PC_UP_4%TYPE DEFAULT NULL,
--        p_libre_pc_up_5                 PC_UP.LIBRE_PC_UP_5%TYPE DEFAULT NULL
        );

    p_cod_up:=v_cod_up;
    return 'OK';

EXCEPTION
    WHEN OTHERS THEN
        rollback to savepoint my_pc_bas_cre_new_up;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_cod_usn         => g_cod_usn,
                        p_lib_ano_1       => 'group',
                        p_par_ano_1       => p_grp,
                        p_lib_ano_2       => 'Uee ref',
                        p_par_ano_2       => g_uee_ref.no_uee,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;

end;

/*
****************************************************************************
* pc_bas_add_uee_up - Ajout des UP � une UEE
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'ajouter des UEE � une UP
--
-- PARAMETRES :
-- ------------
--  utilisation des pr�f�rences 1 � 3
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,19.10.15,tcho  init du v_vol_cou et non du v_vol !
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  volume palettis� ou -1
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_add_uee_up (p_cod_up        varchar2,
                            p_grp           varchar2,
                            p_vol           number -- total � palettiser pour le groupe
                          )
return varchar2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_add_uee_up';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-54';
    err_except          EXCEPTION;

    v_ret               varchar2(100);

    v_vol               number:=0;
    v_nb_col            number:=0;
    v_pds               number:=0;
    v_seuil_next        number:=0;

    cursor c_pref(x_vol_reste number) is
        select cle_rgp_pal_pref_A_1,sum(vol) vol
        from v_pexptsk_uee_det e,table(g_uee) t
        where t.column_value=e.no_uee
          and e.etat_atv_pc_uee=g_etat_uee
          and e.id_session_lock is null
          and e.lst_grp like p_grp||'%'
        group by cle_rgp_pal_pref_A_1
        having sum(vol)<=x_vol_reste -- volume total rentre dans le volume restant de la palette
        order by 2 desc;

    r_pref c_pref%ROWTYPE;


   -- gestion de la r�partition des couches

   SURF_PAL   number:=1200*800;
   SURF_SEUIL number:=1200*800*(su_bas_to_number(su_bas_rch_par_usn ('SU_CUBE_IQ_PCT_LAYER','S'))/100); -- surface * pct de remplissage
   DIFF_HAUT  number:=su_bas_to_number(su_bas_rch_par_usn ('SU_CUBE_IQ_MAX_DIFF_HAUT_COU','S'))/2; -- diff�rence de hauteur / 2

   v_no_cou     number:=0;
   v_lst_pro    varchar2(32000);
   v_lst_pro2   varchar2(32000);
   v_surf       number;
   v_surf2      number;
   v_haut       number;
   v_haut2      number;
   v_vol_cou    number;
   v_maj        boolean;
   vt_vol_up    su_global_pkv.ttb_number;
   v            number;
   p            number;
   p2           number;

    cursor c_cou_1 is
      select d.cod_pro_res,
             sum(c.long_cnt*c.larg_cnt*c.haut_cnt_plein) vol,
             min(nvl(L.cle_rgp_pal_pref_a_1,'#NULL#')||'-'||e.cod_pss_afc||'-'||nvl(c.cod_stack,'-')) cle
      from su_cnt c,pc_uee e,pc_uee_det d,pc_lig_com l
      where e.id_session_lock=g_no_session_ora
        and c.cod_cnt=e.cod_cnt
        and d.no_uee=e.no_uee
        and d.no_com=l.no_com
        and d.no_lig_com=l.no_lig_com
        and e.libre_pc_uee_1 is null
        and c.portab_cnt!='9' -- on ne fait pas de couche avec des produits qui s'�crasent !
      group by d.cod_pro_res
      having sum(c.long_cnt*c.larg_cnt)>=SURF_PAL                       -- plus d'une couche en surface
          or (count(*)>=su_bas_gcl_su_ul(cod_pro_res,'10','nb_ul_cou')    -- plus que le nb d'ul / couche
          and sum(c.long_cnt*c.larg_cnt)>=SURF_SEUIL);                      -- et suffisant pour faire une couche CUBE-IQ

   cursor c_cou_mono(x_ges_stack integer) is
     select distinct
            e.cod_pss_afc pss,
            nvl(L.cle_rgp_pal_pref_a_1,'#NULL#') pref,
            decode(x_ges_stack,0,nvl(c.cod_stack,'-'),'z') stack
     from su_cnt c,pc_uee e,pc_uee_det d,pc_lig_com l
     where e.no_uee=D.NO_UEE
       and c.cod_cnt=e.cod_cnt
       and d.no_com=l.no_com
       and d.no_lig_com=l.no_lig_com
       and c.portab_cnt!='9'
       and e.id_session_lock=g_no_session_ora
       and e.libre_pc_uee_1 is null
       ;

    cursor c_uee2(x_pref varchar2,x_pss varchar2,x_stack varchar2) is
        with e as ( -- ensemble des colis � prendre en compte
                select c.haut_cnt_plein haut,c.larg_cnt*c.long_cnt surf
                from su_cnt c,pc_uee e,pc_uee_det d,pc_lig_com l
                where e.no_uee=D.NO_UEE
                and c.cod_cnt=e.cod_cnt
                and d.no_com=l.no_com
                and d.no_lig_com=l.no_lig_com
                and c.portab_cnt!='9'
                and e.id_session_lock=g_no_session_ora
                and e.libre_pc_uee_1 is null
                and e.cod_pss_afc=x_pss
                and nvl(L.cle_rgp_pal_pref_a_1,'#NULL#')=x_pref
                and (x_stack='z' or nvl(c.cod_stack,'-')=x_stack)
                  )
        select haut,
               (select sum(surf)
                from e
                where haut between h.haut-DIFF_HAUT and h.haut+DIFF_HAUT
               ) surf
        from ( select haut
               from e
               group by haut
            ) h -- ensemble des hauteurs � prendre en compte
        order by 2 desc
        ;

    cursor c_uee_cou(x_pref varchar2,x_pss varchar2,x_stack varchar2,x_haut number) is
        with e as ( -- ensemble des colis � prendre en compte
                select e.no_uee,
                       d.cod_pro_res cod_pro,
                       c.larg_cnt*c.long_cnt surf ,
                       c.haut_cnt_plein haut
                from su_cnt c,pc_uee e,pc_uee_det d,pc_lig_com l
                where e.no_uee=D.NO_UEE
                and c.cod_cnt=e.cod_cnt
                and d.no_com=l.no_com
                and d.no_lig_com=l.no_lig_com
                and c.portab_cnt!='9'
                and e.id_session_lock=g_no_session_ora
                and e.libre_pc_uee_1 is null
                and e.cod_pss_afc=x_pss
                and nvl(L.cle_rgp_pal_pref_a_1,'#NULL#')=x_pref
                and (x_stack='z' or nvl(c.cod_stack,'-')=x_stack)
                and c.haut_cnt_plein between x_haut-DIFF_HAUT and x_haut+DIFF_HAUT
                  )
        select cod_pro,sum(surf) surf,min(haut) haut
        from e
        group by cod_pro
        order by 2 desc;

    cursor c_uee3 is
       select distinct libre_pc_uee_1 ,
              libre_pc_uee_2 ,
              libre_pc_uee_3
       from pc_uee e
       where e.id_session_lock=g_no_session_ora
         and e.libre_pc_uee_1 is not null
       order by 3;

    procedure local_add_uee_up(p_typ varchar2) is
        v_select    varchar2(32000);

        v_cursor    INTEGER;
        v_dummy     number;
        v_no_uee    pc_uee.no_uee%TYPE;
        v_no_uee2   pc_uee.no_uee%TYPE;
        v_no_com    pc_lig_com.no_com%TYPE;
        v_no_lig    number;
        v_vol_1     number;
        v_pds_1     number;
        v_nb_col_1  number;
        v_haut      number;
        v_sep_ob    varchar(10);
        v_sens_ob   varchar(10);
        v_order_by  varchar2(1000);
        v_all_order_by  varchar2(4000);
        v_pos       number;
        v_chaine    varchar2(50);

    BEGIN

        v_etape:='Construction du select';
        if p_typ='1' then
            v_select:='SELECT null no_uee,no_com,no_lig_com,min(no_uee) no_uee2';
        else
            v_select:='SELECT no_uee,min(no_com),min(no_lig_com),no_uee no_uee2';
        end if;

        v_select := v_select||',sum(vol),sum(pds),sum(nb_col_theo),min(haut)'
                            ||' from v_pexptsk_uee_det e'
                            ||' where e.id_session_lock=:id_session_lock' -- c'est ceux que je dois traiter
                            ||'   and cod_up is null';   -- ils n'ont pas �t� pris par la boucle pr�c�dente
        if p_typ='1' then
            v_select := v_select ||' group by no_com,no_lig_com';
        else
            v_select := v_select ||' group by no_uee';
        end if;

        v_etape:='Ajout des order by';
        if g_cfg_pal.order_by is not null then
            if not g_order_by.exists(g_cfg_pal.mode_calc_no_ord_pal) then
                v_etape:='Construction du order by';
                IF su_global_pkv.v_niv_dbg >= 9 THEN
                    su_bas_put_debug( v_nom_obj ||' : Make order by '||g_cfg_pal.order_by);
                END IF;
                v_pos := 1;
                v_sep_ob:=' ORDER BY ';
                LOOP
                    v_pos := su_bas_extract_liste(v_pos,g_cfg_pal.order_by,v_chaine);
                    EXIT WHEN v_pos <=0;
                    IF v_chaine IS NOT NULL THEN
                       if substr(v_chaine,1,1)='-' then
                           v_sens_ob:=' DESC';
                           v_order_by:=su_bas_rch_action('CLE_NO_ORD_PAL_HETER',substr(v_chaine,2));
                       else
                           v_sens_ob:='';
                           v_order_by:=su_bas_rch_action('CLE_NO_ORD_PAL_HETER',v_chaine);
                       end if;

                       v_all_order_by:=v_all_order_by||v_sep_ob||v_order_by||v_sens_ob;
                       v_sep_ob:=',';
                    END IF;
                END LOOP;
                g_order_by(g_cfg_pal.mode_calc_no_ord_pal) := v_all_order_by;
            end if;
            v_select := v_select || g_order_by(g_cfg_pal.mode_calc_no_ord_pal);
        end if;

        IF su_global_pkv.v_niv_dbg >= 9 THEN
            su_bas_put_debug( v_nom_obj ||' : '||v_select);
        END IF;

        v_etape:='Open';
        v_cursor := dbms_sql.open_cursor;
        v_etape:='Parse';
        dbms_sql.parse(v_cursor,v_select, dbms_sql.native);
        v_etape:='Bind';
        dbms_sql.bind_variable_char(v_cursor,':id_session_lock',g_no_session_ora);
        if instr(v_select,':p_nb_pal')>0 then
            dbms_sql.bind_variable(v_cursor,':p_nb_pal',g_nb_pal);
        end if;
        if instr(v_select,':p_vol')>0 then
            dbms_sql.bind_variable(v_cursor,':p_vol',p_vol);
        end if;

        v_etape:='define';
        dbms_sql.define_column( v_cursor,1,v_no_uee,20 );
        dbms_sql.define_column( v_cursor,2,v_no_com,20 );
        dbms_sql.define_column( v_cursor,3,v_no_lig );
        dbms_sql.define_column( v_cursor,4,v_no_uee2,20 );
        dbms_sql.define_column( v_cursor,5,v_vol_1 );
        dbms_sql.define_column( v_cursor,6,v_pds_1 );
        dbms_sql.define_column( v_cursor,7,v_nb_col_1 );
        dbms_sql.define_column( v_cursor,8,v_haut );
        v_etape:='Execute';
        v_dummy := dbms_sql.EXECUTE( v_cursor );
        v_etape:='Fetch';
        while dbms_sql.fetch_rows(v_cursor)>0
        loop
            dbms_sql.column_value(v_cursor,1,v_no_uee);
            dbms_sql.column_value(v_cursor,2,v_no_com);
            dbms_sql.column_value(v_cursor,3,v_no_lig);
            dbms_sql.column_value(v_cursor,4,v_no_uee2);
            dbms_sql.column_value(v_cursor,5,v_vol_1);
            dbms_sql.column_value(v_cursor,6,v_pds_1);
            dbms_sql.column_value(v_cursor,7,v_nb_col_1);
            dbms_sql.column_value(v_cursor,8,v_haut);

            IF su_global_pkv.v_niv_dbg >= 9 THEN
                su_bas_put_debug( v_nom_obj ||' : UEE='||v_no_uee||' / '||v_no_uee2||' Com='||v_no_com||' Lig='||v_no_lig
                ||' Nb col='||v_nb_col_1||' Vol='||v_vol_1||' Pds='||v_pds_1||' Haut='||v_haut);
            END IF;

            if v_vol_1+v_vol <= g_cfg_pal.vol_max  -- on s'assure que l'on ne d�passe jamais le volume max
            or v_vol=0  -- cas ligne commande > vol max
            then
                if v_no_uee is null then
                    update pc_uee
                    set cod_up=p_cod_up,
                        typ_up='P1',
                        etat_atv_pc_uee=g_etat_uee_tmp
                    where no_uee in (select d.no_uee
                                     from pc_uee e,pc_uee_det d
                                     where e.no_uee=d.no_uee
                                       and e.id_session_lock=g_no_session_ora -- ne prendre que les UEE marqu�es
                                       and e.cod_up is null
                                       and d.no_com=v_no_com
                                       and d.no_lig_com=v_no_lig) ;
                else
                    update pc_uee
                    set cod_up=p_cod_up,
                        typ_up='P1',
                        etat_atv_pc_uee=g_etat_uee_tmp
                    where no_uee=v_no_uee ;
                end if;

                v_vol:=v_vol+v_vol_1;
                v_nb_col:=v_nb_col+v_nb_col_1;
                v_pds:=v_pds+v_pds_1;

                IF su_global_pkv.v_niv_dbg >= 9 THEN
                    su_bas_put_debug( v_nom_obj ||' : Vol='||v_vol||' /'||g_vol_seuil_min);
                END IF;

                exit when v_vol >= g_vol_seuil_min; -- on s'arr�te d�s que l'on a d�pass� le volume min
            end if;
        end loop;

        dbms_sql.close_cursor(v_cursor);

    exception
        WHEN OTHERS THEN
            IF ( dbms_sql.is_open( v_cursor ) ) THEN
                dbms_sql.close_cursor( v_cursor );
            END IF;
            raise;
    end;

    procedure local_add_all_uee_up(p_pref varchar2 default null) is
        cursor c_uee is
            select no_uee,vol,pds,nb_col_theo
            from v_pexptsk_uee_det e,table(g_uee) t
            where t.column_value=e.no_uee
              and e.etat_atv_pc_uee=g_etat_uee
              and e.id_session_lock is null
              and e.lst_grp like p_grp||'%'
              and (p_pref is null or cle_rgp_pal_pref_A_1 = p_pref);
    begin
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug( v_nom_obj ||': ADD all uee pref=' ||p_pref);
        END IF;
        for r_uee in c_uee
        loop
            update pc_uee
            set cod_up=p_cod_up,
                typ_up='P1',
                etat_atv_pc_uee=g_etat_uee_tmp
            where no_uee=r_uee.no_uee ;

            v_vol   := v_vol+r_uee.vol;
            v_nb_col:= v_nb_col+r_uee.nb_col_theo;
            v_pds   := v_pds+r_uee.pds;
        end loop;

    end;

BEGIN
    savepoint my_pc_bas_add_uee_up;

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 5 THEN
        su_bas_put_debug( v_nom_obj ||' : UP '||p_cod_up||' Grp '||p_grp||' Vol '||p_vol||' Vol max '||g_vol_seuil_max);
    END IF;

    if p_vol <= g_vol_seuil_max then
        v_etape:='Tout le groupe rentre thqt sur une palette';
        local_add_all_uee_up;
    else

        v_etape:='Recherche des lignes de commandes par pr�f�rence';
        loop
            r_pref:=null;
            v_etape:='Rch pr�f�rence la + volumineuse mais inf�rieure au volume restant';
            open c_pref(g_vol_seuil_min-v_vol);
            fetch c_pref into r_pref;
            close c_pref;
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug( v_nom_obj ||' : pref=' ||r_pref.cle_rgp_pal_pref_A_1||' vol='||r_pref.vol);
            END IF;
            exit when nvl(r_pref.vol,0)=0; -- rien trouv�

            local_add_all_uee_up(r_pref.cle_rgp_pal_pref_A_1);

            if g_is_deg=0 then -- la solution n'est pas d�gradable
                v_seuil_next:=(g_nb_pal-1)*g_vol_seuil_min*g_taux_remp;  -- % du volume des palettes restantes pour arr�ter la compl�tion (seuil � 85% pour tenir compte des rejets Cube-IQ)

/* gestion d'un seuil. ex :
Vol min= 1123 nb pal = 3
N� 1 Vol=461
N� 2 Vol=34
N� 3 Vol=913
N� 4 Vol=1015

on essaye de mettre  1 et 2 ensembles :

1� fois on prend le n� 4 , ce qui reste =1408 (461+34+913) < 1684 (2*1123*0.75)
2� fois on prend le n� 3 , ce qui reste =495 (461+34) < 842 (1123*0.75)
3� fois on prend 1 et 2

*/

                exit when (p_grp is null) and ((p_vol-v_vol) <= v_seuil_next); -- ce qui reste tient sur les palettes restantes
            end if;

        end loop;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug( v_nom_obj ||' : vol reste=' ||to_char(p_vol-v_vol)||' Seuil next ='||v_seuil_next||' Is deg ='||g_is_deg);
        END IF;

        -- ne compl�ter la palette que si n�cessaire
        if p_grp is not null -- on est pas sur le groupe "maitre"
        or v_vol=0           -- on a encore rien fait
        or p_vol-v_vol >  v_seuil_next -- ce qui reste ne tient pas sur les palettes restantes
        then

            v_etape:='Blocage UEE pour �tre pris par curseur dynamique';
            update pc_uee
            set id_session_lock=g_no_session_ora,
                lst_fct_lock=';PEXP;',
                libre_pc_uee_1=null,   -- effacer les calculs pr�c�dents
                libre_pc_uee_2=null,
                libre_pc_uee_3=null,
                libre_pc_uee_4=null
            where no_uee in (select no_uee
              from v_pexptsk_uee_det e,table(g_uee) t
              where t.column_value=e.no_uee
                and e.etat_atv_pc_uee=g_etat_uee
                and e.id_session_lock is null
                and e.lst_grp like p_grp||'%');

            /***************************
                Calcul des couches
            ****************************/

            v_etape:='Init volume restant de chaque UP';
            for i in 1 .. g_nb_pal
            loop
                if i=1 then -- 1� palette
                    vt_vol_up(1):=g_vol_seuil_min-v_vol;
                    v:=p_vol-g_vol_seuil_min;
                elsif i=g_nb_pal then -- derni�re palette
                    vt_vol_up(i):=v;
                else
                    vt_vol_up(i):=g_vol_seuil_min;
                    v:=v-g_vol_seuil_min;
                end if;
                IF su_global_pkv.v_niv_dbg >= 9 THEN
                    su_bas_put_debug( v_nom_obj ||' : UP='||i||' Vol='||vt_vol_up(i));
                END IF;
            end loop;


            for dc in 1 .. 2  -- gestion 1/2 couche
            loop

                if dc=1 then
                    v_etape:='Calcul des couches - cas des produits >= 1 couche';
                    for r_cou_1 in c_cou_1
                    loop

                        if su_global_pkv.v_niv_dbg>=9 then
                            su_bas_put_debug(v_nom_obj ||' : Cou Pro='||r_cou_1.cod_pro_res||' Vol='||r_cou_1.vol||' Cle='||r_cou_1.cle);
                        end if;

                       update pc_uee
                       set libre_pc_uee_1=v_no_cou,
                           libre_pc_uee_2=r_cou_1.vol,
                           libre_pc_uee_3=r_cou_1.cle
                       where no_uee in (select e.no_uee
                                        from pc_uee e,pc_uee_det d
                                        where e.id_session_lock=g_no_session_ora
                                          and e.no_uee=d.no_uee
                                          and d.cod_pro_res=r_cou_1.cod_pro_res);


                       v_no_cou:=v_no_cou+1;
                    end loop;
                end if;

                v_etape:='Couche Mono/Multi stacks';
                for ges_cou in 0 .. 1
                loop

                    v_etape:='Rch des cl�s';
                    for r_cou_mono in c_cou_mono(ges_cou) -- couches mono pr�f 1, process et stack
                    loop
                        if su_global_pkv.v_niv_dbg>=9 then
                            su_bas_put_debug(v_nom_obj ||' : Pref='||r_cou_mono.pref||' Pss='||r_cou_mono.pss||' Stack='||r_cou_mono.stack);
                        end if;
                        loop
                            v_maj:=false;
                            v_etape:='Rch hauteur de r�f�rence pour la couche';
                            for r_uee2 in c_uee2(r_cou_mono.pref,r_cou_mono.pss,r_cou_mono.stack)
                            loop
                                if su_global_pkv.v_niv_dbg>=9 then
                                    su_bas_put_debug(v_nom_obj ||' : Haut pivot='||r_uee2.haut||' Surf='||r_uee2.surf||'/'||to_char(SURF_SEUIL/dc));
                                end if;
                                if  r_uee2.haut is null then
                                    v_etape:='Hauteur pivot incoh�rente';
                                    raise err_except;
                                end if;
                                exit when r_uee2.surf<(SURF_SEUIL/dc); -- plus assez de surface pour faire une couche
                                v_etape:='Rch des produits qui vont servir � faire la couche';
                                v_surf:=0;
                                v_surf2:=0;
                                v_haut:=0;
                                v_haut2:=0;
                                v_lst_pro:=';';
                                v_lst_pro2:=null;
                                v_vol_cou:=0;     -- $MOD tcho : init du v_vol_cou et non du v_vol !
                                for r_uee_cou in c_uee_cou(r_cou_mono.pref,r_cou_mono.pss,r_cou_mono.stack,r_uee2.haut)
                                loop
                                    if v_surf+r_uee_cou.surf>=0 then -- suffisamment de place
                                        v_lst_pro:=v_lst_pro||r_uee_cou.cod_pro||';';
                                        v_surf:=v_surf+r_uee_cou.surf;
                                        if r_uee_cou.haut>v_haut then
                                            v_haut:=r_uee_cou.haut;
                                        end if;
                                    elsif v_lst_pro2 is null
                                      or v_surf+r_uee_cou.surf<v_surf2 then -- prendre ceux qui d�passent le moins
                                        v_lst_pro2:=v_lst_pro||r_uee_cou.cod_pro||';';
                                        v_surf2:=v_surf+r_uee_cou.surf;
                                        if r_uee_cou.haut>v_haut then
                                            v_haut2:=r_uee_cou.haut;
                                        else
                                            v_haut2:=v_haut;
                                        end if;
                                    end if;
                                end loop;
                                if v_surf>=(SURF_SEUIL/dc) then -- c'est bon : on a assez pour faire une couche
                                    v_vol_cou:=v_surf*v_haut;
                                elsif v_lst_pro2 is not null then -- tant pis : on prend celle qui d�borde
                                    v_lst_pro:=v_lst_pro2;
                                    v_vol_cou:=v_surf2*v_haut2;
                                end if;
                                if su_global_pkv.v_niv_dbg>=9 then
                                    su_bas_put_debug(v_nom_obj ||' : N� cou='||v_no_cou||' Produits='||v_lst_pro ||' Vol='||v_vol_cou);
                                end if;

                                if v_vol_cou>0 then
                                    v_etape:='Mise � jour des UEE pour la couche';
                                    update pc_uee
                                    set libre_pc_uee_1=v_no_cou,
                                        libre_pc_uee_2=v_vol_cou,
                                        libre_pc_uee_3=r_cou_mono.pref||'-'||r_cou_mono.pss||'-'||r_cou_mono.stack
                                    where no_uee in (select e.no_uee
                                                     from su_cnt c,pc_uee e,pc_uee_det d,pc_lig_com l
                                                     where e.no_uee=D.NO_UEE
                                                       and c.cod_cnt=e.cod_cnt
                                                       and d.no_com=l.no_com
                                                       and d.no_lig_com=l.no_lig_com
                                                       and c.portab_cnt!='9'
                                                      and e.id_session_lock=g_no_session_ora
                                                      and e.libre_pc_uee_1 is null
                                                      and e.cod_pss_afc=r_cou_mono.pss
                                                      and nvl(L.cle_rgp_pal_pref_a_1,'#NULL#')=r_cou_mono.pref
                                                      and (r_cou_mono.stack='z' or nvl(c.cod_stack,'-')=r_cou_mono.stack)
                                                      and instr(v_lst_pro,';'||d.cod_pro_res||';')>0
                                                    );

                                   v_no_cou:=v_no_cou+1;
                                   v_maj:=true;
                                   exit; -- on recherche une autre hauteur pivot
                                end if;
                            end loop; -- haut pivot
                            exit when not v_maj; -- on sort si on a rien mis � jour
                        end loop; -- nouvelle hauteur pivot
                    end loop; -- mono
                end loop; --ges_stack

                v_etape:='Distribution des couches sur les palettes';
                p:=g_nb_pal; -- palette courante (init � la pr�c�dente = la derni�re)
                p2:=p; -- derni�re palette ou on a affect� une couche
                for r_uee3 in c_uee3
                loop
                    IF su_global_pkv.v_niv_dbg >= 9 THEN
                        su_bas_put_debug( v_nom_obj ||' : Cou='||r_uee3.libre_pc_uee_1
                        ||' Vol='||r_uee3.libre_pc_uee_2||' Cl�='||r_uee3.libre_pc_uee_3);
                    END IF;
                    v:=su_bas_to_number(r_uee3.libre_pc_uee_2)/1000000; -- volume couche
                    loop
                        -- palette suivante
                        if p=g_nb_pal then
                            p:= 1;
                        else
                            p:=p+1;
                        end if;
                        exit when p=p2 -- on a fait un tour => on force sur cette palette
                               or v<=vt_vol_up(p);  -- la couche rentre dans le volume de la palette
                    end loop;

                    update pc_uee
                    set libre_pc_uee_4=p -- affectation palette � la couche
                    where id_session_lock=g_no_session_ora
                      and libre_pc_uee_1=r_uee3.libre_pc_uee_1
                      and libre_pc_uee_2=r_uee3.libre_pc_uee_2
                      and libre_pc_uee_3=r_uee3.libre_pc_uee_3;

                    vt_vol_up(p) :=vt_vol_up(p)-v;
                    p2:=p;
                    IF su_global_pkv.v_niv_dbg >= 9 THEN
                        su_bas_put_debug( v_nom_obj ||' : UP affect�='||p||' Vol rest='|| vt_vol_up(p));
                    END IF;
                end loop;

            end loop; -- dc

            v_etape:='Recherche des lignes de commandes � mettre sur une UP';
            local_add_uee_up('1');

            if v_vol < g_vol_seuil_min and g_cfg_pal.autor_fract='1' then -- idem mais � l'uee
                v_etape:='Recherche des uee � mettre sur une UP';
                local_add_uee_up('2');
            end if;
        end if;
    end if;

    if v_vol=0 then
        v_etape:='Rien n''a �t� palettis�';
        raise err_except;
    end if;

    v_etape:='Mise � jour de l''UP';
    update pc_up
    set nb_uee=v_nb_col,
        vol_reel=v_vol,
        pds_brut_reel=v_pds
    where cod_up=p_cod_up
      and typ_up='P1';

    -- d�cr�mentation de ce qui reste � faire
    g_nb_pal:=g_nb_pal-1;
    g_vol_reste:=g_vol_reste-v_vol;

    return 'OK';

EXCEPTION
    WHEN OTHERS THEN
        rollback to savepoint my_pc_bas_add_uee_up;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_cod_usn         => g_cod_usn,
                        p_lib_ano_1       => 'Grp',
                        p_par_ano_1       => p_grp,
                        p_lib_ano_2       => 'UP',
                        p_par_ano_2       => p_cod_up,
                        p_lib_ano_3       => 'Vol',
                        p_par_ano_3       => p_vol,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
end;

/*
****************************************************************************
* pc_bas_split_up_process - S�pararation en 2 UP1 si multi process
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de s�parer l'UP en 2 UP1 + 1 UP2 sup�rieure
-- si palette multi-process (M�canis�+d�bord)
--
-- PARAMETRES :
-- ------------
--  cod_up
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,20.11.14,pluc    Test MODE_CAL_COORD_UEE pour diff�rencier process m�ca
--                      et non m�ca.
-- 01a,23.07.14,tcho    Cr�ation (SUO)
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK/ERROR+ volume palettis� ou -1
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_split_up_process (p_cod_up in out nocopy varchar2,p_grp varchar2)
return varchar2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_split_up_process';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-54';
    err_except          EXCEPTION;

    v_ret               varchar2(100);
    v_cod_up2           pc_up.cod_up%TYPE;
    v_cod_up1           pc_up.cod_up%TYPE;
    v_vol               number:=0;
    v_nb_col            number:=0;
    v_pds               number:=0;
    v_new_haut          number;
    v_new_tol           number;

    cursor c_pss is
       select min(cod_pss_afc) pss_min,max(cod_pss_afc) pss_max,
              max(su_bas_rch_cle_atv_pss_2 (cod_pss_afc, 'POR', 'MODE_CAL_COORD_UEE')) is_meca
       from pc_uee e
       where e.cod_up=p_cod_up
         and e.typ_up='P1'
         and cod_pss_afc is not null;

    r_pss c_pss%ROWTYPE;

    cursor c_uee is
        select no_uee,vol_theo,pds_theo,nb_col_theo
        from pc_uee
        where cod_up=p_cod_up
          and typ_up='P1'
          and su_bas_rch_cle_atv_pss_2 (cod_pss_afc, 'POR', 'MODE_CAL_COORD_UEE') = '0';

    cursor c_up is
       select haut_std*(1+(NVL(tol_max,0)/100)) haut_max,vol_reel,haut_std
       from pc_up
       where cod_up=p_cod_up
         and typ_up='P1';

    r_up c_up%ROWTYPE;

BEGIN

    SAVEPOINT my_pc_bas_split_up_process;

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 5 THEN
        su_bas_put_debug( v_nom_obj ||' : UP='||p_cod_up);
    END IF;

    v_etape:='Rch des process';
    open c_pss;
    fetch c_pss into r_pss;
    if c_pss%NOTFOUND then -- UP vide !!!!
        v_cod_err_su_ano:='ANO-000000';
        raise err_except;
    end if;
    close c_pss;

    v_etape:='Test process';
    if r_pss.is_meca=0 then -- non m�canis�
        update pc_uee   -- d�clar� comme pr�s � �tre pr�par�
        set etat_atv_pc_uee=g_etat_uee_fin
        where cod_up=p_cod_up
          and typ_up='P1' ;
        p_cod_up:=null; -- pour ne pas envoyer � CUBEIQ
        return 'OK';
    elsif r_pss.pss_min=r_pss.pss_max then -- mono-process  (m�canis�)
        return 'OK'; -- on ne change rien
    end if;

    ----------------
    -- multi-process
    ----------------

    v_etape:='Cr�ation UP2';
    v_ret:=pc_bas_cre_new_up (p_grp,v_cod_up2,'P2');
    if v_ret!='OK' then
        raise err_except;
    end if;

    v_etape:='Cr�ation 2� UP1';
    v_ret:=pc_bas_cre_new_up (p_grp,v_cod_up1,'P1');
    if v_ret!='OK' then
        raise err_except;
    end if;

    v_etape:='Mise � jour des UEE';
    for r_uee in c_uee
    loop
        update pc_uee
        set cod_up=v_cod_up1,
            typ_up='P1',
            etat_atv_pc_uee=g_etat_uee_fin
        where no_uee=r_uee.no_uee ;

        v_vol   := v_vol+r_uee.vol_theo;
        v_nb_col:= v_nb_col+r_uee.nb_col_theo;
        v_pds   := v_pds+r_uee.pds_theo;
    end loop;


    v_etape:='Rch info UP meca';
    open c_up;
    fetch c_up into r_up;
    if c_up%NOTFOUND then
        raise err_except;
    end if;
    close c_up;

    v_etape:='Calcul nouvelle hauteur pour cubeiq';
    v_new_haut:=r_up.haut_max-((v_vol*su_bas_to_number(su_bas_rch_par_usn('SP_PLANEXP_FOIS_PSS','S','SDB01')))/(1.2*0.8)); -- enlever la hauteur r�serv�e au d�bord
    if v_new_haut<450 then -- hauteur minimum pour arriver � faire une couche
        v_new_haut:=450;
    end if;

    v_new_tol := round(((v_new_haut/r_up.haut_std)-1)*100,2);

    v_etape:='Mise � jour old UP1';
    update pc_up
    set nb_uee=nb_uee-v_nb_col,
        vol_reel=vol_reel-v_vol,
        pds_brut_reel=pds_brut_reel-v_pds,
        cod_up_sup=v_cod_up2,
        typ_up_sup='P2',
        tol_max=v_new_tol
    where cod_up=p_cod_up
      and typ_up='P1';

    v_etape:='Mise � jour new UP1';
    update pc_up
    set nb_uee=v_nb_col,
        vol_reel=v_vol,
        pds_brut_reel=v_pds,
        cod_up_sup=v_cod_up2,
        typ_up_sup='P2',
        cod_cnt_up=nvl(g_cfg_pal.cod_cnt_subst,g_cfg_pal.cod_cnt_pal)
    where cod_up=v_cod_up1
      and typ_up='P1';

    return 'OK';

EXCEPTION
    WHEN OTHERS THEN
        rollback to my_pc_bas_split_up_process;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_cod_usn         => g_cod_usn,
                        p_lib_ano_1       => 'UP',
                        p_par_ano_1       => p_cod_up,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
end;

/*
****************************************************************************
* pc_bas_cre_up_with_uee - Cr�ation d'une nouvelle UP
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de cr�er une nouvelle UP et d'y rajouter les UEE
--
-- PARAMETRES :
-- ------------
--  Mask du groupe
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 02a,31.07.13,tcho    Sp�cification SUO
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK/ERROR+ volume palettis� ou -1
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_cre_up_with_uee (p_grp varchar2,p_vol number)
return varchar2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_cre_up_with_uee';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-54';
    err_except          EXCEPTION;

    v_ret               varchar2(100);

    v_cod_up            pc_up.cod_up%TYPE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 4 THEN
        su_bas_put_debug( v_nom_obj ||' : Grp='||p_grp||' Vol='||p_vol);
    END IF;

    v_etape:='Cr�ation UP';
    v_ret :=  pc_bas_cre_new_up(p_grp ,v_cod_up);
    if v_ret!='OK' or v_cod_up is null then
        raise err_except;
    end if;

    v_etape:='Ajout des UEE sur l''UP';
    v_ret:=pc_bas_add_uee_up (v_cod_up,p_grp,p_vol);
    if v_ret!='OK' then
        raise err_except;
    end if;

    v_etape:='Gestion multi process';
    v_ret:=pc_bas_split_up_process(v_cod_up,p_grp);
    if v_ret!='OK' then
        raise err_except;
    end if;

    if v_cod_up is not null then -- peut �tre pass�e � NULL si uniquement process d�bord
        v_etape:='Envoi de l''UP � CUBE-IQ';
        insert into su_dia_cubeiq
        (no_msg_cubeiq,etat_msg,cod_usn,command_cubeiq,par_cubeIQ_1,par_cubeIQ_2)
        values
        (SEQ_SU_DIA_CUBEIQ.nextval,1,g_cod_usn,'ASYNCOPTIMIZE','P1',v_cod_up);
    end if;

    v_etape:='Lib�ration des uee';
    update pc_uee
    set ID_session_lock=null,
        lst_fct_lock=null
    where iD_session_lock=g_no_session_ora;

    su_bas_commit_transaction;

    return 'OK';

EXCEPTION
    WHEN OTHERS THEN
        rollback;
        --v_etape:='Lib�ration des uee';
        update pc_uee
        set ID_session_lock=null,
            lst_fct_lock=null
        where iD_session_lock=g_no_session_ora;
        commit;

        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_cod_usn         => g_cod_usn,
                        p_lib_ano_1       => 'Grp',
                        p_par_ano_1       => p_grp,
                        p_lib_ano_2       => 'Vol',
                        p_par_ano_2       => p_vol,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
end;

/*
****************************************************************************
* pc_bas_pal_grp - palettisation par grp
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de calculer une palettisation par grp, et sous-grp
-- et ceci de mani�re r�cursive
--
-- PARAMETRES :
-- ------------
--  utilisation des pr�f�rences 1 � 3
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou OK2 (=OK avec lancement) ou code erreur
--
-- COMMIT :
-- --------
--   OUI

FUNCTION pc_bas_pal_grp (p_grp varchar2 default null,
                         p_niv integer default 1)
return varchar2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_pal_grp';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-58';
    err_except          EXCEPTION;

    v_ret               varchar2(100);
    v_nb_grp            number;
    v_nb_grp_run        number;
    v_vol_pal           number;

    cursor c_uee is
      select su_bas_get_nieme_val ( lst_grp,';',p_niv,0,1) ss_grp,
             sum(e.vol) vol,
             min(lst_grp) lst_grp
      from v_pexptsk_uee_det e,table(g_uee) t
      where t.column_value=e.no_uee
        and e.etat_atv_pc_uee=g_etat_uee
        and e.lst_grp like p_grp||'%'
      group by  su_bas_get_nieme_val ( lst_grp,';',p_niv,0,1)
      order by 2 desc;

     r_uee_v c_uee%ROWTYPE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug( v_nom_obj ||' : Grp '||p_grp||' Niv '||p_niv);
    END IF;

    v_etape:='Rch par sous groupe';
    v_nb_grp:=0;
    v_nb_grp_run:=0;
    v_vol_pal:=0;
    for r_uee in c_uee
    loop
        v_nb_grp:=v_nb_grp+1;
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug( v_nom_obj ||' : N� '||v_nb_grp||' Vol='||r_uee.vol||' / '||g_vol_seuil_min||' lst='||r_uee.lst_grp||' is deg='||g_is_deg);
        END IF;
        if r_uee.ss_grp is not null and
            (r_uee.vol>=g_vol_seuil_min or -- sous groupe > vol palette
             (r_uee.vol>=g_vol_seuil_min*g_taux_remp and g_vol_reste-r_uee.vol<(g_nb_pal-1)*g_vol_seuil_min*g_taux_remp and g_is_deg=0) --sous groupe > 75% vol palette et ce qui reste <75% volume qui reste
            )
            then
            if r_uee.vol>g_vol_seuil_min and su_bas_get_nieme_val ( r_uee.lst_grp,';',p_niv+1,0,1) is not null  then -- il existe un sous sous groupe ?
                v_etape:='Recherche de palettisation des sous-sous-groupe';
                v_ret:=pc_bas_pal_grp (nvl(p_grp,';')||r_uee.ss_grp||';',p_niv+1);   -- r�cursif
            else
                v_ret:='OK';
            end if;
            if v_ret='OK' then
                v_etape:='Palettisation du sous-groupe';
                v_ret:=pc_bas_cre_up_with_uee (nvl(p_grp,';')||r_uee.ss_grp||';',r_uee.vol);
                if v_ret!='OK' then
                    raise err_except;
                end if;
            elsif v_ret!='OK2' then -- => erreur
                raise err_except;
            end if;
            v_nb_grp_run:=v_nb_grp_run+1; -- On a lanc� un sous-groupe ou sous-sous-groupe
        end if;
        if r_uee.vol >nvl(r_uee_v.vol,0) then -- m�moriser le ss groupe le + volumineux
            r_uee_v:=r_uee;
        end if;
    end loop;

    if p_niv>1 and v_nb_grp_run>0 then
        return 'OK2';  -- on a lanc� au moins 1 sous-groupe
    end if;

    if v_nb_grp_run=0 and p_niv=1  then -- on a pas lanc� de sous groupe
        v_etape:='Palettisation du groupe';
        v_ret:=pc_bas_cre_up_with_uee (p_grp,g_vol_reste);
        if v_ret!='OK' then
            raise err_except;
        end if;
    end if;

    return 'OK';

EXCEPTION
    WHEN OTHERS THEN
        rollback ;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_cod_usn         => g_cod_usn,
                        p_lib_ano_1       => 'Groupe',
                        p_par_ano_1       => p_grp,
                        p_lib_ano_2       => 'Niveau',
                        p_par_ano_2       => p_niv,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;

/*
****************************************************************************
* pc_bas_plan_exp_usn - Calcul du plan d'exp�dition pour une usine
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de lancer la palettisation pour une usine
--
-- PARAMETRES :
-- ------------
--  code usine
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 02a,16.06.14,tcho    Sp�cification Syst�me U
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_plan_exp_usn (p_cod_usn VARCHAR2)
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_plan_exp_usn';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-50';
    err_except          EXCEPTION;
    v_ret               varchar2(100);
    v_nb_deg            number;
    v_continue          boolean;
    v_nb                number;

    cursor c_exc is
      select cle_mode_pal_1,
             typ_pal_1,
             cle_rgp_pal_1,
             cod_cfg_pal_1,
             no_dpt,
             sum(vol) vol,
             min(no_uee) no_uee,
             count(distinct no_uee) nb_uee
      from v_pexptsk_uee
      where cod_usn=p_cod_usn
        and etat_atv_pc_uee=g_etat_uee
        and su_bas_etat_val_num(etat_atv_pc_ent_com,'PC_ENT_COM') <= g_etat_com_num
      group by cle_mode_pal_1,
             typ_pal_1,
             cle_rgp_pal_1,
             cod_cfg_pal_1,
             no_dpt
      order by vol desc -- prendre les signatures les + volumineuses d'abord, pour g�rer la d�gradation des mod�les � la fin
             ;

    cursor c_lock(x_cle_mode_pal_1 varchar2,
             x_typ_pal_1 varchar2,
             x_cle_rgp_pal_1 varchar2,
             x_cod_cfg_pal_1 varchar2,
             x_no_dpt varchar2
             ) is
      select count(distinct no_uee) nb_uee
      from v_pexptsk_uee_lock
      where cod_usn=p_cod_usn
        and etat_atv_pc_uee=g_etat_uee
        and su_bas_etat_val_num(etat_atv_pc_ent_com,'PC_ENT_COM') <= g_etat_com_num
        and cle_mode_pal_1=x_cle_mode_pal_1
        and  typ_pal_1=x_typ_pal_1
        and  cle_rgp_pal_1=x_cle_rgp_pal_1
        and  cod_cfg_pal_1=x_cod_cfg_pal_1
        and  no_dpt=x_no_dpt;

    cursor c_up_run IS
       select /*+ FIRST_ROWS_1 */ u.cod_up
       from pc_uee e,pc_up u
       where e.cod_up=u.cod_up
         and e.typ_up=u.typ_up
         and (e.etat_atv_pc_uee =g_etat_uee_tmp  -- UEE en cours
           or ( etat_up_complete='0' -- ou palette � valider manuellement
                AND su_bas_etat_val_num(e.etat_atv_pc_uee, 'PC_UEE') < su_bas_etat_val_num('TEST_FIN_PREPA', 'PC_UEE')
              )
             )
         and u.sgn_pal_up=g_uee_ref.sgn
         and rownum=1;

    r_up_run    c_up_run%ROWTYPE;

    Cursor c_uee_ref(x_no_uee varchar2) is
       select *
       from v_pexptsk_uee
       where no_uee=x_no_uee;

    cursor c_cfg_pal(x_cfg_pal varchar2,x_no_var varchar2) is
       select *
       from v_pexptsk_cfg_pal
       where cod_cfg_pal=x_cfg_pal
         and no_var_cfg_pal=x_no_var;


    cursor c_deg is
      select sum(vol) vol,
             count(decode(etat_atv_pc_uee,g_etat_uee_tmp,1,null)) nb_cours
      from v_pexptsk_uee
      where cod_usn=p_cod_usn
        and etat_atv_pc_uee in (g_etat_uee,g_etat_uee_tmp)
        and su_bas_etat_val_num(etat_atv_pc_ent_com,'PC_ENT_COM') <= g_etat_com_num
        and cle_mode_pal_1=g_uee_ref.cle_mode_pal_1
        and typ_pal_1=g_uee_ref.typ_pal_1
        and cle_rgp_pal_2=g_uee_ref.cle_rgp_pal_2
        and cod_cfg_pal_1=g_uee_ref.cod_cfg_pal_1
        and no_dpt=g_uee_ref.no_dpt
      group by cle_rgp_pal_1;

    cursor c_deg2 is
      select 1
      from v_pexptsk_uee
      where cod_usn=p_cod_usn
        and etat_atv_pc_uee in (g_etat_uee,g_etat_uee_tmp)
        and su_bas_etat_val_num(etat_atv_pc_ent_com,'PC_ENT_COM') <= g_etat_com_num
        and cle_mode_pal_1=g_uee_ref.cle_mode_pal_1
        and typ_pal_1=g_uee_ref.typ_pal_1
        and cle_rgp_pal_2=g_uee_ref.cle_rgp_pal_2
        and cle_rgp_pal_1!=g_uee_ref.cle_rgp_pal_1
        and cod_cfg_pal_1=g_uee_ref.cod_cfg_pal_1
        and no_dpt=g_uee_ref.no_dpt;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug( v_nom_obj ||' : Usn '||p_cod_usn);
    END IF;
    g_cod_usn:=p_cod_usn;

    /* on recherche par palettisation exclusive, pour qu'en cas de probl�me
       on puisse continuer sur d'autres lignes de commandes
       mais pas celles-qui ont les m�mes affinit�s exclusives;
    */
    v_etape:='D�but d''activit� usine';
    su_bas_set_activity   ('Palettisation Usine '||p_cod_usn);

    v_etape:='Liberation des verrous'; -- en cas de plantage de la t�che de fond
    update pc_uee
    set id_session_lock=null,
        lst_fct_lock=null
    WHERE id_session_lock IS NOT NULL
      AND instr(lst_fct_lock, ';PEXP;') > 0
      and etat_atv_pc_uee=g_etat_uee
      and cod_usn=p_cod_usn;
    commit;

    v_etape:='Rch des palettisations exclusives';
    for r_exc in c_exc
    loop
        v_etape:='Activit� exclusive';
        su_bas_set_activity   ('Palettisation Usine '||p_cod_usn,
                               'Exclusivit� '||r_exc.no_dpt|| '/'|| r_exc.cle_mode_pal_1|| '/'|| r_exc.typ_pal_1|| '/'|| r_exc.cle_rgp_pal_1);

        v_ret:='OK';
        g_uee:=null;

        v_etape:='Rch si verrou en cours pour la signature';
        open c_lock(r_exc.cle_mode_pal_1,
             r_exc.typ_pal_1 ,
             r_exc.cle_rgp_pal_1 ,
             r_exc.cod_cfg_pal_1 ,
             r_exc.no_dpt );
        fetch c_lock into v_nb;
        close c_lock;

        v_continue:=(v_nb=r_exc.nb_uee); -- continuer si pas de lock

        if v_continue then

            v_etape:='Rch info UEE de r�f�rence';
            open c_uee_ref(r_exc.no_uee);
            fetch c_uee_ref into g_uee_ref;
            close c_uee_ref;

            v_etape:='Test si palette en cours pour la signature';
            open c_up_run;
            fetch c_up_run into r_up_run;
            v_continue :=c_up_run%NOTFOUND; -- on peut continuer si pas de palette en cours pour la m�me signature
            if not v_continue and su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug( v_nom_obj ||' : UP run '||r_up_run.cod_up||' sgn='||g_uee_ref.sgn);
            END IF;
            close c_up_run;
        end if;

        if v_continue then
            if (nvl(g_cfg_pal.cod_cfg_pal,'#NULL#')!=r_exc.cod_cfg_pal_1) then
                v_etape:='Rch info mod�le de palette';
                open c_cfg_pal(r_exc.cod_cfg_pal_1,0);
                fetch c_cfg_pal into g_cfg_pal ;
                close c_cfg_pal;

                if (nvl(g_cfg_pal.cod_cfg_pal,'#NULL#')!=r_exc.cod_cfg_pal_1) then
                    v_ret:='PC-PEXP-52';
                end if;
            end if;

            if v_ret='OK' and r_exc.typ_pal_1!='HETER' then -- Devrait �tre filtr� par la vue mais bon ...            v_etape:='Type de palettisation non g�r�e';
                v_ret:='PC-PEXP-53';
                v_continue:=false;
            end if;
        end if;

        if v_continue then
            v_etape:='Rch si on peut d�grader la solution';
            v_nb_deg:=0;
            IF su_global_pkv.v_niv_dbg >= 9 THEN
                su_bas_put_debug( v_nom_obj ||' Vol='||r_exc.vol||' / seuil= '||g_cfg_pal.vol_seuil||' Rgp2='||g_uee_ref.cle_rgp_pal_2);
            END IF;
            if r_exc.vol<=g_cfg_pal.vol_seuil            -- si volume groupe < seuil de d�gradation
            and g_uee_ref.cle_rgp_pal_2 is not null      -- et qu'il y a un mod�le d�grad�
            then
                for r_deg in c_deg
                loop
                    v_nb_deg:=v_nb_deg+1;
                    IF su_global_pkv.v_niv_dbg >= 9 THEN
                        su_bas_put_debug( v_nom_obj ||' Nb deg='||v_nb_deg||' Vol='||r_deg.vol||' / seuil= '||g_cfg_pal.vol_seuil||' Nb cours='||r_deg.nb_cours);
                    END IF;
                    if v_continue and (r_deg.vol>g_cfg_pal.vol_seuil or r_deg.nb_cours>0) then
                        v_continue:=false;
                    end if;
                    if not v_continue and v_nb_deg>1 then -- au moins 2 groupes dont un pas pr�s => il faut attendre
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug( v_nom_obj ||' : Attente avant d�gradation '||g_uee_ref.sgn);
                        END IF;
                        exit;
                    end if;
                end loop;
            end if;
            if v_nb_deg=1 then -- un seul groupe => pas de fusion possible => on continue
                 v_continue:=true;
            elsif v_nb_deg>1 and v_continue then -- tous les groupes sont pr�s � fusionner
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug( v_nom_obj ||' : D�gradation '||g_uee_ref.sgn);
                END IF;
                v_etape:='D�gradation du mod�le de palettisation';
                update pc_lig_com
                set CLE_RGP_PAL_1=CLE_RGP_PAL_2,
                    CLE_RGP_PAL_2=null,
                    CLE_RGP_PAL_PREF_A_1=CLE_RGP_PAL_PREF_B_1,
                    CLE_RGP_PAL_PREF_B_1=null
                where (no_com,no_lig_com) in (select distinct no_com,no_lig_com
                                 from v_pexptsk_uee
                                 where cod_usn=p_cod_usn
                                   and etat_atv_pc_uee=g_etat_uee
                                   and su_bas_etat_val_num(etat_atv_pc_ent_com,'PC_ENT_COM') <= g_etat_com_num
                                   and cle_mode_pal_1=g_uee_ref.cle_mode_pal_1
                                   and typ_pal_1=g_uee_ref.typ_pal_1
                                   and cle_rgp_pal_2=g_uee_ref.cle_rgp_pal_2
                                   and cod_cfg_pal_1=g_uee_ref.cod_cfg_pal_1
                                   and no_dpt=g_uee_ref.no_dpt);

                commit;
                RETURN; -- sortie de la proc�dure car cela remet en question le curseur initial
            end if;
        end if;

        if v_continue then
            v_etape:='Init des UEE � palettiser';
            select distinct no_uee
            bulk collect into g_uee
            from v_pexptsk_uee
            where cod_usn=p_cod_usn
              and etat_atv_pc_uee=g_etat_uee
              and su_bas_etat_val_num(etat_atv_pc_ent_com,'PC_ENT_COM') <= g_etat_com_num
              and cle_mode_pal_1=r_exc.cle_mode_pal_1
              and typ_pal_1=r_exc.typ_pal_1
              and nvl(cle_rgp_pal_1,'#NULL#')=nvl(r_exc.cle_rgp_pal_1,'#NULL#')
              and cod_cfg_pal_1=r_exc.cod_cfg_pal_1
              and no_dpt=r_exc.no_dpt;

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj ||' : Nb UEE='||g_uee.count);
            end if;

            if g_uee.count=0 then
                v_ret:='PC-PEXP-56';
                v_continue:=false;
            end if;

        end if;

        if v_continue then
            v_etape:='Calcul des seuils et des volumes';
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug( v_nom_obj ||' : Vol '||r_exc.vol||' / '||g_cfg_pal.vol_min);
            END IF;
            v_ret:=pc_bas_calc_seuils (r_exc.vol);
        end if;

        if v_continue and v_ret='OK' then
            g_vol_reste:=r_exc.vol;
            if r_exc.vol<=g_vol_seuil_max then
                v_etape:='Palettisation 1 seule palette';
                v_ret:=pc_bas_cre_up_with_uee (null, r_exc.vol);
            else
                v_etape:='Rch s''il y a des chances que la solution puisse �tre d�grad�e';
                g_is_deg:=0;
                if g_uee_ref.cle_rgp_pal_2 is not null then
                    open c_deg2;
                    fetch c_deg2 into g_is_deg;
                    close c_deg2;
                end if;

                v_etape:='Palettisation par groupe';
                v_ret:=pc_bas_pal_grp;
            end  if;
        end if;

        if v_ret!='OK' then
            rollback;
            if v_ret!='ERROR' then
               v_cod_err_su_ano:=v_ret;
            end if;
            su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_lib_ano_1       => 'Usn',
                            p_par_ano_1       => p_cod_usn,
                            p_lib_ano_2       => 'Dpt',
                            p_par_ano_2       => r_exc.no_dpt,
                            p_lib_ano_3       => 'Mode pal',
                            p_par_ano_3       => r_exc.cle_mode_pal_1,
                            p_lib_ano_4       => 'Typ pal',
                            p_par_ano_4       => r_exc.typ_pal_1,
                            p_lib_ano_5       => 'Rgp pal',
                            p_par_ano_5       => r_exc.cle_rgp_pal_1,
                            p_lib_ano_6       => 'Cfg pal',
                            p_par_ano_6       => r_exc.cod_cfg_pal_1,
                            p_cod_usn         => p_cod_usn,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_PLANEXP');
            if g_uee.count>0 then
                v_etape:='Mise en erreur des UEE';
                pc_bas_plan_exp_err (v_ret);
            end if;
        end if;
    end loop;


EXCEPTION
    WHEN OTHERS THEN
        rollback;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_lib_ano_1       => 'Usn',
                        p_par_ano_1       => p_cod_usn,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_PLANEXP');
END;

/*
****************************************************************************
* pc_bas_plan_exp_loop - t�che de fond de calcul du plan d'exp�dition
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de lancer la palettisation pour chaque usine
--
-- PARAMETRES :
-- ------------
--  param�tres standard des t�ches de fond
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,31.07.13,tcho    Cr�ation
-- 00a,31.07.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  dans p_ret : CONTINUE, WAIT ou EXIT
--


PROCEDURE pc_bas_plan_exp_loop (p_id_tsk VARCHAR2,
                          p_par_tsk_fond_1 VARCHAR2, -- lst usine
                          p_par_tsk_fond_2 VARCHAR2,
                          p_par_tsk_fond_3 VARCHAR2,
                          p_par_tsk_fond_4 VARCHAR2,
                          p_par_tsk_fond_5 VARCHAR2,
                          p_cod_ope_tsk VARCHAR2,
                          p_tps_cycle NUMBER,
                          p_cmd_unix OUT VARCHAR2,
                          p_ret OUT VARCHAR2)
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_plan_exp_loop';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-PEXP-50';
    err_except          EXCEPTION;

    cursor c_usn is
       select cod_usn
       from su_usn
       where (p_par_tsk_fond_1 is null
            or p_par_tsk_fond_1='*'
            or p_par_tsk_fond_1='%'
            or instr(p_par_tsk_fond_1,';'||cod_usn||';')>0)
         and exists ( select 1
                      from SU_PSS_ATV_CFG
                      where cod_pss='$'||su_usn.cod_usn  -- process usine
                        and cod_atv like 'POR%'     -- preordo
                        and cod_cfg_atv='CREA_PLAN' -- cr�ation plan
                        and val_cle_atv='5');       -- en mode asynchrone

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 1 THEN
        su_bas_put_debug( v_nom_obj ||' : Usn '||p_par_tsk_fond_1);
    END IF;

    v_etape:= 'Init variables globales'; -- r�init pour forcer la relecture des donn�es de config � chaque tour de boucle de la t�che
    g_etat_uee:=su_bas_rch_etat_atv('INTEGRATION_PLAN_ASYNC','PC_UEE');
    g_etat_uee_tmp:=su_bas_rch_etat_atv('TEMPORAIRE_PLAN','PC_UEE');
    g_etat_uee_fin:=su_bas_rch_etat_atv('VALIDATION_PLAN','PC_UEE');
    g_etat_up:=su_bas_rch_etat_atv('CREATION','PC_UP');
    g_etat_com_num:=su_bas_etat_val_num('PRPP','PC_ENT_COM');
    g_cfg_pal.cod_cfg_pal:=null;
    g_no_session_ora:=su_global_pkg.su_bas_get_no_session_ora;
    g_uee_ref.no_uee:=null;

    v_etape:='Palettisation par usine';
    for r_usn in c_usn
    loop
        su_global_pkg.su_bas_set_cod_usn(r_usn.cod_usn); --$MOD,20141013,croc trac 25425
        pc_bas_plan_exp_usn(r_usn.cod_usn);
    end loop;

    p_ret := 'WAIT';


EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_lib_ano_1       => 'Usn',
                        p_par_ano_1       => p_par_tsk_fond_1,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_PLANEXP');
        p_ret := 'EXIT';
END;

END; -- fin du package
/
show errors;

