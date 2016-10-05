/* $Id$
****************************************************************************
* su_bas_irw_sp_lig_cfg_rgp_pal - Insertion enregistrement table SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction d'insertion d'un enregistrement dans la table SP_LIG_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_irw_sp_lig_cfg_rgp_pal( rec IN OUT NOCOPY SP_LIG_CFG_RGP_PAL%ROWTYPE )
RETURN VARCHAR2
IS
BEGIN

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||rec.cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col VAL_DIM_PRO_RGP > '||rec.val_dim_pro_rgp);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col TYP_PRO_RGP > '||rec.typ_pro_rgp);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col NO_RGP_PAL > '||rec.no_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col NO_ORD_RGP_PAL > '||rec.no_ord_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||rec.libre_sp_lig_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||rec.libre_sp_lig_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||rec.libre_sp_lig_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||rec.libre_sp_lig_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||rec.libre_sp_lig_cfg_rgp_pal_5);
    END IF;

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
        LIBRE_SP_LIG_CFG_RGP_PAL_5
    ) VALUES (
        rec.COD_CFG_RGP_PAL,
        rec.VAL_DIM_PRO_RGP,
        rec.TYP_PRO_RGP,
        rec.NO_RGP_PAL,
        rec.NO_ORD_RGP_PAL,
        rec.LIBRE_SP_LIG_CFG_RGP_PAL_1,
        rec.LIBRE_SP_LIG_CFG_RGP_PAL_2,
        rec.LIBRE_SP_LIG_CFG_RGP_PAL_3,
        rec.LIBRE_SP_LIG_CFG_RGP_PAL_4,
        rec.LIBRE_SP_LIG_CFG_RGP_PAL_5
    );

    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Insert',
                        p_par_ano_1       => rec.cod_cfg_rgp_pal,
                        p_lib_ano_1       => 'CODCFGRGPP',
                        p_par_ano_2       => rec.val_dim_pro_rgp,
                        p_lib_ano_2       => 'VALDIMPROR',
                        p_par_ano_3       => rec.typ_pro_rgp,
                        p_lib_ano_3       => 'TYPPRORGP',
                        p_par_ano_4       => rec.no_rgp_pal,
                        p_lib_ano_4       => 'NORGPPAL',
                        p_par_ano_5       => rec.no_ord_rgp_pal,
                        p_lib_ano_5       => 'NOORDRGPPA',
                        p_par_ano_6       => rec.libre_sp_lig_cfg_rgp_pal_1,
                        p_lib_ano_6       => 'LIBRESPLIG',
                        p_par_ano_7       => rec.libre_sp_lig_cfg_rgp_pal_2,
                        p_lib_ano_7       => 'LIBRESPLIG',
                        p_par_ano_8       => rec.libre_sp_lig_cfg_rgp_pal_3,
                        p_lib_ano_8       => 'LIBRESPLIG',
                        p_par_ano_9       => rec.libre_sp_lig_cfg_rgp_pal_4,
                        p_lib_ano_9       => 'LIBRESPLIG',
                        p_par_ano_10      => rec.libre_sp_lig_cfg_rgp_pal_5,
                        p_lib_ano_10      => 'LIBRESPLIG',
                        p_nom_obj         => 'su_bas_irw_sp_lig_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE );

    IF su_global_pkv.v_niv_dbg >= 8 THEN
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||rec.cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col VAL_DIM_PRO_RGP > '||rec.val_dim_pro_rgp);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col TYP_PRO_RGP > '||rec.typ_pro_rgp);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col NO_RGP_PAL > '||rec.no_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col NO_ORD_RGP_PAL > '||rec.no_ord_rgp_pal);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||rec.libre_sp_lig_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||rec.libre_sp_lig_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||rec.libre_sp_lig_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||rec.libre_sp_lig_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_irw_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||rec.libre_sp_lig_cfg_rgp_pal_5);
    END IF;

        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
