/* $Id$
****************************************************************************
* sp_bas_simu_csl_pal -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de simuler la consolidation des palettes 
-- PARAMETRES :
-- ------------
--  xxx
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,29.09.16,mco2    cr�ation
-- 00a,18.09.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE PROCEDURE sp_bas_simu_csl_pal (
    p_nb_pal_max    NUMBER,
    p_lst_usn       VARCHAR2 default '*',
    p_offset_dat    VARCHAR2 default '0')
IS

    v_version          su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj          su_ano_his.nom_obj%TYPE := 'sp_bas_simu_csl_pal';
    v_etape            su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano   su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except         EXCEPTION;
    v_ret              VARCHAR2 (100) := NULL;

CURSOR c_ut (x_date DATE)IS
SELECT cod_ut, typ_ut
FROM pc_ut
WHERE su_bas_etat_val_num(etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('CONSOLIDE', 'PC_UT')
AND (p_lst_usn='*' OR p_lst_usn='%' OR p_lst_usn IS NULL OR INSTR(p_lst_usn,';'||cod_usn||';')>0)
AND rownum <= p_nb_pal_max
AND dat_crea<x_date;

r_ut c_ut%ROWTYPE;

BEGIN
    
    OPEN c_ut(SYSDATE-NVL(su_bas_to_number(p_offset_dat),0));
    FETCH c_ut INTO r_ut;
    WHILE c_ut%FOUND
    LOOP
        v_ret := sp_bas_edt_etq_pal_exp (p_cod_ut  =>  r_ut.cod_ut, p_typ_ut  =>  r_ut.typ_ut);
        FETCH c_ut INTO r_ut;
    END LOOP;
    CLOSE c_ut;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1 => 'Ut',
                        p_par_ano_1 => r_ut.typ_ut||'-'||r_ut.cod_ut,
                        p_lib_ano_2 => 'p_offset_dat',
                        p_par_ano_2 => p_offset_dat,
                        p_cod_err_su_ano => v_cod_err_su_ano,
                        p_nom_obj => v_nom_obj,
                        p_version => v_version);

END;
/
show errors;
