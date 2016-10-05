/* $Id$
****************************************************************************
* su_bas_2rw_sp_ent_cfg_rgp_pal - Construction rowtype SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de création d'un rowtype la table SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   ROWTYPE
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_2rw_sp_ent_cfg_rgp_pal(
    p_cod_cfg_rgp_pal               SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_lib_cfg_rgp_pal               SP_ENT_CFG_RGP_PAL.LIB_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_1    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_1%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_2    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_2%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_3    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_3%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_4    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_4%TYPE DEFAULT NULL,
    p_libre_sp_ent_cfg_rgp_pal_5    SP_ENT_CFG_RGP_PAL.LIBRE_SP_ENT_CFG_RGP_PAL_5%TYPE DEFAULT NULL,
    p_etat_phenyx                   SP_ENT_CFG_RGP_PAL.ETAT_PHENYX%TYPE DEFAULT NULL,
    p_dat_crea                      SP_ENT_CFG_RGP_PAL.DAT_CREA%TYPE DEFAULT NULL,
    p_dat_maj                       SP_ENT_CFG_RGP_PAL.DAT_MAJ%TYPE DEFAULT NULL,
    p_ope_crea                      SP_ENT_CFG_RGP_PAL.OPE_CREA%TYPE DEFAULT NULL,
    p_ope_maj                       SP_ENT_CFG_RGP_PAL.OPE_MAJ%TYPE DEFAULT NULL,
    p_usr_crea                      SP_ENT_CFG_RGP_PAL.USR_CREA%TYPE DEFAULT NULL,
    p_usr_maj                       SP_ENT_CFG_RGP_PAL.USR_MAJ%TYPE DEFAULT NULL,
    p_info_pos_crea                 SP_ENT_CFG_RGP_PAL.INFO_POS_CREA%TYPE DEFAULT NULL,
    p_info_pos_maj                  SP_ENT_CFG_RGP_PAL.INFO_POS_MAJ%TYPE DEFAULT NULL
    ) RETURN SP_ENT_CFG_RGP_PAL%ROWTYPE
IS
    rec             SP_ENT_CFG_RGP_PAL%ROWTYPE;

BEGIN


    rec.COD_CFG_RGP_PAL := p_cod_cfg_rgp_pal;
    rec.LIB_CFG_RGP_PAL := p_lib_cfg_rgp_pal;
    rec.LIBRE_SP_ENT_CFG_RGP_PAL_1 := p_libre_sp_ent_cfg_rgp_pal_1;
    rec.LIBRE_SP_ENT_CFG_RGP_PAL_2 := p_libre_sp_ent_cfg_rgp_pal_2;
    rec.LIBRE_SP_ENT_CFG_RGP_PAL_3 := p_libre_sp_ent_cfg_rgp_pal_3;
    rec.LIBRE_SP_ENT_CFG_RGP_PAL_4 := p_libre_sp_ent_cfg_rgp_pal_4;
    rec.LIBRE_SP_ENT_CFG_RGP_PAL_5 := p_libre_sp_ent_cfg_rgp_pal_5;
    rec.ETAT_PHENYX := nvl(p_etat_phenyx,0);
    rec.DAT_CREA := p_dat_crea;
    rec.DAT_MAJ := p_dat_maj;
    rec.OPE_CREA := p_ope_crea;
    rec.OPE_MAJ := p_ope_maj;
    rec.USR_CREA := p_usr_crea;
    rec.USR_MAJ := p_usr_maj;
    rec.INFO_POS_CREA := p_info_pos_crea;
    rec.INFO_POS_MAJ := p_info_pos_maj;

    RETURN rec;
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : Remplissage du record',
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
                        p_nom_obj         => 'su_bas_2rw_sp_ent_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE );

        RAISE;
        RETURN NULL;

END;
/
SHOW ERRORS;
