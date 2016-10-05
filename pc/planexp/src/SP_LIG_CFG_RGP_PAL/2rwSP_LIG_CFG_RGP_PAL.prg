/* $Id$
****************************************************************************
* su_bas_2rw_sp_lig_cfg_rgp_pal - Construction rowtype SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de création d'un rowtype la table SP_LIG_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   ROWTYPE
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_2rw_sp_lig_cfg_rgp_pal(
    p_cod_cfg_rgp_pal               SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE DEFAULT NULL,
    p_val_dim_pro_rgp               SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP%TYPE DEFAULT NULL,
    p_typ_pro_rgp                   SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP%TYPE DEFAULT NULL,
    p_no_rgp_pal                    SP_LIG_CFG_RGP_PAL.NO_RGP_PAL%TYPE DEFAULT NULL,
    p_no_ord_rgp_pal                SP_LIG_CFG_RGP_PAL.NO_ORD_RGP_PAL%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_1    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_1%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_2    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_2%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_3    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_3%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_4    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_4%TYPE DEFAULT NULL,
    p_libre_sp_lig_cfg_rgp_pal_5    SP_LIG_CFG_RGP_PAL.LIBRE_SP_LIG_CFG_RGP_PAL_5%TYPE DEFAULT NULL,
    p_etat_phenyx                   SP_LIG_CFG_RGP_PAL.ETAT_PHENYX%TYPE DEFAULT NULL,
    p_dat_crea                      SP_LIG_CFG_RGP_PAL.DAT_CREA%TYPE DEFAULT NULL,
    p_dat_maj                       SP_LIG_CFG_RGP_PAL.DAT_MAJ%TYPE DEFAULT NULL,
    p_ope_crea                      SP_LIG_CFG_RGP_PAL.OPE_CREA%TYPE DEFAULT NULL,
    p_ope_maj                       SP_LIG_CFG_RGP_PAL.OPE_MAJ%TYPE DEFAULT NULL,
    p_usr_crea                      SP_LIG_CFG_RGP_PAL.USR_CREA%TYPE DEFAULT NULL,
    p_usr_maj                       SP_LIG_CFG_RGP_PAL.USR_MAJ%TYPE DEFAULT NULL,
    p_info_pos_crea                 SP_LIG_CFG_RGP_PAL.INFO_POS_CREA%TYPE DEFAULT NULL,
    p_info_pos_maj                  SP_LIG_CFG_RGP_PAL.INFO_POS_MAJ%TYPE DEFAULT NULL
    ) RETURN SP_LIG_CFG_RGP_PAL%ROWTYPE
IS
    rec             SP_LIG_CFG_RGP_PAL%ROWTYPE;

BEGIN


    rec.COD_CFG_RGP_PAL := p_cod_cfg_rgp_pal;
    rec.VAL_DIM_PRO_RGP := p_val_dim_pro_rgp;
    rec.TYP_PRO_RGP := p_typ_pro_rgp;
    rec.NO_RGP_PAL := p_no_rgp_pal;
    rec.NO_ORD_RGP_PAL := p_no_ord_rgp_pal;
    rec.LIBRE_SP_LIG_CFG_RGP_PAL_1 := p_libre_sp_lig_cfg_rgp_pal_1;
    rec.LIBRE_SP_LIG_CFG_RGP_PAL_2 := p_libre_sp_lig_cfg_rgp_pal_2;
    rec.LIBRE_SP_LIG_CFG_RGP_PAL_3 := p_libre_sp_lig_cfg_rgp_pal_3;
    rec.LIBRE_SP_LIG_CFG_RGP_PAL_4 := p_libre_sp_lig_cfg_rgp_pal_4;
    rec.LIBRE_SP_LIG_CFG_RGP_PAL_5 := p_libre_sp_lig_cfg_rgp_pal_5;
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
                        p_par_ano_2       => p_val_dim_pro_rgp,
                        p_lib_ano_2       => 'VALDIMPROR',
                        p_par_ano_3       => p_typ_pro_rgp,
                        p_lib_ano_3       => 'TYPPRORGP',
                        p_par_ano_4       => p_no_rgp_pal,
                        p_lib_ano_4       => 'NORGPPAL',
                        p_par_ano_5       => p_no_ord_rgp_pal,
                        p_lib_ano_5       => 'NOORDRGPPA',
                        p_par_ano_6       => p_libre_sp_lig_cfg_rgp_pal_1,
                        p_lib_ano_6       => 'LIBRESPLIG',
                        p_par_ano_7       => p_libre_sp_lig_cfg_rgp_pal_2,
                        p_lib_ano_7       => 'LIBRESPLIG',
                        p_par_ano_8       => p_libre_sp_lig_cfg_rgp_pal_3,
                        p_lib_ano_8       => 'LIBRESPLIG',
                        p_par_ano_9       => p_libre_sp_lig_cfg_rgp_pal_4,
                        p_lib_ano_9       => 'LIBRESPLIG',
                        p_par_ano_10      => p_libre_sp_lig_cfg_rgp_pal_5,
                        p_lib_ano_10      => 'LIBRESPLIG',
                        p_nom_obj         => 'su_bas_2rw_sp_lig_cfg_rgp_pal',
                        p_version         => '@(#) VERSION 00a $Revision$',
                        p_cod_err_ora_ano => SQLCODE );

        RAISE;
        RETURN NULL;

END;
/
SHOW ERRORS;
