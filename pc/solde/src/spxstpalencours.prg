/* $Id$
****************************************************************************
* sp_is_pal_en_cours -    
*
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de contrôler si ligne avec au moins 
-- 1 colis ordonnancé ( pour controle sur interruption ligne dans l'écran
-- de solde)
--
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02,26.11.14,pluc     Creation
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   OUI

CREATE OR REPLACE FUNCTION sp_bas_xst_pal_en_cours 
    (
    p_no_com        pc_lig_com.no_com%TYPE,
    p_no_lig_com    pc_lig_com.no_lig_com%TYPE,
    p_no_uee        pc_uee.no_uee%TYPE
    )
RETURN BOOLEAN
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02 $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_xst_pal_en_cours';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    CURSOR c_uee IS
    SELECT 1
    FROM   pc_ut u, pc_uee_det t, pc_uee e
    WHERE  (( t.no_com = p_no_com
             AND    t.no_lig_com = p_no_lig_com
             AND    p_no_com IS NOT NULL AND p_no_lig_com IS NOT NULL
            )
          OR (
             t.no_uee = p_no_uee
             AND p_no_uee IS NOT NULL
             )
           )
    AND    t.no_uee = e.no_uee
    AND    su_bas_etat_val_num(e.etat_atv_pc_uee, 'PC_UEE') >= su_bas_etat_val_num('ORDO_FINALISE', 'PC_UEE')
    AND    su_bas_etat_val_num(u.etat_atv_pc_ut, 'PC_UT') >= su_bas_etat_val_num('REGULATION', 'PC_UT')
    AND    EXISTS ( SELECT 1
                    FROM  pc_sqc_cle s
                    WHERE s.cod_cle_sqc = e.no_uee
                   )
    AND    e.cod_ut_sup = u.cod_ut
    AND    e.typ_ut_sup = u.typ_ut
    AND    su_bas_rch_cle_atv_pss_2 (e.cod_pss_afc, 'BFF', 'MODE_GES_BFF') = '2';
    
    r_uee c_uee%ROWTYPE;
    v_found_uee BOOLEAN;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : no_com = '  || p_no_com
                                  ||' : no_lig_com = ' || p_no_lig_com 
                                  ||' : no_uee = '|| p_no_uee);
    END IF;

    OPEN c_uee;
    FETCH c_uee INTO r_uee;
    v_found_uee := c_uee%FOUND;
    CLOSE c_uee;

    IF v_found_uee THEN 
        RETURN TRUE;
    END IF;

    RETURN FALSE;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'no_lig_com',
                        p_par_ano_2       => p_no_lig_com,
                        p_lib_ano_3       => 'no_uee',
                        p_par_ano_3       => p_no_uee,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN TRUE;
END;
/
show errors;

exit;