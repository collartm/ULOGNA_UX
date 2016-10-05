/* $Id$
****************************************************************************
* su_bas_irw_sp_ent_cfg_rgp_pal - Insertion enregistrement table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction d'insertion d'un enregistrement dans la table SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_irw_sp_ent_cfg_rgp_pal( rec IN OUT NOCOPY SP_ENT_CFG_RGP_PAL%ROWTYPE )
RETURN VARCHAR2
IS
BEGIN

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||rec.cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIB_CFG_RGP_PAL > '||rec.lib_cfg_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_1 > '||rec.libre_sp_ent_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_2 > '||rec.libre_sp_ent_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_3 > '||rec.libre_sp_ent_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_4 > '||rec.libre_sp_ent_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_5 > '||rec.libre_sp_ent_cfg_rgp_pal_5);
    END IF;

    INSERT INTO SP_ENT_CFG_RGP_PAL (
        COD_CFG_RGP_PAL,
        LIB_CFG_RGP_PAL,
        LIBRE_SP_ENT_CFG_RGP_PAL_1,
        LIBRE_SP_ENT_CFG_RGP_PAL_2,
        LIBRE_SP_ENT_CFG_RGP_PAL_3,
        LIBRE_SP_ENT_CFG_RGP_PAL_4,
        LIBRE_SP_ENT_CFG_RGP_PAL_5
    ) VALUES (
        rec.COD_CFG_RGP_PAL,
        rec.LIB_CFG_RGP_PAL,
        rec.LIBRE_SP_ENT_CFG_RGP_PAL_1,
        rec.LIBRE_SP_ENT_CFG_RGP_PAL_2,
        rec.LIBRE_SP_ENT_CFG_RGP_PAL_3,
        rec.LIBRE_SP_ENT_CFG_RGP_PAL_4,
        rec.LIBRE_SP_ENT_CFG_RGP_PAL_5
    );

    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Insert',
                        p_par_ano_1       => rec.cod_cfg_rgp_pal,
                        p_lib_ano_1       => 'CODCFGRGPP',
                        p_par_ano_2       => rec.lib_cfg_rgp_pal,
                        p_lib_ano_2       => 'LIBCFGRGPP',
                        p_par_ano_3       => rec.libre_sp_ent_cfg_rgp_pal_1,
                        p_lib_ano_3       => 'LIBRESPENT',
                        p_par_ano_4       => rec.libre_sp_ent_cfg_rgp_pal_2,
                        p_lib_ano_4       => 'LIBRESPENT',
                        p_par_ano_5       => rec.libre_sp_ent_cfg_rgp_pal_3,
                        p_lib_ano_5       => 'LIBRESPENT',
                        p_par_ano_6       => rec.libre_sp_ent_cfg_rgp_pal_4,
                        p_lib_ano_6       => 'LIBRESPENT',
                        p_par_ano_7       => rec.libre_sp_ent_cfg_rgp_pal_5,
                        p_lib_ano_7       => 'LIBRESPENT',
                        p_nom_obj         => 'su_bas_irw_sp_ent_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE );

    IF su_global_pkv.v_niv_dbg >= 8 THEN
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||rec.cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIB_CFG_RGP_PAL > '||rec.lib_cfg_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_1 > '||rec.libre_sp_ent_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_2 > '||rec.libre_sp_ent_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_3 > '||rec.libre_sp_ent_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_4 > '||rec.libre_sp_ent_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_irw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_5 > '||rec.libre_sp_ent_cfg_rgp_pal_5);
    END IF;

        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
