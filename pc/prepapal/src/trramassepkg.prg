/* $Id$
****************************************************************************
* pc_tr_ramasse_pkg -
*/
-- DESCRIPTION :
-- -------------
-- Ce package g�re les menu du terminal radio des postes ramasse
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01d,19.04.12,rbel    ajout contrainte usine dans rch ut
-- 01c,16.04.12,rbel    gestion validation temporaire
-- 01b,28.07.10,rbel    Diverses corrections d'�critures
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
CREATE OR REPLACE
PACKAGE BODY pc_tr_ramasse_pkg AS

/*
****************************************************************************
* su_bas_bor_commence-
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de savoir si le traitement d'un bordereau est commenc�
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,24.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
-- RETOUR :
-- --------
--  OUI ou NON ou ERROR

-- COMMIT :
-- --------
--  NON

FUNCTION su_bas_bor_commence 
RETURN VARCHAR2 IS
        
    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'su_bas_bor_commence';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE :=NULL;
    err_except       EXCEPTION;
    
    v_ret           VARCHAR2(10):='NON';
            
    CURSOR c_bor  IS             
     SELECT 'OUI' 
         FROM pc_pic p
         WHERE p.no_bor_pic =v_bordereau_en_cours AND 
               p.cod_err_pc_pic IS NULL AND 
               p.qte_pic > 0;  

BEGIN

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj);
    END IF;

    v_etape:='debut';
    OPEN c_bor;
    FETCH c_bor INTO v_ret;
    CLOSE c_bor;
    
    RETURN v_ret; 
EXCEPTION
    WHEN OTHERS THEN
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'poste',
                        p_par_ano_1       => v_no_pos,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';

END;
    
/*
****************************************************************************
* su_bas_key_f1 -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de prendre en compte l'appui par l'op�rateur
-- sur la touche F1 => Sortir
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE su_bas_key_f1 IS
    
    v_active_win    su_tr_win.cod_win%TYPE;
    v_active_item   su_tr_item.cod_item%TYPE;

    BEGIN
        
        v_active_win  := su_term_pkg.get_active_win;
        v_active_item := su_term_pkg.get_active_item;

        IF  v_active_win = 'W_LST_BOR' THEN
            IF su_bas_bor_commence!='OUI'  THEN
                pc_bas_desaff_bor(v_bordereau_en_cours);
                v_bordereau_en_cours := NULL;                
                --su_term_pkg.close_module;
                su_term_pkg.active_window('W_ATT_BOR');
            ELSE
                su_term_pkg.close_cursor('C_LST_ORD_PIC');
                su_term_pkg.close_cursor('C_LST_UEE_PIC');
                --su_term_pkg.active_window('W_ATT_BOR');
                su_term_pkg.active_window('W_MODE_RET'||'_'||v_typ_val_pc);
            END IF;
                        
        ELSIF v_active_win = 'W_AFF_ORD_PIC' THEN
            v_cb_pic := NULL;                    
            su_term_pkg.close_cursor('C_LST_ORD_PIC');
            su_term_pkg.open_cursor('C_LST_ORD_PIC');
            su_term_pkg.active_window('W_LST_BOR');
        
        ELSIF v_active_win = 'W_AFF_UEE_PIC' THEN
            v_cb_uee :=NULL;                  
            su_term_pkg.close_cursor('C_LST_UEE_PIC');
            su_term_pkg.open_cursor('C_LST_UEE_PIC');
            su_term_pkg.close_cursor('C_LST_ORD_PIC');
            su_term_pkg.open_cursor('C_LST_ORD_PIC');
            su_term_pkg.active_window('W_LST_BOR');
        
        --ELSIF v_active_win = 'W_ATT_BOR' THEN
        --    su_term_pkg.active_window('W_MODE_VAL');
            
        ELSE
            IF v_bordereau_en_cours IS NOT NULL THEN
                pc_bas_desaff_bor(v_bordereau_en_cours);
                v_bordereau_en_cours := NULL;                
            END IF;
            su_term_pkg.close_module;
        END IF;
    END;


/*
****************************************************************************
* su_bas_key_f4 -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de prendre en compte l'appui par l'op�rateur
-- sur la touche F4 => Fin palette
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01d,04.07.13,alfl    controle qu'il reste des UEE_DET � traiter dans c_bor (x_borne_pc_uee_det)
-- au cas on la validation picking n'est pas configur�e
-- 01c,24.04.12,alfl    chosir le bordereau deja affect�
-- 01b,23.04.12,alfl    modif sur cursor c_bor pour prende en compte les bordereaux deja commenc�s
-- 01a,24.02.10,rleb    Version Phenyx
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE su_bas_key_f4 IS
        
    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01d $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'su_bas_key_f4';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO_0048';
    err_except       EXCEPTION;
    
    v_active_win    su_tr_win.cod_win%TYPE;
    v_ret           VARCHAR2(10);
    
            
    CURSOR c_bor(x_borne_pc_pic NUMBER, x_borne_pc_uee_det NUMBER)  IS             
     SELECT DISTINCT DECODE(d.no_pos,NULL,1,0),p.no_bor_pic bor ,p.niv_prio,p.dat_sel,p.dat_prep
         FROM pc_pic p, pc_pic_uee pu, pc_uee_det d
         WHERE p.cod_pic = pu.cod_pic
           AND pu.etat_actif = '1'
           AND pu.no_uee = d.no_uee  AND pu.no_com = d.no_com AND pu.no_lig_com = d.no_lig_com
           AND p.no_bor_pic IS NOT NULL
           AND p.cod_err_pc_pic IS NULL
           AND p.qte_pic < p.qte_a_pic  
           AND su_bas_etat_val_num(p.etat_atv_pc_pic,'PC_PIC') < x_borne_pc_pic
           AND su_bas_etat_val_num(d.etat_atv_pc_uee_det,'PC_UEE_DET') < x_borne_pc_uee_det
           AND (d.no_pos IS NULL OR d.no_pos=v_no_pos)
           AND su_bas_lst_cod_compare(v_lst_pss, p.cod_pss_afc) = 1
        ORDER BY 1,p.niv_prio, p.dat_sel, p.dat_prep;
                
    r_bor c_bor%ROWTYPE;
    

BEGIN
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' v_no_pos '||v_no_pos|| ' v_lst_pss '||v_lst_pss );
    END IF;

  
    v_active_win  := su_term_pkg.get_active_win;

    IF  v_active_win = 'W_ATT_BOR' THEN 
        v_etape := 'Affectation de bordereau � r�aliser ';
        v_no_bor_pic:=NULL;
        -- recherche  un bordereau affect� au poste en priorite
        OPEN c_bor(su_bas_etat_val_num ('LANCEMENT_N1','PC_PIC'),su_bas_etat_val_num ('PREPARATION_INTERROMPUE','PC_UEE_DET')) ;
        FETCH c_bor INTO r_bor;
        IF c_bor%FOUND THEN
            v_no_bor_pic:=r_bor.bor;
            v_cb_bor_pic_lu := NULL;
            
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj||v_etape||v_no_bor_pic);
            END IF;

            
            pc_bas_valid_debut_bor;
        ELSE
            su_term_pkg.active_window('W_NO_TRV');
            v_init_val := TRUE;
            su_term_pkg.create_timer(p_timer_name => 'TIMER_FEN',
                                         p_timer_proc => 'su_bas_init',
                                         p_freq       => 2,
                                         p_repeat     => FALSE);
        END IF;
        CLOSE c_bor;       
                  
    ELSIF  v_active_win = 'W_LST_BOR' THEN 
            NULL;
            /*
        v_etape := 'Cloture de bordereau';
        --Message de confirmation= Confirmez-vous la fin de la palette ?
        su_term_pkg.message_box_code(p_type    => 'ON',
                                     p_message => 'TER_RM_023',
                                     p_title   => 'TER_TITLE-0002',
                                     p_on_yes  => 'pc_bas_cloture_bor',
                                     p_on_no   => 'su_bas_init');
                                     */
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'poste',
                        p_par_ano_1       => v_no_pos,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');            
