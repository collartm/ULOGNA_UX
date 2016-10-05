/* $Id$
****************************************************************************
* su_bas_maj_sp_lig_cfg_rgp_pal - Cr�ation ou mise � jour enregistrement table SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de cr�ation ou de mise � jour d'un enregistrement de la table SP_LIG_CFG_RGP_PAL
--
-- p_mode = 1 si param�tre � NULL remplace la valeur courante
-- p_mode = 2 pour garder les valeurs pr�-existante
-- p_mode = 3 pour ne pas faire d'update existe d�j�
-- p_mode = 0 ne pas remplacer si le param�tre=NULL
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
FUNCTION su_bas_maj_sp_lig_cfg_rgp_pal(
    p_mode                          VARCHAR2,
    p_cod_cfg_rgp_pal               SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE,
    p_val_dim_pro_rgp               SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP%TYPE,
    p_typ_pro_rgp                   SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP%TYPE,
    p_no_rgp_pal                    SP_LIG_CFG_RGP_PAL.NO_RGP_PAL%TYPE DEFAULT NULL,
    p_no_ord_rgp_pal                SP_LIG_CFG_RGP_PAL.NO_ORD_RGP_PAL%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_1    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_1%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_2    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_2%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_3    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_3%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_4    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_4%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_5    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_5%TYPE DEFAULT NULL
    ) RETURN VARCHAR2
IS
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE ;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) ;

    duplicate_primary_key    EXCEPTION;
    PRAGMA EXCEPTION_INIT(duplicate_primary_key,-1);

BEGIN

    BEGIN

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||p_cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col VAL_DIM_PRO_RGP > '||p_val_dim_pro_rgp);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col TYP_PRO_RGP > '||p_typ_pro_rgp);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col NO_RGP_PAL > '||p_no_rgp_pal);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col NO_ORD_RGP_PAL > '||p_no_ord_rgp_pal);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||p_libre_sp_lig_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||p_libre_sp_lig_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||p_libre_sp_lig_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||p_libre_sp_lig_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||p_libre_sp_lig_cfg_rgp_pal_5);
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
        p_cod_cfg_rgp_pal,
        p_val_dim_pro_rgp,
        p_typ_pro_rgp,
        p_no_rgp_pal,
        p_no_ord_rgp_pal,
        p_libre_sp_lig_cfg_rgp_pal_1,
        p_libre_sp_lig_cfg_rgp_pal_2,
        p_libre_sp_lig_cfg_rgp_pal_3,
        p_libre_sp_lig_cfg_rgp_pal_4,
        p_libre_sp_lig_cfg_rgp_pal_5
        );

        RETURN 'OK';

    EXCEPTION
        WHEN duplicate_primary_key THEN
            v_ret := su_bas_upd_sp_lig_cfg_rgp_pal ( p_mode => p_mode,
                p_cod_cfg_rgp_pal               => p_cod_cfg_rgp_pal,
                p_val_dim_pro_rgp               => p_val_dim_pro_rgp,
                p_typ_pro_rgp                   => p_typ_pro_rgp,
                p_no_rgp_pal                    => p_no_rgp_pal,
                p_no_ord_rgp_pal                => p_no_ord_rgp_pal,
                p_libre_sp_lig_cfg_rgp_pal_1    => p_libre_sp_lig_cfg_rgp_pal_1,
                p_libre_sp_lig_cfg_rgp_pal_2    => p_libre_sp_lig_cfg_rgp_pal_2,
                p_libre_sp_lig_cfg_rgp_pal_3    => p_libre_sp_lig_cfg_rgp_pal_3,
                p_libre_sp_lig_cfg_rgp_pal_4    => p_libre_sp_lig_cfg_rgp_pal_4,
                p_libre_sp_lig_cfg_rgp_pal_5    => p_libre_sp_lig_cfg_rgp_pal_5
                );
    END;

    IF v_ret !='OK' THEN
          RAISE err_except;
    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Update',
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_lib_ano_1       => 'Mode',
                        p_par_ano_1       => p_mode,
                        p_par_ano_2       => p_cod_cfg_rgp_pal,
                        p_lib_ano_2       => 'CODCFGRGPP',
                        p_par_ano_3       => p_val_dim_pro_rgp,
                        p_lib_ano_3       => 'VALDIMPROR',
                        p_par_ano_4       => p_typ_pro_rgp,
                        p_lib_ano_4       => 'TYPPRORGP',
                        p_par_ano_5       => p_no_rgp_pal,
                        p_lib_ano_5        => 'NORGPPAL',
                        p_par_ano_6       => p_no_ord_rgp_pal,
                        p_lib_ano_6        => 'NOORDRGPPA',
                        p_par_ano_7       => p_libre_sp_lig_cfg_rgp_pal_1,
                        p_lib_ano_7        => 'LIBRESPLIG',
                        p_par_ano_8       => p_libre_sp_lig_cfg_rgp_pal_2,
                        p_lib_ano_8        => 'LIBRESPLIG',
                        p_par_ano_9       => p_libre_sp_lig_cfg_rgp_pal_3,
                        p_lib_ano_9        => 'LIBRESPLIG',
                        p_par_ano_10      => p_libre_sp_lig_cfg_rgp_pal_4,
                        p_lib_ano_10       => 'LIBRESPLIG',
                        p_nom_obj         => 'su_bas_maj_sp_lig_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE);
    IF su_global_pkv.v_niv_dbg >= 8 THEN
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Mode > '||p_mode);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||p_cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col VAL_DIM_PRO_RGP > '||p_val_dim_pro_rgp);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col TYP_PRO_RGP > '||p_typ_pro_rgp);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col NO_RGP_PAL > '||p_no_rgp_pal);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col NO_ORD_RGP_PAL > '||p_no_ord_rgp_pal);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||p_libre_sp_lig_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||p_libre_sp_lig_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||p_libre_sp_lig_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||p_libre_sp_lig_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_maj_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||p_libre_sp_lig_cfg_rgp_pal_5);
    END IF;

        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
