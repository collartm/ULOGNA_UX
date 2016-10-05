/* $Id$
****************************************************************************
* su_bas_ins_sp_ent_cfg_rgp_pal - Insertion table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de création d'une fiche dans la table SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_ins_sp_ent_cfg_rgp_pal(
    p_cod_cfg_rgp_pal               SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_lib_cfg_rgp_pal               SP_ENT_CFG_RGP_PAL.LIB_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_1    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_1%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_2    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_2%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_3    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_3%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_4    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_4%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_5    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_5%TYPE DEFAULT NULL
    ) RETURN VARCHAR2
IS
BEGIN

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||p_cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIB_CFG_RGP_PAL > '||p_lib_cfg_rgp_pal);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_1 > '||p_libre_sp_ent_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_2 > '||p_libre_sp_ent_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_3 > '||p_libre_sp_ent_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_4 > '||p_libre_sp_ent_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_5 > '||p_libre_sp_ent_cfg_rgp_pal_5);
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
        p_cod_cfg_rgp_pal,
        p_lib_cfg_rgp_pal,
        p_libre_sp_ent_cfg_rgp_pal_1,
        p_libre_sp_ent_cfg_rgp_pal_2,
        p_libre_sp_ent_cfg_rgp_pal_3,
        p_libre_sp_ent_cfg_rgp_pal_4,
        p_libre_sp_ent_cfg_rgp_pal_5
    );

    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Insert',
                        p_par_ano_1       => p_cod_cfg_rgp_pal,
                        p_lib_ano_1       => 'CODCFGRGPP',
                        p_par_ano_2       => p_lib_cfg_rgp_pal,
                        p_lib_ano_2       => 'LIBCFGRGPP',
                        p_par_ano_3       => p_libre_sp_ent_cfg_rgp_pal_1,
                        p_lib_ano_3       => 'LIBRESPENT',
                        p_par_ano_4       => p_libre_sp_ent_cfg_rgp_pal_2,
                        p_lib_ano_4       => 'LIBRESPENT',
                        p_par_ano_5       => p_libre_sp_ent_cfg_rgp_pal_3,
                        p_lib_ano_5       => 'LIBRESPENT',
                        p_par_ano_6       => p_libre_sp_ent_cfg_rgp_pal_4,
                        p_lib_ano_6       => 'LIBRESPENT',
                        p_par_ano_7       => p_libre_sp_ent_cfg_rgp_pal_5,
                        p_lib_ano_7       => 'LIBRESPENT',
                        p_nom_obj         => 'su_bas_ins_sp_ent_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE );

    IF su_global_pkv.v_niv_dbg >= 8 THEN
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||p_cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIB_CFG_RGP_PAL > '||p_lib_cfg_rgp_pal);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_1 > '||p_libre_sp_ent_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_2 > '||p_libre_sp_ent_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_3 > '||p_libre_sp_ent_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_4 > '||p_libre_sp_ent_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_ins_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_5 > '||p_libre_sp_ent_cfg_rgp_pal_5);
    END IF;

        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