END;

                                
/*
****************************************************************************
* su_bas_init -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'initialiser le menu
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE su_bas_init IS
    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01c $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'su_bas_init';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';

    v_ret   VARCHAR2(10);
BEGIN
    
    v_etape := ' Appel fin bordereau';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj|| v_etape);
    END IF;


    v_no_pos := su_term_pkg.get_no_pos;
    v_cod_ope := su_term_pkg.get_cod_ope;        
    
    v_lst_pss := su_bas_gcl_pc_pos(p_no_pos =>v_no_pos,
                                         p_colonne => 'LST_PSS');
    
    v_lst_cod_cc_cb := su_bas_gcl_pc_pos(p_no_pos =>v_no_pos,
                                         p_colonne => 'LST_COD_CC_CB');
                                         
    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(su_global_pkv.v_cod_usn),
                                    p_typ_atv =>'PIC',
                                    p_cod_cfg =>'CC_CB_STK',
                                    p_val     =>v_cod_cc_stk);
            
    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(su_global_pkv.v_cod_usn),
                                    p_typ_atv =>'PIC',
                                    p_cod_cfg =>'LST_CC_CB_STK',
                                    p_val     =>v_lst_cod_cc_stk);
    
                                    
    IF v_ret <> 'OK' OR v_lst_cod_cc_stk IS NULL  THEN
       v_lst_cod_cc_stk:=';'||v_cod_cc_stk||';';
    END IF;
    
    v_index              := NULL;
    v_cb_bor_pic_lu      := NULL;
    v_no_bor_pic         := NULL;
    v_bordereau_en_cours := NULL;
    v_cb_pic             := NULL;
    v_cod_emp_en_cours   := NULL;
    v_no_com_en_cours    := NULL;
    v_no_cmd_en_cours    := NULL;
    v_no_lig_com_en_cours:= NULL;
    v_cod_ut             := NULL;
    v_typ_ut             := NULL;
    v_typ_ut_exp         := su_bas_gcl_su_lig_par(p_nom_par=>'TYP_UP',
                                         p_par=>'P1',
                                         p_cod_module=>'SU',
                                         p_etat_spec=>0,
                                         p_colonne => 'ACTION_LIG_PAR_2');
    v_lib_pro            := NULL;
    v_dlc_min            := NULL;
    v_qte_dem            := NULL;
    v_qte_prop           := NULL;
    v_qte_prel           := NULL;
    v_lst_uee            := ';';
    v_no_stk_en_cours    := NULL;
    v_cb_uee             := NULL;
    v_etat_pic           := NULL;
    v_typ_val_pc         :='C';      -- validation non temporaire 

    v_valid_par_colis := FALSE;
    
    IF v_init_val = TRUE THEN
        v_init_val := FALSE;
        su_term_pkg.active_window('W_ATT_BOR');
    --ELSE
    --  su_term_pkg.active_window('W_MODE_VAL');
    END IF;
     
END;

/*
****************************************************************************
* su_bas_exit -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de sortir du menu
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

    PROCEDURE su_bas_exit IS
    BEGIN
        su_term_pkg.close_cursor('C_LST_ORD_PIC');
        su_term_pkg.close_cursor('C_LST_UEE_PIC');
        
        
    END;

/*
****************************************************************************
* pc_bas_tr_ramasse_paquet
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de d�clarer que l'on travail par paquet de colis
-- (sans etiquette colis)
-- 
    PROCEDURE pc_bas_ramasse_paquet IS
    BEGIN
        v_valid_par_colis := FALSE;
    END;
/*
****************************************************************************
* pc_bas_tr_ramasse_colis
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de d�clarer que l'on travail colis par colis
-- pour editer une etiquette
--
    PROCEDURE pc_bas_ramasse_colis IS
    BEGIN
        v_valid_par_colis := TRUE;
    END;


/*
****************************************************************************
* pc_bas_valid_debut_bor -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de valider la lecture du bordereau en cours
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01c,24.04.12,alfl    refonte 
-- 01b,12.02.10,rleb    refonte pour tr_ramasse phenyx
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_valid_debut_bor IS

        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_valid_debut_bor';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
        err_except          EXCEPTION;
        v_ret               VARCHAR2(100) := NULL;
    
        v_ctx   		    su_ctx_pkg.tt_ctx;
        v_rec               su_read_cc_pkv.tr_read_cc;
        v_cod_cc    	    su_ent_cc.cod_cc%TYPE;
        v_cod_cc_next       su_ent_cc.cod_cc%TYPE;
        v_cfg_mode_tr       VARCHAR2(100);       
        

        --Curseur sur le bordereau
        CURSOR c_bor  IS             
            SELECT DISTINCT p.no_bor_pic bor, d.no_pos,
                            p.dat_sel, p.niv_prio, p.dat_prep,d.cod_pss_afc
              FROM pc_pic p, pc_pic_uee pu, pc_uee_det d
             WHERE (p.no_bor_pic = v_no_bor_pic )
               AND p.cod_pic = pu.cod_pic
               AND pu.etat_actif = '1'
               AND pu.no_uee = d.no_uee  AND pu.no_com = d.no_com AND pu.no_lig_com = d.no_lig_com
               AND p.no_bor_pic IS NOT NULL
               AND p.cod_err_pc_pic IS NULL
               AND p.qte_pic < p.qte_a_pic         -- pic avec un reste � pr�lever
               AND su_bas_lst_cod_compare(v_lst_pss, p.cod_pss_afc) = 1
            ORDER BY p.niv_prio, p.dat_sel, p.dat_prep;
                    
        r_bor c_bor%ROWTYPE;
        v_val_tmp   VARCHAR2(10);
        
        CURSOR c_bor_term IS
            SELECT SUM(qte_a_pic - qte_pic)
              FROM pc_pic p
             WHERE p.no_bor_pic = v_no_bor_pic
               AND su_bas_lst_cod_compare(v_lst_pss, p.cod_pss_afc) = 1;

        v_qte_rest    pc_pic.qte_a_pic%TYPE;        

        CURSOR c_cmd IS
        SELECT  no_cmd
        FROM    pc_lig_com m, pc_uee_det t
        WHERE   t.no_bor_pic = v_bordereau_en_cours
        AND     t.no_com = m.no_com
        AND     t.no_lig_com = m.no_lig_com;

        r_cmd c_cmd%ROWTYPE;
                                        
    BEGIN    
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj);
        END IF;

        v_ret := 'OK';

        -- test si on doit faire un decodage 
        IF v_cb_bor_pic_lu IS NOT NULL THEN
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                 su_bas_put_debug(v_nom_obj ||' : cb_lu = ' || v_cb_bor_pic_lu
                                        || ' / no_pos ' || v_no_pos
                                        || ' / cod_ope: ' || v_cod_ope);
             END IF;	    
       
            IF v_lst_cod_cc_cb IS NOT NULL THEN
                v_ctx.DELETE;
            
                v_etape := 'Decodage CB bordereau : ' || v_cb_bor_pic_lu;
	            v_ret := su_bas_read_lst_cc_rec (
                        p_rec => v_rec,
                        p_cod_cc => v_cod_cc,
                        p_cod_cc_next => v_cod_cc_next,
                        p_ctx => v_ctx,
                        p_val_cc => v_cb_bor_pic_lu,
                        p_typ_cc => NULL,
                        p_is_128 => NULL,
                        p_is_lg_fix => NULL,
                        p_fct_test => 'su_cc_pkg.su_bas_test_cc',
                        p_lst_cod_cc => v_lst_cod_cc_cb
                        );

                IF v_ret <> 'OK' THEN
		            v_etape := 'Probleme decodage CB bordereau picking : ' || v_cb_bor_pic_lu || 'v_ret = ' || v_ret;
		            su_term_pkg.message_box_code('O','TER_LCB_001','TER_TITLE-0001');
                    v_cb_bor_pic_lu := NULL;

	            ELSE
                    v_no_bor_pic  := SU_CTX_PKG.su_bas_get_char(v_ctx,'NO_BOR_PIC');

                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                       su_bas_put_debug(v_nom_obj ||' : decodage = ' ||
                                                    ' / v_no_bor_pic ' || v_no_bor_pic);
                    END IF;
                    IF v_no_bor_pic IS NULL THEN
                      -- D�codage OK mais pas de no_bor_pic dans le contexte??? Mauvais code � barre lu
                        su_term_pkg.message_box_code('O','TER_LCB_001','TER_TITLE-0001');
                        v_cb_bor_pic_lu := NULL;                                 
                    END IF;
                END IF;
            ELSE
                v_etape := 'Probl�me cfg cc poste absente';
                su_term_pkg.message_box_code('O','TER_LCB_002','TER_TITLE-0001');
                v_cb_bor_pic_lu := NULL;
            END IF;
        END IF;
        v_etape:=' on verfie le bordereau '||v_no_bor_pic;
         IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj|| v_etape);
        END IF;

        OPEN c_bor ; 
        FETCH c_bor INTO r_bor;
        IF c_bor%FOUND  THEN
            -- test si poste coincide pour gestion message erreur
            IF r_bor.no_pos IS NOT NULL AND r_bor.no_pos!=v_no_pos THEN
                su_term_pkg.message_box_code(p_type    => 'O',
                                         p_message => 'TER_LCB_005',
                                         p_title   => 'TER_TITLE-0001',
                                         p_par_1   => r_bor.no_pos
                                        );

                    
            ELSE
                v_bordereau_en_cours := r_bor.bor; --utile pour les curseurs

                --$MOD YQUE 23062015
                -- FORCAGE COD_PSS_AFC = SDB01 syst�matisquement pour permettre l'�dition
                v_etape:='Forcage process pour UT_SUP';
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj|| v_etape);
                END IF;
                UPDATE PC_UT 
                SET cod_pss_afc = r_bor.cod_pss_afc
                WHERE typ_up = 'P2' AND 
                    (cod_ut,typ_ut) in
                (SELECT distinct p.cod_ut_sup,p.typ_ut_sup
                 FROM pc_uee_det d ,pc_uee u,pc_ut p 
                 WHERE d.no_bor_pic = v_bordereau_en_cours AND 
                       u.no_uee = d.no_uee AND 
                       p.cod_ut = u.cod_ut_sup AND 
                       p.typ_ut = u.typ_ut_sup);
                COMMIT;
                --$MOD FIN

                OPEN c_cmd;
                FETCH c_cmd INTO r_cmd;
                CLOSE c_cmd;

                v_no_cmd_en_cours := r_cmd.no_cmd;

                -- suivi des performances
                sp_bas_ins_disout_utac  ( p_cod_ope  => v_cod_ope,
                                          p_no_tache => '006',
                                          p_no_cmd   => v_no_cmd_en_cours,
                                          p_statut   => 'O',
                                          p_date     => SYSDATE,
                                          p_qte      => 0
                                          );
                --insert into su_dia_sg ( no_msg_sg, etat_msg, cod_disout_prg, cle_car_1, cle_car_2, cle_car_3)
                --values( seq_dia_sg.nextval, '1', '801-UPRP-S', v_no_cmd_en_cours, '0', v_cod_ope);                

                su_bas_commit;

                v_etape:='recherche si validation temporaire';
                v_typ_val_pc:='C';
                
                v_ret := su_bas_rch_cle_atv_pss(p_cod_pss => r_bor.cod_pss_afc,
                                                p_typ_atv => 'PIC',
                                                p_cod_cfg => 'CFG_MODE_OP_TR', 
                                                p_val     => v_cfg_mode_tr);
                
                v_val_tmp := su_bas_rch_action_det(p_nom_par   => 'CFG_MODE_OP_TR', 
                                                   p_par       => v_cfg_mode_tr, 
                                                   p_no_action => 2);
                
                IF NVL(v_val_tmp, '0') = '1' THEN 
                    v_typ_val_pc:='T';    -- validation temporaire
                END IF;
                
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj ||' Type de validation '||v_typ_val_pc);
                END IF;
                pc_bas_aff_lst;
            END IF; 
        ELSE
            -- Bordereau termin� ou inconnu
            OPEN c_bor_term;
            FETCH c_bor_term INTO v_qte_rest;
            CLOSE c_bor_term;

            IF v_qte_rest <= 0 THEN
                -- bordereau termin�
                su_term_pkg.message_box_code('O','TER_RM_055','TER_TITLE-0001');
            ELSE
                su_term_pkg.message_box_code('O','TER_LCB_003','TER_TITLE-0001');
            END IF;            
        END IF;
        CLOSE c_bor;
        v_cb_bor_pic_lu := null;
        v_no_bor_pic:=NULL;

            
    EXCEPTION
        WHEN OTHERS THEN
            su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'no_pos',
                            p_par_ano_1       => v_no_pos,
                            p_lib_ano_2       => 'cod_ope',
                            p_par_ano_2       => v_cod_ope,
                            p_lib_ano_3       => 'cb lu',
                            p_par_ano_3       => v_cb_bor_pic_lu,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
            v_cb_bor_pic_lu := null;
            v_no_bor_pic:=NULL;

    END;

/*
****************************************************************************
* pc_bas_aff_lst -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de s'affecter le bordereau en cours
-- et d'afficher la liste du picking a realiser
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,12.02.10,rleb    refonte pour tr_ramasse phenyx
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_aff_lst IS
    
    v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_aff_lst';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except          EXCEPTION;

    v_ret               VARCHAR2(10):=NULL;
    
    CURSOR c_verif IS
        SELECT COUNT(*)
          FROM pc_uee_det
         WHERE no_pos = v_no_pos
           AND etat_atv_pc_uee_det IN (su_bas_rch_etat_atv( 'AFFECTATION_POSTE', 'PC_UEE_DET' ),
                                       su_bas_rch_etat_atv( 'TRANSFERE_POSTE', 'PC_UEE_DET' ))
           AND no_bor_pic = v_bordereau_en_cours;

    r_verif         c_verif%ROWTYPE;

    v_nb_uee_aff    NUMBER := 0;   -- Nombre d''UEE affect�s au poste courant

BEGIN

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj);
    END IF;

    v_etape := 'Affectation bordereau';
    v_ret := pc_bas_aff_bor_pos( p_no_pos     => v_no_pos,
                                 p_no_bor     => v_bordereau_en_cours,
                                 p_no_lig_bor => NULL,
                                 p_mode       => 'A' );
    IF v_ret != 'OK' THEN
        RAISE err_except;
    END IF;

    COMMIT;
    
    v_etape := 'V�rif si affectation Ok';
    OPEN c_verif;
    FETCH c_verif INTO v_nb_uee_aff;
    IF v_nb_uee_aff = 0 THEN
        -- Probl�me affectation
        su_term_pkg.message_box_code(p_type    => 'O',
                                     p_message => 'TER_LCB_007',
                                     p_title   => 'TER_TITLE-0001',
                                     p_par_1   => v_bordereau_en_cours
                                    );
        v_cb_bor_pic_lu := NULL;
    ELSE                
        v_titre := 'PREPA BOR=' || v_bordereau_en_cours;
        v_cb_pic := NULL;
    
        su_term_pkg.active_window('W_LST_BOR');
        su_term_pkg.open_cursor('C_LST_ORD_PIC');
        su_term_pkg.active_item('E_UT_A_PIC');
        
    END IF;
    CLOSE c_verif;

EXCEPTION
    WHEN OTHERS THEN
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret != 'ERROR' AND v_ret IS NOT NULL THEN 
            su_term_pkg.message_box_code('O',v_ret,'TER_TITLE-0001');
        ELSE
            su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');
        END IF;
END;


/*
****************************************************************************
* pc_bas_valid_cb_pic -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de valider la lecture du code barre de picking
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01d,20.03.14,rbel    Mise en commentaire de la jointure sur cod_ut + ajout order by sur cod_ut
-- 01c,20.06.13,mnev    Correction sur le decodage par lecture CB UT ou EMP
--
-- 01b,20.07.11,mnev    MAJ commentaires et etapes.
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_valid_cb_pic IS
   
    v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01d $Revision$';
    v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_valid_cb_pic';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except          EXCEPTION;
    
    v_ret               VARCHAR2(20);
    
    v_nb                NUMBER := 0;
    
    v_cod_cc_next       su_ent_cc.cod_cc%TYPE;
    v_cod_cc    	    su_ent_cc.cod_cc%TYPE;
    v_rec               su_read_cc_pkv.tr_read_cc;
    v_ctx   		    su_ctx_pkg.tt_ctx;
    
    v_emp_mono_ut       VARCHAR2(5);
    
    --
    -- il faut imperativement disposer de stock pour que la rch aboutisse
    --
    CURSOR c_ut (x_cod_ut  se_ut.cod_ut%TYPE,
                 x_typ_ut  se_ut.typ_ut%TYPE,
                 x_cod_emp se_emp.cod_emp%TYPE,
                 x_cb_emp  se_emp.cb_emp%TYPE,  
                 x_etat_num_uee_det pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
        SELECT s.*, p.dlc_min, p.cod_ops, d.no_com, d.no_lig_com
        FROM se_stk s, pc_pic p, pc_pic_uee pu, pc_uee_det d
        WHERE /*((s.cod_ut = x_cod_ut AND s.typ_ut = x_typ_ut) --cas ou le cb est une UT
                 OR
                 ( --cas ou l'on recherche une fiche de stock par rapport a un cb
                    (s.cod_pro = v_cod_pro OR v_cod_pro is null) 
                    AND (s.cod_va = v_cod_va OR v_cod_va is null) 
                    AND (s.cod_vl = v_cod_vl OR v_cod_vl is null )
                    AND (s.cod_prk = v_cod_prk OR v_cod_prk is null )
                    AND (x_cod_emp is null and x_cod_ut is null)
                 )
                 OR 
                 ((su_bas_gcl_se_emp(s.cod_emp, 'CB_EMP') = x_cb_emp OR
                    s.cod_emp = x_cod_emp))   --cas o� le cb est un emp
               )                  
          AND (p.cod_emp = s.cod_emp OR s.cod_emp IS NULL)
          */
          --AND (p.cod_ut_stk = s.cod_ut OR s.cod_ut IS NULL)
          s.cod_emp = x_cod_emp
          AND p.cod_mag = s.cod_mag
          AND p.cod_pro = s.cod_pro AND p.cod_va = s.cod_va AND p.cod_vl = s.cod_vl 
          AND NVL(p.cod_prk,'0') = NVL(s.cod_prk,'0') 
          AND p.no_bor_pic = v_bordereau_en_cours
          AND pu.cod_pic = p.cod_pic
          AND pu.etat_actif = '1'
          AND pu.no_uee = d.no_uee  AND pu.no_com = d.no_com AND pu.no_lig_com = d.no_lig_com               
          AND p.qte_pic < p.qte_a_pic         -- pic avec un reste � pr�lever
          AND su_bas_etat_val_num(d.etat_atv_pc_uee_det,'PC_UEE_DET') < x_etat_num_uee_det -- ligne colis non termin�
         ORDER BY DECODE(s.cod_lot_stk, v_cod_lot_stk, 0, 1),
                  DECODE(s.dat_dlc, v_dat_dlc, 0, 1),
                  DECODE(s.cod_ut || s.typ_ut, x_cod_ut || x_typ_ut, 0, 1),
                  s.dat_dlc;

    r_ut            c_ut%ROWTYPE;
    v_found_ut      BOOLEAN;

    -- rch si stock pr�sent ...
    CURSOR c_cause (x_cod_ut  se_ut.cod_ut%TYPE,
                    x_typ_ut  se_ut.typ_ut%TYPE,
                    x_cod_emp se_emp.cod_emp%TYPE,
                    x_cb_emp  se_emp.cb_emp%TYPE) IS
        SELECT * 
        FROM se_stk s
        WHERE ((s.cod_ut = x_cod_ut AND s.typ_ut = x_typ_ut) --cas ou le cb est une UT
                 OR
                 ( --cas ou l'on recherche une fiche de stock par rapport a un cb
                    (s.cod_pro = v_cod_pro OR v_cod_pro is null) 
                    AND (s.cod_va = v_cod_va OR v_cod_va is null) 
                    AND (s.cod_vl = v_cod_vl OR v_cod_vl is null )
                    AND (s.cod_prk = v_cod_prk OR v_cod_prk is null )
                    AND (x_cod_emp is null and x_cod_ut is null)
                 )
                 OR 
                 ((su_bas_gcl_se_emp(s.cod_emp, 'CB_EMP') = x_cb_emp OR
                    s.cod_emp = x_cod_emp))   --cas o� le cb est un emp
               );

    r_cause c_cause%ROWTYPE;
    
    CURSOR c_pic (x_cod_pro  pc_pic.cod_pro%TYPE,
                  x_cod_va   pc_pic.cod_va%TYPE,
                  x_cod_vl   pc_pic.cod_vl%TYPE) IS
        SELECT (qte_a_pic - qte_pic) qte_rest
        FROM pc_pic p
        WHERE p.cod_pro = x_cod_pro
          AND p.cod_va = x_cod_va
          AND p.cod_vl = x_cod_vl
          AND p.no_bor_pic = v_bordereau_en_cours;

    r_pic       c_pic%ROWTYPE;
    
    -- rch meilleur stock ailleurs ...
    CURSOR c_stk_tst (x_cod_emp     se_stk.cod_emp%TYPE,
                      x_dlc_min     se_stk.dat_dlc%TYPE,
                      x_dlc_trouve  se_stk.dat_dlc%TYPE,
                      x_cod_pro     pc_pic.cod_pro%TYPE,
                      x_cod_va      pc_pic.cod_va%TYPE,
                      x_cod_vl      pc_pic.cod_vl%TYPE) IS
    SELECT DISTINCT cod_ut, cod_emp 
      FROM se_stk
     WHERE (cod_emp = x_cod_emp OR x_cod_emp IS NULL)
       AND cod_pro = x_cod_pro 
       AND cod_va = x_cod_va 
       AND cod_vl = x_cod_vl 
       AND dat_dlc >= x_dlc_min
       AND dat_dlc < x_dlc_trouve
       AND etat_blocage_stk LIKE '_0_';
     
    r_stk_tst       c_stk_tst%ROWTYPE;
    
    -- controle si emplacement mono UT 
    CURSOR c_emp_cb (x_cod_emp se_stk.cod_emp%TYPE) IS
      SELECT NVL(COUNT(DISTINCT cod_ut||typ_ut),0) nb
      FROM se_stk 
      WHERE cod_emp=x_cod_emp AND qte_pce > 0; 

    r_emp_cb        c_emp_cb%ROWTYPE;
    found_emp_cb    BOOLEAN;
     
    -- Init des CB � NULL
    --
    -- Suite au decodage 1 seul CB devra �tre positionn�
    --
    v_cb_emp        VARCHAR2(100) := NULL;
    v_cb_ut         VARCHAR2(100) := NULL;
    v_cb_pro        VARCHAR2(100) := NULL;

    v_cod_emp       se_stk.cod_emp%TYPE := NULL;
    v_no_stk        se_stk.no_stk%TYPE  := NULL;
     
    v_par_1         VARCHAR2(100) := NULL;
    v_par_2         VARCHAR2(100) := NULL;

