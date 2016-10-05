/* $Id$
****************************************************************************
* sp_bas_suo_sqc_set_ut - 
*/
-- DESCRIPTION :
-- -------------
-- Proc�dure de declaration externe au package sequenceur d'une action sur l'UT              
--
--
-- PARAMETRES :
-- ------------
--  p_cod_ut : UT colis
--  p_typ_ut : UT colis
--  p_action : action trait�e 
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,10.12.14 pluc    Creation
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
-- 'OK' ou 'ERROR'
--
-- COMMIT :
-- --------
-- NON  

CREATE OR REPLACE
FUNCTION sp_bas_suo_sqc_set_ut (p_cod_ut       pc_uee.cod_ut%TYPE,
                                p_typ_ut       pc_uee.typ_ut%TYPE,
                                p_action       VARCHAR2,
                                p_par_1        VARCHAR2 DEFAULT NULL,
                                p_par_2        VARCHAR2 DEFAULT NULL,
                                p_par_3        VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_suo_sqc_set_ut';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';

BEGIN

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' UT:' || p_cod_ut || '-' || p_typ_ut);
        su_bas_put_debug(v_nom_obj||' p_action:' || p_action);
        su_bas_put_debug(v_nom_obj||' p_par_1 :' || p_par_1);
    END IF;

    CASE p_action 

        WHEN 'UT_MAJLIBUT' THEN
            --
            -- Mise � jour libell� UT : stocke valeur emp AGV pour magasin rebut colis
            -- Cas de finalisation manuelle de palettisation.
            --
            -- purge palette (finalisation ou annulation).
            IF p_par_1 IS NOT NULL THEN
                UPDATE pc_ut SET
                    lib_ut = su_bas_rch_action('SP_EMP_AGV', p_par_1)
                WHERE cod_ut = p_cod_ut AND typ_ut = p_typ_ut;

            END IF;
            -- d�simplantation
            IF su_bas_gcl_pc_ut(p_cod_ut, p_typ_ut, 'COD_CLI') = 'S' THEN
                UPDATE pc_ut SET
                    lib_ut = DECODE(su_bas_gcl_su_pro(cod_pro, 'LIBRE_SU_PRO_13'), 
                                                      '20', su_bas_rch_action('SP_EMP_AGV', 'SORINV'),
                                                      su_bas_rch_action('SP_EMP_AGV', 'DESIMPL')
                                    )
                WHERE cod_ut = p_cod_ut AND typ_ut = p_typ_ut;
            END IF;
        ELSE
            NULL;

    END CASE;

    RETURN v_ret;
            
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_ut',
                        p_par_ano_1       => p_cod_ut,
                        p_lib_ano_2       => 'typ_ut',
                        p_par_ano_2       => p_typ_ut,
                        p_lib_ano_3       => 'action',
                        p_par_ano_3       => p_action,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;   
/
show errors;

