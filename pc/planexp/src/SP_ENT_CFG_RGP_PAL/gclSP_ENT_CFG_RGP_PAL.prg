/* $Id$
****************************************************************************
* su_bas_gcl_sp_ent_cfg_rgp_pal - Valeur d'une colonne d'une table SP_ENT_CFG_RGP_PAL
*/
-- DESCRIPTION :
-- -------------
-- Fonction qui retourne la valeur d'une colonne d'un enregistrement de la table SP_ENT_CFG_RGP_PAL
--
-- RETOUR :
-- --------
--   Valeur de colonne en VARCHAR2
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION su_bas_gcl_sp_ent_cfg_rgp_pal(
    p_cod_cfg_rgp_pal               SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL%TYPE,
    p_colonne                       VARCHAR2
    ) RETURN VARCHAR2
IS
    --v_version       VARCHAR2(50)  := '@(#) VERSION 00a $Revision$';
    --v_nom_obj       VARCHAR2(50)  := 'su_bas_gcl_sp_ent_cfg_rgp_pal';
    --v_etape         varchar2(500) ;

    v_ret           VARCHAR2(4000);

    CURSOR c_lib_cfg_rgp_pal IS SELECT LIB_CFG_RGP_PAL FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_libre_sp_ent_cfg_rgp_pal_1 IS SELECT LIBRE_SP_ENT_CFG_RGP_PAL_1 FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_libre_sp_ent_cfg_rgp_pal_2 IS SELECT LIBRE_SP_ENT_CFG_RGP_PAL_2 FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_libre_sp_ent_cfg_rgp_pal_3 IS SELECT LIBRE_SP_ENT_CFG_RGP_PAL_3 FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_libre_sp_ent_cfg_rgp_pal_4 IS SELECT LIBRE_SP_ENT_CFG_RGP_PAL_4 FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_libre_sp_ent_cfg_rgp_pal_5 IS SELECT LIBRE_SP_ENT_CFG_RGP_PAL_5 FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_etat_phenyx IS SELECT ETAT_PHENYX FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_dat_crea IS SELECT to_char(DAT_CREA,su_bas_get_date_format) FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_dat_maj IS SELECT to_char(DAT_MAJ,su_bas_get_date_format) FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_ope_crea IS SELECT OPE_CREA FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_ope_maj IS SELECT OPE_MAJ FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_usr_crea IS SELECT USR_CREA FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_usr_maj IS SELECT USR_MAJ FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_info_pos_crea IS SELECT INFO_POS_CREA FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
    CURSOR c_info_pos_maj IS SELECT INFO_POS_MAJ FROM SP_ENT_CFG_RGP_PAL WHERE p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL;
BEGIN

    --v_etape := 'Rch enregistrement';
    CASE UPPER(p_colonne)
    WHEN 'LIB_CFG_RGP_PAL' THEN open c_lib_cfg_rgp_pal; FETCH c_lib_cfg_rgp_pal INTO v_ret; CLOSE c_lib_cfg_rgp_pal;
    WHEN 'LIBRE_SP_ENT_CFG_RGP_PAL_1' THEN open c_libre_sp_ent_cfg_rgp_pal_1; FETCH c_libre_sp_ent_cfg_rgp_pal_1 INTO v_ret; CLOSE c_libre_sp_ent_cfg_rgp_pal_1;
    WHEN 'LIBRE_SP_ENT_CFG_RGP_PAL_2' THEN open c_libre_sp_ent_cfg_rgp_pal_2; FETCH c_libre_sp_ent_cfg_rgp_pal_2 INTO v_ret; CLOSE c_libre_sp_ent_cfg_rgp_pal_2;
    WHEN 'LIBRE_SP_ENT_CFG_RGP_PAL_3' THEN open c_libre_sp_ent_cfg_rgp_pal_3; FETCH c_libre_sp_ent_cfg_rgp_pal_3 INTO v_ret; CLOSE c_libre_sp_ent_cfg_rgp_pal_3;
    WHEN 'LIBRE_SP_ENT_CFG_RGP_PAL_4' THEN open c_libre_sp_ent_cfg_rgp_pal_4; FETCH c_libre_sp_ent_cfg_rgp_pal_4 INTO v_ret; CLOSE c_libre_sp_ent_cfg_rgp_pal_4;
    WHEN 'LIBRE_SP_ENT_CFG_RGP_PAL_5' THEN open c_libre_sp_ent_cfg_rgp_pal_5; FETCH c_libre_sp_ent_cfg_rgp_pal_5 INTO v_ret; CLOSE c_libre_sp_ent_cfg_rgp_pal_5;
    WHEN 'ETAT_PHENYX' THEN open c_etat_phenyx; FETCH c_etat_phenyx INTO v_ret; CLOSE c_etat_phenyx;
    WHEN 'DAT_CREA' THEN open c_dat_crea; FETCH c_dat_crea INTO v_ret; CLOSE c_dat_crea;
    WHEN 'DAT_MAJ' THEN open c_dat_maj; FETCH c_dat_maj INTO v_ret; CLOSE c_dat_maj;
    WHEN 'OPE_CREA' THEN open c_ope_crea; FETCH c_ope_crea INTO v_ret; CLOSE c_ope_crea;
    WHEN 'OPE_MAJ' THEN open c_ope_maj; FETCH c_ope_maj INTO v_ret; CLOSE c_ope_maj;
    WHEN 'USR_CREA' THEN open c_usr_crea; FETCH c_usr_crea INTO v_ret; CLOSE c_usr_crea;
    WHEN 'USR_MAJ' THEN open c_usr_maj; FETCH c_usr_maj INTO v_ret; CLOSE c_usr_maj;
    WHEN 'INFO_POS_CREA' THEN open c_info_pos_crea; FETCH c_info_pos_crea INTO v_ret; CLOSE c_info_pos_crea;
    WHEN 'INFO_POS_MAJ' THEN open c_info_pos_maj; FETCH c_info_pos_maj INTO v_ret; CLOSE c_info_pos_maj;
    ELSE
      IF UPPER(p_colonne) in ('DAT_CREA','DAT_MAJ') THEN
        EXECUTE IMMEDIATE 'DECLARE CURSOR c_col IS SELECT to_char('||p_colonne||',su_bas_get_date_format) FROM SP_ENT_CFG_RGP_PAL WHERE :p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL; BEGIN OPEN c_col;FETCH c_col INTO :v_ret; CLOSE c_col; END;'
        USING IN p_cod_cfg_rgp_pal , OUT v_ret;
      ELSE
        EXECUTE IMMEDIATE 'DECLARE CURSOR c_col IS SELECT '||p_colonne||' FROM SP_ENT_CFG_RGP_PAL WHERE :p_cod_cfg_rgp_pal = SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL; BEGIN OPEN c_col;FETCH c_col INTO :v_ret; CLOSE c_col; END;'
        USING IN p_cod_cfg_rgp_pal , OUT v_ret;
      END IF;
    END CASE;
    RETURN v_ret;
EXCEPTION WHEN OTHERS THEN
    EXECUTE IMMEDIATE 'DECLARE CURSOR c_col IS SELECT '||p_colonne||' FROM VF_SP_ENT_CFG_RGP_PAL WHERE :p_cod_cfg_rgp_pal = VF_SP_ENT_CFG_RGP_PAL.COD_CFG_RGP_PAL; BEGIN OPEN c_col;FETCH c_col INTO :v_ret; CLOSE c_col; END;'
    USING IN p_cod_cfg_rgp_pal , OUT v_ret;
    return v_ret;
END;
/
SHOW ERRORS;