BEGIN

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' Raz');
    END IF;

    -- Raz des variables ...
    v_cod_ut          := NULL;
    v_typ_ut          := NULL;
    v_cod_lot_stk     := NULL;
    v_cod_mag         := NULL;
    v_cod_emp         := NULL;
    v_cod_pro         := NULL;
    v_cod_va          := NULL;
    v_cod_vl          := NULL; 
    v_cod_prk         := NULL;
    v_cod_lot_stk     := NULL;
    v_dat_dlc         := NULL;
    v_dat_stk         := NULL;
    v_cod_ss_lot_stk  := NULL;
    v_pds_brut_val    := NULL;
    v_pds_net_val     := NULL;
    v_car_stk_1       := NULL;
    v_car_stk_2       := NULL;
    v_car_stk_3       := NULL;
    v_car_stk_4       := NULL;
    v_car_stk_5       := NULL;
    v_car_stk_6       := NULL;
    v_car_stk_7       := NULL;
    v_car_stk_8       := NULL;
    v_car_stk_9       := NULL;
    v_car_stk_10      := NULL;
    v_car_stk_11      := NULL;
    v_car_stk_12      := NULL;
    v_car_stk_13      := NULL;
    v_car_stk_14      := NULL;
    v_car_stk_15      := NULL;
    v_car_stk_16      := NULL;
    v_car_stk_17      := NULL;
    v_car_stk_18      := NULL;
    v_car_stk_19      := NULL;
    v_car_stk_20      := NULL;


    v_etape := 'Recherche ut';
    -- Recherche si le CB correspond a une UT
    -- *************
    -- CB = CB UT ?
    -- *************
    --
    v_ret := se_bas_rch_ut (p_cb_ut  => v_cb_pic,
                            p_typ_ut => v_typ_ut,
                            p_cod_ut => v_cod_ut,
                            p_cod_usn_loc => su_global_pkv.v_cod_usn);
    
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj ||' CB=UT cod_ut trouv�=' || v_cod_ut || ' ret='||v_ret);
    END IF;
                
    IF v_cod_ut IS NULL THEN                               
        --
        -- Recherche si le CB correspond a un CB emplacement (il faut que l'emplacement soit mono-UT)
        -- *************
        -- CB = CB EMP ?
        -- *************
        --
        v_etape := 'R�cup nb emp et min(cod_emp) du CB';
        v_nb := se_bas_rch_emp_cb (p_cb_emp   => v_cb_pic,
                                   p_cod_emp  => v_cod_emp,
                                   p_cod_usn  => su_global_pkv.v_cod_usn,
                                   p_mask_mag => '%');
                                            
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj ||' CB=EMP cod_emp trouv�=' || v_cod_emp || ' nb=' || TO_CHAR(v_nb));
        END IF;

        IF v_nb >= 1 THEN
            --
            -- il existe au moins 1 emplacement pour ce CB ...
            --
            -- decodage OK via CB emplacement
            v_cb_emp := v_cb_pic; 
            -- 
            -- On pose que le min(cod_emp) retourn� par se_bas_rch_emp_cb
            -- designe l'emplacement de pr�l�vement.
            --
            -- Le premier emplacement est-il mono-ut ?
            --

            -- $MOD,18.02.15,pluc Spec SUO : possible multi-UT ( pas de gestion DLC/lot sur le d�bord).
            /*
            v_etape := 'Emp mono UT ?';
            OPEN c_emp_cb(v_cod_emp);
            FETCH c_emp_cb INTO r_emp_cb;
            found_emp_cb :=  c_emp_cb%FOUND;
            CLOSE c_emp_cb;
                     
            IF found_emp_cb THEN 
                IF r_emp_cb.nb > 1 THEN
                    -- Cet emplacement n'est pas mono-ut, on ne peut accepter un 
                    -- CB emplacement comme choix de lecture 
                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                       su_bas_put_debug(v_nom_obj ||' : WARNING !!! L''emplacement = ' || v_cod_emp
                                                  || ' n''est pas mono-UT. Utiliser le code_UT pour le d�codage. ');
                    END IF;
                    su_term_pkg.message_box_code('O','TER_RM_024','TER_TITLE-0001');
                    v_cb_emp  := NULL;
                    v_cod_emp := NULL;
                    v_nb := 0;
                END IF;
            END IF;
            */
        ELSE
            v_cb_emp  := NULL;
            v_cod_emp := NULL;
            v_nb := 0;
        END IF;         

    ELSE
        -- decodage OK via CB UT       
        v_cb_ut := v_cb_pic;
    END IF;                                   

    IF v_cod_emp IS NULL AND v_cod_ut IS NULL THEN 
        --
        -- SI le CB ne correspond NI a un cod_emp NI a un cod_ut 
        -- ALORS on regarde s'il correspond a un CB de stock
        -- *************
        -- CB = CB STK ?
        -- *************
        --
        v_ctx.DELETE;

        v_etape := 'decodage CB stock ';
        v_ret := su_bas_read_lst_cc_rec (
                                p_rec => v_rec,
                                p_cod_cc => v_cod_cc,
                                p_cod_cc_next => v_cod_cc_next,
                                p_ctx => v_ctx,
                                p_val_cc => v_cb_pic,
                                p_typ_cc => NULL,
                                p_is_128 => NULL, 
                                p_is_lg_fix => NULL, 
                                p_fct_test => 'su_cc_pkg.su_bas_test_cc', 
                                p_lst_cod_cc => v_lst_cod_cc_stk
                                );
        
        IF v_ret <> 'OK' THEN

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj ||' Echec rch CB stock=' || v_ret);
            END IF;

            v_etape:='decodage stk non trouv�e -> init';
            su_term_pkg.message_box_code('O','TER_RCH-0001','TER_TITLE-0001');
        
            v_cod_ut := NULL;
            v_typ_ut := NULL;
            v_cb_pic := NULL;
        
            RETURN;
        END IF;
        
        -- decodage OK via CB produit
        v_cb_pro          := v_cb_pic;

        v_cod_pro         := v_rec.cod_pro;
        v_cod_va          := v_rec.cod_va;
        v_cod_vl          := v_rec.cod_vl;
        v_cod_prk         := TO_CHAR(TO_NUMBER(v_rec.cod_prk));  -- Suppression du 0 non significatif
        v_cod_lot_stk     := v_rec.cod_lot_stk;
        v_dat_dlc         := TO_DATE(v_rec.dat_dlc, su_bas_get_date_format);
        v_dat_stk         := TO_DATE(v_rec.dat_stk, su_bas_get_date_format);
        v_cod_ss_lot_stk  := v_rec.cod_ss_lot_stk;
        v_pds_brut_val    := SU_CTX_PKG.su_bas_get_number(v_ctx,'PDS_BRUT_VAL');
        v_pds_net_val     := SU_CTX_PKG.su_bas_get_number(v_ctx,'PDS_NET_VAL');
        v_car_stk_1       := v_rec.car_stk_1;
        v_car_stk_2       := v_rec.car_stk_2;
        v_car_stk_3       := v_rec.car_stk_3;
        v_car_stk_4       := v_rec.car_stk_4;
        v_car_stk_5       := v_rec.car_stk_5;
        v_car_stk_6       := v_rec.car_stk_6;
        v_car_stk_7       := v_rec.car_stk_7;
        v_car_stk_8       := v_rec.car_stk_8;
        v_car_stk_9       := v_rec.car_stk_9;
        v_car_stk_10      := v_rec.car_stk_10;
        v_car_stk_11      := v_rec.car_stk_11;
        v_car_stk_12      := v_rec.car_stk_12;
        v_car_stk_13      := v_rec.car_stk_13;
        v_car_stk_14      := v_rec.car_stk_14;
        v_car_stk_15      := v_rec.car_stk_15;
        v_car_stk_16      := v_rec.car_stk_16;
        v_car_stk_17      := v_rec.car_stk_17;
        v_car_stk_18      := v_rec.car_stk_18;
        v_car_stk_19      := v_rec.car_stk_19;
        v_car_stk_20      := v_rec.car_stk_20;
        
        IF v_cod_pro IS NULL THEN

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj ||' Echec identification du produit');
            END IF;

            su_term_pkg.message_box_code('O','TER_RCH-0005','TER_TITLE-0001');
            
            v_cod_ut := NULL;
            v_typ_ut := NULL;
            v_cb_pic := NULL;
            
            RETURN;
        END IF;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj ||' Decodage cod_pro=' || v_cod_pro);
            su_bas_put_debug(v_nom_obj ||' Decodage cod_va =' || v_cod_va);
            su_bas_put_debug(v_nom_obj ||' Decodage cod_vl =' || v_cod_vl);
            su_bas_put_debug(v_nom_obj ||' Decodage cod_prk=' || v_cod_prk);
            su_bas_put_debug(v_nom_obj ||' Decodage cod_lot=' || v_cod_lot_stk);
            su_bas_put_debug(v_nom_obj ||' Decodage dat_dlc=' || TO_CHAR(v_dat_dlc,'DD/MM/YY'));
            su_bas_put_debug(v_nom_obj ||' Decodage dat_stk=' || TO_CHAR(v_dat_stk,'DD/MM/YY'));
            su_bas_put_debug(v_nom_obj ||' Decodage cod_slo=' || v_cod_ss_lot_stk);
        END IF;
        
    END IF;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj ||' Rch UT:' || v_cod_ut || ' ' || v_typ_ut || ' Emp:' ||v_cod_emp || ' CBEmp:' || v_cb_emp);
    END IF;

    v_etape := 'Recherche OPS pour bor en cours';
    OPEN c_ut(v_cod_ut, v_typ_ut, v_cod_emp, v_cb_emp, su_bas_etat_val_num('TEST_FIN_PREPA','PC_UEE_DET'));
    FETCH c_ut INTO r_ut;
    IF c_ut%FOUND THEN        

        IF v_cb_pro IS NULL THEN
            -- on n'est pas pass� par un CB produit ...
            -- donc on prend toutes les infos theoriques de la fiche stock
            -- retrouv�es � partir de l'UT ou de l'emplacement
            v_cod_pro         := r_ut.cod_pro;
            v_cod_va          := r_ut.cod_va;
            v_cod_vl          := r_ut.cod_vl;
            v_cod_prk         := r_ut.cod_prk;
            v_cod_lot_stk     := r_ut.cod_lot_stk;
            v_dat_dlc         := r_ut.dat_dlc;
            v_dat_stk         := r_ut.dat_stk;
            v_cod_ss_lot_stk  := r_ut.cod_ss_lot_stk;
            v_car_stk_1       := r_ut.car_stk_1;
            v_car_stk_2       := r_ut.car_stk_2;
            v_car_stk_3       := r_ut.car_stk_3;
            v_car_stk_4       := r_ut.car_stk_4;
            v_car_stk_5       := r_ut.car_stk_5;
            v_car_stk_6       := r_ut.car_stk_6;
            v_car_stk_7       := r_ut.car_stk_7;
            v_car_stk_8       := r_ut.car_stk_8;
            v_car_stk_9       := r_ut.car_stk_9;
            v_car_stk_10      := r_ut.car_stk_10;
            v_car_stk_11      := r_ut.car_stk_11;
            v_car_stk_12      := r_ut.car_stk_12;
            v_car_stk_13      := r_ut.car_stk_13;
            v_car_stk_14      := r_ut.car_stk_14;
            v_car_stk_15      := r_ut.car_stk_15;
            v_car_stk_16      := r_ut.car_stk_16;
            v_car_stk_17      := r_ut.car_stk_17;
            v_car_stk_18      := r_ut.car_stk_18;
            v_car_stk_19      := r_ut.car_stk_19;
            v_car_stk_20      := r_ut.car_stk_20;
        END IF;

        -- Magasin
        v_cod_mag         := r_ut.cod_mag;
        -- Emp 
        v_cod_emp         := r_ut.cod_emp;
        -- UT
        v_cod_ut          := r_ut.cod_ut;
        v_typ_ut          := r_ut.typ_ut;    
    
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj ||' Trouv� OPS:' || r_ut.cod_ops || ' no_stk:' || TO_NUMBER(r_ut.no_stk));
        END IF;

        -- V�rification compatibilit� stock
        v_etape := 'Test stock';
        v_ret := pc_bas_test_stk_compa_pic(p_cod_ops        => r_ut.cod_ops,
                                           p_cod_emp        => v_cod_emp,    
                                           p_cod_ut         => v_cod_ut,
                                           p_typ_ut         => v_typ_ut,
                                           p_cod_lot_stk    => v_cod_lot_stk,
                                           p_cod_ss_lot_stk => v_cod_ss_lot_stk,
                                           p_dat_dlc        => v_dat_dlc,
                                           p_dat_stk        => v_dat_stk,
                                           p_no_stk         => r_ut.no_stk,
                                           p_par_1          => v_par_1,
                                           p_par_2          => v_par_2,
                                           p_car_stk_1      => v_car_stk_1,
                                           p_car_stk_2      => v_car_stk_2,
                                           p_car_stk_3      => v_car_stk_3,
                                           p_car_stk_4      => v_car_stk_4,
                                           p_car_stk_5      => v_car_stk_5,
                                           p_car_stk_6      => v_car_stk_6,
                                           p_car_stk_7      => v_car_stk_7,
                                           p_car_stk_8      => v_car_stk_8,
                                           p_car_stk_9      => v_car_stk_9,
                                           p_car_stk_10     => v_car_stk_10,
                                           p_car_stk_11     => v_car_stk_11,
                                           p_car_stk_12     => v_car_stk_12,
                                           p_car_stk_13     => v_car_stk_13,
                                           p_car_stk_14     => v_car_stk_14,
                                           p_car_stk_15     => v_car_stk_15,
                                           p_car_stk_16     => v_car_stk_16,
                                           p_car_stk_17     => v_car_stk_17,
                                           p_car_stk_18     => v_car_stk_18,
                                           p_car_stk_19     => v_car_stk_19,
                                           p_car_stk_20     => v_car_stk_20);
                                                   
        IF v_ret <> 'OK' THEN

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj ||' Echec compatibilite du stock:' || v_ret);
            END IF;

            v_etape := 'Stock incompatible v_ret=' || v_ret;
            su_term_pkg.message_box_code(p_type    => 'O',
                                         p_message => v_ret,
                                         p_title   => 'TER_TITLE-0001',
                                         p_par_1   => v_par_1,
                                         p_par_2   => v_par_2);
            v_cod_ut := NULL;
            v_typ_ut := NULL;
            v_cb_pic := NULL;                        

        ELSE
            --
            -- stock jug� compatible mais ... 
            -- y a t-il un stock avec une DLC meilleure (plus courte) ?
            --
            v_etape := 'Rch stk';
            OPEN c_stk_tst(v_cod_emp, r_ut.dlc_min, v_dat_dlc, v_cod_pro, v_cod_va, v_cod_vl);
            FETCH c_stk_tst INTO r_stk_tst;
            IF c_stk_tst%FOUND THEN
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj ||' DLC plus courte ds emp:' || r_stk_tst.cod_emp);
                END IF;

                v_etape := 'Echec stk NOK';
                su_term_pkg.message_box_code(p_type    => 'O',
                                             p_message => 'TER_RM_007',
                                             p_title   => 'TER_TITLE-0002',
                                             p_par_1   => r_stk_tst.cod_ut);
                v_cod_ut := NULL;
                v_typ_ut := NULL;
                v_cb_pic := NULL;
                v_cb_emp := NULL;
                v_cb_pro := NULL;
                
            ELSE

                v_etape := 'Rch stk OK';
                v_cod_emp_en_cours := v_cod_emp;
                v_lib_emp_en_cours := SUBSTR(NVL(su_bas_gcl_se_emp(v_cod_emp_en_cours,'LIB_EMP'), v_cod_emp_en_cours), 1, 16);
                v_no_stk_en_cours  := r_ut.no_stk;
                v_cod_pro_en_cours := v_cod_pro;
                v_cod_va_en_cours  := v_cod_va;
                v_cod_vl_en_cours  := v_cod_vl;
                v_no_com_en_cours  := r_ut.no_com;
                v_no_lig_com_en_cours := r_ut.no_lig_com;
                
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj ||' Ca roule sur emp:' || v_cod_emp);
                END IF;

                v_etape := 'Affichage �cran suivant';
                IF v_valid_par_colis = FALSE THEN
                    --
                    -- validation par paquet
                    --
                    pc_bas_aff_ord_pic;
                    --
                    su_term_pkg.active_window('W_AFF_ORD_PIC');
                    su_term_pkg.active_item('E_QTE_PREL');
                ELSE
                    --
                    -- validation au colis
                    --
                    pc_bas_aff_uee_pic;
                    --
                    v_etape := 'active W_AFF_UEE_PIC';
                    su_term_pkg.active_window('W_AFF_UEE_PIC');
                    v_etape := 'close C_LST_UEE_PIC';
                    su_term_pkg.close_cursor('C_LST_UEE_PIC');
                    v_etape := 'opene C_LST_UEE_PIC';
                    su_term_pkg.open_cursor('C_LST_UEE_PIC');
                    su_term_pkg.active_item('E_CB_UEE');
                END IF;

            END IF;
            CLOSE c_stk_tst;            

        END IF;

    ELSE

        -- Rch explications sur le NOT FOUND ...
        -- 
        -- a t on du stock ?
        --
        v_etape := 'Rch explication';
        OPEN c_cause (v_cod_ut, v_typ_ut, v_cod_emp, v_cb_emp);
        FETCH c_cause INTO r_cause;
        IF c_cause%NOTFOUND THEN
            -- 
            -- il n'existe pas de stock ...
            --
            IF v_cod_ut IS NOT NULL THEN
                su_term_pkg.message_box_code('O','TER_RM_001','TER_TITLE-0001',
                                             p_par_1   => v_cod_ut);
            ELSIF v_cod_emp IS NOT NULL THEN
                su_term_pkg.message_box_code('O','TER_RM_026','TER_TITLE-0001',
                                             p_par_1   => v_cod_emp);
            ELSE
                su_term_pkg.message_box_code('O','TER_RM_027','TER_TITLE-0001',
                                             p_par_1   => v_cod_pro);
            END IF;
        ELSE
            -- 
            -- il existe bien du stock ... on suppose donc qu'il ne convient pas ...
            --
            OPEN c_pic(r_cause.cod_pro,
                       r_cause.cod_va,
                       r_cause.cod_vl);
            FETCH c_pic INTO r_pic;
            IF c_pic%NOTFOUND THEN
                -- Pas ce produit dans le bordereau
                su_term_pkg.message_box_code(p_type    => 'O',
                                         p_message => 'TER_RM_053',
                                         p_title   =>'TER_TITLE-0001',
                                         p_par_1   => r_cause.cod_pro);
            ELSIF r_pic.qte_rest <= 0 THEN
                -- Tout a �t� valid� pour ce produit dans ce bordereau
                su_term_pkg.message_box_code(p_type    => 'O',
                                         p_message => 'TER_RM_056',
                                         p_title   =>'TER_TITLE-0001',
                                         p_par_1   => r_cause.cod_pro);
            ELSE
                -- c'est le bon produit et il en reste � prendre dans ce bordereau
                -- UT non pr�sente dans le bon emplacement
                IF v_cod_ut IS NOT NULL THEN
                    su_term_pkg.message_box_code('O','TER_RM_051','TER_TITLE-0001',
                                                 p_par_1   => v_cod_ut);
                ELSIF v_cod_emp IS NOT NULL THEN
                    su_term_pkg.message_box_code('O','TER_RM_052','TER_TITLE-0001',
                                                 p_par_1   => v_cod_emp);
                ELSE
                    su_term_pkg.message_box_code('O','TER_RM_053','TER_TITLE-0001',
                                                 p_par_1   => r_cause.cod_pro);
                END IF;
            END IF;
            CLOSE c_pic;
        END IF;
        CLOSE c_cause;
        
        -- UT inconnue
        v_cod_ut := NULL;
        v_typ_ut := NULL;
        v_cb_pic := NULL;
        v_cb_emp := NULL;
        v_cb_pro := NULL;
                    
    END IF;
    CLOSE c_ut;        
    
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_lib_ano_2       => 'cb lu',
                        p_par_ano_2       => v_cb_pic,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');            

