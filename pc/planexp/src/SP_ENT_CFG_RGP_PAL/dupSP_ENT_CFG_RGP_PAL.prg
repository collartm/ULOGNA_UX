/* $Id$
****************************************************************************
* su_bas_dup_sp_ent_cfg_rgp_pal - Duplication d'enregistrements de la table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de duplication de un ou plusieurs enregistrements de la table SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_dup_sp_ent_cfg_rgp_pal(
    p_cod_cfg_rgp_pal_orig          SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_cod_cfg_rgp_pal_dest          SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL
    ) RETURN VARCHAR2
IS
BEGIN

    INSERT INTO SP_ENT_CFG_RGP_PAL (
        COD_CFG_RGP_PAL,
        LIB_CFG_RGP_PAL,
        LIBRE_SP_ENT_CFG_RGP_PAL_1,
        LIBRE_SP_ENT_CFG_RGP_PAL_2,
        LIBRE_SP_ENT_CFG_RGP_PAL_3,
        LIBRE_SP_ENT_CFG_RGP_PAL_4,
        LIBRE_SP_ENT_CFG_RGP_PAL_5)
    SELECT
        NVL(p_cod_cfg_rgp_pal_dest,COD_CFG_RGP_PAL),
        LIB_CFG_RGP_PAL,
        LIBRE_SP_ENT_CFG_RGP_PAL_1,
        LIBRE_SP_ENT_CFG_RGP_PAL_2,
        LIBRE_SP_ENT_CFG_RGP_PAL_3,
        LIBRE_SP_ENT_CFG_RGP_PAL_4,
        LIBRE_SP_ENT_CFG_RGP_PAL_5
    FROM SP_ENT_CFG_RGP_PAL
    WHERE SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL LIKE nvl(p_cod_cfg_rgp_pal_orig,'%') ;
    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Dupliquer enregistrement',
                        p_par_ano_1       => p_cod_cfg_rgp_pal_orig,
                        p_par_ano_2       => p_cod_cfg_rgp_pal_dest,
                        p_lib_ano_1       => 'CODCFGRGPP',
                        p_lib_ano_2       => 'CODCFGRGPP',
                        p_nom_obj         => 'su_bas_dup_sp_ent_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE);
        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
