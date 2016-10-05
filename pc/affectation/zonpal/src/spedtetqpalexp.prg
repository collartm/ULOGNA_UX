/* $Id$
****************************************************************************
* sp_bas_edt_etq_pal_exp -    
*
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet l'impression de la fiche logistique
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

CREATE OR REPLACE FUNCTION sp_bas_edt_etq_pal_exp 
    (
    p_cod_ut    pc_ut.cod_ut%TYPE,
    p_typ_ut    pc_ut.typ_ut%TYPE
    )
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02 $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_edt_etq_pal_exp';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    
    v_cod_ldoc      su_ldoc.cod_ldoc%TYPE;    
    v_cod_ope_tsk   su_tsk_fond.cod_ope_tsk%TYPE;    
    v_ctx           su_ctx_pkg.tt_ctx;
    v_add_ctx       BOOLEAN;    

    CURSOR c_ut IS
    SELECT cod_ut, typ_ut, etat_atv_pc_ut
    FROM   pc_ut
    WHERE  cod_ut = p_cod_ut
    AND    typ_ut = p_typ_ut;

    r_ut c_ut%ROWTYPE;
    v_found_ut BOOLEAN;

    CURSOR c_uee ( x_cod_ut pc_ut.cod_ut%TYPE,
                   x_typ_ut pc_ut.typ_ut%TYPE) IS
    SELECT 1
    FROM   pc_uee e
    WHERE  cod_ut_sup = x_cod_ut
    AND    typ_ut_sup = x_typ_ut
    AND    su_bas_etat_val_num(etat_atv_pc_uee , 'PC_UEE') < su_bas_etat_val_num('CONTROLE' , 'PC_UEE');

    r_uee c_uee%ROWTYPE;
    v_found_uee BOOLEAN;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : cod_ut = '  || p_cod_ut
                                  ||' : typ_ut = '  || p_typ_ut );
    END IF;

    OPEN c_ut;
    FETCH c_ut INTO r_ut;
    v_found_ut := c_ut%FOUND;
    CLOSE c_ut;

    IF v_found_ut THEN

        IF su_bas_etat_val_num(r_ut.etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('CONSOLIDE', 'PC_UT') THEN

            OPEN c_uee ( p_cod_ut, p_typ_ut);
            FETCH c_uee INTO r_uee;
            v_found_uee := c_uee%FOUND;
            CLOSE c_uee;

            IF NOT v_found_uee THEN

                v_etape := 'Déclaration consolidation ut ' || r_ut.cod_ut;
                v_ret := pc_afu_pkg.pc_bas_consolide_1_ut (p_cod_ut => r_ut.cod_ut,
                                                           p_typ_ut => r_ut.typ_ut);

            END IF;
        END IF;

        v_cod_ldoc := su_bas_rch_par_usn (p_cod_par_usn => 'SP_LDOC_ETQ_PAL_EXP',
                                          p_cod_usn => NVL(su_global_pkv.v_cod_usn,'%')
                                          );

        IF v_cod_ldoc IS NOT NULL THEN
            -- lancement ldoc
            v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx, 'P_COD_UT',   r_ut.cod_ut);
            v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx, 'P_TYP_UT',   r_ut.typ_ut);

            v_etape := 'Exécution ldoc ' || v_cod_ldoc;
            su_lst_doc_pkg.su_bas_exec_lst_doc (p_cod_ldoc  => v_cod_ldoc,
                                                p_lst_par   => v_ctx,
                                                p_cod_ope   => su_global_pkv.v_cod_ope,
                                                p_no_pos    => su_global_pkv.v_no_pos,
                                                p_aut_transaction => FALSE);

            su_my_alert.signal(su_bas_rch_affaire_str||'_ALT_'||'PRINT'||'_CTL', 'RUN');        
        END IF;

    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_ut',
                        p_par_ano_1       => p_cod_ut,
                        p_lib_ano_2       => 'typ_ut',
                        p_par_ano_2       => p_typ_ut,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;
/
show errors;

exit;