END;


/*
****************************************************************************
* pc_bas_aff_ord_pic -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'afficher les informations de l'ordre de picking
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,17.07.12,alfl    groupement par ops et non par ligne commande
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_aff_ord_pic IS

    v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_aff_ord_pic';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except          EXCEPTION;
    
    v_ret               VARCHAR2(10);
    
    CURSOR c_bor IS
        SELECT SUBSTR(su_pro.lib_pro, 1, 20) lib_pro,
               MIN(p.dlc_min) dlc_min, 
               SUM(su_bas_conv_unite_to_one_sel (p.cod_pro, p.cod_vl, p.qte_a_pic, p.unite_qte, 'C') - 
                     su_bas_conv_unite_to_one_sel (p.cod_pro, p.cod_vl, p.qte_pic, p.unite_qte, 'C')) qte_dem  
          FROM su_pro, pc_pic p, pc_pic_uee pu 
        WHERE p.cod_pro = v_cod_pro_en_cours
          AND p.cod_va = v_cod_va_en_cours
          AND p.cod_vl = v_cod_vl_en_cours
          AND p.no_bor_pic = v_bordereau_en_cours
          --AND (p.cod_emp = v_cod_emp_en_cours OR v_cod_emp_en_cours IS NULL)
          AND pu.cod_pic = p.cod_pic
          AND pu.etat_actif = '1'
          AND pu.no_com = v_no_com_en_cours
          --AND pu.no_lig_com = v_no_lig_com_en_cours 
          AND su_pro.cod_pro = p.cod_pro              
        GROUP BY su_pro.lib_pro, p.unite_qte,p.cod_ops;
        
    r_bor     c_bor%ROWTYPE;

    CURSOR c_info_ut (x_dlc_min   se_stk.dat_dlc%TYPE)IS
        SELECT TRUNC(SUM(su_bas_conv_unite_to_one_sel (s.cod_pro, s.cod_vl, s.qte_unit_1, s.unit_stk_1, 'C'))) prop
        FROM se_stk s
        WHERE (s.cod_ut = v_cod_ut AND s.typ_ut = v_typ_ut OR v_cod_ut IS NULL)
          AND (s.cod_emp = v_cod_emp_en_cours OR v_cod_emp_en_cours IS NULL)
          AND s.cod_pro = v_cod_pro_en_cours 
          AND s.cod_va = v_cod_va_en_cours
          AND s.cod_vl = v_cod_vl_en_cours
          AND s.cod_mag = v_cod_mag
          AND (s.dat_dlc >= x_dlc_min OR x_dlc_min IS NULL);

    r_info_ut c_info_ut%ROWTYPE;        
    
    -- on gere la quantit�e propos�e  si on a des validations temporaires
    CURSOR c_info_val (x_dlc_min   se_stk.dat_dlc%TYPE)IS
    SELECT SUM(nb_col_val) qte_val FROM PC_VAL_PC  s
    WHERE typ_val_pc='T' AND 
                (s.cod_ut_stk = v_cod_ut AND s.typ_ut_stk = v_typ_ut OR v_cod_ut IS NULL)
          AND (s.cod_emp = v_cod_emp_en_cours OR v_cod_emp_en_cours IS NULL)
          AND s.cod_pro = v_cod_pro_en_cours 
          AND s.cod_va = v_cod_va_en_cours
          AND s.cod_vl = v_cod_vl_en_cours
          AND s.cod_mag = v_cod_mag
          AND (s.dat_dlc >= x_dlc_min OR x_dlc_min IS NULL);
    
    r_info_val c_info_val%ROWTYPE; 

BEGIN

    v_etape := 'Recup INFO bor:' || v_bordereau_en_cours || ' emp:' || v_cod_emp_en_cours;

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj ||' '||v_etape);
    END IF;

    OPEN c_bor;
    FETCH c_bor INTO r_bor;
    IF c_bor%FOUND THEN
        v_lib_pro := r_bor.lib_pro;
        v_dlc_min := TO_CHAR(r_bor.dlc_min,'DD/MM/YYYY');
        v_qte_dem := r_bor.qte_dem;
    END IF;
    CLOSE c_bor;    

    v_etape := 'Recup INFO UT:' || v_cod_ut || ' ' || v_typ_ut;
    OPEN c_info_ut (r_bor.dlc_min);
    FETCH c_info_ut INTO r_info_ut;
    IF c_info_ut%FOUND THEN
        r_info_val.qte_val:=0;
        -- on tient compte des validation temporaire pour mette a jour la quantit�e propos�e
        OPEN c_info_val(r_bor.dlc_min);
        FETCH c_info_val INTO r_info_val;
        CLOSE c_info_val;
        r_info_ut.prop:=r_info_ut.prop-r_info_val.qte_val;
        IF r_info_ut.prop < r_bor.qte_dem THEN 
            v_qte_prop := r_info_ut.prop;
        ELSE
            v_qte_prop := r_bor.qte_dem;  -- on ne peut pas proposer une quantit� sup�rieure � la qte_dem
        END IF;            
    ELSE
        v_qte_prop := 0;
    END IF;
    CLOSE c_info_ut;
    
    v_qte_prel := NULL;
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');                

END;

/*
****************************************************************************
* pc_bas_aff_uee_pic -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'afficher les informations de des colis � pr�lever
-- dans le cas d'une validation avec etq colis
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,10.03.10,rleb    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_aff_uee_pic IS

    v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_aff_uee_pic';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except          EXCEPTION;
    
    v_ret               VARCHAR2(10);
    
    CURSOR c_info_uee IS
        SELECT    'VALID: '
               || LTRIM (TO_CHAR (v.nb_col_val, '099'))
               || '/'
               || LTRIM (TO_CHAR (v.nb_col_theo, '099')) etat_pic,
               su_bas_gcl_su_pro (cod_pro, 'LIB_PRO_COURT') cod_pro
          FROM v_det_bor_ramasse v
         WHERE v.no_bor_pic = v_bordereau_en_cours
           AND (cod_emp = v_cod_emp_en_cours OR v_cod_emp_en_cours IS NULL)
           AND cod_pro = v_cod_pro_en_cours;

    r_info_uee c_info_uee%ROWTYPE;

BEGIN

    v_etape := 'Rch information colis';

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj ||' '||v_etape);
    END IF;

    OPEN c_info_uee;
    FETCH c_info_uee INTO r_info_uee;
    IF c_info_uee%FOUND THEN
        v_etape:='info uee trouv�es';
        v_lib_pro:=r_info_uee.cod_pro; -- on affiche le produit du 1er colis de la liste
        v_etat_pic:=r_info_uee.etat_pic;
    ELSE
        v_etape:='info uee pas trouv�es';
        v_lib_pro := su_bas_gcl_su_pro(v_cod_pro_en_cours, 'LIB_PRO_COURT'); -- on affiche le produit du 1er colis de la liste
        v_etat_pic:= '?';
    END IF;
    CLOSE c_info_uee;   
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');                         

END;


/*
****************************************************************************
* pc_bas_prevalid_qte_prel -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de prendre en compte les controles avant validation
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,27.06.13,mnev    Controle avant traitement de validation
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_prevalid_qte_prel IS

    v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_prevalid_qte_prel';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except          EXCEPTION;

    CURSOR c_info_bor IS
        SELECT DISTINCT  cod_pss_afc  
          FROM pc_uee_det
         WHERE 
         no_bor_pic = v_bordereau_en_cours;

    r_info_bor   c_info_bor%ROWTYPE;

    v_ret        VARCHAR2(20):=NULL;
    v_nb_prel    NUMBER(5);
    
    v_cod_err            VARCHAR2(100)  := NULL;
    v_msg_err            VARCHAR2(1000) := NULL;
    v_par_1              VARCHAR2(100)  := NULL;
    v_par_2              VARCHAR2(100)  := NULL;
    
BEGIN

    v_etape := 'Debut traitement';

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj ||' '||v_etape);
    END IF;

    v_etape := 'Test qte saisie';
    IF su_bas_is_number(v_qte_prel) IS NULL THEN            
        v_qte_prel := NULL; 
        su_term_pkg.message_box_code('O','TER_RM_002','TER_TITLE-0001');
        
    ELSIF TO_NUMBER(v_qte_prel) = 0 THEN            
        v_qte_prel := NULL; 
        su_term_pkg.message_box_code('O','TER_RM_003','TER_TITLE-0001');
        
    ELSIF TO_NUMBER(v_qte_prel) > v_qte_dem THEN            
        v_qte_prel := NULL; 
        su_term_pkg.message_box_code('O','TER_RM_009','TER_TITLE-0001');
        
    ELSE
        v_nb_prel := TO_NUMBER(v_qte_prel);

        v_etape := 'Rch infos bordereau';
        OPEN c_info_bor;
        FETCH c_info_bor INTO r_info_bor;
        CLOSE c_info_bor;

        v_etape := 'Controle de coherence du stock';
        pc_pn1_verif_stk_coherent (p_retour        => v_cod_err,
                                   p_lib_err       => v_msg_err,
                                   p_par_1         => v_par_1,
                                   p_par_2         => v_par_2, 
                                   p_no_pos        => v_no_pos,
                                   p_no_bor        => v_bordereau_en_cours,
                                   p_cod_pro       => v_cod_pro,
                                   p_cod_va        => v_cod_va, 
                                   p_cod_vl        => v_cod_vl,
                                   p_cod_prk       => v_cod_prk,
                                   p_qte           => v_qte_prel,
                                   p_unit          => 'C',
                                   p_cod_emp       => v_cod_emp_en_cours,
                                   p_cod_ut        => v_cod_ut, 
                                   p_typ_ut        => v_typ_ut, 
                                   p_cod_lot_stk   => v_cod_lot_stk,
                                   p_cod_ss_lot_stk=> v_cod_ss_lot_stk,
                                   p_dat_dlc       => TO_CHAR(v_dat_dlc,'YYYYMMDD'),       
                                   p_dat_stk       => TO_CHAR(v_dat_stk,'YYYYMMDD'));

        IF v_cod_err <> 'OK' THEN
            -- Info op�rateur ... non bloquant ...
            su_term_pkg.message_box_code(p_type    => 'ON',
                                         p_message => v_cod_err, 
                                         p_title   => 'TER_TITLE-0005',
                                         p_on_yes  => 'pc_bas_valid_qte_prel',
                                         p_on_no   => '',
                                         p_par_1   => v_par_1,
                                         p_par_2   => v_par_2);
        ELSE
            pc_bas_valid_qte_prel;
        END IF;

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_lib_ano_2       => 'cod_ut',
                        p_par_ano_2       => v_cod_ut,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');
END;

    
/*
****************************************************************************
* pc_bas_valid_qte_prel -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de prendre en compte la validation de la quantit� pr�lev�e
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03a,27.06.13,mnev    Sortie de la partier controle dans procedure prevalid
-- 02c,17.07.12,alfl    Ne se contente pas de la ligne commande en cours 
--                      (cas de 2 lignes meme produit)
-- 02b,23.04.12,alfl    Demande ou pas de correctin de stock
-- 02a,21.07.11,mnev    Controle si changement d'UT palette pour generer 
--                      les validations
-- 01d,01.04.11,mnev    Deplace maj du record r_last.
-- 01c,10.11.10,mnev    Traite le cas du multi lignes de commandes
--                      ex : regroupement de 2 lignes commandes mm pro mm cli
-- 01b,04.10.09,rbel    Ajout test si PSS accepte UEE de regroupement
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_valid_qte_prel IS

    v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 03a $Revision$';
    v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_valid_qte_prel';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except          EXCEPTION;

    CURSOR c_lst_uee (x_etat_num_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
        SELECT u.no_uee,
               u.no_uee_com, u.no_uee_lig_com,                     
               SUM(d.pds_theo) pds_tot, 
               SUM(d.nb_pce_theo) nb_pce_tot,
               --SUM(p.qte_a_pic - p.qte_pic) qte_tot,
               --p.unite_qte,
               SUM(d.qte_theo - d.qte_val) qte_tot,
               d.unite_qte,
               d.cod_usn, pu.no_com, pu.no_lig_com,
               u.cod_ut_sup, u.typ_ut_sup, u.cod_pss_afc
        FROM pc_pic p, pc_pic_uee pu, pc_uee_det d, pc_uee u --, se_emp s
        WHERE p.no_bor_pic = v_bordereau_en_cours
          /*AND p.cod_emp = s.cod_emp
          AND (p.cod_emp = v_cod_emp_en_cours OR v_cod_emp_en_cours IS NULL OR s.CTG_EMP = 'DEB')*/ -- on ne test plus l'emplacement de picking
          AND p.cod_pro = v_cod_pro_en_cours
          AND p.cod_va = v_cod_va_en_cours
          AND p.cod_vl = v_cod_vl_en_cours
          AND pu.cod_pic = p.cod_pic 
          AND pu.etat_actif = '1'
          AND pu.no_com = v_no_com_en_cours
          --AND pu.no_lig_com = v_no_lig_com_en_cours
          AND pu.no_uee = d.no_uee  AND pu.no_com = d.no_com AND pu.no_lig_com = d.no_lig_com
          AND u.no_uee = pu.no_uee               
          AND p.qte_pic < p.qte_a_pic         -- pic avec un reste � pr�lever
          AND su_bas_etat_val_num(d.etat_atv_pc_uee_det,'PC_UEE_DET') < x_etat_num_uee_det
        GROUP BY u.no_uee, u.no_uee_com, u.cod_ut_sup, u.typ_ut_sup, u.cod_pss_afc, p.cod_emp, u.no_uee_lig_com, 
                 d.cod_usn, pu.no_com, pu.no_lig_com, d.unite_qte
        ORDER BY pu.no_com, pu.no_lig_com,  
                 DECODE(v_cod_emp_en_cours, p.cod_emp, 0, 1), cod_ut_sup, no_uee_com, no_uee_lig_com;
    
    r_lst_uee c_lst_uee%ROWTYPE;    
    r_last    c_lst_uee%ROWTYPE;    
    
    CURSOR c_info_bor IS
        SELECT DISTINCT  cod_pss_afc  
          FROM pc_uee_det
         WHERE 
         no_bor_pic = v_bordereau_en_cours;
    r_info_bor   c_info_bor%ROWTYPE;

    v_ret        VARCHAR2(20):=NULL;
    v_nb_prel    NUMBER(5);
    
    v_nb_uee_pic NUMBER(5);
    i            NUMBER(5);
    
    v_nb_uee_tot         NUMBER(5) := 0;
    v_nb_pce_tot         pc_uee_det.nb_pce_theo%TYPE := 0;
    v_pds_tot            pc_uee_det.pds_theo%TYPE    := 0;
    v_qte_pic            pc_pic.qte_a_pic%TYPE       := 0;
    v_cod_ut_sup         pc_uee.cod_ut_sup%TYPE  := NULL;
    v_cod_pss_afc        pc_uee.cod_pss_afc%TYPE := NULL;
    v_mode_corr          VARCHAR2(5):=NULL;
    v_cfg_mode_tr        VARCHAR2(80);

    v_cod_err            VARCHAR2(100);
    v_msg_err            VARCHAR2(1000) := NULL;
    
    v_accepte_uee_rgp    VARCHAR2(20) := '1';
    
