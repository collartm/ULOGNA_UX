/* $Id$
****************************************************************************
* sp_bas_edt_fl_tmp - Test édition fiche logistique temporaire    
*
*/
-- DESCRIPTION :
-- -------------
--
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver, Date    , Auteur   Description
-- -------------------------------------------------------------------------
-- 01a, 24.02.15, tjaf     Creation
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   OUI

CREATE OR REPLACE FUNCTION sp_bas_edt_fl_tmp 
    (
    p_cod_ut        pc_ut.cod_ut%TYPE,
    p_typ_ut        pc_ut.typ_ut%TYPE
    )
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_edt_fl_tmp';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    CURSOR c_ut IS
        SELECT  lib_ut, cod_ut_sup, typ_ut_sup, etat_atv_pc_ut
        FROM    pc_ut
        WHERE   cod_ut = p_cod_ut 
        AND     typ_ut = p_typ_ut;

    r_ut        c_ut%ROWTYPE;

    CURSOR c_ut_deb (x_cod_ut_sup pc_ut.cod_ut%TYPE,
                     x_typ_ut_sup pc_ut.typ_ut%TYPE) IS
        SELECT  1
        FROM    pc_ut
        WHERE   cod_ut_sup  = x_cod_ut_sup
        AND     typ_ut_sup  = x_typ_ut_sup
        AND     cod_pss_afc = 'SDB01';

    r_ut_deb    c_ut_deb%ROWTYPE;
BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_cod_ut = '  || p_cod_ut
                                  ||' : p_typ_ut = '  || p_typ_ut );
    END IF;

    -- Récupération du l'ut sup
    OPEN  c_ut;
    FETCH c_ut INTO r_ut;
    IF c_ut%FOUND THEN
        -- Cas de la palette à compléter en débord
        IF r_ut.lib_ut IS NOT NULL AND r_ut.cod_ut_sup IS NOT NULL THEN
            -- Verif existance palette débord
            OPEN  c_ut_deb(r_ut.cod_ut_sup, r_ut.typ_ut_sup);
            FETCH c_ut_deb INTO r_ut_deb;
            IF c_ut_deb%FOUND THEN
                RETURN 'OK';
            END IF;

            CLOSE c_ut_deb;
        END IF;
    
        -- Cas de la finalisation manuelle ou annulation
        IF r_ut.lib_ut IS NOT NULL AND su_bas_etat_val_num(r_ut.etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('CONSOLIDE', 'PC_UT') THEN
            RETURN 'OK';
        END IF;
    END IF;

    CLOSE c_ut;

    RETURN 'KO';

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cod_ut',
                        p_par_ano_1       => p_cod_ut,
                        p_lib_ano_2       => 'p_typ_ut',
                        p_par_ano_2       => p_typ_ut,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'KO';
END;
/
show errors;

EXIT;