/* $Id$
****************************************************************************
* pc_bas_atv_sup_lig_cmd - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de 
--
-- PARAMETRES :
-- ------------
--  p_mode : '0' = supprimer
--           '1' = marquer
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02b,21.05.14,mnev    Ajout controle av/ap preordo sur delete reel d'1 ligne
-- 02a,12.02.14,mnev    Supprime la gestion des lignes négatives (ces lignes
--                      n'existent plus depuis la 12.2).
-- 01c,03.03.10,mnev    Utilise bas_is_cli_integrable en + du parametre
-- 01b,19.02.07,mnev    réorganisation
-- 01a,10.12.06,alfl    initiale
-- 00a,24.11.06,GENMPD  version 2.8
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION pc_bas_atv_sup_lig_cmd (p_mode                  VARCHAR2,
                                 p_no_cmd                PC_ENT_CMD.no_cmd%TYPE,
                                 p_no_lig_cmd            PC_LIG_CMD.no_lig_cmd%TYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_sup_lig_cmd';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    ret_maj             EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(20)  := NULL;
    v_etat              su_action_atv.etat_atv%TYPE;
    v_pc                VARCHAR2(20)  := NULL;  -- avec/sans module PC
    v_cod_usn           su_usn.cod_usn%TYPE;
    
    CURSOR c_lig_cmd IS 
    SELECT * 
    FROM pc_lig_cmd
    WHERE no_cmd = p_no_cmd AND  no_lig_cmd = p_no_lig_cmd
    FOR UPDATE;

    r_lig_cmd           pc_lig_cmd%ROWTYPE;
    
    CURSOR c_lig_com IS 
    SELECT * 
    FROM pc_lig_com
    WHERE no_cmd = p_no_cmd AND  no_lig_cmd = p_no_lig_cmd
    ORDER BY qte_cde ASC;
    
    r_lig_com           pc_lig_com%ROWTYPE;
    v_xst_lig_com       BOOLEAN;
    v_cod_cli           pc_ent_cmd.cod_cli%TYPE := NULL;
    v_no_ord            NUMBER;
    v_no_ord_pord       NUMBER;


BEGIN

    SAVEPOINT my_sp_atv_sup_lig_cmd;

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' : no_cmd = ' || p_no_cmd || ' lig_cmd:' || p_no_lig_cmd);
    END IF;

    /************************ 
     1) PHASE INITIALISATION 
     ************************/

    -- ooooooooooooooooooooooooooooooo
    -- DEBUT         code pré-standard

    -- test si cmd existe
    v_cod_usn := su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,
                                       p_colonne=>'COD_USN');
    IF v_cod_usn IS NULL THEN
        v_cod_err_su_ano := 'PC_ENT_CMD_002';-- usine absente
        RAISE err_except;
    END IF;

    --   -- Rechercher l'enregistrement 
	IF su_bas_xst_pc_lig_cmd (p_no_cmd=>p_no_cmd, p_no_lig_cmd=>p_no_lig_cmd) = 'NON' THEN		    
        -- lig commande introuvable 
        v_cod_err_su_ano := 'PC_LIG_CMD_002';
        RAISE err_except;
    END IF;

    -- recherche de la ligne
    v_etape := 'open c_lig_cmd';
    OPEN c_lig_cmd;
    FETCH c_lig_cmd INTO r_lig_cmd;

    -- FIN           code pré-standard
    -- ooooooooooooooooooooooooooooooo

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_SUP_LIG_CMD') THEN 
        v_ret_evt := pc_evt_atv_sup_lig_cmd('PRE' , r_lig_cmd);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /********************
     2) PHASE TRAITEMENT 
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_ATV_SUP_LIG_CMD') THEN 
        v_ret_evt := pc_evt_atv_sup_lig_cmd('ON' , r_lig_cmd);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        -- 
        -- DEBUT         code standard
        --
        v_etape := 'Début';
        -- on test si la ligne est deja integree
        v_etape := 'Open c_lig_com';
        OPEN c_lig_com;
        FETCH c_lig_com INTO r_lig_com;
        v_xst_lig_com := c_lig_com%FOUND;
        CLOSE c_lig_com;
        
        IF v_xst_lig_com THEN
            --
            -- ----------- deja integree --------------
            -- => modification avec qte a 0
            --
            v_etape := 'qte a 0';
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || ' etape:' || v_etape);
            END IF;
            
            r_lig_cmd.qte_cde:=0;
            v_ret :=pc_bas_atv_maj_lig_cmd (p_mode        =>'0', 
                                            pr_new_lig_cmd=>r_lig_cmd);
            
            IF v_ret = 'ERROR' THEN
                -- exception
                RAISE err_except;
            ELSIF v_ret <> 'OK' THEN
                -- retour d'une erreur de traitement
                RAISE ret_maj;
            END IF;
        END IF;
        
        ----------------pas integree ou déjà integree avec ret ok ---------------
        
        v_etape := 'marque ';
        v_etat := su_bas_rch_etat_atv('SUPPRESSION','PC_LIG_CMD');
        
        r_lig_cmd.etat_atv_pc_lig_cmd := v_etat;
            
        UPDATE pc_lig_cmd SET 
            etat_atv_pc_lig_cmd = v_etat
        WHERE no_cmd = p_no_cmd AND no_lig_cmd = p_no_lig_cmd;
        
        IF p_mode = '0' THEN
            --
            -- suppression reelle lig_cmd
            --
            v_etape := 'recup no_ord 1';
            pc_bas_get_sup_etat_atv_cmd (p_no_cmd    =>p_no_cmd,
                                         p_no_lig_cmd=>p_no_lig_cmd,
                                         p_no_ord    =>v_no_ord); -- out

            v_no_ord_pord := su_bas_etat_val_num ('VALIDATION_PREORDO','PC_LIG_COM');

            v_etape := 'avant ou apres pre ordo';
            IF v_no_ord < v_no_ord_pord THEN

                v_etape:='delete lig_cmd';
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || ' etape:' || v_etape);
                END IF;
                
                DELETE pc_lig_cmd 
                WHERE no_cmd = p_no_cmd AND no_lig_cmd = p_no_lig_cmd;
                   
                -- maj nb_lig_att et nb_lig_recu de pc_ent_cmd
                v_ret := pc_bas_recal_nb_lig_ent_cmd (p_no_cmd, '-');

                su_bas_cre_ano (p_txt_ano         => 'OK',
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'no_cmd',
                                p_par_ano_1       => p_no_cmd,
                                p_lib_ano_2       => 'no_lig_cmd',
                                p_par_ano_2       => TO_CHAR(p_no_lig_cmd),
                                p_cod_err_su_ano  => 'PC_LIG_CMD_004',
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version,
                                p_niv_ano         => 4);
            ELSE
                DELETE FROM pc_lig_cmd
                    WHERE no_cmd = p_no_cmd 
                    AND no_lig_cmd = p_no_lig_cmd
                    AND etat_atv_pc_lig_cmd = 'TERM';

            END IF;

        END IF;  

        --      
        -- FIN   code du traitement standard
        -- 

    END IF;

    /**********************
     3) PHASE FINALISATION
    **********************/
    --
    -- oooooooooooooooooooooooooooooo
    -- DEBUT code du traitement final 

    v_pc := su_bas_rch_action (p_nom_par   =>'CFG_FLUX_MODULE',
                               p_par       =>v_cod_usn,
                               p_cod_module=>'SU',
                               p_no_action =>2);
    
    IF NVL(v_pc,'1') = '1' THEN
        -- module PC : OK => lire config client
        v_cod_cli := su_bas_gcl_pc_ent_cmd(p_no_cmd=>r_lig_cmd.no_cmd,
                                           p_colonne=>'COD_CLI');

        v_pc := pc_bas_is_cli_integrable (v_cod_cli,'C',SYSDATE);
    END IF;

    -- Si avec module PC alors on finalise 
    IF NVL(v_pc,'1') = '1' AND 
       NVL(r_lig_cmd.etat_atv_pc_lig_cmd,'#NULL#') <> su_bas_rch_etat_atv('CREATION_N3','PC_LIG_CMD') THEN
        v_etape := 'finalisation';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj || ' etape:' || v_etape);
        END IF;
	    v_ret := pc_bas_fnl_enr_lig_cmd ('DELETE', r_lig_cmd);
        IF v_ret != 'OK' THEN
            RAISE err_except;
        END IF;
    ELSE
        -- on travaille sans module PC
        v_ret := 'OK';
    END IF;

    -- FIN   code du traitement final 
    -- oooooooooooooooooooooooooooooo

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_SUP_LIG_CMD') THEN 
        v_ret_evt := pc_evt_atv_sup_lig_cmd('POST' , r_lig_cmd);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;
    
    CLOSE c_lig_cmd;          

    RETURN NVL(v_cod_err_su_ano, v_ret);

EXCEPTION
    WHEN ret_maj THEN
        ROLLBACK TO my_sp_atv_sup_lig_cmd;
        RETURN v_ret; 

    WHEN OTHERS THEN
        ROLLBACK TO my_sp_atv_sup_lig_cmd;
        
        IF c_lig_cmd%ISOPEN THEN
		    CLOSE c_lig_cmd;
		END IF;

        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_cmd',
                        p_par_ano_1       => p_no_cmd,
                        p_lib_ano_2       => 'no_lig_cmd',
                        p_par_ano_2       => TO_CHAR(p_no_lig_cmd),
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;
/
show errors;