BEGIN

    v_etape := 'Debut traitement';

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj ||' '||v_etape);
    END IF;

    v_nb_prel := TO_NUMBER(v_qte_prel);

    v_etape := 'Rch infos bordereau';
    -- on va cherche le mode de correction
    OPEN c_info_bor;
    FETCH c_info_bor INTO r_info_bor;
    CLOSE c_info_bor;

    v_etape := 'Mode de correction stock';
    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss => r_info_bor.cod_pss_afc,
                                    p_typ_atv => 'PIC',
                                    p_cod_cfg => 'CFG_MODE_OP_TR', 
                                    p_val     => v_cfg_mode_tr);
            
    v_mode_corr := su_bas_rch_action_det(p_nom_par   => 'CFG_MODE_OP_TR', 
                                         p_par       => v_cfg_mode_tr, 
                                         p_no_action => 1);
    
    -- Gestion du nombre de colis pour une correction de stock
    v_etape := 'Calcul nb_col pour correction stock';
    IF v_nb_prel > v_qte_prop THEN
        v_nb_col_ent := v_nb_prel - TO_NUMBER(v_qte_prop);
        
        IF v_mode_corr = '1' THEn -- automatique
            pc_bas_entree_stk;
        ELSIF v_mode_corr='2' THEN
            su_term_pkg.message_box_code(p_type    => 'ON',
                                     p_message => 'TER_RM_005',
                                     p_title   => 'TER_TITLE-0002',
                                     p_on_yes  => 'pc_bas_entree_stk',
                                     p_on_no   => '',
                                     p_par_1   => v_nb_col_ent);
        ELSE
            NULL;
        END IF;
    ELSIF v_nb_prel < v_qte_prop THEN 
        v_nb_col_sor := TO_NUMBER(v_qte_prop) - v_nb_prel;
        IF v_mode_corr = '1' THEn -- automatique
            pc_bas_sortie_stk ;
        ELSIF v_mode_corr = '2' THEN
            su_term_pkg.message_box_code(p_type    => 'ON',
                                     p_message => 'TER_RM_006',
                                     p_title   => 'TER_TITLE-0002',
                                     p_on_yes  => 'pc_bas_sortie_stk',
                                     p_on_no   => '',
                                     p_par_1   => v_nb_col_sor);
        ELSE
            NULL;
        END IF;
    END IF;
    
    -- Gestion du nombre de colis pr�lever pour la pr�paration
    v_etape := 'Calcul nb_uee_pic';
    IF v_nb_prel > v_qte_dem THEN
        v_nb_uee_pic := TO_NUMBER(v_qte_dem);
    ELSE
        v_nb_uee_pic := v_nb_prel;
    END IF;
               
    -- Construction de la liste des colis pr�lev�s
    v_etape := 'Rch liste uee';
    i := v_nb_uee_pic;
    v_lst_uee         := ';';
    r_last.no_com     := NULL;
    r_last.no_lig_com := NULL;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj ||' v_bordereau_en_cours : ' || v_bordereau_en_cours
                         ||' v_cod_emp_en_cours : ' || v_cod_emp_en_cours
                         ||' v_cod_pro_en_cours : ' || v_cod_pro_en_cours
                         ||' v_cod_va_en_cours : ' || v_cod_va_en_cours
                         ||' v_no_com_en_cours : ' || v_no_com_en_cours
                         ||' v_cod_vl_en_cours : ' || v_cod_vl_en_cours);

    END IF;


    OPEN c_lst_uee (su_bas_etat_val_num(su_bas_rch_etat_atv('TEST_FIN_PREPA','PC_UEE_DET'),'PC_UEE_DET'));
    LOOP

        FETCH c_lst_uee INTO r_lst_uee;
        EXIT WHEN c_lst_uee%NOTFOUND;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj ||' Trouve UEE : ' || r_lst_uee.no_uee);
        END IF;

        IF v_cod_pss_afc IS NULL OR r_lst_uee.cod_pss_afc <> v_cod_pss_afc THEN
    
            -- memorise le code process
            v_cod_pss_afc := r_lst_uee.cod_pss_afc;

            v_etape := 'Rch clef process ACCEPTE_UEE_RGP dans pss '|| v_cod_pss_afc;
            v_ret := su_bas_rch_cle_atv_pss(p_cod_pss => v_cod_pss_afc,            
                                            p_typ_atv => 'ORD',
                                            p_cod_cfg => 'ACCEPTE_UEE_RGP',
                                            p_val     => v_accepte_uee_rgp);

        END IF;

        v_cod_ut_sup := r_lst_uee.cod_ut_sup;

        IF v_accepte_uee_rgp = '1' THEN 
            --
            -- validation par paquet
            v_etape := 'validation par paquet';
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj ||' '||v_etape);
            END IF;

            --
            -- si changement ligne commande ou UT on doit 
            -- obligatoirement faire une validation de pr�paration.
            --
            IF r_lst_uee.no_com <> NVL(r_last.no_com,r_lst_uee.no_com) OR 
               r_lst_uee.no_lig_com <> NVL(r_last.no_lig_com,r_lst_uee.no_lig_com) OR
               r_lst_uee.cod_ut_sup <> NVL(r_last.cod_ut_sup,r_lst_uee.cod_ut_sup) THEN

                v_etape := 'Appel validation pr�paration';
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj ||' '||v_etape);
                END IF;

                pc_bas_ramasse_valide_prp( p_ret            => v_ret,
                                           p_lib_err        => v_msg_err,
                                           p_no_pos         => v_no_pos,
                                           p_cod_ope        => v_cod_ope,
                                           p_cod_ut_sup     => r_last.cod_ut_sup,
                                           p_cod_ut_stk     => v_cod_ut,
                                           p_typ_ut_stk     => v_typ_ut,  
                                           p_cod_usn        => r_last.cod_usn,     
                                           p_pds_reel       => v_pds_tot,
                                           p_qte_reel       => v_qte_pic,
                                           p_nb_col_reel    => v_nb_uee_tot,
                                           p_nb_pce_reel    => v_nb_pce_tot,
                                           p_process        => NULL,                 --process pour les colis manquants
                                           p_fin            => 'N',                  --indique si fin de palette
                                           p_unite          => r_last.unite_qte,     --unit� de commande
                                           p_lst_uee        => v_lst_uee,            --liste des uee � regrouper pour la validation
                                           p_no_bor         => v_bordereau_en_cours, --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                           p_no_lig_bor     => NULL,                 --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                           p_cod_pro        => v_cod_pro,
                                           p_cod_va         => v_cod_va,
                                           p_cod_vl         => v_cod_vl,
                                           p_cod_prk        => v_cod_prk,
                                           p_cod_lot_stk    => v_cod_lot_stk,
                                           p_cod_ss_lot_stk => v_cod_ss_lot_stk,
                                           p_dat_dlc        => TO_CHAR(v_dat_dlc,'YYYYMMDD'),
                                           p_dat_stk        => TO_CHAR(v_dat_stk,'YYYYMMDD'),
                                           p_cod_mag        => v_cod_mag,
                                           p_cod_emp        => v_cod_emp_en_cours,
                                           p_car_stk_1      => v_car_stk_1,
                                           p_car_stk_2      => v_car_stk_2,
                                           p_car_stk_3      => v_car_stk_3,
                                           p_car_stk_4      => v_car_stk_4,
                                           p_car_stk_5      => v_car_stk_5,
                                           p_car_stk_6      => v_car_stk_6,
                                           p_car_stk_7      => v_car_stk_7,
                                           p_car_stk_8      => v_car_stk_8,
                                           p_car_stk_9      => v_car_stk_9,
                                           p_car_stk_10     => v_car_stk_10,
                                           p_car_stk_11     => v_car_stk_11,
                                           p_car_stk_12     => v_car_stk_12,
                                           p_car_stk_13     => v_car_stk_13,
                                           p_car_stk_14     => v_car_stk_14,
                                           p_car_stk_15     => v_car_stk_15,
                                           p_car_stk_16     => v_car_stk_16,
                                           p_car_stk_17     => v_car_stk_17,
                                           p_car_stk_18     => v_car_stk_18,
                                           p_car_stk_19     => v_car_stk_19,
                                           p_car_stk_20     => v_car_stk_20,
                                           p_typ_val_pc     =>v_typ_val_pc);

                IF v_ret != 'OK' THEN
                    RAISE err_except;
                END IF;

                v_lst_uee    := ';';
                v_nb_pce_tot := 0;
                v_pds_tot    := 0;
                v_qte_pic    := 0;
                v_nb_uee_tot := 0;

            END IF;

            r_last := r_lst_uee;

            v_lst_uee    := v_lst_uee ||r_lst_uee.no_uee||';';
            v_nb_pce_tot := v_nb_pce_tot + r_lst_uee.nb_pce_tot;
            v_pds_tot    := v_pds_tot + r_lst_uee.pds_tot;
            v_qte_pic    := v_qte_pic + r_lst_uee.qte_tot;  
            v_nb_uee_tot := v_nb_uee_tot + 1;

        ELSE
            --
            -- validation colis par colis
            v_etape := 'validation par colis';
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj ||' '||v_etape);
            END IF;
            v_etape := 'Appel validation pr�paration';
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj ||' '||v_etape);
            END IF;

            pc_bas_ramasse_valide_prp( p_ret            => v_ret,
                                       p_lib_err        => v_msg_err,
                                       p_no_pos         => v_no_pos,
                                       p_cod_ope        => v_cod_ope,
                                       p_cod_ut_sup     => v_cod_ut_sup,
                                       p_cod_ut_stk     => v_cod_ut,
                                       p_typ_ut_stk     => v_typ_ut,  
                                       p_cod_usn        => r_lst_uee.cod_usn,     
                                       p_pds_reel       => r_lst_uee.pds_tot,
                                       p_qte_reel       => r_lst_uee.qte_tot,
                                       p_nb_col_reel    => 1,
                                       p_nb_pce_reel    => r_lst_uee.nb_pce_tot,
                                       p_process        => NULL,                 --process pour les colis manquants
                                       p_fin            => 'N',                  --indique si fin de palette
                                       p_unite          => r_lst_uee.unite_qte,  --unit� de commande
                                       p_lst_uee        => ';' || r_lst_uee.no_uee || ';',            --liste des uee � regrouper pour la validation
                                       p_no_bor         => v_bordereau_en_cours, --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                       p_no_lig_bor     => NULL,                 --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                       p_cod_pro        => v_cod_pro,
                                       p_cod_va         => v_cod_va,
                                       p_cod_vl         => v_cod_vl,
                                       p_cod_prk        => v_cod_prk,
                                       p_cod_lot_stk    => v_cod_lot_stk,
                                       p_cod_ss_lot_stk => v_cod_ss_lot_stk,
                                       p_dat_dlc        => TO_CHAR(v_dat_dlc,'YYYYMMDD'),
                                       p_dat_stk        => TO_CHAR(v_dat_stk,'YYYYMMDD'),
                                       p_cod_mag        => v_cod_mag,
                                       p_cod_emp        => v_cod_emp_en_cours,
                                       p_car_stk_1      => v_car_stk_1,
                                       p_car_stk_2      => v_car_stk_2,
                                       p_car_stk_3      => v_car_stk_3,
                                       p_car_stk_4      => v_car_stk_4,
                                       p_car_stk_5      => v_car_stk_5,
                                       p_car_stk_6      => v_car_stk_6,
                                       p_car_stk_7      => v_car_stk_7,
                                       p_car_stk_8      => v_car_stk_8,
                                       p_car_stk_9      => v_car_stk_9,
                                       p_car_stk_10     => v_car_stk_10,
                                       p_car_stk_11     => v_car_stk_11,
                                       p_car_stk_12     => v_car_stk_12,
                                       p_car_stk_13     => v_car_stk_13,
                                       p_car_stk_14     => v_car_stk_14,
                                       p_car_stk_15     => v_car_stk_15,
                                       p_car_stk_16     => v_car_stk_16,
                                       p_car_stk_17     => v_car_stk_17,
                                       p_car_stk_18     => v_car_stk_18,
                                       p_car_stk_19     => v_car_stk_19,
                                       p_car_stk_20     => v_car_stk_20,
                                       p_typ_val_pc     => v_typ_val_pc);

            IF v_ret != 'OK' THEN
                RAISE err_except;
            END IF;
        
        END IF;
         
        i := i - 1;
        EXIT WHEN i <= 0;

    END LOOP;
    CLOSE c_lst_uee;
    
    IF v_accepte_uee_rgp = '1' AND v_lst_uee <> ';' THEN
        --
        -- si liste constitu�e et non trait�e ...
        v_etape := 'si liste constitu�e et non trait�e';
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj ||' '||v_etape);
        END IF;

        --
        IF su_global_pkv.v_niv_dbg >= 3 THEN
           su_bas_put_debug(v_nom_obj||' : v_cod_ut_sup=' || v_cod_ut_sup || 
                                       ' v_bordereau_en_cours='||v_bordereau_en_cours||
                                       ' lst_uee=' || v_lst_uee ||
                                       ' unite_qte='||r_last.unite_qte ||
                                       ' cod_vl='||v_cod_vl||
                                       ' cod_emp=' || v_cod_emp_en_cours||
                                       ' v_no_stk= '||v_no_stk_en_cours);
        END IF;

        v_etape := 'Appel validation pr�paration';
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj ||' '||v_etape);
        END IF;

        pc_bas_ramasse_valide_prp( p_ret            => v_ret,
                                   p_lib_err        => v_msg_err,
                                   p_no_pos         => v_no_pos,
                                   p_cod_ope        => v_cod_ope,
                                   p_cod_ut_sup     => v_cod_ut_sup,
                                   p_cod_ut_stk     => v_cod_ut,
                                   p_typ_ut_stk     => v_typ_ut,  
                                   p_cod_usn        => r_last.cod_usn,     
                                   p_pds_reel       => v_pds_tot,
                                   p_qte_reel       => v_qte_pic,
                                   p_nb_col_reel    => v_nb_uee_tot,
                                   p_nb_pce_reel    => v_nb_pce_tot,
                                   p_process        => NULL,                 --process pour les colis manquants
                                   p_fin            => 'N',                  --indique si fin de palette
                                   p_unite          => r_last.unite_qte,     --unit� de commande
                                   p_lst_uee        => v_lst_uee,            --liste des uee � regrouper pour la validation
                                   p_no_bor         => v_bordereau_en_cours, --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                   p_no_lig_bor     => NULL,                 --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                   p_cod_pro        => v_cod_pro,
                                   p_cod_va         => v_cod_va,
                                   p_cod_vl         => v_cod_vl,
                                   p_cod_prk        => v_cod_prk,
                                   p_cod_lot_stk    => v_cod_lot_stk,
                                   p_cod_ss_lot_stk => v_cod_ss_lot_stk,
                                   p_dat_dlc        => TO_CHAR(v_dat_dlc,'YYYYMMDD'),
                                   p_dat_stk        => TO_CHAR(v_dat_stk,'YYYYMMDD'),
                                   p_cod_mag        => v_cod_mag,
                                   p_cod_emp        => v_cod_emp_en_cours,
                                   p_car_stk_1      => v_car_stk_1,
                                   p_car_stk_2      => v_car_stk_2,
                                   p_car_stk_3      => v_car_stk_3,
                                   p_car_stk_4      => v_car_stk_4,
                                   p_car_stk_5      => v_car_stk_5,
                                   p_car_stk_6      => v_car_stk_6,
                                   p_car_stk_7      => v_car_stk_7,
                                   p_car_stk_8      => v_car_stk_8,
                                   p_car_stk_9      => v_car_stk_9,
                                   p_car_stk_10     => v_car_stk_10,
                                   p_car_stk_11     => v_car_stk_11,
                                   p_car_stk_12     => v_car_stk_12,
                                   p_car_stk_13     => v_car_stk_13,
                                   p_car_stk_14     => v_car_stk_14,
                                   p_car_stk_15     => v_car_stk_15,
                                   p_car_stk_16     => v_car_stk_16,
                                   p_car_stk_17     => v_car_stk_17,
                                   p_car_stk_18     => v_car_stk_18,
                                   p_car_stk_19     => v_car_stk_19,
                                   p_car_stk_20     => v_car_stk_20,
                                   p_typ_val_pc     => v_typ_val_pc);

        IF v_ret != 'OK' THEN
            RAISE err_except;
        END IF;
    END IF;
    
    COMMIT;

    IF pc_bas_bor_term = 'ENCOURS' THEN            
        -- on raffrachit le curseur et on revient dans la fen�tre liste ligne bordereau 
        -- en attente lecture UT
        su_term_pkg.close_cursor('C_LST_ORD_PIC');
        su_term_pkg.open_cursor('C_LST_ORD_PIC');
        v_cb_pic := NULL;
        su_term_pkg.active_window('W_LST_BOR');
        su_term_pkg.active_item('E_UT_A_PIC');
    ELSE
        -- bordereau enti�rement pr�par�
        --pc_bas_cloture_bor;
        v_sscc_ut := NULL;
        su_term_pkg.active_window('W_SSCC_UT');
        su_term_pkg.active_item('E_SSCC_UT');
        
    END IF;
                    
