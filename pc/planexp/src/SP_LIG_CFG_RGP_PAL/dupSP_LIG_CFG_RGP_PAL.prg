/* $Id$
****************************************************************************
* su_bas_dup_sp_lig_cfg_rgp_pal - Duplication d'enregistrements de la table SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de duplication de un ou plusieurs enregistrements de la table SP_LIG_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_dup_sp_lig_cfg_rgp_pal(
    p_cod_cfg_rgp_pal_orig          SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_cod_cfg_rgp_pal_dest          SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_val_dim_pro_rgp_orig          SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP%TYPE DEFAULT NULL,
    p_val_dim_pro_rgp_dest          SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP%TYPE DEFAULT NULL,
    p_typ_pro_rgp_orig              SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP%TYPE DEFAULT NULL,
    p_typ_pro_rgp_dest              SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP%TYPE DEFAULT NULL
    ) RETURN VARCHAR2
IS
BEGIN

    INSERT INTO SP_LIG_CFG_RGP_PAL (
        COD_CFG_RGP_PAL,
        VAL_DIM_PRO_RGP,
        TYP_PRO_RGP,
        NO_RGP_PAL,
        NO_ORD_RGP_PAL,
        LIBRE_SP_LIG_CFG_RGP_PAL_1,
        LIBRE_SP_LIG_CFG_RGP_PAL_2,
        LIBRE_SP_LIG_CFG_RGP_PAL_3,
        LIBRE_SP_LIG_CFG_RGP_PAL_4,
        LIBRE_SP_LIG_CFG_RGP_PAL_5)
    SELECT
        NVL(p_cod_cfg_rgp_pal_dest,COD_CFG_RGP_PAL),
        NVL(p_val_dim_pro_rgp_dest,VAL_DIM_PRO_RGP),
        NVL(p_typ_pro_rgp_dest,TYP_PRO_RGP),
        NO_RGP_PAL,
        NO_ORD_RGP_PAL,
        LIBRE_SP_LIG_CFG_RGP_PAL_1,
        LIBRE_SP_LIG_CFG_RGP_PAL_2,
        LIBRE_SP_LIG_CFG_RGP_PAL_3,
        LIBRE_SP_LIG_CFG_RGP_PAL_4,
        LIBRE_SP_LIG_CFG_RGP_PAL_5
    FROM SP_LIG_CFG_RGP_PAL
    WHERE SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL LIKE nvl(p_cod_cfg_rgp_pal_orig,'%') 
      AND SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP LIKE nvl(p_val_dim_pro_rgp_orig,'%') 
      AND SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP LIKE nvl(p_typ_pro_rgp_orig,'%') ;
    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Dupliquer enregistrement',
                        p_par_ano_1       => p_cod_cfg_rgp_pal_orig,
                        p_par_ano_2       => p_cod_cfg_rgp_pal_dest,
                        p_lib_ano_1       => 'CODCFGRGPP',
                        p_lib_ano_2       => 'CODCFGRGPP',
                        p_par_ano_3       => p_val_dim_pro_rgp_orig,
                        p_par_ano_4       => p_val_dim_pro_rgp_dest,
                        p_lib_ano_3       => 'VALDIMPROR',
                        p_lib_ano_4       => 'VALDIMPROR',
                        p_par_ano_5       => p_typ_pro_rgp_orig,
                        p_par_ano_6       => p_typ_pro_rgp_dest,
                        p_lib_ano_5       => 'TYPPRORGP',
                        p_lib_ano_6       => 'TYPPRORGP',
                        p_nom_obj         => 'su_bas_dup_sp_lig_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE);
        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
