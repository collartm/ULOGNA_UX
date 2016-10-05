/* $Id$ 
**************************************************************************** 
* sp_bas_raz_ut_debord - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'annuler et de relancer d'une palette pour process 
-- débord dans le cas d'une annulation de la palette méca associée.
--
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver, Date,    Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a, 29.09.15, pluc   Creation
-- 00a, 24.04.14, GENPRG version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_bas_raz_ut_debord
     (
      p_cod_ut pc_ut.cod_ut%TYPE,
      p_typ_ut pc_ut.typ_ut%TYPE,
      p_motif  VARCHAR2
      )
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_raz_ut_debord';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;

    v_ret VARCHAR2(50) := 'OK';

    CURSOR c_ut ( x_cod_ut pc_ut.cod_ut%TYPE,
                  x_typ_ut pc_ut.typ_ut%TYPE) IS
    SELECT u.cod_ut, u.typ_ut
    FROM   pc_ut u, pc_ut t
    WHERE  t.cod_ut = x_cod_ut
    AND    t.typ_ut = x_typ_ut
    AND    t.cod_ut_sup IS NOT NULL
    AND    u.cod_ut_sup = t.cod_ut_sup
    AND    u.typ_ut_sup = t.typ_ut_sup
    AND    u.cod_pss_afc = 'SDB01';
    
    r_ut       c_ut%ROWTYPE;
    v_found_ut BOOLEAN;
    
BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug (v_nom_obj);
    END IF;

    IF p_motif = 'UT_ANRPRP' THEN
    
        OPEN c_ut ( p_cod_ut, p_typ_ut);
        FETCH c_ut INTO r_ut;
        v_found_ut := c_ut%FOUND;
        CLOSE c_ut;
        
        IF v_found_ut THEN
        
            FOR r_uee IN ( SELECT no_uee FROM pc_uee WHERE cod_ut_sup = r_ut.cod_ut AND typ_ut_sup = r_ut.typ_ut) LOOP
                
                v_ret := pc_solde_pkg.pc_bas_annulation_uee (p_no_uee     => r_uee.no_uee,
                                                             p_cpt_commit => NULL);
  
                IF v_ret != 'OK' THEN
                    RAISE err_except;
                END IF;

                v_ret := pc_bas_relance_uee_2_plan (p_no_uee => r_uee.no_uee);
                IF v_ret != 'OK' THEN
                    RAISE err_except;
                END IF;
            END LOOP;
        END IF;
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        su_bas_cre_ano (p_txt_ano            => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano    => SQLCODE,
                        p_cod_err_su_ano     => v_cod_err_su_ano,
                        p_nom_obj            => v_nom_obj,
                        p_version            => v_version);
        RETURN 'ERROR';
END;
/
