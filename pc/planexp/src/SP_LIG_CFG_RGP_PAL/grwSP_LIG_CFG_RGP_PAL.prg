/* $Id$
****************************************************************************
* su_bas_grw_sp_lig_cfg_rgp_pal - Lecture enregistrement table SP_LIG_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de lecture d'un enregistrement de la table SP_LIG_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   SP_LIG_CFG_RGP_PAL%ROWTYPE
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_grw_sp_lig_cfg_rgp_pal(
    p_cod_cfg_rgp_pal               SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE,
    p_val_dim_pro_rgp               SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP%TYPE,
    p_typ_pro_rgp                   SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP%TYPE
    ) RETURN SP_LIG_CFG_RGP_PAL%ROWTYPE
IS
    CURSOR c_row IS
        SELECT *
        FROM SP_LIG_CFG_RGP_PAL
        WHERE p_cod_cfg_rgp_pal = SP_LIG_CFG_RGP_PAL.COD_CFG_RGP_PAL
          AND p_val_dim_pro_rgp = SP_LIG_CFG_RGP_PAL.VAL_DIM_PRO_RGP
          AND p_typ_pro_rgp = SP_LIG_CFG_RGP_PAL.TYP_PRO_RGP;

    r_row SP_LIG_CFG_RGP_PAL%ROWTYPE;

BEGIN

    OPEN c_row;
    FETCH c_row INTO r_row;
    CLOSE c_row;

    RETURN r_row;
 -- Pas de gestion d'exception
END;
/
SHOW ERRORS;
