/* $Id$
****************************************************************************
* pc_bas_relance_uee_2_plan - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de relancer un colis annuler (PRP0) vers       
-- une reprise en charge par le calcul de plan palette.
-- 
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,16.10.14,mnev    Creation version pour sequenceur. 
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
-- OK : si tout va bien  
-- <ETAT COLIS> : si probleme sur l'etat du colis 
-- ERROR : si exception
--
-- COMMIT :
-- --------
-- NON

CREATE OR REPLACE
FUNCTION pc_bas_relance_uee_2_plan (p_no_uee  pc_uee.no_uee%TYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_relance_uee_2_plan';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_cod_pss           su_pss.cod_pss%TYPE;
    v_etat              pc_uee.etat_atv_pc_uee%TYPE := NULL;
    v_statut            VARCHAR2(20);
    v_crea_plan         VARCHAR2(20);
    vr_uee              pc_uee%ROWTYPE;

    CURSOR c_ut (x_cod_ut pc_ut.cod_ut%TYPE,
                 x_typ_ut pc_ut.typ_ut%TYPE) IS
        SELECT P.cod_ut, P.typ_ut, P.etat_atv_pc_ut, P.etat_pal_ut,
               P.cod_ut_sup, P.typ_ut_sup, P.cod_pss_afc
          FROM pc_ut P
         WHERE P.cod_ut=x_cod_ut AND P.typ_ut=x_typ_ut;

    r_ut            c_ut%ROWTYPE;
    
    -- recherche presence d'UEE sur l'UT + presence d'UEE ordonnancées 
    CURSOR c_uee_ut(x_cod_ut_sup pc_ut.cod_ut_sup%TYPE,
                    x_typ_ut_sup pc_ut.typ_ut_sup%TYPE) IS
        SELECT NVL(COUNT(no_uee),0) nb_uee, 
               NVL(SUM(su_bas_is_condi_etat_atv (etat_atv_pc_uee,'>=','ORDO_FINALISE','PC_UEE')),0) nb_uee_ordo
          FROM pc_uee
         WHERE cod_ut_sup=x_cod_ut_sup AND typ_ut_sup=x_typ_ut_sup;
                
    r_uee_ut   c_uee_ut%ROWTYPE;
     
    CURSOR c_ut_P2_vide (x_cod_ut_sup pc_uee.cod_ut_sup%TYPE,
                         x_typ_ut_sup pc_uee.typ_ut_sup%TYPE) IS
        SELECT cod_ut 
          FROM pc_ut
         WHERE cod_ut_sup=x_cod_ut_sup AND typ_ut_sup=x_typ_ut_sup AND etat_atv_pc_ut!=su_bas_rch_etat_atv('PREPARATION_NULLE','PC_UT') ;
      
    r_ut_P2_vide  c_ut_P2_vide%ROWTYPE;

    CURSOR c_lig IS 
        SELECT DISTINCT b.no_com, b.no_lig_com, b.no_cmd, b.no_lig_cmd
          FROM pc_uee_det a, pc_lig_com b
         WHERE a.no_com = b.no_com AND a.no_lig_com = b.no_lig_com AND a.no_uee = p_no_uee AND
               su_bas_etat_val_num (b.etat_atv_pc_lig_com,'PC_LIG_COM') > su_bas_etat_val_num ('SLD_RELANCE_AVEC_COLIS','PC_LIG_COM');

BEGIN

    SAVEPOINT my_pc_relance_uee_2_plan;

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' uee:' || p_no_uee);
    END IF;
                                   
    -- rch etat du colis
    v_etat := su_bas_gcl_pc_uee (p_no_uee=>p_no_uee,
                                 p_colonne=>'ETAT_ATV_PC_UEE');
     
    IF v_etat = su_bas_rch_etat_atv ('PREPARATION_INTERROMPUE','PC_UEE') OR
       v_etat = su_bas_rch_etat_atv ('PREPARATION_NULLE','PC_UEE') THEN

        v_etape := 'efface saisie temporaire';
        DELETE FROM pc_val_pc 
            WHERE typ_val_pc = 'T' AND no_uee = p_no_uee;

        v_etape := 'lecture row colis';
        vr_uee := su_bas_grw_pc_uee (p_no_uee => p_no_uee);

        IF su_bas_xst_pc_ut (p_cod_ut=>vr_uee.cod_ut_sup,
                             p_typ_ut=>vr_uee.typ_ut_sup) <> 'OUI' THEN
            vr_uee.cod_ut_sup := NULL;
            vr_uee.typ_ut_sup := NULL;
        END IF;

        --
        -- Le colis est bien interrompu ... on peut le relancer            
        -- . le process est conserve
        -- . on repositonne le colis et ses lignes à interruption
        --
        v_etape := 'Maj ligne colis CC';
        UPDATE pc_uee_det SET
            etat_atv_pc_uee_det = NVL(su_bas_rch_etat_atv ('SET_RELANCE_2_PLA','PC_UEE_DET'),etat_atv_pc_uee_det),
            no_pos              = NULL,
            cod_mag_pic         = NULL,
            cod_emp_pic         = NULL,
            no_bor_pic          = NULL,
            no_lig_bor_pic      = NULL,
            cle_distri_res      = NULL
        WHERE no_uee = p_no_uee;

        -- -------------------------------------------------------------
        -- MAJ UEE : recherche si calcul plan au preordo ..
        -- -------------------------------------------------------------
        v_etape := 'rch lieu calcul du plan';
        v_statut := su_bas_rch_cle_atv_pss(su_bas_get_pss_defaut(vr_uee.cod_usn),
                                           'POR',	        -- Type d'activité
                                           'CREA_PLAN',
                                           v_crea_plan);
        IF v_statut = 'ERROR' THEN
            RAISE err_except;
        END IF;

        -- -----------------------------------------------------------------------
        -- On souhaite ne plus tenir compte de l'UP actuelle pour cet UEE
        -- on doit donc effacer toutes traces de plan sur ce colis
        -- OU
        -- la ligne de commande est passée par un pré-ordo ligne, on va donc repasser 
        -- le colis dans l'étape avant pré-ordo ligne => suppression colis et donc retrait de l'éventuel palette
        -- -----------------------------------------------------------------------
        -- il faut corriger le plan ...
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||' annule info plan');
        END IF;

        IF vr_uee.cod_up IS NOT NULL AND 
           vr_uee.etat_atv_pc_uee <> su_bas_rch_etat_atv ('PREPARATION_NULLE','PC_UEE') THEN
            -- Correction de l'UP avec retrait de l'UEE
            v_etape := 'corrige UP';
            v_ret := pc_valprepa_pkg.pc_bas_corrige_up (pr_uee=>vr_uee);
            IF v_ret<>'OK' THEN
                RAISE err_except;
            END IF;
        END IF;

        v_etape := 'Maj colis 0';
        UPDATE pc_uee SET
            etat_atv_pc_uee = NVL(su_bas_rch_etat_atv('SET_RELANCE_2_PLA','PC_UEE'),etat_atv_pc_uee),
            cod_up          = NULL,
            typ_up          = NULL,
            cod_ut          = NULL,
            typ_ut          = NULL,
            cod_ut_sup      = NULL,
            typ_ut_sup      = NULL,
            lst_chkpt_suivi = lst_chkpt_suivi || ';REL2PLA;',
            dat_reg         = NULL,
            no_reg          = 0,
            no_rmp          = NULL,
            sgn_serie       = NULL,
            sgn_ss_serie    = NULL,
            no_ss_serie     = NULL,
            cod_grp_aff     = no_uee,
            etat_cr_lvzp    = '0',
            etat_cr_cpal    = '0',
            cb_complet      = NULL,
            dat_sel         = NULL,  
            dat_tn1         = NULL,
            mode_aff_uee    = NULL,
            no_uee_ut_p1    = NULL,
            cod_pss_afc     = NVL(cod_pss_avant_iter, cod_pss_afc), 
            cod_pss_avant_iter = NULL,
            motif_purge_uee = NULL
        WHERE no_uee = p_no_uee;

        -- prepare à 0  la palette si plus aucun colis affecté
        v_etape :='open c_uee_ut';
        OPEN c_uee_ut(vr_uee.cod_ut_sup,vr_uee.typ_ut_sup);
        v_etape :='fetch c_uee_ut';
        FETCH c_uee_ut INTO r_uee_ut;

        IF r_uee_ut.nb_uee=0 AND vr_uee.cod_ut_sup IS NOT NULL THEN

            v_etape :='recupere UT P2 associe à la P1 ';
            OPEN c_ut (vr_uee.cod_ut_sup, vr_uee.typ_ut_sup);
            FETCH c_ut INTO r_ut;
            CLOSE c_ut;

            v_etape :='fige a PRP0 la palette P1 '||r_ut.cod_ut;
            UPDATE pc_ut SET 
                etat_atv_pc_ut=su_bas_rch_etat_atv('PREPARATION_NULLE','PC_UT'),
                etat_pal_ut='0'
            WHERE cod_ut=vr_uee.cod_ut_sup AND typ_ut=vr_uee.typ_ut_sup;

            -- Liberation jeton au cas ou ...
            v_etape:='libere jeton';
            v_ret:=pc_afu_pkg.pc_bas_libere_jtn (p_cod_ut=>vr_uee.cod_ut_sup,
                                                 p_typ_ut=>vr_uee.typ_ut_sup);

            -- La P2 est-elle sans P1? si oui la figer a PRP0
            v_etape :='open c_ut_P2_vide';    
            OPEN c_ut_P2_vide(r_ut.cod_ut_sup,r_ut.typ_ut_sup);
            FETCH c_ut_P2_vide INTO r_ut_P2_vide;
            IF c_ut_P2_vide%NOTFOUND THEN
                v_etape :='fige a PRP0 la palette P2 '||r_ut.cod_ut_sup;
                UPDATE pc_ut SET 
                    etat_atv_pc_ut=su_bas_rch_etat_atv('PREPARATION_NULLE','PC_UT'),         --
                    etat_pal_ut='0'
                WHERE cod_ut=r_ut.cod_ut_sup and typ_ut=r_ut.typ_ut_sup;

                -- Liberation jeton au cas ou ...
                v_etape:='libere jeton';
                v_ret:=pc_afu_pkg.pc_bas_libere_jtn (p_cod_ut=>r_ut.cod_ut_sup,
                                                     p_typ_ut=>r_ut.typ_ut_sup);
            END IF;                        
            CLOSE c_ut_P2_vide;

        END IF;
        v_etape :='close c_uee_ut';
        CLOSE c_uee_ut;

        -- on repositionne a PORD si l'etat est plus avancé
        FOR r_lig IN c_lig LOOP

            v_etape := 'MAJ pc_lig_com REL_AVEC_COLIS';
            UPDATE pc_lig_com SET
                etat_atv_pc_lig_com=su_bas_rch_etat_atv('SLD_RELANCE_AVEC_COLIS','PC_LIG_COM')
            WHERE no_com=r_lig.no_com AND no_lig_com=r_lig.no_lig_com;

            -- on met a jour aussi ent_com, lig_cmd,ent_cmd
            UPDATE pc_ent_com SET
                etat_atv_pc_ent_com=su_bas_rch_etat_atv ('SLD_RELANCE_AVEC_COLIS','PC_ENT_COM')
            WHERE no_com=r_lig.no_com;

            -- $MOD,09.04.15,pluc Pas de mise à jour de l'entete pour ne pas envoyer un 2nd
            -- état "en cours" de commande vers le N3
            --UPDATE pc_ent_cmd SET
            --    etat_atv_pc_ent_cmd=su_bas_rch_etat_atv ('SLD_RELANCE_AVEC_COLIS','PC_ENT_CMD')
            --WHERE no_cmd=r_lig.no_cmd;

            UPDATE pc_lig_cmd SET
                etat_atv_pc_lig_cmd=su_bas_rch_etat_atv ('SLD_RELANCE_AVEC_COLIS','PC_LIG_CMD')
            WHERE no_cmd=r_lig.no_cmd AND no_lig_cmd=r_lig.no_lig_cmd;

            -- Memorise info traitement  prepa sur ligne com
            v_ret :=su_bas_ins_pc_dat_action(p_nom_table    =>'PC_LIG_COM',
                                                 p_cle_1    => r_lig.no_com,
                                                 p_cle_2    => TO_CHAR(r_lig.no_lig_com),
                                                 p_cod_act    => su_bas_rch_etat_atv('SLD_RELANCE_AVEC_COLIS','PC_LIG_COM'),
                                                 p_dat_act    => SYSDATE
                                                 );
        END LOOP;

        v_etape := 'Maj pc_sld_etat_uee_det';
        UPDATE pc_sld_etat_uee_det SET
            etat_annulation_uee_det = NULL,
            etat_interruption_uee_det = NULL,
            etat_solde_uee_det = NULL
        WHERE no_uee = p_no_uee;

        v_etape := 'Effacement pic_uee';
        DELETE pc_pic_uee
        WHERE no_uee = p_no_uee;

        su_bas_cre_ano (p_txt_ano         => v_etape,
                        p_niv_ano         => '3',
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_uee',
                        p_par_ano_1       => p_no_uee,
                        p_cod_err_su_ano  => 'PC-REPRP-002',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        v_ret := 'OK';
    ELSE
        -- probleme : l'etat du colis ne convient pas ... 
        v_ret := v_etat;
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_uee',
                        p_par_ano_1       => p_no_uee,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        ROLLBACK TO my_pc_relance_uee_2_plan;
        RETURN 'ERROR';
END;
/
show errors;