EXCEPTION
    WHEN OTHERS THEN
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_lib_ano_2       => 'cod_ut',
                        p_par_ano_2       => v_cod_ut,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');
END;


PROCEDURE pc_bas_valid_bor IS
    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_valid_bor';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except       EXCEPTION;

    v_ret VARCHAR2(100);

    CURSOR c_ut_bor IS
    SELECT e.cod_ut_sup, e.typ_ut_sup
    FROM   pc_ut u, pc_uee e, pc_uee_det t
    WHERE  t.no_bor_pic = v_bordereau_en_cours
    AND    t.no_uee     = e.no_uee
    AND    e.cod_ut_sup = u.cod_ut
    AND    e.typ_ut_sup = u.typ_ut
    AND    u.cod_ut_sup IS NULL
    AND    u.typ_ut_sup IS NULL
    UNION ALL
    SELECT u.cod_ut_sup, u.typ_ut_sup
    FROM   pc_ut u, pc_uee e, pc_uee_det t
    WHERE  t.no_bor_pic = v_bordereau_en_cours
    AND    t.no_uee     = e.no_uee
    AND    e.cod_ut_sup = u.cod_ut
    AND    e.typ_ut_sup = u.typ_ut
    AND    u.cod_ut_sup IS NOT NULL
    AND    u.typ_ut_sup IS NOT NULL
        ;

    r_ut_bor c_ut_bor%ROWTYPE;

BEGIN

    su_bas_put_debug(v_nom_obj ||' v_sscc_ut = '||v_sscc_ut);
    v_sscc_ut := LTRIM(v_sscc_ut,'0');
    su_bas_put_debug(v_nom_obj ||' v_sscc_ut = '||v_sscc_ut);

    su_bas_put_debug(v_nom_obj ||' avant cod_ut = '||v_cod_ut_pal ||'/'||v_typ_ut_pal);
    --$MOD YQUE 22/06/2015 init de l'ut sinon garde la pr�c�dente !!!
    v_cod_ut_pal := NULL;
    v_typ_ut_pal := NULL;
    su_bas_put_debug(v_nom_obj ||' RAZ cod_ut = '||v_cod_ut_pal ||'/'||v_typ_ut_pal);

    v_ret := se_bas_rch_ut (p_cb_ut  => v_sscc_ut,
                            p_typ_ut => v_typ_ut_pal,
                            p_cod_ut => v_cod_ut_pal,
                            p_cod_usn_loc => su_global_pkv.v_cod_usn);

    --IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj ||' cod_ut = '||v_cod_ut_pal ||'/'||v_typ_ut_pal);
        su_bas_put_debug(v_nom_obj ||' bor = '||v_bordereau_en_cours);
    --END IF;

    IF v_cod_ut_pal IS NOT NULL THEN

        OPEN c_ut_bor;
        FETCH c_ut_bor INTO r_ut_bor;
        CLOSE c_ut_bor;

        --IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj ||' cod_ut bor = '||r_ut_bor.cod_ut_sup ||'/'||r_ut_bor.typ_ut_sup);
        --END IF;

        IF r_ut_bor.cod_ut_sup = v_cod_ut_pal
            AND r_ut_bor.typ_ut_sup = v_typ_ut_pal THEN

            pc_bas_cloture_bor; 
        ELSE
            v_sscc_ut := NULL;
            su_term_pkg.message_box_code('O','TER_RM_100','TER_TITLE-0001');
        END IF;
    ELSE
        v_sscc_ut := NULL;
        su_term_pkg.message_box_code('O','TER_RM_101','TER_TITLE-0001');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O','TER_ANO-0001','TER_TITLE-0001');
END;

