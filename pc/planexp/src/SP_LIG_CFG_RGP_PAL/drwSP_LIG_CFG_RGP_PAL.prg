/* $Id$
****************************************************************************
* su_bas_drw_sp_lig_cfg_rgp_pal - Debug enregistrement table SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de trace d'un enregistrement de la table SP_LIG_CFG_RGP_PAL
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
FUNCTION su_bas_drw_sp_lig_cfg_rgp_pal(
    p_mode NUMBER,
    rec    IN OUT NOCOPY SP_LIG_CFG_RGP_PAL%ROWTYPE 
    ) RETURN VARCHAR2
IS
--    v_version           VARCHAR2(50)  := '@(#) VERSION 00a $Revision$';
--    v_nom_obj           VARCHAR2(50)  := 'su_bas_drw_sp_lig_cfg_rgp_pal';
--    v_etape             varchar2(500) ;
--    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
BEGIN

IF p_mode>0 OR rec.cod_cfg_rgp_pal IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL > '||rec.cod_cfg_rgp_pal);
END IF;
IF p_mode>0 OR rec.val_dim_pro_rgp IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP > '||rec.val_dim_pro_rgp);
END IF;
IF p_mode>0 OR rec.typ_pro_rgp IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP > '||rec.typ_pro_rgp);
END IF;
IF p_mode>0 OR rec.no_rgp_pal IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.NO_RGP_PAL > '||rec.no_rgp_pal);
END IF;
IF p_mode>0 OR rec.no_ord_rgp_pal IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.NO_ORD_RGP_PAL > '||rec.no_ord_rgp_pal);
END IF;
IF p_mode>0 OR rec.libre_sp_lig_cfg_rgp_pal_1 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||rec.libre_sp_lig_cfg_rgp_pal_1);
END IF;
IF p_mode>0 OR rec.libre_sp_lig_cfg_rgp_pal_2 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||rec.libre_sp_lig_cfg_rgp_pal_2);
END IF;
IF p_mode>0 OR rec.libre_sp_lig_cfg_rgp_pal_3 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||rec.libre_sp_lig_cfg_rgp_pal_3);
END IF;
IF p_mode>0 OR rec.libre_sp_lig_cfg_rgp_pal_4 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||rec.libre_sp_lig_cfg_rgp_pal_4);
END IF;
IF p_mode>0 OR rec.libre_sp_lig_cfg_rgp_pal_5 IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||rec.libre_sp_lig_cfg_rgp_pal_5);
END IF;
IF p_mode>0 OR rec.etat_phenyx IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.ETAT_PHENYX > '||rec.etat_phenyx);
END IF;
IF p_mode>0 OR rec.dat_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.DAT_CREA > '||to_char(rec.dat_crea,'DD/MM/YYYY HH24:MI:SS'));
END IF;
IF p_mode>0 OR rec.dat_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.DAT_MAJ > '||to_char(rec.dat_maj,'DD/MM/YYYY HH24:MI:SS'));
END IF;
IF p_mode>0 OR rec.ope_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.OPE_CREA > '||rec.ope_crea);
END IF;
IF p_mode>0 OR rec.ope_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.OPE_MAJ > '||rec.ope_maj);
END IF;
IF p_mode>0 OR rec.usr_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.USR_CREA > '||rec.usr_crea);
END IF;
IF p_mode>0 OR rec.usr_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.USR_MAJ > '||rec.usr_maj);
END IF;
IF p_mode>0 OR rec.info_pos_crea IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.INFO_POS_CREA > '||rec.info_pos_crea);
END IF;
IF p_mode>0 OR rec.info_pos_maj IS NOT NULL THEN
    su_bas_put_debug('Col SP_LIG_CFG_RGP_PAL.INFO_POS_MAJ > '||rec.info_pos_maj);
END IF;

RETURN 'OK';

END;
/
SHOW ERRORS;
