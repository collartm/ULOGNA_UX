/* $Id$
****************************************************************************
* su_bas_xst_sp_ent_cfg_rgp_pal - Existence enregistrement table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction qui teste l'existence d'un enregistrement de la table SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   OUI/NON/ERROR
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_xst_sp_ent_cfg_rgp_pal(
    p_cod_cfg_rgp_pal               SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE
    ) RETURN VARCHAR2
IS
    v_ret           VARCHAR2(10)  := 'NON';

    CURSOR c_row IS
        SELECT 'OUI'
        FROM SP_ENT_CFG_RGP_PAL
        WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;

BEGIN

    OPEN c_row;
    FETCH c_row INTO v_ret;
    CLOSE c_row;

    RETURN v_ret;
EXCEPTION
    WHEN OTHERS THEN
        -- Pas de gestion d'anomalie pour pouvoir gérer cette fonction en SELECT
        RETURN 'ERROR';

END;
/
SHOW ERRORS;
