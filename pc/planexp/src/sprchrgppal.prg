/* $Id$
****************************************************************************
* sp_bas_rch_rgp_pal - Recherche de la configuration de regroupement palette
*/
-- DESCRIPTION :
-- -------------
--
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,18.04.16,tjaf    Modification pour regroupement multicommande
-- 01a,25.08.14,pluc    Creation
-- 00a,24.10.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE FUNCTION sp_bas_rch_rgp_pal
    (
    p_no_com     pc_lig_com.no_com%TYPE,
    p_no_lig_com pc_lig_com.no_lig_com%TYPE
    )
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_rch_rgp_pal';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(20)  := NULL;

    CURSOR c_com IS
    SELECT e.cod_cli, l.cod_pro,
           s.libre_su_cli_7 cod_cfg_rgp_pal_1,
           s.libre_su_cli_8 cod_cfg_rgp_pal_2,
           su_bas_get_val_dim('$PRO', su_bas_rch_action('FRM_SP_CFG_RGP_PAL', 'COD_DIM'),l.cod_pro, '0', '0') val_dim,
           DECODE(INSTR(l.cod_pro, '*'), '0', 'PER', 'PRO') typ_pro,
           e.cod_usn,
           e.libre_pc_ent_com_6 opt_pal, e.libre_pc_ent_com_7 autor_fract,
           su_bas_to_number(e.libre_pc_ent_com_8) + 150 haut_std,
           su_bas_to_number(DECODE(e.libre_pc_ent_com_9, '0', e.libre_pc_ent_com_8, e.libre_pc_ent_com_9)) + 150 haut_max
    FROM   su_cli s, pc_ent_com e, pc_lig_com l
    WHERE  e.no_com     = p_no_com
    AND    e.no_com     = l.no_com
    AND    l.no_lig_com = p_no_lig_com
    AND    e.cod_cli    = s.cod_tiers
    AND    s.typ_tiers  = su_bas_get_typ_tiers_cli;

    r_com c_com%ROWTYPE;

    CURSOR c_cfg_rgp ( x_cod_cfg_rgp_pal sp_ent_cfg_rgp_pal.cod_cfg_rgp_pal%TYPE,
                       x_val_dim         sp_lig_cfg_rgp_pal.val_dim_pro_rgp%TYPE,
                       x_typ_pro         sp_lig_cfg_rgp_pal.typ_pro_rgp%TYPE) IS
    SELECT no_rgp_pal, no_ord_rgp_pal
    FROM   sp_lig_cfg_rgp_pal
    WHERE  cod_cfg_rgp_pal = x_cod_cfg_rgp_pal
    AND    val_dim_pro_rgp = x_val_dim
    AND    typ_pro_rgp     = x_typ_pro;

    r_cfg_1 c_cfg_rgp%ROWTYPE;
    r_cfg_2 c_cfg_rgp%ROWTYPE;

    CURSOR c_cfg_pal ( x_opt_pal  pc_cfg_pal.mode_calc_seuil_vol%TYPE,
                       x_haut_std pc_cfg_pal.haut_std%TYPE,
                       x_haut_max NUMBER) IS
    SELECT *
    FROM   pc_cfg_pal
    WHERE  mode_calc_seuil_vol = x_opt_pal
    AND    haut_std            = x_haut_std
    AND    tol_max             = ROUND( (( x_haut_max - x_haut_std) / x_haut_std)*100);

    r_cfg_pal       c_cfg_pal%ROWTYPE;
    v_found_cfg_pal BOOLEAN;

    v_cod_cfg_pal   pc_cfg_pal.cod_cfg_pal%TYPE;
    v_add_ctx       BOOLEAN;

    -- 01b,18.04.16,tjaf rch autre commande
    CURSOR c_com_compl( x_no_com    pc_lig_com.no_com%TYPE,
                        x_cod_cli   pc_ent_com.cod_cli%TYPE,
                        x_cod_cfg_pal_1 pc_lig_com.cod_cfg_pal_1%TYPE,
                        x_cle_rgp_pal_1 pc_lig_com.cle_rgp_pal_1%TYPE) IS
    SELECT l.cod_cfg_pal_1
    FROM   pc_ent_com e, pc_lig_com l
    WHERE  e.no_com != x_no_com
    AND    e.cod_cli = x_cod_cli
    AND    l.cod_cfg_pal_1 != x_cod_cfg_pal_1
    AND    l.cle_rgp_pal_1 = x_cle_rgp_pal_1
    AND    su_bas_etat_val_num(l.etat_atv_pc_lig_com, 'PC_LIG_COM') 
                        < su_bas_etat_val_num('PORD', 'PC_LIG_COM')
    AND    l.no_com = e.no_com
    ORDER BY e.dat_crea, l.dat_crea;

    r_com_compl       c_com_compl%ROWTYPE;
    v_found_com_compl BOOLEAN;
BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_no_com = ' || p_no_com ||
                                    ' / p_no_lig_com = '||p_no_lig_com );
    END IF;

    OPEN c_com;
    FETCH c_com INTO r_com;
    CLOSE c_com;
    IF r_com.cod_usn != 'S' THEN
        RETURN 'OK';
    END IF;

    -- config de regroupement
    OPEN c_cfg_rgp ( r_com.cod_cfg_rgp_pal_1, r_com.val_dim, r_com.typ_pro);
    FETCH c_cfg_rgp INTO r_cfg_1;
    CLOSE c_cfg_rgp;

    OPEN c_cfg_rgp ( r_com.cod_cfg_rgp_pal_2, r_com.val_dim, r_com.typ_pro);
    FETCH c_cfg_rgp INTO r_cfg_2;
    CLOSE c_cfg_rgp;

    -- config palettisation
    OPEN c_cfg_pal ( r_com.opt_pal, r_com.haut_std, r_com.haut_max);
    FETCH c_cfg_pal INTO r_cfg_pal;
    v_found_cfg_pal := c_cfg_pal%FOUND;
    CLOSE c_cfg_pal;

    IF v_found_cfg_pal THEN
        v_cod_cfg_pal := r_cfg_pal.cod_cfg_pal;
    ELSIF r_com.haut_std IS NULL 
        OR su_bas_to_number(r_com.haut_std)<=0  THEN
        v_cod_cfg_pal:='S';
    ELSE
        v_cod_cfg_pal := 'S'||LPAD(TO_CHAR(seq_sp_cod_cfg_pal.NEXTVAL), 6, '0');
        INSERT INTO pc_cfg_pal ( cod_cfg_pal, no_var_cfg_pal, typ_cfg_pal, haut_std, tol_min, tol_max,
                                 seuil_mono, seuil_multi, nb_max_pro, nb_max_cli, nb_max_ptp, cod_cnt_pal,
                                 mono_up, autor_fract, ss_eclat_jusqua, mode_calc_no_ord_pal,
                                 mode_ges_cd_pal, lib_cfg_pal, cod_cnt_subst, mode_orga_cfg_pal,
                                 comment_cfg_pal, lst_usn_vis,  lst_soc_vis, mode_calc_no_ord_chm, seuil_portab,
                                 chg_type_mono, chg_type_multi, mode_dcp_elm_up, extraire_up_cplt,
                                 article_up_cplt, mode_calc_seuil_vol, seuil_instab,
                                 libre_pc_cfg_pal_1, libre_pc_cfg_pal_2, libre_pc_cfg_pal_3, libre_pc_cfg_pal_4,
                                 libre_pc_cfg_pal_5)
        SELECT v_cod_cfg_pal, no_var_cfg_pal, typ_cfg_pal, r_com.haut_std, tol_min,
               ROUND( (( r_com.haut_max - r_com.haut_std) / r_com.haut_std)*100),
               seuil_mono, seuil_multi, nb_max_pro, nb_max_cli, nb_max_ptp, cod_cnt_pal,
               mono_up, autor_fract, ss_eclat_jusqua, mode_calc_no_ord_pal,
               mode_ges_cd_pal, lib_cfg_pal, cod_cnt_subst, mode_orga_cfg_pal,
               comment_cfg_pal, lst_usn_vis,  lst_soc_vis, mode_calc_no_ord_chm, seuil_portab,
               chg_type_mono, chg_type_multi, mode_dcp_elm_up, extraire_up_cplt,
               article_up_cplt, r_com.opt_pal, seuil_instab,
               libre_pc_cfg_pal_1, libre_pc_cfg_pal_2, libre_pc_cfg_pal_3, libre_pc_cfg_pal_4,
               libre_pc_cfg_pal_5
        FROM pc_cfg_pal
        WHERE cod_cfg_pal = 'S'
        AND   no_var_cfg_pal = '0';
    END IF;

    -- 01b,18.04.16,tjaf recherche palette compatible pour regroupement même client
    OPEN c_com_compl(p_no_com, r_com.cod_cli, v_cod_cfg_pal, '#'||r_cfg_1.no_rgp_pal);
    FETCH c_com_compl INTO r_com_compl;
    v_found_com_compl := c_com_compl%FOUND;
    CLOSE c_com_compl;

    IF v_found_com_compl THEN
        v_cod_cfg_pal := r_com_compl.cod_cfg_pal_1;
    END IF;

    UPDATE pc_lig_com
        SET cle_rgp_pal_1        = cle_rgp_pal_1||'#'||r_cfg_1.no_rgp_pal,
            cle_rgp_pal_pref_A_1 = r_cfg_1.no_ord_rgp_pal,
            cle_rgp_pal_2        = cle_rgp_pal_2||'#'||NVL(r_cfg_2.no_rgp_pal, r_cfg_1.no_rgp_pal),
            cle_rgp_pal_pref_B_1 = r_cfg_2.no_ord_rgp_pal,
            cod_cfg_pal_1        = v_cod_cfg_pal,
            mode_pal_1           = 'CLI' ,
            typ_pal_1            = 'HETER'
    WHERE no_com = p_no_com
    AND   no_lig_com = p_no_lig_com;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_no_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'p_no_lig_com',
                        p_par_ano_2       => p_no_lig_com,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;
/
show errors;


