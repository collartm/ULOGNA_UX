/* $Id$
****************************************************************************
* su_bas_dbg_sp_lig_cfg_rgp_pal - Debug enregistrement table SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de trace de colonnes de la table SP_LIG_CFG_RGP_PAL
--
-- p_mode = 1 toutes les colonnes
-- p_mode = 0 uniquement les colonnes non nulles
--
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_dbg_sp_lig_cfg_rgp_pal(
    p_mode NUMBER DEFAULT 0,
    p_cod_cfg_rgp_pal               SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_val_dim_pro_rgp               SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP%TYPE DEFAULT NULL,
    p_typ_pro_rgp                   SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP%TYPE DEFAULT NULL,
    p_no_rgp_pal                    SP_LIG_CFG_RGP_PAL.NO_RGP_PAL%TYPE DEFAULT NULL,
    p_no_ord_rgp_pal                SP_LIG_CFG_RGP_PAL.NO_ORD_RGP_PAL%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_1    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_1%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_2    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_2%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_3    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_3%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_4    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_4%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_5    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_5%TYPE DEFAULT NULL,
    p_etat_phenyx                   SP_LIG_CFG_RGP_PAL.ETAT_PHENYX%TYPE DEFAULT NULL,
    p_dat_crea                      SP_LIG_CFG_RGP_PAL.DAT_CREA%TYPE DEFAULT NULL,
    p_dat_maj                       SP_LIG_CFG_RGP_PAL.DAT_MAJ%TYPE DEFAULT NULL,
    p_ope_crea                      SP_LIG_CFG_RGP_PAL.OPE_CREA%TYPE DEFAULT NULL,
    p_ope_maj                       SP_LIG_CFG_RGP_PAL.OPE_MAJ%TYPE DEFAULT NULL,
    p_usr_crea                      SP_LIG_CFG_RGP_PAL.USR_CREA%TYPE DEFAULT NULL,
    p_usr_maj                       SP_LIG_CFG_RGP_PAL.USR_MAJ%TYPE DEFAULT NULL,
    p_info_pos_crea                 SP_LIG_CFG_RGP_PAL.INFO_POS_CREA%TYPE DEFAULT NULL,
    p_info_pos_maj                  SP_LIG_CFG_RGP_PAL.INFO_POS_MAJ%TYPE DEFAULT NULL
    ) RETURN VARCHAR2
IS
--    v_version           VARCHAR2(50)  := '@(#) VERSION 00a $Revision$';
--    v_nom_obj           VARCHAR2(50)  := 'su_bas_dbg_sp_lig_cfg_rgp_pal';
--    v_etape             varchar2(500) ;
--    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
BEGIN

IF p_mode>0 OR p_cod_cfg_rgp_pal IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL > '||p_cod_cfg_rgp_pal);
END IF;
IF p_mode>0 OR p_val_dim_pro_rgp IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP > '||p_val_dim_pro_rgp);
END IF;
IF p_mode>0 OR p_typ_pro_rgp IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP > '||p_typ_pro_rgp);
END IF;
IF p_mode>0 OR p_no_rgp_pal IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.NO_RGP_PAL > '||p_no_rgp_pal);
END IF;
IF p_mode>0 OR p_no_ord_rgp_pal IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.NO_ORD_RGP_PAL > '||p_no_ord_rgp_pal);
END IF;
IF p_mode>0 OR p_libre_sp_lig_cfg_rgp_pal_1 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||p_libre_sp_lig_cfg_rgp_pal_1);
END IF;
IF p_mode>0 OR p_libre_sp_lig_cfg_rgp_pal_2 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||p_libre_sp_lig_cfg_rgp_pal_2);
END IF;
IF p_mode>0 OR p_libre_sp_lig_cfg_rgp_pal_3 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||p_libre_sp_lig_cfg_rgp_pal_3);
END IF;
IF p_mode>0 OR p_libre_sp_lig_cfg_rgp_pal_4 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||p_libre_sp_lig_cfg_rgp_pal_4);
END IF;
IF p_mode>0 OR p_libre_sp_lig_cfg_rgp_pal_5 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||p_libre_sp_lig_cfg_rgp_pal_5);
END IF;
IF p_mode>0 OR p_etat_phenyx IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.ETAT_PHENYX > '||p_etat_phenyx);
END IF;
IF p_mode>0 OR p_dat_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.DAT_CREA > '||to_char(p_dat_crea,'DD/MM/YYYY HH24:MI:SS'));
END IF;
IF p_mode>0 OR p_dat_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.DAT_MAJ > '||to_char(p_dat_maj,'DD/MM/YYYY HH24:MI:SS'));
END IF;
IF p_mode>0 OR p_ope_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.OPE_CREA > '||p_ope_crea);
END IF;
IF p_mode>0 OR p_ope_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.OPE_MAJ > '||p_ope_maj);
END IF;
IF p_mode>0 OR p_usr_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.USR_CREA > '||p_usr_crea);
END IF;
IF p_mode>0 OR p_usr_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.USR_MAJ > '||p_usr_maj);
END IF;
IF p_mode>0 OR p_info_pos_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.INFO_POS_CREA > '||p_info_pos_crea);
END IF;
IF p_mode>0 OR p_info_pos_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.INFO_POS_MAJ > '||p_info_pos_maj);
END IF;

RETURN 'OK';

END;
/
SHOW ERRORS;
