/* $Id$
****************************************************************************
* su_bas_urw_sp_ent_cfg_rgp_pal - Mise à jour enregistrement table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de mise à jour d'un enregistrement de la table SP_ENT_CFG_RGP_PAL
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
FUNCTION su_bas_urw_sp_ent_cfg_rgp_pal(
    p_mode VARCHAR2,
    rec    IN OUT NOCOPY SP_ENT_CFG_RGP_PAL%ROWTYPE 
    ) RETURN VARCHAR2
IS
BEGIN

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Mode > '||p_mode);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||rec.cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIB_CFG_RGP_PAL > '||rec.lib_cfg_rgp_pal);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_1 > '||rec.libre_sp_ent_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_2 > '||rec.libre_sp_ent_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_3 > '||rec.libre_sp_ent_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_4 > '||rec.libre_sp_ent_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_5 > '||rec.libre_sp_ent_cfg_rgp_pal_5);
    END IF;

    IF p_mode = '1' THEN
        UPDATE SP_ENT_CFG_RGP_PAL SET
            LIB_CFG_RGP_PAL = rec.lib_cfg_rgp_pal,
            LIBRE_SP_ENT_CFG_RGP_PAL_1 = rec.libre_sp_ent_cfg_rgp_pal_1,
            LIBRE_SP_ENT_CFG_RGP_PAL_2 = rec.libre_sp_ent_cfg_rgp_pal_2,
            LIBRE_SP_ENT_CFG_RGP_PAL_3 = rec.libre_sp_ent_cfg_rgp_pal_3,
            LIBRE_SP_ENT_CFG_RGP_PAL_4 = rec.libre_sp_ent_cfg_rgp_pal_4,
            LIBRE_SP_ENT_CFG_RGP_PAL_5 = rec.libre_sp_ent_cfg_rgp_pal_5
        WHERE rec.cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    ELSIF p_mode = '0' THEN
        UPDATE SP_ENT_CFG_RGP_PAL SET
            LIB_CFG_RGP_PAL = nvl(rec.lib_cfg_rgp_pal,LIB_CFG_RGP_PAL),
            LIBRE_SP_ENT_CFG_RGP_PAL_1 = nvl(rec.libre_sp_ent_cfg_rgp_pal_1,LIBRE_SP_ENT_CFG_RGP_PAL_1),
            LIBRE_SP_ENT_CFG_RGP_PAL_2 = nvl(rec.libre_sp_ent_cfg_rgp_pal_2,LIBRE_SP_ENT_CFG_RGP_PAL_2),
            LIBRE_SP_ENT_CFG_RGP_PAL_3 = nvl(rec.libre_sp_ent_cfg_rgp_pal_3,LIBRE_SP_ENT_CFG_RGP_PAL_3),
            LIBRE_SP_ENT_CFG_RGP_PAL_4 = nvl(rec.libre_sp_ent_cfg_rgp_pal_4,LIBRE_SP_ENT_CFG_RGP_PAL_4),
            LIBRE_SP_ENT_CFG_RGP_PAL_5 = nvl(rec.libre_sp_ent_cfg_rgp_pal_5,LIBRE_SP_ENT_CFG_RGP_PAL_5)
        WHERE rec.cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    ELSIF p_mode = '2' THEN
        UPDATE SP_ENT_CFG_RGP_PAL SET
            LIB_CFG_RGP_PAL = nvl(lib_cfg_rgp_pal,rec.LIB_CFG_RGP_PAL),
            LIBRE_SP_ENT_CFG_RGP_PAL_1 = nvl(libre_sp_ent_cfg_rgp_pal_1,rec.LIBRE_SP_ENT_CFG_RGP_PAL_1),
            LIBRE_SP_ENT_CFG_RGP_PAL_2 = nvl(libre_sp_ent_cfg_rgp_pal_2,rec.LIBRE_SP_ENT_CFG_RGP_PAL_2),
            LIBRE_SP_ENT_CFG_RGP_PAL_3 = nvl(libre_sp_ent_cfg_rgp_pal_3,rec.LIBRE_SP_ENT_CFG_RGP_PAL_3),
            LIBRE_SP_ENT_CFG_RGP_PAL_4 = nvl(libre_sp_ent_cfg_rgp_pal_4,rec.LIBRE_SP_ENT_CFG_RGP_PAL_4),
            LIBRE_SP_ENT_CFG_RGP_PAL_5 = nvl(libre_sp_ent_cfg_rgp_pal_5,rec.LIBRE_SP_ENT_CFG_RGP_PAL_5)
        WHERE rec.cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    END IF;
    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Mise à jour enregistrement',
                        p_lib_ano_1       => 'Mode',
                        p_par_ano_1       => p_mode,
                        p_par_ano_2       => rec.cod_cfg_rgp_pal,
                        p_lib_ano_2       => 'CODCFGRGPP',
                        p_nom_obj         => 'su_bas_urw_sp_ent_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE);

    IF su_global_pkv.v_niv_dbg >= 8 THEN
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Mode > '||p_mode);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col COD_CFG_RGP_PAL > '||rec.cod_cfg_rgp_pal);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIB_CFG_RGP_PAL > '||rec.lib_cfg_rgp_pal);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_1 > '||rec.libre_sp_ent_cfg_rgp_pal_1);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_2 > '||rec.libre_sp_ent_cfg_rgp_pal_2);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_3 > '||rec.libre_sp_ent_cfg_rgp_pal_3);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_4 > '||rec.libre_sp_ent_cfg_rgp_pal_4);
        su_bas_put_debug('su_bas_urw_sp_ent_cfg_rgp_pal : Col LIBRE_SP_ENT_CFG_RGP_PAL_5 > '||rec.libre_sp_ent_cfg_rgp_pal_5);
    END IF;

        RAISE;
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
