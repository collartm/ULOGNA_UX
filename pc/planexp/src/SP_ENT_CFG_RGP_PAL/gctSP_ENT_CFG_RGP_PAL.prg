/* $Id$
****************************************************************************
* su_bas_gct_sp_ent_cfg_rgp_pal - Mise à jour d'un enregistrement de la table SP_ENT_CFG_RGP_PAL par rapport à un contexte 
*/
-- DESCRIPTION :
-- -------------
-- Fonction qui récupère les colonnes d'un contexte dans une enregistrement de tableSP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_gct_sp_ent_cfg_rgp_pal( 
    p_ctx           IN OUT NOCOPY su_ctx_pkg.tt_ctx,
    rec             IN OUT NOCOPY SP_ENT_CFG_RGP_PAL%ROWTYPE ,
    p_ctx_prefix    varchar2 default null,
    p_ctx_suffix    varchar2 default null)
RETURN BOOLEAN
IS
BEGIN


  rec.cod_cfg_rgp_pal := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'COD_CFG_RGP_PAL' || p_ctx_suffix);
  rec.lib_cfg_rgp_pal := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'LIB_CFG_RGP_PAL' || p_ctx_suffix);
  rec.libre_sp_ent_cfg_rgp_pal_1 := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_1' || p_ctx_suffix);
  rec.libre_sp_ent_cfg_rgp_pal_2 := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_2' || p_ctx_suffix);
  rec.libre_sp_ent_cfg_rgp_pal_3 := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_3' || p_ctx_suffix);
  rec.libre_sp_ent_cfg_rgp_pal_4 := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_4' || p_ctx_suffix);
  rec.libre_sp_ent_cfg_rgp_pal_5 := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'LIBRE_SP_ENT_CFG_RGP_PAL_5' || p_ctx_suffix);
  rec.etat_phenyx := su_ctx_pkg.su_bas_get_number(p_ctx,p_ctx_prefix || 'ETAT_PHENYX' || p_ctx_suffix);
  rec.dat_crea := su_ctx_pkg.su_bas_get_date(p_ctx,p_ctx_prefix || 'DAT_CREA' || p_ctx_suffix);
  rec.dat_maj := su_ctx_pkg.su_bas_get_date(p_ctx,p_ctx_prefix || 'DAT_MAJ' || p_ctx_suffix);
  rec.ope_crea := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'OPE_CREA' || p_ctx_suffix);
  rec.ope_maj := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'OPE_MAJ' || p_ctx_suffix);
  rec.usr_crea := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'USR_CREA' || p_ctx_suffix);
  rec.usr_maj := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'USR_MAJ' || p_ctx_suffix);
  rec.info_pos_crea := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'INFO_POS_CREA' || p_ctx_suffix);
  rec.info_pos_maj := su_ctx_pkg.su_bas_get_char(p_ctx,p_ctx_prefix || 'INFO_POS_MAJ' || p_ctx_suffix);
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Pop ctx',
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
                        p_nom_obj         => 'su_bas_gct_sp_ent_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE );

        RAISE;
        RETURN false;

END;
/
SHOW ERRORS;
