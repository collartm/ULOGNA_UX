/* $Id$
****************************************************************************
* pc_bas_recal_cubeiq - Lance la mise à jour par CubeIQ
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de relancer le calcul des coordonnées spatiales
-- des UEEs présents sur l'UP du colis passé en paramètre.
--
-- PARAMETRES :
-- ------------
--  - N° de colis
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,19.11.14,pluc    création
-- 00a,08.09.06,GENMPD  version 2.7
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE FUNCTION pc_bas_recal_cubeiq  
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_recal_cubeiq';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;

    CURSOR c_uee ( x_cod_up pc_up.cod_up%TYPE,
                   x_typ_up pc_up.typ_up%TYPE) IS
    SELECT 1 
    FROM   pc_uee
    WHERE  cod_up = x_cod_up
    AND    typ_up = x_typ_up;

    r_uee c_uee%ROWTYPE;
    v_found_uee BOOLEAN;

    -- récupère mode de calcul UP su dernier calcul OK.
    CURSOR c_der_cal ( x_cod_up pc_up.cod_up%TYPE,
                       x_typ_up pc_up.typ_up%TYPE ) IS
    SELECT par_cubeiq_3
    FROM   su_dia_cubeiq
    WHERE  par_cubeiq_1 = x_typ_up
    AND    par_cubeiq_2 = x_cod_up
    AND    etat_msg     = '0'
    ORDER BY dat_crea DESC;

    r_der_cal c_der_cal%ROWTYPE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj);
    END IF;

    FOR r_up IN ( SELECT no_msg_cubeiq, par_cubeiq_1 typ_up, par_cubeiq_2 cod_up FROM su_dia_cubeiq WHERE etat_msg = 'RECAL') LOOP

        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj || ' up ='||r_up.cod_up);
        END IF;

        OPEN c_uee ( r_up.cod_up, r_up.typ_up);
        FETCH c_uee INTO r_uee;
        v_found_uee := c_uee%FOUND;
        CLOSE c_uee;

        IF v_found_uee THEN

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || ' found uee');
            END IF;

            UPDATE pc_up
                SET etat_up_complete = '0'
                WHERE cod_up = r_up.cod_up
                AND   typ_up = r_up.typ_up;

            OPEN c_der_cal ( r_up.cod_up, r_up.typ_up);
            FETCH c_der_cal INTO r_der_cal;
            CLOSE c_der_cal;

            UPDATE su_dia_cubeiq
                SET etat_msg = '3',            -- + de hauteur
                    par_cubeiq_3 = r_der_cal.par_cubeiq_3     -- si chgt de mode de calcul 
            WHERE no_msg_cubeiq = r_up.no_msg_cubeiq;
        ELSE
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || ' not found uee');
            END IF;

            DELETE FROM su_dia_cubeiq WHERE no_msg_cubeiq = r_up.no_msg_cubeiq;
        END IF;

    END LOOP;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;
/
show errors;

