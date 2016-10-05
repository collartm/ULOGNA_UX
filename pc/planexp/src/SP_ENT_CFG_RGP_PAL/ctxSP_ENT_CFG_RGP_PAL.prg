/* $Id$
****************************************************************************
* su_bas_ctx_sp_ent_cfg_rgp_pal - Mise en contexte d'un enregistrement de la table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction qui met l'ensemble des colonnes de la table dans un contexte SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_ctx_sp_ent_cfg_rgp_pal( 
    p_ctx           IN OUT NOCOPY su_ctx_pkg.tt_ctx,
    rec             SP_ENT_CFG_RGP_PAL%ROWTYPE ,
    p_ctx_prefix    varchar2 default null,
    p_ctx_suffix    varchar2 default null)
RETURN BOOLEAN
IS
BEGIN

    IF 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'COD_CFG_RGP_PAL' || p_ctx_suffix,rec.cod_cfg_rgp_pal) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'LIB_CFG_RGP_PAL' || p_ctx_suffix,rec.lib_cfg_rgp_pal) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_1' || p_ctx_suffix,rec.libre_sp_ent_cfg_rgp_pal_1) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_2' || p_ctx_suffix,rec.libre_sp_ent_cfg_rgp_pal_2) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_3' || p_ctx_suffix,rec.libre_sp_ent_cfg_rgp_pal_3) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_4' || p_ctx_suffix,rec.libre_sp_ent_cfg_rgp_pal_4) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_5' || p_ctx_suffix,rec.libre_sp_ent_cfg_rgp_pal_5) AND 
        su_ctx_pkg.su_bas_set_number(p_ctx,p_ctx_prefix || 'ETAT_PHENYX' || p_ctx_suffix,rec.etat_phenyx) AND 
        su_ctx_pkg.su_bas_set_date(p_ctx,p_ctx_prefix || 'DAT_CREA' || p_ctx_suffix,rec.dat_crea) AND 
        su_ctx_pkg.su_bas_set_date(p_ctx,p_ctx_prefix || 'DAT_MAJ' || p_ctx_suffix,rec.dat_maj) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'OPE_CREA' || p_ctx_suffix,rec.ope_crea) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'OPE_MAJ' || p_ctx_suffix,rec.ope_maj) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'USR_CREA' || p_ctx_suffix,rec.usr_crea) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'USR_MAJ' || p_ctx_suffix,rec.usr_maj) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'INFO_POS_CREA' || p_ctx_suffix,rec.info_pos_crea) AND 
        su_ctx_pkg.su_bas_set_char(p_ctx,p_ctx_prefix || 'INFO_POS_MAJ' || p_ctx_suffix,rec.info_pos_maj)
    THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Push ctx',
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
                        p_nom_obj         => 'su_bas_ctx_sp_ent_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE );

        RAISE;
        RETURN false;

END;
/
SHOW ERRORS;
