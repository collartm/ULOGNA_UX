/* $Id$
****************************************************************************
* pc_evt_atv_qvl_lig_com - 
*/
-- DESCRIPTION :
-- -------------
-- Gestion des evènements fonction pc_bas_atv_qvl_lig_com du package pc_integration_pkg
--
-- PARAMETRES :
-- ------------
--  P_EVENT : PRE/ON/POST 
--
-- HISTORIQUE DES MODIFICATIONS :
-- ---------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK    = Tout c'est bien passé
--  ERROR = Cela s'est mal passé
--  NULL  = Rien n'a été fait-------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,05.12.06, JDRE	Initialisation
-- 00a,05.12.06,GENPRG  version 2.9
-- ----------------------------------------------------------
--
-- COMMIT :
-- --------
--   ?

CREATE OR REPLACE
FUNCTION pc_evt_atv_qvl_lig_com (
    p_event                 VARCHAR2,
    pr_lig_com              PC_LIG_COM%ROWTYPE  
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_evt_atv_qvl_lig_com';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;

    v_ret               varchar2(100):=null;

BEGIN
    
    IF p_event = 'PRE' THEN
        v_etape := 'Action Pre';
    ELSIF p_event = 'ON' THEN
        v_etape := 'Action On';
    ELSIF p_event = 'POST' THEN
        v_etape := 'Action Post';

        -- recherche et prise en compte des modèles de palettisation (groupe et ordre produits).
        v_ret := sp_bas_rch_rgp_pal ( pr_lig_com.no_com, pr_lig_com.no_lig_com);

        -- Commandes squelette => palettisation à la commande
        IF su_bas_gcl_pc_ent_cmd ( pr_lig_com.no_cmd, 'LIBRE_PC_ENT_CMD_1') = '1' 
            OR su_bas_gcl_pc_ent_cmd( pr_lig_com.no_cmd, 'TYP_CMD') = 'D' THEN

            UPDATE pc_lig_com
                SET mode_pal_1 = 'CMD'
            WHERE no_com     = pr_lig_com.no_com
            AND   no_lig_com = pr_lig_com.no_lig_com;
        END IF;

    END IF;
    
    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Evt',
                        p_par_ano_1       => p_event,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;
/
show errors;