/*
****************************************************************************
* pc_bas_bor_term -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de savoir si le bordereau est termin�
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,25.01.10,rbel    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

    FUNCTION pc_bas_bor_term RETURN VARCHAR2 IS

        v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_bor_term';
        v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
        err_except       EXCEPTION;

        CURSOR c_pic (x_etat_num_uee_det pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
            SELECT 1
            FROM pc_pic p, pc_pic_uee pu, pc_uee_det d
            WHERE p.no_bor_pic = v_bordereau_en_cours
              AND pu.cod_pic = p.cod_pic
              AND pu.etat_actif = '1'
              AND pu.no_uee = d.no_uee  AND pu.no_com = d.no_com AND pu.no_lig_com = d.no_lig_com               
              AND p.qte_pic < p.qte_a_pic         -- pic avec un reste � pr�lever
              AND su_bas_etat_val_num(d.etat_atv_pc_uee_det,'PC_UEE_DET') < x_etat_num_uee_det; -- ligne colis non termin�
              
        r_pic         c_pic%ROWTYPE;
        v_found_pic   BOOLEAN;

    BEGIN
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj);
        END IF;

    
        --Controle si reste du travail sur ce pic
        v_etape := 'Rch pic';
        OPEN c_pic (su_bas_etat_val_num(su_bas_rch_etat_atv('TEST_FIN_PREPA','PC_UEE_DET'),'PC_UEE_DET'));
        FETCH c_pic INTO r_pic;
        v_found_pic := c_pic%FOUND;
        CLOSE c_pic;

        IF v_found_pic THEN            
            RETURN 'ENCOURS';
        ELSE
            RETURN 'TERMINE';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'No BOR',
                            p_par_ano_1       => v_bordereau_en_cours,
                            p_lib_ano_2       => 'cod_ut',
                            p_par_ano_2       => v_cod_ut,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
            su_term_pkg.message_box_code('O','TER_ANO-0001','TER_TITLE-0001');
            RETURN 'TERMINE';
            

    END;

/*
****************************************************************************
* pc_bas_entree_stk-
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de gerer le flux du stk en entree lorsque 
-- qte_prel > qte_dem 
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,28.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON
    PROCEDURE pc_bas_entree_stk IS

        v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_entree_stk';
        v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
        err_except          EXCEPTION;
        
        CURSOR c_pro IS
            SELECT *
            FROM se_stk
            WHERE (cod_ut = v_cod_ut
              AND typ_ut = v_typ_ut) OR no_stk=v_no_stk_en_cours; --dans le cas ou l'on ne travail pas en UT
            
        r_pro c_pro%ROWTYPE;
        v_found_pro BOOLEAN;

        v_ret           VARCHAR2(10);
        v_qte_a_entrer  se_stk.qte_unit_1%TYPE;
    BEGIN
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj);
        END IF;

        SAVEPOINT my_pc_bas_entree_stk;
        v_etape := 'Entr�e stock';
        OPEN c_pro;
        FETCH c_pro INTO r_pro;
        v_found_pro := c_pro%FOUND;
        CLOSE c_pro;
        
        IF v_found_pro THEN
            v_etape := 'Appel fonction entree stock'||' ; COD UT : '||v_cod_ut||' ; TYP UT : '||v_typ_ut;
            v_qte_a_entrer := su_bas_conv_unite_to_one_sel(p_cod_pro    => r_pro.cod_pro,
                                                           p_cod_vl     => r_pro.cod_vl,
                                                           p_qte_orig   => v_nb_col_ent,
                                                           p_unite_orig => 'C',
                                                           p_unite_dest => r_pro.unit_stk_1);
            
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                 su_bas_put_debug(v_nom_obj ||' : p_cod_pro = '|| r_pro.cod_pro
                                            ||' / p_cod_vl = '|| r_pro.cod_vl
                                            ||' / p_qte_orig = '|| v_nb_col_ent
                                            ||' / p_qte_unit_1 '|| TO_CHAR(v_qte_a_entrer));
            END IF;

            v_ret :=  se_stk_pkg.se_bas_stk_in (p_typ_mvt     => 'ESIMP',
                                                p_mode_ent    => 'STD',
                                                p_cod_pro     => r_pro.cod_pro,
                                                p_cod_vl      => r_pro.cod_vl,
                                                p_cod_va      => r_pro.cod_va,
                                                p_cod_prk     => r_pro.cod_prk,
                                                p_cod_emp     => r_pro.cod_emp,
                                                p_qte_unit_1  => v_qte_a_entrer,
                                                p_unit_stk_1  => r_pro.unit_stk_1,
                                                p_typ_stk     => r_pro.typ_stk,
                                                p_cod_lot_stk => r_pro.cod_lot_stk,
                                                p_dat_dlc     => r_pro.dat_dlc,
                                                p_dat_stk     => r_pro.dat_stk,
                                                p_cod_ut      => v_cod_ut,
                                                p_typ_ut      => v_typ_ut);
            IF v_ret != 'OK' THEN                    
                RAISE err_except;
            END IF;
            
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO my_pc_bas_entree_stk;
                            
            Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'No BOR',
                            p_par_ano_1       => v_bordereau_en_cours,
                            p_lib_ano_2       => 'UT',
                            p_par_ano_2       => v_typ_ut||'.'||v_cod_ut,
                            p_lib_ano_3       => 'NO_STK',
                            p_par_ano_3       => v_no_stk_en_cours,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
            su_term_pkg.message_box_code('O','TER_ANO_0054','TER_TITLE-0001');
    END;

/*
****************************************************************************
* pc_bas_sortie_stk-
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de gerer le flux du stk en sortie lorsque 
-- qte_prel < qte_dem 
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,28.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON
PROCEDURE pc_bas_sortie_stk IS

        v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_sortie_stk';
        v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
        err_except          EXCEPTION;

        CURSOR c_pro IS
            SELECT *
            FROM se_stk
            WHERE (cod_ut = v_cod_ut
              AND typ_ut = v_typ_ut) OR no_stk=v_no_stk_en_cours; --dans le cas ou l'on ne travail pas en UT
            
        r_pro c_pro%ROWTYPE;
        v_found_pro BOOLEAN;

        v_ret           VARCHAR2(10);
        v_qte_a_sortir  se_stk.qte_unit_1%TYPE;
BEGIN
         v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj);
        END IF;

        SAVEPOINT my_pc_bas_sortie_stk;
        v_etape := 'Sortie stock';
        OPEN c_pro;
        FETCH c_pro INTO r_pro;
        v_found_pro := c_pro%FOUND;
        CLOSE c_pro;
        
        IF v_found_pro THEN
            v_etape := 'Appel fonction sortie stock'||' ; COD UT : '||v_cod_ut||' ; TYP UT : '||v_typ_ut;
            v_qte_a_sortir := su_bas_conv_unite_to_one_sel(p_cod_pro    => r_pro.cod_pro,
                                                           p_cod_vl     => r_pro.cod_vl,
                                                           p_qte_orig   => v_nb_col_sor,
                                                           p_unite_orig => 'C',
                                                           p_unite_dest => r_pro.unit_stk_1);

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                 su_bas_put_debug(v_nom_obj ||' : p_cod_pro = ' || r_pro.cod_pro
                                            ||' / p_cod_vl = '|| r_pro.cod_vl
                                            ||' / p_qte_orig = '|| v_nb_col_sor
                                            ||' / p_unite_dest = '|| r_pro.unit_stk_1
                                            || ' / p_qte_unit_1 ' || TO_CHAR(v_qte_a_sortir));
            END IF;

            v_ret :=  se_stk_pkg.se_bas_stk_out( p_typ_mvt     => 'SSIMP',
                                                 p_mode_sor    => 'STD',
                                                 p_cod_pro     => r_pro.cod_pro,
                                                 p_cod_vl      => r_pro.cod_vl,
                                                 p_cod_va      => r_pro.cod_va,
                                                 p_cod_prk     => r_pro.cod_prk,
                                                 p_cod_emp     => r_pro.cod_emp,
                                                 p_qte_unit_1  => v_qte_a_sortir,
                                                 p_unit_stk_1  => r_pro.unit_stk_1,
                                                 p_typ_stk     => r_pro.typ_stk,
                                                 p_cod_lot_stk => r_pro.cod_lot_stk,
                                                 p_dat_dlc     => r_pro.dat_dlc,
                                                 p_dat_stk     => r_pro.dat_stk,
                                                 p_cod_ut      => v_cod_ut,
                                                 p_typ_ut      => v_typ_ut);
            IF v_ret != 'OK' THEN                    
                RAISE err_except;
            END IF;
            
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO my_pc_bas_sortie_stk;
                            
            Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'No BOR',
                            p_par_ano_1       => v_bordereau_en_cours,
                            p_lib_ano_2       => 'UT',
                            p_par_ano_2       => v_typ_ut||'.'||v_cod_ut,
                            p_lib_ano_3       => 'NO_STK',
                            p_par_ano_3       => v_no_stk_en_cours,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
            su_term_pkg.message_box_code('O','TER_ANO_0055','TER_TITLE-0001');
    END;

/*
****************************************************************************
* pc_bas_desaff_bor -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de d�saffecter un ou les bordereaux du poste
--
-- PARAMETRES :
-- ------------
--  NO_BOR pour d�saffecter un bordereau
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,19.01.10,rbel    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI
PROCEDURE pc_bas_desaff_bor (p_no_bor_pic  pc_pic.no_bor_pic%TYPE DEFAULT NULL) IS

        v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_desaff_bor';
        v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
        err_except          EXCEPTION;

        v_ret          VARCHAR2(10);
        
        CURSOR c_bor (x_etat_uee_det pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
            SELECT DISTINCT p.no_bor_pic 
            FROM pc_pic p, pc_pic_uee pu, pc_uee_det d 
            WHERE p.cod_pic = pu.cod_pic
              AND pu.etat_actif = '1'
              AND pu.no_uee = d.no_uee  AND pu.no_com = d.no_com AND pu.no_lig_com = d.no_lig_com
              AND d.no_pos = v_no_pos
              AND ( su_bas_etat_val_num (d.etat_atv_pc_uee_det,'PC_UEE_DET') < x_etat_uee_det);
              
        v_no_bor   pc_pic.no_bor_pic%TYPE;
        
    BEGIN
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj);
        END IF;

    
        IF p_no_bor_pic IS NOT NULL THEN
            v_etape := 'D�saffectation bordereau '|| p_no_bor_pic;
            v_ret := pc_bas_aff_bor_pos( p_no_pos     => v_no_pos,
                                         p_no_bor     => p_no_bor_pic,
                                         p_no_lig_bor => NULL,
                                         p_mode       => 'D'
                                       );
            IF v_ret != 'OK' THEN
                RAISE err_except;
            END IF;
        ELSE
            v_etape := 'Boucle sur les bordereaux';
            FOR r_bor IN c_bor (su_bas_etat_val_num ('TEST_FIN_PREPA','PC_UEE_DET')) LOOP
                
                v_no_bor := r_bor.no_bor_pic;
                
                v_etape := 'D�saffectation bordereau '|| v_no_bor;
                v_ret := pc_bas_aff_bor_pos( p_no_pos     => v_no_pos,
                                             p_no_bor     => v_no_bor,
                                             p_no_lig_bor => NULL,
                                             p_mode       => 'D'
                                           );
                IF v_ret != 'OK' THEN
                    RAISE err_except;
                END IF;
            END LOOP;
        
        END IF;
        
        COMMIT;       

    EXCEPTION
        WHEN OTHERS THEN
            Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'No BOR',
                            p_par_ano_1       => NVL(v_no_bor, p_no_bor_pic),
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
            su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');
    END;


/*
****************************************************************************
* pc_bas_valid_uee
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de valider un colis dans le cas d'une validation
-- avec etiquette colis
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,08.03.10,rleb    Version initiale
-- 00a,08.03.10,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_valid_uee IS
      
    v_version           SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_valid_uee';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except          EXCEPTION;
    
    v_ldoc              su_ldoc.cod_ldoc%TYPE;
    v_ctx               su_ctx_pkg.tt_ctx;
    v_cod_pn1_jal_trait NUMBER;
    v_lst_param_ldoc    VARCHAR2(100);
    v_ret               VARCHAR2(20):=NULL;
    v_cod_ut_sup        pc_uee.cod_ut_sup%TYPE;
    v_found_pic         BOOLEAN;
    
    --R�cup�re la liste des UEE susceptibles d'�tre � pr�lever sur ce bordereau
    CURSOR c_lst_uee (x_etat_num_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
    SELECT d.no_uee, d.pds_theo, d.nb_pce_theo, d.qte_theo,
           d.unite_qte, d.cod_usn, pu.no_com, pu.no_lig_com,
           d.cod_pss_afc 
      FROM pc_pic p, pc_pic_uee pu, pc_uee_det d, pc_uee u
      WHERE p.no_bor_pic = v_bordereau_en_cours
        AND p.cod_pro = v_cod_pro_en_cours
        AND p.cod_va = v_cod_va_en_cours
        AND p.cod_vl = v_cod_vl_en_cours
        AND u.cb_complet = v_cb_uee
        AND u.no_uee = d.no_uee
        AND p.cod_pic = pu.cod_pic
        AND pu.etat_actif = '1'
        AND pu.no_uee = d.no_uee  AND pu.no_com = d.no_com AND pu.no_lig_com = d.no_lig_com               
        AND p.qte_pic < p.qte_a_pic         -- pic avec un reste � pr�lever
        AND su_bas_etat_val_num(d.etat_atv_pc_uee_det,'PC_UEE_DET') < x_etat_num_uee_det;

    r_lst_uee c_lst_uee%ROWTYPE;
      
    --Curseur pour savoir s'il reste des UEE � pr�lever sur l'emplacement
    CURSOR c_reste_uee_prel IS
    SELECT DISTINCT 1
      FROM pc_pic 
     WHERE no_bor_pic = v_bordereau_en_cours
       AND (cod_emp=v_cod_emp_en_cours OR v_cod_emp_en_cours IS NULL)
       AND cod_pro = v_cod_pro_en_cours
       AND cod_va = v_cod_va_en_cours
       AND cod_vl = v_cod_vl_en_cours
       AND qte_pic < qte_a_pic;  
      
    r_reste_uee_prel c_reste_uee_prel%ROWTYPE;
    
    CURSOR c_ut_sup IS
    SELECT DISTINCT cod_ut_sup  
      FROM pc_uee u, pc_uee_det ud 
     WHERE u.no_uee = ud.no_uee 
       AND ud.no_bor_pic = v_bordereau_en_cours;

    v_msg_err   VARCHAR2(1000) := NULL;
    
BEGIN

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj);
    END IF;

    -- V�rifie si le cb_complet de l'uee est affect� a ce bordereau
    OPEN c_lst_uee (su_bas_etat_val_num(su_bas_rch_etat_atv('TEST_FIN_PREPA','PC_UEE_DET'),'PC_UEE_DET'));
    FETCH c_lst_uee INTO r_lst_uee;
    IF c_lst_uee%FOUND THEN

        --r�cup�re la palette
        v_etape := ' Rch palette exp�dition pour bor ' || v_bordereau_en_cours;
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape);
        END IF;

        OPEN c_ut_sup;
        FETCH c_ut_sup INTO v_cod_ut_sup;
        IF c_ut_sup%NOTFOUND THEN
            RAISE err_except;
        END IF;
        CLOSE c_ut_sup;
       
        v_lst_uee :=';'||r_lst_uee.no_uee||';';
       
        v_etape := ' Appel validation pr�paration';
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape);
        END IF;

        pc_bas_ramasse_valide_prp( p_ret            => v_ret,
                                   p_lib_err        => v_msg_err,
                                   p_no_pos         => v_no_pos,
                                   p_cod_ope        => v_cod_ope,
                                   p_cod_ut_sup     => v_cod_ut_sup,
                                   p_cod_ut_stk     => v_cod_ut,
                                   p_typ_ut_stk     => v_typ_ut,  
                                   p_cod_usn        => r_lst_uee.cod_usn,     
                                   p_pds_reel       => r_lst_uee.pds_theo,
                                   p_qte_reel       => r_lst_uee.qte_theo,
                                   p_nb_col_reel    => '1',
                                   p_nb_pce_reel    => r_lst_uee.nb_pce_theo,
                                   p_process        => NULL,         --process pour les colis manquants
                                   p_fin            => 'N',                  --indique si fin de palette
                                   p_unite          => r_lst_uee.unite_qte,  --unit� de commande
                                   p_lst_uee        => v_lst_uee,            --liste des uee � regrouper pour la validation
                                   p_no_bor         => v_bordereau_en_cours, --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                   p_no_lig_bor     => NULL,                 --dans le cas ou l'uee est sur plusieurs ligne de commandes...est-ce possible?
                                   p_cod_pro        => v_cod_pro,
                                   p_cod_va         => v_cod_va,
                                   p_cod_vl         => v_cod_vl,
                                   p_cod_prk        => v_cod_prk,
                                   p_cod_lot_stk    => v_cod_lot_stk,
                                   p_cod_ss_lot_stk => v_cod_ss_lot_stk,
                                   p_dat_dlc        => TO_CHAR(v_dat_dlc,'YYYYMMDD'),
                                   p_dat_stk        => TO_CHAR(v_dat_stk,'YYYYMMDD'),
                                   p_cod_mag        => v_cod_mag,
                                   p_cod_emp        => v_cod_emp_en_cours,
                                   p_car_stk_1      => v_car_stk_1,
                                   p_car_stk_2      => v_car_stk_2,
                                   p_car_stk_3      => v_car_stk_3,
                                   p_car_stk_4      => v_car_stk_4,
                                   p_car_stk_5      => v_car_stk_5,
                                   p_car_stk_6      => v_car_stk_6,
                                   p_car_stk_7      => v_car_stk_7,
                                   p_car_stk_8      => v_car_stk_8,
                                   p_car_stk_9      => v_car_stk_9,
                                   p_car_stk_10     => v_car_stk_10,
                                   p_car_stk_11     => v_car_stk_11,
                                   p_car_stk_12     => v_car_stk_12,
                                   p_car_stk_13     => v_car_stk_13,
                                   p_car_stk_14     => v_car_stk_14,
                                   p_car_stk_15     => v_car_stk_15,
                                   p_car_stk_16     => v_car_stk_16,
                                   p_car_stk_17     => v_car_stk_17,
                                   p_car_stk_18     => v_car_stk_18,
                                   p_car_stk_19     => v_car_stk_19,
                                   p_car_stk_20     => v_car_stk_20,
                                   p_typ_val_pc     => v_typ_val_pc);

        IF v_ret != 'OK' THEN
            RAISE err_except;
        END IF;
        
        COMMIT;
        
        pc_bas_aff_uee_pic; --permet de raffraichir les infos
        
    ELSE
       v_etape := 'colis inconnu ou deja pr�lev�';
       su_term_pkg.message_box_code('O','TER_RM_001','TER_TITLE-0002');
    END IF;
    CLOSE c_lst_uee;


    IF pc_bas_bor_term = 'ENCOURS' THEN            
        v_etape := ' Rch si reste uee � prel';
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape);
        END IF;

        OPEN c_reste_uee_prel;
        FETCH c_reste_uee_prel INTO r_reste_uee_prel;
        v_found_pic := c_reste_uee_prel%FOUND;
        IF  v_found_pic THEN  
            --Il reste des UEE � prelever 
            su_term_pkg.close_cursor('C_LST_UEE_PIC');
            su_term_pkg.open_cursor('C_LST_UEE_PIC');
            v_cb_uee := NULL;
            su_term_pkg.active_window('W_AFF_UEE_PIC');
            su_term_pkg.active_item('E_CB_UEE');
         ELSE
             --Tous les UEE de la liste sont termin�s
             su_term_pkg.close_cursor('C_LST_ORD_PIC');
             su_term_pkg.open_cursor('C_LST_ORD_PIC');
             v_cb_uee := NULL;
             su_term_pkg.active_window('W_LST_BOR');
             su_term_pkg.active_item('E_UT_A_PIC');
         END IF;
        CLOSE c_reste_uee_prel;
        
    ELSE
        -- bordereau enti�rement pr�par�
        pc_bas_cloture_bor;
                        
    END IF;  
    
EXCEPTION
  WHEN OTHERS THEN
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'poste',
                        p_par_ano_1       => v_no_pos,
                        p_lib_ano_2       => 'bor',
                        p_par_ano_2       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O',v_cod_err_su_ano,'TER_TITLE-0001');
END;


/*
****************************************************************************
* pc_bas_cloture_bor
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de cloturer le bordereau
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,27.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_cloture_bor IS

    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_cloture_bor';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except       EXCEPTION;

    v_ret            VARCHAR2(30);
    v_msg_err        VARCHAR2(1000) := NULL;

    CURSOR c_ut IS
    SELECT SUM(u.nb_col_val) nb
    FROM   pc_uee u, pc_uee_det e
    WHERE  e.no_bor_pic = v_bordereau_en_cours
    AND    e.etat_atv_pc_uee_det != 'PRP0'
    AND    e.no_uee = u.no_uee;
    
    r_ut c_ut%ROWTYPE; 

BEGIN

    SAVEPOINT pc_bas_cloture_bor; 

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj);
    END IF;
    
    v_etape := ' Appel fin bordereau';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj|| v_etape);
    END IF;

    OPEN c_ut;
    FETCH c_ut INTO r_ut;
    CLOSE c_ut;

    -- suivi des performances
    sp_bas_ins_disout_utac  ( p_cod_ope  => v_cod_ope,
                              p_no_tache => '006',
                              p_no_cmd   => v_no_cmd_en_cours,
                              p_statut   => 'F',
                              p_date     => SYSDATE,
                              p_qte      => r_ut.nb         
                              );

    pc_bas_ramasse_valide_prp( p_ret         => v_ret,
                               p_lib_err     => v_msg_err,
                               p_no_pos      => v_no_pos,
                               p_cod_ope     => v_cod_ope,
                               p_cod_ut_sup   => NULL,
                               p_cod_usn     => NULL,     
                               p_pds_reel    => NULL,
                               p_qte_reel    => NULL,
                               p_nb_col_reel => NULL,
                               p_nb_pce_reel => NULL,
                               p_process     => NULL,
                               p_fin         => 'O',     -- fin de bordereau             
                               p_no_bor      => v_bordereau_en_cours, 
                               p_cod_pro     => NULL,
                               p_cod_va      => NULL,
                               p_cod_vl      => NULL);

    IF v_ret != 'OK' THEN
        v_cod_err_su_ano := 'TER_RM_015';
        RAISE err_except;
    END IF;
         
    COMMIT;
    
    su_term_pkg.active_window('W_TRF_OK');
    v_init_val := TRUE;
    su_term_pkg.create_timer(p_timer_name => 'TIMER_FEN',
                             p_timer_proc => 'su_bas_init',
                             p_freq       => 2,
                             p_repeat     => FALSE
                            );
    

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO pc_bas_cloture_bor;
                        
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O', v_cod_err_su_ano, 'TER_TITLE-0001');
    
    END;
/*
****************************************************************************
* pc_bas_recommence_bor
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'annuler les traitements du bordereau pour le recommencer
-- seulement dans le cas de validation temporaire
-- 
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01b,20.03.14,rbel   gestion des pc_pic
-- 01a,25.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_recommence_bor IS

    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_recommence_bor';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except       EXCEPTION;

    v_ret           VARCHAR2(30);
    v_etat_pic      VARCHAR2(30):= su_bas_rch_etat_atv('ATTENTE_LANCEMENT_N1','PC_PIC');

    v_point         VARCHAR2(10) := 'OUI';
        
BEGIN

    SAVEPOINT pc_bas_recommence_bor; 

    v_etape:=' debut traitement bor= '||v_bordereau_en_cours|| ' pos = '||v_no_pos;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||v_etape);
    END IF;

    
    
    IF v_typ_val_pc='T' THEN 
        -- seulement possible dans le cas des validations temporaires
        -- on efface les validations temporaires
        DELETE PC_VAL_PC WHERE no_pos=v_no_pos AND typ_val_pc='T'
                        AND no_uee IN (SELECt DISTINCT no_uee from PC_UEE_DET WHERE no_bor_pic=v_bordereau_en_cours); 
        
        -- on remet a jour les pic
        UPDATE PC_PIC 
           SET qte_pic=0,
               etat_atv_pc_pic=v_etat_pic
         WHERE no_bor_pic= v_bordereau_en_cours 
           AND su_bas_etat_val_num(etat_atv_pc_pic,'PC_PIC') < su_bas_etat_val_num('PIC_TERM','PC_PIC');               
        
        -- on doit eclater tous les uee regroup�s
        v_etape:='eclate UEE';
        FOR r_uee IN (SELECT distinct(U.no_uee) FROM  PC_UEE U,PC_UEE_DET D
                        WHERE u.no_uee=d.no_uee AND d.no_bor_pic=v_bordereau_en_cours
                        AND U.nb_col_theo>1 AND  cod_err_pc_uee IS NULL
                        AND su_bas_etat_val_num(d.etat_atv_pc_uee_det,'PC_UEE_DET') < su_bas_etat_val_num('TEST_FIN_PREPA','PC_UEE_DET'))
        LOOP
            v_ret:=pc_bas_eclate_uee(p_no_uee=>r_uee.no_uee,p_avec_pic=>'OUI');  -- gestion du v_ret
        END LOOP;        
        
        COMMIT;
        v_point := 'NON';

    END IF;

    v_bordereau_en_cours := NULL;
    v_cb_bor_pic_lu := NULL;
    su_term_pkg.active_window('W_ATT_BOR');

EXCEPTION
    WHEN OTHERS THEN
        IF v_point = 'OUI' THEN
            ROLLBACK TO pc_bas_recommence_bor;
        END IF;
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O', v_cod_err_su_ano, 'TER_TITLE-0001');
    
END;    
/*
****************************************************************************
* pc_bas_retour
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de quitter un bordereau
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,25.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_retour IS

        v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_retour';
        v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
        err_except       EXCEPTION;

        v_ret           VARCHAR2(30);
        
        
                
BEGIN
    v_etape:=' debut retour bor= '||v_bordereau_en_cours|| ' pos = '||v_no_pos;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||v_etape);
    END IF;

    v_bordereau_en_cours := NULL;
    v_cb_bor_pic_lu := NULL;
    su_term_pkg.active_window('W_ATT_BOR');
    
END;    

/*
****************************************************************************
* pc_bas_conf_abandon
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de confirmer l'abandon bordereau
-- il ne sera plus traitable
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,25.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_conf_abandon IS

        v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_conf_abandon';
        v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
        err_except       EXCEPTION;
                
BEGIN
       
    su_term_pkg.message_box_code(p_type    => 'ON',
                                         p_message => 'TER_RM_030',
                                         p_title   => 'TER_TITLE-0002',
                                         p_on_yes  => 'pc_bas_abandonne_bor',
                                         p_on_no   => 'pc_bas_retour');
END;    

/*
****************************************************************************
* pc_bas_conf_recom
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de confirmer le recommencement d'un bordereau
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,25.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_conf_recom IS

        v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_conf_recom';
        v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
        err_except       EXCEPTION;

BEGIN
       
    su_term_pkg.message_box_code(p_type    => 'ON',
                                         p_message => 'TER_RM_031',
                                         p_title   => 'TER_TITLE-0002',
                                         p_on_yes  => 'pc_bas_recommence_bor',
                                         p_on_no   => 'pc_bas_retour');
END;    
      
/*
****************************************************************************
* pc_bas_abandonne_bor
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'abandonner un bordereau
-- il ne sera plus traitable
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,25.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_abandonne_bor IS

    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_abandonne_bor';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except       EXCEPTION;

    v_ret           VARCHAR2(30);
    v_etat_pic      VARCHAR2(30):= su_bas_rch_etat_atv('ATTENTE_LANCEMENT_N1','PC_PIC');
    
    CURSOR c_val IS
    SELECT no_val_pc 
        FROM pc_val_pc 
        WHERE no_pos=v_no_pos AND typ_val_pc='T' AND 
              no_uee IN (SELECT DISTINCT no_uee FROM pc_uee_det WHERE no_bor_pic=v_bordereau_en_cours); 

    r_val           c_val%ROWTYPE;
        
    v_point         VARCHAR2(10) := 'OUI';

BEGIN

    SAVEPOINT pc_bas_abandonne_bor; 

    v_etape:=' debut abandonne bor= '||v_bordereau_en_cours|| ' pos = '||v_no_pos;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||v_etape);
    END IF;

    -- on met les pic en erreur pour ne plus les selectionner
    UPDATE PC_PIC SET cod_err_pc_pic='ABAN'
    WHERE no_bor_pic= v_bordereau_en_cours AND qte_pic=0
    AND etat_atv_pc_pic=v_etat_pic;
    
    COMMIT;
    v_point := 'NON';
   
    -- si on trouve des validations temporaire on demande si on les valide
    OPEN c_val;
    FETCH c_val INTO r_val;
    IF c_val%FOUND THEN
        -- on demande si on valide les pc_val_pc temporaires
        su_term_pkg.message_box_code(p_type    => 'ON',
                                     p_message => 'TER_RM_029',
                                     p_title   => 'TER_TITLE-0002',
                                     p_on_yes  => 'pc_bas_val_tmp',
                                     p_on_no   => 'pc_bas_del_tmp');
    
    ELSE
        v_bordereau_en_cours := NULL;
        v_cb_bor_pic_lu := NULL;
        su_term_pkg.active_window('W_ATT_BOR');
    END IF;
    CLOSE c_val;
    
EXCEPTION
    WHEN OTHERS THEN
        IF v_point = 'OUI' THEN
            ROLLBACK TO pc_bas_abandonne_bor; 
        END IF;
        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_bor',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        su_term_pkg.message_box_code('O', v_cod_err_su_ano, 'TER_TITLE-0001');
    
END;    
             
/****************************************************************************
* pc_bas_val_tmp
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de valider les validations temporaires
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01b,20.03.14,rbel   gestion des pc_pic
-- 01a,25.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--  OUI

PROCEDURE pc_bas_val_tmp IS

    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_val_tmp';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except       EXCEPTION;

    v_ret           VARCHAR2(30);
    
    v_etat_pic          VARCHAR2(30):= su_bas_rch_etat_atv('ATTENTE_LANCEMENT_N1','PC_PIC');
    
    CURSOR c_val IS
        SELECT no_val_pc, no_uee, cod_pro, cod_va, cod_vl, qte_val, unite_qte, cod_pss_afc
        FROM pc_val_pc 
        WHERE no_pos=v_no_pos AND typ_val_pc='T' AND 
              no_uee IN (SELECT DISTINCT no_uee from PC_UEE_DET WHERE no_bor_pic=v_bordereau_en_cours); 

    r_val           c_val%ROWTYPE;

    v_point         VARCHAR2(10) := 'OUI';
                         
BEGIN

    SAVEPOINT pc_bas_val_tmp; 

    v_etape:=' debut  '||v_bordereau_en_cours|| ' pos = '||v_no_pos;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||v_etape);
    END IF;

    
    FOR r_val IN c_val 
    LOOP
        v_etape := 'Init picking uee:'||r_val.no_uee;
        -- on r�-initiailise les picking pour pouvoir faire ensuite la validation normale des ops (sortie de stock, gestion r�assor, mise � jour sp�cial ... fait dans la validation des ops)
        UPDATE PC_PIC 
           SET qte_pic = 0,
               etat_atv_pc_pic = v_etat_pic
         WHERE cod_pic IN (SELECT cod_pic FROM pc_pic_uee WHERE no_uee = r_val.no_uee AND etat_actif = '1');
             
        v_etape := 'Validation picking uee:'||r_val.no_uee;
        v_ret := pc_bas_val_ret_ops  (p_cod_pss_afc => r_val.cod_pss_afc,
                                      p_no_uee      => r_val.no_uee,
                                      p_cod_pro     => r_val.cod_pro,
                                      p_cod_vl      => r_val.cod_vl,
                                      p_qte_val     => r_val.qte_val,
                                      p_unite_qte   => r_val.unite_qte);
            
        UPDATE pc_val_pc 
           SET typ_val_pc='C' 
         WHERE no_val_pc= r_val.no_val_pc;
        
        v_ret := pc_valprepa_pkg.pc_bas_trt_val_pc  (p_no_val_pc=>r_val.no_val_pc);   
    END LOOP;        
   
    COMMIT;
    v_point := 'NON';

    v_bordereau_en_cours := NULL;
    v_cb_bor_pic_lu := NULL;
    su_term_pkg.active_window('W_ATT_BOR');

EXCEPTION
    WHEN OTHERS THEN
        IF v_point = 'OUI' THEN
            ROLLBACK TO pc_bas_val_temp;
        END IF;

        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        su_term_pkg.message_box_code('O', v_cod_err_su_ano, 'TER_TITLE-0001');
    
END;    

/****************************************************************************
* pc_bas_del_tmp
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction delete les validations temporaires
--
-- PARAMETRES :
-- ------------
--  Aucun
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01b,20.03.14,rbel    gestion des pc_pic en appelant fonction recommence bordereau
-- 01a,25.04.12,alfl    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
--   OUI

PROCEDURE pc_bas_del_tmp IS

    v_version        SU_ANO_HIS.VERSION%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj        SU_ANO_HIS.nom_obj%TYPE := 'pc_bas_del_tmp';
    v_etape          SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano SU_ANO_HIS.cod_err_su_ano%TYPE := 'TER_ANO-0000';
    err_except       EXCEPTION;

    v_ret           VARCHAR2(30);
    v_etat_pic      VARCHAR2(30):= su_bas_rch_etat_atv('ATTENTE_LANCEMENT_N1','PC_PIC');
    
    --CURSOR c_val IS
    --SELECT no_val_pc 
    --    FROM pc_val_pc 
    --    WHERE no_pos=v_no_pos AND typ_val_pc='T' AND 
    --          no_uee IN (SELECt DISTINCT no_uee from PC_UEE_DET WHERE no_bor_pic=v_bordereau_en_cours); 

    --r_val           c_val%ROWTYPE;
    v_point         VARCHAR2(10) := 'OUI';
        
BEGIN

    SAVEPOINT pc_bas_del_tmp; 

    v_etape:=' debut  '||v_bordereau_en_cours|| ' pos = '||v_no_pos;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||v_etape);
    END IF;

    --DELETE PC_VAL_PC
    --WHERE  no_pos=v_no_pos AND typ_val_pc='T'
    --         AND no_uee IN (SELECt DISTINCT no_uee from PC_UEE_DET WHERE no_bor_pic=v_bordereau_en_cours);
             
    --COMMIT;
    
    -- on met tous les pic non valid�s en pr�paration du bordereau en erreur pour ne plus les selectionner
    UPDATE PC_PIC 
       SET cod_err_pc_pic='ABAN'
     WHERE no_bor_pic = v_bordereau_en_cours 
       AND su_bas_etat_val_num(etat_atv_pc_pic,'PC_PIC') < su_bas_etat_val_num('PIC_TERM','PC_PIC');
           
    v_etape := 'Recommence bor';
    pc_bas_recommence_bor;    
    
    v_point := 'NON';

    v_bordereau_en_cours := NULL;
    v_cb_bor_pic_lu      := NULL;
    su_term_pkg.active_window('W_ATT_BOR');

EXCEPTION
    WHEN OTHERS THEN
        IF v_point = 'OUI' THEN
            ROLLBACK TO pc_bas_del_temp;
        END IF;

        Su_Bas_Cre_Ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No BOR',
                        p_par_ano_1       => v_bordereau_en_cours,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        su_term_pkg.message_box_code('O', v_cod_err_su_ano, 'TER_TITLE-0001');
    
END;    
            
-------------------------------------------------------------------------------    
END;    
/
show errors;
