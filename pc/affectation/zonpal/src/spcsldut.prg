/* $Id$
****************************************************************************
* sp_bas_csld_ut - Consolidation UT 
*/
-- DESCRIPTION :
-- -------------
--
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,25.08.14,pluc    Creation
-- 00a,24.10.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE PROCEDURE sp_bas_csld_ut
    (
     p_cod_usn su_usn.cod_usn%TYPE
    )
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_csld_ut';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(20)  := NULL;

BEGIN

    FOR r_ut IN ( SELECT cod_ut, typ_ut 
                  FROM pc_ut t 
                  WHERE su_bas_etat_val_num(etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('CONSOLIDE', 'PC_UT')  
                  AND libre_pc_ut_3 IS NOT NULL
                  AND cod_usn = p_cod_usn
                  AND etat_atv_pc_ut != 'PRP0'
                  AND NOT EXISTS ( SELECT 1 FROM pc_uee e 
                                   WHERE e.cod_ut_sup = t.cod_ut 
                                   AND e.typ_ut_sup = t.typ_ut 
                                   AND su_bas_etat_val_num(etat_atv_pc_uee, 'PC_UEE') < su_bas_etat_val_num('CONTROLE', 'PC_UEE')
                                  )
                 )  LOOP

       v_ret := pc_afu_pkg.pc_bas_consolide_1_ut (p_cod_ut => r_ut.cod_ut,
                                                  p_typ_ut => r_ut.typ_ut);   
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
END;
/
show errors;


