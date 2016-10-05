/* $Id$
****************************************************************************
* su_bas_upd_sp_lig_cfg_rgp_pal - Mise à jour enregistrement table SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de mise à jour d'un enregistrement de la table SP_LIG_CFG_RGP_PAL
--
-- p_mode = 1 si paramêtre à NULL remplace la valeur courante
-- p_mode = 2 pour garder les valeurs pré-existante
-- p_mode = 3 pour ne pas faire d'update existe déjà
-- p_mode = 0 ne pas remplacer si le paramêtre=NULL
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
FUNCTION su_bas_upd_sp_lig_cfg_rgp_pal(
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
BEGIN

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Mode > '||p_mode);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||p_cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col VAL_DIM_PRO_RGP > '||p_val_dim_pro_rgp);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col TYP_PRO_RGP > '||p_typ_pro_rgp);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col NO_RGP_PAL > '||p_no_rgp_pal);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col NO_ORD_RGP_PAL > '||p_no_ord_rgp_pal);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||p_libre_sp_lig_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||p_libre_sp_lig_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||p_libre_sp_lig_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||p_libre_sp_lig_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||p_libre_sp_lig_cfg_rgp_pal_5);
    END IF;

    IF p_mode = '1' THEN
        UPDATE SP_LIG_CFG_RGP_PAL SET
            NO_RGP_PAL = p_no_rgp_pal,
            NO_ORD_RGP_PAL = p_no_ord_rgp_pal,
            LIBRE_SP_LIG_CFG_RGP_PAL_1 = p_libre_sp_lig_cfg_rgp_pal_1,
            LIBRE_SP_LIG_CFG_RGP_PAL_2 = p_libre_sp_lig_cfg_rgp_pal_2,
            LIBRE_SP_LIG_CFG_RGP_PAL_3 = p_libre_sp_lig_cfg_rgp_pal_3,
            LIBRE_SP_LIG_CFG_RGP_PAL_4 = p_libre_sp_lig_cfg_rgp_pal_4,
            LIBRE_SP_LIG_CFG_RGP_PAL_5 = p_libre_sp_lig_cfg_rgp_pal_5
        WHERE p_cod_cfg_rgp_pal = SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL
          AND p_val_dim_pro_rgp = SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP
          AND p_typ_pro_rgp = SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP;
    ELSIF p_mode = '0' THEN
        UPDATE SP_LIG_CFG_RGP_PAL SET
            NO_RGP_PAL = nvl(p_no_rgp_pal,NO_RGP_PAL),
            NO_ORD_RGP_PAL = nvl(p_no_ord_rgp_pal,NO_ORD_RGP_PAL),
            LIBRE_SP_LIG_CFG_RGP_PAL_1 = nvl(p_libre_sp_lig_cfg_rgp_pal_1,LIBRE_SP_LIG_CFG_RGP_PAL_1),
            LIBRE_SP_LIG_CFG_RGP_PAL_2 = nvl(p_libre_sp_lig_cfg_rgp_pal_2,LIBRE_SP_LIG_CFG_RGP_PAL_2),
            LIBRE_SP_LIG_CFG_RGP_PAL_3 = nvl(p_libre_sp_lig_cfg_rgp_pal_3,LIBRE_SP_LIG_CFG_RGP_PAL_3),
            LIBRE_SP_LIG_CFG_RGP_PAL_4 = nvl(p_libre_sp_lig_cfg_rgp_pal_4,LIBRE_SP_LIG_CFG_RGP_PAL_4),
            LIBRE_SP_LIG_CFG_RGP_PAL_5 = nvl(p_libre_sp_lig_cfg_rgp_pal_5,LIBRE_SP_LIG_CFG_RGP_PAL_5)
        WHERE p_cod_cfg_rgp_pal = SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL
          AND p_val_dim_pro_rgp = SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP
          AND p_typ_pro_rgp = SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP;
    ELSIF p_mode = '2' THEN
        UPDATE SP_LIG_CFG_RGP_PAL SET
            NO_RGP_PAL = nvl(no_rgp_pal,p_no_rgp_pal),
            NO_ORD_RGP_PAL = nvl(no_ord_rgp_pal,p_no_ord_rgp_pal),
            LIBRE_SP_LIG_CFG_RGP_PAL_1 = nvl(libre_sp_lig_cfg_rgp_pal_1,p_libre_sp_lig_cfg_rgp_pal_1),
            LIBRE_SP_LIG_CFG_RGP_PAL_2 = nvl(libre_sp_lig_cfg_rgp_pal_2,p_libre_sp_lig_cfg_rgp_pal_2),
            LIBRE_SP_LIG_CFG_RGP_PAL_3 = nvl(libre_sp_lig_cfg_rgp_pal_3,p_libre_sp_lig_cfg_rgp_pal_3),
            LIBRE_SP_LIG_CFG_RGP_PAL_4 = nvl(libre_sp_lig_cfg_rgp_pal_4,p_libre_sp_lig_cfg_rgp_pal_4),
            LIBRE_SP_LIG_CFG_RGP_PAL_5 = nvl(libre_sp_lig_cfg_rgp_pal_5,p_libre_sp_lig_cfg_rgp_pal_5)
        WHERE p_cod_cfg_rgp_pal = SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL
          AND p_val_dim_pro_rgp = SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP
          AND p_typ_pro_rgp = SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP;
    END IF;
    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Mise à jour enregistrement',
                        p_lib_ano_1       => 'Mode',
                        p_par_ano_1       => p_mode,
                        p_par_ano_2       => p_cod_cfg_rgp_pal,
                        p_lib_ano_2       => 'CODCFGRGPP',
                        p_par_ano_3       => p_val_dim_pro_rgp,
                        p_lib_ano_3       => 'VALDIMPROR',
                        p_par_ano_4       => p_typ_pro_rgp,
                        p_lib_ano_4       => 'TYPPRORGP',
                        p_nom_obj         => 'su_bas_upd_sp_lig_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE);
    IF su_global_pkv.v_niv_dbg >= 8 THEN
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal'||' : Mode > '||p_mode);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||p_cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col VAL_DIM_PRO_RGP > '||p_val_dim_pro_rgp);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col TYP_PRO_RGP > '||p_typ_pro_rgp);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col NO_RGP_PAL > '||p_no_rgp_pal);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col NO_ORD_RGP_PAL > '||p_no_ord_rgp_pal);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_1 > '||p_libre_sp_lig_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_2 > '||p_libre_sp_lig_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_3 > '||p_libre_sp_lig_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_4 > '||p_libre_sp_lig_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_upd_sp_lig_cfg_rgp_pal : Col LIBRE_SP_LIG_CFG_RGP_PAL_5 > '||p_libre_sp_lig_cfg_rgp_pal_5);
    END IF;

        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
