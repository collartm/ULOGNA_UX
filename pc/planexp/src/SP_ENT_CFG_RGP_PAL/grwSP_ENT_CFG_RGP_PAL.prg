/* $Id$
****************************************************************************
* su_bas_grw_sp_ent_cfg_rgp_pal - Lecture enregistrement table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction de lecture d'un enregistrement de la table SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   SP_ENT_CFG_RGP_PAL%ROWTYPE
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_grw_sp_ent_cfg_rgp_pal(
    p_cod_cfg_rgp_pal               SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE
    ) RETURN SP_ENT_CFG_RGP_PAL%ROWTYPE
IS
    CURSOR c_row IS
        SELECT *
        FROM SP_ENT_CFG_RGP_PAL
        WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;

    r_row SP_ENT_CFG_RGP_PAL%ROWTYPE;

BEGIN

    OPEN c_row;
    FETCH c_row INTO r_row;
    CLOSE c_row;

    RETURN r_row;
 -- Pas de gestion d'exception
END;
/
SHOW ERRORS;
