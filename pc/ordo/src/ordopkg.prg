/* $Id$ */
CREATE OR REPLACE
PACKAGE BODY pc_ordo_pkg AS

-- DESCRIPTION :
-- -------------
-- ce package contient toutes les fonctions pour effectuer l'ordonnancement
-- des commandes de préparation
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 04c,28.01.15,croc Trac 25245 : Calcul dlc max si delai null
-- 04b,21.01.15,croc Recherche contrat date multi-usines
-- 04a,14.01.15,mco2 Gestion du respect du contrat date en mode Déroger en automatique
-- 03i,10.10.13,alfl recuperer le cod_cnt de l'UEE en CC et si cl CNT_PIC='$EXP'
-- 03h,16.07.13,alfl mise en erreur des uee si la distribution a échoué dans pc_bas_maj_resa_uee
-- 03g,17.10.12,alfl suppression de su_bas_ala_marche
-- 03f,08.10.12,alfl correction plan apres resa-> prendre que les colis réserves
-- 03e,19.05.11,alfl curseur dynamique pour la selection de la vague
-- 03d,13.10.10,alfl GREATEST de la dlc max
-- 03c,18.02.10,alfl prendre en compte dat_fin_sel si delai a NULL + LOOP sur les vagues dans pc_bas_atv_ordo_trt_usn
-- 03b,18.02.10,alfl mettre au moins un mag de picking dans lst_mag_pic
-- 03a,13.01.10 alfl Appel a la pc_bas_ord_rch_atl_prp (recherche un atelier)
-- 02d,02.11.09,mnev pc_bas_trace avec traduction
-- 02c,02.11.09,alfl ajout de trace dans la reservation de stock (pc_bas_trace)
-- 02b,16.10.09,alfl conversion qte_a_res en UB si on est en multi vl
-- 02a,22.04.09,MCOC ajout de la gestion des contraintes de réservation
-- 01a,20.04.07,GQUI
-- 00a,20.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------

/*
****************************************************************************
* pc_bas_atv_ordo_loop -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction est appelé par la tache de fond et permet de
-- lancer les fonctionnalités de Pré-ordonnancement
--
-- PARAMETRES :
-- ------------
--  xxx
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,20.04.07,xxxx    ...
-- 00a,20.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  WAIT ou EXIT
--
-- COMMIT :
-- --------
--   NON
--

PROCEDURE pc_bas_atv_ordo_loop(p_id_tsk         su_tsk_fond.id_tsk%TYPE,
                               p_par_tsk_fond_1 VARCHAR2,   -- Liste Usine
                               p_par_tsk_fond_2 VARCHAR2,
                               p_par_tsk_fond_3 VARCHAR2,
                               p_par_tsk_fond_4 VARCHAR2,
                               p_par_tsk_fond_5 VARCHAR2,
                               p_cod_ope_tsk    su_tsk_fond.cod_ope_tsk%TYPE,
                               p_tps_cycle      su_tsk_fond.tps_cycle%TYPE,
                               p_cmd_unix   OUT VARCHAR2,
                               p_ret        OUT VARCHAR2)
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_ordo_loop:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    -- Déclaration des variables
    v_par_tsk_fond_1    VARCHAR2(200);
    v_position          INTEGER;
    v_cod_usn           su_usn.cod_usn%TYPE;
    v_id_tsk            su_tsk_fond.id_tsk%TYPE := p_id_tsk;
    v_typ_vag           pc_vag.typ_vag%TYPE;
    v_ss_typ_vag        pc_vag.ss_typ_vag%TYPE;
    v_cod_verrou        VARCHAR2(100);

    -- Déclaration des curseurs
    CURSOR c_usn IS
    SELECT cod_usn
    FROM su_usn;
    v_cod_usn_mem       pc_val_pc.cod_usn%TYPE;--Mémorisation du code usine global
BEGIN
    v_etape := '### Debut traitement ### :';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape
                        ||' : p_par_tsk_fond_1 = ' || p_par_tsk_fond_1);
    END IF;

            /************************
            1) PHASE INITIALISATION
            ************************/
    -- Initialisation du contexte
    v_etape := 'Initialisation contexte';
    su_bas_init_context;

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_PC_ORDO_LOOP') THEN
        v_ret_evt := pc_evt_ordo_loop ( 'PRE',
                                        p_id_tsk  ,
                                        p_par_tsk_fond_1,   -- Liste Usines
                                        p_par_tsk_fond_2,
                                        p_par_tsk_fond_3,
                                        p_par_tsk_fond_4,
                                        p_par_tsk_fond_5,
                                        p_cod_ope_tsk,
                                        p_tps_cycle,
                                        p_cmd_unix);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

            /********************
             2) PHASE TRAITEMENT
            ********************/
    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_PC_ORDO_LOOP') THEN
        v_ret_evt := pc_evt_ordo_loop ( 'ON',
                                        p_id_tsk  ,
                                        p_par_tsk_fond_1,  --Liste usines
                                        p_par_tsk_fond_2,
                                        p_par_tsk_fond_3,
                                        p_par_tsk_fond_4,
                                        p_par_tsk_fond_5,
                                        p_cod_ope_tsk,
                                        p_tps_cycle,
                                        p_cmd_unix);
         IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        -- ---------------------------------------------------------------------
        -- Code de traitement standard
        -- ---------------------------------------------------------------------
        -- Attribution du type de vague, du sous_type de vague, du verrou,
        v_typ_vag     := pc_ordo_pkv.TYP_VAG_ORDO;
        v_ss_typ_vag  := pc_ordo_pkv.TYP_VAG_MANU;
        v_cod_verrou  := pc_ordo_pkv.VERROU_ORDO;


        /*********************************
        * On libère les verrous orphelins
        *********************************/
        v_etape := 'Libération des verrous orphelins';
        v_ret := pc_bas_recover_lock (p_cod_fct =>v_cod_verrou);


        /*********************
        * Recherche des usines
        **********************/
        -- Attribution du type de vague, du sous-type, du verrou, de la date de ref.
        v_ss_typ_vag  := pc_ordo_pkv.TYP_VAG_AUTO;
        v_par_tsk_fond_1 := p_par_tsk_fond_1 ;
        LOOP
            -- split du code usine
            v_position := instr(v_par_tsk_fond_1,';');
            IF (nvl(v_position,0) = 0) THEN
                v_cod_usn := v_par_tsk_fond_1;
            ELSE
                v_cod_usn := LTRIM(RTRIM(SUBSTR(v_par_tsk_fond_1,1,v_position-1)));
                v_par_tsk_fond_1 := SUBSTR(v_par_tsk_fond_1,v_position+1);
            END IF;

            /*********************************
            * Toutes les usines ?
            **********************************/
            IF v_cod_usn = '*' THEN
                OPEN c_usn;
                LOOP
                    FETCH c_usn INTO v_cod_usn;
                    EXIT WHEN c_usn%NOTFOUND;

                    /*******************************************************
                    * 1: Traitement de l'ORDO MANUEL pour l'usine
                    ********************************************************/
                    -- Attribution du sous type de vague en MANUEL
                    v_etape := '1-Appel traitement MANUEL Ordo sur l''usine: ' || v_cod_usn ;
                    v_ss_typ_vag  := pc_ordo_pkv.TYP_VAG_MANU;
                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj || v_etape);
                    END IF;
                    
                    v_cod_usn_mem:=su_global_pkg.su_bas_get_cod_usn; -- Mémoriser la variable usine           
                    su_global_pkg.su_bas_set_cod_usn(v_cod_usn); --$MOD,20141013,croc trac 25425
                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj||' : v_cod_usn = '|| v_cod_usn
                                                    ||' su_global_pkv.v_cod_usn '||su_global_pkv.v_cod_usn 
                                                    ||' v_cod_usn_mem '||v_cod_usn_mem);
                    END IF;
                    v_ret := pc_bas_atv_ordo_trt_usn (p_cod_usn        =>v_cod_usn,
                                                      p_par_tsk_fond_2 =>p_par_tsk_fond_2,
                                                      p_par_tsk_fond_3 =>p_par_tsk_fond_3,
                                                      p_par_tsk_fond_4 =>p_par_tsk_fond_4,
                                                      p_par_tsk_fond_5 =>p_par_tsk_fond_5,
                                                      p_typ_vag        =>v_typ_vag,
                                                      p_ss_typ_vag     =>v_ss_typ_vag,
                                                      p_cod_verrou     =>v_cod_verrou);
                    -- Reprendre la variable usine   
                    su_global_pkg.su_bas_set_cod_usn(v_cod_usn_mem);                               
                    IF v_ret <> 'OK' THEN
                        v_niv_ano:= 2;
                        v_cod_err_su_ano := 'PC-ORDO001';
                        su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'Code usine',
                                p_par_ano_1       => v_cod_usn,
                                p_lib_ano_2       => 'Type Vag',
                                p_par_ano_2       => v_typ_vag,
                                p_lib_ano_3       => 'SS_Typ Vag',
                                p_par_ano_3       => v_ss_typ_vag,
                                p_lib_ano_4       => 'Code verrou',
                                p_par_ano_4       => v_cod_verrou,
                                p_cod_err_su_ano  => v_cod_err_su_ano,
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version);
                    END IF;

                    /*******************************************************
                    * 2: Traitement de l'ORDO AUTOMATIQUE pour l'usine
                    ********************************************************/
                    -- Attribution du type de vague en AUTO.
                    v_ss_typ_vag  := pc_ordo_pkv.TYP_VAG_AUTO;
                    v_etape := '1-Appel traitement AUTO ordo sur l''usine: ' || v_cod_usn;
                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj || v_etape);
                    END IF;
                    
                    
                    v_cod_usn_mem:=su_global_pkg.su_bas_get_cod_usn;-- Mémoriser la variable usine            
                    -- Positionner la variable globale v_cod_usn
                    su_global_pkg.su_bas_set_cod_usn(v_cod_usn); --$MOD,20141013,croc trac 25425
                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj||' : v_cod_usn = '|| v_cod_usn
                                          ||' su_global_pkv.v_cod_usn '||su_global_pkv.v_cod_usn 
                                          ||' v_cod_usn_mem '||v_cod_usn_mem);
                    END IF;
                    v_ret := pc_bas_atv_ordo_trt_usn (p_cod_usn         =>v_cod_usn,
                                                      p_par_tsk_fond_2  =>p_par_tsk_fond_2,
                                                      p_par_tsk_fond_3  =>p_par_tsk_fond_3,
                                                      p_par_tsk_fond_4  =>p_par_tsk_fond_4,
                                                      p_par_tsk_fond_5  =>p_par_tsk_fond_5,
                                                      p_typ_vag         =>v_typ_vag,
                                                      p_ss_typ_vag      =>v_ss_typ_vag,
                                                      p_cod_verrou      =>v_cod_verrou);
                    -- Reprendre la variable usine   
                    su_global_pkg.su_bas_set_cod_usn(v_cod_usn_mem);                                     
                    IF v_ret <> 'OK' THEN
                       v_niv_ano:= 2;
                       v_cod_err_su_ano := 'PC-ORDO002';
                       RAISE err_except;
                    END IF;
                END LOOP;
                CLOSE c_usn;

            /**************************
            * Usine paramétrée
            **************************/
            ELSIF v_cod_usn IS NOT NULL THEN
                /*******************************************************
                * 1: Traitement de l'ORDO MANUEL pour l'usine
                ********************************************************/
                -- Attribution du sous type de vague en MANUEL
                v_etape := '2-Appel traitement MANUEL Ordo sur l''usine: ' || v_cod_usn ;
                v_ss_typ_vag  := pc_ordo_pkv.TYP_VAG_MANU;
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || v_etape);
                END IF;
                
                v_cod_usn_mem:=su_global_pkg.su_bas_get_cod_usn; -- Mémoriser la variable usine           
                -- Positionner la variable globale v_cod_usn
                su_global_pkg.su_bas_set_cod_usn(v_cod_usn); --$MOD,20141013,croc trac 25425
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj||' : v_cod_usn = '|| v_cod_usn
                                          ||' su_global_pkv.v_cod_usn '||su_global_pkv.v_cod_usn 
                                          ||' v_cod_usn_mem '||v_cod_usn_mem);
                END IF;
                v_ret := pc_bas_atv_ordo_trt_usn (p_cod_usn         =>v_cod_usn,
                                                  p_par_tsk_fond_2  =>p_par_tsk_fond_2,
                                                  p_par_tsk_fond_3  =>p_par_tsk_fond_3,
                                                  p_par_tsk_fond_4  =>p_par_tsk_fond_4,
                                                  p_par_tsk_fond_5  =>p_par_tsk_fond_5,
                                                  p_typ_vag         =>v_typ_vag,
                                                  p_ss_typ_vag      =>v_ss_typ_vag,
                                                  p_cod_verrou      =>v_cod_verrou);

                   
                su_global_pkg.su_bas_set_cod_usn(v_cod_usn_mem);-- Reprendre la variable usine 
                IF v_ret <> 'OK' THEN
                    v_niv_ano:= 2;
                    v_cod_err_su_ano := 'PC-ORDO001';
                    su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'Code usine',
                            p_par_ano_1       => v_cod_usn,
                            p_lib_ano_2       => 'Type Vag',
                            p_par_ano_2       => v_typ_vag,
                            p_lib_ano_3       => 'SS_Typ Vag',
                            p_par_ano_3       => v_ss_typ_vag,
                            p_lib_ano_4       => 'Code verrou',
                            p_par_ano_4       => v_cod_verrou,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
                END IF;


                /*******************************************************
                * 2: Traitement de l'ORDO AUTOMATIQUE pour l'usine
                ********************************************************/
                -- Attribution du type de vague en AUTO.
                v_ss_typ_vag  := pc_ordo_pkv.TYP_VAG_AUTO;
                v_etape := '2-Appel traitement AUTO ordo sur l''usine: ' || v_cod_usn;
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || v_etape);
                END IF;
                v_ret := pc_bas_atv_ordo_trt_usn (p_cod_usn         =>v_cod_usn,
                                                  p_par_tsk_fond_2  =>p_par_tsk_fond_2,
                                                  p_par_tsk_fond_3  =>p_par_tsk_fond_3,
                                                  p_par_tsk_fond_4  =>p_par_tsk_fond_4,
                                                  p_par_tsk_fond_5  =>p_par_tsk_fond_5,
                                                  p_typ_vag         =>v_typ_vag,
                                                  p_ss_typ_vag      =>v_ss_typ_vag,
                                                  p_cod_verrou      =>v_cod_verrou);

                IF v_ret <> 'OK' THEN
                    v_niv_ano:= 2;
                    v_cod_err_su_ano := 'PC-ORDO002';
                    su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => v_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => v_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => v_ss_typ_vag,
                        p_lib_ano_4       => 'Code verrou',
                        p_par_ano_4       => v_cod_verrou,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
                END IF;
            END IF;
            EXIT WHEN (NVL(v_position,0) = 0);
        END LOOP;

        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' : p_par_tsk_fond_1 = ' || p_par_tsk_fond_1
                        ||' / Fin traitement = ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:ss'));
        END IF;
    END IF;      -- Fin du traitement standard

                /**********************
                 3) PHASE FINALISATION
                **********************/
    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_PC_ORDO_LOOP') THEN
         v_ret_evt := pc_evt_ordo_loop ( 'ON',
                                        p_id_tsk  ,
                                        p_par_tsk_fond_1,   -- Liste Usines
                                        p_par_tsk_fond_2,
                                        p_par_tsk_fond_3,
                                        p_par_tsk_fond_4,
                                        p_par_tsk_fond_5,
                                        p_cod_ope_tsk,
                                        p_tps_cycle,
                                        p_cmd_unix);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    v_etape := '##### Fin de traitement ##### : ';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape
                        ||' : p_par_tsk_fond_1 = ' || p_par_tsk_fond_1);
    END IF;


    -- Retour pour mise en attente sur cycle
    ----------------------------------------
    p_ret := 'WAIT';

EXCEPTION
    WHEN OTHERS THEN
      IF c_usn%ISOPEN THEN
          CLOSE c_usn;
      END IF;

      v_cod_err_su_ano := 'PC-ORDO000';
      su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_niv_ano=>v_niv_ano,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_usn         => v_cod_usn,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_par_tsk_fond_1,
                        p_lib_ano_2       => 'Id tsk',
                        p_par_ano_2       => v_id_tsk,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         =>'PC_ORDO_ECHEC');

      p_ret := 'EXIT';
END;

/****************************************************************************
*   pc_bas_rch_th_active -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de rechercher la tranche horaire active de la vague
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,20.11.09,mnev    Utilise la fonction exterieure au package.
-- 01b,04.07.08,mnev    Corrige calcul du n° de jour
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn   : code usine
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_rch_th_active (p_cod_usn      su_usn.cod_usn%TYPE,
                               p_typ_vag      pc_vag.typ_vag%TYPE,
                               p_ss_typ_vag   pc_vag.ss_typ_vag%TYPE,
                               p_dat_ref      DATE,
                               pr_pc_th   OUT pc_th%ROWTYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_rch_th_active:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

BEGIN


    v_ret := pc_bas_rch_th_active_vag(p_cod_usn => p_cod_usn,
                                      p_typ_vag => p_typ_vag,
                                      p_ss_typ_vag => p_ss_typ_vag,
                                      p_dat_ref => p_dat_ref,
                                      pr_pc_th  => pr_pc_th);
    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_atv_ordo_trt_usn -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet d'effectuer les traitements d'ordo
-- sur une usine passée en paramètre et suivant la configuration de la vague
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02g,02.12.14,mnev    Gère heure deb > heure fin
-- 02f,23.06.14,mnev    Ajout d'un COMMIT en fin de traitement.
-- 02e,07.11.12,alfl    integration du traitement des UEE non regulés
-- 02d,19.07.12,mnev    Modif sur le OR delai_sel ds c_pc_th
-- 02c,14.05.10,rbel    Correction gestion erreur
-- 02b,18.02.10,alfl    LOOP sur les th
-- 02a,29.10.09,rbel    Suppression savepoint car bas_resa_stk fait des commit
--                      Appel fonction d'annulation en cas d'erreurs
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_typ_vag    : type de vague
--  p_ss_typ_vag : sous type de vague
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--  OUI

FUNCTION pc_bas_atv_ordo_trt_usn (p_cod_usn         su_usn.cod_usn%TYPE,
                                  p_par_tsk_fond_2  VARCHAR2,    -- code d'activité
                                  p_par_tsk_fond_3  VARCHAR2,
                                  p_par_tsk_fond_4  VARCHAR2,
                                  p_par_tsk_fond_5  VARCHAR2,
                                  p_typ_vag         pc_vag.typ_vag%TYPE,
                                  p_ss_typ_vag      pc_vag.ss_typ_vag%TYPE,
                                  p_cod_verrou      VARCHAR2)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02g $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_ordo_trt_usn:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_2             VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    -- déclarations de variables
    v_nb_lig_lock       NUMBER(10) := 0;
    v_nb_uee_lock       NUMBER(10) := 0;
    v_crea_plan         VARCHAR2(20);
    v_cod_pss_defaut    su_pss.cod_pss%TYPE;
    v_status            VARCHAR2(20);
    v_dat_ref           DATE := SYSDATE;
    v_cod_atv           VARCHAR2(100) := p_par_tsk_fond_2;   -- code d'activité
    v_typ_atv_cible     VARCHAR2(100):=NULL;

    -- no_session
    -- ----------
    v_session_ora       VARCHAR2(20) := su_global_pkv.v_no_session_ora;

    -- déclaration des curseurs
    -- ------------------------
    -- On récupère de la tranche horaire active
    -- les configurations de vagues activées, triées par no ordre
    CURSOR c_pc_vag_cfg  (x_cod_th  pc_th.cod_th%TYPE) IS
        SELECT v.*
        FROM pc_th a, pc_th_det b, pc_vag v
        WHERE a.cod_th       = x_cod_th                 AND
              a.etat_actif   = '1'                      AND
              b.cod_th       = a.cod_th                 AND
              b.etat_actif   = '1'                      AND
              b.no_vag       = v.no_vag                 AND
              b.mode_vag     = v.mode_vag               AND
              v.etat_actif   = '1'                      AND
              v.mode_vag     = pc_ordo_pkv.MODE_VAG_CFG
        ORDER BY b.no_ord_vag;

    r_pc_vag_cfg     c_pc_vag_cfg%ROWTYPE;
    r_pc_th          pc_th%ROWTYPE;

    CURSOR c_typ_atv_cible IS
    SELECT B.typ_atv from su_atv A, su_atv B
    WHERE A.cod_atv=v_cod_atv AND B.cod_atv=A.COD_ATV_CIBLE_DRG;


    -- déclaration des curseurs
    -- Recherche de la tranche horaire active
    CURSOR c_pc_th (
            x_cod_usn       su_usn.cod_usn%TYPE,
            x_typ_vag       pc_vag.typ_vag%TYPE,
            x_ss_typ_vag    pc_vag.ss_typ_vag%TYPE,
            x_dat_ref       DATE) IS
        SELECT   *
        FROM     pc_th a
        WHERE    a.cod_usn = x_cod_usn
        AND      a.typ_vag = x_typ_vag
        AND      a.ss_typ_vag = x_ss_typ_vag
        AND      a.etat_actif = '1'
        AND      ((a.jour = TO_CHAR(su_bas_get_jour (x_dat_ref)) OR a.jour = '*') AND (
                  (a.hh_deb-TRUNC(a.hh_deb) <= a.hh_fin-TRUNC(a.hh_fin) AND
                    ((x_dat_ref - TRUNC (x_dat_ref)) BETWEEN (a.hh_deb - TRUNC (a.hh_deb)) AND (a.hh_fin - TRUNC (a.hh_fin)))
                  ) OR
                  (a.hh_deb-TRUNC(a.hh_deb) > a.hh_fin-TRUNC(a.hh_fin) AND
                    NOT ((x_dat_ref - TRUNC (x_dat_ref)) BETWEEN (a.hh_fin - TRUNC (a.hh_fin)) AND (a.hh_deb - TRUNC (a.hh_deb)))
                  ) OR
                  (a.delai_sel >= 9999999)  -- Mode infini
                 ))
        ORDER BY a.jour DESC,a.hh_deb;

    r_pc_th          c_pc_th%ROWTYPE;
    found_pc_th      BOOLEAN;

    v_debut             TIMESTAMP;
    v_debut_tot         TIMESTAMP;

    v_etape_resa_stk    BOOLEAN := FALSE;
    v_savep             VARCHAR2(30) := '';

BEGIN

    v_etape := 'Debut trait:' || ' usine: ' || p_cod_usn
                              || ' typ_vag: '  || p_typ_vag
                              || ' ss_typ_vag: ' || p_ss_typ_vag;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;

    v_etape := 'pose IDP';
    su_perf_pkg.su_bas_start_idp(p_typ_idp => 'SU_ATV1TRT',
                                 p_cod_idp => p_par_tsk_fond_2 || p_ss_typ_vag);

                 /************************
                 1) PHASE INITIALISATION
                ************************/

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_PC_ORDO_TRT_USN') THEN
        v_ret_evt := pc_evt_ordo_trt_usn ('PRE' ,
                                           p_cod_usn,
                                           p_par_tsk_fond_2,
                                           p_par_tsk_fond_3,
                                           p_par_tsk_fond_4,
                                           p_par_tsk_fond_5,
                                           p_typ_vag,
                                           p_ss_typ_vag,
                                           p_cod_verrou);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

                /********************
                 2) PHASE TRAITEMENT
                ********************/
    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_PC_ORDO_TRT_USN') THEN
        v_ret_evt := pc_evt_ordo_trt_usn ('ON',
                                           p_cod_usn,
                                           p_par_tsk_fond_2,
                                           p_par_tsk_fond_3,
                                           p_par_tsk_fond_4,
                                           p_par_tsk_fond_5,
                                           p_typ_vag,
                                           p_ss_typ_vag,
                                           p_cod_verrou);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        -- ---------------------------------------------------------------------
        -- Code de traitement standard
        -- ---------------------------------------------------------------------


        -- recup si on doit calculer le plan
        -- ---------------------------------
        -- Recherche de la valeur de la clef 'CREA_PLAN' du process default de l'usine
        v_cod_pss_defaut   := su_bas_get_pss_defaut(p_cod_usn);
        v_status := su_bas_rch_cle_atv_pss(v_cod_pss_defaut,
                                          'ORD',            -- Type d'activité
                                          'CREA_PLAN',
                                           v_crea_plan);

        IF su_global_pkv.v_niv_dbg >= 6 THEN
           v_etape := ' Lecture clef CREA_PLAN:' || v_crea_plan;
           su_bas_put_debug(v_nom_obj || v_etape);
           su_bas_put_debug(v_nom_obj || 'Rch tranches horaires : Usn=' || p_cod_usn || ' Typ_vag=' ||
                            p_typ_vag || ' Sous type=' || p_ss_typ_vag || ' dat_ref=' || TO_CHAR(v_dat_ref,'DD/MM/YY HH24:MI'));
        END IF;

        FOR r_pc_th IN c_pc_th (p_cod_usn, p_typ_vag, p_ss_typ_vag, v_dat_ref)
        LOOP
            v_etape := ' Vague trouvee:' || r_pc_th.cod_th;

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug (v_nom_obj || v_etape);
            END IF;

            -- Test si une tranche horaire existe ??
            IF  r_pc_th.cod_th IS NULL THEN
                v_etape := ' -> Pas de tranche horaire mode:' || p_ss_typ_vag
                           || ' Usine:' || p_cod_usn;
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                   su_bas_put_debug(v_nom_obj || v_etape);
                END IF;
                RETURN 'OK';  -- on sort
            END IF;

            IF su_global_pkv.v_niv_dbg >= 2 THEN
                su_bas_put_debug(v_nom_obj||' *** BEGIN T=0');
                v_debut_tot := SYSTIMESTAMP;
                v_debut     := v_debut_tot;
            END IF;

            v_etape := 'Rch des cfg vagues sur la tranche horaire active: ' || r_pc_th.cod_th;
            OPEN c_pc_vag_cfg (r_pc_th.cod_th);
            LOOP
                FETCH c_pc_vag_cfg INTO r_pc_vag_cfg;
                EXIT WHEN c_pc_vag_cfg%NOTFOUND;

                IF su_global_pkv.v_niv_dbg >= 2 THEN
                    su_bas_put_debug(v_nom_obj||' *** FETCH T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                    v_debut := SYSTIMESTAMP;
                END IF;

                ----------------------------------------------
                -- 1: Pose d'un verrou sur les LIG COM et UEE
                --    (commit ds les fonctions de selection)
                -----------------------------------------------
                v_etape := 'Pose verrou sur lig-com et uee de la vague: ';
                v_nb_lig_lock := 0;
                IF  p_ss_typ_vag = pc_ordo_pkv.TYP_VAG_AUTO  THEN
                    v_ret := pc_bas_select_vag_auto (p_cod_usn     =>p_cod_usn,
                                            p_typ_vag     =>p_typ_vag,
                                            p_ss_typ_vag  =>p_ss_typ_vag,
                                            pr_pc_th      =>r_pc_th,
                                            pr_pc_vag_cfg =>r_pc_vag_cfg,
                                            p_cod_verrou  =>p_cod_verrou,
                                            p_crea_plan   =>v_crea_plan,
                                            p_nb_lig_lock =>v_nb_lig_lock,
                                            p_nb_uee_lock =>v_nb_uee_lock);
                ELSE
                    v_ret := pc_bas_select_vag_manu (p_cod_usn     =>p_cod_usn,
                                            p_typ_vag     =>p_typ_vag,
                                            p_ss_typ_vag  =>p_ss_typ_vag,
                                            pr_pc_th      =>r_pc_th,
                                            pr_pc_vag_cfg =>r_pc_vag_cfg,
                                            p_cod_verrou  =>p_cod_verrou,
                                            p_crea_plan   =>v_crea_plan,
                                            p_nb_lig_lock =>v_nb_lig_lock,
                                            p_nb_uee_lock =>v_nb_uee_lock);

                END IF;

                -- Traitement de l'erreur
                IF v_ret <> 'OK' THEN
                    v_niv_ano:= 2;
                    v_cod_err_su_ano := 'PC-ORDO004';
                    RAISE err_except;
                END IF;

                IF su_global_pkv.v_niv_dbg >= 3 THEN
                   su_bas_put_debug(v_nom_obj || v_etape
                                    || ' Nb de lig lockees: ' || TO_CHAR(v_nb_lig_lock)
                                    || ' Nb d''UEE lockees: ' || TO_CHAR(v_nb_uee_lock));
                END IF;
                -- test si des lignes ont été verrouillées.
                --------------------------------------------
                IF v_nb_lig_lock > 0 THEN

                    IF su_global_pkv.v_niv_dbg >= 2 THEN
                        su_bas_put_debug(v_nom_obj||'*** SELECTION OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                        v_debut := SYSTIMESTAMP;
                    END IF;

                    --$MOD,rbel,29.10.09  mise en commentaire savepoint
                    -- Dépose d'un savepoint pour le traitement des lignes de la vague
                    v_etape := 'Depose du savepoint:  my_sp_ordo_lig_vague';
                    v_savep := 'my_sp_ordo_lig_vague';
                    SAVEPOINT my_sp_ordo_lig_vague;

                    v_etape_resa_stk := FALSE;

                    ------------------------------------------------------------
                    -- 2: Test et Calcul d'un plan avant réservation de la vague
                    ------------------------------------------------------------
                    IF p_ss_typ_vag = pc_ordo_pkv.TYP_VAG_AUTO AND
                        v_crea_plan = pc_ordo_pkv.AVEC_CALCUL_PLAN_AVANT_RESA THEN

                        v_etape := 'Calcul du plan de la vague avant réservation';
                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                            su_bas_put_debug(v_nom_obj || v_etape);
                        END IF;
                        v_ret := pc_bas_calcul_plan_pal (p_crea_plan  =>v_crea_plan,
                                                         p_cod_verrou =>p_cod_verrou);

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** PLAN M1 OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                            v_debut := SYSTIMESTAMP;
                        END IF;

                       ----------------------------------------------
                       -- Traitement de l'erreur
                        IF v_ret <> 'OK' THEN
                            v_niv_ano:= 2;
                            v_cod_err_su_ano := 'PC-ORDO005';
                            su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'Code usine',
                                p_par_ano_1       => p_cod_usn,
                                p_lib_ano_2       => 'Type Vag',
                                p_par_ano_2       => p_typ_vag,
                                p_lib_ano_3       => 'SS_Typ Vag',
                                p_par_ano_3       => p_ss_typ_vag,
                                p_lib_ano_4       => 'Code verrou',
                                p_par_ano_4       => p_cod_verrou,
                                p_cod_err_su_ano  => v_cod_err_su_ano,
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version);
                        END IF;

                    END IF;

                    ---------------------------------------------------
                    -- 3: Réservation Ferme du stock
                    ---------------------------------------------------
                    v_etape := 'Réservation Ferme du stock';
                    IF v_ret = 'OK' AND p_ss_typ_vag = pc_ordo_pkv.TYP_VAG_AUTO THEN
                        v_ret := pc_bas_resa_stk (  p_cod_usn       =>p_cod_usn,
                                                p_typ_vag       =>p_typ_vag,
                                                p_ss_typ_vag    =>p_ss_typ_vag,
                                                p_no_vag        =>r_pc_vag_cfg.no_vag,
                                                p_cod_verrou    =>p_cod_verrou,
                                                p_crea_plan     =>v_crea_plan
                                             );
                        -- Traitement de l'erreur
                        IF v_ret = 'ERROR' THEN
                           v_niv_ano:= 2;
                           v_cod_err_su_ano := 'PC-ORDO006';
                           su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'Code usine',
                                p_par_ano_1       => p_cod_usn,
                                p_lib_ano_2       => 'Type Vag',
                                p_par_ano_2       => p_typ_vag,
                                p_lib_ano_3       => 'SS_Typ Vag',
                                p_par_ano_3       => p_ss_typ_vag,
                                p_lib_ano_4       => 'Code verrou',
                                p_par_ano_4       => p_cod_verrou,
                                p_cod_err_su_ano  => v_cod_err_su_ano,
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version);
                        END IF;

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** RESA OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                            v_debut := SYSTIMESTAMP;
                        END IF;

                        v_etape := 'Depose du savepoint:  my_sp_ordo_lig_vague';
                        v_savep := 'my_sp_ordo_lig_vague';
                        SAVEPOINT my_sp_ordo_lig_vague;

                        v_etape_resa_stk := TRUE;

                    END IF;

                    --------------------------------------------------------
                    -- 4: Distribution des réservations sur les colis PC_UEE
                    --------------------------------------------------------
                    IF v_ret = 'OK' THEN
                        v_etape := 'Distribution des résas sur colis';
                        v_ret := pc_bas_distribution_resa ( p_cod_usn       =>p_cod_usn,
                                                            p_typ_vag       =>p_typ_vag,
                                                            p_ss_typ_vag    =>p_ss_typ_vag,
                                                            p_no_vag        =>r_pc_vag_cfg.no_vag,
                                                            p_cod_verrou    =>p_cod_verrou,
                                                            p_crea_plan     =>v_crea_plan
                                                          );

                        -- Traitement de l'erreur
                        IF v_ret <> 'OK' THEN
                            v_niv_ano:= 2;
                            v_cod_err_su_ano := 'PC-ORDO007';
                            su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'Code usine',
                            p_par_ano_1       => p_cod_usn,
                            p_lib_ano_2       => 'Type Vag',
                            p_par_ano_2       => p_typ_vag,
                            p_lib_ano_3       => 'SS_Typ Vag',
                            p_par_ano_3       => p_ss_typ_vag,
                            p_lib_ano_4       => 'Code verrou',
                            p_par_ano_4       => p_cod_verrou,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
                        END IF;

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** DISTRI OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                            v_debut := SYSTIMESTAMP;
                        END IF;

                    END IF;

                    -----------------------------------------------------------------------------------------
                    -- 5: Test et Calcul du plan de la vague si calcul du plan APRES_RESA (v_crea_plan = '2'
                    -----------------------------------------------------------------------------------------
                    IF v_ret = 'OK' AND
                        p_ss_typ_vag = pc_ordo_pkv.TYP_VAG_AUTO AND
                        v_crea_plan IN (pc_ordo_pkv.AVEC_CALCUL_PLAN_APRES_RESA,
                                        pc_ordo_pkv.AVEC_CALCUL_PLAN_FIN_ORDO) THEN

                        -- On préalable on doit dévérouiller tous les colis
                        -- qui n'ont pu être réservés.
                        v_etape := 'Intégration dans un plan';
                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                            su_bas_put_debug(v_nom_obj || v_etape);
                        END IF;
                        v_ret := pc_bas_calcul_plan_pal (p_crea_plan  =>v_crea_plan,
                                                         p_cod_verrou =>p_cod_verrou);

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** PLAN M2 OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2')||' '||v_ret);
                            v_debut := SYSTIMESTAMP;
                        END IF;

                        ----------------------------------------------
                        -- Traitement de l'erreur
                        IF v_ret <> 'OK' THEN
                            v_niv_ano:= 2;
                            v_cod_err_su_ano := 'PC-ORDO008';
                            su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'Code usine',
                            p_par_ano_1       => p_cod_usn,
                            p_lib_ano_2       => 'Type Vag',
                            p_par_ano_2       => p_typ_vag,
                            p_lib_ano_3       => 'SS_Typ Vag',
                            p_par_ano_3       => p_ss_typ_vag,
                            p_lib_ano_4       => 'Code verrou',
                            p_par_ano_4       => p_cod_verrou,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);
                        END IF;

                    END IF;

                    v_etape := 'Dereservation lig erreur planexp';
                    pc_bas_dereserve_rstk_lig_err (p_crea_plan  => v_crea_plan,
                                                   p_cod_verrou => p_cod_verrou);

                    ----------------------------------------------------
                    -- 6: On valide le plan si creation du plan à l'ORDO
                    ----------------------------------------------------
                    IF v_ret = 'OK'                                 AND
                       p_ss_typ_vag = pc_ordo_pkv.TYP_VAG_AUTO      AND
                       v_crea_plan IN (pc_ordo_pkv.AVEC_CALCUL_PLAN_AVANT_RESA,
                                       pc_ordo_pkv.AVEC_CALCUL_PLAN_APRES_RESA,
                                       pc_ordo_pkv.AVEC_CALCUL_PLAN_FIN_ORDO) THEN
                        -- On valide le plan
                        v_etape := 'Validation du plan';
                        v_ret := pc_plan_exp_pkg.pc_bas_valid_plan (p_fct_lock  =>p_cod_verrou);

                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                           su_bas_put_debug(v_nom_obj|| ' ' || v_etape||' '||v_ret);
                        END IF;

                        ----------------------------------------------
                        -- Traitement de l'erreur
                        IF v_ret <> 'OK' THEN
                            v_niv_ano:= 2;
                            v_cod_err_su_ano := 'PC-ORDO009';
                            su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'Code usine',
                                p_par_ano_1       => p_cod_usn,
                                p_lib_ano_2       => 'Type Vag',
                                p_par_ano_2       => p_typ_vag,
                                p_lib_ano_3       => 'SS_Typ Vag',
                                p_par_ano_3       => p_ss_typ_vag,
                                p_lib_ano_4       => 'Code verrou',
                                p_par_ano_4       => p_cod_verrou,
                                p_cod_err_su_ano  => v_cod_err_su_ano,
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version);
                        END IF;

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** VALIDATION PLAN OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                            v_debut := SYSTIMESTAMP;
                        END IF;

                    END IF;

                    ---------------------------------------------
                    -- 7: Validation des traitements en définitif
                    ---------------------------------------------
                    IF v_ret = 'OK' THEN
                       v_etape := 'Validation des traitements en définitif';
                       v_ret := pc_bas_valid_ordo (p_cod_usn     =>p_cod_usn,
                                                   p_typ_vag     =>p_typ_vag,
                                                   p_ss_typ_vag  =>p_ss_typ_vag,
                                                   p_cod_verrou  =>p_cod_verrou
                                                   );

                       -- Traitement de l'erreur
                       IF v_ret <> 'OK' THEN
                          v_niv_ano:= 2;
                          v_cod_err_su_ano := 'PC-ORDO011';
                          su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'Code usine',
                                p_par_ano_1       => p_cod_usn,
                                p_lib_ano_2       => 'Type Vag',
                                p_par_ano_2       => p_typ_vag,
                                p_lib_ano_3       => 'SS_Typ Vag',
                                p_par_ano_3       => p_ss_typ_vag,
                                p_lib_ano_4       => 'Code verrou',
                                p_par_ano_4       => p_cod_verrou,
                                p_cod_err_su_ano  => v_cod_err_su_ano,
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version);
                       END IF;

                       IF su_global_pkv.v_niv_dbg >= 2 THEN
                           su_bas_put_debug(v_nom_obj||'*** VALIDATION ORDO OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                           v_debut := SYSTIMESTAMP;
                       END IF;

                    END IF;

                    ---------------------------------------------
                    -- 8: Génération des palettes d'expédition UT
                    ---------------------------------------------
                    IF v_ret = 'OK' THEN
                        v_etape := 'Génération des palettes UT';
                        v_ret := pc_ut_pkg.pc_bas_gen_ut (p_cod_verrou);
                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                           su_bas_put_debug(v_nom_obj || v_etape);
                        END IF;

                        -- Traitement de l'erreur
                        IF v_ret <> 'OK' THEN
                            v_niv_ano:= 2;
                            v_cod_err_su_ano := 'PC-ORDO010';
                            su_bas_cre_ano (p_txt_ano   => 'ERREUR: ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'Code usine',
                                p_par_ano_1       => p_cod_usn,
                                p_lib_ano_2       => 'Type Vag',
                                p_par_ano_2       => p_typ_vag,
                                p_lib_ano_3       => 'SS_Typ Vag',
                                p_par_ano_3       => p_ss_typ_vag,
                                p_lib_ano_4       => 'Code verrou',
                                p_par_ano_4       => p_cod_verrou,
                                p_cod_err_su_ano  => v_cod_err_su_ano,
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version);
                        END IF;

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** GEN UT OK T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                            v_debut := SYSTIMESTAMP;
                        END IF;

                    END IF;


                    -- --------------------------------------------------------------------------
                    -- 9: On test si tout c'est bien passé, sinon on doit rollbacker
                    --    et défaire tout ce qui a été réservé et locké
                    -- --------------------------------------------------------------------------
                    IF v_ret <> 'OK' AND v_etape_resa_stk THEN
                        -- rollbacker jusqu'au savepoint
                        IF v_savep IS NOT NULL THEN
                            ROLLBACK TO my_sp_ordo_lig_vague;
                            v_savep := NULL;
                        END IF;

                        --$MOD,rbel,29.10.09 il faut tout défaire les résa eventuelles déja commitée
                        v_etape := 'Annulation du traitement de la vague';
                        v_ret := pc_bas_ordo_ann (p_cod_usn => p_cod_usn,
                                                  p_cod_verrou => p_cod_verrou);

                    ELSE
                        IF v_ret <> 'OK' THEN
                            IF v_savep IS NOT NULL THEN
                                ROLLBACK TO my_sp_ordo_lig_vague;
                                v_savep := NULL;
                            END IF;
                        END IF;

                        -------------------------------------------------------------------
                        -- 10: On déverrouille tous les resa PC_RSTK lockés de la vague
                        --     avec liberation du stock si record en erreur
                        --------------------------------------------------------------------
                        v_etape := 'On enlève les verrous sur PC_RSTK';
                        v_ret := pc_bas_unlock_pc_rstk(p_cod_usn        =>p_cod_usn,
                                                       p_cod_verrou     =>p_cod_verrou);

                        -------------------------------------------------------------------
                        -- 11: On met à jour no_uee_ut_p1 sur PC_UEE
                        --------------------------------------------------------------------
                        v_etape := 'On met à jour no_uee_ut_p1 sur PC_UEE';
                        v_ret := pc_bas_gen_no_uee_ut_p1(p_cod_usn      =>p_cod_usn,
                                                         p_cod_verrou   =>p_cod_verrou);

                        -------------------------------------------------------------------
                        -- 12: On déverrouille tous les colis dans PC_UEE lockés de la vague
                        --------------------------------------------------------------------
                        v_etape := 'On enlève les verrous sur les colis (PC_UEE)';
                        v_ret := pc_bas_unlock_pc_uee(p_cod_usn     =>p_cod_usn,
                                                      p_cod_verrou  =>p_cod_verrou);

                        -----------------------------------------------------------------------
                        -- 13: On déverrouille toutes les lig_com lockées de la vague
                        -----------------------------------------------------------------------
                        v_etape := 'Deverrouilage des lig_com de (PC_LIG_COM)';
                        v_ret := pc_bas_unlock_pc_lig_com (p_cod_usn     =>p_cod_usn,
                                                           p_cod_verrou  =>p_cod_verrou);

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** FIN TRT 2 T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                            v_debut := SYSTIMESTAMP;
                        END IF;

                    END IF;

                    IF su_global_pkv.v_niv_dbg >= 2 THEN
                        su_bas_put_debug(v_nom_obj||'*** FIN TRT 2 T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                        v_debut := SYSTIMESTAMP;
                    END IF;

                    -------------------------------------------
                    -- 14: ON COMMIT;
                    -------------------------------------------
                    v_etape := 'On commit';
                    COMMIT;

                    v_savep := NULL;
                    ---------------------------------------------
                    -- 15: Controle des UEE non regules
                    ---------------------------------------------
                    v_etape := 'UEE non regul';
                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                       su_bas_put_debug(v_nom_obj || v_etape);
                    END IF;
                    v_ret_2 := pc_afu_pkg.pc_bas_recup_uee_non_reg (p_cod_usn);
                    v_etape := 'On commit 2';
                    COMMIT;

                END IF;    --  IF v_nb_lig_lock > 0 THEN

            END LOOP;
            CLOSE  c_pc_vag_cfg;
        END LOOP;

        -- recupere type atv cible
        v_etape:='type atv cible';
        OPEN c_typ_atv_cible;
        FETCH c_typ_atv_cible INTO v_typ_atv_cible;
        CLOSE c_typ_atv_cible;

        IF pc_ordo_pkv.ALERT_ATV_CIBLE AND v_typ_atv_cible IS NOT NULL THEN
            -- Reinit le flag.
            pc_ordo_pkv.ALERT_ATV_CIBLE := FALSE;

            -- On lance une alerte pour synchroniser l'activité cible.
            v_etape := 'On lance un alerte sur l''activité cible de type '||v_typ_atv_cible||
                       ' et l''usine' || p_cod_usn;

            su_bas_lance_tsk_atv (p_cod_usn,v_typ_atv_cible);

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || v_etape);
            END IF;
        END IF;

    END IF;     -- **** FIN DU TRAITEMENT STANDARD ****

    /**********************
    3) PHASE FINALISATION
    **********************/
    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_PC_ORDO_TRT_USN') THEN
        v_ret_evt := pc_evt_ordo_trt_usn ('POST',
                                          p_cod_usn,
                                          p_par_tsk_fond_2,
                                          p_par_tsk_fond_3,
                                          p_par_tsk_fond_4,
                                          p_par_tsk_fond_5,
                                          p_typ_vag,
                                          p_ss_typ_vag,
                                          p_cod_verrou
                                          );
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    v_etape := 'ecriture IDP';
    su_perf_pkg.su_bas_write_idp(p_typ_idp => 'SU_ATV1TRT',
                                 p_cod_idp => p_par_tsk_fond_2 || p_ss_typ_vag,
                                 p_cod_usn => p_cod_usn);

    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||'*** END FINAL T='|| to_char((SYSTIMESTAMP-v_debut_tot),'sssssxFF2'));
    END IF;

    COMMIT;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        IF c_pc_vag_cfg%ISOPEN THEN
            CLOSE c_pc_vag_cfg;

            --$MOD,rbel,29.10.09 on était en cours de traitement d'une vague
            -- il faut revenir à la situation initiale
            IF v_savep IS NOT NULL THEN
                ROLLBACK TO my_sp_ordo_lig_vague;
            END IF;

            v_etape := 'Annulation du traitement de la vague';
            v_ret := pc_bas_ordo_ann (p_cod_usn => p_cod_usn,
                                      p_cod_verrou => p_cod_verrou);
            COMMIT;
        END IF;

        -- On rollback
        ROLLBACK;

        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;


/****************************************************************************
*   pc_bas_select_vag_auto -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet d'effectuer la sélection de ligne commandes
-- sur une usine passée en paramètre et suivant la configuration de la vague
-- en mode AUTOMATIQUE
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,09.12.12,mnev    calcul date de debut via nouveau champ pc_th.j_deb
-- 01d,19.05.11,alfl    curseur dynamique pour la selection de la vague
-- 01c,19.02.10,alfl    prendre en compte dat_fin_sel si delai a NULL
-- 01b,04.02.09,RBEL    ajout critères de vague dans le curseur de recherche de lig_com
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_typ_vag    : type de vague
--  p_ss_typ_vag : sous type de vague
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
-- OUI

FUNCTION pc_bas_select_vag_auto (p_cod_usn     su_usn.cod_usn%TYPE,
                            p_typ_vag          pc_vag.typ_vag%TYPE,
                            p_ss_typ_vag       pc_vag.ss_typ_vag%TYPE,
                            pr_pc_vag_cfg      pc_vag%ROWTYPE,
                            pr_pc_th           pc_th%ROWTYPE,
                            p_cod_verrou       VARCHAR2,
                            p_crea_plan        VARCHAR2,
                            p_nb_lig_lock IN OUT NUMBER,
                            p_nb_uee_lock IN OUT NUMBER
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_select_vag_auto:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;
    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- déclarations de variables
    v_no_com_ec     pc_ent_com.no_com%TYPE := NULL;
    v_nb_com        NUMBER(10) := 0;
    v_dat_heure_deb DATE;
    v_dat_heure_fin DATE;
    v_etat_atv_lig      pc_lig_com.etat_atv_pc_lig_com%TYPE;
    v_etat_atv_uee_min  VARCHAR2(20);
    v_etat_atv_uee_max  VARCHAR2(20);

    rowcountlig     NUMBER(10) := 0;
    rowcountuee     NUMBER(10) := 0;

    v_cod_pss_defaut    su_pss.cod_pss%TYPE;
    v_status            VARCHAR2(20);
    v_pss_uee_vag_auto  su_pss_atv_cfg.val_cle_atv%TYPE;
    v_req               VARCHAR2(4000) := NULL;
    v_crs               INTEGER;
    v_select            dbms_sql.varchar2a;
    v_result_fetch      INTEGER := 0;
    -- déclarations de variables
    v_no_com            pc_lig_com.no_com%TYPE;
    v_no_lig_com        pc_lig_com.no_lig_com%TYPE;
    v_lst_fct_lock      pc_lig_com.lst_fct_lock%TYPE;


    -- Déclarations des curseurs
    -- --------------------------

   BEGIN

    -- on dépose un SAVEPOINT
    SAVEPOINT my_sp_pc_bas_select_vag;

    v_etape := ' Debut trait.:' || ' p_typ_vag: ' || p_typ_vag || ' p_ss_typ_vag: ' || p_ss_typ_vag || ' p_crea_plan: ' || p_crea_plan ;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;
            /************************
            1) PHASE INITIALISATION
            ************************/
    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_PC_ORDO_SEL_VAG_AUTO') THEN
        v_ret_evt := pc_evt_ordo_select_vag_auto( 'PRE',
                                       p_cod_usn,
                                       p_typ_vag,
                                       p_ss_typ_vag,
                                       pr_pc_vag_cfg,
                                       pr_pc_th,
                                       p_cod_verrou,
                                       p_crea_plan,
                                       p_nb_lig_lock,
                                       p_nb_uee_lock);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

            /********************
             2) PHASE TRAITEMENT
            ********************/
    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_PC_ORDO_SEL_VAG_AUTO') THEN
        v_ret_evt := pc_evt_ordo_select_vag_auto( 'ON',
                                       p_cod_usn,
                                       p_typ_vag,
                                       p_ss_typ_vag,
                                       pr_pc_vag_cfg,
                                       pr_pc_th,
                                       p_cod_verrou,
                                       p_crea_plan,
                                       p_nb_lig_lock,
                                       p_nb_uee_lock);
         IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    /**********************
     DEBUT TRAITEMENT STD
    **********************/
    IF v_ret_evt IS NULL THEN

        -- recup si on doit tenir compte du process des UEE pour locker les UEE
        -- ---------------------------------
        -- Recherche de la valeur de la clef 'PSS_UEE_VAG_AUTO' du process default de l'usine
        v_cod_pss_defaut := su_bas_get_pss_defaut(p_cod_usn);
        v_status := su_bas_rch_cle_atv_pss(v_cod_pss_defaut,
                                          'ORD',            -- Type d'activité
                                          'PSS_UEE_VAG_AUTO',
                                           v_pss_uee_vag_auto);

        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj || ' para. pss_uee_vag_auto=<' || v_pss_uee_vag_auto || '>');
        END IF;

        -- Recherche l'etat d'activité des lignes commandes à verrouiller
        v_etat_atv_lig := su_bas_rch_etat_atv (p_cod_action_atv => 'QUALIF_ORDO',
                                           p_nom_table      => 'PC_LIG_COM');

        -- Recherche l'etat d'activité
        IF p_crea_plan IN ( pc_ordo_pkv.AVEC_CALCUL_PLAN_AVANT_RESA,
                            pc_ordo_pkv.AVEC_CALCUL_PLAN_APRES_RESA,
                            pc_ordo_pkv.AVEC_CALCUL_PLAN_FIN_ORDO) THEN  -- plan a calculer

            v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                               p_cod_action_atv => 'VALIDATION_PLAN',
                                               p_nom_table      => 'PC_UEE');

            v_etat_atv_uee_min := su_bas_rch_etat_atv (
                                               p_cod_action_atv=> 'CREATION',
                                               p_nom_table      => 'PC_UEE');

        ELSE   -- sinon le plan existe déjà
            v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                               p_cod_action_atv => 'VALIDATION_PLAN',
                                               p_nom_table      => 'PC_UEE');

            v_etat_atv_uee_min := v_etat_atv_uee_max;
        END IF;

        -- calcul des limites d'horaires.
        v_dat_heure_deb := TRUNC (SYSDATE + NVL(pr_pc_th.j_deb,0));
        IF NVL (pr_pc_th.delai_sel, 0) > 0 THEN
            v_dat_heure_fin := su_bas_calc_dat_delai (p_dat_ref    => SYSDATE,
                                                      p_mode_calc  => '+',
                                                      p_delai_mi   => pr_pc_th.delai_sel);

        ELSIF pr_pc_th.dat_fin_sel IS NOT NULL THEN
            -- on prendra l'heure limite de sélection si elle est NON NULL et < à la date fin calculée
             v_dat_heure_fin := TO_DATE (TO_CHAR (SYSDATE, 'YYYYMMDD') || TO_CHAR (pr_pc_th.dat_fin_sel, 'HH24MISS'),

                                'YYYYMMDDHH24MISS');

        ELSE
            -- Si delai = 0 alors, heure de fin < heure debut => pas d'ordo
            -- -----------------------------------------------------------------
            v_dat_heure_fin := v_dat_heure_deb - 1;
        END IF;

        v_etape:='  date fin sel ';

        IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || v_etape|| TO_CHAR(v_dat_heure_fin, 'YYYY/MM/DD/HH24:MI:SS'));
        END IF;

        IF v_dat_heure_fin >= v_dat_heure_deb THEN
            -- Trace
            v_etape := 'LOOP sur pc_lig_com: ' || ' etat_atv_lig: ' || v_etat_atv_lig
                      || ' dat_heure_deb: ' || TO_CHAR(v_dat_heure_deb, 'YYYYMMDDHH24MISS')
                      || ' dat_heure_fin: ' || TO_CHAR(v_dat_heure_fin, 'YYYYMMDDHH24MISS');
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || v_etape);
            END IF;

             v_req:='SELECT l.no_com, l.no_lig_com, l.lst_fct_lock
                FROM pc_lig_com l, pc_ent_com e, pc_ent_cmd u
                WHERE l.no_com = e.no_com
                AND l.no_cmd = u.no_cmd
                AND su_bas_select_for_lock (l.id_session_lock) = ''TRUE''
                AND l.etat_atv_pc_lig_com = '''||v_etat_atv_lig||''''||
                'AND l.cod_usn = '''||p_cod_usn||''''||
                'AND l.cod_err_pc_lig_com IS NULL
                AND l.qte_cde > 0
                AND l.etat_autor_ord = ''' || pc_ordo_pkv.AUTOR_ORD_AUTO || ''''||
                ' AND DECODE('''||NVL(pr_pc_vag_cfg.typ_dat_sel,'0')||''',
                                                               ''0'', e.dat_prep,
                                                               ''1'', e.dat_exp,
                                                               ''2'', e.dat_crea, e.dat_prep) >= :DAT_DEB' ||
            ' AND DECODE('''||NVL(pr_pc_vag_cfg.typ_dat_sel,'0')||''',
                                                               ''0'', e.dat_prep,
                                                               ''1'', e.dat_exp,
                                                               ''2'', e.dat_crea, e.dat_prep) <= :DAT_FIN';


            v_etape := 'Récupération clause spécifique vague';
            IF pr_pc_vag_cfg.txt_where = 'ERROR' THEN
                RAISE err_except;
            END IF;

            v_req := v_req || pr_pc_vag_cfg.txt_where
                       || ' ORDER BY NVL(e.dat_prep, e.dat_dem) ASC, e.no_com ASC
                            FOR UPDATE OF l.lst_fct_lock';

            -- Execution dynamique du curseur de recherche
            v_etape := 'su_bas_open';
            v_crs := su_plsql_pkg.su_bas_open;
            v_select.DELETE;

            su_plsql_pkg.su_bas_add_code(v_select, v_req);

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' Select = ');
                su_plsql_pkg.su_bas_debug(v_select);
            END IF;

            v_etape := 'Parse du select';
            su_plsql_pkg.su_bas_parse(v_select, v_crs);

            v_etape := 'Bind des variables';
            su_plsql_pkg.su_bas_bind_date (v_crs,':DAT_DEB', v_dat_heure_deb);
            su_plsql_pkg.su_bas_bind_date (v_crs,':DAT_FIN', v_dat_heure_fin);

            v_etape := 'Define colonne';
            dbms_sql.define_column(v_crs, 1, v_no_com, 20);
            dbms_sql.define_column(v_crs, 2, v_no_lig_com);
            dbms_sql.define_column(v_crs, 3, v_lst_fct_lock, 200);

            v_etape := 'Execute curseur';
            su_plsql_pkg.su_bas_execute(v_crs);
            LOOP
                v_etape := 'Fetch curseur';
                v_result_fetch := su_plsql_pkg.su_bas_fetch(v_crs);
                EXIT WHEN v_result_fetch <= 0;

                v_etape := 'Récup varible retour';
                dbms_sql.column_value(v_crs, 1, v_no_com);
                dbms_sql.column_value(v_crs, 2, v_no_lig_com);
                dbms_sql.column_value(v_crs, 3, v_lst_fct_lock);

                -- Test si paramétrage d'un nb de commandes max
                IF NVL(pr_pc_vag_cfg.nb_com_max, 0) > 0 THEN      -- on doit comptabiliser le nb de commandes
                    IF v_no_com_ec IS NULL OR v_no_com_ec <> v_no_com THEN
                        v_no_com_ec := v_no_com;
                        v_nb_com := v_nb_com +1;
                    END IF;

                    IF v_nb_com > NVL(pr_pc_vag_cfg.nb_com_max,0) THEN
                        EXIT;       -- On sort
                    END IF;
                END IF;

                v_etape := 'On pose le verrou';
                UPDATE pc_lig_com l SET
                     lst_fct_lock = su_bas_lock (p_cod_verrou, l.lst_fct_lock, l.id_session_lock)
                WHERE no_com = v_no_com
                AND no_lig_com = v_no_lig_com;

                -- Cummul du nb de ligne lockée
                p_nb_lig_lock := NVL(p_nb_lig_lock, 0) +1;

                v_etape := 'On pose un verrou sur PC_UEE';
                UPDATE pc_uee u SET
                    u.lst_fct_lock = su_bas_lock (p_cod_verrou, u.lst_fct_lock, u.id_session_lock)
                WHERE  su_bas_select_for_lock (u.id_session_lock) = 'TRUE'             AND
                       INSTR(u.lst_fct_lock, ';'||p_cod_verrou||';') IS NULL             AND
                       u.etat_atv_pc_uee IN (SELECT *
                                             FROM TABLE(su_bas_list_etat_atv(v_etat_atv_uee_min, v_etat_atv_uee_max,'PC_UEE'))) AND
                       u.cod_err_pc_uee  IS NULL                                         AND
                       u.no_uee IN (SELECT no_uee ud
                                      FROM pc_uee_det ud
                                     WHERE ud.cod_err_pc_uee_det IS NULL                  AND
                                           ud.no_com     = v_no_com               AND
                                           ud.no_lig_com = v_no_lig_com)
                                     AND
                                     (
                                        (
                                        su_bas_lst_cod_compare(NVL(pr_pc_vag_cfg.lst_cod_pss,'*'), u.cod_pss_afc) > 0
                                        AND su_bas_lst_cod_compare(NVL(pr_pc_vag_cfg.lst_cod_grp_pss,'*'), su_bas_gcl_su_pss(u.cod_pss_afc, 'COD_GRP_PSS')) > 0

                                        )
                                      OR
                                    NVL(v_pss_uee_vag_auto, '0') = '0'
                                    );
                rowcountuee := SQL%ROWCOUNT;

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    v_etape := 'Ligne '|| v_no_com ||'-'|| v_no_lig_com || 'Nbre d''UEE lockees: ' || TO_CHAR(rowcountuee);
                    su_bas_put_debug(v_nom_obj || v_etape);
                END IF;

                -- Cummul du nb de colis lockés
                p_nb_uee_lock := NVL(p_nb_uee_lock, 0) + rowcountuee;
            END LOOP;
            v_etape := 'Close curseur';
            su_plsql_pkg.su_bas_close(v_crs);
        END IF;
    END IF;  -- IF v_ret_evt IS NULL THEN
    /********************
     FIN TRAITEMENT STD
    ********************/

    /**********************
    3) PHASE FINALISATION
    *********************/
    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_PC_ORDO_SEL_VAG_AUTO') THEN
        v_ret_evt := pc_evt_ordo_select_vag_auto( 'POST',
                                       p_cod_usn,
                                       p_typ_vag,
                                       p_ss_typ_vag,
                                       pr_pc_vag_cfg,
                                       pr_pc_th,
                                       p_cod_verrou,
                                       p_crea_plan,
                                       p_nb_lig_lock,
                                       p_nb_uee_lock);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /***************
    -- ON commit;
    ***************/
    v_etape := 'ON commit';
    COMMIT;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        su_plsql_pkg.su_bas_close(v_crs);

        ROLLBACK TO my_sp_pc_bas_select_vag;
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_select_vag_manu -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet d'effectuer la sélection de ligne commandes
-- sur une usine passée en paramètre et suivant la configuration de la vague
-- en mode MANUEL
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_typ_vag    : type de vague
--  p_ss_typ_vag : sous type de vague
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
-- OUI

FUNCTION pc_bas_select_vag_manu (p_cod_usn         su_usn.cod_usn%TYPE,
                                p_typ_vag          pc_vag.typ_vag%TYPE,
                                p_ss_typ_vag       pc_vag.ss_typ_vag%TYPE,
                                pr_pc_vag_cfg      pc_vag%ROWTYPE,
                                pr_pc_th           pc_th%ROWTYPE,
                                p_cod_verrou       VARCHAR2,
                                p_crea_plan        VARCHAR2,
                                p_nb_lig_lock IN OUT NUMBER,
                                p_nb_uee_lock IN OUT NUMBER
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_select_vag_manu:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;
    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- déclarations de variables
    v_no_com_ec     pc_ent_com.no_com%TYPE := NULL;
    v_nb_com        NUMBER(10) := 0;

    v_lst_etat_atv_lig  VARCHAR2(1000);
    v_etat_atv_rstk     pc_rstk.etat_atv_pc_rstk%TYPE;
    v_etat_atv_uee_min  VARCHAR2(20);
    v_etat_atv_uee_max  VARCHAR2(20);

    rowcountlig     NUMBER(10) := 0;
    rowcountuee     NUMBER(10) := 0;


    -- Déclarations des curseurs
    -- --------------------------
    -- Curseur FOR UPDATE sur PC_LIG_COM
    CURSOR c_lig_com ( x_lst_etat_atv_lig  pc_lig_com.etat_atv_pc_lig_com%TYPE,
                       x_etat_atv_rstk     pc_rstk.etat_atv_pc_rstk%TYPE) IS
    SELECT l.no_com, l.no_lig_com, l.lst_fct_lock verrou_lig,
           rs.id_res, rs.ref_rstk_1, rs.ref_rstk_2, rs.ref_rstk_3,
           rs.ref_rstk_4, rs.ref_rstk_5, rs.lst_fct_lock verrou_rstk
    FROM pc_lig_com l, pc_ent_com e, pc_rstk rs
    WHERE e.no_com = rs.ref_rstk_1                                                AND
          e.no_com = l.no_com                                                     AND
          l.no_lig_com = pc_bas_to_number(rs.ref_rstk_2)                          AND
          su_bas_select_for_lock (l.id_session_lock) = 'TRUE'                     AND
          INSTR(x_lst_etat_atv_lig, ';' ||  l.etat_atv_pc_lig_com || ';') > 0     AND
          l.cod_usn = p_cod_usn                                                   AND
          l.cod_err_pc_lig_com IS NULL                                            AND
          l.qte_cde > 0                                                           AND
          l.etat_autor_ord != pc_ordo_pkv.INTERDIT_ORD                            AND  -- != '0' => ( '1' ou '2')
          su_bas_select_for_lock (rs.id_session_lock) = 'TRUE'                    AND
          rs.etat_atv_pc_rstk = x_etat_atv_rstk                                   AND
          rs.cod_err_pc_rstk IS NULL
    ORDER BY NVL(e.dat_prep, e.dat_dem) ASC, e.no_com ASC, l.no_lig_com ASC
    FOR UPDATE OF l.lst_fct_lock, rs.lst_fct_lock;

    r_lig_com   c_lig_com%ROWTYPE;

BEGIN

    -- on dépose un SAVEPOINT
    SAVEPOINT my_sp_pc_bas_sel_vag_manu;

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;

            /************************
            1) PHASE INITIALISATION
            ************************/
    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_PC_ORDO_SEL_VAG_MANU') THEN
        v_ret_evt := pc_evt_ordo_select_vag_manu( 'PRE',
                                       p_cod_usn,
                                       p_typ_vag,
                                       p_ss_typ_vag,
                                       pr_pc_vag_cfg,
                                       pr_pc_th,
                                       p_cod_verrou,
                                       p_crea_plan,
                                       p_nb_lig_lock,
                                       p_nb_uee_lock);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;
            /********************
             2) PHASE TRAITEMENT
            ********************/
    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_PC_ORDO_SEL_VAG_MANU') THEN
        v_ret_evt := pc_evt_ordo_select_vag_manu( 'ON',
                                       p_cod_usn,
                                       p_typ_vag,
                                       p_ss_typ_vag,
                                       pr_pc_vag_cfg,
                                       pr_pc_th,
                                       p_cod_verrou,
                                       p_crea_plan,
                                       p_nb_lig_lock,
                                       p_nb_uee_lock);
         IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    /**********************
     DEBUT TRAITEMENT STD
    **********************/
    IF v_ret_evt IS NULL THEN

        -- Recherche l'etat d'activité des lignes commandes à verrouiller
        v_lst_etat_atv_lig := ';';
        v_lst_etat_atv_lig :=  v_lst_etat_atv_lig ||
                               su_bas_rch_etat_atv (p_cod_action_atv    => 'QUALIF_ORDO',
                                                    p_nom_table         => 'PC_LIG_COM') || ';';

        v_lst_etat_atv_lig :=  v_lst_etat_atv_lig ||
                               su_bas_rch_etat_atv (p_cod_action_atv    => 'VALIDATION_ORDO_MAN',
                                                    p_nom_table         => 'PC_LIG_COM') || ';';

        -- Recherche l'etat d'activité des resas effectuée en MANUEL
        v_etat_atv_rstk := su_bas_rch_etat_atv (p_cod_action_atv    => 'RESA_MANU',
                                                p_nom_table         => 'PC_RSTK');

        -- Recherche l'etat d'activité des PC_UEE à verrouiller
        -- si SANS CALCUL => le calul a déjà été fait au pré-ordo
        IF p_crea_plan IN ( pc_ordo_pkv.AVEC_CALCUL_PLAN_AVANT_RESA,
                            pc_ordo_pkv.AVEC_CALCUL_PLAN_APRES_RESA,
                            pc_ordo_pkv.AVEC_CALCUL_PLAN_FIN_ORDO) THEN  -- plan a calculer

            v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                               p_cod_action_atv => 'VALIDATION_PLAN',
                                               p_nom_table      => 'PC_UEE');

            v_etat_atv_uee_min := su_bas_rch_etat_atv (
                                               p_cod_action_atv=> 'CREATION',
                                               p_nom_table      => 'PC_UEE');

        ELSE   -- sinon le plan existe déjà
            v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                               p_cod_action_atv => 'VALIDATION_PLAN',
                                               p_nom_table      => 'PC_UEE');

            v_etat_atv_uee_min := v_etat_atv_uee_max;
        END IF;

        v_etape := 'LOOP sur pc_lig_com';
        OPEN c_lig_com (v_lst_etat_atv_lig, v_etat_atv_rstk);
        LOOP
            FETCH c_lig_com INTO r_lig_com;
            EXIT WHEN c_lig_com%NOTFOUND;

            IF v_no_com_ec IS NULL OR v_no_com_ec <> r_lig_com.no_com THEN
                v_no_com_ec := r_lig_com.no_com;
                v_nb_com := v_nb_com +1;
            END IF;

            -- Test si paramétrage d'un nb de commandes max
            IF NVL(pr_pc_vag_cfg.nb_com_max, 0) > 0 AND      -- on doit comptabiliser le nb de commandes
                v_nb_com > pr_pc_vag_cfg.nb_com_max THEN
                EXIT;       -- On sort
            END IF;

            v_etape := 'On pose un verrou sur PC_RSTK id_res: '|| r_lig_com.id_res;
            UPDATE pc_rstk rs SET
                lst_fct_lock = su_bas_lock (p_cod_verrou, rs.lst_fct_lock, rs.id_session_lock)
            WHERE rs.id_res = r_lig_com.id_res AND
                INSTR(rs.lst_fct_lock, ';'||p_cod_verrou||';') IS NULL;

            v_etape := 'On pose un verrou sur PC_LIG_COM Com-lig: ' ||
                       r_lig_com.no_com || '-' || r_lig_com.no_lig_com;
            UPDATE pc_lig_com l SET
                lst_fct_lock = su_bas_lock (p_cod_verrou, l.lst_fct_lock, l.id_session_lock)
            WHERE l.no_com     = r_lig_com.no_com AND
                l.no_lig_com = r_lig_com.no_lig_com AND
                INSTR(l.lst_fct_lock, ';'||p_cod_verrou||';') IS NULL;

            rowcountlig := SQL%ROWCOUNT;

            -- Cumul du nb de ligne lockées
            p_nb_lig_lock := NVL(p_nb_lig_lock, 0) + rowcountlig;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || 'Lock ' || TO_CHAR(p_nb_lig_lock) || ' LIG lockees');
            END IF;

            UPDATE pc_uee u SET
                 u.lst_fct_lock = su_bas_lock (p_cod_verrou, u.lst_fct_lock, u.id_session_lock)
            WHERE  su_bas_select_for_lock (u.id_session_lock) = 'TRUE'                AND
                   INSTR(u.lst_fct_lock, ';'||p_cod_verrou||';') IS NULL              AND
                   u.etat_atv_pc_uee IN (SELECT *
                                         FROM TABLE(su_bas_list_etat_atv(v_etat_atv_uee_min, v_etat_atv_uee_max,'PC_UEE'))) AND
                   u.cod_err_pc_uee  IS NULL                                          AND
                   (u.cod_up = r_lig_com.ref_rstk_4 OR r_lig_com.ref_rstk_4 IS NULL)  AND
                   (u.typ_up = r_lig_com.ref_rstk_5 OR r_lig_com.ref_rstk_5 IS NULL)  AND
                   u.no_uee IN (SELECT no_uee ud
                                FROM pc_uee_det ud
                                WHERE ud.cod_err_pc_uee_det IS NULL                  AND
                                      ud.no_com     = r_lig_com.no_com               AND
                                      ud.no_lig_com = r_lig_com.no_lig_com)          AND
                   NOT EXISTS (SELECT 1
                                FROM pc_uee_det ud, pc_lig_com lc
                                WHERE ud.no_com = lc.no_com AND ud.no_lig_com = lc.no_lig_com AND
                                      ud.no_uee = u.no_uee AND
                                      su_bas_etat_val_num(ud.etat_atv_pc_uee_det,'PC_UEE_DET') <    -- $MOD,patch,21160
                                      su_bas_etat_val_num('PREPARATION_NULLE','PC_UEE_DET') AND
                                      (NVL(INSTR(lc.lst_fct_lock,';'||p_cod_verrou||';'),0) = 0 OR
                                       lc.id_session_lock <> v_session_ora));
            rowcountuee := SQL%ROWCOUNT;

            -- Cummul du nb de colis lockés
            p_nb_uee_lock := NVL(p_nb_uee_lock, 0) + rowcountuee;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || 'Lock ' || TO_CHAR(p_nb_uee_lock) || ' UEE lockees');
            END IF;


        END LOOP;
        CLOSE c_lig_com;
    END IF;     -- IF v_ret_evt IS NULL THEN
    /********************
     FIN TRAITEMENT STD
    ********************/

    /**********************
    3) PHASE FINALISATION
    *********************/
    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_PC_ORDO_SEL_VAG_MANU') THEN
        v_ret_evt := pc_evt_ordo_select_vag_manu( 'POST',
                                       p_cod_usn,
                                       p_typ_vag,
                                       p_ss_typ_vag,
                                       pr_pc_vag_cfg,
                                       pr_pc_th,
                                       p_cod_verrou,
                                       p_crea_plan,
                                       p_nb_lig_lock,
                                       p_nb_uee_lock);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /***************
    -- ON commit;
    ***************/
    COMMIT;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        IF c_lig_com%ISOPEN THEN
            CLOSE c_lig_com;
        END IF;

        ROLLBACK TO my_sp_pc_bas_sel_vag_manu;
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_cal_lst_mag_par_groupe
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de calculer la liste des magasins entrant dans
-- la configuration d'un générique et applique a un process final
-- d'une palette
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,05.10.10,mnev    ajoution no_grp dans su_lst_pss
-- 01c,05.10.10,mnev    evite les doublon dans la liste
-- 01b,29.12.09,mnev    gestion du $CDE
-- 01a,24.09.09,mnev    creation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- ---------
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_cal_lst_mag_par_groupe (p_cod_pss_afc          su_lst_pss.cod_pss%TYPE,
                                        p_cod_pss_final        su_lst_pss.cod_pss%TYPE,
                                        p_no_grp               su_pss_mag.no_grp%TYPE,
                                        p_typ_prk              su_lst_pss.typ_prk%TYPE,
                                        p_cod_cfg_rstk         su_lst_pss.cod_cfg_rstk%TYPE,
                                        p_pct_qte_min_pal_res  su_lst_pss.pct_qte_min_pal_res%TYPE,
                                        p_pct_qte_max_pal_res  su_lst_pss.pct_qte_max_pal_res%TYPE,
                                        p_mode_lst_rch         su_lst_pss.mode_lst_rch%TYPE,
                                        p_having_ges_qte       su_lst_pss.having_ges_qte%TYPE,
                                        p_mode_res             VARCHAR2)
RETURN VARCHAR2 DETERMINISTIC IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_cal_lst_mag_par_groupe';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclaration des curseurs
    -- ------------------------
    v_lst_mag_frc       VARCHAR2(1000) := NULL;

    -- Curseur de recherche de magasins du meme groupe
    CURSOR c_mag (x_cod_pss           su_pss_mag.cod_pss%TYPE,
                  x_cod_pss_final     su_pss_mag.cod_pss%TYPE,
                  x_no_grp            su_pss_mag.no_grp%TYPE,
                  x_typ_prk           su_pss_mag.typ_prk%TYPE,
                  x_cod_cfg_rstk      su_lst_pss.cod_cfg_rstk%TYPE,
                  x_qte_min           su_lst_pss.pct_qte_min_pal_res%TYPE,
                  x_qte_max           su_lst_pss.pct_qte_min_pal_res%TYPE,
                  x_mode_rch          su_lst_pss.mode_lst_rch%TYPE) IS
       SELECT pm.cod_mag, pm.no_ord_grp
       FROM su_pss_mag pm, su_lst_pss lp, su_pss_mag c
       WHERE pm.cod_pss = x_cod_pss AND
              lp.cod_pss_final = x_cod_pss_final AND
              (pm.autor_res_auto = '1' OR p_mode_res = 'MANU') AND
              (pm.typ_prk = x_typ_prk OR x_typ_prk IS NULL) AND
              lp.cod_pss = pm.cod_pss AND
              lp.cod_mag = pm.cod_mag AND
              lp.typ_prk = pm.typ_prk AND
              lp.no_grp  = pm.no_grp AND
              (lp.cod_cfg_rstk = x_cod_cfg_rstk OR x_cod_cfg_rstk IS NULL) AND
              (lp.pct_qte_min_pal_res = x_qte_min OR x_qte_min IS NULL) AND
              (lp.pct_qte_max_pal_res = x_qte_max OR x_qte_max IS NULL) AND
              (lp.mode_lst_rch = x_mode_rch OR x_mode_rch IS NULL) AND
              c.cod_pss     = lp.cod_pss_final AND
              c.cod_mag     = pm.cod_mag AND
              c.typ_prk     = pm.typ_prk AND
              c.etat_cfg_stk_pic <> '2' AND
              pm.no_grp = x_no_grp
       GROUP BY pm.cod_mag, pm.no_ord_grp
       ORDER BY pm.no_ord_grp;

    r_mag c_mag%ROWTYPE;

BEGIN

    v_etape := 'Debut trait: ';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                   ' p_cod_pss_afc: ' || p_cod_pss_afc ||
                   ' p_cod_pss_final: ' || p_cod_pss_final ||
                   ' p_no_grp: '     || TO_CHAR(p_no_grp) ||
                   ' p_typ_prk: ' || p_typ_prk);
    END IF;

    v_etape := 'Contruire liste mag du groupe';
    OPEN c_mag (p_cod_pss_afc,
                p_cod_pss_final,
                p_no_grp,
                p_typ_prk,
                p_cod_cfg_rstk,
                p_pct_qte_min_pal_res,
                p_pct_qte_max_pal_res,
                p_mode_lst_rch);
    LOOP
        FETCH c_mag INTO r_mag;
        EXIT WHEN c_mag%NOTFOUND;

        IF INSTR(NVL(v_lst_mag_frc,'?'), r_mag.cod_mag) = 0 THEN
            v_lst_mag_frc := NVL(v_lst_mag_frc,';') || r_mag.cod_mag || ';';
        END IF;

    END LOOP;
    CLOSE c_mag;

    v_etape := 'Valeur de retour: ';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                         ' v_lst_mag_frc : ' || v_lst_mag_frc);

    END IF;

    RETURN v_lst_mag_frc;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_pss',
                        p_par_ano_1       => p_cod_pss_afc,
                        p_lib_ano_2       => 'cod_pss_f',
                        p_par_ano_2       => p_cod_pss_final,
                        p_lib_ano_3       => 'no_grp',
                        p_par_ano_3       => TO_CHAR(p_no_grp),
                        p_lib_ano_4       => 'typ_prk',
                        p_par_ano_4       => p_typ_prk,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN NULL;
END;

/****************************************************************************
*   pc_bas_crea_uee_id_res_2 -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de créer des colis en fonction d'une
-- réservation ferme. i
-- Pour une réservation, identifiée par (no_rstk,id_res),
-- il n'est possible de créer qu'un type de colis (CC ou CD)
-- mais pas les 2.
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03a,02.08.11,mnev    Appel depuis pc_bas_resa_stk au lieu de distribution
--                      => les données initiales ne sont plus les mêmes.
-- 02b,15.03.11,mnev    Arrangements
-- 02a,03.02.11,mnev    Gestion cod_vet cod_vet_cd
-- 01a,10.01.11,RLEB    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRES :
-- ----------
--  pr_ent_rstk  : record de reservation de SE
--  p_ref_rstk_x : cle de reference qui seront à insérer dans pc_rstk après la création
--  p_cod_pss    : code du process final
--  p_qte_deres  : quantité déreservée dans l'unité de la demande
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--  NON

FUNCTION pc_bas_crea_uee_id_res_2 (pr_ent_rstk  IN OUT se_ent_rstk%ROWTYPE,
                                   p_ref_rstk_1 IN OUT pc_rstk.ref_rstk_1%TYPE,
                                   p_ref_rstk_2 IN OUT pc_rstk.ref_rstk_2%TYPE,
                                   p_ref_rstk_3 IN OUT pc_rstk.ref_rstk_3%TYPE,
                                   p_ref_rstk_4 IN OUT pc_rstk.ref_rstk_4%TYPE,
                                   p_ref_rstk_5 IN OUT pc_rstk.ref_rstk_5%TYPE,
                                   p_cod_pss    IN     pc_uee.cod_pss_afc%TYPE,
                                   p_qte_deres  OUT pc_rstk.qte_res%TYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_crea_uee_id_res_2:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclarations de variables
    -----------------------------
   v_status             VARCHAR2(20);
   v_cre_uee            VARCHAR2(3) := 'NON';
   v_no_uee             pc_uee.no_uee%TYPE;
   v_etat_atv_rstk      pc_rstk.etat_atv_pc_rstk%TYPE;
   v_typ_uee            pc_uee.typ_uee%TYPE;
   v_pds_1C             pc_uee.pds_theo%TYPE;
   v_qte_vol_1C         pc_uee.vol_theo%TYPE;
   v_qte_1C             pc_uee_det.qte_theo%TYPE;
   v_nb_pce_1C          pc_uee_det.nb_pce_theo%TYPE;
   v_pds_theo           pc_uee.pds_theo%TYPE;
   v_qte_theo           pc_uee_det.qte_theo%TYPE;
   v_qte_en_cc          pc_uee_det.qte_theo%TYPE;
   v_qte_en_cd          pc_uee_det.qte_theo%TYPE;
   v_nb_pce_theo        pc_uee_det.nb_pce_theo%TYPE;
   v_qte_vol_theo       pc_uee.vol_theo%TYPE;
   v_qte_ub             pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_ul             pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_pds            pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_pce            pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_colis          pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_pal            pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_vol            pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_unit_cde       pc_rstk_det.qte_res%TYPE := NULL;
   v_qte_unit_2         pc_rstk_det.qte_res%TYPE := NULL;
   v_unit_stk_2         pc_rstk_det.unit_res%TYPE := NULL;
   v_qte                pc_uee_det.qte_theo%TYPE;
   v_nb_colis           NUMBER;
   v_mod_nb_colis       NUMBER;
   v_qte_a_dereserver   NUMBER:=0;
   v_cod_cnt            pc_uee.cod_cnt%TYPE:=NULL;
   v_pcb_ul             su_ul.pcb%TYPE;

   vr_uee               pc_uee%ROWTYPE;
   vr_uee_det           pc_uee_det%ROWTYPE;

    -- Déclarations des curseurs
    -- --------------------------

    -- permet de savoir s'il a une une resa à traiter
    CURSOR c_res (x_id_res pc_rstk.id_res%TYPE) IS
        SELECT 1
        FROM se_ent_rstk s
        WHERE s.no_rstk = x_id_res;

    r_res     c_res%ROWTYPE;
    found_res BOOLEAN;

    -- permet de savoir s'il existe une UEE de référence pour ligne commande.
    CURSOR c_ueeref (x_no_com pc_uee_det.no_com%TYPE, x_no_lig_com pc_uee_det.no_lig_com%TYPE) IS
        SELECT u.*
        FROM pc_uee u, pc_uee_det d
        WHERE d.no_com = x_no_com
          AND d.no_lig_com = x_no_lig_com
          AND d.no_uee = u.no_uee
          AND u.no_uee=nvl(u.no_uee_ref,'#NULL#'); -- colis de référence

    found_ueeref BOOLEAN;
    r_ueeref     c_ueeref%ROWTYPE;

    CURSOR c_ueedetref (x_no_uee pc_uee_det.no_uee%TYPE,
                        x_no_com pc_uee_det.no_com%TYPE,
                        x_no_lig_com pc_uee_det.no_lig_com%TYPE) IS
        SELECT *
        FROM pc_uee_det
        WHERE no_uee = x_no_uee
          AND no_com = x_no_com
          AND no_lig_com = x_no_lig_com;

    found_ueedetref BOOLEAN;
    r_ueedetref     c_ueedetref%ROWTYPE;

    -- lecture des variantes de traitements
    CURSOR c_lig (x_no_com     pc_lig_com.no_com%TYPE,
                  x_no_lig_com pc_lig_com.no_lig_com%TYPE) IS
        SELECT cod_vet, cod_vet_cd, cod_vedoc_ofs, cod_vedoc_mqe,
               cod_vedoc_pce_1, cod_vedoc_pce_2,
               cod_vedoc_col_1, cod_vedoc_col_2,
               cod_vedoc_col_1_cd, cod_vedoc_col_2_cd,
               cod_ved
        FROM pc_lig_com
        WHERE no_com = x_no_com AND no_lig_com = x_no_lig_com;

    r_lig       c_lig%ROWTYPE;
    v_found_lig BOOLEAN;

    --permet d'effacer un ancien colis créé pour la commande, sans résa.
    --il ne faut pas effacer ceux qui dispose de résa!!!
    CURSOR c_ueevide (x_no_com pc_uee_det.no_com%TYPE,
                      x_no_lig_com pc_uee_det.no_lig_com%TYPE) IS
        SELECT u.*
        FROM pc_uee u,pc_uee_det ud
        WHERE u.no_uee=ud.no_uee
          AND ud.no_com = x_no_com
          AND ud.no_lig_com = x_no_lig_com
          AND u.no_uee <> nvl(u.no_uee_ref,'#NULL#')
          AND u.etat_atv_pc_uee = 'CREA'
          AND ud.id_res IS NULL;

    r_ueevide c_ueevide%ROWTYPE;

    CURSOR c_ueedetvide (x_no_uee pc_uee.no_uee%TYPE) IS
        SELECT *
        FROM pc_uee_det
        WHERE no_uee = x_no_uee;

    r_ueedetvide c_ueedetvide%ROWTYPE;

    CURSOR c_stkres (x_id_res pc_rstk.id_res%TYPE) IS
        SELECT a.unit_res, b.no_rstk, b.no_stk, b.qte_res, b.cod_pro, b.cod_va, b.cod_vl
        FROM se_ent_rstk a, se_lig_rstk b
        WHERE b.no_rstk = x_id_res AND b.no_rstk = a.no_rstk;

    found_stkres BOOLEAN;
    r_stkres     c_stkres%ROWTYPE;

    CURSOR c_stk (x_no_stk se_stk.no_stk%TYPE) IS
        SELECT *
        FROM se_stk
        WHERE no_stk=x_no_stk AND qte_unit_1 > 0;

    found_stk BOOLEAN;
    r_stk     c_stk%ROWTYPE;

    CURSOR c_ueecd (x_no_com pc_uee_det.no_com%TYPE) IS
        SELECT u.no_uee
        FROM pc_uee u, pc_uee_det d
        WHERE d.no_com = x_no_com
          AND d.no_uee = u.no_uee
          AND u.typ_uee = 'CD'
          AND u.no_uee <> nvl(u.no_uee_ref,'#NULL#')
          AND d.etat_atv_pc_uee_det = 'CREA';

    r_ueecd c_ueecd%ROWTYPE;

    CURSOR c_ueedetcd (x_no_uee pc_uee_det.no_uee%TYPE,
                       x_no_com pc_uee_det.no_com%TYPE,
                       x_no_lig_com pc_uee_det.no_lig_com%TYPE) IS
        SELECT 1
        FROM pc_uee u, pc_uee_det d
        WHERE d.no_uee = x_no_uee
          AND d.no_com = x_no_com
          AND d.no_lig_com = x_no_lig_com
          AND d.no_uee = u.no_uee
          AND u.typ_uee = 'CD'
          AND u.no_uee <> nvl(u.no_uee_ref,'#NULL#')
          AND d.etat_atv_pc_uee_det = 'CREA';

    r_ueedetcd     c_ueedetcd%ROWTYPE;
    found_ueedetcd BOOLEAN;

    CURSOR c_cod_up (x_no_uee pc_uee.no_uee%TYPE) IS
    SELECT cod_up
        FROM pc_uee
        WHERE no_uee=x_no_uee;

    r_cod_up c_cod_up%ROWTYPE;

    r_vet_usn       v_vet_usn%ROWTYPE;
    v_cod_vet_cc    v_vet_usn.cod_vet%TYPE;
    v_cod_vet_cd    v_vet_usn.cod_vet%TYPE;
    v_id_res        pc_rstk.id_res%TYPE;
    v_info_qte_1    NUMBER := 0;
    v_info_qte_cc   NUMBER := 0;
    v_info_qte_cd   NUMBER := 0;

BEGIN

    SAVEPOINT my_pc_bas_crea_uee_id_res;  -- Pour la gestion de l'exception on fixe un point de rollback.

    p_qte_deres := 0;

    v_etape := 'Debut trait. pc_bas_crea_uee_id_res:' || pr_ent_rstk.no_rstk;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
        su_bas_put_debug(v_nom_obj || ' ref_rstk_1:' || p_ref_rstk_1);
        su_bas_put_debug(v_nom_obj || ' ref_rstk_2:' || p_ref_rstk_2);
        su_bas_put_debug(v_nom_obj || ' ref_rstk_3:' || p_ref_rstk_3);
        su_bas_put_debug(v_nom_obj || ' ref_rstk_4:' || p_ref_rstk_4);
        su_bas_put_debug(v_nom_obj || ' ref_rstk_5:' || p_ref_rstk_5);
    END IF;

    v_id_res := pr_ent_rstk.no_rstk;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||' v_id_res:' || v_id_res);
    END IF;

    -- réservation temporaire existe?
    v_etape := 'open c_res';
    OPEN c_res (v_id_res);
    FETCH c_res INTO r_res;
    found_res := c_res%FOUND;
    CLOSE c_res;

    -- uee de référence existe t-il?
    v_etape := 'open c_ueeref';
    OPEN c_ueeref(p_ref_rstk_1, pc_bas_to_number(p_ref_rstk_2));
    FETCH c_ueeref INTO r_ueeref;
    found_ueeref := c_ueeref%FOUND;
    CLOSE c_ueeref;

    -- uee det de référence existe t-il?
    v_etape := 'open c_ueedetref';
    OPEN c_ueedetref (r_ueeref.no_uee, p_ref_rstk_1, pc_bas_to_number(p_ref_rstk_2));
    FETCH c_ueedetref INTO r_ueedetref;
    found_ueedetref := c_ueedetref%FOUND;
    CLOSE c_ueedetref;

    v_etape := 'open c_lig';
    OPEN c_lig (p_ref_rstk_1, pc_bas_to_number(p_ref_rstk_2));
    FETCH c_lig INTO r_lig;
    v_found_lig := c_lig%FOUND;
    CLOSE c_lig;

    IF found_res AND found_ueeref AND found_ueedetref AND v_found_lig THEN

        ----------------------------------------------
        --1: contrôle si il n'existe pas des uee vides
        --   (uee sans réservations)
        ----------------------------------------------
        v_etape := 'open c_ueevide';
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' ' || v_etape);
        END IF;

        OPEN c_ueevide (p_ref_rstk_1,pc_bas_to_number(p_ref_rstk_2));
        LOOP
            FETCH c_ueevide INTO r_ueevide;
            EXIT WHEN c_ueevide%NOTFOUND;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
               su_bas_put_debug(v_nom_obj || ' no_uee vide:'||r_ueevide.no_uee);
            END IF;

            -- on reconstruit le colis de référence avant suppression de l'uee vide
            v_etape := 'MAJ pc_uee reference';
            UPDATE pc_uee SET
                nb_pce_theo = nb_pce_theo + r_ueevide.nb_pce_theo,
                pds_theo    = pds_theo + r_ueevide.pds_theo,
                vol_theo    = vol_theo + r_ueevide.vol_theo
            WHERE no_uee = r_ueeref.no_uee;

            OPEN c_ueedetvide (r_ueevide.no_uee);
            LOOP
                FETCH c_ueedetvide INTO r_ueedetvide;
                EXIT WHEN c_ueedetvide%NOTFOUND;

                v_etape := 'Maj UEE det de référence';
                UPDATE pc_uee_det SET
                    qte_theo = qte_theo + r_ueedetvide.qte_theo,
                    nb_pce_theo = nb_pce_theo + r_ueedetvide.nb_pce_theo,
                    pds_theo = pds_theo + r_ueedetvide.pds_theo
                WHERE no_uee = r_ueedetref.no_uee AND
                      no_com = r_ueedetref.no_com AND no_lig_com = r_ueedetref.no_lig_com;
            END LOOP;
            CLOSE c_ueedetvide;

            v_etape := 'Efface UEE_DET';
            DELETE FROM pc_uee_det
                WHERE no_uee = r_ueevide.no_uee;

            v_etape := 'Efface UEE';
            DELETE FROM pc_uee
                WHERE no_uee = r_ueevide.no_uee;

        END LOOP;
        CLOSE c_ueevide;

        -------------------------------------------------------
        --2: boucle sur le stock réservé pour l'id_res en cours
        -------------------------------------------------------
        v_etape := 'boucle sur le stock reserve';
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' ' ||v_etape);
        END IF;

        FOR r_stkres IN c_stkres(v_id_res) LOOP

            IF su_global_pkv.v_niv_dbg >= 6 THEN
               su_bas_put_debug(v_nom_obj || ' no_rstk: '||r_stkres.no_rstk||' / no_stk: '||r_stkres.no_stk);
            END IF;

            v_qte_en_cc        := 0;
            v_qte_en_cd        := 0;
            v_qte_a_dereserver := 0;

            --
            -- Verifie si sous type process impose un type d'UEE
            --
            v_typ_uee := su_bas_gcl_su_lig_par(p_nom_par  =>'SS_TYP_PSS',
                                               p_par       =>su_bas_gcl_su_pss(p_cod_pss, 'SS_TYP_PSS'),
                                               p_cod_module=>'SU',
                                               p_etat_spec =>'0',
                                               p_colonne   =>'ACTION_LIG_PAR_2');

            IF v_typ_uee = 'CC' THEN
                -- tout en colis complet
                v_qte_en_cc := r_stkres.qte_res;

            ELSIF v_typ_uee = 'CD' THEN
                -- tout en colis detail
                v_qte_en_cd := r_stkres.qte_res;

            ELSE
                --
                -- Verifie si type de la VL reservée impose un type d'UEE
                --
                v_etape := 'calcul du type UEE';
                v_typ_uee := su_bas_gcl_su_lig_par(p_nom_par  =>'TYP_UL',
                                                   p_par       =>su_bas_gcl_su_ul(r_stkres.cod_pro,r_stkres.cod_vl, 'TYP_UL'),
                                                   p_cod_module=>'SU',
                                                   p_etat_spec =>'0',
                                                   p_colonne   =>'ACTION_LIG_PAR_3');

                IF v_typ_uee = 'CC' THEN
                    -- tout en colis complet
                    v_qte_en_cc := r_stkres.qte_res;

                ELSIF v_typ_uee = 'CD' THEN
                    -- tout en colis detail
                    v_qte_en_cd := r_stkres.qte_res;

                ELSE
                    --
                    -- Controle PCB de l'UL
                    --
                    v_pcb_ul := su_bas_gcl_su_ul(r_stkres.cod_pro, r_stkres.cod_vl, 'PCB');

                    --
                    v_ret := su_bas_conv_unite_to_one(p_cod_pro        => r_stkres.cod_pro,
                                                      p_cod_vl         => r_stkres.cod_vl,
                                                      p_qte_orig       => r_stkres.qte_res,
                                                      p_unite_orig     => r_stkres.unit_res,
                                                      p_unite_dest     => 'P',
                                                      p_qte_dest       => v_qte_pce);

                    IF NVL(v_pcb_ul,0) > 0 AND v_qte_pce >= v_pcb_ul THEN

                        v_ret := su_bas_conv_unite_to_one(p_cod_pro        => r_stkres.cod_pro,
                                                          p_cod_vl         => r_stkres.cod_vl,
                                                          p_qte_orig       => MOD(v_qte_pce, v_pcb_ul),
                                                          p_unite_orig     => 'P',
                                                          p_unite_dest     => r_stkres.unit_res,
                                                          p_qte_dest       => v_qte_a_dereserver);

                        v_qte_en_cc := r_stkres.qte_res - v_qte_a_dereserver;

                        -- cumul pour info message trace
                        v_info_qte_1 := v_info_qte_1 + MOD(v_qte_pce, v_pcb_ul);

                    ELSE
                        --
                        -- Deduction en fonction de la nature de l'UL
                        --
                        IF su_bas_gcl_su_ul(r_stkres.cod_pro, r_stkres.cod_vl, 'TYP_UL') = 'CC' THEN
                            -- tout en colis complet
                            v_qte_en_cc := r_stkres.qte_res;

                        ELSIF su_bas_gcl_su_ul(r_stkres.cod_pro, r_stkres.cod_vl, 'TYP_UL') = 'PCE' THEN
                            -- tout en colis detail
                            v_qte_en_cd := r_stkres.qte_res;

                        ELSE
                            -- tout en colis detail
                            v_qte_en_cd := r_stkres.qte_res;

                        END IF;
                    END IF;

                END IF;

            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' / r_stkres.qte_res:' || TO_CHAR(r_stkres.qte_res) || ' ' || r_stkres.unit_res ||
                                            ' / v_qte_a_deres:' || TO_CHAR(v_qte_a_dereserver) ||
                                            ' / v_qte_en_cc:' || TO_CHAR(v_qte_en_cc) ||
                                            ' / v_qte_en_cd:' || TO_CHAR(v_qte_en_cd));
            END IF;

            ---------------------------------------------
            -- 2.1: dereservation de la partie incomplete
            ---------------------------------------------
            v_etape := 'qte a dereserver';
            IF NVL(v_qte_a_dereserver,0) > 0 THEN

                v_etape := 'Dereservation stock process';

                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || ' v_qte_a_dereserver:'||v_qte_a_dereserver||' / id_res:'||v_id_res);
                END IF;

                v_etape := 'Libère rstk ferme sur SE';
                v_ret := su_bas_conv_unite_to_one(
                            p_cod_pro        => r_stkres.cod_pro,
                            p_cod_vl         => r_stkres.cod_vl,
                            p_qte_orig       => v_qte_a_dereserver,
                            p_unite_orig     => 'P',
                            p_unite_dest     => r_stkres.unit_res,
                            p_qte_dest       => v_qte_a_dereserver);

                v_ret := se_bas_libere_rstk (
                            p_no_rstk       => v_id_res,
                            p_qte_libere => v_qte_a_dereserver,
                            p_delete     => TRUE,
                            p_cod_pro    => r_stkres.cod_pro,
                            p_cod_vl     => r_stkres.cod_vl,
                            p_cod_va     => r_stkres.cod_va);

                IF v_ret <> 'OK' THEN
                    v_etape := 'Problème sur liberation stock ferme sur SE NO_RSTK: ' || v_id_res;
                    v_niv_ano:= 2;
                    RAISE err_except;
                END IF;

                v_etape := 'Libère rstk ferme sur PC';
                v_ret := pc_bas_libere_rstk (p_id_res       => v_id_res,
                                             p_qte_libere   => v_qte_a_dereserver);
                IF v_ret <> 'OK' THEN
                    v_niv_ano:= 2;
                    v_etape := 'Problème sur liberation stock ferme sur PC ID_RES: ' || v_id_res;
                    RAISE err_except;
                END IF;

                -- paramètre OUT
                p_qte_deres := p_qte_deres + v_qte_a_dereserver;

            END IF;

            -------------------------------
            -- 2.2: Creation colis complet
            -------------------------------
            IF v_qte_en_cc > 0 THEN

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' Creation en CC: ' ||TO_CHAR(v_qte_en_cc));
                END IF;

                --
                -- Calcul des qtes pour 1 colis
                --
                v_ret := su_bas_conv_unite_to_one(p_cod_pro        => r_stkres.cod_pro,
                                                  p_cod_vl         => r_stkres.cod_vl,
                                                  p_qte_orig       => 1,
                                                  p_unite_orig     => 'C',
                                                  p_unite_dest     => r_ueedetref.unite_qte, -- unite de commande
                                                  p_qte_dest       => v_qte_unit_cde);

                v_qte_colis  := NULL;
                v_qte_unit_2 := NULL;
                v_unit_stk_2 := NULL;
                v_qte_ub     := NULL;
                v_qte_ul     := NULL;
                v_qte_pds    := NULL;
                v_qte_pce    := NULL;
                v_qte_pal    := NULL;
                v_qte_vol    := NULL;

                v_etape:='Determine les qte de base pour 1 colis';
                v_ret := su_bas_conv_unite_to_all(  p_cod_pro    =>r_stkres.cod_pro,
                                                    p_cod_vl     =>r_stkres.cod_vl,
                                                    p_pcb        =>NULL,
                                                    p_qte_unit_1 =>1,
                                                    p_unit_stk_1 =>'C',
                                                    p_qte_colis  =>v_qte_colis,
                                                    p_qte_unit_2 =>v_qte_unit_2,
                                                    p_unit_stk_2 =>v_unit_stk_2,
                                                    p_qte_ub     =>v_qte_ub,
                                                    p_qte_ul     =>v_qte_ul,
                                                    p_qte_pds    =>v_qte_pds,
                                                    p_qte_pce    =>v_qte_pce,
                                                    p_qte_pal    =>v_qte_pal,
                                                    p_qte_vol    =>v_qte_vol);

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug('Resultats pour 1 Colis.');
                    su_bas_put_debug('Qte:' || TO_CHAR(v_qte_unit_cde) || ' ' || r_ueedetref.unite_qte);
                    su_bas_put_debug('Pce:' || TO_CHAR(v_qte_pce));
                    su_bas_put_debug('Pds:' || TO_CHAR(v_qte_pds));
                    su_bas_put_debug('Vol:' || TO_CHAR(v_qte_vol));
                    su_bas_put_debug('Col:' || TO_CHAR(v_qte_colis));
                END IF;

                -- Rch du code contenant d'expédition
                IF su_bas_gcl_su_ul(r_stkres.cod_pro, r_stkres.cod_vl, 'TYP_UL') = 'PCE' THEN
                    v_cod_cnt  := NVL(su_bas_gcl_su_ul(r_stkres.cod_pro, r_stkres.cod_vl,'COD_CNT_EXP'),r_ueeref.cod_cnt);
                ELSE
                    v_cod_cnt  := NVL(su_bas_gcl_su_ul(r_stkres.cod_pro, r_stkres.cod_vl,'COD_CNT'),r_ueeref.cod_cnt);
                END IF;

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug('v_cod_cnt : ' || v_cod_cnt);
                END IF;

                v_qte_1C     := v_qte_unit_cde; -- dans l'unite de commande
                v_pds_1C     := v_qte_pds;
                v_nb_pce_1C  := v_qte_pce;
                v_qte_vol_1C := v_qte_vol;

                v_etape := 'Determine le nb de CC à creer';

                v_ret := su_bas_conv_unite_to_one(p_cod_pro        => r_stkres.cod_pro,
                                                  p_cod_vl         => r_stkres.cod_vl,
                                                  p_qte_orig       => v_qte_en_cc,
                                                  p_unite_orig     => r_stkres.unit_res,
                                                  p_unite_dest     => r_ueedetref.unite_qte, -- unite de commande
                                                  p_qte_dest       => v_qte_unit_cde);

                v_qte_colis  := NULL;
                v_qte_unit_2 := NULL;
                v_unit_stk_2 := NULL;
                v_qte_ub     := NULL;
                v_qte_ul     := NULL;
                v_qte_pds    := NULL;
                v_qte_pce    := NULL;
                v_qte_pal    := NULL;
                v_qte_vol    := NULL;

                v_ret := su_bas_conv_unite_to_all(p_cod_pro    =>r_stkres.cod_pro,
                                                  p_cod_vl     =>r_stkres.cod_vl,
                                                  p_pcb        =>NULL,
                                                  p_qte_unit_1 =>v_qte_en_cc,
                                                  p_unit_stk_1 =>r_stkres.unit_res,
                                                  p_qte_colis  =>v_qte_colis,
                                                  p_qte_unit_2 =>v_qte_unit_2,
                                                  p_unit_stk_2 =>v_unit_stk_2,
                                                  p_qte_ub     =>v_qte_ub,
                                                  p_qte_ul     =>v_qte_ul,
                                                  p_qte_pds    =>v_qte_pds,
                                                  p_qte_pce    =>v_qte_pce,
                                                  p_qte_pal    =>v_qte_pal,
                                                  p_qte_vol    =>v_qte_vol);

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug('Resultats pour les N Colis.');
                    su_bas_put_debug('Qte:' || TO_CHAR(v_qte_unit_cde) || ' ' || r_ueedetref.unite_qte);
                    su_bas_put_debug('Pce:' || TO_CHAR(v_qte_pce));
                    su_bas_put_debug('Pds:' || TO_CHAR(v_qte_pds));
                    su_bas_put_debug('Vol:' || TO_CHAR(v_qte_vol));
                    su_bas_put_debug('Col:' || TO_CHAR(v_qte_colis));
                END IF;

                -- On doit arrondir au nombre de colis entier superieur
                v_nb_colis := CEIL (v_qte_colis);

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug('Boucle sur v_nb_colis:' || TO_CHAR(v_nb_colis));
                END IF;

                -- Recup du record ve de traitement
                v_etape := 'Lecture VET';
                v_cod_vet_cc := r_lig.cod_vet;
                r_vet_usn    := su_bas_grw_su_v_vet_usn(v_cod_vet_cc, r_ueeref.cod_usn);

                v_info_qte_cc := v_info_qte_cc + v_nb_colis;

                v_etape := 'Création des colis complets';
                FOR r_colis IN 1..v_nb_colis LOOP

                    IF v_qte_unit_cde <= 0 THEN
                        --
                        -- normalement on doit sortir sur le nombre de colis atteint
                        --
                        v_etape := 'PB sur calcul nb_colis';
                        su_bas_cre_ano (p_txt_ano => v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_lib_ano_1       => 'nb_colis',
                                p_par_ano_1       => TO_CHAR(v_nb_colis),
                                p_lib_ano_2       => 'qte_u_cde',
                                p_par_ano_2       => TO_CHAR(v_qte_unit_cde),
                                p_lib_ano_3       => 'qte_1C',
                                p_par_ano_3       => TO_CHAR(v_qte_1C),
                                p_cod_err_su_ano  => v_cod_err_su_ano,
                                p_nom_obj         => v_nom_obj,
                                p_niv_ano         => 2,
                                p_version         => v_version);
                        EXIT;
                    END IF;

                    v_etape := 'creation record new pc_uee';
                    vr_uee := r_ueeref;

                    vr_uee.typ_uee           := 'CC';
                    vr_uee.nb_pce_theo       := v_nb_pce_1C;
                    vr_uee.pds_theo          := v_pds_1C;
                    vr_uee.vol_theo          := v_qte_vol_1C;
                    vr_uee.nb_col_theo       := 1;
                    vr_uee.cod_ut            := NULL;
                    vr_uee.typ_ut            := NULL;
                    vr_uee.id_cb             := NULL;
                    vr_uee.no_bcnt           := NULL;
                    vr_uee.no_chm            := NULL;
                    vr_uee.no_ord_chm        := NULL;
                    vr_uee.mode_trait_col    := r_vet_usn.mode_trait_col;
                    vr_uee.mode_etq_col      := r_vet_usn.mode_etq_col;
                    vr_uee.cod_cnt           := v_cod_cnt;
                    vr_uee.cod_pss_afc       := p_cod_pss;
                    vr_uee.no_uee_ref        := r_ueedetref.no_uee; --on marque le colis référent pour trace

                    v_ret := pc_bas_cre_pc_uee (pr_pc_uee => vr_uee,
                                                p_no_com => r_ueeref.no_com,
                                                p_no_uee => v_no_uee);

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj ||  ' no_uee:'||v_no_uee||' v_ret:'||v_ret);
                    END IF;

                    IF v_ret <> 'OK' THEN
                        RAISE err_except;
                    END IF;

                    v_etape := 'creation record new pc_uee det';
                    vr_uee_det := r_ueedetref;

                    vr_uee_det.no_uee       := v_no_uee;
                    vr_uee_det.qte_theo     := v_qte_1C;
                    vr_uee_det.nb_pce_theo  := v_nb_pce_1C;
                    vr_uee_det.pds_theo     := v_pds_1C;
                    vr_uee_det.qte_val      := 0;
                    vr_uee_det.nb_pce_val   := 0;
                    vr_uee_det.pds_net_val  := 0;
                    vr_uee_det.pds_brut_val := 0;
                    vr_uee_det.id_res       := v_id_res;
                    vr_uee_det.cod_vl_res   := r_stkres.cod_vl;
                    vr_uee_det.cod_va_res   := r_stkres.cod_va;
                    vr_uee_det.cod_pss_afc  := p_cod_pss;
                    vr_uee_det.no_com       := r_ueedetref.no_com;
                    vr_uee_det.no_lig_com   := r_ueedetref.no_lig_com;
                    vr_uee_det.mode_trait_pce := r_vet_usn.mode_trait_pce;
                    vr_uee_det.mode_etq_pce   := r_vet_usn.mode_etq_pce;
                    vr_uee_det.cod_vet        := NULL;  -- calculer plus tard
                    vr_uee_det.cod_vedoc_ofs  :=r_lig.cod_vedoc_ofs;
                    vr_uee_det.cod_vedoc_mqe  :=r_lig.cod_vedoc_mqe;
                    vr_uee_det.cod_vedoc_pce_1:=r_lig.cod_vedoc_pce_1;
                    vr_uee_det.cod_vedoc_pce_2:=r_lig.cod_vedoc_pce_2;
                    vr_uee_det.cod_vedoc_col_1:=r_lig.cod_vedoc_col_1;
                    vr_uee_det.cod_vedoc_col_2:=r_lig.cod_vedoc_col_2;
                    vr_uee_det.cod_ved        :=r_lig.cod_ved;

                    v_ret := pc_bas_cre_pc_uee_det (pr_pc_uee_det=>vr_uee_det,
                                                    p_typ_uee=>'CC');

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj ||' ' || v_etape ||v_no_uee ||' v_ret:'||v_ret);
                    END IF;

                    IF v_ret <> 'OK' THEN
                        RAISE err_except;
                    END IF;

                    -- sortir le n° de colis à NULL car colis detail
                    -- pour MAJ de pc_rstk à suivre de la creation
                    p_ref_rstk_3 := NULL;

                    -- MAJ du colis de référence (NO_UEE = NO_UEE_REF)
                    -------------------------------------------------
                    v_etape := 'Maj UEE de référence';
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj|| ' ' || v_etape);
                    END IF;

                    UPDATE pc_uee SET
                        nb_pce_theo = nb_pce_theo - v_nb_pce_1C,
                        pds_theo    = pds_theo - v_pds_1C
                    WHERE no_uee = r_ueeref.no_uee;

                    v_etape := 'Maj UEE_DET de référence';
                    UPDATE pc_uee_det SET
                        qte_theo    = qte_theo - v_qte_1C,
                        nb_pce_theo = nb_pce_theo - v_nb_pce_1C,
                        pds_theo    = pds_theo - v_pds_1C
                    WHERE no_uee = r_ueedetref.no_uee AND
                          no_com = r_ueedetref.no_com AND no_lig_com = r_ueedetref.no_lig_com;

                    v_etape := 'Maj des compteurs qte';
                    v_qte_pce      := v_qte_pce - v_nb_pce_1C;
                    v_qte_pds      := v_qte_pds - v_pds_1C;
                    v_qte_unit_cde := v_qte_unit_cde - v_qte_1C;

                    IF v_qte_unit_cde < v_qte_1C THEN
                        -- plus assez pour un colis complet ...
                        -- => mise a jour des qte avec le reste
                        v_nb_pce_1C := v_qte_pce;
                        v_pds_1C    := v_qte_pds;
                        v_qte_1C    := v_qte_unit_cde;
                    END IF;

                END LOOP;

                -- END IF;

            END IF;

            IF v_qte_en_cd > 0 THEN

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' Creation en CD:' ||TO_CHAR(v_qte_en_cd));
                END IF;


                ---------------------------------------------------------
                -- 2.3: Creation colis detail CD
                ---------------------------------------------------------
                v_etape:='Creation / completion du colis detail de la commande';

                -- si colis détail on recherche à faire un seul colis par commande
                -- recherche si colis existe pour une autre ligne
                OPEN c_ueecd (p_ref_rstk_1);
                FETCH c_ueecd INTO r_ueecd;
                IF c_ueecd%NOTFOUND THEN
                    v_cre_uee := 'OUI';
                ELSE
                    v_no_uee := r_ueecd.no_uee;
                    v_cre_uee := 'NON';
                END IF;
                CLOSE c_ueecd;

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj || ' v_cre_uee: '||v_cre_uee||' unit_res:'||r_stkres.unit_res);
                END IF;

                -- 2.3.1 Détermine les quantités à ajouter au colis unique CD
                -- ----------------------------------------------------------
                -- conversion en unité de base (pièce)
                v_qte_colis  := NULL;
                v_qte_unit_2 := NULL;
                v_unit_stk_2 := NULL;
                v_qte_ub     := NULL;
                v_qte_ul     := NULL;
                v_qte_pds    := NULL;
                v_qte_pce    := NULL;
                v_qte_pal    := NULL;
                v_qte_vol    := NULL;

                v_ret := su_bas_conv_unite_to_all (p_cod_pro    =>r_stkres.cod_pro,
                                                   p_cod_vl     =>r_stkres.cod_vl,
                                                   p_pcb        =>NULL,
                                                   p_qte_unit_1 =>v_qte_en_cd,
                                                   p_unit_stk_1 =>r_stkres.unit_res,
                                                   p_qte_colis  =>v_qte_colis,
                                                   p_qte_unit_2 =>v_qte_unit_2,
                                                   p_unit_stk_2 =>v_unit_stk_2,
                                                   p_qte_ub     =>v_qte_ub,
                                                   p_qte_ul     =>v_qte_ul,
                                                   p_qte_pds    =>v_qte_pds,
                                                   p_qte_pce    =>v_qte_pce,
                                                   p_qte_pal    =>v_qte_pal,
                                                   p_qte_vol    =>v_qte_vol);

                v_qte_theo    := v_qte_pce;
                v_pds_theo    := v_qte_pds;
                v_nb_pce_theo := v_qte_pce;

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug('v_cre_uee:' || v_cre_uee);
                    su_bas_put_debug('v_no_uee:' || v_no_uee);
                    su_bas_put_debug('Qte:' || TO_CHAR(v_qte_theo));
                    su_bas_put_debug('Unit:' || r_stkres.unit_res);
                    su_bas_put_debug('Pce:' || TO_CHAR(v_nb_pce_theo));
                    su_bas_put_debug('Pds:' || TO_CHAR(v_pds_theo));
                END IF;

                -- recup du record ve de traitement
                v_etape := 'controle VET';
                v_cod_vet_cd := NVL(r_lig.cod_vet_cd, r_lig.cod_vet);

                r_vet_usn := su_bas_grw_su_v_vet_usn(v_cod_vet_cd, r_ueeref.cod_usn);

                -- 2.3.2: MAJ ou création du record PC_UEE de l'id_res en cours
                ----------------------------------------------------------------
                IF v_cre_uee = 'NON' THEN

                    v_etape := 'maj record uee';
                    UPDATE pc_uee SET
                        nb_pce_theo = nb_pce_theo + v_nb_pce_theo,
                        pds_theo    = pds_theo + v_pds_theo,
                        no_uee_ref  = r_ueedetref.no_uee
                    WHERE no_uee = v_no_uee;

                    -- Pour s'assurer que l'on a qu'un COD_UP pour le colis CD, lors de la distribution
                    -- MNEV : a eclaicir ...
                    --
                    v_etape := 'ctrl cod_up du colis CD';
                    OPEN c_cod_up (v_no_uee);
                    FETCH c_cod_up INTO r_cod_up;
                    IF c_cod_up%FOUND THEN
                        p_ref_rstk_4 := r_cod_up.cod_up;
                    END IF;
                    CLOSE c_cod_up;

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj || ' ' || v_etape||' : no_uee: '||v_no_uee);
                    END IF;

                ELSE

                    v_etape := 'creation record new uee';
                    vr_uee := r_ueeref;

                    vr_uee.typ_uee           := 'CD';
                    vr_uee.nb_pce_theo       := v_nb_pce_theo;
                    vr_uee.pds_theo          := v_pds_theo;
                    vr_uee.nb_col_theo       := 1;
                    vr_uee.cod_ut            := NULL;
                    vr_uee.typ_ut            := NULL;
                    vr_uee.id_cb             := NULL;
                    vr_uee.no_bcnt           := NULL;
                    vr_uee.no_chm            := NULL;
                    vr_uee.no_ord_chm        := NULL;
                    vr_uee.mode_trait_col    := r_vet_usn.mode_trait_col;
                    vr_uee.mode_etq_col      := r_vet_usn.mode_etq_col;
                    vr_uee.cod_pss_afc       := p_cod_pss;

                    vr_uee.no_uee_ref        := r_ueedetref.no_uee;

                    v_ret := pc_bas_cre_pc_uee (pr_pc_uee => vr_uee,
                                                p_no_com  => r_ueeref.no_com,
                                                p_no_uee  => v_no_uee);

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj || ' ' || v_etape||' : no_uee: '||v_no_uee);
                    END IF;

                    IF v_ret <> 'OK' THEN
                        RAISE err_except;
                    END IF;

                    v_info_qte_cd := v_info_qte_cd + 1;

                END IF;

                -- 2.3.3: MAJ ou création du record PC_UEE_DET de l'id_res en cours
                -------------------------------------------------------------------
                v_etape := 'creation/MAJ record new uee det';
                OPEN c_ueedetcd (v_no_uee, p_ref_rstk_1, pc_bas_to_number(p_ref_rstk_2));
                FETCH c_ueedetcd INTO r_ueedetcd;
                found_ueedetcd := c_ueedetcd%FOUND;
                CLOSE c_ueedetcd;

                IF found_ueedetcd THEN
                    v_etape := 'MAJ record new uee det';
                    UPDATE pc_uee_det SET
                        qte_theo    = qte_theo + v_qte_theo,
                        nb_pce_theo = nb_pce_theo + v_nb_pce_theo,
                        pds_theo    = pds_theo + v_pds_theo
                    WHERE no_uee = v_no_uee AND no_com = p_ref_rstk_1 AND
                          no_lig_com = pc_bas_to_number(p_ref_rstk_2);

                ELSE
                    v_etape := 'creation record new uee det';
                    vr_uee_det := r_ueedetref;

                    vr_uee_det.no_uee       := v_no_uee;
                    vr_uee_det.qte_theo     := v_qte_theo;
                    vr_uee_det.unite_qte    := 'P';
                    vr_uee_det.nb_pce_theo  := v_nb_pce_theo;
                    vr_uee_det.pds_theo     := v_pds_theo;
                    vr_uee_det.qte_val      := 0;
                    vr_uee_det.nb_pce_val   := 0;
                    vr_uee_det.pds_net_val  := 0;
                    vr_uee_det.pds_brut_val := 0;
                    vr_uee_det.id_res       := v_id_res;
                    vr_uee_det.cod_pss_afc  := p_cod_pss;
                    vr_uee_det.no_com       := r_ueedetref.no_com;
                    vr_uee_det.no_lig_com   := r_ueedetref.no_lig_com;
                    vr_uee_det.mode_trait_pce := r_vet_usn.mode_trait_pce;
                    vr_uee_det.mode_etq_pce   := r_vet_usn.mode_etq_pce;
                    vr_uee_det.cod_vet        := NULL;
                    vr_uee_det.cod_vedoc_ofs  :=r_lig.cod_vedoc_ofs;
                    vr_uee_det.cod_vedoc_mqe  :=r_lig.cod_vedoc_mqe;
                    vr_uee_det.cod_vedoc_pce_1:=r_lig.cod_vedoc_pce_1;
                    vr_uee_det.cod_vedoc_pce_2:=r_lig.cod_vedoc_pce_2;
                    vr_uee_det.cod_vedoc_col_1:=r_lig.cod_vedoc_col_1_cd;
                    vr_uee_det.cod_vedoc_col_2:=r_lig.cod_vedoc_col_2_cd;
                    vr_uee_det.cod_ved        :=r_lig.cod_ved;

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj ||' ' || v_etape ||v_no_uee);
                    END IF;

                    v_ret := pc_bas_cre_pc_uee_det (pr_pc_uee_det=>vr_uee_det,
                                                    p_typ_uee=>'CD');

                    IF v_ret <> 'OK' THEN
                       RAISE err_except;
                    END IF;
                END IF;

                -- 2.3.4: MAJ UEE de Référence
                ------------------------------
                -- resortir le n° de colis CD utilisé
                -- pour MAJ de pc_rstk à suivre de la creation
                p_ref_rstk_3 := v_no_uee;

                v_etape := 'Maj PC_UEE de référence';
                UPDATE pc_uee SET
                    nb_pce_theo = nb_pce_theo - v_nb_pce_theo,
                    pds_theo    = pds_theo - v_pds_theo
                WHERE no_uee = r_ueeref.no_uee;

                v_etape := 'Maj PC_UEE_DET de référence';
                UPDATE pc_uee_det SET
                    qte_theo = qte_theo - v_qte_theo,
                    nb_pce_theo = nb_pce_theo - v_nb_pce_theo,
                    pds_theo = pds_theo - v_pds_theo
                WHERE no_uee = r_ueedetref.no_uee AND
                      no_com = r_ueedetref.no_com AND no_lig_com = r_ueedetref.no_lig_com
                RETURNING qte_theo INTO v_qte;

                -- ON insert le colis de reference si celui ci dispose d'une quantité.
                -- MAIS si ce colis devient au final entièrement réservé, sa qté sera à 0.
                -- >> Il faut donc supprimer le colis de référence vide du plan
                IF r_ueeref.cod_elm_up IS NOT NULL AND v_qte <= 0 THEN
                    v_etape := 'MAJ pc_uee.cod_elm_up du colis reference vide';
                    UPDATE pc_uee SET
                        cod_elm_up = NULL,
                        cod_up     = NULL,
                        typ_up     = NULL
                    WHERE no_uee = r_ueeref.no_uee;

                    v_etape := 'Suppression elm_up du colis reference vide';
                    DELETE FROM pc_elm_up WHERE no_uee = r_ueeref.no_uee;

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' '   || v_etape ||' cod_elm_up:'|| r_ueeref.cod_elm_up);
                    END IF;
                END IF;

            END IF;

        END LOOP;
    ELSE
        v_etape := 'PB recuperation resa ou du colis de réference';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj || ' ' || v_etape);
        END IF;

        IF pc_trace_pkg.get_autor_resa THEN
            pc_bas_trace('ORDO_MANU',2,
                         'PB de récupération réservation SE ou colis de référence');
        END IF;

    END IF;

    IF v_info_qte_1 > 0 THEN
        IF pc_trace_pkg.get_autor_resa THEN
            pc_bas_trace('ORDO_MANU',2,
                         'Deréservation de $1 pièce(s) à la création des colis',
                         p_1=>TO_CHAR(v_info_qte_1));
        END IF;
    END IF;

    IF pc_trace_pkg.get_autor_resa THEN
        pc_bas_trace('ORDO_MANU',2,
                     'Création de $1 colis CC et de $2 colis CD',
                     p_1=>TO_CHAR(v_info_qte_cc),
                     p_2=>TO_CHAR(v_info_qte_cd));
    END IF;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' Fin crea_uee_id_res_2: OK');
    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
      --v_cod_err_su_ano := 'PC-ORDO000';
      ROLLBACK TO my_pc_bas_crea_uee_id_res;

      su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No_com',
                        p_par_ano_1       => r_ueedetref.no_com,
                        p_lib_ano_2       => 'No_lig_com',
                        p_par_ano_2       => r_ueedetref.no_lig_com,
                        p_lib_ano_3       => 'v_ret',
                        p_par_ano_3       => v_ret,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;


/****************************************************************************
*   pc_bas_decrea_uee_id_res -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'annuler la creation des colis
-- en fonction de la réservation ferme.
--
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01h,03.07.13,alfl    positionne su_global_pkv.v_mode_arc a MANU pour ne pas
--                      archiver les pc_uee_det et pc_uee
-- 01g,05.08.11,mnev    Controle lignes colis avant effacement de pc_uee.
-- 01f,28.07.11,mnev    Efface saisie temporaire si elles existent.
-- 01e,21.07.11,mnev    Correction sur les DELETE
--              alfl    Correction sur le savepoint
-- 01d,31.05.11,mnev    Traite le cas d'appel avec id_res à NULL
-- 01c,15.03.11,mnev    Arrangements
-- 01b,14.03.11,mnev    Ajout paramètre p_mode_appel
--                      Supprime delete sur se_rstk et pc_rstk
-- 01a,10.01.11,RLEB    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_mode_appel : précise la fonction appelante.
--                 on en deduit si l'on doit replacer le colis vers le colis de reference ou non
--                 STD : OUI
--                 FIN : NON
--                 ...
--                 def : OUI
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_decrea_uee_id_res (p_id_res             pc_rstk.id_res%TYPE,
                                   p_cod_pss_afc        pc_rstk.cod_pss_afc%TYPE DEFAULT NULL,
                                   p_qte_libere         NUMBER,
                                   p_no_lig_rstk        se_lig_rstk.no_lig_rstk%TYPE DEFAULT NULL,
                                   p_no_uee             pc_uee.no_uee%TYPE DEFAULT NULL,
                                   p_mode_appel         VARCHAR2 DEFAULT 'STD')
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01h $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_decrea_uee_id_res:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclarations de variables
    -----------------------------

    v_status            VARCHAR2(20);
    v_qte_libere        NUMBER:=p_qte_libere;
    v_qte_libere_valid  NUMBER;       --nécessaire si on ne gère pas le stock en UT, sinon on risque de détruire plus
    v_pds_theo          pc_uee.pds_theo%TYPE;
    v_vol_theo          pc_uee.vol_theo%TYPE;
    v_qte_theo          pc_uee_det.qte_theo%TYPE;
    v_qte               pc_uee_det.qte_theo%TYPE;
    v_nb_pce_theo       pc_uee_det.nb_pce_theo%TYPE;
    v_qte_ub            pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_ul            pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_pds           pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_pce           pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_colis         pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_pal           pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_vol           pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_unit_2        pc_rstk_det.qte_res%TYPE := NULL;
    v_unit_stk_2        VARCHAR2(10):=NULL;

    vr_uee              pc_uee%ROWTYPE;
    vr_uee_det          pc_uee_det%ROWTYPE;
    v_no_uee            pc_uee.no_uee%TYPE;
    v_typ_uee           pc_uee.typ_uee%TYPE;

    -- Déclarations des curseurs
    -- --------------------------
    CURSOR c_uee (x_etat_max NUMBER) IS
    SELECT DISTINCT d.no_uee,
           d.no_com,
           d.no_lig_com,
           d.nb_pce_theo,
           d.pds_theo,
           d.vol_theo,
           d.qte_theo,
           d.cod_pro_res cod_pro,
           d.cod_vl_res cod_vl,
           r.unit_res
    FROM pc_rstk k, pc_rstk_det r, pc_uee u, pc_uee_det d
    WHERE (d.id_res = p_id_res OR (p_id_res IS NULL AND p_no_uee IS NOT NULL))
       AND d.id_res = r.id_res
       AND (d.no_uee = p_no_uee OR (p_no_uee IS NULL AND p_id_res IS NOT NULL))
       AND d.no_uee = u.no_uee
       AND r.id_res = k.id_res
       AND k.no_uee_ref IS NOT NULL
       AND (u.typ_uee = 'CC'
            OR
            (u.typ_uee = 'CD' AND u.no_uee<>NVL(u.no_uee_ref,'#NULL#'))
           )
       AND (r.no_lig_rstk  = p_no_lig_rstk OR p_no_lig_rstk IS NULL)
       AND u.no_uee_ref IS NOT NULL
       AND su_bas_etat_val_num(u.etat_atv_pc_uee,'PC_UEE') <= x_etat_max;

    found_uee BOOLEAN;
    r_uee c_uee%ROWTYPE;

    CURSOR c_ueeref (x_no_com pc_uee_det.no_com%TYPE, x_no_lig_com pc_uee_det.no_lig_com%TYPE) IS
    SELECT u.*
    FROM pc_uee u, pc_uee_det d
    WHERE d.no_com = x_no_com
      AND d.no_lig_com = x_no_lig_com
      AND d.no_uee = u.no_uee
      AND u.no_uee=u.no_uee_ref; -- colis de référence

    found_ueeref BOOLEAN;
    r_ueeref c_ueeref%ROWTYPE;

    CURSOR c_ueedetref (x_no_uee pc_uee_det.no_uee%TYPE, x_no_com pc_uee_det.no_com%TYPE, x_no_lig_com pc_uee_det.no_lig_com%TYPE) IS
    SELECT *
    FROM pc_uee_det
    WHERE no_uee = x_no_uee
      AND no_com = x_no_com
      AND no_lig_com = x_no_lig_com;

    found_ueedetref BOOLEAN;
    r_ueedetref c_ueedetref%ROWTYPE;

    CURSOR c_ueevide IS
    SELECT u.*, d.no_lig_com
    FROM pc_uee_det d, pc_uee u
    WHERE u.no_uee_ref IS NOT NULL
      AND u.no_uee <> NVL(u.no_uee_ref,'#NULL#')
      AND d.etat_atv_pc_uee_det IN ('CREA','ITER')
      AND NOT EXISTS (SELECT 1
                      FROM pc_rstk, pc_uee_det
                      WHERE pc_rstk.id_res = pc_uee_det.id_res AND pc_uee_det.no_uee = u.no_uee AND pc_uee_det.id_res IS NOT NULL)
      AND u.no_uee = d.no_uee;

    r_ueevide c_ueevide%ROWTYPE;

    CURSOR c_ueedetvide (x_no_uee pc_uee.no_uee%TYPE) IS
    SELECT *
    FROM pc_uee_det
    WHERE no_uee = x_no_uee;

    r_ueedetvide c_ueedetvide%ROWTYPE;

    CURSOR c_ctl (x_no_uee pc_uee.no_uee%TYPE) IS
    SELECT count(*) nb_lig, SUM(nb_pce_theo) nb_pce_theo, SUM(pds_theo) pds_theo
    FROM pc_uee_det
    WHERE no_uee = x_no_uee;

    r_ctl c_ctl%ROWTYPE;

    v_etat_max   NUMBER;
    v_uee_ref    pc_rstk.no_uee_ref%TYPE := NULL;
    v_mode_arc          VARCHAR2(30):=NULL;


BEGIN

    v_ret :='OK';

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' id_res=' || TO_CHAR(p_id_res) || ' / qte_libere=' || TO_CHAR(p_qte_libere) || ' / no_lig_rstk=' || TO_CHAR(p_no_lig_rstk));
        su_bas_put_debug(v_nom_obj||' mode_appel=' || p_mode_appel);
    END IF;

    SAVEPOINT bas_decrea_uee_id_res_sp;  -- Pour la gestion de l'exception on fixe un point de rollback.

    IF p_id_res IS NOT NULL THEN
        v_uee_ref := su_bas_gcl_pc_rstk (p_id_res => p_id_res,
                                         p_colonne => 'NO_UEE_REF');
    ELSE
        -- non NULL : permet de traiter le cas p_id_res IS NULL
        v_uee_ref := 0;
    END IF;

    IF v_uee_ref IS NOT NULL AND p_mode_appel = 'STD' THEN

        v_etat_max := su_bas_etat_val_num('PREPARATION_INTERROMPUE','PC_UEE');

        v_etape := 'open c_uee';
        OPEN c_uee (v_etat_max);
        LOOP
            v_etape :='Debut Trait. décreation colis ' || r_uee.no_uee;
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj|| ' ' || v_etape);
            END IF;

            FETCH c_uee INTO r_uee;
            EXIT WHEN c_uee%NOTFOUND OR (v_qte_libere <= 0 AND p_qte_libere IS NOT NULL) OR v_qte_libere=v_qte_libere_valid;

            IF p_qte_libere IS NULL THEN
                v_qte_libere := r_uee.qte_theo;
            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' : no_uee = '||r_uee.no_uee ||' no_com:'||r_uee.no_com||'-'||r_uee.no_lig_com );
                su_bas_put_debug(v_nom_obj||' : v_qte_libere = '||v_qte_libere ||' r_uee.qte_theo:'||r_uee.qte_theo );
            END IF;

            --1: recupère données à maj
            -------------------------------------
            v_etape :='recupère données à maj';
            IF v_qte_libere <= r_uee.qte_theo THEN
                -- init a NULL
                v_qte_colis  := NULL;
                v_qte_unit_2 := NULL;
                v_unit_stk_2 := NULL;
                v_qte_ub     := NULL;
                v_qte_ul     := NULL;
                v_qte_pds    := NULL;
                v_qte_pce    := NULL;
                v_qte_pal    := NULL;
                v_qte_vol    := NULL;

                v_etape:=' conversion car multi VL autorise:';
                v_ret := su_bas_conv_unite_to_all(p_cod_pro    =>r_uee.cod_pro,
                                                  p_cod_vl     =>r_uee.cod_vl,
                                                  p_pcb        =>NULL,
                                                  p_qte_unit_1 =>v_qte_libere,
                                                  p_unit_stk_1 =>r_uee.unit_res,
                                                  p_qte_colis  =>v_qte_colis,
                                                  p_qte_unit_2 =>v_qte_unit_2,
                                                  p_unit_stk_2 =>v_unit_stk_2,
                                                  p_qte_ub     =>v_qte_ub,
                                                  p_qte_ul     =>v_qte_ul,
                                                  p_qte_pds    =>v_qte_pds,
                                                  p_qte_pce    =>v_qte_pce,
                                                  p_qte_pal    =>v_qte_pal,
                                                  p_qte_vol    =>v_qte_vol);

                v_qte_theo := v_qte_libere;
                v_pds_theo := v_qte_pds;
                v_vol_theo := v_qte_vol;
                v_nb_pce_theo := v_qte_pce;

            ELSE
                v_qte_theo := r_uee.qte_theo;
                v_pds_theo := r_uee.pds_theo;
                v_vol_theo := r_uee.vol_theo;
                v_nb_pce_theo := r_uee.nb_pce_theo;
            END IF;

            v_etape:=' récupère le colis de reférence à reconstruire';
            OPEN c_ueeref(r_uee.no_com, r_uee.no_lig_com);
            FETCH c_ueeref INTO r_ueeref;
            found_ueeref := c_ueeref%FOUND;
            CLOSE c_ueeref;

            OPEN c_ueedetref (r_ueeref.no_uee, r_uee.no_com, r_uee.no_lig_com);
            FETCH c_ueedetref INTO r_ueedetref;
            found_ueedetref := c_ueedetref%FOUND;
            CLOSE c_ueedetref;

            --2: MAj UEE de référence
            -------------------------
            IF found_ueeref AND found_ueedetref THEN

                v_etape := 'Maj UEE de référence';
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' ' || v_etape||' '||r_ueeref.no_uee);
                END IF;

                UPDATE pc_uee SET
                    nb_pce_theo = nb_pce_theo + v_nb_pce_theo,
                    pds_theo    = pds_theo + v_pds_theo,
                    etat_atv_pc_uee = 'CREA' -- sinon pb sur la creation du plan
                WHERE no_uee = r_ueeref.no_uee;

                v_etape := 'Maj UEE DET de référence';
                UPDATE pc_uee_det SET
                    qte_theo = qte_theo + v_qte_theo,
                    nb_pce_theo = nb_pce_theo + v_nb_pce_theo,
                    pds_theo = pds_theo + v_pds_theo
                WHERE no_uee = r_ueedetref.no_uee AND
                      no_com = r_ueedetref.no_com AND no_lig_com = r_ueedetref.no_lig_com;

            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj|| ' ' || v_etape||' no_res:' || r_uee.no_uee || ' / qte_theo:' || TO_CHAR(v_qte_theo)||' r_uee.qte_theo:'||r_uee.qte_theo);
            END IF;

            --3: Delete PC_UEE_DET créé à partir de l'UEE de ref.
            -----------------------------------------------------
            v_etape := 'Maj UEE det de réference';
            UPDATE pc_uee_det SET
                qte_theo = qte_theo - v_qte_theo,
                nb_pce_theo = nb_pce_theo - v_nb_pce_theo,
                pds_theo = pds_theo - v_pds_theo
            WHERE no_uee = r_uee.no_uee AND
                  no_com = r_ueedetref.no_com AND no_lig_com = r_ueedetref.no_lig_com
            RETURNING qte_theo INTO v_qte;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' v_qte_theo:' || TO_CHAR(v_qte_theo)||' / v_qte:'||v_qte);
            END IF;

            IF v_qte <=0 THEN
                v_etape := 'efface saisie temporaire';
                DELETE FROM pc_val_pc
                    WHERE typ_val_pc = 'T' AND no_uee = r_uee.no_uee AND
                          no_com = r_ueedetref.no_com AND no_lig_com = r_ueedetref.no_lig_com;

                v_etape:='effacement normal ligne colis';
                v_mode_arc:= su_global_pkv.v_mode_arc;

                --positionne v_mode_arc a MANU pour ne pas archiver
                su_global_pkv.v_mode_arc:='MANU';

                DELETE FROM pc_uee_det
                   WHERE no_uee = r_uee.no_uee
                     AND no_com = r_ueedetref.no_com
                     AND no_lig_com = r_ueedetref.no_lig_com;

                 -- repositionne v_mode_arc;
                 su_global_pkv.v_mode_arc:=v_mode_arc;


                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj|| ' delete pc_uee_det n°:' ||r_uee.no_uee || '-' ||
                                     r_ueedetref.no_com || '-' || TO_CHAR(r_ueedetref.no_lig_com));
                END IF;
            END IF;

            --4: Delete PC_UEE créé à partir de l'UEE de ref.
            -------------------------------------------------
            v_etape := 'Maj UEE de réference';
            UPDATE pc_uee SET
                nb_pce_theo = nb_pce_theo - v_nb_pce_theo,
                pds_theo = pds_theo - v_pds_theo
            WHERE no_uee = r_uee.no_uee
            RETURNING nb_pce_theo INTO v_qte;

            IF v_qte <= 0 THEN
                v_etape := 'ctl pc_uee_det';
                OPEN c_ctl (r_uee.no_uee);
                FETCH c_ctl INTO r_ctl;
                IF c_ctl%NOTFOUND THEN
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' delete pc_uee n°:' ||r_uee.no_uee );
                    END IF;

                    v_etape:='effacement normal colis';
                    v_mode_arc:= su_global_pkv.v_mode_arc;

                    --positionne v_mode_arc a MANU pour ne pas archiver
                    su_global_pkv.v_mode_arc:='MANU';

                    DELETE FROM pc_uee
                    WHERE no_uee = r_uee.no_uee;

                    -- repositionne v_mode_arc;
                    su_global_pkv.v_mode_arc:=v_mode_arc;

                ELSE
                    -- le colis arrive à zéro or il reste des lignes de colis ...
                    -- cas anormal => signaler par anomalie
                    su_bas_cre_ano (p_txt_ano         => 'Qté nulle sur colis',
                                    p_cod_err_ora_ano => SQLCODE,
                                    p_niv_ano         => 2,
                                    p_lib_ano_1       => 'no_uee',
                                    p_par_ano_1       => r_uee.no_uee,
                                    p_lib_ano_2       => 'nb lignes',
                                    p_par_ano_2       => TO_CHAR(r_ctl.nb_lig),
                                    p_lib_ano_3       => 'nb pce lig',
                                    p_par_ano_3       => TO_CHAR(r_ctl.nb_pce_theo),
                                    p_cod_err_su_ano  => 'PC-ORDO030',
                                    p_nom_obj         => v_nom_obj,
                                    p_version         => v_version);
                    --
                    -- remise a jour du colis ... ou effacement si lignes à 0
                    --
                    IF NVL(r_ctl.nb_pce_theo,0) > 0 THEN
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj||' Recuperation qte sur pc_uee n°:' ||r_uee.no_uee );
                        END IF;

                        v_etape := 'recup qte';
                        UPDATE pc_uee SET
                            nb_pce_theo = r_ctl.nb_pce_theo,
                            pds_theo    = r_ctl.pds_theo
                        WHERE no_uee = r_uee.no_uee;
                    ELSE
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj||' delete pc_uee_det + pc_uee n°:' ||r_uee.no_uee );
                        END IF;
                        v_mode_arc:= su_global_pkv.v_mode_arc;
                        --positionne v_mode_arc a MANU pour ne pas archiver
                        su_global_pkv.v_mode_arc:='MANU';

                        v_etape:='efface lignes colis';
                        DELETE FROM pc_uee_det
                        WHERE no_uee = r_uee.no_uee;

                        v_etape:='efface colis';
                        DELETE FROM pc_uee
                        WHERE no_uee = r_uee.no_uee;
                        -- repositionne v_mode_arc;
                        su_global_pkv.v_mode_arc:=v_mode_arc;


                    END IF;

                END IF;
                CLOSE c_ctl;

            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' : v_qte_libere:' || v_qte_libere||' / r_uee.qte_theo:'||r_uee.qte_theo);
            END IF;

            --Pour forcer la sortie du loop si une v_qte>0 donc pas delete
            IF v_qte_libere < r_uee.qte_theo THEN
                v_qte_libere := v_qte_libere - r_uee.qte_theo;
            END IF;

            v_qte_libere_valid:= nvl(v_qte_libere_valid,0) + v_qte_theo;

        END LOOP;
        CLOSE c_uee;

        --5: contrôle s'il n''existe pas des uee vide
        ---------------------------------------------
        v_etape := 'contrôle UEE vide';
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj|| ' ' || v_etape);
        END IF;

        OPEN c_ueevide;
        LOOP
            FETCH c_ueevide INTO r_ueevide;
            EXIT WHEN c_ueevide%NOTFOUND;

            OPEN c_ueeref(r_ueevide.no_com, r_ueevide.no_lig_com);
            FETCH c_ueeref INTO r_ueeref;
            found_ueeref := c_ueeref%FOUND;
            CLOSE c_ueeref;

            OPEN c_ueedetref (r_ueeref.no_uee, r_ueevide.no_com, r_ueevide.no_lig_com);
            FETCH c_ueedetref INTO r_ueedetref;
            found_ueedetref := c_ueedetref%FOUND;
            CLOSE c_ueedetref;

            IF found_ueeref AND found_ueedetref THEN
                v_etape := 'Recharge colis de référence';
                UPDATE pc_uee SET
                    nb_pce_theo = nb_pce_theo + r_ueevide.nb_pce_theo,
                    pds_theo = pds_theo + r_ueevide.pds_theo
                WHERE no_uee = r_ueeref.no_uee;

                OPEN c_ueedetvide (r_ueevide.no_uee);
                LOOP
                    FETCH c_ueedetvide INTO r_ueedetvide;
                    EXIT WHEN c_ueedetvide%NOTFOUND;

                    v_etape := 'Maj UEE det de référence';
                    UPDATE pc_uee_det SET
                        qte_theo = qte_theo + r_ueedetvide.qte_theo,
                        nb_pce_theo = nb_pce_theo + r_ueedetvide.nb_pce_theo,
                        pds_theo = pds_theo + r_ueedetvide.pds_theo
                    WHERE no_uee = r_ueedetref.no_uee AND
                          no_com = r_ueedetref.no_com AND no_lig_com = r_ueedetref.no_lig_com;
                END LOOP;
                CLOSE c_ueedetvide;
            END IF;

            v_etape := 'supprime pic du colis origine';
            v_mode_arc:= su_global_pkv.v_mode_arc;
            --positionne v_mode_arc a MANU pour ne pas archiver
            su_global_pkv.v_mode_arc:='MANU';

            DELETE FROM pc_pic WHERE cod_pic IN (SELECT cod_pic
                                                 FROM pc_pic_uee a
                                                 WHERE no_uee = r_ueevide.no_uee AND
                                                       no_com = r_ueevide.no_com AND no_lig_com = r_ueevide.no_lig_com);

            v_etape := 'supprime lien du colis origine';
            DELETE FROM pc_pic_uee WHERE no_uee = r_ueevide.no_uee AND
                                         no_com = r_ueevide.no_com AND
                                         no_lig_com = r_ueevide.no_lig_com;

            v_etape := 'supprime ligne colis';
            DELETE FROM pc_uee_det WHERE no_uee = r_ueevide.no_uee AND
                                         no_com = r_ueevide.no_com AND
                                         no_lig_com = r_ueevide.no_lig_com;

            v_etape := 'supprime colis si plus de ligne';
            DELETE FROM pc_uee WHERE no_uee = r_ueevide.no_uee AND NOT EXISTS (SELECT 1 FROM pc_uee_det a WHERE a.no_uee = r_ueevide.no_uee);
            -- repositionne v_mode_arc;
            su_global_pkv.v_mode_arc:=v_mode_arc;


        END LOOP;
        CLOSE c_ueevide;

    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
    su_global_pkv.v_mode_arc:='AUTO';

        ROLLBACK TO bas_decrea_uee_id_res_sp;

        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'id_res',
                        p_par_ano_1       => TO_CHAR(p_id_res),
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        v_ret:=NVL(v_cod_err_su_ano,'ERROR');
        RETURN v_ret;
END;

/****************************************************************************
*   pc_bas_resa_stk -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet d'effectuer une réservation de stock
-- ferme sur les UEE lockées par la vague
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- ------------------------------------------------------------------------
-- 17a,14.01.15,mco2    Ajout d'un parametre a l'appel de pc_bas_calcul_surclause_where
-- 16a,21.07.14,mnev    Ajout du cod_usn dans pc_rstk.
-- 15b,18.07.14,mnev    Corrige calcul dlcmin dlcmax en mode sans resa.
-- 15a,11.04.14,mnev    Creation si besoin d'une ligne de reservation forcee
--                      en mode preordo ligne
-- 14a,10.04.14,mnev    Supprime utilisation de se_stk ds le mode preordo ligne.
--                      Ajout de car_stk_1 à car_stk_20 dans pc_rstk_det
--                      Passage du cod_soc_proprio à se_bas_res_stk.
-- 13a,26.02.14,mnev    Gestion de l'éclatement de la reservation du preordo ligne
-- 12a,13.12.12,mnev    gestion d'un timeout pour le traitement
-- 11d,05.11.12,mnev    suppression de v_mode_res et utilisation de p_mode_res
--                      deja existante.
-- 11c,20.04.12,rbel    correction absence renseignement ref_stk pour le mode
--                      sans résa de stock
-- 11b,23.01.11,rbel    ajout tri sur nb colis dans palette exp sur curseur c_uee_rgp
-- 11a,02.08.11,mnev    branchement de la creation des colis juste après
--                      se_bas_res_stk.
-- 10b,01.08.11,mnev    ajout test qte_theo > 0 ds curseur c_uee_rgp
-- 10a,16.02.11,mnev    ajout paramètre p_cb_derog_auto
-- 09b,15.02.11,rleb    ajout déréservation colis non entier, si pss=CC et
--                      creation uee par rapport à la résa.
-- 09a,25.01.11,mnev    ajout prise en compte de l'UEE de reférence
-- 08a,05.10.10,mnev    ajout no_grp dans su_lst_pss
-- 07a,04.10.10,mnev    ajout controle pulse activite
-- 06c,15.04.10,rbel    mise à jour DLC_MIN même si la valeur est NULL
-- 06b,12.03.10,mnev    passe dlc_min à se_bas_res_stk ...
-- 06a,21.01.10,mnev    passe le code process à fonction prk_rch_lst_compatible
-- 05c,29.12.09,mnev    bascule neutre en neutre + prk
--                      ajoute typ_prk dans contexte de qualification
--                      pc_bas_trace avec traduction
-- 05b,15.12.09,mnev    gestion de la reservation sur ref commerciale $CDE
-- 05a,04.12.09,mnev    ajout donnees dans contexte de qualification
-- 04c,02.11.09,alfl    ajout de trace dans la reservation de stock (pc_bas_trace)
-- 04b,29.10.09,mnev    refonte qte et unite en mode multi vl (cod_vl='%')
-- 04a;29.10.09,rbel    Commit à chaque tour pour libération d'enregistrements
-- 03d,16.10.09,alfl    conversion qte_a_res en UB si on est en multi vl
-- 03c,24.09.09,mnev    Evite de boucler et d'appeler se_bas_xxx pour rien
--                      Ajout calcul liste magasins du groupe
-- 03b,18.03.09,mnev    Correction pour rester mono-process sur un colis
--                      detail.
-- 03a,25.02.09,mnev    Gestion configuration de reservation via su_lst_pss
-- 02c,29.01.09,mnev    Amelioration de l'algo sur le generique :
-- 02c,29.01.09,mnev    On déroule par couple (process,magasin) le curseur
--                      pss_final.
-- 02b,27.12.08,tcho    gestion commande de réassort
-- 02a,19.12.08,mnev    Gestion du mode_res_stk_pc
-- 01i,04.12.08,mnev    Controle etat_atv_pc_uee_det dans curseur.
-- 01h,07.11.08,mnev    On doit prendre le process dans le colis et pas
--                      dans la ligne de commande.
-- 01g,05.11.08,mnev    Correction calcul liste des prk pour reservation.
-- 01f,30.10.08,mnev    Réécriture du curseur de selection :
--                      - prise en compte avancee des UEE de regroupement.
-- 01e,08.10.08,mnev    Passe les contraintes de reservation dans car_stk_x
-- 01d,01.10.08,mnev    le curseur de rch de process ne DOIT PLUS prendre
--                      en compte le stock. Les contraintes liées à la
--                      recherche de stock sont à traiter par la
--                      configuration de la clause de réservation.
-- 01c,05.05.08,mnev    ajout gestion du n° de colis p_no_uee pour resa CD
-- 01b,05.05.08,mnev    correction sur curseur c_uee_rgp pour les colis CD
-- 01a,23.04.07,gqui    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_typ_vag    : type de vague
--  p_ss_typ_vag : sous type de vague
--
-- RETOUR :
-- --------
--  OK
--  TIMEOUT : sortie OK mais avant la fin de traitement de toute la selection ...
--  ERROR
--
-- COMMIT :
-- --------
--  !!!!!!!!!! OUI !!!!!!!!!!!

FUNCTION pc_bas_resa_stk (p_cod_usn           su_usn.cod_usn%TYPE,
                          p_typ_vag           pc_vag.typ_vag%TYPE,
                          p_ss_typ_vag        pc_vag.ss_typ_vag%TYPE,
                          p_no_vag            pc_vag.no_vag%TYPE,
                          p_cod_verrou        VARCHAR2,
                          p_crea_plan         VARCHAR2,
                          p_cod_up            pc_uee.cod_up%TYPE      DEFAULT NULL,    -- Utilisation possible en mode manuel
                          p_typ_up            pc_uee.typ_up%TYPE      DEFAULT NULL,    --
                          p_no_com            pc_lig_com.no_com%TYPE  DEFAULT NULL,    --
                          p_no_lig_com        pc_lig_com.no_com%TYPE  DEFAULT NULL,    --
                          p_no_uee            pc_uee.no_uee%TYPE      DEFAULT NULL,    --
                          p_qte_dem           pc_lig_com.qte_cde%TYPE DEFAULT NULL,    --
                          p_cod_pss_dem       VARCHAR2                DEFAULT NULL,    --
                          p_cod_prk_dem       VARCHAR2                DEFAULT NULL,    --
                          p_cod_mag_dem       VARCHAR2                DEFAULT NULL,    --
                          p_where_sup         VARCHAR2                DEFAULT NULL,    --
                          p_mode_res          VARCHAR2                DEFAULT 'AUTO',  --
                          p_cod_pro           pc_lig_com.cod_pro%TYPE DEFAULT NULL,    --
                          p_cod_va            pc_lig_com.cod_va%TYPE  DEFAULT NULL,    --
                          p_cod_vl            pc_lig_com.cod_vl%TYPE  DEFAULT NULL,    --
                          p_cb_contrat_dt     VARCHAR2                DEFAULT 'A',     -- auto
                          p_cb_substitution   VARCHAR2                DEFAULT 'A',     --
                          p_cb_derog_auto     VARCHAR2                DEFAULT 'A')     -- auto
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 17a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_resa_stk:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(100) := NULL;
    v_status            VARCHAR2(20);
    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- déclarations de variables
    v_id_res            pc_rstk.id_res%TYPE;
    v_id_res_porl       pc_rstk.id_res%TYPE;
    v_etat_atv_uee_min  VARCHAR2(20);
    v_etat_atv_uee_max  VARCHAR2(20);
    v_etat_atv_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE;
    v_etat_atv_resa     pc_rstk.etat_atv_pc_rstk%TYPE;
    v_qte_result        se_stk_res.qte_res%TYPE;
    v_qte_restant       se_stk_res.qte_res%TYPE := -1;
    v_qte_deres         se_stk_res.qte_res%TYPE := 0;
    v_qte_a_res         NUMBER := 0;
    v_qte_dem           NUMBER := 0;
    v_cod_pss_defaut    su_pss.cod_pss%TYPE;
    v_typ_resa          VARCHAR2(10);           -- Ferme ou Global
    v_trt_resa_ec       VARCHAR2(10) := 'OK';   -- Traitement Resa sur colis eb cours
    v_i                 NUMBER :=0;
    v_no_uee_max_ec     pc_uee.no_uee%TYPE := NULL;
    v_no_com_ec         pc_lig_com.no_com%TYPE := NULL;
    v_no_lig_com_ec     pc_lig_com.no_lig_com%TYPE := NULL;
    v_cod_cfg_rstk      VARCHAR2(50);
    v_autor_rgl_prk_cpt VARCHAR2(20);
    v_lst_typ_rgl_prk       VARCHAR2(100);
    v_autor_resa_multi_vl   VARCHAR2(20);
    v_mode_neutre_plus_prk  VARCHAR2(20);
    v_pct_qte_min_pal_res   VARCHAR2(20);
    v_pct_qte_max_pal_res   VARCHAR2(20);
    v_qte_stk_min        NUMBER := 0;
    v_list_cod_prk       VARCHAR2(2000);
    v_list_cod_pss_prk   VARCHAR2(2000);
    v_list_id_action_prk VARCHAR2(2000);
    v_no_vag_rstk        NUMBER;
    v_dat_dlc_min        DATE   := NULL;
    v_dat_dlc_max        DATE   := NULL;
    v_dat_1_min          DATE   := NULL;
    v_nb_con_min_pal     NUMBER := NULL;
    v_nb_con_max_pal     NUMBER := NULL;
    v_qte_res_stk        pc_rstk_det.qte_res%TYPE;
    v_qte_res_lig        pc_rstk_det.qte_res%TYPE;
    v_qte_res_ub         pc_rstk_det.qte_res%TYPE;
    v_mode_round_pic     se_ent_rstk.mode_round_pic%TYPE;
    v_mode_round_res     se_ent_rstk.mode_round_res%TYPE;
    v_typ_prk            su_lst_pss.typ_prk%TYPE;
    v_qte_ub             pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_ul             pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_pds            pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_pce            pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_colis          pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_pal            pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_vol            pc_rstk_det.qte_res%TYPE := NULL;
    v_qte_unit_2         pc_rstk_det.qte_res%TYPE := NULL;
    v_unit_stk_2         VARCHAR2(10):=NULL;
    v_qte_tmp            pc_rstk_det.qte_res%TYPE := NULL;
    v_cod_mag_dem        VARCHAR2(30):=NULL;
    v_cod_prk_dem        VARCHAR2(30):=NULL;

    v_unit_tmp           VARCHAR2(10):=NULL;
    v_trace              NUMBER:=0;
    v_trace_sub          NUMBER:=0;
    v_trace_v_nb_con_min_pal    VARCHAR2(50):=NULL;
    v_trace_v_nb_con_max_pal    VARCHAR2(50):=NULL;
    v_trace_v_dat_dlc_min       VARCHAR2(50):=NULL;
    v_trace_v_dat_dlc_max       VARCHAR2(50):=NULL;
    v_trace_mag_rch             VARCHAR2(50):=NULL;
    v_trace_v_qte_stk_min       VARCHAR2(50):=NULL;
    v_trace_v_fct_pro_sub       VARCHAR2(50):=NULL;
    v_trace_cod_vl              VARCHAR2(30);


    -- Déclaration d'un tableau des magasins de picking/reservation/reservation+typ_prk
    v_list_mag          pc_ordo_pkg.tt_lst_mag;
    v_where             VARCHAR2(4000);

    v_debut             TIMESTAMP;
    v_debut_tot         TIMESTAMP;

    -- Déclarations des curseurs
    -- --------------------------
    -- Curseur PC_UEE
    -- On effectue des regroupements de colis par ligne commandes et par
    -- palette du plan
    CURSOR c_uee_rgp (x_etat_atv_uee_min  pc_uee.etat_atv_pc_uee%TYPE,
                      x_etat_atv_uee_max  pc_uee.etat_atv_pc_uee%TYPE,
                      x_etat_atv_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
    SELECT l.no_com,
           l.no_lig_com,
           l.cod_cfg_pal_1,
           m.val_ctr_res_1,
           m.val_ctr_res_2,
           m.val_ctr_res_3,
           m.val_ctr_res_4,
           m.val_ctr_res_5,
           m.val_ctr_res_6,
           m.val_ctr_res_7,
           m.val_ctr_res_8,
           m.val_ctr_res_9,
           m.val_ctr_res_10,
           m.val_ctr_res_11,
           m.val_ctr_res_12,
           m.val_ctr_res_13,
           m.val_ctr_res_14,
           m.val_ctr_res_15,
           m.val_ctr_res_16,
           m.val_ctr_res_17,
           m.val_ctr_res_18,
           m.val_ctr_res_19,
           m.val_ctr_res_20,
           m.cod_lot_res,
           m.lst_mag_res,
           m.cod_prk_res cod_prk,
           e.dat_prep,
           e.dat_dem,
           e.cod_soc,
           l.cod_pro,
           l.cod_va,
           l.cod_vl,
           l.typ_col,
           l.id_res_porl,
           u.cod_pss_afc,
           DECODE(u.no_uee_ref,u.no_uee,'1','0') uee_ref,
           l.etat_autor_prk,
           l.etat_autor_chg_vl,
           l.mode_res_stk_pc,
           l.dlc_min,
           l.dlc_max,
           l.pcb_exp ,
           SUM(d.qte_theo) qte_cde,
           DECODE(l.typ_col,'CD',d.no_uee, DECODE(u.nb_col_theo,1,NULL,u.no_uee)) no_uee,
           MAX(d.no_uee) no_uee_max,
           d.unite_qte,
           MAX(u.cod_cnt) cod_cnt,
           u.cod_up,
           u.typ_up,
           m.cod_ctr_res,
           m.fct_pro_sub_aut,
           m.fct_pro_sub_man,
           d.cod_qlf_trv
    FROM pc_uee u, pc_uee_det d, pc_lig_com l, pc_ent_com e, pc_lig_cmd m
    WHERE l.no_com = e.no_com                                                     AND
          l.no_com = d.no_com                                                     AND
          l.no_lig_com = d.no_lig_com                                             AND
          l.no_cmd = m.no_cmd AND l.no_lig_cmd = m.no_lig_cmd                     AND
          l.cod_err_pc_lig_com  IS NULL                                           AND
          l.id_session_lock  = v_session_ora                                      AND
          d.id_res IS NULL                                                        AND
          INSTR(l.lst_fct_lock, ';'||p_cod_verrou||';') > 0                       AND
          u.no_uee = d.no_uee                                                     AND
          INSTR(u.lst_fct_lock, ';'||p_cod_verrou||';') > 0                       AND
          u.etat_atv_pc_uee IN (SELECT *
                                  FROM TABLE(su_bas_list_etat_atv(x_etat_atv_uee_min, x_etat_atv_uee_max,'PC_UEE'))) AND
          d.etat_atv_pc_uee_det = x_etat_atv_uee_det                              AND
          u.cod_err_pc_uee  IS NULL                                               AND
          d.cod_err_pc_uee_det IS NULL                                            AND
          d.qte_theo > 0                                                          AND
          (u.cod_pss_afc = p_cod_pss_dem OR p_cod_pss_dem IS NULL)                AND
          --(p_qte_dem IS NULL OR -- $MOD,mnev,normalement plus necessaire ...
          --(u.nb_col_theo = 1 AND p_no_uee IS NULL AND p_qte_dem IS NOT NULL) OR
          --(u.nb_col_theo > 1 AND p_no_uee IS NOT NULL AND p_qte_dem IS NOT NULL)) AND
          (u.cod_up = p_cod_up OR p_cod_up IS NULL)                               AND
          (u.typ_up = p_typ_up OR p_typ_up IS NULL)                               AND
          (e.no_com = p_no_com OR p_no_com IS NULL)                               AND
          (u.no_uee = p_no_uee OR p_no_uee IS NULL)                               AND
          (l.no_lig_com = p_no_lig_com OR p_no_lig_com IS NULL)
    GROUP BY l.no_com, l.no_lig_com, l.cod_cfg_pal_1,
             m.val_ctr_res_1, m.val_ctr_res_2, m.val_ctr_res_3,
             m.val_ctr_res_4, m.val_ctr_res_5, m.val_ctr_res_6,
             m.val_ctr_res_7, m.val_ctr_res_8, m.val_ctr_res_9,
             m.val_ctr_res_10,m.val_ctr_res_11,m.val_ctr_res_12,
             m.val_ctr_res_13,m.val_ctr_res_14,m.val_ctr_res_15,
             m.val_ctr_res_16,m.val_ctr_res_17,m.val_ctr_res_18,
             m.val_ctr_res_19,m.val_ctr_res_20,
             m.cod_lot_res,m.lst_mag_res,m.cod_prk_res,
             e.dat_prep, e.dat_dem, e.cod_soc,
             l.cod_pro, l.cod_va, l.cod_vl, l.typ_col,l.pcb_exp, l.id_res_porl,
             u.cod_pss_afc,  l.etat_autor_prk, l.etat_autor_chg_vl, l.mode_res_stk_pc,
             l.dlc_min, l.dlc_max,
             DECODE(l.typ_col, 'CD', d.no_uee, DECODE(u.nb_col_theo,1,NULL,u.no_uee)),
             DECODE(u.no_uee_ref,u.no_uee,'1','0'),
             d.unite_qte, u.cod_up, u.typ_up , u.nb_col_theo,
             m.cod_ctr_res, m.fct_pro_sub_aut, m.fct_pro_sub_man, d.cod_qlf_trv
    ORDER BY NVL(e.dat_prep, e.dat_dem) ASC, l.no_com ASC,
             SUM(d.qte_theo) DESC,
             u.cod_up ASC,
             DECODE(l.typ_col, 'CC', DECODE(u.nb_col_theo,1,1,0), 'CD', 2) ASC,  -- en premier les colis complet
             DECODE(l.typ_col, 'CC', l.no_lig_com, 'CD', MAX(u.no_uee)) ASC; -- par ligne si colis complet
                                                                             -- par colis si colis détail
    r_uee_rgp      c_uee_rgp%ROWTYPE;
    found_uee_rgp  BOOLEAN;

    v_no_uee_ref   pc_uee.no_uee_ref%TYPE;

    -- Curseur sur les lignes de réservations
    -- (lecture dans SE)
    CURSOR c_lig_rstk (x_no_rstk se_lig_rstk.no_rstk%TYPE) IS
    SELECT lrs.no_rstk, lrs.no_lig_rstk,
        lrs.no_stk, lrs.cod_mag_piC,
        lrs.qte_res,
        ers.unit_res,
        s.cod_pro, s.cod_vl,
        s.cod_va, s.cod_prk, s.cod_emp,
        s.unit_stk_1 unit_stk,
        s.cod_usn, s.cod_mag,
        s.cod_lot_stk,
        s.cod_ss_lot_stk, s.dat_dlc,
        s.dat_stk, s.dat_ent_mag,
        s.cod_ut, s.typ_ut,
        s.car_stk_1, s.car_stk_2, s.car_stk_3,
        s.car_stk_4, s.car_stk_5, s.car_stk_6,
        s.car_stk_7, s.car_stk_8, s.car_stk_9,
        s.car_stk_10, s.car_stk_11, s.car_stk_12,
        s.car_stk_13, s.car_stk_14, s.car_stk_15,
        s.car_stk_16, s.car_stk_17, s.car_stk_18,
        s.car_stk_19, s.car_stk_20,
        s.cod_soc_proprio
    FROM se_ent_rstk ers, se_lig_rstk lrs, se_stk s
    WHERE lrs.no_stk = s.no_stk AND
          lrs.no_rstk = x_no_rstk AND
          ers.no_rstk = lrs.no_rstk
    ORDER BY lrs.no_lig_rstk;

    r_lig_rstk    c_lig_rstk%ROWTYPE;

    -- Curseur sur les lignes de réservations issues de
    -- la reservation ferme du preordo ligne
    -- (lecture dans PC à cause de qte_rdis necessaire pour la redistribution)
    CURSOR c_lig_porl (x_id_res pc_rstk.id_res%TYPE,
                       x_qte    pc_rstk.qte_res%TYPE) IS
    SELECT lrs.id_res no_rstk, lrs.no_lig_rstk,
        lrs.no_stk, lrs.cod_mag_pic,
        lrs.qte_res - NVL(lrs.qte_rdis,0) qte_res,
        ers.unite_qte unit_res,
        lrs.cod_pro, lrs.cod_vl,
        lrs.cod_va, lrs.cod_prk, lrs.cod_emp,
        lrs.unit_stk,
        lrs.cod_usn, lrs.cod_mag,
        lrs.cod_lot_stk,
        lrs.cod_ss_lot_stk, lrs.dat_dlc,
        lrs.dat_stk, lrs.dat_ent_mag,
        lrs.cod_ut, lrs.typ_ut,
        lrs.car_stk_1, lrs.car_stk_2, lrs.car_stk_3,
        lrs.car_stk_4, lrs.car_stk_5, lrs.car_stk_6,
        lrs.car_stk_7, lrs.car_stk_8, lrs.car_stk_9,
        lrs.car_stk_10, lrs.car_stk_11, lrs.car_stk_12,
        lrs.car_stk_13, lrs.car_stk_14, lrs.car_stk_15,
        lrs.car_stk_16, lrs.car_stk_17, lrs.car_stk_18,
        lrs.car_stk_19, lrs.car_stk_20,
        lrs.cod_soc_proprio
    FROM pc_rstk ers, pc_rstk_det lrs
    WHERE lrs.id_res = x_id_res AND
          ers.id_res = lrs.id_res AND
          NVL(lrs.qte_rdis,0) < lrs.qte_res
    ORDER BY DECODE(SIGN(lrs.qte_res - NVL(lrs.qte_rdis,0) - x_qte), 0, 0, -1, 1, 2), lrs.cod_emp, lrs.cod_ut, lrs.cod_lot_stk, lrs.no_lig_rstk;

    r_lig_porl    c_lig_porl%ROWTYPE;

    vr_pc_rstk    pc_rstk%ROWTYPE;

    -- Curseur de recherche du process final
    CURSOR c_pss_final (x_cod_pss     su_pss_mag.cod_pss%TYPE,
                        x_autor_prk   VARCHAR2,
                        x_lst_mag_res VARCHAR2,
                        x_cod_pss_cd  su_pss.cod_pss%TYPE,
                        x_cod_qlf_trv VARCHAR2) IS
       -- Selection sur la VL commandée
       SELECT NVL(lp.cod_pss_final, pm.cod_pss) COD_PSS_FINAL,  --1
            pm.cod_mag,              --2
            pm.no_grp,               --3
            pm.no_ord_grp,           --4
            lp.no_ord no_ord_pss,    --5
            pm.tst_dlc_min,          --6
            --lp.cod_mag cod_mag_force,-- 7
            pm.typ_prk typ_prk_force,-- 8
            lp.cod_cfg_rstk,         -- 9
            lp.pct_qte_min_pal_res,  -- 10
            lp.pct_qte_max_pal_res,  -- 11
            lp.mode_lst_rch,         -- 12
            lp.having_ges_qte
       FROM su_pss_mag pm, su_lst_pss lp, su_pss_mag c
       WHERE pm.cod_pss =  x_cod_pss           AND
              (pm.autor_res_auto = '1' OR p_mode_res = 'MANU') AND
              ((pm.typ_prk > '0' AND x_autor_prk = '1') OR pm.typ_prk = '0' OR pm.typ_prk = '$CDE') AND
              lp.cod_pss(+) = pm.cod_pss        AND
              lp.cod_mag(+) = pm.cod_mag        AND
              lp.typ_prk(+) = pm.typ_prk        AND
              lp.no_grp(+)  = pm.no_grp         AND
              c.cod_pss     = NVL(lp.cod_pss_final, pm.cod_pss) AND
              c.cod_mag     = pm.cod_mag AND
              c.typ_prk     = pm.typ_prk AND
              (c.etat_cfg_stk_pic <> '2' OR lp.cod_pss_final IS NULL) AND
              (lp.cod_pss_final = x_cod_pss_cd OR
               x_cod_pss_cd IS NULL OR
               pm.cod_pss = x_cod_pss_cd) AND
              (x_lst_mag_res IS NULL OR INSTR(x_lst_mag_res,';'||pm.cod_mag||';')>0) AND
              (lp.lst_typ_trv IS NULL OR INSTR(lp.lst_typ_trv,';'||x_cod_qlf_trv||';') > 0)
       GROUP BY NVL(lp.cod_pss_final, pm.cod_pss), pm.cod_mag, pm.no_grp,
                pm.no_ord_grp, lp.no_ord,
                pm.tst_dlc_min, lp.cod_mag, pm.typ_prk, lp.cod_cfg_rstk,
                lp.pct_qte_min_pal_res, lp.pct_qte_max_pal_res, lp.mode_lst_rch, lp.having_ges_qte
       ORDER BY 3, 4, 5;

    r_pss_final         c_pss_final%ROWTYPE;
    v_lst_pss_trt       VARCHAR2(4000);
    v_lst_mag_frc       VARCHAR2(2000);
    v_clef              VARCHAR2(500);

    -- Recherche action 1 et 2 du paramètre mode_res_stk_pc
    CURSOR c_par (x_par su_lig_par.par%TYPE) IS
        SELECT action_lig_par_1 cod_cfg_res,
               action_lig_par_2 prio_pss
        FROM su_lig_par
        WHERE nom_par = 'MODE_RES_STK_PC' AND par = x_par
          AND cod_module = 'SU' AND etat_actif = '1';

    r_par c_par%ROWTYPE;

    -- recherche article commercial
    CURSOR c_refcde (x_no_cmd     pc_lig_cmd.no_cmd%TYPE,
                     x_no_lig_cmd pc_lig_cmd.no_lig_cmd%TYPE) IS
        SELECT cod_pro_cde, cod_va_cde, cod_vl_cde
        FROM pc_lig_cmd
        WHERE no_cmd = x_no_cmd AND no_lig_cmd = x_no_lig_cmd;

    r_refcde c_refcde%ROWTYPE;

    v_cod_pss_cd    su_pss.cod_pss%TYPE := NULL;

    r_lig_com       pc_lig_com%ROWTYPE;
    r_ent_rstk      se_ent_rstk%ROWTYPE;
    v_ctr           se_ctr_res_pkg.tt_ctr;
    v_fct_pro_sub   pc_lig_cmd.fct_pro_sub_aut%TYPE;
    v_cod_pro       pc_lig_com.cod_pro%TYPE;
    v_cod_va        pc_lig_com.cod_va%TYPE;
    v_cod_vl        pc_lig_com.cod_vl%TYPE;
    v_fin_rch_pss   VARCHAR2(10);
    v_abandon       VARCHAR2(10);
    v_dat_activite  DATE := NULL;

    v_typ_pss           VARCHAR2(10):=NULL;
    v_qte_a_dereserver  NUMBER:=0;
    v_qte_entiere       NUMBER:=0;

    CURSOR c_resa_crea_uee (x_no_rstk se_ent_rstk.no_rstk%TYPE) IS
    SELECT e.no_rstk, l.cod_pro, l.cod_va, l.cod_vl, SUM(qte_res) qte_res, e.unit_res
    FROM se_lig_rstk l, se_ent_rstk e
    WHERE l.no_rstk=e.no_rstk
      AND l.no_rstk=x_no_rstk
    GROUP BY e.no_rstk, l.cod_pro, l.cod_va, l.cod_vl, e.unit_res;

    r_resa_crea_uee c_resa_crea_uee%ROWTYPE;

    v_ref_rstk_1    pc_rstk.ref_rstk_1%TYPE;
    v_ref_rstk_2    pc_rstk.ref_rstk_2%TYPE;
    v_ref_rstk_3    pc_rstk.ref_rstk_3%TYPE;
    v_ref_rstk_4    pc_rstk.ref_rstk_4%TYPE;
    v_ref_rstk_5    pc_rstk.ref_rstk_5%TYPE;

    v_profondeur    NUMBER(6);

    v_timeout       NUMBER;
    v_dat_sortie    DATE;
    v_retour        VARCHAR2(20) := 'OK';

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
        su_bas_put_debug('p_no_com:' || p_no_com);
        su_bas_put_debug('p_no_lig_com:' || TO_CHAR(p_no_lig_com));
        su_bas_put_debug('p_no_uee:' || p_no_uee);
        su_bas_put_debug('p_cb_contrat_dt:' || p_cb_contrat_dt);
        su_bas_put_debug('p_cb_substitution:' || p_cb_substitution);
        su_bas_put_debug('p_cb_derog_auto:' || p_cb_derog_auto);
    END IF;

    -- lecture du timeout configure en fonction du mode ...
    v_etape := 'is_number';
    v_timeout := su_bas_is_number(su_bas_rch_action (p_nom_par   =>'PC_TIMEOUT',
                                                     p_par       =>'ORD_' || p_mode_res,
                                                     p_no_action => 1));
    IF v_timeout IS NOT NULL THEN
        v_etape := 'timeout';
        v_dat_sortie := SYSDATE + v_timeout/86400;
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug('Avec gestion d''un timeout:' || TO_CHAR(v_dat_sortie, 'DD/MM/YYYY HH24:MI:SS'));
        END IF;
    ELSE
        v_dat_sortie := NULL;
    END IF;

    /************************
    1) PHASE INITIALISATION
    ************************/
    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_PC_ORDO_RESA_STK') THEN
        v_ret_evt := pc_evt_ordo_resa_stk( 'PRE',
                                        p_cod_usn,
                                        p_typ_vag,
                                        p_ss_typ_vag,
                                        p_no_vag,
                                        p_cod_verrou,
                                        p_crea_plan,
                                        p_cod_up,
                                        p_typ_up,
                                        p_no_com,
                                        p_no_lig_com,
                                        p_no_uee,
                                        p_qte_dem,
                                        p_cod_pss_dem,
                                        p_cod_prk_dem,
                                        p_cod_mag_dem);

        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;
    /********************
    2) PHASE TRAITEMENT
    ********************/
    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_PC_ORDO_RESA_STK') THEN
        v_ret_evt := pc_evt_ordo_resa_stk( 'ON',
                                        p_cod_usn,
                                        p_typ_vag,
                                        p_ss_typ_vag,
                                        p_no_vag,
                                        p_cod_verrou,
                                        p_crea_plan,
                                        p_cod_up,
                                        p_typ_up,
                                        p_no_com,
                                        p_no_lig_com,
                                        p_no_uee,
                                        p_qte_dem,
                                        p_cod_pss_dem,
                                        p_cod_prk_dem,
                                        p_cod_mag_dem);
         IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    /**********************
     DEBUT TRAITEMENT STD
    **********************/
    IF v_ret_evt IS NULL THEN
        -- Lecture etat
        v_etat_atv_uee_det := su_bas_rch_etat_atv('CREATION','PC_UEE_DET');
        -- Recherche l'etat d'activité
        -- si calcul du plan expédition après resa
        IF p_crea_plan IN ( pc_ordo_pkv.AVEC_CALCUL_PLAN_AVANT_RESA,
                            pc_ordo_pkv.AVEC_CALCUL_PLAN_APRES_RESA,
                            pc_ordo_pkv.AVEC_CALCUL_PLAN_FIN_ORDO) THEN  -- plan a calculer

            v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                               p_cod_action_atv => 'VALIDATION_PLAN',
                                               p_nom_table      => 'PC_UEE');

            v_etat_atv_uee_min := su_bas_rch_etat_atv (
                                               p_cod_action_atv=> 'CREATION',
                                               p_nom_table      => 'PC_UEE');

        ELSE   -- sinon le plan existe déjà
            v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                               p_cod_action_atv => 'VALIDATION_PLAN',
                                               p_nom_table      => 'PC_UEE');

            v_etat_atv_uee_min := v_etat_atv_uee_max;
        END IF;

        -- Recherche des mode d'arrondi par rapport au process default de l'usine
        v_cod_pss_defaut   := su_bas_get_pss_defaut(p_cod_usn);
        v_status := su_bas_rch_cle_atv_pss(v_cod_pss_defaut,
                                          'ORD',            -- Type d'activité
                                          'MODE_ROUND_PIC',
                                           v_mode_round_pic);
        v_status := su_bas_rch_cle_atv_pss(v_cod_pss_defaut,
                                          'ORD',            -- Type d'activité
                                          'MODE_ROUND_RES',
                                           v_mode_round_res);

        -- Recherche l'etat d'activité pour la création des resas
        v_etat_atv_resa := su_bas_rch_etat_atv (p_cod_action_atv    => 'CREATION',
                                                p_nom_table         => 'PC_RSTK');

        IF su_global_pkv.v_niv_dbg >= 2 THEN
            su_bas_put_debug(v_nom_obj||'*** BEGIN T=0');
        END IF;
        v_debut_tot := SYSTIMESTAMP;
        v_debut     := v_debut_tot;

        -- initialisation de la quantite ... NULL = TOUT
        v_qte_dem := p_qte_dem;

        v_etape := 'LOOP sur les colis pc_uee groupés';
        v_trt_resa_ec := 'OK';            -- init valeur
        OPEN c_uee_rgp(v_etat_atv_uee_min, v_etat_atv_uee_max, v_etat_atv_uee_det);
        LOOP
            FETCH c_uee_rgp INTO r_uee_rgp;
            --
            -- Conditions de sortie remplies ?
            -- (rollback eventuel apres le end loop ...)
            --
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                IF c_uee_rgp%NOTFOUND THEN
                    su_bas_put_debug(v_nom_obj||' NOT FOUND');
                END IF;

                IF NVL(v_qte_dem,1) <= 0 THEN
                    su_bas_put_debug(v_nom_obj||' QTE <= 0');
                END IF;
            END IF;
            EXIT WHEN c_uee_rgp%NOTFOUND OR NVL(v_qte_dem,1) <= 0;

            v_cod_pro  := NVL(p_cod_pro, r_uee_rgp.cod_pro);
            v_cod_va   := NVL(p_cod_va,  r_uee_rgp.cod_va);
            v_cod_vl   := NVL(p_cod_vl,  r_uee_rgp.cod_vl);

            IF su_global_pkv.v_niv_dbg >= 2 THEN
                su_bas_put_debug(v_nom_obj||'*** Fetch T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                v_debut := SYSTIMESTAMP;
            END IF;

            v_etape :=  'Traitement sur Lig-Com: ' ||
                         r_uee_rgp.no_com || '-' || TO_CHAR(r_uee_rgp.no_lig_com) || ' UEE:' || r_uee_rgp.no_uee ||
                         ' UP:' || r_uee_rgp.cod_up || ' ' || r_uee_rgp.typ_up ||
                         ' Process:' || r_uee_rgp.cod_pss_afc ||
                         ' MagDem:' || p_cod_mag_dem ||
                         ' Qte:' || r_uee_rgp.qte_cde || ' ' || r_uee_rgp.unite_qte;

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || v_etape);
            END IF;

            IF pc_trace_pkg.get_autor_resa THEN
                IF r_uee_rgp.no_uee IS NOT NULL THEN
                    pc_bas_trace('ORDO_MANU',1,
                                 'Lig Com $1 / UEE $2 / UL $3 / A réserver $4',
                                 p_1=>p_no_com||'-'||to_char(p_no_lig_com),
                                 p_2=>r_uee_rgp.no_uee,
                                 p_3=>v_cod_pro||'-'||v_cod_vl,
                                 p_4=>to_char(NVL(LEAST(v_qte_dem,r_uee_rgp.qte_cde), r_uee_rgp.qte_cde))||' '||r_uee_rgp.unite_qte);
                ELSE
                    pc_bas_trace('ORDO_MANU',1,
                                 'Lig Com $1 / UP $2 / UL $3 / A réserver $4',
                                 p_1=>p_no_com||'-'||to_char(p_no_lig_com),
                                 p_2=>r_uee_rgp.cod_up || ' ' || r_uee_rgp.typ_up,
                                 p_3=>v_cod_pro||'-'||v_cod_vl,
                                 p_4=>to_char(NVL(LEAST(v_qte_dem,r_uee_rgp.qte_cde), r_uee_rgp.qte_cde))||' '||r_uee_rgp.unite_qte);
                END IF;

                IF r_uee_rgp.cod_ctr_res IS NOT NULL THEN
                    pc_bas_trace('ORDO_MANU',2,
                                 'Présence contrat : $1',
                                 p_1=>r_uee_rgp.cod_ctr_res);
                END IF;

            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                 su_bas_put_debug(v_nom_obj || 'contrat cod_ctr_res=' || r_uee_rgp.cod_ctr_res);
                 su_bas_put_debug(v_nom_obj || 'no_max_ec=' || TO_CHAR(v_no_uee_max_ec));
                 su_bas_put_debug(v_nom_obj || 'no_max=' || TO_CHAR(r_uee_rgp.no_uee_max));
            END IF;

            -- Récupération du row de la ligne commande
            --------------------------------------------
            r_lig_com := su_bas_grw_pc_lig_com(r_uee_rgp.no_com, r_uee_rgp.no_lig_com);

            -- Dépose d'un savepoint pour un groupe de colis
            -- ---------------------------------------------
            IF (v_no_uee_max_ec IS NULL OR  r_uee_rgp.no_uee_max <> v_no_uee_max_ec) AND
               v_trt_resa_ec = 'ERROR' THEN
               v_etape := 'ROLLBACK TO my_sp_pc_bas_resa_rgp';
               ROLLBACK TO my_sp_pc_bas_resa_rgp;  -- on doit au préalable rollbacker
               IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || v_etape);
               END IF;

               -- Dépose d'un savepoint pour le nouveau groupe colis
               v_etape := 'savepoint Trt=ERR';
               SAVEPOINT my_sp_pc_bas_resa_rgp;
               v_no_uee_max_ec := r_uee_rgp.no_uee_max;
               v_no_com_ec     := r_uee_rgp.no_com;
               v_no_lig_com_ec := r_uee_rgp.no_lig_com;
               v_trt_resa_ec  := 'OK';
               v_cod_pss_cd    := NULL;
               IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj || v_etape);
               END IF;

            ELSIF (v_no_uee_max_ec IS NULL OR  r_uee_rgp.no_uee_max <> v_no_uee_max_ec) THEN

               --$MOD,rbel,29.10.09, on commit à chaque changement de groupe de colis
               COMMIT;

               IF v_timeout IS NOT NULL THEN

                   -- sortie si délai atteint
                   IF SYSDATE > v_dat_sortie THEN

                       v_retour := 'TIMEOUT';
                       su_bas_cre_ano (p_txt_ano         => 'Sortie sur timeout',
                                       p_niv_ano         => 3,
                                       p_cod_err_ora_ano => SQLCODE,
                                       p_lib_ano_1       => 'Usine',
                                       p_par_ano_1       => p_cod_usn,
                                       p_lib_ano_2       => 'TypVag',
                                       p_par_ano_2       => p_typ_vag,
                                       p_lib_ano_3       => 'SsTypVag',
                                       p_par_ano_3       => p_ss_typ_vag,
                                       p_lib_ano_4       => 'Delai(sec)',
                                       p_par_ano_4       => v_timeout,
                                       p_cod_err_su_ano  => 'PC-ORDO999',
                                       p_nom_obj         => v_nom_obj,
                                       p_version         => v_version);
                       EXIT;
                   END IF;

               END IF;

               IF p_mode_res = 'AUTO' THEN
                   v_etape := 'Controle pulse activite:' || su_global_pkv.v_cod_ope;
                   su_bas_ctl_activity(su_global_pkv.v_cod_ope, v_dat_activite);
               END IF;

               -- Dépose d'un savepoint pour le nouveau groupe colis
               v_etape := 'savepoint CHGT';
               SAVEPOINT my_sp_pc_bas_resa_rgp;
               -- Recup du groupe colis en cours
               v_no_uee_max_ec := r_uee_rgp.no_uee_max;
               v_no_com_ec     := r_uee_rgp.no_com;
               v_no_lig_com_ec := r_uee_rgp.no_lig_com;
               v_trt_resa_ec   := 'OK';
               v_cod_pss_cd    := NULL;
               IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj || v_etape);
               END IF;

            END IF;

            --------------------------------------------------------------------------------
            -- On ne peut faire une RESERVATION que si v_trt_resa_ec = OK'
            -- Dans le cas d'un colis détail si une des lignes du colis n'est pas réservée
            -- alors l'ensemble des résas du colis doivent être avortées (ROLLBACK)
            --------------------------------------------------------------------------------
            IF v_trt_resa_ec = 'OK' THEN
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj || 'cod_pss_afc: ' || r_uee_rgp.cod_pss_afc);
                    su_bas_put_debug(v_nom_obj || 'cod_pss_cd : ' || v_cod_pss_cd);
                END IF;

                v_etape := 'Debut boucle FOR pour la réservation';
                v_fin_rch_pss := 'NON';
                v_lst_pss_trt := '?';
                v_qte_a_res   := NVL(LEAST(v_qte_dem,r_uee_rgp.qte_cde), r_uee_rgp.qte_cde);          -- Qte a réserver


                IF p_cod_mag_dem IS NOT NULL THEN
                    v_cod_mag_dem:= ';'||p_cod_mag_dem||';' ;
                ELSE
                    v_cod_mag_dem:=NULL;
                END IF;

                -- profondeur de rch
                v_profondeur := 0;

                v_etape := 'Start IDP ORDRCH';
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '0');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '1');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '2');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '3');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '4');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '5');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '6');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '7');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '8');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => '9');
                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_ORDRCH',
                                             p_cod_idp => 'N');

                FOR r_pss_final IN c_pss_final (r_uee_rgp.cod_pss_afc,
                                                r_uee_rgp.etat_autor_prk,
                                                NVL(r_uee_rgp.lst_mag_res,v_cod_mag_dem),
                                                v_cod_pss_cd,
                                                r_uee_rgp.cod_qlf_trv)
                LOOP

                  -- considition de sortie ...
                  EXIT WHEN v_qte_a_res <= 0 OR v_trt_resa_ec <> 'OK' OR v_fin_rch_pss = 'OUI';

                  v_profondeur := v_profondeur + 1;

                  v_etape := 'inital = final ?';
                  IF r_pss_final.no_ord_pss IS NULL THEN
                      -- process initial = process final : donc 1 seule boucle suffira...
                      --v_fin_rch_pss := 'OUI';
                      r_pss_final.no_grp     := NULL;   -- juste pour la clef ...
                      r_pss_final.no_ord_grp := NULL;   --
                  END IF;

                  -- ---------------------------
                  -- neutre = neutre + prémarqué
                  -- ---------------------------
                  v_etape := 'neutre + prk ?';
                  IF r_pss_final.typ_prk_force = '0' THEN
                      v_status := su_bas_rch_cle_atv_pss(r_uee_rgp.cod_pss_afc,
                                                         'ORD', -- type activité
                                                         'MODE_NEUTRE_PLUS_PRK',
                                                         v_mode_neutre_plus_prk);
                      IF v_mode_neutre_plus_prk = '1' THEN
                          r_pss_final.typ_prk_force := NULL;
                      END IF;
                  END IF;

                  -- --------------------------------------------------------------------------
                  -- le no_ord_pss est renseigne uniquement si config du generique (su_lst_pss)
                  -- --------------------------------------------------------------------------
                  -- calcul clef pour eviter de relancer 2 actions de resa identiques
                  v_etape := 'calcul clef';
                  v_clef :=  r_pss_final.cod_pss_final || '#' || r_pss_final.no_grp || '#' ||
                             r_pss_final.typ_prk_force || '#' || r_pss_final.cod_cfg_rstk || '#' ||
                             TO_CHAR(r_pss_final.pct_qte_min_pal_res) || '#' ||
                             TO_CHAR(r_pss_final.pct_qte_max_pal_res) || '#' ||
                             r_pss_final.mode_lst_rch || '#' || r_pss_final.having_ges_qte;

                  IF su_global_pkv.v_niv_dbg >= 3 THEN
                      su_bas_put_debug(v_nom_obj || ' *** FETCH:' || v_clef);
                  END IF;

                  -- si process pas encore traite ...
                  IF INSTR(NVL(v_lst_pss_trt,'#NULL#'), ';' || v_clef || ';') = 0 THEN -- {

                    v_lst_mag_frc := NULL;

                    -- le no_ord_pss est renseigne uniquement si config du generique (su_lst_pss)
                    IF r_pss_final.no_ord_pss IS NOT NULL THEN
                        v_etape := 'calcul mag groupe';
                        v_lst_mag_frc := pc_bas_cal_lst_mag_par_groupe (r_uee_rgp.cod_pss_afc,
                                                                        r_pss_final.cod_pss_final,
                                                                        r_pss_final.no_grp,
                                                                        r_pss_final.typ_prk_force,
                                                                        r_pss_final.cod_cfg_rstk,
                                                                        r_pss_final.pct_qte_min_pal_res,
                                                                        r_pss_final.pct_qte_max_pal_res,
                                                                        r_pss_final.mode_lst_rch,
                                                                        r_pss_final.having_ges_qte,
                                                                        p_mode_res);
                    END IF;

                    -- ajouter le process dans la liste (process OU process + magasin si générique)
                    v_lst_pss_trt := v_lst_pss_trt || ';' || v_clef || ';';

                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj || ' *** ' || 'OK pour traitement Mag:' || NVL(v_lst_mag_frc,'a calculer'));
                    END IF;

                    -- --------------------------
                    -- Traitement du typ_prg $CDE
                    -- --------------------------
                    IF r_pss_final.typ_prk_force = '$CDE' THEN
                        --r_pss_final.typ_prk_force := '0';
                        v_etape := 'open c_refcde';
                        OPEN c_refcde (r_lig_com.no_cmd, r_lig_com.no_lig_cmd);
                        FETCH c_refcde INTO r_refcde;
                        CLOSE c_refcde;

                        v_etape := 'map sur ref cde';
                        -- on passe sur la reference commerciale
                        v_cod_pro := r_refcde.cod_pro_cde;
                        v_cod_va  := r_refcde.cod_va_cde;
                        v_cod_vl  := r_refcde.cod_vl_cde;

                    ELSE
                        -- reprendre l'article origine
                        v_cod_pro  := NVL(p_cod_pro, r_uee_rgp.cod_pro);
                        v_cod_va   := NVL(p_cod_va,  r_uee_rgp.cod_va);
                        v_cod_vl   := NVL(p_cod_vl,  r_uee_rgp.cod_vl);
                    END IF;

                    -- test si le process est compatible pour l'ordo pour
                    -- la ligne commande ('TRUE' => process qualifié)
                    IF su_bas_tst_qlf_pss(pr_lig_com    =>r_lig_com,
                                          p_cod_qlf     =>r_pss_final.cod_pss_final,
                                          p_cle_rch_qlf =>'ORD',
                                          p_ctx_lib_N1   =>'p_qte_a_res',
                                          p_ctx_par_N1   =>v_qte_a_res,
                                          p_ctx_lib_V1   =>'p_unite_res',
                                          p_ctx_par_V1   =>r_uee_rgp.unite_qte,
                                          p_ctx_lib_V2   =>'p_cod_pro_res',
                                          p_ctx_par_V2   =>v_cod_pro,
                                          p_ctx_lib_V3   =>'p_cod_va_res',
                                          p_ctx_par_V3   =>v_cod_va,
                                          p_ctx_lib_V4   =>'p_cod_vl_res',
                                          p_ctx_par_V4   =>v_cod_vl,
                                          p_ctx_lib_V5   =>'p_typ_prk',
                                          p_ctx_par_V5   =>r_pss_final.typ_prk_force
                                          ) = 'TRUE' THEN

                        v_abandon := NULL;
                        --------------------------------
                        -- Recherche des clefs de config
                        --------------------------------
                        v_etape := 'Process qualifie. Rch clef cfg sur PSS ' || r_pss_final.cod_pss_final;
                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                            su_bas_put_debug(v_nom_obj || ' /// ' || v_etape);
                        END IF;

                        -- Recherche de la valeur de la clef 'AUTOR_RGL_PRK_CPT'
                        -- Cette clef permet ou non l'autorisation de traiter
                        -- des règles de compatibilité pour les PRK.
                        v_status := su_bas_rch_cle_atv_pss(r_pss_final.cod_pss_final,
                                               'ORD', -- type activité
                                               'AUTOR_RGL_PRK_CPT',
                                                v_autor_rgl_prk_cpt);

                        -- Recherche de la valeur de la clef 'LST_TYP_RGL_PRK'
                        -- Cette clef permet de récupérer les types de règles PRK
                        -- que l'on peut utiliser
                        -- N'est fonctionnel que si le paramètre précédent "Autorisation de traiter
                        -- des règles de compatibilité pour les PRK" est activé.
                        v_status := su_bas_rch_cle_atv_pss(r_pss_final.cod_pss_final,
                                               'ORD', -- type activité
                                               'LST_TYP_RGL_PRK',
                                                v_lst_typ_rgl_prk);

                        -- Recherche de la valeur de la clef 'AUTOR_RESA_MULTI_VL'
                        -- Cette clef permet ou non l'autorisation de traiter
                        -- la resa sur toutes les VL du produit.
                        v_status := su_bas_rch_cle_atv_pss(r_pss_final.cod_pss_final,
                                               'ORD', -- type activité
                                               'AUTOR_RESA_MULTI_VL',
                                                v_autor_resa_multi_vl);

                        -- Recherche de la valeur de la clef 'COD_CFG_RSTK'
                        -- Pour la config de réservation
                        IF r_pss_final.cod_cfg_rstk IS NULL THEN
                            v_status := su_bas_rch_cle_atv_pss(r_pss_final.cod_pss_final,
                                                  'ORD', -- type activité
                                                  'COD_CFG_RSTK',
                                                   v_cod_cfg_rstk );
                        ELSE
                            v_cod_cfg_rstk := r_pss_final.cod_cfg_rstk;
                        END IF;

                        -- Recherche de la valeur de la clef 'PCT_MIN_QTE_PAL_RES'
                        -- Permet de prendre en considération une taille minimale
                        -- de palette en stock par rapport à son std
                        IF r_pss_final.pct_qte_min_pal_res IS NULL THEN
                            v_status := su_bas_rch_cle_atv_pss(r_pss_final.cod_pss_final,
                                                  'ORD', -- type activité
                                                  'PCT_QTE_MIN_PAL_RES',
                                                   v_pct_qte_min_pal_res);
                        ELSE
                            v_pct_qte_min_pal_res := r_pss_final.pct_qte_min_pal_res;
                        END IF;


                        -- Recherche de la valeur de la clef 'PCT_MAX_QTE_PAL_RES'
                        -- Pour la config de réservation
                        -- Permet de prendre en considération une taille maximale
                        -- de palette en stock par rapport à son std
                        IF r_pss_final.pct_qte_max_pal_res IS NULL THEN
                            v_status := su_bas_rch_cle_atv_pss(r_pss_final.cod_pss_final,
                                                  'ORD', -- type activité
                                                  'PCT_QTE_MAX_PAL_RES',
                                                   v_pct_qte_max_pal_res);
                        ELSE
                            v_pct_qte_max_pal_res := r_pss_final.pct_qte_max_pal_res;
                        END IF;

                        -- Test si les pourcentage en min et max sont respectivement > 0 et < 100
                        -- si oui, on doit calculer les quantités en min et max pour la réservation
                        -- d'une palette en stock. La palette doit se trouver bornée en terme de quantité
                        -- entre ces 2 valeurs
                        IF NVL(v_pct_qte_min_pal_res, 0) > 0 OR NVL(v_pct_qte_max_pal_res, 100) < 100 THEN
                            pc_bas_calcul_borne_pal(p_cod_cfg_pal    =>r_uee_rgp.cod_cfg_pal_1,
                                                    p_cod_cnt        =>r_uee_rgp.cod_cnt,
                                                    p_pct_min_pal    =>v_pct_qte_min_pal_res,
                                                    p_pct_max_pal    =>v_pct_qte_max_pal_res,
                                                    p_nb_con_min_pal =>v_nb_con_min_pal,
                                                    p_nb_con_max_pal =>v_nb_con_max_pal);
                        ELSE
                            v_nb_con_min_pal := NULL;
                            v_nb_con_max_pal := NULL;
                        END IF;

                        -- ---------------------------------------------------------------
                        -- il faut controler la qté commandée par rapport au min et eu max
                        -- ---------------------------------------------------------------
                        v_etape := 'ctrl qte min max';
                        NULL;
                        IF v_nb_con_min_pal IS NOT NULL OR v_nb_con_max_pal IS NOT NULL THEN
                            -- init a NULL
                            v_qte_colis  := NULL;
                            v_qte_unit_2 := NULL;
                            v_unit_stk_2 := NULL;
                            v_qte_ub     := NULL;
                            v_qte_ul     := NULL;
                            v_qte_pds    := NULL;
                            v_qte_pce    := NULL;
                            v_qte_pal    := NULL;
                            v_qte_vol    := NULL;

                            v_etape:=' conversion car multi VL autorise:';
                            v_ret := su_bas_conv_unite_to_all(p_cod_pro =>v_cod_pro,  -- code pro origine
                                           p_cod_vl     =>r_uee_rgp.cod_vl,           -- code VL origine
                                           p_pcb        =>r_uee_rgp.pcb_exp,          -- pcb de la ligne commande
                                           p_qte_unit_1 =>v_qte_a_res,
                                           p_unit_stk_1 =>r_uee_rgp.unite_qte,
                                           p_qte_colis  =>v_qte_colis,
                                           p_qte_unit_2 =>v_qte_unit_2,
                                           p_unit_stk_2 =>v_unit_stk_2,
                                           p_qte_ub     =>v_qte_ub,
                                           p_qte_ul     =>v_qte_ul,
                                           p_qte_pds    =>v_qte_pds,
                                           p_qte_pce    =>v_qte_pce,
                                           p_qte_pal    =>v_qte_pal,
                                           p_qte_vol    =>v_qte_vol);

                            IF v_qte_colis < NVL(v_nb_con_min_pal,0) OR v_qte_colis > NVL(v_nb_con_max_pal,999999) THEN
                                -- abandon car hors fourchette
                                v_abandon := 'HORSSEUIL';
                            END IF;

                        END IF;

                        v_etape := 'Rch action par';
                        OPEN c_par (r_uee_rgp.mode_res_stk_pc);
                        FETCH c_par INTO r_par;
                        IF c_par%NOTFOUND THEN
                            r_par.cod_cfg_res := NULL;
                            r_par.prio_pss    := NULL;
                        END IF;
                        CLOSE c_par;

                        IF r_par.cod_cfg_res IS NOT NULL THEN
                            -- SI pas de priorite au process ...
                            IF NVL(r_par.prio_pss,'1') = '0' THEN
                                -- ALORS on prend le code renseigné dans la config donnée
                                -- par la ligne de commande
                                v_cod_cfg_rstk := r_par.cod_cfg_res;

                            -- SI priorite au process mais code sans réservation ...
                            ELSIF NVL(r_par.prio_pss,'1') = '1' AND v_cod_cfg_rstk = 'SANS' THEN
                                -- ALORS on prend le code renseigné dans la config donnée
                                -- par la ligne de commande
                                v_cod_cfg_rstk := r_par.cod_cfg_res;
                            END IF;
                        END IF;

                        IF pc_trace_pkg.get_autor_resa THEN
                            IF r_pss_final.typ_prk_force = '0' THEN
                                pc_bas_trace ('ORDO_MANU',1,'Essai process $1 / Mag $2 / en Neutre / Cfg $3',
                                              p_1=>r_pss_final.cod_pss_final,
                                              p_2=>NVL(v_lst_mag_frc,'f(pss final)'),
                                              p_3=>v_cod_cfg_rstk);
                            ELSIF r_pss_final.typ_prk_force = '$CDE' THEN
                                pc_bas_trace ('ORDO_MANU',1,'Essai process $1 / Mag $2 / Réf commerciale $3 / Cfg $4',
                                              p_1=>r_pss_final.cod_pss_final,
                                              p_2=>NVL(v_lst_mag_frc,'f(pss)'),
                                              p_3=>v_cod_pro || '-' || v_cod_va || '-' || v_cod_vl,
                                              p_4=>v_cod_cfg_rstk);
                            ELSIF r_pss_final.typ_prk_force IS NULL THEN
                                pc_bas_trace ('ORDO_MANU',1,'Essai process $1 / Mag $2 / Neutre OU prémarqué / Cfg $3',
                                              p_1=>r_pss_final.cod_pss_final,
                                              p_2=>NVL(v_lst_mag_frc,'f(pss)'),
                                              p_3=>v_cod_cfg_rstk);
                            ELSE
                                pc_bas_trace ('ORDO_MANU',1,'Essai process $1 / Mag $2 / en Prémarqué type $3 / Cfg $4',
                                              p_1=>r_pss_final.cod_pss_final,
                                              p_2=>NVL(v_lst_mag_frc,'f(pss)'),
                                              p_3=>NVL(r_pss_final.typ_prk_force,'?'),
                                              p_4=>v_cod_cfg_rstk);
                            END IF;
                        END IF;

                        IF v_cod_cfg_rstk = 'SANS' THEN
                            v_typ_resa := '99';      -- Pas de RESA => Réservation virtuelle

                            v_etape := 'calcul DLC min - sans resa';
                            IF r_uee_rgp.dlc_min IS NULL THEN
                                -- dlc min
                                pc_bas_rch_contrat_date (p_no_com       =>r_uee_rgp.no_com,
                                                         p_no_lig_com   =>r_uee_rgp.no_lig_com,
                                                         p_typ_ctt_date =>'DLC_MIN',
                                                         p_date         =>v_dat_dlc_min
                                                         );

                                IF v_dat_dlc_min IS NOT NULL THEN
                                    v_etape := 'MAJ dlc min/max';
                                    UPDATE pc_lig_com l SET
                                        l.dlc_min = v_dat_dlc_min
                                    WHERE l.no_com = r_uee_rgp.no_com AND l.no_lig_com = r_uee_rgp.no_lig_com;
                                END IF;

                            END IF;

                            v_etape := 'calcul DLC max - sans resa';
                            IF r_uee_rgp.dlc_max IS NULL THEN
                                 -- dlc_max
                                 pc_bas_rch_contrat_date (p_no_com       =>r_uee_rgp.no_com,
                                                          p_no_lig_com   =>r_uee_rgp.no_lig_com,
                                                          p_typ_ctt_date =>'DLC_MAX',
                                                          p_date         =>v_dat_dlc_max
                                                          );

                                 IF v_dat_dlc_max IS NOT NULL THEN
                                     v_etape := 'MAJ dlc min/max';
                                     UPDATE pc_lig_com l SET
                                         l.dlc_max = v_dat_dlc_max
                                     WHERE l.no_com = r_uee_rgp.no_com AND l.no_lig_com = r_uee_rgp.no_lig_com;
                                 END IF;
                             END IF;

                        ELSE
                            -- Recherche du type de réservation en fonction du code de configuration
                            v_typ_resa := su_bas_gcl_se_cfg_rstk(v_cod_cfg_rstk, 'MODE_RSTK');

                            -- Calcul d'une surclause where
                            -------------------------------
                            v_etape := 'Calcul d''une surclause v_where';  -- contrat date ou limite palette ou spécif
                            v_where := NULL;
                            v_dat_dlc_min := r_uee_rgp.dlc_min;
                            v_dat_dlc_max := r_uee_rgp.dlc_max;

                            IF NVL(p_cb_derog_auto,'A') = '1' THEN
                                --
                                -- les dérogation sont déjà intégrées dans la p_where_sup par l'écran ...
                                --
                                v_etape := 'calcul surclause (1)';
                                pc_bas_calcul_surclause_where (p_no_com         => r_uee_rgp.no_com,
                                                               p_no_lig_com     => r_uee_rgp.no_lig_com,
                                                               p_dat_dlc_min    => v_dat_dlc_min,
                                                               p_dat_dlc_max    => v_dat_dlc_max,
                                                               p_where_sup      => p_where_sup,
                                                               p_dat_1_min      => v_dat_1_min,
                                                               p_nb_con_min_pal => v_nb_con_min_pal,
                                                               p_nb_con_max_pal => v_nb_con_max_pal,
                                                               p_having_ges_qte => r_pss_final.having_ges_qte,
                                                               p_where          => v_where,
                                                               p_mode_res       => p_mode_res,
															   p_cb_contrat_dt  => p_cb_contrat_dt); --$MOD,mco2 04a
                            ELSE
                                v_etape := 'calcul surclause (2)';
                                pc_bas_calcul_surclause_where (p_no_com         => r_uee_rgp.no_com,
                                                               p_no_lig_com     => r_uee_rgp.no_lig_com,
                                                               p_dat_dlc_min    => v_dat_dlc_min,
                                                               p_dat_dlc_max    => v_dat_dlc_max,
                                                               p_where_sup      => p_where_sup,
                                                               p_dat_1_min      => v_dat_1_min,
                                                               p_nb_con_min_pal => v_nb_con_min_pal,
                                                               p_nb_con_max_pal => v_nb_con_max_pal,
                                                               p_having_ges_qte => r_pss_final.having_ges_qte,
                                                               p_where          => v_where,
                                                               p_mode_res       => p_mode_res,
                                                               p_cod_ctr_res    => r_uee_rgp.cod_ctr_res,      -- $MODMCOC 21042009 begin
                                                               p_val_ctr_res_1  => r_uee_rgp.val_ctr_res_1,
                                                               p_val_ctr_res_2  => r_uee_rgp.val_ctr_res_2,
                                                               p_val_ctr_res_3  => r_uee_rgp.val_ctr_res_3,
                                                               p_val_ctr_res_4  => r_uee_rgp.val_ctr_res_4,
                                                               p_val_ctr_res_5  => r_uee_rgp.val_ctr_res_5,
                                                               p_val_ctr_res_6  => r_uee_rgp.val_ctr_res_6,
                                                               p_val_ctr_res_7  => r_uee_rgp.val_ctr_res_7,
                                                               p_val_ctr_res_8  => r_uee_rgp.val_ctr_res_8,
                                                               p_val_ctr_res_9  => r_uee_rgp.val_ctr_res_9,
                                                               p_val_ctr_res_10 => r_uee_rgp.val_ctr_res_10,
                                                               p_val_ctr_res_11 => r_uee_rgp.val_ctr_res_11,
                                                               p_val_ctr_res_12 => r_uee_rgp.val_ctr_res_12,
                                                               p_val_ctr_res_13 => r_uee_rgp.val_ctr_res_13,
                                                               p_val_ctr_res_14 => r_uee_rgp.val_ctr_res_14,
                                                               p_val_ctr_res_15 => r_uee_rgp.val_ctr_res_15,
                                                               p_val_ctr_res_16 => r_uee_rgp.val_ctr_res_16,
                                                               p_val_ctr_res_17 => r_uee_rgp.val_ctr_res_17,
                                                               p_val_ctr_res_18 => r_uee_rgp.val_ctr_res_18,
                                                               p_val_ctr_res_19 => r_uee_rgp.val_ctr_res_19,
                                                               p_val_ctr_res_20 => r_uee_rgp.val_ctr_res_20,     -- $MODMCOC 21042009 end
                                                               p_cb_contrat_dt  => p_cb_contrat_dt --$MOD,mco2 04a
															   );
                            END IF;

                            -- si pas de gestion du contrat date ...
                            IF NVL(p_cb_contrat_dt,'1') = '0' THEN
                                v_dat_dlc_min := NULL;
                                v_dat_dlc_max := NULL;
                            END IF;

                            IF (v_dat_dlc_min IS NOT NULL AND r_uee_rgp.dlc_min IS NULL)          OR
                                (v_dat_dlc_min IS NOT NULL AND v_dat_dlc_min <> r_uee_rgp.dlc_min) OR
                                (v_dat_dlc_max IS NOT NULL AND r_uee_rgp.dlc_max IS NULL)          OR
                                (v_dat_dlc_max IS NOT NULL AND v_dat_dlc_max <> r_uee_rgp.dlc_max) THEN

                                -- on doit mettre a jour la ligne commande
                                v_etape := 'Update pc_lig_com, dlc_min, dlc_max';
                                IF su_global_pkv.v_niv_dbg >= 3 THEN
                                     su_bas_put_debug(v_nom_obj || v_etape
                                         || ' No_com-no_lig_com:' || r_uee_rgp.no_com || '-'
                                         || TO_CHAR(r_uee_rgp.no_lig_com)
                                         || ' dlc_min:' || TO_CHAR(v_dat_dlc_min,'DDMMYYYY')
                                         || ' dlc_max:' || TO_CHAR(v_dat_dlc_max,'DDMMYYYY'));
                                END IF;
                                UPDATE pc_lig_com l SET
                                        l.dlc_min = v_dat_dlc_min,
                                        l.dlc_max = v_dat_dlc_max
                                WHERE   l.no_com     = r_uee_rgp.no_com    AND
                                        l.no_lig_com = r_uee_rgp.no_lig_com;
                            END IF;

                            ----------------------------------------------------------
                            -- Calcul de la liste des codes de prémarquage compatible
                            ----------------------------------------------------------
                            -- calcul la liste des indices de prémarquage de la lig-commande;
                            v_etape := 'Calcul la liste de prémarquage de lig_com: '
                                 || r_uee_rgp.no_com || '-' || TO_CHAR(r_uee_rgp.no_lig_com);
                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || v_etape);
                            END IF;

                            IF p_cod_prk_dem IS NULL THEN
                                IF r_pss_final.typ_prk_force = '$CDE' THEN
                                    v_cod_prk_dem := '$CDE';
                                ELSE
                                    v_cod_prk_dem := NULL;
                                END IF;
                            ELSE
                                v_cod_prk_dem := p_cod_prk_dem;
                            END IF;

                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || ' v_cod_prk_dem : ' || v_cod_prk_dem);
                            END IF;

                            v_ret := pc_bas_calcul_lst_prk(p_no_com =>r_uee_rgp.no_com,
                                               p_no_lig_com         =>r_uee_rgp.no_lig_com,
                                               p_cod_prk_dem        =>v_cod_prk_dem,
                                               p_autor_rgl_prk_cpt  =>v_autor_rgl_prk_cpt,
                                               p_lst_typ_rgl_prk    =>v_lst_typ_rgl_prk,
                                               p_list_cod_prk       =>v_list_cod_prk,
                                               p_list_cod_pss_prk   =>v_list_cod_pss_prk,
                                               p_list_id_action_prk =>v_list_id_action_prk,
                                               p_cod_pss            =>r_pss_final.cod_pss_final
                                               );
                            IF v_ret <> 'OK' THEN
                                v_trt_resa_ec := 'ERROR';
                                v_etape := 'Erreur sur calcul de la liste des PRK';
                                IF su_global_pkv.v_niv_dbg >= 3 THEN
                                    su_bas_put_debug(v_nom_obj || v_etape);
                                END IF;
                            END IF;

                            -- Test si les prémarqués sont autorisés pour la ligne
                            IF r_uee_rgp.etat_autor_prk = '0' THEN
                                v_list_cod_prk := ';#NULL#;0;';
                            ELSE
                                IF INSTR(v_list_cod_prk,';0;') > 0 THEN
                                    v_list_cod_prk := v_list_cod_prk || '#NULL#;';
                                END IF;
                            END IF;

                        END IF;        -- IF v_cod_cfg_rstk = 'SANS'  ....

                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || 'code cfg reservation :' || v_cod_cfg_rstk);
                        END IF;

                        IF NVL(r_pss_final.typ_prk_force,'0') <> '0' AND r_pss_final.typ_prk_force <> '$CDE' AND
                           (v_list_cod_prk=';0;#NULL#;' OR v_list_cod_prk=';#NULL#;0;') THEN
                            v_abandon := 'PAS2PRK';
                        END IF;

                        IF r_pss_final.typ_prk_force = '$CDE' AND INSTR(v_list_cod_prk,'$CDE') = 0 THEN
                            v_abandon := 'PAS2CDE';
                        END IF;

                        IF r_pss_final.typ_prk_force = '$CDE' AND INSTR(v_list_cod_prk,'$DIFF') > 0 THEN
                            v_abandon := 'PAS_CPT';
                        END IF;

                        IF v_abandon = 'PAS2PRK' THEN
                            -- la config demande de traiter du premarque
                            -- or il n'y a aucun code dans la liste
                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || 'pas de code prk trouvé. v_list:' || v_list_cod_prk);
                            END IF;
                            IF pc_trace_pkg.get_autor_resa THEN
                                pc_bas_trace ('ORDO_MANU',2,'Abandon, pas de code premarquage utilisable.');
                            END IF;

                        ELSIF v_abandon = 'PAS2CDE' THEN
                            -- la config demande de traiter du premarque
                            -- or il n'y a aucun code dans la liste
                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || 'pas de code $CDE trouvé. v_list:' || v_list_cod_prk);
                            END IF;
                            IF pc_trace_pkg.get_autor_resa THEN
                                pc_bas_trace ('ORDO_MANU',2,'Abandon, pas de config sur la référence commerciale.');
                            END IF;

                        ELSIF v_abandon = 'PAS_CPT' THEN
                            -- la config demande de traiter du premarque
                            -- or il n'y a aucun code dans la liste
                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || 'ref cde pas compatible ' || v_list_cod_prk);
                            END IF;
                            IF pc_trace_pkg.get_autor_resa THEN
                                pc_bas_trace ('ORDO_MANU',2,'Abandon, ref cde pas compatible.');
                            END IF;

                        ELSIF v_abandon = 'HORSSEUIL' THEN
                            -- la config demande de traiter un seuil min et/ou max
                            -- or la qté est déjà hors fourchette ...
                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || 'hors seuil.');
                            END IF;
                            IF pc_trace_pkg.get_autor_resa THEN
                                pc_bas_trace ('ORDO_MANU',2,'Abandon, qté en dehors des seuils min,max.');
                            END IF;

                        ELSE
                          --------------------------------------------------------------
                          -- Calcul d'un tableau de listes des magasins par n° de groupe
                          -- en fonction du process final
                          --------------------------------------------------------------
                          v_etape := 'Calcul liste de magasins';
                          IF r_uee_rgp.lst_mag_res IS NULL THEN
                              --
                              -- pas de liste imposée
                              --

                              IF p_cod_prk_dem IS NULL THEN
                                  v_typ_prk := r_pss_final.typ_prk_force;
                              ELSE
                                  v_typ_prk := su_bas_gcl_su_prk(p_cod_prk_dem,'TYP_PRK');
                              END IF;

                              v_ret := pc_bas_calcul_lst_mag(p_mode_res       => p_mode_res,
                                                             p_cod_pss        => r_pss_final.cod_pss_final,
                                                             p_cod_mag_dem    => NVL(p_cod_mag_dem, v_lst_mag_frc),
                                                             p_typ_prk_dem    => v_typ_prk,
                                                             p_etat_autor_prk => r_uee_rgp.etat_autor_prk,
                                                             p_list_mag       => v_list_mag);

                              IF v_ret <> 'OK' THEN
                                  v_trt_resa_ec := 'ERROR';
                                  v_etape := 'Erreur sur calcul de la liste des magasins';
                                  IF su_global_pkv.v_niv_dbg >= 3 THEN
                                      su_bas_put_debug(v_nom_obj || ' ' || v_etape);
                                  END IF;
                              END IF;

                          ELSE
                              --
                              -- liste imposée
                              --

                              v_list_mag.DELETE;
                              v_list_mag(1).lst_mag_pic := r_uee_rgp.lst_mag_res;
                              v_list_mag(1).lst_mag_res := r_uee_rgp.lst_mag_res;

                              IF r_uee_rgp.cod_prk IS NULL THEN
                                  v_list_mag(1).lst_mag_res_prk := ';' ||replace(substr(r_uee_rgp.lst_mag_res,2),
                                                                   ';',',0;');
                              ELSE
                                v_list_mag(1).lst_mag_res_prk := ';' ||replace(substr(r_uee_rgp.lst_mag_res,2),
                                                                 ';',','|| su_bas_gcl_su_prk(r_uee_rgp.cod_prk,'typ_prk')||';');

                              END IF;

                              v_list_mag(1).lst_mag_rch :=v_list_mag(1).lst_mag_res;
                              v_list_mag(1).lst_mag_rch_prk :=v_list_mag(1).lst_mag_res_prk;

                          END IF;

                          -------------------------------------------------------------
                          -- Test si possibilité de VL multiples
                          -------------------------------------------------------------
                          IF p_cod_vl IS NULL THEN
                              IF v_autor_resa_multi_vl = '1' AND r_uee_rgp.etat_autor_chg_vl = '1' THEN
                                  v_cod_vl := '%';
                                  v_etape:=' on est en VL multiples ';
                                  IF su_global_pkv.v_niv_dbg >= 3 THEN
                                     su_bas_put_debug(v_nom_obj || v_etape);
                                  END IF;
                              ELSE
                                  v_cod_vl := r_uee_rgp.cod_vl;
                              END IF;
                          ELSE
                              v_cod_vl := p_cod_vl;
                          END IF;

                          IF su_global_pkv.v_niv_dbg >= 3 THEN
                            su_bas_put_debug(v_nom_obj || ' on traite la vl '||v_cod_vl);
                          END IF;

                          --------------------------------------------------------------
                          -- Réservation du stock
                          --------------------------------------------------------------
                          -- La liste des magasins de réservations est constituée de magasins sur lesquels
                          -- on peut faire des réservations.
                          -- La liste des magasins de pickings est constituée de magasins ou l'on est autorisé
                          -- a faire du picking (Cette liste est égale ou plus restrictive à la listes des
                          -- magasins de réservation).
                          -- Si v_qte_restant (qte restante a réserver) = 0, la totalité à pu être réservée

                          ---------------------------------------------------------------
                          -- Boucle de réservation sur les différents groupes de magasins
                          ---------------------------------------------------------------
                          v_i := v_list_mag.FIRST;
                          WHILE v_i IS NOT NULL AND v_qte_a_res > 0 AND v_trt_resa_ec = 'OK' -- {
                          LOOP
                            v_etape := 'Demande de résa stock pour Com-lig ' ||
                                   r_uee_rgp.no_com || '-' || TO_CHAR(r_uee_rgp.no_lig_com)  ||
                                  ' Produit: ' || v_cod_pro ||
                                  ' Qte: ' || TO_CHAR(v_qte_a_res) ||
                                  ' Unit: ' ||  r_uee_rgp.unite_qte;
                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || v_etape);
                            END IF;

                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || 'Suite Trace > GRP:' || TO_CHAR(v_i) ||
                                    ' prk: ' || v_list_cod_prk ||
                                    ' lstmag resa:  ' || v_list_mag(v_i).lst_mag_res ||
                                    ' lstmag pic: ' || v_list_mag(v_i).lst_mag_pic ||
                                    ' lstmag resa,prk: ' || v_list_mag(v_i).lst_mag_res_prk ||
                                    ' qte demandée: ' || TO_CHAR(v_qte_dem));
                            END IF;

                            -- si saisie manuelle (qte_dem n'est pas null) : alors on ne controle plus les autres magasins
                            -- OU demande de desactivation des mag de rch  : alors on ne controle plus les autres magasins
                            IF p_qte_dem IS NOT NULL OR r_pss_final.mode_lst_rch IS NULL THEN
                                -- si saisie manuelle alors on ne controle plus les autres magasins
                                v_list_mag(v_i).lst_mag_rch     := v_list_mag(v_i).lst_mag_res;
                                v_list_mag(v_i).lst_mag_rch_prk := v_list_mag(v_i).lst_mag_res_prk;
                            END IF;

                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || 'Suite Trace >' ||
                                    ' lst mag rch: ' || v_list_mag(v_i).lst_mag_rch ||
                                    ' lst mag rch,prk: ' || v_list_mag(v_i).lst_mag_rch_prk);
                            END IF;

                            v_id_res_porl := r_uee_rgp.id_res_porl;

                            -- Test si le code config de resa correspond
                            -- à un mode Sans Réservation de stock
                            IF v_cod_cfg_rstk = 'SANS' THEN

                                -- On réserve une séquence,
                                v_etape := 'Réservation virtuelle';
                                v_id_res := su_bas_seq_unique_nextval (p_nom_seq          => 'SEQ_NO_RSTK' ,
                                                                       p_nom_table        => 'SE_ENT_RSTK',
                                                                       p_nom_col          => 'NO_RSTK');

                                IF v_id_res_porl > 0 THEN

                                    -- ATTENTION, il n'y a pas de réservation dans ce cas de figure
                                    -- Seul, 1 fiche dans PC_RSTK sera insérée
                                    v_qte_restant   := 0;
                                    v_qte_result    := 0;
                                    v_unit_tmp      := 'P';

                                    IF r_uee_rgp.unite_qte <> 'P' THEN
                                        -- conversion en unite 'P'
                                        /*
                                        v_ret := su_bas_conv_unite_to_one(p_cod_pro   =>v_cod_pro,
                                                                          p_cod_vl    =>r_uee_rgp.cod_vl,
                                                                          p_qte_orig  =>v_qte_a_res,
                                                                          p_unite_orig=>r_uee_rgp.unite_qte,
                                                                          p_unite_dest=>'P',
                                                                          p_qte_dest  =>v_qte_tmp);
                                        */

                                        -- init a NULL
                                        v_qte_colis  := NULL;
                                        v_qte_unit_2 := NULL;
                                        v_unit_stk_2 := NULL;
                                        v_qte_ub     := NULL;
                                        v_qte_ul     := NULL;
                                        v_qte_pds    := NULL;
                                        v_qte_pce    := NULL;
                                        v_qte_pal    := NULL;
                                        v_qte_vol    := NULL;

                                        v_ret := su_bas_conv_unite_to_all(p_cod_pro =>v_cod_pro,   -- code pro origine
                                                       p_cod_vl      =>r_uee_rgp.cod_vl,           -- code VL origine
                                                       p_pcb         =>r_uee_rgp.pcb_exp,          -- pcb de la ligne commande
                                                       p_qte_unit_1  =>v_qte_a_res,
                                                       p_unit_stk_1  =>r_uee_rgp.unite_qte,
                                                       p_qte_colis   =>v_qte_colis,
                                                       p_qte_unit_2  =>v_qte_unit_2,
                                                       p_unit_stk_2  =>v_unit_stk_2,
                                                       p_qte_ub      =>v_qte_ub,
                                                       p_qte_ul      =>v_qte_ul,
                                                       p_qte_pds     =>v_qte_pds,
                                                       p_qte_pce     =>v_qte_pce,
                                                       p_qte_pal     =>v_qte_pal,
                                                       p_qte_vol     =>v_qte_vol);

                                        IF v_ret <> 'OK' THEN
                                            RAISE err_except;
                                        END IF;

                                        -- on veut un resultat en pièces
                                        v_qte_tmp := v_qte_pce;

                                    ELSE
                                        v_qte_tmp       := v_qte_a_res;
                                    END IF;

                                ELSE
                                    -- ATTENTION, il n'y a pas de réservation dans ce cas de figure
                                    -- Seul, 1 fiche dans PC_RSTK sera insérée
                                    v_qte_restant   := 0;
                                    v_qte_result    := 0;
                                    v_qte_tmp       := v_qte_a_res;
                                    v_unit_tmp      := r_uee_rgp.unite_qte;

                                END IF;

                                -- reference pour creation pc_rstk ...
                                v_etape := 'references';
                                v_ref_rstk_1 := r_uee_rgp.no_com;
                                v_ref_rstk_2 := TO_CHAR(r_uee_rgp.no_lig_com);
                                v_ref_rstk_3 := r_uee_rgp.no_uee;
                                v_ref_rstk_4 := r_uee_rgp.cod_up;
                                v_ref_rstk_5 := r_uee_rgp.typ_up;

                                v_etape := 'Réservation virtuelle avec id_res: ' || v_id_res
                                           || ' (MODE SANS RESERVATION)';
                                IF su_global_pkv.v_niv_dbg >= 3 THEN
                                    su_bas_put_debug(v_nom_obj || v_etape);
                                END IF;

                                v_fct_pro_sub := NULL;

                            ELSE
                                -- Préemption d'une séquence de réservation pour la vague
                                IF v_no_vag_rstk IS NULL THEN -- inutile de créer un n° de vague à chaque fois
                                    v_etape := 'Préemption d''une séquence de réservation sur SEQ_NO_VAG_RSTK';
                                    v_no_vag_rstk := su_bas_seq_nextval ('SEQ_NO_VAG_RSTK');
                                END IF;
                                v_id_res := NULL;

                                IF NVL(p_cb_substitution,'1') = 'A' THEN
                                    -- on utilise la liste de substitution automatique
                                    v_fct_pro_sub := r_uee_rgp.fct_pro_sub_aut;

                                ELSIF NVL(p_cb_substitution,'1') = '0' THEN
                                    -- pas de substitution : case decochee dans ecran
                                    v_fct_pro_sub := NULL;

                                ELSIF NVL(p_cb_substitution,'1') = '1' THEN
                                    -- on utilise la liste de substitution manuelle
                                    v_fct_pro_sub := r_uee_rgp.fct_pro_sub_man;
                                END IF;

                                IF su_global_pkv.v_niv_dbg >= 3 THEN
                                    su_bas_put_debug(v_nom_obj || 'Fonction substitution:' || v_fct_pro_sub);
                                END IF;

                                IF su_global_pkv.v_niv_dbg >= 2 THEN
                                    su_bas_put_debug(v_nom_obj||'*** Appel SE.RES T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                                    v_debut := SYSTIMESTAMP;
                                END IF;

                                -- il faut convertir la quantité en UB si on est en multi VL
                                IF v_cod_vl = '%' THEN

                                   -- init a NULL
                                   v_qte_colis  := NULL;
                                   v_qte_unit_2 := NULL;
                                   v_unit_stk_2 := NULL;
                                   v_qte_ub     := NULL;
                                   v_qte_ul     := NULL;
                                   v_qte_pds    := NULL;
                                   v_qte_pce    := NULL;
                                   v_qte_pal    := NULL;
                                   v_qte_vol    := NULL;

                                   v_etape:=' conversion car multi VL autorise:';
                                   v_ret := su_bas_conv_unite_to_all(p_cod_pro =>v_cod_pro,   -- code pro origine
                                                  p_cod_vl      =>r_uee_rgp.cod_vl,           -- code VL origine
                                                  p_pcb         =>r_uee_rgp.pcb_exp,          -- pcb de la ligne commande
                                                  p_qte_unit_1  =>v_qte_a_res,
                                                  p_unit_stk_1  =>r_uee_rgp.unite_qte,
                                                  p_qte_colis   =>v_qte_colis,
                                                  p_qte_unit_2  =>v_qte_unit_2,
                                                  p_unit_stk_2  =>v_unit_stk_2,
                                                  p_qte_ub      =>v_qte_ub,
                                                  p_qte_ul      =>v_qte_ul,
                                                  p_qte_pds     =>v_qte_pds,
                                                  p_qte_pce     =>v_qte_pce,
                                                  p_qte_pal     =>v_qte_pal,
                                                  p_qte_vol     =>v_qte_vol);

                                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                                        su_bas_put_debug(v_nom_obj||v_etape||' cod_pro:'||v_cod_pro ||' vl:'||r_uee_rgp.cod_vl||
                                         ' unite:'||r_uee_rgp.unite_qte|| ' pcb:'||TO_CHAR(r_uee_rgp.pcb_exp) ||
                                         ' qte_a_res:'|| TO_CHAR(v_qte_a_res)||' soit '||TO_CHAR(v_qte_ub)|| ' UB');
                                    END IF;

                                    IF v_ret <> 'OK' THEN
                                        v_etape := 'Erreur sur calcul conversion en multi vl';
                                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                                            su_bas_put_debug(v_nom_obj || v_etape);
                                        END IF;
                                    END IF;

                                END IF;

                                -- si on est en multi vl on reserve en UB
                                IF v_cod_vl = '%' THEN
                                    v_qte_tmp := v_qte_ub;
                                    v_unit_tmp:='UB';
                                ELSE
                                    v_qte_tmp:=v_qte_a_res;
                                    v_unit_tmp:= r_uee_rgp.unite_qte;
                                END IF;

                                v_etape := 'pose IDP';
                                su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_RES1STK',
                                                             p_cod_idp => p_mode_res || '-' || r_pss_final.cod_pss_final || '-' || v_cod_cfg_rstk);

                                v_etape :=' reservation de stock ';
                                v_qte_restant := se_bas_res_stk(
                                        pr_ent_rstk         =>r_ent_rstk,
                                        p_cod_cfg_rstk      =>v_cod_cfg_rstk,
                                        p_no_vag_rstk       =>v_no_vag_rstk,
                                        p_typ_ref_rstk      =>'LIG',
                                        p_ref_rstk_1        =>r_uee_rgp.no_com,
                                        p_ref_rstk_2        =>TO_CHAR(r_uee_rgp.no_lig_com),
                                        p_ref_rstk_3        =>r_uee_rgp.no_uee,
                                        p_ref_rstk_4        =>r_uee_rgp.cod_up,
                                        p_ref_rstk_5        =>r_uee_rgp.typ_up,
                                        p_cod_pro           =>v_cod_pro,
                                        p_cod_va            =>v_cod_va,
                                        p_cod_vl            =>v_cod_vl,                         --v_cod_vl
                                        p_qte_res_dem       =>v_qte_tmp,                        --v_qte_a_res
                                        p_unit_res          =>v_unit_tmp,                       --r_uee_rgp.unite_qte
                                        p_lst_cod_prk       =>NVL(v_list_cod_prk,';#NULL#;'),   --liste des codes prk
                                        p_lst_mag_rch       =>v_list_mag(v_i).lst_mag_rch,      --liste des magasins de recherche
                                        p_lst_mag_res       =>v_list_mag(v_i).lst_mag_res,      --liste des magasins de réservation
                                        p_lst_mag_pic       =>v_list_mag(v_i).lst_mag_pic,      --liste des magasins de picking
                                        p_lst_mag_typ_prk   =>v_list_mag(v_i).lst_mag_rch_prk,  --liste couple (magasin de resa, typ_prk)
                                        p_qte_stk_min       =>v_qte_stk_min,                    --stock mini
                                        p_dat_dlc           =>v_dat_dlc_min,                    --dlc mini
                                        p_cod_soc_proprio   =>r_uee_rgp.cod_soc,                --pas encore dispo dans se ...
                                        p_where             =>v_where,                          --sur clause where (contrat date, spécif)
                                        p_mode_round_pic    =>v_mode_round_pic,
                                        p_mode_round_res    =>v_mode_round_res,
                                        p_car_stk_1         =>r_uee_rgp.val_ctr_res_1,
                                        p_car_stk_2         =>r_uee_rgp.val_ctr_res_2,
                                        p_car_stk_3         =>r_uee_rgp.val_ctr_res_3,
                                        p_car_stk_4         =>r_uee_rgp.val_ctr_res_4,
                                        p_car_stk_5         =>r_uee_rgp.val_ctr_res_5,
                                        p_car_stk_6         =>r_uee_rgp.val_ctr_res_6,
                                        p_car_stk_7         =>r_uee_rgp.val_ctr_res_7,
                                        p_car_stk_8         =>r_uee_rgp.val_ctr_res_8,
                                        p_car_stk_9         =>r_uee_rgp.val_ctr_res_9,
                                        p_car_stk_10        =>r_uee_rgp.val_ctr_res_10,
                                        p_car_stk_11        =>r_uee_rgp.val_ctr_res_11,
                                        p_car_stk_12        =>r_uee_rgp.val_ctr_res_12,
                                        p_car_stk_13        =>r_uee_rgp.val_ctr_res_13,
                                        p_car_stk_14        =>r_uee_rgp.val_ctr_res_14,
                                        p_car_stk_15        =>r_uee_rgp.val_ctr_res_15,
                                        p_car_stk_16        =>r_uee_rgp.val_ctr_res_16,
                                        p_car_stk_17        =>r_uee_rgp.val_ctr_res_17,
                                        p_car_stk_18        =>r_uee_rgp.val_ctr_res_18,
                                        p_car_stk_19        =>r_uee_rgp.val_ctr_res_19,
                                        p_car_stk_20        =>r_uee_rgp.val_ctr_res_20,
                                        p_cod_lot_stk       =>r_uee_rgp.cod_lot_res,
                                        p_fct_pro_sub       =>v_fct_pro_sub);                   -- $MOD MCOC 06/05/09 - gestion de la substitution

                                v_qte_result := v_qte_restant;

                                IF su_global_pkv.v_niv_dbg >=2  THEN
                                    su_bas_put_debug(v_nom_obj||'*** Retour SE.RES T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                                    v_debut := SYSTIMESTAMP;
                                END IF;

                                v_id_res :=  r_ent_rstk.no_rstk;

                                IF su_global_pkv.v_niv_dbg >= 3 THEN
                                    IF v_qte_result = -1 THEN --ERREUR
                                        su_bas_put_debug(v_nom_obj||v_etape||' ERREUR reservation sur qte a reserver de '|| to_char(v_qte_tmp));
                                    ELSE
                                        su_bas_put_debug(v_nom_obj||v_etape||' qte a reserver:'||TO_CHAR(v_qte_tmp)|| ' '||v_unit_tmp||
                                                                             ' qte reservee:'|| TO_CHAR(v_qte_tmp - v_qte_result));
                                    END IF;

                                END IF;

                                v_etape := 'ecriture IDP';
                                su_perf_pkg.su_bas_write_idp(p_typ_idp => 'PC_RES1STK',
                                                             p_cod_idp => p_mode_res || '-' || r_pss_final.cod_pss_final || '-' || v_cod_cfg_rstk,
                                                             p_cod_usn => p_cod_usn);

                                -- reference pour creation pc_rstk ...
                                v_etape := 'references';
                                v_ref_rstk_1 := r_uee_rgp.no_com;
                                v_ref_rstk_2 := TO_CHAR(r_uee_rgp.no_lig_com);
                                v_ref_rstk_3 := r_uee_rgp.no_uee;
                                v_ref_rstk_4 := r_uee_rgp.cod_up;
                                v_ref_rstk_5 := r_uee_rgp.typ_up;

                                --
                                -- je suis en train d'ordonnancer un colis de reference ...
                                --
                                IF r_uee_rgp.no_uee IS NOT NULL AND su_bas_gcl_pc_uee (p_no_uee => r_uee_rgp.no_uee,
                                                                                       p_colonne=> 'NO_UEE_REF') = r_uee_rgp.no_uee THEN

                                    v_etape := 'Création des UEE à partir de la reservation';
                                    v_ret := pc_ordo_pkg.pc_bas_crea_uee_id_res_2 (pr_ent_rstk  => r_ent_rstk,
                                                                                   p_ref_rstk_1 => v_ref_rstk_1,    -- IN,OUT
                                                                                   p_ref_rstk_2 => v_ref_rstk_2,    -- IN,OUT
                                                                                   p_ref_rstk_3 => v_ref_rstk_3,    -- IN,OUT
                                                                                   p_ref_rstk_4 => v_ref_rstk_4,    -- IN,OUT
                                                                                   p_ref_rstk_5 => v_ref_rstk_5,    -- IN,OUT
                                                                                   p_cod_pss    => r_pss_final.cod_pss_final,
                                                                                   p_qte_deres  => v_qte_deres);

                                    -- SI fraction dereservee ALORS augmenter le reste
                                    v_qte_restant := v_qte_restant + NVL(v_qte_deres,0);
                                    v_qte_result  := v_qte_result + NVL(v_qte_deres,0);

                                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                                        su_bas_put_debug(v_nom_obj|| ' crea_uee_id_res_2 ' || v_ret || ' avec dereservation de ' ||TO_CHAR(v_qte_deres));
                                    END IF;

                                END IF;

                                --
                                -- Il faut reconvertir la quantité restant en unite d'origine SI multi vl
                                --
                                v_etape:='reconversion de la quantité ';
                                IF v_cod_vl = '%' AND v_qte_tmp <> v_qte_result THEN
                                    --
                                    -- j'ai reserve quelque chose ...
                                    --
                                    v_ret := su_bas_conv_unite_to_one(p_cod_pro   =>v_cod_pro,
                                                                      p_cod_vl    =>r_uee_rgp.cod_vl,    -- code VL origine,
                                                                      p_qte_orig  =>v_qte_result,
                                                                      p_unite_orig=>'UB',
                                                                      p_unite_dest=>r_uee_rgp.unite_qte,  --unite d'origine
                                                                      p_qte_dest  =>v_qte_restant);

                                    IF su_global_pkv.v_niv_dbg >= 3 THEN
                                        su_bas_put_debug(v_nom_obj||v_etape||' reste a res:'||v_qte_restant||
                                                         ' ' ||r_uee_rgp.unite_qte);
                                    END IF;

                                    IF v_ret <> 'OK' THEN
                                        v_etape := 'Erreur sur calcul conversion en multi vl en retour de resa';
                                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                                            su_bas_put_debug(v_nom_obj || v_etape);
                                        END IF;
                                    END IF;

                                END IF;

                            END IF;

                            IF v_cod_vl='%' THEN
                                v_trace_cod_vl:='MULTI';
                            ELSE
                                v_trace_cod_vl:=v_cod_vl;
                            END IF;

                            IF v_qte_restant = v_qte_a_res THEN
                                v_etape := 'Résultat RESA-> Rien  :';

                                IF pc_trace_pkg.get_autor_resa THEN
                                   pc_bas_trace('ORDO_MANU',2,'Pas de réservation, Mag:$1 UL:$2 Prk:$3 Reste:$4',
                                                p_1=>v_list_mag(v_i).lst_mag_res,
                                                p_2=>v_cod_pro||'-'||v_trace_cod_vl,
                                                p_3=>NVL(v_list_cod_prk,';#NULL#;'),
                                                p_4=>to_char(v_qte_a_res)||' '||r_uee_rgp.unite_qte);
                                END IF;

                            ELSIF v_qte_restant > 0 THEN
                                v_etape := 'Résultat RESA->Partiel:';

                                IF pc_trace_pkg.get_autor_resa THEN
                                    pc_bas_trace('ORDO_MANU',2,'Réservation partielle, Mag:$1 UL:$2 Prk:$3 Réservé:$4',
                                                 p_1=>v_list_mag(v_i).lst_mag_res,
                                                 p_2=>v_cod_pro||'-'||v_trace_cod_vl,
                                                 p_3=>NVL(v_list_cod_prk,';#NULL#;'),
                                                 p_4=> TO_CHAR(v_qte_a_res - v_qte_restant)||' '||r_uee_rgp.unite_qte);
                                END IF;

                            ELSIF v_qte_restant = 0 THEN
                                v_etape := 'Résultat RESA-> OK!!! :';

                                IF pc_trace_pkg.get_autor_resa THEN
                                    pc_bas_trace('ORDO_MANU',2,'Réservation complète, Mag:$1 UL:$2 Prk:$3 Réservé:$4',
                                                 p_1=>v_list_mag(v_i).lst_mag_res,
                                                 p_2=>v_cod_pro||'-'||v_trace_cod_vl,
                                                 p_3=>NVL(v_list_cod_prk,';#NULL#;'),
                                                 p_4=> TO_CHAR(v_qte_a_res)||' '||r_uee_rgp.unite_qte);
                                END IF;

                            ELSE
                                v_etape := 'Résultat RESA->ERREUR!:';
                                IF pc_trace_pkg.get_autor_resa THEN
                                   pc_bas_trace('ORDO_MANU',2,'Erreur MagRes:$1 MagPic:$2 Qté de :$3',
                                                p_1=>v_list_mag(v_i).lst_mag_res,
                                                p_2=>v_list_mag(v_i).lst_mag_pic,
                                                p_3=>to_char(v_qte_tmp)||' '||v_unit_tmp);
                                END IF;
                            END IF;

                            IF pc_trace_pkg.get_autor_resa THEN
                               -- on affiche les contraintes en trace si besoins
                               v_trace:=0;
                               v_trace_sub:=0;
                               v_trace_v_qte_stk_min:=NULL;
                               v_trace_v_nb_con_min_pal:=NULL;
                               v_trace_v_nb_con_max_pal:=NULL;
                               v_trace_v_dat_dlc_min:=NULL;
                               v_trace_v_dat_dlc_max:=NULL;
                               v_trace_mag_rch:=NULL;

                               -- S'il existe des magasins de recherches ...
                               IF  v_list_mag(v_i).lst_mag_rch <> v_list_mag(v_i).lst_mag_res THEN
                                   v_trace_mag_rch :='Mag:'|| v_list_mag(v_i).lst_mag_rch;
                                   v_trace:=1;
                               END IF;

                               IF  NVL(v_qte_stk_min,0) > 0 THEN
                                   v_trace_v_qte_stk_min:=' Qte stk min:'||to_char(v_qte_stk_min);
                                   v_trace:=1;
                               END IF;
                               IF  NVL(v_nb_con_min_pal,0) > 0 THEN
                                   v_trace_v_nb_con_min_pal:=' Nb colis min:'||to_char(v_nb_con_min_pal);
                                   v_trace:=1;
                               END IF;

                               IF  NVL(v_nb_con_max_pal,0) > 0 THEN
                                   v_trace_v_nb_con_max_pal:=' Nb colis max:'||to_char(v_nb_con_max_pal);
                                   v_trace:=1;
                               END IF;
                               IF v_dat_dlc_min IS NOT NULL THEN
                                   v_trace_v_dat_dlc_min:=' DLC min:'||to_char(v_dat_dlc_min,'DD/MM/YY');
                                   v_trace:=1;
                               END IF;
                               IF v_dat_dlc_max IS NOT NULL THEN
                                   v_trace_v_dat_dlc_max:=' DLC max:'||to_char(v_dat_dlc_max,'DD/MM/YY');
                                   v_trace:=1;
                               END IF;
                               IF v_fct_pro_sub IS NOT NULL THEN
                                   v_trace_v_fct_pro_sub:=v_fct_pro_sub;
                                   v_trace_sub:=1;
                               END IF;

                               IF v_trace=1 THEN
                                   pc_bas_trace('ORDO_MANU',3,'Contraintes: $1',
                                                p_1=>v_trace_mag_rch|| v_trace_v_nb_con_min_pal||v_trace_v_nb_con_max_pal||
                                                     v_trace_v_dat_dlc_min||v_trace_v_dat_dlc_max);

                               END IF;
                               IF v_trace_sub=1 THEN
                                   pc_bas_trace('ORDO_MANU',3,'Rch substitution: $1', p_1=>v_trace_v_fct_pro_sub);
                               END IF;

                            END IF;

                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                su_bas_put_debug(v_nom_obj || v_etape || 'LigCom: ' || r_uee_rgp.no_com
                                                             || '-' || TO_CHAR(r_uee_rgp.no_lig_com)
                                                             || ' Produit-VA-VL: ' || v_cod_pro
                                                             || '-' || v_cod_va || '-' || v_cod_vl
                                                             || ' Qte Dem: ' || TO_CHAR(v_qte_a_res)
                                                             || ' Qte Restante: ' || TO_CHAR(v_qte_restant)
                                                             || ' Id_res: ' || v_id_res);
                            END IF;

                            -- Gestion de l'erreur (v_qte_restant = -1)
                            IF v_qte_restant < 0 THEN
                                v_trt_resa_ec := 'ERROR';
                                v_niv_ano:= 2;
                                v_cod_err_su_ano := 'PC-ORDO012';

                                su_bas_cre_ano (p_txt_ano   => 'ERREUR : ' || v_etape,
                                        p_cod_err_ora_ano => SQLCODE,
                                        p_lib_ano_1       => 'Code usine',
                                        p_par_ano_1       => p_cod_usn,
                                        p_lib_ano_2       => 'No_com',
                                        p_par_ano_2       => r_uee_rgp.no_com,
                                        p_lib_ano_3       => 'No_lig',
                                        p_par_ano_3       => TO_CHAR(r_uee_rgp.no_lig_com),
                                        p_cod_err_su_ano  => v_cod_err_su_ano,
                                        p_nom_obj         => v_nom_obj,
                                        p_version         => v_version);

                            END IF;

                            -- Traitement d'une resa OK (partiel ou total)
                            IF v_qte_restant >= 0           AND
                                v_qte_restant <> v_qte_a_res AND
                                NVL(v_id_res, 0) <> 0 THEN

                                --Encapsulage des fonctions d'insert (Cause du RAISE des fonctions su_bas_ins...)
                                BEGIN

                                    v_etape := 'is uee ref';
                                    IF r_uee_rgp.uee_ref = '1' THEN
                                        v_no_uee_ref := r_uee_rgp.no_uee;
                                    ELSE
                                        v_no_uee_ref := NULL;
                                    END IF;

                                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                                        su_bas_put_debug(v_nom_obj || ' v_qte_tmp:' || TO_CHAR(v_qte_tmp) || ' typ_resa:' || v_typ_resa);
                                    END IF;

                                    IF NVL(v_id_res_porl,0) = 0 THEN
                                        v_etape := 'creation classique PC_RSTK id_res: ' || TO_CHAR(v_id_res);
                                        v_ret :=  su_bas_ins_pc_rstk(p_id_res   =>v_id_res,
                                                    p_typ_res           =>v_typ_resa,
                                                    p_cod_usn           =>p_cod_usn,
                                                    p_cod_cfg_rstk      =>v_cod_cfg_rstk,
                                                    p_etat_atv_pc_rstk  =>v_etat_atv_resa,
                                                    p_qte_dem           =>v_qte_tmp,
                                                    p_qte_res           =>v_qte_tmp - v_qte_result,
                                                    p_unite_qte         =>v_unit_tmp,
                                                    p_cod_pss_afc       =>r_pss_final.cod_pss_final,
                                                    p_cod_pss_demandeur =>r_uee_rgp.cod_pss_afc,
                                                    p_ref_rstk_1        =>v_ref_rstk_1,
                                                    p_ref_rstk_2        =>v_ref_rstk_2,
                                                    p_ref_rstk_3        =>v_ref_rstk_3,
                                                    p_ref_rstk_4        =>v_ref_rstk_4,
                                                    p_ref_rstk_5        =>v_ref_rstk_5,
                                                    p_ref_rstk_6        =>NULL,
                                                    p_ref_rstk_7        =>NULL,
                                                    p_ref_rstk_8        =>NULL,
                                                    p_no_uee_ref        =>v_no_uee_ref,
                                                    p_list_cod_prk      =>v_list_cod_prk,
                                                    p_list_cod_pss_prk  =>v_list_cod_pss_prk,
                                                    p_list_id_action_prk=>v_list_id_action_prk,
                                                    p_list_cod_mag_res  =>v_list_mag(v_i).lst_mag_res,
                                                    p_list_cod_mag_pic  =>v_list_mag(v_i).lst_mag_pic,
                                                    p_id_res_porl       => v_id_res_porl
                                                    );
                                    ELSE
                                        -- on recupère la liste utilisée lors de la reservation ferme originelle
                                        vr_pc_rstk := su_bas_grw_pc_rstk (p_id_res => v_id_res_porl);

                                        v_etape := 'creation via id_porl PC_RSTK id_res: ' || TO_CHAR(v_id_res);
                                        v_ret :=  su_bas_ins_pc_rstk(p_id_res   =>v_id_res,
                                                    p_typ_res           =>v_typ_resa,
                                                    p_cod_usn           =>p_cod_usn,
                                                    p_cod_cfg_rstk      =>v_cod_cfg_rstk,
                                                    p_etat_atv_pc_rstk  =>v_etat_atv_resa,
                                                    p_qte_dem           =>v_qte_tmp,
                                                    p_qte_res           =>v_qte_tmp - v_qte_result,
                                                    p_unite_qte         =>v_unit_tmp,
                                                    p_cod_pss_afc       =>r_pss_final.cod_pss_final,
                                                    p_cod_pss_demandeur =>r_uee_rgp.cod_pss_afc,
                                                    p_ref_rstk_1        =>v_ref_rstk_1,
                                                    p_ref_rstk_2        =>v_ref_rstk_2,
                                                    p_ref_rstk_3        =>v_ref_rstk_3,
                                                    p_ref_rstk_4        =>v_ref_rstk_4,
                                                    p_ref_rstk_5        =>v_ref_rstk_5,
                                                    p_ref_rstk_6        =>NULL,
                                                    p_ref_rstk_7        =>NULL,
                                                    p_ref_rstk_8        =>NULL,
                                                    p_no_uee_ref        =>v_no_uee_ref,
                                                    p_list_cod_prk      =>vr_pc_rstk.list_cod_prk,
                                                    p_list_cod_pss_prk  =>vr_pc_rstk.list_cod_pss_prk,
                                                    p_list_id_action_prk=>vr_pc_rstk.list_id_action_prk,
                                                    p_list_cod_mag_res  =>vr_pc_rstk.list_cod_mag_res,
                                                    p_list_cod_mag_pic  =>vr_pc_rstk.list_cod_mag_pic,
                                                    p_id_res_porl       => v_id_res_porl
                                                    );
                                    END IF;

                                    -- Dépose d'un verrou
                                    v_etape := 'On pose un verrou sur PC_RSTK';
                                    UPDATE pc_rstk  r SET
                                        lst_fct_lock = su_bas_lock (p_cod_verrou, r.lst_fct_lock, r.id_session_lock)
                                    WHERE r.id_res = v_id_res;

                                    --
                                    -- Cas normal de reservation ferme "classique" traitée à l'ordo
                                    --
                                    IF v_typ_resa <> '99' THEN

                                        v_etape := 'Recup ligne resa detail de id_res:  ' || v_id_res;
                                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                                            su_bas_put_debug(v_nom_obj || v_etape );
                                        END IF;

                                        OPEN c_lig_rstk(v_id_res);
                                        LOOP
                                            FETCH c_lig_rstk INTO r_lig_rstk;
                                            EXIT WHEN c_lig_rstk%NOTFOUND;

                                            v_etape := 'Traitement de ligne resa detail id_res:  ' || v_id_res
                                                        || 'cod_pro: ' ||  r_lig_rstk.cod_pro
                                                        || 'vl: '      ||  r_lig_rstk.cod_vl
                                                        || 'qte_res: ' ||  r_lig_rstk.qte_res
                                                        || 'unite: '   ||  r_lig_rstk.unit_res
                                                        || 'no_stk: '  ||  r_lig_rstk.no_stk;

                                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                                su_bas_put_debug(v_nom_obj || v_etape);
                                            END IF;

                                            -- ----------------------------
                                            -- Conversion en unite de stock
                                            -- ----------------------------
                                            IF r_lig_rstk.unit_res <> r_lig_rstk.unit_stk THEN

                                                -- On calcul la quantité reservée dans l'unité de stock
                                                v_ret := su_bas_conv_unite_to_one(
                                                            p_cod_pro      =>r_lig_rstk.cod_pro,
                                                            p_cod_vl       =>r_lig_rstk.cod_vl,
                                                            p_qte_orig     =>r_lig_rstk.qte_res,
                                                            p_unite_orig   =>r_lig_rstk.unit_res,
                                                            p_unite_dest   =>r_lig_rstk.unit_stk,
                                                            p_qte_dest     =>v_qte_res_stk);
                                                IF v_ret <> 'OK' THEN
                                                    v_etape := 'PB lors de la conversion d''unite->' ||
                                                                ' p_cod_pro: '    || r_lig_rstk.cod_pro  ||
                                                                ' p_cod_vl: '     || r_lig_rstk.cod_vl   ||
                                                                ' p_qte_orig: '   || r_lig_rstk.qte_res  ||
                                                                ' p_unite_orig: ' || r_lig_rstk.unit_res ||
                                                                ' p_unite_dest: ' || r_lig_rstk.unit_stk;
                                                    RAISE err_except;
                                                END IF;
                                            ELSE
                                                v_qte_res_stk := r_lig_rstk.qte_res;
                                            END IF;

                                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                                su_bas_put_debug(v_nom_obj||' qte_res_ub:'||v_qte_res_ub || ' UB');
                                                --su_bas_put_debug(v_nom_obj||' qte_res_lig:'||v_qte_res_lig || ' ' || r_uee_rgp.unite_qte);
                                                su_bas_put_debug(v_nom_obj||' qte_res_stk:'||v_qte_res_stk || ' ' || r_lig_rstk.unit_stk);
                                                su_bas_put_debug(v_nom_obj||' qte_res:'||r_lig_rstk.qte_res || ' ' || r_lig_rstk.unit_res);
                                            END IF;

                                            v_etape := 'Creation d''un record dans PC_RSTK_DET id_res-no_lig_rstk:'  ||
                                                        v_id_res || '-' || TO_CHAR(r_lig_rstk.no_lig_rstk);
                                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                                su_bas_put_debug(v_nom_obj || v_etape );
                                            END IF;

                                            v_ret :=  su_bas_ins_pc_rstk_det(p_id_res   =>v_id_res,
                                                                        p_no_lig_rstk   =>r_lig_rstk.no_lig_rstk,
                                                                        p_no_stk        =>r_lig_rstk.no_stk,
                                                                        p_qte_res       =>r_lig_rstk.qte_res,
                                                                        p_unit_res      =>r_lig_rstk.unit_res,
                                                                        p_qte_res_stk   =>v_qte_res_stk,
                                                                        p_unit_stk      =>r_lig_rstk.unit_stk,
                                                                        p_cod_mag_pic   =>r_lig_rstk.cod_mag_pic,
                                                                        p_cod_pro       =>r_lig_rstk.cod_pro,
                                                                        p_cod_vl        =>r_lig_rstk.cod_vl,
                                                                        p_cod_va        =>r_lig_rstk.cod_va,
                                                                        p_cod_prk       =>r_lig_rstk.cod_prk,
                                                                        p_cod_emp       =>r_lig_rstk.cod_emp,
                                                                        p_cod_usn       =>r_lig_rstk.cod_usn,
                                                                        p_cod_mag       =>r_lig_rstk.cod_mag,
                                                                        p_cod_lot_stk   =>r_lig_rstk.cod_lot_stk,
                                                                        p_cod_ss_lot_stk=>r_lig_rstk.cod_ss_lot_stk,
                                                                        p_dat_dlc       =>r_lig_rstk.dat_dlc,
                                                                        p_dat_stk       =>r_lig_rstk.dat_stk,
                                                                        p_dat_ent_mag   =>r_lig_rstk.dat_ent_mag,
                                                                        p_cod_ut        =>r_lig_rstk.cod_ut,
                                                                        p_typ_ut        =>r_lig_rstk.typ_ut,
                                                                        p_cod_soc_proprio => r_lig_rstk.cod_soc_proprio,
                                                                        p_car_stk_1     =>r_lig_rstk.car_stk_1,
                                                                        p_car_stk_2     =>r_lig_rstk.car_stk_2,
                                                                        p_car_stk_3     =>r_lig_rstk.car_stk_3,
                                                                        p_car_stk_4     =>r_lig_rstk.car_stk_4,
                                                                        p_car_stk_5     =>r_lig_rstk.car_stk_5,
                                                                        p_car_stk_6     =>r_lig_rstk.car_stk_6,
                                                                        p_car_stk_7     =>r_lig_rstk.car_stk_7,
                                                                        p_car_stk_8     =>r_lig_rstk.car_stk_8,
                                                                        p_car_stk_9     =>r_lig_rstk.car_stk_9,
                                                                        p_car_stk_10    =>r_lig_rstk.car_stk_10,
                                                                        p_car_stk_11    =>r_lig_rstk.car_stk_11,
                                                                        p_car_stk_12    =>r_lig_rstk.car_stk_12,
                                                                        p_car_stk_13    =>r_lig_rstk.car_stk_13,
                                                                        p_car_stk_14    =>r_lig_rstk.car_stk_14,
                                                                        p_car_stk_15    =>r_lig_rstk.car_stk_15,
                                                                        p_car_stk_16    =>r_lig_rstk.car_stk_16,
                                                                        p_car_stk_17    =>r_lig_rstk.car_stk_17,
                                                                        p_car_stk_18    =>r_lig_rstk.car_stk_18,
                                                                        p_car_stk_19    =>r_lig_rstk.car_stk_19,
                                                                        p_car_stk_20    =>r_lig_rstk.car_stk_20,
                                                                        p_qte_rdis      =>NULL);
                                        END LOOP;
                                        CLOSE c_lig_rstk;

                                    --
                                    -- Cas de la reservation ferme traitée au préordo ligne
                                    --
                                    ELSIF v_id_res_porl > 0 THEN

                                        v_etape := 'Recup id_res_porl:  ' || v_id_res_porl;
                                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                                            su_bas_put_debug(v_nom_obj || v_etape);
                                        END IF;

                                        -- il faut replacer les listes de magasins

                                        OPEN c_lig_porl(v_id_res_porl, v_qte_tmp);
                                        LOOP
                                            FETCH c_lig_porl INTO r_lig_porl;
                                            EXIT WHEN c_lig_porl%NOTFOUND OR v_qte_tmp <= 0;

                                            v_etape := 'Traitement ligne resa porl id_res_porl:  ' || v_id_res_porl
                                                        || 'cod_pro: ' ||  r_lig_porl.cod_pro
                                                        || 'vl: '      ||  r_lig_porl.cod_vl
                                                        || 'qte_res: ' ||  r_lig_porl.qte_res
                                                        || 'unite: '   ||  r_lig_porl.unit_res
                                                        || 'no_stk: '  ||  r_lig_porl.no_stk;

                                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                                su_bas_put_debug(v_nom_obj || v_etape );
                                            END IF;

                                            -- ----------------------------
                                            -- Conversion en unite de stock
                                            -- ----------------------------
                                            IF r_lig_porl.unit_res <> r_lig_porl.unit_stk THEN

                                                -- On calcul la quantité reservée dans l'unité de stock
                                                v_ret := su_bas_conv_unite_to_one(
                                                            p_cod_pro      =>r_lig_porl.cod_pro,
                                                            p_cod_vl       =>r_lig_porl.cod_vl,
                                                            p_qte_orig     =>LEAST(v_qte_tmp, r_lig_porl.qte_res),
                                                            p_unite_orig   =>r_lig_porl.unit_res,
                                                            p_unite_dest   =>r_lig_porl.unit_stk,
                                                            p_qte_dest     =>v_qte_res_stk);
                                                IF v_ret <> 'OK' THEN
                                                    v_etape := 'PB lors de la conversion d''unite->' ||
                                                                ' p_cod_pro: '    || r_lig_porl.cod_pro  ||
                                                                ' p_cod_vl: '     || r_lig_porl.cod_vl   ||
                                                                ' p_qte_orig: '   || r_lig_porl.qte_res  ||
                                                                ' p_unite_orig: ' || r_lig_porl.unit_res ||
                                                                ' p_unite_dest: ' || r_lig_porl.unit_stk;
                                                    RAISE err_except;
                                                END IF;
                                            ELSE
                                                v_qte_res_stk := r_lig_porl.qte_res;
                                            END IF;

                                            IF su_global_pkv.v_niv_dbg >= 3 THEN
                                                su_bas_put_debug(v_nom_obj||' qte_res_stk:'||v_qte_res_stk || ' ' || r_lig_porl.unit_stk);
                                                su_bas_put_debug(v_nom_obj||' qte_res:'||r_lig_porl.qte_res || ' ' || r_lig_porl.unit_res);
                                            END IF;

                                            v_etape := 'Creation d''un record dans PC_RSTK_DET id_res-no_lig_rstk:'  ||
                                                        v_id_res || '-' || TO_CHAR(r_lig_porl.no_lig_rstk);
                                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                                su_bas_put_debug(v_nom_obj || v_etape );
                                            END IF;

                                            v_ret :=  su_bas_ins_pc_rstk_det(p_id_res   =>v_id_res,
                                                                        p_no_lig_rstk   =>r_lig_porl.no_lig_rstk,
                                                                        p_no_stk        =>r_lig_porl.no_stk,
                                                                        p_qte_res       =>LEAST(v_qte_tmp, r_lig_porl.qte_res),
                                                                        p_unit_res      =>r_lig_porl.unit_res,
                                                                        p_qte_res_stk   =>v_qte_res_stk,
                                                                        p_unit_stk      =>r_lig_porl.unit_stk,
                                                                        p_cod_mag_pic   =>r_lig_porl.cod_mag_pic,
                                                                        p_cod_pro       =>r_lig_porl.cod_pro,
                                                                        p_cod_vl        =>r_lig_porl.cod_vl,
                                                                        p_cod_va        =>r_lig_porl.cod_va,
                                                                        p_cod_prk       =>r_lig_porl.cod_prk,
                                                                        p_cod_emp       =>r_lig_porl.cod_emp,
                                                                        p_cod_usn       =>r_lig_porl.cod_usn,
                                                                        p_cod_mag       =>r_lig_porl.cod_mag,
                                                                        p_cod_lot_stk   =>r_lig_porl.cod_lot_stk,
                                                                        p_cod_ss_lot_stk=>r_lig_porl.cod_ss_lot_stk,
                                                                        p_dat_dlc       =>r_lig_porl.dat_dlc,
                                                                        p_dat_stk       =>r_lig_porl.dat_stk,
                                                                        p_dat_ent_mag   =>r_lig_porl.dat_ent_mag,
                                                                        p_cod_ut        =>r_lig_porl.cod_ut,
                                                                        p_typ_ut        =>r_lig_porl.typ_ut,
                                                                        p_cod_soc_proprio => r_lig_porl.cod_soc_proprio,
                                                                        p_car_stk_1     =>r_lig_porl.car_stk_1,
                                                                        p_car_stk_2     =>r_lig_porl.car_stk_2,
                                                                        p_car_stk_3     =>r_lig_porl.car_stk_3,
                                                                        p_car_stk_4     =>r_lig_porl.car_stk_4,
                                                                        p_car_stk_5     =>r_lig_porl.car_stk_5,
                                                                        p_car_stk_6     =>r_lig_porl.car_stk_6,
                                                                        p_car_stk_7     =>r_lig_porl.car_stk_7,
                                                                        p_car_stk_8     =>r_lig_porl.car_stk_8,
                                                                        p_car_stk_9     =>r_lig_porl.car_stk_9,
                                                                        p_car_stk_10    =>r_lig_porl.car_stk_10,
                                                                        p_car_stk_11    =>r_lig_porl.car_stk_11,
                                                                        p_car_stk_12    =>r_lig_porl.car_stk_12,
                                                                        p_car_stk_13    =>r_lig_porl.car_stk_13,
                                                                        p_car_stk_14    =>r_lig_porl.car_stk_14,
                                                                        p_car_stk_15    =>r_lig_porl.car_stk_15,
                                                                        p_car_stk_16    =>r_lig_porl.car_stk_16,
                                                                        p_car_stk_17    =>r_lig_porl.car_stk_17,
                                                                        p_car_stk_18    =>r_lig_porl.car_stk_18,
                                                                        p_car_stk_19    =>r_lig_porl.car_stk_19,
                                                                        p_car_stk_20    =>r_lig_porl.car_stk_20,
                                                                        p_qte_rdis      =>NULL);

                                            v_etape := 'maj qte sur ligne resa detail';
                                            UPDATE pc_rstk_det SET
                                                qte_rdis = qte_rdis + LEAST(v_qte_tmp, r_lig_porl.qte_res)
                                            WHERE id_res = r_lig_porl.no_rstk AND no_lig_rstk = r_lig_porl.no_lig_rstk;

                                            v_qte_tmp := v_qte_tmp - LEAST(v_qte_tmp, r_lig_porl.qte_res);

                                        END LOOP;
                                        CLOSE c_lig_porl;

                                        IF v_qte_tmp > 0 THEN

                                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                                su_bas_put_debug(v_nom_obj || ' Creation resa forcee de : ' || TO_CHAR(v_qte_tmp));
                                            END IF;

                                            --
                                            -- Il reste une qte et plus de ligne de reservation
                                            -- (cas du forcage de reservation)
                                            --
                                            v_etape := 'lecture forcage';
                                            --
                                            v_ret :=  su_bas_ins_pc_rstk_det(p_id_res   =>v_id_res,
                                                                        p_no_lig_rstk   =>0,
                                                                        p_no_stk        =>NULL,
                                                                        p_qte_res       =>v_qte_tmp,
                                                                        p_unit_res      =>v_unit_tmp,
                                                                        p_qte_res_stk   =>v_qte_tmp,
                                                                        p_unit_stk      =>v_unit_tmp,
                                                                        p_cod_mag_pic   =>su_bas_get_nieme_val (vr_pc_rstk.list_cod_mag_pic,';',1,0,1),
                                                                        p_cod_pro       =>v_cod_pro,
                                                                        p_cod_vl        =>v_cod_vl,
                                                                        p_cod_va        =>v_cod_va,
                                                                        p_cod_prk       =>NULL,
                                                                        p_cod_emp       =>NULL,
                                                                        p_cod_usn       =>p_cod_usn,
                                                                        p_cod_mag       =>su_bas_get_nieme_val (vr_pc_rstk.list_cod_mag_pic,';',1,0,1),
                                                                        p_cod_lot_stk   =>NULL,
                                                                        p_cod_ss_lot_stk=>NULL,
                                                                        p_dat_dlc       =>NULL,
                                                                        p_dat_stk       =>NULL,
                                                                        p_dat_ent_mag   =>NULL,
                                                                        p_cod_ut        =>NULL,
                                                                        p_typ_ut        =>NULL,
                                                                        p_cod_soc_proprio=>NULL,
                                                                        p_car_stk_1     =>NULL,
                                                                        p_car_stk_2     =>NULL,
                                                                        p_car_stk_3     =>NULL,
                                                                        p_car_stk_4     =>NULL,
                                                                        p_car_stk_5     =>NULL,
                                                                        p_car_stk_6     =>NULL,
                                                                        p_car_stk_7     =>NULL,
                                                                        p_car_stk_8     =>NULL,
                                                                        p_car_stk_9     =>NULL,
                                                                        p_car_stk_10    =>NULL,
                                                                        p_car_stk_11    =>NULL,
                                                                        p_car_stk_12    =>NULL,
                                                                        p_car_stk_13    =>NULL,
                                                                        p_car_stk_14    =>NULL,
                                                                        p_car_stk_15    =>NULL,
                                                                        p_car_stk_16    =>NULL,
                                                                        p_car_stk_17    =>NULL,
                                                                        p_car_stk_18    =>NULL,
                                                                        p_car_stk_19    =>NULL,
                                                                        p_car_stk_20    =>NULL,
                                                                        p_qte_rdis      =>NULL);

                                            v_qte_tmp := 0;

                                        END IF;

                                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                                            su_bas_put_debug(v_nom_obj || ' Reste: ' || TO_CHAR(v_qte_tmp));
                                        END IF;

                                    END IF;

                                    -- on met la qte initialement demandee a jour
                                    -- en enlevant ce que l'on vient de reserver ...
                                    v_qte_dem := v_qte_dem - (v_qte_a_res - v_qte_restant);
                                    -- Maj de v_qte_a_res
                                    v_qte_a_res := v_qte_restant;

                                    -- Si colis complet et presence no_uee => UEE de regroupement
                                    IF r_uee_rgp.typ_col = 'CC' AND r_uee_rgp.no_uee IS NOT NULL THEN
                                        -- dans ce cas on autorise qu'une seule réservation sur la ligne de colis
                                        v_trt_resa_ec := 'FIN';
                                    END IF;

                                    -- controle si colis detail ...
                                    IF r_uee_rgp.typ_col = 'CD' AND v_cod_pss_cd IS NULL THEN
                                        -- c'est la premiere ligne du colis ...
                                        v_cod_pss_cd := r_pss_final.cod_pss_final;
                                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                                            su_bas_put_debug(v_nom_obj || 'Process fixé pour CD : ' || v_cod_pss_cd);
                                        END IF;
                                    END IF;

                                EXCEPTION
                                    WHEN OTHERS THEN
                                    IF c_lig_porl%ISOPEN THEN
                                        CLOSE c_lig_porl;
                                    END IF;
                                    v_niv_ano:= 2;
                                    v_trt_resa_ec := 'ERROR';
                                    v_cod_err_su_ano := 'PC-ORDO013';

                                    su_bas_cre_ano (p_txt_ano   => 'ERREUR : ' || v_etape,
                                        p_cod_err_ora_ano => SQLCODE,
                                        p_lib_ano_1       => 'Code usine',
                                        p_par_ano_1       => p_cod_usn,
                                        p_lib_ano_2       => 'No_com',
                                        p_par_ano_2       => r_uee_rgp.no_com,
                                        p_lib_ano_3       => 'No lig',
                                        p_par_ano_3       => TO_CHAR(r_uee_rgp.no_lig_com),
                                        p_cod_err_su_ano  => v_cod_err_su_ano,
                                        p_nom_obj         => v_nom_obj,
                                        p_version         => v_version);

                                END;
                            END IF;

                            -- passe aux listes suivantes
                            v_i := v_list_mag.NEXT(v_i);

                          END LOOP;    --WHILE }

                        END IF;

                    ELSE

                        IF pc_trace_pkg.get_autor_resa THEN
                            pc_bas_trace('ORDO_MANU',1,'Essai sur process $1 : non qualifié',
                                         p_1=>r_pss_final.cod_pss_final);
                        END IF;

                        v_etape := 'Process non qualifié : ' || r_pss_final.cod_pss_final
                            || ' LigCom:' || r_lig_com.no_com || '-'
                            || TO_CHAR(r_lig_com.no_lig_com);
                        IF su_global_pkv.v_niv_dbg >= 3 THEN
                            su_bas_put_debug(v_nom_obj || ' /// ' || v_etape );
                        END IF;
                    END IF;  -- test de la qualification du process

                  ELSE
                      IF su_global_pkv.v_niv_dbg >= 3 THEN
                          su_bas_put_debug(v_nom_obj || ' *** ' || 'Clef déja traitée ...');
                      END IF;
                  END IF;    -- }

                END LOOP;    -- FOR r_pss_final

                v_etape := 'Write IDP ORDRCH';
                IF v_profondeur > 9 THEN
                    su_perf_pkg.su_bas_write_idp(p_typ_idp => 'PC_ORDRCH',
                                                 p_cod_idp => 'N',
                                                 p_cod_usn => p_cod_usn);
                ELSE
                    su_perf_pkg.su_bas_write_idp(p_typ_idp => 'PC_ORDRCH',
                                                 p_cod_idp => TO_CHAR(v_profondeur),
                                                 p_cod_usn => p_cod_usn);
                END IF;


                IF pc_trace_pkg.get_autor_resa THEN
                    IF v_qte_a_res <= 0 THEN
                        pc_bas_trace('ORDO_MANU',1,'Fin avec Succès. La totalité a été réservée');
                    ELSE
                        pc_bas_trace('ORDO_MANU',1,'Fin. Non reservé $1',
                                     p_1=>TO_CHAR(v_qte_a_res)||' '||r_uee_rgp.unite_qte);
                    END IF;
                END IF;

                -- Test s'il ne reste pas une qte en commande non traitée en réservation
                -- pour un colis détail
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj || ' v_qte_a_res:' || TO_CHAR(v_qte_a_res));
                    su_bas_put_debug(v_nom_obj || ' v_typ_col:' || r_uee_rgp.typ_col);
                END IF;
                IF v_qte_a_res <> 0 AND r_uee_rgp.typ_col = 'CD' AND r_uee_rgp.uee_ref = '0' THEN
                    v_trt_resa_ec := 'ERROR';     -- on devra ROLLBACKER au savepoint.
                    IF pc_trace_pkg.get_autor_resa THEN
                        pc_bas_trace('ORDO_MANU',2,'Annulation complete sur colis detail $1',
                                     p_1=>r_uee_rgp.no_uee_max);
                    END IF;
                END IF;

            END IF;   -- v_trt_resa_ec = 'OK'

        END LOOP;
        CLOSE c_uee_rgp;

        -- test si une resa en cours doit être avortée
        IF v_trt_resa_ec = 'ERROR' THEN
            -- on doit rollbacker les résa précédentes du dernier groupe colis
            ROLLBACK TO my_sp_pc_bas_resa_rgp;
            v_etape :=  'ROLLBACK TO my_sp_pc_bas_resa_rgp';
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || v_etape);
            END IF;

        END IF;

    END IF;   --  IF v_ret_evt IS NULL THEN
    /**********************
     FIN TRAITEMENT STD
    **********************/
    /**********************
    3) PHASE FINALISATION
    *********************/
    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_PC_ORDO_RESA_STK') THEN
        v_ret_evt := pc_evt_ordo_resa_stk( 'POST',
                                        p_cod_usn,
                                        p_typ_vag,
                                        p_ss_typ_vag,
                                        p_no_vag,
                                        p_cod_verrou,
                                        p_crea_plan,
                                        p_cod_up,
                                        p_typ_up,
                                        p_no_com,
                                        p_no_lig_com,
                                        p_no_uee,
                                        p_qte_dem,
                                        p_cod_pss_dem,
                                        p_cod_prk_dem,
                                        p_cod_mag_dem);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||'*** END FINAL T='|| to_char((SYSTIMESTAMP-v_debut_tot),'sssssxFF2'));
    END IF;
    IF pc_trace_pkg.get_autor_resa THEN
        pc_bas_trace('ORDO_MANU',1,'Temps: $1',
                     p_1=>to_char((SYSTIMESTAMP-v_debut_tot),'sssssxFF2'));
    END IF;

    COMMIT;

    -- reset autor trace
    pc_trace_pkg.set_autor_resa(FALSE);

    RETURN v_retour;

EXCEPTION
    WHEN OTHERS THEN
        IF c_uee_rgp%ISOPEN THEN
            CLOSE c_uee_rgp;
        END IF;
        pc_trace_pkg.set_autor_resa(FALSE);
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;


/****************************************************************************
*   pc_bas_calcul_borne_pal
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de calculer une qte min et max pour la réservation
-- d'une palette
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,18.12.09,mnev    si pourcentage pas renseigne alors nb_con à NULL
-- 01a,29.08.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- ---------
--  p_cod_cfg_pal        pc_cfg_pal.cod_cfg_pal%TYPE,
--  p_cod_cnt            pc_uee.cod_cnt%TYPE,
--  p_pct_min_pal        NUMBER,
--  p_pct_max_pal        NUMBER,
--  p_nb_con_min_pal IN OUT NUMBER,
--  p_nb_con_max_pal IN OUT NUMBER
--
--
-- COMMIT :
-- --------
--   NON


PROCEDURE pc_bas_calcul_borne_pal(p_cod_cfg_pal           pc_cfg_pal.cod_cfg_pal%TYPE,
                                  p_cod_cnt               pc_uee.cod_cnt%TYPE,
                                  p_pct_min_pal           NUMBER,
                                  p_pct_max_pal           NUMBER,
                                  p_nb_con_min_pal IN OUT NUMBER,
                                  p_nb_con_max_pal IN OUT NUMBER
    ) IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_borne_pal: ';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;


    -- Déclaration des curseurs
    -- ------------------------
    CURSOR c_cfg_pal IS
    SELECT *
    FROM pc_cfg_pal
    WHERE pc_cfg_pal.cod_cfg_pal = p_cod_cfg_pal;

    r_cfg_pal      c_cfg_pal%ROWTYPE;
    found_cfg_pal  BOOLEAN;

    -- Déclaration des varaiables
    -- --------------------------
    v_nb_con_couche  NUMBER := 0;
    v_nb_couche      NUMBER := 0;
    v_nb_con_pal     NUMBER := 0;

BEGIN

    v_etape := 'Debut trait: ';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                   ' p_cod_cfg_pal: ' || p_cod_cfg_pal ||
                   ' p_cod_cnt: '     || p_cod_cnt ||
                   ' p_pct_min_pal: ' || TO_CHAR(p_pct_min_pal) ||
                   ' p_pct_max_pal: ' || TO_CHAR(p_pct_max_pal));
    END IF;

    v_etape := 'OPEN c_cfg_pal avec cod_cfg_pal: ' || p_cod_cfg_pal;
    OPEN c_cfg_pal;
    FETCH c_cfg_pal INTO r_cfg_pal;
    found_cfg_pal := c_cfg_pal%FOUND;
    CLOSE c_cfg_pal;

    IF found_cfg_pal THEN
        -- Calcul le nb de couche par palette et le nb de colis par couche
        v_etape := 'Calcul le nb de colis par couche et le nb de couche en std';
        IF pc_bas_cal_cnt_couche (p_cod_cnt_sor     =>r_cfg_pal.cod_cnt_pal,
                                  p_haut_std        =>r_cfg_pal.haut_std,
                                  p_cod_cnt_ent     =>p_cod_cnt,
                                  p_nb_cnt_ent_cou  =>v_nb_con_couche,
                                  p_nb_cou_cnt_sor  =>v_nb_couche) = 'OK' THEN
            --on applique les pourcentages
            v_nb_con_pal     := NVL(v_nb_con_couche, 0) * NVL(v_nb_couche, 0);

            IF p_pct_min_pal IS NOT NULL THEN
                p_nb_con_min_pal := CEIL ((v_nb_con_pal * p_pct_min_pal) /100);
            ELSE
                p_nb_con_min_pal := NULL;
            END IF;
            IF p_pct_max_pal IS NOT NULL THEN
                p_nb_con_max_pal := FLOOR((v_nb_con_pal * p_pct_max_pal) /100);
            ELSE
                p_nb_con_max_pal := NULL;
            END IF;

            IF v_nb_con_pal <= 0 THEN
                p_nb_con_min_pal := NULL;
                p_nb_con_max_pal := NULL;
            END IF;

        ELSE
            p_nb_con_min_pal := NULL;
            p_nb_con_max_pal := NULL;
        END IF;
    ELSE
        p_nb_con_min_pal := NULL;
        p_nb_con_max_pal := NULL;
    END IF;


    v_etape := 'Valeur de retour: ';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                         ' p_qte_min_pal: ' || TO_CHAR(p_nb_con_min_pal) ||
                         ' p_qte_max_pal: ' || TO_CHAR(p_nb_con_max_pal));

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cod_cfg_pal',
                        p_par_ano_1       => p_cod_cfg_pal,
                        p_lib_ano_2       => 'p_cod_Cnt',
                        p_par_ano_2       => p_cod_cnt,
                        p_lib_ano_3       => 'p_pct_min_pal',
                        p_par_ano_3       => TO_CHAR(p_pct_min_pal),
                        p_lib_ano_4       => 'p_pct_max_pal',
                        p_par_ano_4       => TO_CHAR(p_pct_max_pal),
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        p_nb_con_min_pal := NULL;
        p_nb_con_max_pal := NULL;

END;



/****************************************************************************
*   pc_bas_calcul_surclause_where -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de construire une sur-clause p_where
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,14.01.15,mco2    Ajout d'un parametre : valeur case a cocher respect du contrat date
-- 01c,16.02.11,mnev    Ajout trace debug
-- 01b,15.04.10,rbel    Init DLC_MIN et MAX si clause where sup demande de ne
--                      pas avoir de contrat date
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_no_com             : no de commande
--  p_no_lig             : no de lig_commande
--  p_dat_dlc_min   IN OUT  DATE,
--  p_dat_dlc_max   IN OUT  DATE,
--  p_dat_1_min     IN OUT  DATE,
--  nb_con_min_pal        NUMBER,
--  p_nb_con_max_pal      NUMBER,
--  p_date_where   IN OUT  : sur clause p_where
--  p_cb_contrat_dt VARCHAR2 : Gestion du contrat date (Cas a cocher de l'ecran ordo)
--
--
-- COMMIT :
-- --------
--  NON

PROCEDURE pc_bas_calcul_surclause_where (
                                p_no_com                pc_lig_com.no_com%TYPE,
                                p_no_lig_com            pc_lig_com.no_lig_com%TYPE,
                                p_dat_dlc_min   IN OUT  DATE,
                                p_dat_dlc_max   IN OUT  DATE,
                                p_where_sup     IN      VARCHAR2,
                                p_dat_1_min     IN OUT  DATE,
                                p_nb_con_min_pal        NUMBER,
                                p_nb_con_max_pal        NUMBER,
                                p_having_ges_qte        VARCHAR2,
                                p_where         IN OUT  VARCHAR2,
                                p_mode_res              VARCHAR2 DEFAULT 'AUTO',
                                p_cod_ctr_res           pc_lig_cmd.cod_ctr_res%TYPE DEFAULT NULL,
                                p_val_ctr_res_1         pc_lig_cmd.val_ctr_res_1%TYPE DEFAULT NULL,
                                p_val_ctr_res_2         pc_lig_cmd.val_ctr_res_2%TYPE DEFAULT NULL,
                                p_val_ctr_res_3         pc_lig_cmd.val_ctr_res_3%TYPE DEFAULT NULL,
                                p_val_ctr_res_4         pc_lig_cmd.val_ctr_res_4%TYPE DEFAULT NULL,
                                p_val_ctr_res_5         pc_lig_cmd.val_ctr_res_5%TYPE DEFAULT NULL,
                                p_val_ctr_res_6         pc_lig_cmd.val_ctr_res_6%TYPE DEFAULT NULL,
                                p_val_ctr_res_7         pc_lig_cmd.val_ctr_res_7%TYPE DEFAULT NULL,
                                p_val_ctr_res_8         pc_lig_cmd.val_ctr_res_8%TYPE DEFAULT NULL,
                                p_val_ctr_res_9         pc_lig_cmd.val_ctr_res_9%TYPE DEFAULT NULL,
                                p_val_ctr_res_10        pc_lig_cmd.val_ctr_res_10%TYPE DEFAULT NULL,
                                p_val_ctr_res_11        pc_lig_cmd.val_ctr_res_11%TYPE DEFAULT NULL,
                                p_val_ctr_res_12        pc_lig_cmd.val_ctr_res_12%TYPE DEFAULT NULL,
                                p_val_ctr_res_13        pc_lig_cmd.val_ctr_res_13%TYPE DEFAULT NULL,
                                p_val_ctr_res_14        pc_lig_cmd.val_ctr_res_14%TYPE DEFAULT NULL,
                                p_val_ctr_res_15        pc_lig_cmd.val_ctr_res_15%TYPE DEFAULT NULL,
                                p_val_ctr_res_16        pc_lig_cmd.val_ctr_res_16%TYPE DEFAULT NULL,
                                p_val_ctr_res_17        pc_lig_cmd.val_ctr_res_17%TYPE DEFAULT NULL,
                                p_val_ctr_res_18        pc_lig_cmd.val_ctr_res_18%TYPE DEFAULT NULL,
                                p_val_ctr_res_19        pc_lig_cmd.val_ctr_res_19%TYPE DEFAULT NULL,
                                p_val_ctr_res_20        pc_lig_cmd.val_ctr_res_20%TYPE DEFAULT NULL,
                                p_cb_contrat_dt         VARCHAR2                DEFAULT 'A' --$MOD MCO2 04a
    ) IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_surclause_where: ';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    v_tmp_where         VARCHAR2(4000);
    v_ctr               se_ctr_res_pkg.tt_ctr;
    v_wh                VARCHAR2(500);
    v_sp                VARCHAR2(20);

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj ||' No Lig Com: ' || p_no_com || '-' || p_no_lig_com);
        su_bas_put_debug(v_nom_obj ||' Where_Sup='|| p_where_sup);
        su_bas_put_debug(v_nom_obj ||' p_mode_res='|| p_mode_res);
        su_bas_put_debug(v_nom_obj ||' p_cod_ctr_res='|| p_cod_ctr_res);
        su_bas_put_debug(v_nom_obj ||' p_having_ges_qte='|| p_having_ges_qte);
        su_bas_put_debug(v_nom_obj ||' p_nb_con_min_pal='|| p_nb_con_min_pal);
        su_bas_put_debug(v_nom_obj ||' p_nb_con_max_pal='|| p_nb_con_max_pal);
    END IF;

    -- IMPORTANT: la clause where doit inclure au début 'AND '
    -- ******************************************************
    -- --------------------------------------------
    -- Recherche des contrats dates
    -- --------------------------------------------
    -- Recherche de la dlc_min par rapport au contrat
    -- si p_dat_dlc_min is NULL (on doit vérifier le contrat)
    pc_bas_rch_contrat_date (p_no_com       =>p_no_com,
                             p_no_lig_com   =>p_no_lig_com,
                             p_typ_ctt_date =>'DLC_MIN',
                             p_date         =>p_dat_dlc_min
                             );

    -- on doit vérifier le contrat pour la date max
    pc_bas_rch_contrat_date (p_no_com       =>p_no_com,
                             p_no_lig_com   =>p_no_lig_com,
                             p_typ_ctt_date =>'DLC_MAX',
                             p_date         =>p_dat_dlc_max
                             );

    IF su_global_pkv.v_niv_dbg >= 3 THEN
         su_bas_put_debug(v_nom_obj || v_etape
                          || ' No_com-no_lig_com:' || p_no_com || '-'
                          || TO_CHAR(p_no_lig_com)
                          || ' dlc_min:' || TO_CHAR(p_dat_dlc_min,'DDMMYYYY')
                          || ' dlc_max:' || TO_CHAR(p_dat_dlc_max,'DDMMYYYY'));
    END IF;

    -- Si p_where_sup renseigne => saisie manuelle via ecran ordo
    IF p_where_sup IS NOT NULL  THEN
        p_where := p_where || p_where_sup;       -- p_where_sup (clause venant de l'ordo manuel)
    END IF;

	IF NVL(p_cb_contrat_dt,'1') = '1' THEN  --$MOD mco2 02a
        IF p_dat_dlc_min IS NOT NULL THEN
           p_where := p_where || ' AND /*#R1.012#*/ (DAT_DLC IS NULL OR DAT_DLC >= TO_DATE(''' || TO_CHAR(p_dat_dlc_min, 'DDMMYYYY') || ''',''DDMMYYYY'')) ';
        END IF;

        IF p_dat_dlc_max IS NOT NULL THEN
           p_where := p_where || ' AND /*#R1.013#*/ (DAT_DLC IS NULL OR DAT_DLC <= TO_DATE(''' || TO_CHAR(p_dat_dlc_max, 'DDMMYYYY') || ''',''DDMMYYYY'')) ';
        END IF;

    END IF;

    -- Recherche de la dat_1_min par rapport au contrat
    -- dat_1 non utilisée pour l'instant dans la surclause
    ------------------------------------------------------
    /*
    pc_bas_rch_contrat_date (p_no_com       =>r_uee_rgp.no_com,
                             p_no_lig_com   =>r_uee_rgp.no_lig_com,
                             p_typ_ctt_date =>'DAT_1',
                             p_date         =>p_dat_1_min
                             );
    */

    ------------------------------------------------------------
    -- Contrainte sur les quantités: cas des palettes entières
    ------------------------------------------------------------
    IF p_having_ges_qte IS NULL THEN
        -- ------------------------------------------------
        -- application des seuils sur la qte totale de l'ut
        -- ------------------------------------------------
        IF p_nb_con_min_pal IS NOT NULL OR p_nb_con_max_pal IS NOT NULL THEN
            p_where := p_where || ' AND /*#R1.015#*/ ((COD_UT, TYP_UT) IN' ||
                                  ' (SELECT COD_UT, TYP_UT FROM SE_STK' ||
                                  ' WHERE COD_UT IS NOT NULL' ||
                                  ' GROUP BY COD_UT, TYP_UT' ||
                                  ' HAVING SUM(NVL(QTE_COLIS, 0)) >= ' || TO_CHAR(NVL(p_nb_con_min_pal, 0)) ||
                                  ' AND SUM(NVL(QTE_COLIS, 0)) <= ' || TO_CHAR(NVL(p_nb_con_max_pal, 999999999999)) || '))';
        END IF;

    ELSE
        IF p_nb_con_min_pal IS NOT NULL OR p_nb_con_max_pal IS NOT NULL THEN

            v_wh := NULL;
            v_sp := NULL;
            IF INSTR(p_having_ges_qte,'COD_UT') > 0 THEN
                v_wh := NVL(v_wh,'WHERE ') || v_sp || 'COD_UT IS NOT NULL';
                v_sp := ' AND ';
            END IF;

            IF INSTR(p_having_ges_qte,'COD_EMP') > 0 THEN
                v_wh := NVL(v_wh,'WHERE ') || v_sp || 'COD_EMP IS NOT NULL';
                v_sp := ' AND ';
            END IF;

            p_where := p_where || ' AND /*#R1.016#*/ ((' || p_having_ges_qte || ') IN' ||
                                  ' (SELECT ' || p_having_ges_qte || ' FROM SE_STK ' ||
                                  v_wh ||
                                  ' GROUP BY ' || p_having_ges_qte ||
                                  ' HAVING SUM(NVL(QTE_COLIS, 0)) >= ' || TO_CHAR(NVL(p_nb_con_min_pal, 0)) ||
                                  ' AND SUM(NVL(QTE_COLIS, 0)) <= ' || TO_CHAR(NVL(p_nb_con_max_pal, 999999999999)) || '))';
        END IF;
    END IF;

    IF p_mode_res = 'AUTO' AND p_cod_ctr_res IS NOT NULL THEN

        v_etape := 'Calc clause WHERE pour contraites de reservation';
        v_ctr(1).val_ctr_res    := p_val_ctr_res_1;
        v_ctr(2).val_ctr_res    := p_val_ctr_res_2;
        v_ctr(3).val_ctr_res    := p_val_ctr_res_3;
        v_ctr(4).val_ctr_res    := p_val_ctr_res_4;
        v_ctr(5).val_ctr_res    := p_val_ctr_res_5;
        v_ctr(6).val_ctr_res    := p_val_ctr_res_6;
        v_ctr(7).val_ctr_res    := p_val_ctr_res_7;
        v_ctr(8).val_ctr_res    := p_val_ctr_res_8;
        v_ctr(9).val_ctr_res    := p_val_ctr_res_9;
        v_ctr(10).val_ctr_res   := p_val_ctr_res_10;
        v_ctr(11).val_ctr_res   := p_val_ctr_res_11;
        v_ctr(12).val_ctr_res   := p_val_ctr_res_12;
        v_ctr(13).val_ctr_res   := p_val_ctr_res_13;
        v_ctr(14).val_ctr_res   := p_val_ctr_res_14;
        v_ctr(15).val_ctr_res   := p_val_ctr_res_15;
        v_ctr(16).val_ctr_res   := p_val_ctr_res_16;
        v_ctr(17).val_ctr_res   := p_val_ctr_res_17;
        v_ctr(18).val_ctr_res   := p_val_ctr_res_18;
        v_ctr(19).val_ctr_res   := p_val_ctr_res_19;
        v_ctr(20).val_ctr_res   := p_val_ctr_res_20;

        IF se_ctr_res_pkg.se_bas_calc_where(p_cod_ctr_res   => p_cod_ctr_res,
                                            p_ctr           => v_ctr,
                                            p_where         => v_tmp_where) != 'OK' THEN
            RAISE err_except;
        END IF;

        p_where := p_where || ' AND ' ||v_tmp_where;
    END IF;

    v_etape := 'Clause WHERE calculée';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape || ': ' || p_where );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'No_lig',
                        p_par_ano_2       => p_no_lig_com,
                        p_lib_ano_3       => 'p_where',
                        p_par_ano_3       => p_where,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        p_where := NULL;
END;

/****************************************************************************
*   pc_bas_distribution_resa -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet d'affecter aux colis les resa effectuées
--
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,04.10.10,mnev    ajout controle pulse activite
-- 01c,17.12.09,mnev    replace le code process en cas de probleme
-- 01b,17.12.08,mnev    MAJ id_res à NULL si erreur de distribution.
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_typ_vag    : type de vague
--  p_ss_typ_vag : sous type de vague
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_distribution_resa (p_cod_usn          su_usn.cod_usn%TYPE,
                                   p_typ_vag          pc_vag.typ_vag%TYPE,
                                   p_ss_typ_vag       pc_vag.ss_typ_vag%TYPE,
                                   p_no_vag           pc_vag.no_vag%TYPE,
                                   p_cod_verrou       VARCHAR2,
                                   p_crea_plan        VARCHAR2,
                                   p_mode_dis         VARCHAR2 DEFAULT 'A')   -- 'A'(Automatique) ou 'M'(Manuel)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_distribution_resa:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclarations de variables
    -----------------------------
    v_no_uee_ec         pc_uee.no_uee%TYPE;
    v_no_com_ec         pc_ent_com.no_com%TYPE;
    v_no_lig_com_ec     pc_lig_com.no_lig_com%TYPE;
    v_trt_dis_ec        VARCHAR2(10) := 'OK';  -- flag de traitement en cours
    v_qte_tot_res       NUMBER   := 0;
    v_etat_atv_rstk     pc_rstk.etat_atv_pc_rstk%TYPE;


    -- Déclarations des curseurs
    -- --------------------------
    -- Curseur les resas effectuées
    -- ref_rstk_1 :no_com , ref_rstk_2 :no_lig_com
    -- ref_rstk_3 :no_uee (no colis détail), ref_rstk_4 :cod_up, ref_rstk_5 :typ_up
    CURSOR c_pc_rstk (x_etat_atv_rstk       pc_rstk.etat_atv_pc_rstk%TYPE) IS
    SELECT rs.*
    FROM pc_rstk rs, pc_lig_com l
    WHERE   rs.cod_err_pc_rstk IS NULL                                      AND
            rs.id_session_lock  = v_session_ora                             AND
            INSTR(rs.lst_fct_lock, ';'||p_cod_verrou||';') > 0              AND
            rs.etat_atv_pc_rstk = x_etat_atv_rstk                           AND
            l.no_com     = rs.ref_rstk_1                                    AND
            l.no_lig_com = pc_bas_to_number(rs.ref_rstk_2)
    ORDER BY l.no_com ASC,
             rs.ref_rstk_4 ASC,                                               -- par UP (palette)
             DECODE(l.typ_col, 'CC', 0, 'CD', 1) ASC,                         -- en premier les colis complet
             DECODE(l.typ_col, 'CC', l.no_lig_com, 'CD', rs.ref_rstk_3) ASC;  -- par ligne si colis complet

    r_pc_rstk          c_pc_rstk%ROWTYPE;
    found_pc_rstk      BOOLEAN;

    TYPE t_resa IS TABLE OF c_pc_rstk%ROWTYPE;
    vt_resa t_resa := t_resa();

    v_dat_activite     DATE := NULL;

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' ' || v_etape);
    END IF;

    --Test du sous_type de vague
    IF p_ss_typ_vag = pc_ordo_pkv.TYP_VAG_MANU THEN
       v_etat_atv_rstk := su_bas_rch_etat_atv (p_cod_action_atv => 'RESA_MANU',
                                               p_nom_table      => 'PC_RSTK');
    ELSE
       v_etat_atv_rstk := su_bas_rch_etat_atv (p_cod_action_atv => 'CREATION',
                                               p_nom_table      => 'PC_RSTK');
    END IF;

    /*
    v_etape := 'LOOP sur les réservations BULK';
    OPEN c_pc_rstk(v_etat_atv_rstk);
    FETCH c_pc_rstk BULK COLLECT INTO vt_resa;
    CLOSE c_pc_rstk;

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || 'Collection FIRST:' || vt_resa.first || ' LAST:' || vt_resa.last);
    END IF;

    v_etape := 'Lecture collection';
    FOR i IN vt_resa.first .. vt_resa.last
    LOOP
        v_etape := 'Affecte elm collection';
        r_pc_rstk := vt_resa(i);
    */

    -- Récupération des réservations effectuées
    v_etape := 'LOOP sur les entêtes de réservations';
    OPEN c_pc_rstk(v_etat_atv_rstk);
    LOOP

        FETCH c_pc_rstk INTO r_pc_rstk;
        EXIT WHEN c_pc_rstk%NOTFOUND;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' distri pour id_res:' || r_pc_rstk.id_res);
        END IF;

        -- ---------------------------------------------------------------
        IF (v_no_uee_ec IS NULL OR  NVL(r_pc_rstk.ref_rstk_3, '$') <> v_no_uee_ec) THEN
           -- le traitement courant n'est plus sur le même colis ou groupe de colis
           v_trt_dis_ec  := 'OK';
           -- Recup du groupe colis en cours
           v_no_uee_ec     := r_pc_rstk.ref_rstk_3;
        END IF;

        v_no_com_ec     := r_pc_rstk.ref_rstk_1;
        v_no_lig_com_ec := pc_bas_to_number(r_pc_rstk.ref_rstk_2);

        IF v_trt_dis_ec = 'OK' THEN

           v_etape := 'Appel de pc_bas_distri_id_res';
           -- Appel de la fonction de distribution de la resa id_res
           v_ret := pc_bas_distri_id_res (p_cod_usn      =>p_cod_usn,
                                          p_no_com       =>v_no_com_ec,
                                          p_no_lig_com   =>v_no_lig_com_ec,
                                          pr_pc_rstk     =>r_pc_rstk,
                                          p_cod_verrou   =>p_cod_verrou,
                                          p_crea_plan    =>p_crea_plan,
                                          p_mode_dis     =>p_mode_dis);
           IF v_ret <> 'OK' THEN
               v_trt_dis_ec := 'ERROR';
           END IF;

        END IF;

        IF v_trt_dis_ec <> 'OK' THEN

            v_cod_err_su_ano := 'PC-ORDO022';
            v_etape := 'correction pc_rstk';
            -- On doit marquer la résa en ERREUR
            UPDATE pc_rstk SET
                   cod_err_pc_rstk = v_cod_err_su_ano
            WHERE pc_rstk.id_res = r_pc_rstk.id_res;

            --------------------------------------
            v_etape := 'Appel de pc_bas_decrea_uee_id_res';
            --------------------------------------
            v_ret := pc_bas_decrea_uee_id_res (p_id_res      => r_pc_rstk.id_res,
                                               p_cod_pss_afc => r_pc_rstk.cod_pss_afc,
                                               p_qte_libere  => r_pc_rstk.qte_res);

            v_etape := 'correction pc_uee_det';
            UPDATE pc_uee_det SET
                id_res = NULL,
                cod_pss_afc = su_bas_gcl_pc_uee(no_uee,'COD_PSS_AFC')
            WHERE id_res = r_pc_rstk.id_res;

            v_etape := 'Erreur sur distribution id_res:' || r_pc_rstk.id_res;
            -- Création d'une anomalie
            v_niv_ano:= 2;
            su_bas_cre_ano (p_txt_ano => v_etape,
                    p_cod_err_ora_ano => SQLCODE,
                    p_lib_ano_1       => 'Id_res',
                    p_par_ano_1       => r_pc_rstk.id_res,
                    p_lib_ano_2       => 'No_com',
                    p_par_ano_2       => v_no_com_ec,
                    p_lib_ano_3       => 'No_lig_com',
                    p_par_ano_3       => v_no_lig_com_ec,
                    p_cod_err_su_ano  => v_cod_err_su_ano,
                    p_niv_ano         => v_niv_ano,
                    p_nom_obj         => v_nom_obj,
                    p_version         => v_version);

        END IF;   -- IF v_trt_dis_ec <> 'OK'

        v_etape := 'Controle activite:' || su_global_pkv.v_cod_ope;
        su_bas_ctl_activity(su_global_pkv.v_cod_ope, v_dat_activite);

    END LOOP;
    CLOSE c_pc_rstk;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        IF c_pc_rstk%ISOPEN THEN
            CLOSE c_pc_rstk;
        END IF;

        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

/* $Id$
****************************************************************************
* pc_bap_ORDOMAJUEED01  -- Evenement metier standardisé
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction correspond a un evenement metier
--
-- <BAP>
-- <NAME>ORDOMAJUEED01</>
-- <TITLE>MAJ COLIS A ORDONNANCEMENT</>
-- <CHAR>NO_ETAPE</>
-- <CHAR>COD_USN</>
-- <CHAR>COD_VERROU</>
-- <CHAR>NO_COM</>
-- <NUMBER>NO_LIG_COM</>
-- <CHAR>NO_UEE</>
-- <CHAR>COD_PRO</>
-- <CHAR>COD_VA</>
-- <CHAR>COD_VL</>
-- </BAP>
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,11.03.10,mnev    mise a jour pour le standard
-- 01a,01.03.10,gqui    initiale pour Eural.
-- 00a,15.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
-- RETOUR
----------
-- resultat du traitement ou ERROR si probleme
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bap_ORDOMAJUEED01 ( p_no_etape         VARCHAR2,
                                p_cod_usn          su_usn.cod_usn%TYPE,
                                p_cod_verrou       VARCHAR2,
                                p_no_com           pc_lig_com.no_com%TYPE,
                                p_no_lig_com       pc_lig_com.no_lig_com%TYPE,
                                p_no_uee           pc_uee.no_uee%TYPE,
                                p_cod_pro          pc_uee_det.cod_pro_res%TYPE,
                                p_cod_va           pc_uee_det.cod_va_res%TYPE,
                                p_cod_vl           pc_uee_det.cod_vl_res%TYPE
                                )
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bap_ORDOMAJUEED01';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_ret               VARCHAR2(1000) := 'OK';

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20) := 'ORDOMAJUEED01';

BEGIN

    SAVEPOINT my_point_bap_ORDOMAJUEED01;  -- Pour la gestion de l'exception on fixe un point de rollback.

    /********************
    2) PHASE TRAITEMENT
    ********************/

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN

        v_etape := 'creation ctx';
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'NO_ETAPE', p_no_etape);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_USN', p_cod_usn);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_VERROU', p_cod_verrou);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'NO_COM', p_no_com);
        v_add_ctx := su_ctx_pkg.su_bas_set_number(v_ctx,'NO_LIG_COM', p_no_lig_com);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'NO_UEE', p_no_uee);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_PRO', p_cod_pro);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_VA', p_cod_va);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_VL', p_cod_vl);

        v_etape := 'Appel événement ON';
        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_' || v_event);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    v_ret := v_ret_evt;

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj|| ' v_ret:' || v_ret);
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_point_bap_ORDOMAJUEED01;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_usn',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'No_com',
                        p_par_ano_2       => p_no_com,
                        p_lib_ano_3       => 'No_lig_com',
                        p_par_ano_3       => p_no_lig_com,
                        p_lib_ano_4       => 'No_uee',
                        p_par_ano_4       => p_no_uee,
                        p_lib_ano_5       => 'No_etape',
                        p_par_ano_5       => p_no_etape,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_maj_resa_uee -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de mettre la resa des colis UEE et UEE_DET, le process définitif
-- et la génération des ordres de picking
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 08a,11.04.14,mnev    Meilleure gestion du no_stk à NULL.
-- 07a,26.02.14,mnev    Prend en compte l'id_res_porl du tableau de resa.
-- 06d,16.01.14,rbel    Tenir compte de la cle_distri_res lors d'une distribution
--                      en mode 'A' si elle renseignée
-- 06c,16.07.13,alfl    mise en erreur des uee si la distribution a échouée
-- 06b,03.07.13,alfl    positionne su_global_pkv.v_mode_arc a MANU pour ne pas archiver les pc_uee_det et pc_uee
-- 06a,04.01.13,mnev    Gestion d'un nouveau mode de distribution
-- 05b,14.09.11,mnev    Renseigner dlc_min, dlc_max aussi si config sans résa
-- 05a,04.03.11,mnev    Gestion cod_vet, cod_vet_cd
-- 04j,26.01.11,rleb    ne pas prendre l'uee_no_ref dans le calcul
-- 04i,13.12.10,alfl    prendre le max entre la dlc reservee et celle de la ligne commande
-- 04h,29.10.10,mnev    Correction de l'order by : ajout du cod_up (cas du
--                      calcul de plan après resa => id_res non porteur
--                      de l'UP donc oblige d'ajouter le cod_up en clair)
-- 04g,15.10.10,mnev    Evite charge de préparation à 0 pour creation picking
-- 04f,12.03.10,mnev    Mise a jour cod_pro_res, cod_va_res et cod_vl_res
-- 04e,11.03.10,mnev    Ajout evenement pour MAJ UEE
-- 04d,03.03.09,mnev    Correction bug sur test process demandeur impossible
--                      en colis multi-lignes car l'UEE prend son process
--                      final des la premiere ligne distribuée ...
--                      Ajout soustraction sur v_qte_exp_ub dans la boucle !
-- 04c,03.12.08,mnev    Correction sur curseur c_uee_det pour colis detail.
-- 04b,24.11.08,mnev    Correction bug 1 qte_dis au lieu d'1 qte_res
--                      cas de reservation multiples sur 1 ligne de colis
-- 04a,08.11.08,mnev    Ajout parametre cod_pss_demandeur necessaire pour
--                      assurer une distribution coherente sur les colis
--                      du bon process.
-- 03b,03.11.08,mnev    Ajout d'un LEAST sur calcul de v_nb_col.
-- 03a,27.10.08,mnev    Gestion de l'éclatement des UEE de regroupement.
-- 02a,24.10.08,mnev    Utilisation de pc_uee.nb_col_theo
--                      (UEE de regroupement).
-- 01b,08.08.07,mnev    gestion des charges de preparation
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_no_com      : no de commande
--  p_no_lig      : no de lig_commande
--
--
-- RETOUR :
-- --------
-- OK ou ERROR
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_maj_resa_uee (p_cod_usn            su_usn.cod_usn%TYPE,
                              p_no_com             pc_lig_com.no_com%TYPE,
                              p_no_lig_com         pc_lig_com.no_lig_com%TYPE,
                              p_cod_up             pc_up.cod_up%TYPE,
                              p_typ_up             pc_up.typ_up%TYPE,
                              p_no_uee             pc_uee.no_uee%TYPE,
                              p_cod_pss_afc        su_pss.cod_pss%TYPE,
                              p_cod_pss_demandeur  pc_rstk.cod_pss_demandeur%TYPE,
                              p_cod_verrou         VARCHAR2,
                              p_crea_plan          VARCHAR2,
                              p_nb_colis_exp       NUMBER,
                              p_id_res             pc_rstk.id_res%TYPE,
                              pt_list_resa  IN OUT NOCOPY pc_ordo_pkg.tt_lst_resa,
                              p_mode_dis           VARCHAR2  DEFAULT 'A'
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 08a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_maj_resa_uee:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;
    v_cod_ala           su_ala.cod_ala%TYPE:=NULL;

    -- Déclarations des variables
    -----------------------------
    v_etat_atv_uee_min  VARCHAR2(20);
    v_etat_atv_uee_max  VARCHAR2(20);

    v_etat_atv_uee_det_avant    pc_uee_det.etat_atv_pc_uee_det%TYPE;
    v_etat_atv_uee_det_apres    pc_uee_det.etat_atv_pc_uee_det%TYPE;

    v_qte_exp_ub        NUMBER := 0;                -- Qte a expédier en Unité base
    v_qte_resa_ub       NUMBER := 0;                -- Qte réservée en Unité base
    v_qte_a_pic         NUMBER := 0;                -- Qte a picker
    v_qte_a_pic_stk     NUMBER := 0;                -- Qte a picker dans l'unité de stock
    v_nb_colis_exp      NUMBER := p_nb_colis_exp;   -- Nb de colis a expédier
    v_no_stk            se_stk.no_stk%TYPE := NULL; -- No de la fiche STK
    v_mode_aff_uee      VARCHAR2(20);
    v_pos               NUMBER(5);
    v_cod_mag_pic       se_stk.cod_mag%TYPE;
    v_no_etape          VARCHAR2(5);

    -- déclaration de curseurs
    CURSOR c_uee_det (x_etat_atv_uee_min  pc_uee.etat_atv_pc_uee%TYPE,
                      x_etat_atv_uee_max  pc_uee.etat_atv_pc_uee%TYPE,
                      x_etat_atv_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
    SELECT u.nb_col_theo, u.no_uee, u.typ_uee, u.tps_prp_col, u.dat_sel, u.cod_pss_afc,
           u.cod_up, ud.no_com, ud.no_lig_com, ud.tps_prp_pce,
           ud.cod_pro_res, ud.cod_vl_res, ud.qte_theo, ud.unite_qte, ud.rowid rowid_ud,
           l.cod_vedoc_ofs, l.cod_vedoc_mqe,
           l.cod_vedoc_pce_1, l.cod_vedoc_pce_2,
           l.cod_vedoc_col_1, l.cod_vedoc_col_2,
           l.cod_vedoc_col_1_cd, l.cod_vedoc_col_2_cd,
           l.cod_vet, l.cod_vet_cd, l.dlc_min, l.dlc_max,
           ud.cle_distri_res
    FROM pc_uee u, pc_uee_det ud, pc_lig_com l
    WHERE ud.no_com         = p_no_com                         AND
          ud.no_lig_com     = p_no_lig_com                     AND
          ud.no_com         = l.no_com                         AND
          ud.no_lig_com     = l.no_lig_com                     AND
          (u.no_uee         = p_no_uee OR p_no_uee IS NULL)    AND
          --((u.nb_col_theo   = 1 AND p_no_uee IS NULL AND u.typ_uee = 'CC') OR
           --(u.nb_col_theo   = 1 AND p_no_uee IS NOT NULL AND u.typ_uee = 'CD' AND u.no_uee_ref IS NULL) OR
           --(u.nb_col_theo   = 1 AND p_no_uee IS NOT NULL AND u.no_uee_ref IS NOT NULL AND u.no_uee<>u.no_uee_ref) OR
           --(u.nb_col_theo > 1 AND p_no_uee IS NOT NULL AND u.typ_uee = 'CC'))       AND
          ((u.nb_col_theo   = 1 AND p_no_uee IS NULL AND u.typ_uee = 'CC') OR
           (u.nb_col_theo   = 1 AND p_no_uee IS NOT NULL AND u.typ_uee = 'CD' AND u.no_uee<>NVL(u.no_uee_ref,'#NULL#')) OR
           (u.nb_col_theo > 1 AND p_no_uee IS NOT NULL AND u.typ_uee = 'CC')) AND
          (u.cod_up         = p_cod_up OR p_cod_up IS NULL)    AND
          (u.typ_up         = p_typ_up OR p_typ_up IS NULL)    AND
          (l.typ_col        = u.typ_uee OR u.no_uee_ref IS NOT NULL) AND
          u.no_uee          = ud.no_uee                        AND
          u.cod_err_pc_uee       IS NULL                       AND
          ud.cod_err_pc_uee_det  IS NULL                       AND
          (u.cod_pss_afc = p_cod_pss_afc OR u.cod_pss_afc = p_cod_pss_demandeur  OR p_no_uee IS NOT NULL) AND
          u.etat_atv_pc_uee IN (SELECT *
                                FROM TABLE(su_bas_list_etat_atv(x_etat_atv_uee_min, x_etat_atv_uee_max,'PC_UEE'))) AND
          u.id_session_lock  = v_session_ora                   AND
          INSTR(u.lst_fct_lock, ';'||p_cod_verrou||';') > 0    AND
          ud.etat_atv_pc_uee_det = x_etat_atv_uee_det          AND
          (ud.id_res IS NULL OR ud.id_res = p_id_res)               --Necessaire si distribution en manuel
    ORDER BY u.cod_up, ud.id_res, u.no_uee ASC;

    r_uee_det  c_uee_det%ROWTYPE;


    -- Curseur sur la fiche stock
    CURSOR c_stk (x_no_stk    se_stk.no_stk%TYPE) IS
    SELECT *
    FROM se_stk
    WHERE no_stk = x_no_stk;

    r_stk     c_stk%ROWTYPE;

    -- Curseur sur les emp du magasin pour récuper 1 emplacement de débord  en prio
    CURSOR c_emp (x_cod_mag    se_emp.cod_mag%TYPE) IS
    SELECT *
    FROM se_emp
    WHERE cod_mag = x_cod_mag
    ORDER BY DECODE(cod_emp, 'DEB', 0, 1)ASC;

    r_emp     c_emp%ROWTYPE;

    -- Curseur de recherche d'une fiche stock (mode sans resa, cas de la Non reservation de stock)
    CURSOR c_stk_sr (x_cod_pro          se_stk.cod_pro%TYPE,
                     x_cod_vl           se_stk.cod_va%TYPE,
                     x_cod_va           se_stk.cod_va%TYPE,
                     x_list_mag_pic     VARCHAR2) IS
    SELECT *
    FROM se_stk s
    WHERE s.cod_pro = x_cod_pro           AND
          s.cod_vl  = x_cod_vl            AND
          s.cod_va  = x_cod_va            AND
          INSTR(x_list_mag_pic, ';'||s.cod_mag||';') > 0 ;

    found_c_stk_sr    BOOLEAN;

    -- Curseur de recherche d'une action possible sur premarquage
    CURSOR c_prk_action (x_id_action_prk    su_prk_action.id_action_prk%TYPE) IS
    SELECT *
    FROM su_prk_action a
    WHERE a.id_action_prk = x_id_action_prk     AND
          (a.cod_vedoc_pce_1 IS NOT NULL OR
           a.cod_vedoc_pce_2 IS NOT NULL OR
           a.cod_vedoc_ofs   IS NOT NULL OR
           a.cod_vedoc_mqe   IS NOT NULL OR
           a.cod_vedoc_col_1 IS NOT NULL OR
           a.cod_vedoc_col_2 IS NOT NULL OR
           a.cod_vet         IS NOT NULL);

    r_prk_action       c_prk_action%ROWTYPE;
    found_prk_action   BOOLEAN;

    CURSOR c_dup_det (x_no_uee pc_uee_det.no_uee%TYPE,
                      x_no_com pc_uee_det.no_com%TYPE,
                      x_no_lig_com pc_uee_det.no_lig_com%TYPE) IS
        SELECT *
        FROM pc_uee_det
        WHERE no_uee = x_no_uee AND no_com = x_no_com AND no_lig_com = x_no_lig_com;

    r_dup_det c_dup_det%ROWTYPE;

    v_chg_prp              pc_pic.chg_prp%TYPE := 0;
    v_cod_emp              se_stk.cod_emp%TYPE;
    v_coef                 pc_uee.nb_pce_theo%TYPE;
    vr_uee                 pc_uee%ROWTYPE;
    v_nb_col               pc_uee.nb_col_theo%TYPE;
    v_no_uee_rl            pc_uee.no_uee%TYPE;
    v_qte_theo             pc_uee_det.qte_theo%TYPE;
    v_accepte_uee_rgp      VARCHAR2(20);
    v_tps_prp_pce          pc_uee_det.tps_prp_pce%TYPE;
    v_tps_prp_col          pc_uee.tps_prp_col%TYPE;
    v_cod_vet              pc_uee_det.cod_vet%TYPE;
    v_vedoc_1              pc_uee_det.cod_vedoc_col_1%TYPE;
    v_vedoc_2              pc_uee_det.cod_vedoc_col_2%TYPE;

    v_mode_arc          VARCHAR2(30):=NULL;


BEGIN

    -- Dépose d'un savepoint
    v_etape := 'Depose du savepoint my_sp_pc_ordo_resa_uee';
    SAVEPOINT my_sp_pc_ordo_resa_uee;

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                         'p_mode_dis: ' || p_mode_dis||
                         'No Lig Com: ' || p_no_com || '-' || TO_CHAR(p_no_lig_com) ||
                         'p_cod_up: ' || p_cod_up ||
                         'p_typ_up: ' || p_typ_up ||
                         'p_cod_pss_afc: ' || p_cod_pss_afc ||
                         'p_cod_pss_demandeur: ' || p_cod_pss_demandeur ||
                         'p_id_res: ' || p_id_res ||
                         'p_no_uee: ' || p_no_uee ||
                         'p_nb_colis_exp: ' || TO_CHAR(p_nb_colis_exp));
    END IF;

    -- Recherche l'etat d'activité
    IF p_crea_plan IN ( pc_ordo_pkv.AVEC_CALCUL_PLAN_AVANT_RESA,
                        pc_ordo_pkv.AVEC_CALCUL_PLAN_APRES_RESA,
                        pc_ordo_pkv.AVEC_CALCUL_PLAN_FIN_ORDO) THEN  -- plan a calculer

        v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                           p_cod_action_atv => 'VALIDATION_PLAN',
                                           p_nom_table      => 'PC_UEE');

        v_etat_atv_uee_min := su_bas_rch_etat_atv (
                                           p_cod_action_atv=> 'CREATION',
                                           p_nom_table      => 'PC_UEE');

    ELSE   -- sinon le plan existe déjà
        v_etat_atv_uee_max := su_bas_rch_etat_atv (
                                           p_cod_action_atv => 'VALIDATION_PLAN',
                                           p_nom_table      => 'PC_UEE');

        v_etat_atv_uee_min := v_etat_atv_uee_max;
    END IF;

    v_etat_atv_uee_det_avant := su_bas_rch_etat_atv('CREATION','PC_UEE_DET');
    v_etat_atv_uee_det_apres := su_bas_rch_etat_atv('RESERVATION_STOCK','PC_UEE_DET');

    -- rch clef de cfg
    v_etape := 'Rch cle pss MODE_AFF_UEE';
    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'AFF','MODE_AFF_UEE', v_mode_aff_uee);

    -- rch clef de cfg
    v_etape := 'Rch cle pss ACCEPTE_UEE_RGP';
    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'ORD','ACCEPTE_UEE_RGP', v_accepte_uee_rgp);

    -- Recherche des colis
    v_etape := 'Open c_uee';
    OPEN c_uee_det(v_etat_atv_uee_min, v_etat_atv_uee_max, v_etat_atv_uee_det_avant);
    <<boucle_uee_det>>
    LOOP
        FETCH c_uee_det INTO r_uee_det;
        EXIT WHEN c_uee_det%NOTFOUND OR v_nb_colis_exp <= 0;

        v_etape := 'Distri mode ' || p_mode_dis;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
           su_bas_put_debug(v_nom_obj || ' Ligne Colis UEE: ' || r_uee_det.no_uee ||
                            ' id_res :' || p_id_res ||
                            ' cod_pss_afc: ' || p_cod_pss_afc);
        END IF;

        -- Si 'M' : Distribution sans création des PC_PIC (pour le 'M'anuel)
        -- nécessaire pour les jointures dans les vues
        -- La distribution définitive sera faite par la tache de fond
        -- avec création des PC_PIC

        IF p_mode_dis = 'M' THEN  -- mode Manuel 'M'
            -- ------------------------
            -- Mode distribution manuel
            -- ------------------------
            -- Mise a jour de UEE_DET
            v_etape := 'MAJ pc_uee_det';
            UPDATE pc_uee_det ud SET
                ud.id_res      = p_id_res,
                ud.cod_pss_afc = p_cod_pss_afc
            WHERE ud.rowid = r_uee_det.rowid_ud;

            IF r_uee_det.typ_uee = 'CC' AND r_uee_det.cod_up IS NULL THEN  -- 'Colis Complet' + Pas de plan

                -- -------------------------------------------------------------------
                -- Mode distribution manuel mais avec calcul de plan restant à traiter
                -- => il faut mettre la cle de distribution à jour dans pc_uee_det
                -- -------------------------------------------------------------------
                v_etape     := 'init avant while';
                v_no_uee_rl := r_uee_det.no_uee;
                v_qte_theo  := r_uee_det.qte_theo;

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                   su_bas_put_debug(v_nom_obj || ' Distri Manu : v_etat_atv_uee_det_apres '||v_etat_atv_uee_det_apres );
                END IF;

                -- Conversion de la qte du colis en unité de base
                v_etape := 'conversion';
                v_ret := su_bas_conv_unite_to_one(
                                        p_cod_pro      =>r_uee_det.cod_pro_res,
                                        p_cod_vl       =>r_uee_det.cod_vl_res,
                                        p_qte_orig     =>v_qte_theo,
                                        p_unite_orig   =>r_uee_det.unite_qte,
                                        p_unite_dest   =>'UB',
                                        p_qte_dest     =>v_qte_exp_ub);

                -- *************************************************
                -- (boucle-resa) Recherche dans le tableau des resas
                -- *************************************************
                v_etape := 'Rch ds tab resa';
                FOR i IN pt_list_resa.FIRST .. pt_list_resa.LAST
                LOOP
                    v_etape := 'Calcul qte colis en UB';
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj || 'p_qte_orig:' || TO_CHAR(v_qte_theo) || ' ' || r_uee_det.unite_qte ||
                                         ' qte en UB:' || TO_CHAR(v_qte_exp_ub));
                    END IF;

                    -- MEMO :
                    -- le jour ou l'on devra distribuer sur des UEE créées à partir des UT réservées
                    -- il faudra ajouter une condition ici pour ne distribuer que sur le bon lien
                    -- UT <-> UEE

                    IF (pt_list_resa(i).qte_res - pt_list_resa(i).qte_dis_manu) > 0 AND
                        (pt_list_resa(i).typ_res <> '99' OR NVL(pt_list_resa(i).id_res_porl,0) > 0) AND
                        pt_list_resa(i).cle_distri_res IS NOT NULL THEN
                        -- Il reste une quantité a distribuer
                        -- on prend ce qu'il nous faut
                        -- Conversion de la qte restante en unité de base
                        v_etape:=' Il reste une quantité a distribuer';

                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || v_etape);
                        END IF;

                        v_ret := su_bas_conv_unite_to_one(
                                        p_cod_pro      =>pt_list_resa(i).cod_pro,
                                        p_cod_vl       =>pt_list_resa(i).cod_vl,
                                        p_qte_orig     =>pt_list_resa(i).qte_res - pt_list_resa(i).qte_dis_manu,
                                        p_unite_orig   =>pt_list_resa(i).unite_res,
                                        p_unite_dest   =>'UB',
                                        p_qte_dest     =>v_qte_resa_ub);

                        v_etape := 'Calcul qte des resa';
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || ' Res:' || TO_CHAR(pt_list_resa(i).qte_res) ||
                                                          ' Dis:' || TO_CHAR(pt_list_resa(i).qte_dis_manu) ||
                                                          ' qte resa en UB:' || TO_CHAR(v_qte_resa_ub) ||
                                                          ' qte expe en UB:' || TO_CHAR(v_qte_exp_ub));
                        END IF;

                        -- test si la quantité de resa est suffisante,
                        -- si OUI on prend la quantité v_qte_exp_ub
                        IF v_qte_resa_ub >= v_qte_exp_ub THEN
                            -- On effectue une conversion vers l'unite de resa
                            v_ret := su_bas_conv_unite_to_one(
                                        p_cod_pro      =>pt_list_resa(i).cod_pro,
                                        p_cod_vl       =>pt_list_resa(i).cod_vl,
                                        p_qte_orig     =>v_qte_exp_ub,
                                        p_unite_orig   =>'UB',
                                        p_unite_dest   =>pt_list_resa(i).unite_res,
                                        p_qte_dest     =>v_qte_a_pic);

                            -- Mise a jour du tableau
                            pt_list_resa(i).qte_dis_manu := pt_list_resa(i).qte_dis_manu + v_qte_a_pic;

                        -- Sinon la quantité est insuffisante (on prend tout)
                        -- cas de reservation multiple sur une ligne de colis
                        ELSE
                            v_qte_a_pic := pt_list_resa(i).qte_res - pt_list_resa(i).qte_dis_manu;
                            -- Mise a jour du tableau
                            pt_list_resa(i).qte_dis_manu := pt_list_resa(i).qte_res;

                        END IF;

                        v_etape := 'Calcul qte des resa';
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || ' qte a pic :' || TO_CHAR(v_qte_a_pic));
                        END IF;

                        -- Modification du process si cod_pss_final est non NULL et <> de cod_pss_afc
                        IF pt_list_resa(i).cod_pss_final IS NOT NULL AND
                            pt_list_resa(i).cod_pss_final <> p_cod_pss_afc THEN

                            v_etape := 'Changement PROCESS: ' || ' no_uee :' || v_no_uee_rl ||
                                       ' id_res :' || p_id_res || ' cod_pss_afc: ' || pt_list_resa(i).cod_pss_final;
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj || ' ' || v_etape);
                            END IF;

                            -- Mise a jour de UEE_DET
                            UPDATE pc_uee_det ud SET
                                ud.cod_pss_afc = pt_list_resa(i).cod_pss_final
                            WHERE ud.rowid = r_uee_det.rowid_ud;

                        END IF;

                        v_etape := 'MAJ cle distribution';
                        -- MAJ cle de distribution
                        UPDATE pc_uee_det ud SET
                            ud.cle_distri_res = pt_list_resa(i).cle_distri_res
                        WHERE ud.rowid = r_uee_det.rowid_ud;

                        IF v_qte_resa_ub >= v_qte_exp_ub THEN
                            -- On peut sortir de la boucle FOR car la quantité est suffisante
                            EXIT;
                        END IF;

                        -- il faut mettre a jour la qte exp en ub ... avec la partie traitée ...
                        v_qte_exp_ub := v_qte_exp_ub - v_qte_resa_ub;

                    END IF;

                END LOOP;

            END IF;

        ELSE
            -- ---------------------------------------------
            -- Mode distribution standard en automatique 'A'
            -- ---------------------------------------------
            v_etape       := 'init avant while';
            v_nb_col      := LEAST(p_nb_colis_exp, r_uee_det.nb_col_theo);
            v_no_uee_rl   := r_uee_det.no_uee;
            v_qte_theo    := r_uee_det.qte_theo;
            v_tps_prp_pce := r_uee_det.tps_prp_pce;
            v_tps_prp_col := r_uee_det.tps_prp_col;

            IF v_accepte_uee_rgp = '0' AND r_uee_det.nb_col_theo > 1 THEN
                -- il faut fractionner ... avec un coefficient de ...
                v_coef        := r_uee_det.nb_col_theo;
                v_qte_theo    := r_uee_det.qte_theo / v_coef;
                v_tps_prp_pce := r_uee_det.tps_prp_pce / v_coef;
                v_tps_prp_col := r_uee_det.tps_prp_col / v_coef;

                vr_uee := su_bas_grw_pc_uee (p_no_uee => r_uee_det.no_uee);
                vr_uee.nb_col_theo := 1;
                vr_uee.nb_pce_theo := vr_uee.nb_pce_theo / v_coef;
                vr_uee.pds_theo    := vr_uee.pds_theo / v_coef;
            END IF;

            WHILE v_nb_col > 0 LOOP -- { --

                v_etape:=' LOOP v_nb_col';
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                   su_bas_put_debug(v_nom_obj ||v_etape|| 'nb_col '|| to_char(v_nb_col));
                END IF;

                IF v_accepte_uee_rgp = '0' AND r_uee_det.nb_col_theo > 1 THEN
                    -- 1) dupliquer pc_uee et pc_uee_det
                    v_no_uee_rl := r_uee_det.no_uee || '.' || TO_CHAR(v_nb_col);

                    v_etape := 'Creation d une UEE par eclatement';
                    v_ret := pc_bas_cre_pc_uee (pr_pc_uee => vr_uee,
                                                p_no_com  => r_uee_det.no_com,
                                                p_no_uee  => v_no_uee_rl);
                    IF v_ret <> 'OK' THEN
                        RAISE err_except;
                    END IF;

                    v_etape:='moins 1 sur l''UEE de regroupement';
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                       su_bas_put_debug(v_nom_obj || v_etape);
                    END IF;

                    UPDATE pc_uee SET
                        nb_col_theo = nb_col_theo - 1
                    WHERE no_uee = r_uee_det.no_uee;

                    v_etape := 'open c_dup_det';
                    OPEN c_dup_det (r_uee_det.no_uee,
                                    r_uee_det.no_com,
                                    r_uee_det.no_lig_com);
                    LOOP
                        FETCH c_dup_det INTO r_dup_det;
                        EXIT WHEN c_dup_det%NOTFOUND;

                        v_etape := 'MAJ uee_det eclatee';
                        r_dup_det.no_uee      := v_no_uee_rl;
                        r_dup_det.nb_pce_theo := r_dup_det.nb_pce_theo / v_coef;
                        r_dup_det.pds_theo    := r_dup_det.pds_theo / v_coef;
                        r_dup_det.qte_theo    := r_dup_det.qte_theo / v_coef;

                        v_etape := 'Creation d une UEE_DET par eclatement';
                        v_ret := pc_bas_cre_pc_uee_det (pr_pc_uee_det => r_dup_det,
                                                        p_typ_uee     => 'CC'); -- toujours en colis complets !
                        IF v_ret <> 'OK' THEN
                            RAISE err_except;
                        END IF;

                        -- moins qte sur l'UEE detail de regroupement
                        UPDATE pc_uee_det SET
                            nb_pce_theo = nb_pce_theo - r_dup_det.nb_pce_theo,
                            pds_theo    = pds_theo    - r_dup_det.pds_theo,
                            qte_theo    = qte_theo    - r_dup_det.qte_theo
                        WHERE no_uee = r_uee_det.no_uee AND no_com = r_uee_det.no_com AND no_lig_com = r_uee_det.no_lig_com;

                    END LOOP;
                    CLOSE c_dup_det;

                END IF;

                -- Mise a jour de UEE_DET
                v_etape := 'MAJ pc_uee_det';
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                   su_bas_put_debug(v_nom_obj || v_etape || 'v_etat_atv_uee_det_apres '||v_etat_atv_uee_det_apres );
                END IF;

                UPDATE pc_uee_det ud SET
                    ud.id_res               = p_id_res,
                    ud.etat_atv_pc_uee_det  = v_etat_atv_uee_det_apres,
                    ud.cod_pss_afc          = p_cod_pss_afc,
                    ud.dlc_min              = r_uee_det.dlc_min,
                    ud.dlc_max              = r_uee_det.dlc_max
                WHERE ud.no_uee = v_no_uee_rl AND ud.no_com = r_uee_det.no_com AND ud.no_lig_com = r_uee_det.no_lig_com;

                -- Mise a jour du process, mode_aff_uee dans UEE
                v_etape := 'MAJ pc_uee';
                UPDATE pc_uee u SET
                    u.cod_pss_afc = p_cod_pss_afc,
                    u.mode_aff_uee = v_mode_aff_uee
                WHERE u.no_uee = v_no_uee_rl;

                -- Conversion de la qte du colis en unité de base
                v_etape := 'conversion';
                v_ret := su_bas_conv_unite_to_one(
                                        p_cod_pro      =>r_uee_det.cod_pro_res,
                                        p_cod_vl       =>r_uee_det.cod_vl_res,
                                        p_qte_orig     =>v_qte_theo,
                                        p_unite_orig   =>r_uee_det.unite_qte,
                                        p_unite_dest   =>'UB',
                                        p_qte_dest     =>v_qte_exp_ub);

                -- *************************************************
                -- (boucle-resa) Recherche dans le tableau des resas
                -- *************************************************
                v_etape := 'Rch ds tab resa';
                FOR i IN pt_list_resa.FIRST .. pt_list_resa.LAST
                LOOP
                    v_etape := 'Calcul qte colis en UB';
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj || 'p_qte_orig:' || TO_CHAR(v_qte_theo) || ' ' || r_uee_det.unite_qte ||
                                         ' qte en UB:' || TO_CHAR(v_qte_exp_ub));
                    END IF;

                    -- MEMO :
                    -- le jour ou l'on devra distribuer sur des UEE créées à partir des UT réservées
                    -- il faudra ajouter une condition ici pour ne distribuer que sur le bon lien
                    -- UT <-> UEE

                    IF (pt_list_resa(i).qte_res - pt_list_resa(i).qte_dis) > 0 AND
                       (r_uee_det.cle_distri_res IS NULL OR                                                                          -- pas de cle_distri_res de calculée au préalable
                        (r_uee_det.cle_distri_res IS NOT NULL AND r_uee_det.cle_distri_res = pt_list_resa(i).cle_distri_res)) THEN   -- ou bien un cle_distri_res de calculée au préalable et il faut la respecter
                        -- Il reste une quantité a distribuer
                        -- on prend ce qu'il nous faut
                        -- Conversion de la qte restante en unité de base
                        v_etape:=' Il reste une quantité a distribuer';

                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || v_etape);
                        END IF;

                        v_ret := su_bas_conv_unite_to_one(
                                        p_cod_pro      =>pt_list_resa(i).cod_pro,
                                        p_cod_vl       =>pt_list_resa(i).cod_vl,
                                        p_qte_orig     =>pt_list_resa(i).qte_res - pt_list_resa(i).qte_dis,
                                        p_unite_orig   =>pt_list_resa(i).unite_res,
                                        p_unite_dest   =>'UB',
                                        p_qte_dest     =>v_qte_resa_ub);

                        v_etape := 'Calcul qte des resa';
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || ' Res:' || TO_CHAR(pt_list_resa(i).qte_res) ||
                                                          ' Dis:' || TO_CHAR(pt_list_resa(i).qte_dis) ||
                                                          ' qte resa en UB:' || TO_CHAR(v_qte_resa_ub) ||
                                                          ' qte expe en UB:' || TO_CHAR(v_qte_exp_ub));
                        END IF;

                        -- test si la quantité de resa est suffisante,
                        -- si OUI on prend la quantité v_qte_exp_ub
                        IF v_qte_resa_ub >= v_qte_exp_ub THEN
                            -- On effectue une conversion vers l'unite de resa
                            v_ret := su_bas_conv_unite_to_one(
                                        p_cod_pro      =>pt_list_resa(i).cod_pro,
                                        p_cod_vl       =>pt_list_resa(i).cod_vl,
                                        p_qte_orig     =>v_qte_exp_ub,
                                        p_unite_orig   =>'UB',
                                        p_unite_dest   =>pt_list_resa(i).unite_res,
                                        p_qte_dest     =>v_qte_a_pic);

                            -- Mise a jour du tableau
                            pt_list_resa(i).qte_dis := pt_list_resa(i).qte_dis + v_qte_a_pic;

                            -- Calcul de la charge de préparation total
                            v_chg_prp := v_tps_prp_pce + v_tps_prp_col;

                        -- Sinon la quantité est insuffisante (on prend tout)
                        -- cas de reservation multiple sur une ligne de colis
                        ELSE
                            v_qte_a_pic := pt_list_resa(i).qte_res - pt_list_resa(i).qte_dis;
                            -- Mise a jour du tableau
                            pt_list_resa(i).qte_dis := pt_list_resa(i).qte_res;

                            -- Calcul de la charge de préparation partiel (bout de ligne colis)
                            v_chg_prp := (v_tps_prp_pce + v_tps_prp_col) * (v_qte_resa_ub / v_qte_exp_ub);
                        END IF;

                        IF NVL(v_chg_prp,0) = 0 THEN
                            v_chg_prp := 0.1;
                        END IF;

                        v_etape := 'Calcul qte des resa';
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || ' qte a pic :' || TO_CHAR(v_qte_a_pic));
                        END IF;
                        --
                        -- Récupération de la fiche stock
                        -- Test si mode sans resa => typ_res = '99'
                        --
                        IF (pt_list_resa(i).typ_res = '99' AND NVL(pt_list_resa(i).id_res_porl,0) = 0) OR
                           (pt_list_resa(i).no_stk IS NULL) THEN
                            --
                            -- On n'a pas de fiche de stock ...
                            -- On recherche s'il existe une fiche STK sur les magasins de pick.
                            --
                            v_etape := 'On Recherche une fiche STK, cas du mode sans RESA: ' ||
                                         ' Pro :' || pt_list_resa(i).cod_pro ||
                                         ' VL :' || pt_list_resa(i).cod_vl ||
                                         ' VA :' || pt_list_resa(i).cod_va ||
                                         ' List_cod_mag_pic :' || pt_list_resa(i).list_cod_mag_pic;
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj || v_etape);
                            END IF;

                            OPEN c_stk_sr (pt_list_resa(i).cod_pro,
                                            pt_list_resa(i).cod_vl,
                                            pt_list_resa(i).cod_va,
                                            pt_list_resa(i).list_cod_mag_pic);
                            FETCH c_stk_sr INTO r_stk;
                            found_c_stk_sr := c_stk_sr%FOUND;
                            CLOSE c_stk_sr;
                            IF found_c_stk_sr THEN
                                v_no_stk := r_stk.no_stk;
                                pt_list_resa(i).cod_mag_pic := r_stk.cod_mag;
                            ELSE
                                v_no_stk := NULL;
                                r_stk := NULL;       --Reset le record
                                -- Recherche le 1er magasin de picking dans la liste
                                v_pos := 1;
                                v_pos := su_bas_extract_liste(v_pos,pt_list_resa(i).list_cod_mag_pic, v_cod_mag_pic);
                                IF v_cod_mag_pic IS NULL THEN
                                   -- Recherche d'un magasin de picking impossible
                                   v_etape:= 'ERREUR: Magasin de picking Inexistant, cas du mode SANS RESA';
                                   IF su_global_pkv.v_niv_dbg >= 6 THEN
                                      su_bas_put_debug(v_nom_obj || v_etape);
                                   END IF;
                                   RAISE err_except;
                                END IF;

                                -- On renseigne le record avec le strict minimum
                                v_etape := 'On renseigne le record avec le strict minimum, cas de mode sans RESA: ' ||
                                           ' Pro :' || pt_list_resa(i).cod_pro ||
                                           ' VL :' || pt_list_resa(i).cod_vl ||
                                           ' VA :' || pt_list_resa(i).cod_va ||
                                           ' List_cod_mag_pic :' || v_cod_mag_pic;
                                IF su_global_pkv.v_niv_dbg >= 6 THEN
                                   su_bas_put_debug(v_nom_obj || v_etape);
                                END IF;

                                r_stk.cod_pro := pt_list_resa(i).cod_pro;
                                r_stk.cod_vl  := pt_list_resa(i).cod_vl;
                                r_stk.cod_va  := pt_list_resa(i).cod_va;
                                r_stk.cod_mag := v_cod_mag_pic;
                                r_stk.cod_usn := p_cod_usn;
                                pt_list_resa(i).cod_mag_pic := v_cod_mag_pic;
                            END IF;

                        ELSIF v_no_stk IS NULL OR v_no_stk <> pt_list_resa(i).no_stk THEN
                            --
                            -- on reprend la fiche de stock reservée ...
                            --
                            v_no_stk :=  pt_list_resa(i).no_stk;

                            v_etape:=' On récupère le record de la fiche STK';
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj || v_etape);
                            END IF;

                            --OPEN c_stk (v_no_stk);
                            --FETCH c_stk INTO r_stk;
                            --CLOSE c_stk;

                            -- recopie fiche de stock origine
                            r_stk := pt_list_resa(i).r_stk;

                        END IF;

                        IF pt_list_resa(i).unite_res <> pt_list_resa(i).unite_stk THEN
                            -- On effectue une conversion vers l''unite de stock
                            v_ret := su_bas_conv_unite_to_one(
                                            p_cod_pro      =>pt_list_resa(i).cod_pro,
                                            p_cod_vl       =>pt_list_resa(i).cod_vl,
                                            p_qte_orig     =>v_qte_a_pic,
                                            p_unite_orig   =>pt_list_resa(i).unite_res,
                                            p_unite_dest   =>pt_list_resa(i).unite_stk,
                                            p_qte_dest     =>v_qte_a_pic_stk);
                            IF v_ret <> 'OK' THEN
                                v_etape := 'PB lors de la conversion d''unité->' ||
                                           ' p_cod_pro: '    || pt_list_resa(i).cod_pro ||
                                           ' p_cod_vl: '     || pt_list_resa(i).cod_vl  ||
                                           ' p_qte_orig: '   || v_qte_a_pic      ||
                                           ' p_unite_orig: ' || pt_list_resa(i).unite_res ||
                                           ' p_unite_dest: ' || pt_list_resa(i).unite_stk;
                                RAISE err_except;
                            END IF;
                        ELSE
                           v_qte_a_pic_stk := v_qte_a_pic;
                        END IF;

                        -- Création de l'ordre de picking (ou regroupement)
                        v_ret := pc_bas_crea_pic (p_no_com      =>p_no_com,
                                                  p_no_lig_com  =>p_no_lig_com,
                                                  p_no_uee      =>v_no_uee_rl,
                                                  p_typ_uee     =>r_uee_det.typ_uee,
                                                  pr_stk        =>r_stk,
                                                  p_cod_pss_afc =>NVL(pt_list_resa(i).cod_pss_final, p_cod_pss_afc),
                                                  p_cod_verrou  =>p_cod_verrou,
                                                  p_qte_a_pic   =>v_qte_a_pic_stk,
                                                  p_unite_pic   =>pt_list_resa(i).unite_stk,
                                                  p_qte_a_pic_2 =>v_qte_a_pic,
                                                  p_unite_pic_2 =>pt_list_resa(i).unite_res,
                                                  p_cod_mag_pic =>pt_list_resa(i).cod_mag_pic,
                                                  p_chg_prp     =>NVL(v_chg_prp,0));

                        IF v_ret <> 'OK' THEN
                            v_etape := 'Erreur lors de la Création des ordres PIC';
                            v_cod_err_su_ano := 'PC-ORDO016';
                            RAISE err_except;
                        END IF;

                        -- Mise a jour dans PC_UEE_DET
                        -- du COD_MAG_PIC et de COD_EMP_PIC
                        v_etape := 'Update PC_UEE_DET, Maj COD_MAG_PIC, COD_EMP_PIC, COD_PRK: '
                                   || ' No_uee :' || v_no_uee_rl
                                   || ' No_Com :' || r_uee_det.no_com
                                   || ' No_lig :' || r_uee_det.no_lig_com
                                   || ' Cod_Mag_Pic :' || pt_list_resa(i).cod_mag_pic
                                   || ' Cod_Emp_Pic :' || r_stk.cod_emp
                                   || ' Cod_Prk :' || pt_list_resa(i).cod_prk;

                        IF r_stk.cod_emp IS NULL THEN
                            -- on recherche 1 emplacement de débord sur le magasin
                            OPEN c_emp(pt_list_resa(i).cod_mag_pic);
                            FETCH c_emp INTO r_emp;
                            IF c_emp%NOTFOUND THEN
                                v_etape := 'PB, pas d''emplacement de débord (CTG_EMP=DEB) trouvé sur le mag: ' ||
                                           pt_list_resa(i).cod_mag_pic;
                                v_cod_err_su_ano := 'PC-ORDO023';
                                RAISE err_except;
                            END IF;
                            CLOSE c_emp;
                        END IF;

                        -- Test si égalité entre magasin de résa et magasin de picking
                        -- Si OUI, le code emp est bon,  si NON forcé le code emp à NULL
                        -- Il sera reculer par l'affectation (si NULL)
                        IF r_stk.cod_mag =  NVL(pt_list_resa(i).cod_mag_pic, '$') THEN
                           v_cod_emp := r_stk.cod_emp;
                        ELSE
                           v_cod_emp := NULL;
                        END IF;

                        v_etape:='UPDATE pc_uee_det magasin';
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || v_etape);
                        END IF;

                        UPDATE pc_uee_det ud SET
                            ud.cod_pro_res = pt_list_resa(i).cod_pro,
                            ud.cod_va_res  = pt_list_resa(i).cod_va,
                            ud.cod_vl_res  = pt_list_resa(i).cod_vl,
                            ud.cod_mag_pic = pt_list_resa(i).cod_mag_pic,
                            ud.cod_prk_res = pt_list_resa(i).cod_prk,
                            ud.cod_emp_pic = v_cod_emp,
                            ud.cle_distri_res = pt_list_resa(i).cle_distri_res,
                            ud.dlc_min = LEAST(ud.dlc_min, NVL(r_stk.dat_dlc, ud.dlc_min)),  -- $MODGQUI cas d'un contrat date forcé a l'ordo manuel
                            ud.dlc_max=GREATEST (ud.dlc_max,NVL(r_stk.dat_dlc,ud.dlc_max))
                        WHERE ud.no_uee = v_no_uee_rl AND ud.no_com = r_uee_det.no_com AND ud.no_lig_com = r_uee_det.no_lig_com;

                        -- Modification du process si cod_pss_final est non NULL et <> de cod_pss_afc
                        IF pt_list_resa(i).cod_pss_final IS NOT NULL AND
                            pt_list_resa(i).cod_pss_final <> p_cod_pss_afc THEN

                            v_etape := 'Changement du PROCESS sur pc_uee et pc_uee_det: ' ||
                                         ' No_uee :' || v_no_uee_rl ||
                                         ' Id_res :' || p_id_res ||
                                         ' Cod_pss_afc: ' || pt_list_resa(i).cod_pss_final;
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj || v_etape);
                            END IF;

                            -- Mise a jour de UEE_DET
                            UPDATE pc_uee_det ud SET
                                ud.cod_pss_afc = pt_list_resa(i).cod_pss_final
                            WHERE ud.no_uee = v_no_uee_rl AND ud.no_com = r_uee_det.no_com AND ud.no_lig_com = r_uee_det.no_lig_com;

                            -- Mise a jour du process, mode_aff_uee dans UEE
                            UPDATE pc_uee u SET
                                u.cod_pss_afc = pt_list_resa(i).cod_pss_final
                            WHERE u.no_uee = v_no_uee_rl;
                        END IF;

                        v_etape := 'Recup id_action_prk:';
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || v_etape ||
                                ' id_action_prk: ' || pt_list_resa(i).id_action_prk);
                        END IF;

                        --  Modification si action de prémarquage => id_action_prk is not NULL
                        IF pt_list_resa(i).id_action_prk IS NOT NULL THEN
                            -- Recherche si une fiche action existe
                            OPEN c_prk_action (pt_list_resa(i).id_action_prk);
                            FETCH c_prk_action INTO r_prk_action;
                            found_prk_action := c_prk_action%FOUND;
                            CLOSE c_prk_action;
                        END IF;

                        IF r_uee_det.typ_uee = 'CC' THEN
                            v_cod_vet := r_uee_det.cod_vet;
                            v_vedoc_1 := r_uee_det.cod_vedoc_col_1;
                            v_vedoc_2 := r_uee_det.cod_vedoc_col_2;
                        ELSE
                            v_cod_vet := NVL(r_uee_det.cod_vet_cd, r_uee_det.cod_vet);
                            v_vedoc_1 := r_uee_det.cod_vedoc_col_1_cd;
                            v_vedoc_2 := r_uee_det.cod_vedoc_col_2_cd;
                        END IF;

                        IF pt_list_resa(i).id_action_prk IS NOT NULL AND found_prk_action THEN
                            v_etape := 'Modification des VEs sur pc_uee_det fct de SU_PRK_ACTION: ' ||
                                   ' No_uee :' || v_no_uee_rl ||
                                   ' Id_res :' || p_id_res ||
                                   ' id_action_prk: ' || pt_list_resa(i).id_action_prk;
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj || v_etape);
                            END IF;

                            v_no_etape := '1';      -- '1', pour mise a jour sur evenement
                            UPDATE pc_uee_det ud SET
                               ud.cod_vedoc_pce_1 = NVL(r_prk_action.cod_vedoc_pce_1, r_uee_det.cod_vedoc_pce_1),
                               ud.cod_vedoc_pce_2 = NVL(r_prk_action.cod_vedoc_pce_2, r_uee_det.cod_vedoc_pce_2),
                               ud.cod_vedoc_col_1 = NVL(r_prk_action.cod_vedoc_col_1, v_vedoc_1),
                               ud.cod_vedoc_col_2 = NVL(r_prk_action.cod_vedoc_col_2, v_vedoc_2),
                               ud.cod_vedoc_ofs   = NVL(r_prk_action.cod_vedoc_ofs,   r_uee_det.cod_vedoc_ofs),
                               ud.cod_vedoc_mqe   = NVL(r_prk_action.cod_vedoc_mqe,   r_uee_det.cod_vedoc_mqe),
                               ud.cod_vet         = NVL(r_prk_action.cod_vet, v_cod_vet)
                            WHERE ud.no_uee = v_no_uee_rl AND ud.no_com = r_uee_det.no_com AND ud.no_lig_com = r_uee_det.no_lig_com;

                        ELSE
                            -- sinon on remet à niveau les VE en fonction de la ligne
                            v_etape := 'Mise à niveau des VE fct de PC_LIG_COM';
                            v_no_etape := '2';      -- '2', pour mise a jour sur evenement
                            UPDATE pc_uee_det ud SET
                               ud.cod_vedoc_pce_1 = r_uee_det.cod_vedoc_pce_1,
                               ud.cod_vedoc_pce_2 = r_uee_det.cod_vedoc_pce_2,
                               ud.cod_vedoc_col_1 = v_vedoc_1,
                               ud.cod_vedoc_col_2 = v_vedoc_2,
                               ud.cod_vedoc_ofs   = r_uee_det.cod_vedoc_ofs,
                               ud.cod_vedoc_mqe   = r_uee_det.cod_vedoc_mqe,
                               ud.cod_vet         = v_cod_vet
                            WHERE ud.no_uee = v_no_uee_rl AND ud.no_com = r_uee_det.no_com AND ud.no_lig_com = r_uee_det.no_lig_com;
                        END IF;

                        -- appel evenement metier
                        v_etape := 'Maj sur Evt du colis détail à l''ordonnancement';
                        v_ret := pc_bap_ORDOMAJUEED01 (p_no_etape => v_no_etape,
                                                       p_cod_usn => p_cod_usn,
                                                       p_cod_verrou => p_cod_verrou,
                                                       p_no_com     => p_no_com,
                                                       p_no_lig_com => p_no_lig_com,
                                                       p_no_uee     => v_no_uee_rl,
                                                       p_cod_pro    => pt_list_resa(i).cod_pro,
                                                       p_cod_va     => pt_list_resa(i).cod_va,
                                                       p_cod_vl     => pt_list_resa(i).cod_vl);

                        IF v_qte_resa_ub >= v_qte_exp_ub THEN
                           -- On peut sortir de la boucle FOR car la quantité est suffisante
                           EXIT;
                        END IF;

                        -- il faut mettre a jour la qte exp en ub ... avec la partie traitée ...
                        v_qte_exp_ub := v_qte_exp_ub - v_qte_resa_ub;

                    END IF;
                END LOOP;  -- boucle_resa;

                -- -----------------------------------------
                -- decrementation pour assurer la sortie ...
                -- -----------------------------------------
                IF (v_accepte_uee_rgp = '0' AND r_uee_det.nb_col_theo > 1) THEN

                    v_etape:=' moins 1 car on fractionne';
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj || v_etape);
                    END IF;

                    v_nb_col := v_nb_col - 1;
                    IF v_nb_col <= 0 THEN
                        IF v_nb_colis_exp >= r_uee_det.nb_col_theo THEN
                            v_etape := 'DELETE uee_det RGP';
                            -- recupere su_global_pkv.v_mode_arc
                            v_mode_arc:= su_global_pkv.v_mode_arc;
                            --positionne v_mode_arc a MANU pour ne pas archiver
                            su_global_pkv.v_mode_arc:='MANU';

                            DELETE pc_uee_det
                            WHERE no_uee = r_uee_det.no_uee AND no_com = r_uee_det.no_com AND no_lig_com = r_uee_det.no_lig_com;

                            v_etape := 'DELETE uee RGP';
                            DELETE pc_uee
                            WHERE no_uee = r_uee_det.no_uee;
                            su_global_pkv.v_mode_arc:=v_mode_arc;
                        END IF;
                    END IF;
                ELSE
                    -- on doit sortir des le premier tour ...
                    v_nb_col := v_nb_col - r_uee_det.nb_col_theo;
                END IF;

            END LOOP;  -- } WHILE

        END IF;   -- IF p_mode_dis <> 'A'... ELSE....

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            v_etape:=' (v_nb_colis_exp-r_uee_det.nb_col_theo)=';
            su_bas_put_debug(v_nom_obj || v_etape || TO_CHAR(v_nb_colis_exp - r_uee_det.nb_col_theo));
        END IF;

        v_nb_colis_exp := v_nb_colis_exp - r_uee_det.nb_col_theo;

    END LOOP boucle_uee_det;
    CLOSE c_uee_det;

    --IF v_nb_colis_exp > 0 OR p_mode_dis = 'A' THEN
    IF v_nb_colis_exp > 0 THEN
        -- cas en principe impossible
        -- on trace une anomalie.
        v_etape := 'Tous les colis en réservation n''ont pu être distribués, reste: ' || v_nb_colis_exp;
        IF su_global_pkv.v_niv_dbg >= 6 THEN
           su_bas_put_debug(v_nom_obj || v_etape);
        END IF;
        v_cod_ala        := 'PC_MAJ_RESA';
        v_cod_err_su_ano := 'PC-ORDO021';
        RAISE err_except;
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_global_pkv.v_mode_arc:='AUTO';
        v_cod_err_su_ano := NVL(v_cod_err_su_ano, 'ERROR');
        -- on doit rollbacker au savepoint
        ROLLBACK TO my_sp_pc_ordo_resa_uee;

        IF v_cod_ala= 'PC_MAJ_RESA' THEN -- a faire apres le rollback pour recuperer les memes uee
            IF p_no_uee IS NOT NULL THEN
                pc_bas_set_err_enr (p_table=>'PC_UEE',
                                    p_cod_err=>'ERR_RESA',
                                    p_cle1=>p_no_uee); -- transaction autonome
            ELSE
                FOR r_uee IN c_uee_det(v_etat_atv_uee_min, v_etat_atv_uee_max, v_etat_atv_uee_det_avant)
                LOOP
                    -- mise en erreur des uee
                    pc_bas_set_err_enr (p_table=>'PC_UEE',
                                        p_cod_err=>'ERR_RESA',
                                        p_cle1=>r_uee.no_uee); -- transaction autonome
                END LOOP;
            END IF;
        END IF;

        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'No_lig',
                        p_par_ano_2       => p_no_lig_com,
                        p_lib_ano_3       => 'NbColRestant',
                        p_par_ano_3       => TO_CHAR(v_nb_colis_exp),
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => v_cod_ala);

       RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_distri_id_res
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'affecter aux colis un identifiant de réservation
-- donné.
-- Un mode de distribution simplifié existe (moe 'M') et est utilisé par
-- l'ordonnancement
--
--
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03a,23.04.14,mnev    n'utilise plus se_stk dans tous les cas.
-- 02b,11.04.14,mnev    n'utilise plus se_stk en mode preordo ligne.
-- 02a,26.02.14,mnev    ajout prise en compte de id_res_porl ds tableau resa
-- 01h,04.01.13,mnev    ajout infos dans le tableau des réservations
-- 01g,31.12.12,mnev    Recopie process issu de l'événement de rch.
--
-- 01f,14.09.11,mnev    Picking en unité de stock si config sans résa
-- 01e,18.03.11,mnev    Ajout arrondi a la 3eme decimale sur v_qte_pce
-- 01d,08.03.11,mnev    Change test sur v_mode_gen_uee
-- 01c,31.01.11,rleb    Ajout creation UEE suivant la résa.
-- 01b,03.07.09,mnev    Correction sur retrait de la partie decimale
--                      de la reservation.
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_typ_vag    : type de vague
--  p_ss_typ_vag : sous type de vague
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_distri_id_res ( p_cod_usn          su_usn.cod_usn%TYPE,
                                p_no_com           pc_lig_com.no_com%TYPE,
                                p_no_lig_com       pc_lig_com.no_lig_com%TYPE,
                                pr_pc_rstk         pc_rstk%ROWTYPE,
                                p_cod_verrou       VARCHAR2,
                                p_crea_plan        VARCHAR2,
                                p_mode_dis         VARCHAR2 DEFAULT 'A'   -- 'A'(Automatique) ou 'M'(Manuel)
    )  RETURN VARCHAR2

IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_distri_id_res:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclarations de variables
    -----------------------------
    v_nb_colis_exp_ann  NUMBER   := 0;      -- Nb de colis à expédier annules
    v_nb_colis_exp      NUMBER   := 0;      -- Nb de colis à expédier réserves
    v_qte_unit_base     NUMBER   := 0;      -- Qte en equivalent en unite base
    v_qte_ub            NUMBER   := 0;      -- buffer

    v_qte_unit_2        NUMBER   := 0;
    v_unit_stk_2        VARCHAR2(10) := NULL;
    v_qte_ul            NUMBER   := 0;
    v_qte_col           NUMBER   := 0;
    v_qte_pds           NUMBER   := 0;
    v_qte_pce           NUMBER   := 0;
    v_qte_pal           NUMBER   := 0;
    v_qte_vol           NUMBER   := 0;

    -- Déclaration d'un tableau des resa_a_picker
    vt_list_resa        pc_ordo_pkg.tt_lst_resa;
    vi                  NUMBER   := 0;      -- Indice du tableau
    v_no_uee_ec         pc_uee.no_uee%TYPE;
    v_trt_dis_ec        VARCHAR2(10) := 'ERROR';  -- flag de traitement en cours

    v_pos_prk           NUMBER;
    v_pos_pss           NUMBER;
    v_pos_id            NUMBER;
    v_cod_prk           se_lig_rstk.cod_prk%TYPE;
    v_cod_pss           pc_rstk.cod_pss_afc%TYPE;
    v_id_action_prk     su_prk_action.id_action_prk%TYPE;
    v_cod_pss_final     pc_rstk.cod_pss_afc%TYPE;
    v_id_res            pc_rstk.id_res%TYPE;
    v_qte_reliquat      NUMBER;
    v_unite_reliquat    VARCHAR2(10) := NULL;
    v_qte_a_dereserver  NUMBER;
    --v_mode_gen_uee      VARCHAR2(20) := NULL;
    v_status            VARCHAR2(20);

    -- Curseur sur les lignes de resa avec en UNION
    -- le cas du mode SANS RESERVATION (typ_resa = 99)
    CURSOR c_lig_resa (x_id_res    pc_rstk.id_res%TYPE,
                       x_cod_usn   su_usn.cod_usn%TYPE) IS
    SELECT '1',
           rs.id_res        ID_RES,
           rs.unite_qte     UNIT_RES_DEM,
           rl.qte_res       QTE_RES,
           rl.unit_res      UNIT_RES,
           rl.qte_res_stk   QTE_RES_STK,
           rl.unit_stk      UNIT_STK,
           rl.no_lig_rstk   NO_LIG_RSTK,
           rl.no_stk        NO_STK,
           rl.cod_pro       COD_PRO_RES,
           rl.cod_vl        COD_VL_RES,
           rl.cod_va        COD_VA_RES,
           rl.cod_ut        COD_UT_STK_RES,
           rl.typ_ut        TYP_UT_STK_RES,
           rl.cod_prk       COD_PRK,
           rl.cod_emp       COD_EMP,
           rl.cod_mag       COD_MAG,
           rl.dat_stk       DAT_STK,
           rl.dat_dlc       DAT_DLC,
           rl.dat_ent_mag   DAT_ENT_MAG,
           rl.cod_lot_stk   COD_LOT_STK,
           rl.cod_ss_lot_stk COD_SS_LOT_STK,
           rl.cod_mag_pic   COD_MAG_PIC,
           rs.typ_res       TYP_RES,
           rs.id_res_porl   ID_RES_PORL,
           rl.car_stk_1, rl.car_stk_2, rl.car_stk_3,
           rl.car_stk_4, rl.car_stk_5, rl.car_stk_6,
           rl.car_stk_7, rl.car_stk_8, rl.car_stk_9,
           rl.car_stk_10, rl.car_stk_11, rl.car_stk_12,
           rl.car_stk_13, rl.car_stk_14, rl.car_stk_15,
           rl.car_stk_16, rl.car_stk_17, rl.car_stk_18,
           rl.car_stk_19, rl.car_stk_20,
           rl.cod_soc_proprio,
           rl.cod_usn
    FROM   pc_rstk rs, pc_rstk_det rl
    WHERE   rl.id_res  = x_id_res           AND
            rs.id_res  = rl.id_res          AND
            rs.typ_res  <> '99'             AND
            rl.cod_usn = x_cod_usn
   UNION ALL
   SELECT  '1',
           rs.id_res        ID_RES,
           rs.unite_qte     UNIT_RES_DEM,
           rs.qte_res       QTE_RES,
           rs.unite_qte     UNIT_RES,
           rs.qte_res       QTE_RES_STK,
           rs.unite_qte     UNIT_RES_STK,
           NULL             NO_LIG_RSTK,
           NULL             NO_STK,
           l.cod_pro        COD_PRO_RES,
           l.cod_vl         COD_VL_RES,
           l.cod_va         COD_VA_RES,
           NULL             COD_UT_STK_RES,
           NULL             TYP_UT_STK_RES,
           NULL             COD_PRK,
           NULL             COD_EMP,
           NULL             COD_MAG,
           NULL             DAT_STK,
           NULL             DAT_DLC,
           NULL             DAT_ENT_MAG,
           NULL             COD_LOT_STK,
           NULL             COD_SS_LOT_STK,
           NULL             COD_MAG_PIC,
           rs.typ_res       TYP_RES,
           rs.id_res_porl   ID_RES_PORL,
           NULL car_stk_1, NULL car_stk_2, NULL car_stk_3,
           NULL car_stk_4, NULL car_stk_5, NULL car_stk_6,
           NULL car_stk_7, NULL car_stk_8, NULL car_stk_9,
           NULL car_stk_10, NULL car_stk_11, NULL car_stk_12,
           NULL car_stk_13, NULL car_stk_14, NULL car_stk_15,
           NULL car_stk_16, NULL car_stk_17, NULL car_stk_18,
           NULL car_stk_19, NULL car_stk_20,
           NULL cod_soc_proprio,
           l.cod_usn
    FROM   pc_rstk rs, pc_lig_com l
    WHERE   rs.id_res    = x_id_res         AND
            rs.typ_res   = '99'             AND
            l.no_com     = rs.ref_rstk_1    AND
            l.id_res_porl IS NULL           AND
            l.no_lig_com = pc_bas_to_number(rs.ref_rstk_2) AND
            l.cod_usn = x_cod_usn
   UNION ALL
    SELECT '1',
           rs.id_res        ID_RES,
           rs.unite_qte     UNIT_RES_DEM,
           rl.qte_res       QTE_RES,
           rl.unit_res      UNIT_RES,
           rl.qte_res_stk   QTE_RES_STK,
           rl.unit_stk      UNIT_STK,
           rl.no_lig_rstk   NO_LIG_RSTK,
           rl.no_stk        NO_STK,
           rl.cod_pro       COD_PRO_RES,
           rl.cod_vl        COD_VL_RES,
           rl.cod_va        COD_VA_RES,
           rl.cod_ut        COD_UT_STK_RES,
           rl.typ_ut        TYP_UT_STK_RES,
           rl.cod_prk       COD_PRK,
           rl.cod_emp       COD_EMP,
           rl.cod_mag       COD_MAG,
           rl.dat_stk       DAT_STK,
           rl.dat_dlc       DAT_DLC,
           rl.dat_ent_mag   DAT_ENT_MAG,
           rl.cod_lot_stk   COD_LOT_STK,
           rl.cod_ss_lot_stk COD_SS_LOT_STK,
           rl.cod_mag_pic   COD_MAG_PIC,
           rs.typ_res       TYP_RES,
           rs.id_res_porl   ID_RES_PORL,
           rl.car_stk_1, rl.car_stk_2, rl.car_stk_3,
           rl.car_stk_4, rl.car_stk_5, rl.car_stk_6,
           rl.car_stk_7, rl.car_stk_8, rl.car_stk_9,
           rl.car_stk_10, rl.car_stk_11, rl.car_stk_12,
           rl.car_stk_13, rl.car_stk_14, rl.car_stk_15,
           rl.car_stk_16, rl.car_stk_17, rl.car_stk_18,
           rl.car_stk_19, rl.car_stk_20,
           rl.cod_soc_proprio,
           rl.cod_usn
    FROM   pc_rstk rs, pc_rstk_det rl
    WHERE   rl.id_res  = x_id_res           AND
            rs.id_res  = rl.id_res          AND
            rs.typ_res  = '99'              AND
            rs.id_res_porl IS NOT NULL      AND
            rl.cod_usn = x_cod_usn
    ORDER BY 1, DAT_DLC ASC NULLS LAST, DAT_ENT_MAG ASC NULLS LAST;

    r_lig_resa         c_lig_resa%ROWTYPE;
    found_lig_resa     BOOLEAN;

    r_lig_com          pc_lig_com%ROWTYPE;

    CURSOR c_nb_col_exp IS
        SELECT count(*) nb_col_exp
        FROM pc_uee_det
        WHERE id_res=pr_pc_rstk.id_res AND etat_atv_pc_uee_det='CREA';

    r_nb_col_exp c_nb_col_exp%ROWTYPE;

    v_cle_distri_res pc_uee_det.cle_distri_res%TYPE := NULL;

BEGIN

    -- Dépose d'un savepoint
    v_etape := 'Depose du savepoint my_sp_pc_distri_id_res';
    SAVEPOINT my_sp_pc_distri_id_res;

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' ' || v_etape);
    END IF;

    v_id_res := pr_pc_rstk.id_res;

    -- init compteurs
    v_nb_colis_exp  := 0;      -- Nb de colis à expédier et réservé
    v_qte_unit_base := 0;      -- Qte dans l'unite base
    v_qte_ub        := 0;      -- buffer

    -- init tableau
    vt_list_resa.DELETE;
    vi := 1;

    v_etape :=  'LOOP sur les lignes de resa id_res = ' || v_id_res;
    IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj || ' ' || v_etape);
    END IF;

    OPEN c_lig_resa (v_id_res, p_cod_usn);
    LOOP
        FETCH c_lig_resa INTO r_lig_resa;
        EXIT WHEN c_lig_resa%NOTFOUND;

        IF su_global_pkv.v_niv_dbg >= 3 THEN
            v_etape := 'Lig Resa pour Com-Lig: ' || p_no_com || '-' || p_no_lig_com ||
                        ' Pro: '     || r_lig_resa.cod_pro_res ||
                        ' VA: '      || r_lig_resa.cod_va_res  ||
                        ' VL: '      || r_lig_resa.cod_vl_res  ||
                        ' Qte_res: ' || r_lig_resa.qte_res ||
                        ' Unit: '    || r_lig_resa.unit_res ||
                        ' Id_res: '  || r_lig_resa.id_res;

            su_bas_put_debug(v_nom_obj || ' ' || v_etape);
        END IF;

        -- Conversion obligatoire (cas des substitution ou changement de VL)
        -- pour calculer la quantité en unite de base
        v_etape :=  'Conversion de la réservation id_res: ' || v_id_res ||
                    ' No_lig_rstk : ' || TO_CHAR(r_lig_resa.no_lig_rstk);
        v_ret := su_bas_conv_unite_to_one(
                                p_cod_pro      =>r_lig_resa.cod_pro_res,
                                p_cod_vl       =>r_lig_resa.cod_vl_res,
                                p_qte_orig     =>r_lig_resa.qte_res,
                                p_unite_orig   =>r_lig_resa.unit_res,
                                p_unite_dest   =>'UB',
                                p_qte_dest     =>v_qte_ub);

        IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || ' v_qte_ub:' || TO_CHAR(v_qte_ub));
        END IF;

        -- Somme (cas de lots multiple, dlc, ...)
        v_qte_unit_base := v_qte_unit_base + v_qte_ub;

        v_cod_pss_final := pr_pc_rstk.cod_pss_afc;
        -- Test si resa d'un prk  => Recherche du process associé
        -- et de l'identifiant de la fiche su_prk_action
        IF NVL(r_lig_resa.cod_prk, '#NULL#') <> '#NULL#' OR
           INSTR(pr_pc_rstk.list_cod_prk, '$CDE') > 0 THEN            -- ajout clause INSTR(... $MODGQUI 02032010
            v_etape := 'Récupération d''un process associé possible et d''un id_action_prk';
            v_pos_prk := 1;
            v_pos_pss := 1;
            v_pos_id  := 1;
            LOOP
                v_pos_prk := su_bas_extract_liste(v_pos_prk, pr_pc_rstk.list_cod_prk, v_cod_prk);
                v_pos_pss := su_bas_extract_liste(v_pos_pss, pr_pc_rstk.list_cod_pss_prk, v_cod_pss);
                v_pos_id  := su_bas_extract_liste(v_pos_id,  pr_pc_rstk.list_id_action_prk, v_id_action_prk);
                EXIT WHEN v_pos_prk <=0;
                IF NVL(v_cod_prk, '#NULL#') <> '#NULL#' AND
                   (v_cod_prk = r_lig_resa.cod_prk  OR v_cod_prk = '$CDE') THEN   -- ajout test OR v_cod_prk = '$CDE', $MODGQUI 02032010
                   IF NVL(v_cod_pss, '#NULL#') <> '#NULL#' THEN
                       v_cod_pss_final := v_cod_pss;
                   END IF;
                   IF v_id_action_prk = '#NULL#' THEN
                       v_id_action_prk := NULL;  -- repositionne à NULL
                   END IF;
                   EXIT;   -- on sort
                END IF;
            END LOOP;
        END IF;

        -- Appel d'un évènement pour le choix final du process
        -- oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
        -- Possibilité de gérer un évènement pour le choix final du process
        -- oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
        IF r_lig_resa.no_stk IS NOT NULL AND
            v_cod_pss_final IS NOT NULL AND
            su_global_pkv.vt_evt_actif.exists('ON_RCH_PSS_VAL_ORDO') THEN
            v_etape := 'Appel événement ON_RCH_PSS_VAL_ORDO';
            v_ret_evt :=  pc_evt_rch_pss_val_ordo('ON',
                                                  v_cod_pss_final,
                                                  r_lig_resa.no_stk);
            IF v_ret_evt = 'ERROR' THEN
               v_cod_err_su_ano := 'PC-ORDO101' ;
               su_bas_cre_ano (p_txt_ano  => 'ERREUR: ' || v_etape,
                    p_cod_err_ora_ano => SQLCODE,
                    p_lib_ano_1       => 'Cod_pss',
                    p_par_ano_1       => v_cod_pss_final,
                    p_lib_ano_2       => 'No stk',
                    p_par_ano_2       => r_lig_resa.no_stk,
                    p_cod_err_su_ano  => v_cod_err_su_ano,
                    p_nom_obj         => v_nom_obj,
                    p_version         => v_version);
               RAISE err_except;
            END IF;

            -- process fourni par l'evenement
            v_cod_pss_final := NVL(v_ret_evt, v_cod_pss_final);

        END IF;

        -- A partir d'ici le process final est connu ...
        -- => rch de la configuration de la cle de distribution
        v_etape := 'Rch cle pss MODE_CAL_CLE_DISTRI';
        v_ret   := su_bas_rch_cle_atv_pss(v_cod_pss_final,'ORD','MODE_CAL_CLE_DISTRI',v_cle_distri_res);

        IF v_cle_distri_res = 'NONE' THEN
            v_cle_distri_res := NULL;

        ELSIF v_cle_distri_res = 'UT_STK' THEN
            v_cle_distri_res := r_lig_resa.cod_ut_stk_res || r_lig_resa.typ_ut_stk_res;

        ELSIF v_cle_distri_res = 'MAG' THEN
            v_cle_distri_res := r_lig_resa.cod_mag;

        ELSIF v_cle_distri_res = 'EMP' THEN
            v_cle_distri_res := r_lig_resa.cod_emp;

        ELSIF v_cle_distri_res = 'DLC' THEN
            v_cle_distri_res := r_lig_resa.dat_dlc;

        ELSIF v_cle_distri_res = 'LOT' THEN
            v_cle_distri_res := r_lig_resa.cod_lot_stk;

        ELSIF v_cle_distri_res = 'PRO' THEN
            v_cle_distri_res := r_lig_resa.cod_pro_res;

        ELSIF v_cle_distri_res = 'ART' THEN
            v_cle_distri_res := r_lig_resa.cod_pro_res||r_lig_resa.cod_va_res||r_lig_resa.cod_vl_res;

        ELSE
            v_cle_distri_res := NULL;
        END IF;

        -- Mise a jour unite_stk et qte_res_stk
        -- pour permettre un picking en unite de stock.
        IF r_lig_resa.typ_res = '99' THEN
            v_etape := 'conversion si sans resa';
            -- recherche unite de stock et calcul qte reservee en unite stock
            r_lig_resa.unit_stk := su_bas_gcl_su_pro_fonc_unite(
                                      p_cod_pro            => r_lig_resa.cod_pro_res,
                                      p_cod_vl             => r_lig_resa.cod_vl_res,
                                      p_typ_pro_fonc_unite => 'S',
                                      p_colonne            => 'COD_UNITE');

            IF r_lig_resa.unit_stk IS NULL THEN
                r_lig_resa.unit_stk := 'P';
            END IF;

            v_ret := su_bas_conv_unite_to_one(
                                    p_cod_pro     =>r_lig_resa.cod_pro_res,
                                    p_cod_vl      =>r_lig_resa.cod_vl_res,
                                    p_qte_orig    =>r_lig_resa.qte_res,
                                    p_unite_orig  =>r_lig_resa.unit_res,
                                    p_unite_dest  =>r_lig_resa.unit_stk,
                                    p_qte_dest    =>r_lig_resa.qte_res_stk);

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_etape || ' qte_res_stk:' || TO_CHAR(r_lig_resa.qte_res_stk)||' unite: '||r_lig_resa.unit_stk);
            END IF;

        END IF;

        -- Mise a jour du tableau
        vt_list_resa(vi).id_res           := v_id_res;                      -- No de réservation
        vt_list_resa(vi).id_res_porl      := r_lig_resa.id_res_porl;        -- No de résa preordo ligne
        vt_list_resa(vi).typ_res          := pr_pc_rstk.typ_res;            -- Type de reseervation
        vt_list_resa(vi).no_stk           := r_lig_resa.no_stk;             -- No de la fiche stock
        vt_list_resa(vi).qte_res          := r_lig_resa.qte_res;            -- Qte réservé
        vt_list_resa(vi).unite_res        := r_lig_resa.unit_res;           -- unité de resa
        vt_list_resa(vi).qte_res_stk      := r_lig_resa.qte_res_stk;        -- Qte réservé dans l'unité de stock
        vt_list_resa(vi).unite_stk        := r_lig_resa.unit_stk;           -- unité de stock
        vt_list_resa(vi).qte_dis_manu     := 0;                             -- qte distribuée en manuel
        vt_list_resa(vi).qte_dis          := 0;                             -- qte distribuée
        vt_list_resa(vi).cod_pro          := r_lig_resa.cod_pro_res;        -- code produit
        vt_list_resa(vi).cod_vl           := r_lig_resa.cod_vl_res;         -- code vl
        vt_list_resa(vi).cod_va           := r_lig_resa.cod_va_res;         -- code va
        vt_list_resa(vi).cod_ut           := r_lig_resa.cod_ut_stk_res;     -- code ut
        vt_list_resa(vi).typ_ut           := r_lig_resa.typ_ut_stk_res;     -- type ut
        vt_list_resa(vi).cle_distri_res   := v_cle_distri_res;              -- cle de distribution
        vt_list_resa(vi).cod_prk          := r_lig_resa.cod_prk;            -- code prk
        vt_list_resa(vi).cod_lot_stk      := r_lig_resa.cod_lot_stk;        -- code lot_stk
        vt_list_resa(vi).cod_mag_pic      := r_lig_resa.cod_mag_pic;        -- code magasin de picking
        vt_list_resa(vi).cod_pss_final    := v_cod_pss_final;               -- code process final
        vt_list_resa(vi).id_action_prk    := v_id_action_prk;               -- ident sur fiche su_prk_action
        vt_list_resa(vi).list_cod_mag_res := pr_pc_rstk.list_cod_mag_res;   -- liste des magasins de resa final
        vt_list_resa(vi).list_cod_mag_pic := pr_pc_rstk.list_cod_mag_pic;   -- liste des magasins de picking final
        vt_list_resa(vi).r_stk.no_stk     := r_lig_resa.no_stk;             -- Fiche stock (se_stk)
        vt_list_resa(vi).r_stk.cod_usn    := r_lig_resa.cod_usn;            --
        vt_list_resa(vi).r_stk.cod_pro    := r_lig_resa.cod_pro_res;        --
        vt_list_resa(vi).r_stk.cod_va     := r_lig_resa.cod_va_res;         --
        vt_list_resa(vi).r_stk.cod_vl     := r_lig_resa.cod_vl_res;         --
        vt_list_resa(vi).r_stk.cod_prk    := r_lig_resa.cod_prk;            --
        vt_list_resa(vi).r_stk.cod_ut     := r_lig_resa.cod_ut_stk_res;     --
        vt_list_resa(vi).r_stk.typ_ut     := r_lig_resa.typ_ut_stk_res;     --
        vt_list_resa(vi).r_stk.cod_emp    := r_lig_resa.cod_emp;            --
        vt_list_resa(vi).r_stk.cod_mag    := r_lig_resa.cod_mag;            --
        vt_list_resa(vi).r_stk.dat_stk    := r_lig_resa.dat_stk;            --
        vt_list_resa(vi).r_stk.dat_dlc    := r_lig_resa.dat_dlc;            --
        vt_list_resa(vi).r_stk.dat_ent_mag:= r_lig_resa.dat_ent_mag;        --
        vt_list_resa(vi).r_stk.cod_lot_stk:= r_lig_resa.cod_lot_stk;        --
        vt_list_resa(vi).r_stk.cod_ss_lot_stk:= r_lig_resa.cod_ss_lot_stk;  --
        vt_list_resa(vi).r_stk.car_stk_1  := r_lig_resa.car_stk_1;          --
        vt_list_resa(vi).r_stk.car_stk_2  := r_lig_resa.car_stk_2;          --
        vt_list_resa(vi).r_stk.car_stk_3  := r_lig_resa.car_stk_3;          --
        vt_list_resa(vi).r_stk.car_stk_4  := r_lig_resa.car_stk_4;          --
        vt_list_resa(vi).r_stk.car_stk_5  := r_lig_resa.car_stk_5;          --
        vt_list_resa(vi).r_stk.car_stk_6  := r_lig_resa.car_stk_6;          --
        vt_list_resa(vi).r_stk.car_stk_7  := r_lig_resa.car_stk_7;          --
        vt_list_resa(vi).r_stk.car_stk_8  := r_lig_resa.car_stk_8;          --
        vt_list_resa(vi).r_stk.car_stk_9  := r_lig_resa.car_stk_9;          --
        vt_list_resa(vi).r_stk.car_stk_10 := r_lig_resa.car_stk_10;         --
        vt_list_resa(vi).r_stk.car_stk_11 := r_lig_resa.car_stk_11;         --
        vt_list_resa(vi).r_stk.car_stk_12 := r_lig_resa.car_stk_12;         --
        vt_list_resa(vi).r_stk.car_stk_13 := r_lig_resa.car_stk_13;         --
        vt_list_resa(vi).r_stk.car_stk_14 := r_lig_resa.car_stk_14;         --
        vt_list_resa(vi).r_stk.car_stk_15 := r_lig_resa.car_stk_15;         --
        vt_list_resa(vi).r_stk.car_stk_16 := r_lig_resa.car_stk_16;         --
        vt_list_resa(vi).r_stk.car_stk_17 := r_lig_resa.car_stk_17;         --
        vt_list_resa(vi).r_stk.car_stk_18 := r_lig_resa.car_stk_18;         --
        vt_list_resa(vi).r_stk.car_stk_19 := r_lig_resa.car_stk_19;         --
        vt_list_resa(vi).r_stk.car_stk_20 := r_lig_resa.car_stk_20;         --
        vt_list_resa(vi).r_stk.cod_soc_proprio:= r_lig_resa.cod_soc_proprio;-- Fin fiche stock (se_stk)

        vi := vi +1;

    END LOOP;
    CLOSE c_lig_resa;

    -- **********************************
    -- CALCUL DU NB DE COLIS D'EXPEDITION
    -- **********************************

    -- récuperation de la lig_com
    v_etape := 'lecture lig_com';
    r_lig_com := su_bas_grw_pc_lig_com (p_no_com =>p_no_com,
                                        p_no_lig_com =>p_no_lig_com);

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' v_qte_unit_base:' || TO_CHAR(v_qte_unit_base)||' typ_col: '||r_lig_com.typ_col);
    END IF;

    --
    -- si creation de colis à partir de la reservation ...
    -- (la cle 3 de reservation est alors un colis de reference)
    --
    IF pr_pc_rstk.no_uee_ref IS NOT NULL THEN

        v_etape := 'détermine le nb colis d''expedition créés à partir de la résa';
        OPEN c_nb_col_exp;
        FETCH c_nb_col_exp INTO r_nb_col_exp;
        IF c_nb_col_exp%FOUND THEN
            v_nb_colis_exp := r_nb_col_exp.nb_col_exp;
            IF v_nb_colis_exp<=0 THEN
                v_nb_colis_exp:=1;
            END IF;
        ELSE
            RAISE err_except;
        END IF;
        CLOSE c_nb_col_exp;

        IF su_global_pkv.v_niv_dbg >= 3 THEN
           su_bas_put_debug(v_nom_obj || ' ' || v_etape || ' nb_col_exp:' || r_nb_col_exp.nb_col_exp);
        END IF;

    -- Test si colis complet
    ELSIF r_lig_com.typ_col = 'CC' THEN
        -- Conversion de la qte de base dans la VL origine en colis
        v_etape := 'Conversion qte de base qte_unit_base = ' || TO_CHAR(v_qte_unit_base) ||
                    ' dans la VL origine en colis';

        v_qte_ub        := NULL;
        v_qte_ul        := NULL;
        v_qte_col       := NULL;
        v_qte_pds       := NULL;
        v_qte_pce       := NULL;
        v_nb_colis_exp  := NULL;
        v_qte_pal       := NULL;
        v_qte_vol       := NULL;
        v_qte_unit_2    := NULL;
        v_unit_stk_2    := NULL;

        IF NVL(v_qte_unit_base, 0)  > 0 THEN
             v_ret := su_bas_conv_unite_to_all(p_cod_pro=>r_lig_com.cod_pro,   -- code pro origine
                                          p_cod_vl      =>r_lig_com.cod_vl,    -- code VL origine
                                          p_pcb         =>r_lig_com.pcb_exp,   -- pcb de la ligne commande
                                          p_qte_unit_1  =>v_qte_unit_base,
                                          p_unit_stk_1  =>'UB',
                                          p_qte_colis   =>v_qte_col,
                                          p_qte_unit_2  =>v_qte_unit_2,
                                          p_unit_stk_2  =>v_unit_stk_2,
                                          p_qte_ub      =>v_qte_ub,
                                          p_qte_ul      =>v_qte_ul,
                                          p_qte_pds     =>v_qte_pds,
                                          p_qte_pce     =>v_qte_pce,
                                          p_qte_pal     =>v_qte_pal,
                                          p_qte_vol     =>v_qte_vol);

             IF v_ret <> 'OK' THEN
                 v_etape := 'ERREUR de Conversion de la qte de base: '
                       || TO_CHAR(v_qte_unit_base)
                       || ' en VL origine, PRO-VL: '
                       || r_lig_com.cod_pro || '-' || r_lig_com.cod_vl;
                 IF su_global_pkv.v_niv_dbg >= 3 THEN
                     su_bas_put_debug(v_nom_obj || v_etape);
                 END IF;
                 RAISE err_except;
             END IF;

             v_qte_pce := ROUND(v_qte_pce,3); -- arrondir a la 3ème decimale ...

             IF su_global_pkv.v_niv_dbg >= 3 THEN
                 su_bas_put_debug(v_nom_obj || ' v_qte_pce:' || TO_CHAR(v_qte_pce));
                 su_bas_put_debug(v_nom_obj || ' pcb_exp:' || TO_CHAR(r_lig_com.pcb_exp));
             END IF;

             v_etape := 'calcul nb colis exp';
             IF NVL(r_lig_com.pcb_exp,0) > 0 THEN
                 -- nb de colis reel par rapport au pcb de la ligne
                 v_nb_colis_exp := v_qte_pce / r_lig_com.pcb_exp;
             ELSE
                 v_nb_colis_exp := v_qte_col;
             END IF;

             IF NVL(v_nb_colis_exp, 0) <= 0 THEN
                 v_etape := 'conversion colis = 0 - ' || TO_CHAR(v_qte_unit_base) || ' UB en VL origine, PRO-VL: ' ||
                            r_lig_com.cod_pro || '-' || r_lig_com.cod_vl || ' v_qte_pce:' || TO_CHAR(v_qte_pce);
                 IF su_global_pkv.v_niv_dbg >= 3 THEN
                     su_bas_put_debug(v_nom_obj || ' ' || v_etape);
                 END IF;
                 RAISE err_except;
             END IF;

        ELSE
            v_etape := 'Qte dans l''Unité de base <= 0 ou NULL <' || TO_CHAR(v_qte_unit_base) ||
                       '> en VL origine, PRO-VL: ' || r_lig_com.cod_pro || '-' || r_lig_com.cod_vl;
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || ' ' || v_etape);
            END IF;
            RAISE err_except;
        END IF;

        IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj || ' v_nb_colis_exp:' || TO_CHAR(v_nb_colis_exp));
        END IF;

        IF NVL(v_qte_col,0) > 0 AND r_lig_com.pcb_exp IS NOT NULL THEN
            IF r_lig_com.pcb_exp <> ROUND(v_qte_pce / v_qte_col) THEN
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || ' !!! PCB EXP <> PCB de Config !!! ' || TO_CHAR(r_lig_com.pcb_exp) || ' <> ' ||
                                     TO_CHAR(ROUND(v_qte_pce / v_qte_col)));
                END IF;
            END IF;
        END IF;

        -- ----------------------------------
        -- Test s'il y a un reliquat de colis
        -- ----------------------------------
        IF MOD(v_nb_colis_exp, 1) > 0 THEN
            -- ---------------------------------------------
            -- On doit libérer le stock en trop
            -- Cela correspond au bout de colis d'expédition
            -- ---------------------------------------------
            v_etape := 'calc qte reliquat';
            IF NVL(r_lig_com.pcb_exp,0) > 0 THEN
                v_qte_reliquat      := ROUND(MOD(v_nb_colis_exp, 1) * r_lig_com.pcb_exp);  -- en pièce ... entiere
                v_unite_reliquat    := 'P';
            ELSE
                v_qte_reliquat      := MOD(v_nb_colis_exp, 1);  -- en colis ...
                v_unite_reliquat    := 'C';
            END IF;

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || ' v_qte_reliquat:' || TO_CHAR(v_qte_reliquat) || ' ' || v_unite_reliquat);
            END IF;

            v_qte_ub            := NULL;
            v_qte_ul            := NULL;
            v_qte_pds           := NULL;
            v_qte_pce           := NULL;
            v_nb_colis_exp_ann  := NULL;
            v_qte_pal           := NULL;
            v_qte_vol           := NULL;
            v_qte_unit_2        := NULL;
            v_unit_stk_2        := NULL;

            v_etape :=  'Conversion de la réservation id_res: ' || v_id_res ||
                        ' No_lig_rstk : ' || TO_CHAR(r_lig_resa.no_lig_rstk);
            v_ret := su_bas_conv_unite_to_one ( p_cod_pro      =>r_lig_com.cod_pro,   -- code pro origine
                                                p_cod_vl       =>r_lig_com.cod_vl,    -- code VL origine
                                                p_qte_orig     =>v_qte_reliquat,
                                                p_unite_orig   =>v_unite_reliquat,
                                                p_unite_dest   =>r_lig_resa.unit_res_dem,
                                                p_qte_dest     =>v_qte_a_dereserver);
            IF v_ret <> 'OK' THEN
                v_etape := 'Problème sur conversion de v_qte_reliquat: '
                             || TO_CHAR(v_qte_reliquat) || ' ' || v_unite_reliquat || ' en unite de resa '
                             || r_lig_resa.unit_res_dem || ' Produit:'
                             || r_lig_com.cod_pro || '-' || r_lig_com.cod_vl;
                v_niv_ano:= 2;
                RAISE err_except;
            END IF;

            IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj || ' v_qte_a_deres:' || TO_CHAR(v_qte_a_dereserver) || ' ' || r_lig_resa.unit_res_dem);
            END IF;

            v_etape := 'Libère rstk ferme sur SE';
            v_ret := se_bas_libere_rstk (p_no_rstk      => v_id_res,
                                         p_qte_libere   => v_qte_a_dereserver,
                                         p_delete       => TRUE,
                                         p_cod_pro      => r_lig_com.cod_pro,
                                         p_cod_vl       => r_lig_com.cod_vl,
                                         p_cod_va       => r_lig_com.cod_va);

            IF v_ret <> 'OK' THEN
                v_etape := 'Problème sur liberation stock ferme sur SE NO_RSTK: ' || v_id_res;
                v_niv_ano:= 2;
                RAISE err_except;
            END IF;

            v_etape := 'Libère rstk ferme sur PC';
            v_ret := pc_bas_libere_rstk (p_id_res       => v_id_res,
                                         p_qte_libere   => v_qte_a_dereserver);
            IF v_ret <> 'OK' THEN
                v_niv_ano:= 2;
                v_etape := 'Problème sur liberation stock ferme sur PC ID_RES: ' || v_id_res;
                RAISE err_except;
            END IF;

            -- puisque l'on a dereserve la partie decimale ...
            -- on conserve le nombre de colis entier ...
            v_nb_colis_exp := TRUNC(v_nb_colis_exp);

        END IF;

    ELSE
        v_nb_colis_exp := 1;    -- Force à 1 pour les colis Détail
    END IF;

    -- ------------------------------------------------------
    -- Appel pour distribution sur le nombre de colis calculé
    -- ------------------------------------------------------
    IF v_nb_colis_exp > 0 THEN
        v_etape := 'Appel de pc_bas_maj_resa_uee';
        -- Appel de la fonction mise a jour des resas sur PC_UEE_DET et PC_UEE
        v_ret := pc_bas_maj_resa_uee (p_cod_usn           =>p_cod_usn,
                                      p_no_com            =>p_no_com,
                                      p_no_lig_com        =>p_no_lig_com,
                                      p_cod_up            =>pr_pc_rstk.ref_rstk_4,
                                      p_typ_up            =>pr_pc_rstk.ref_rstk_5,
                                      p_no_uee            =>pr_pc_rstk.ref_rstk_3,
                                      --p_cod_pss_afc       =>pr_pc_rstk.cod_pss_afc,
                                      p_cod_pss_afc       =>NVL(v_cod_pss_final,pr_pc_rstk.cod_pss_afc),
                                      p_cod_pss_demandeur =>pr_pc_rstk.cod_pss_demandeur,
                                      p_cod_verrou        =>p_cod_verrou,
                                      p_crea_plan         =>p_crea_plan,
                                      p_nb_colis_exp      =>v_nb_colis_exp,
                                      p_id_res            =>v_id_res,
                                      pt_list_resa        =>vt_list_resa,
                                      p_mode_dis          =>p_mode_dis
                                     );
        IF v_ret <> 'OK' THEN
           RAISE err_except;
        END IF;
    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        IF c_lig_resa%ISOPEN THEN
            CLOSE c_lig_resa;
        END IF;
        -- On doit rollbacker
        ROLLBACK TO my_sp_pc_distri_id_res;


        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Id_res',
                        p_par_ano_1       => pr_pc_rstk.id_res,
                        p_lib_ano_2       => 'No_com',
                        p_par_ano_2       => p_no_com,
                        p_lib_ano_3       => 'No_lig_com',
                        p_par_ano_3       => p_no_lig_com,
                        p_lib_ano_4       => 'uee',
                        p_par_ano_4       => pr_pc_rstk.ref_rstk_3,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);


        RETURN 'ERROR';
END;


/****************************************************************************
*   pc_bas_crea_pic -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction realise la creation des ordres de picking.
--
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03d,10.10.13,alfl    recuperer le cod_cnt de l'UEE en CC et si cl CNT_PIC='$EXP'
-- 03c,03.08.11,mnev    Ajout cod_emp dans curseur c_pic.
--                      Mode Cal Unite Pic = 'C' => conversion en unité
--                      de stock du magasin de picking pour l'article commandé
--                      Ajout d'un savepoint
-- 03b,01.07.11,rleb    Création du picking en fonction de la clé "mode_cal_unite_pic"
-- 03a,16.05.11,mnev    Mise a jour nouvelles colonnes cod_abc_ emp et pro
-- 02f,03.12.10,alfl    on prend le max des dlc_max.
-- 02e,03.07.09,mnev    Ajout de NVL sur curseur de regroupement.
--                      RAZ des clefs non gérées dans la variante de resa.
-- 02d,12.03.09,mnev    Correction quand on agrège les ordres de picking
--                      - corrige erreur sur qte_a_pic
--                      - ajout qte_a_pic_2
-- 02c,09.03.09,mnev    Correction sur le test du cod_prk (ajout du NVL)
--                      Prise en compte de la config dans variante res pour :
--                      . cod_prk
--                      . cod_va
--                      . cod_vl
-- 02b,03.02.09,mnev    Corrige (gros) bug sur c_pic
--                      (melange de typ_ut et cod_ut).
-- 02a,15.12.08,mnev    Ajout colonne mode_val_ops dans pc_pic
-- 01d,21.11.08,mnev    Correction sur cle carac 1 à 20 lors de
--                      l'insertion de l'ordre de picking.
-- 01c,29.07.08,alfl    gestion de la priorite de l'ordre de picking
-- 01b,08.08.07,mnev    gestion des charges de preparation
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
-- p_no_com      : no de commande
-- p_no_lig      : no de lig_commande
--
--
-- RETOUR :
-- --------
-- OK ou ERROR
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_crea_pic (p_no_com             pc_lig_com.no_com%TYPE,
                          p_no_lig_com         pc_lig_com.no_lig_com%TYPE,
                          p_no_uee             pc_uee.no_uee%TYPE,
                          p_typ_uee            pc_uee.typ_uee%TYPE,
                          pr_stk               se_stk%ROWTYPE,
                          p_cod_pss_afc        su_pss.cod_pss%TYPE,
                          p_cod_verrou         VARCHAR2,
                          p_qte_a_pic          NUMBER,
                          p_unite_pic          VARCHAR2,
                          p_qte_a_pic_2        NUMBER,
                          p_unite_pic_2        VARCHAR2,
                          p_cod_mag_pic        se_stk.cod_mag%TYPE,
                          p_chg_prp            pc_pic.chg_prp%TYPE
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03d $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_crea_pic:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclarations de variables
    -- -------------------------
    v_cle_pic               pc_pic.cle_pic%TYPE;
    v_cod_vr                pc_vr.cod_vr%TYPE;
    v_mode_pic              pc_pic.mode_pic%TYPE;
    v_rgp                   VARCHAR2(5) := '0';   -- '0' ou '1' (regroupement posssible) si '1'
    v_mode                  VARCHAR2(10);
    v_cod_pic               pc_pic.cod_pic%TYPE;
    v_cod_cnt_pic           su_ul.cod_cnt_stk%TYPE;
    v_cnt_pss_pic           su_ul.cod_cnt_stk%TYPE;
    v_etat_atv_pic          pc_pic.etat_atv_pc_pic%TYPE;

    v_cod_asv               pc_pic.cod_asv%TYPE;
    v_cod_trf_pic           pc_pic.cod_trf_pic%TYPE;
    v_mode_rgp_asv          pc_pic.mode_rgp_asv%TYPE;
    v_mode_asv_pic          pc_pic.mode_asv_pic%TYPE;
    v_mode_rgp_ops          pc_pic.mode_rgp_ops%TYPE;
    v_mode_val_ops          pc_pic.mode_val_ops%TYPE;
    v_mode_trf_ops_pos_pic  pc_pic.mode_trf_ops_pos_pic%TYPE;
    v_mode_rch_pos_pic      pc_pic.mode_rch_pos_pic%TYPE;
    v_trf_otr_aut_val       pc_pic.trf_otr_aut_val%TYPE;
    v_trf_pos_prp_val_pic   pc_pic.trf_pos_prp_val_pic%TYPE;
    v_cc_cle_otr            pc_pic.cc_cle_otr%TYPE;
    v_cc_cod_trf            pc_pic.cc_cod_trf%TYPE;
    v_autor_suspension      pc_pic.autor_suspension%TYPE;
    v_typ_otr               pc_pic.typ_otr%TYPE;
    v_cod_emp               se_stk.cod_emp%TYPE;
    v_no_pos_lct            pc_pic.no_pos_lct%TYPE;
    v_cod_pro_pic           pc_pic.cod_pro%TYPE;
    v_cod_va_pic            pc_pic.cod_va%TYPE;
    v_cod_vl_pic            pc_pic.cod_vl%TYPE;
    v_unite_cible           VARCHAR2(10):=NULL;
    v_unite_pic             VARCHAR2(10):=p_unite_pic;
    v_qte_a_pic             NUMBER:=p_qte_a_pic;
    v_qte_a_pic_ub          NUMBER;

    vr_stk                  se_stk%ROWTYPE := pr_stk;
    v_elm                   VARCHAR2(50) := NULL;

    --Contexte
    v_ctx               su_ctx_pkg.tt_ctx;

    -- Tableau de clefs de réservation
    vt_list_cle_res           pc_ordo_pkg.tt_lst_cle_res;

    -- Déclarations de curseurs
    ---------------------------
    -- Recherche d'un ORDRE DE PICKING (Cas d'une scission sur 2 lots ou 2 DLCs lors
    -- de la réservation pour 1 même colis UEE, (dépend de la variante de réservation)
    -- OU Cas de Regroupement si picking d'1 colis stock pour n colis d'exped). (voir x_rgp)
    CURSOR c_pic (x_no_com         pc_pic_uee.no_com%TYPE,
                  x_no_lig_com     pc_pic_uee.no_lig_com%TYPE,
                  x_no_uee         pc_pic_uee.no_uee%TYPE,
                  x_cod_pss_afc    pc_pic.cod_pss_afc%TYPE,
                  x_rgp            VARCHAR2,
                  x_unite_qte      pc_pic.unite_qte%TYPE,
                  x_unite_qte_2    pc_pic.unite_qte_2%TYPE,
                  x_etat_atv_pic   pc_pic.etat_atv_pc_pic%TYPE,
                  x_cod_emp        pc_pic.cod_emp%TYPE)   IS
        SELECT pic.cod_pic, pic.rowid rowid_pic
        FROM pc_pic pic, pc_pic_uee pu
        WHERE pic.cod_pic        = pu.cod_pic               AND
              pu.no_com          = x_no_com                 AND
              pu.no_lig_com      = x_no_lig_com             AND
              pic.cod_pss_afc    = x_cod_pss_afc            AND
              (pu.no_uee         = x_no_uee OR x_rgp = '1') AND
              (x_rgp = '0'                  OR
                (x_rgp = '1'         AND
                 pic.unite_qte = 'C' AND
                 MOD(pic.qte_a_pic, 1) <> 0 )
              )                                             AND
              pic.unite_qte      = x_unite_qte              AND
              pic.unite_qte_2    = x_unite_qte_2            AND
              pic.etat_atv_pc_pic = x_etat_atv_pic          AND
              pic.cod_pro        = vr_stk.cod_pro           AND
             (pic.cod_vl         = vr_stk.cod_vl OR vt_list_cle_res('COD_VL').etat_obl = '0') AND
             (pic.cod_va         = vr_stk.cod_va OR vt_list_cle_res('COD_VA').etat_obl = '0') AND
             (NVL(pic.cod_prk,'0') = NVL(vr_stk.cod_prk,'0') OR vt_list_cle_res('COD_PRK').etat_obl = '0')  AND
              pic.cod_mag        = p_cod_mag_pic            AND
              NVL(pic.cod_emp,'#NULL#') = NVL(x_cod_emp,'#NULL#') AND
              pic.cod_usn        = vr_stk.cod_usn           AND
             (NVL(pic.cod_ut_stk,'#NULL#')     = NVL(vr_stk.cod_ut,'#NULL#') OR vt_list_cle_res('COD_UT').etat_obl = '0') AND
             (NVL(pic.typ_ut_stk,'#NULL#')     = NVL(vr_stk.typ_ut,'#NULL#') OR vt_list_cle_res('TYP_UT').etat_obl = '0') AND
             (NVL(pic.cod_lot_stk,'#NULL#')    = NVL(vr_stk.cod_lot_stk,'#NULL#') OR vt_list_cle_res('COD_LOT_STK').etat_obl = '0') AND
             (NVL(pic.cod_ss_lot_stk,'#NULL#') = NVL(vr_stk.cod_ss_lot_stk,'#NULL#') OR vt_list_cle_res('COD_SS_LOT_STK').etat_obl = '0') AND
             (pic.dat_dlc = vr_stk.dat_dlc OR vt_list_cle_res('DAT_DLC').etat_obl = '0') AND
             (pic.dat_stk = vr_stk.dat_stk OR vt_list_cle_res('DAT_STK').etat_obl = '0') AND
             (NVL(pic.cod_soc_proprio,'#NULL#')= NVL(vr_stk.cod_soc_proprio,'#NULL#') OR vt_list_cle_res('COD_SOC_PROPRIO').etat_obl = '0') AND
             (NVL(pic.car_stk_1,'#NULL#')  = NVL(vr_stk.car_stk_1,'#NULL#')  OR vt_list_cle_res('CAR_STK_1').etat_obl = '0') AND
             (NVL(pic.car_stk_2,'#NULL#')  = NVL(vr_stk.car_stk_2,'#NULL#')  OR vt_list_cle_res('CAR_STK_2').etat_obl = '0') AND
             (NVL(pic.car_stk_3,'#NULL#')  = NVL(vr_stk.car_stk_3,'#NULL#')  OR vt_list_cle_res('CAR_STK_3').etat_obl = '0') AND
             (NVL(pic.car_stk_4,'#NULL#')  = NVL(vr_stk.car_stk_4,'#NULL#')  OR vt_list_cle_res('CAR_STK_4').etat_obl = '0') AND
             (NVL(pic.car_stk_5,'#NULL#')  = NVL(vr_stk.car_stk_5,'#NULL#')  OR vt_list_cle_res('CAR_STK_5').etat_obl = '0') AND
             (NVL(pic.car_stk_6,'#NULL#')  = NVL(vr_stk.car_stk_6,'#NULL#')  OR vt_list_cle_res('CAR_STK_6').etat_obl = '0') AND
             (NVL(pic.car_stk_7,'#NULL#')  = NVL(vr_stk.car_stk_7,'#NULL#')  OR vt_list_cle_res('CAR_STK_7').etat_obl = '0') AND
             (NVL(pic.car_stk_8,'#NULL#')  = NVL(vr_stk.car_stk_8,'#NULL#')  OR vt_list_cle_res('CAR_STK_8').etat_obl = '0') AND
             (NVL(pic.car_stk_9,'#NULL#')  = NVL(vr_stk.car_stk_9,'#NULL#')  OR vt_list_cle_res('CAR_STK_9').etat_obl = '0') AND
             (NVL(pic.car_stk_10,'#NULL#') = NVL(vr_stk.car_stk_10,'#NULL#') OR vt_list_cle_res('CAR_STK_10').etat_obl = '0') AND
             (NVL(pic.car_stk_11,'#NULL#') = NVL(vr_stk.car_stk_11,'#NULL#') OR vt_list_cle_res('CAR_STK_11').etat_obl = '0') AND
             (NVL(pic.car_stk_12,'#NULL#') = NVL(vr_stk.car_stk_12,'#NULL#') OR vt_list_cle_res('CAR_STK_12').etat_obl = '0') AND
             (NVL(pic.car_stk_13,'#NULL#') = NVL(vr_stk.car_stk_13,'#NULL#') OR vt_list_cle_res('CAR_STK_13').etat_obl = '0') AND
             (NVL(pic.car_stk_14,'#NULL#') = NVL(vr_stk.car_stk_14,'#NULL#') OR vt_list_cle_res('CAR_STK_14').etat_obl = '0') AND
             (NVL(pic.car_stk_15,'#NULL#') = NVL(vr_stk.car_stk_15,'#NULL#') OR vt_list_cle_res('CAR_STK_15').etat_obl = '0') AND
             (NVL(pic.car_stk_16,'#NULL#') = NVL(vr_stk.car_stk_16,'#NULL#') OR vt_list_cle_res('CAR_STK_16').etat_obl = '0') AND
             (NVL(pic.car_stk_17,'#NULL#') = NVL(vr_stk.car_stk_17,'#NULL#') OR vt_list_cle_res('CAR_STK_17').etat_obl = '0') AND
             (NVL(pic.car_stk_18,'#NULL#') = NVL(vr_stk.car_stk_18,'#NULL#') OR vt_list_cle_res('CAR_STK_18').etat_obl = '0') AND
             (NVL(pic.car_stk_19,'#NULL#') = NVL(vr_stk.car_stk_19,'#NULL#') OR vt_list_cle_res('CAR_STK_19').etat_obl = '0') AND
             (NVL(pic.car_stk_20,'#NULL#') = NVL(vr_stk.car_stk_20,'#NULL#') OR vt_list_cle_res('CAR_STK_20').etat_obl = '0');

    r_pic           c_pic%ROWTYPE;
    found_pic       BOOLEAN;

    -- Recherche PIC_UEE
    CURSOR c_pic_uee (x_no_uee      pc_pic_uee.no_uee%TYPE,
                      x_cod_pic     pc_pic_uee.cod_pic%TYPE,
                      x_no_com      pc_pic_uee.no_com%TYPE,
                      x_no_lig_com  pc_pic_uee.no_lig_com%TYPE) IS
       SELECT cod_asv, cod_trf_pic
       FROM pc_pic_uee pu
       WHERE pu.no_uee      = x_no_uee                          AND
             (pu.cod_pic    = x_cod_pic OR x_cod_pic IS NULL)   AND
             (pu.no_com     = x_no_com  OR x_no_com IS NULL)    AND
             (pu.no_lig_com = x_no_lig_com OR x_no_lig_com IS NULL);

    r_pic_uee        c_pic_uee%ROWTYPE;
    found_pic_uee    BOOLEAN;

    -- record colis
    r_uee              pc_uee%ROWTYPE;

    -- lecture dates liees a la commande
    CURSOR c_prp (x_no_com     pc_ent_com.no_com%TYPE,
                  x_no_lig_com pc_lig_com.no_lig_com%TYPE) IS
        SELECT e.dat_prep,
               l.dlc_min, l.dlc_max, l.niv_prio,
               l.cod_pro, l.cod_vl, l.cod_va, l.unite_cde
        FROM pc_ent_com e, pc_lig_com l
        WHERE l.no_com = x_no_com AND l.no_lig_com = x_no_lig_com AND
              l.no_com = e.no_com;

    r_prp   c_prp%ROWTYPE;

    v_no_seq    NUMBER;
    v_add_ctx   BOOLEAN;

    v_cod_abc_emp        se_emp.cod_abc%TYPE := NULL;
    v_cod_abc_pro        su_pro.cod_abc%TYPE := NULL;
    v_mode_cal_unite_pic VARCHAR2(20);

BEGIN

    SAVEPOINT my_pc_bas_crea_pic_sp;

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' LigCom: ' || p_no_com || '-' || p_no_lig_com);
        su_bas_put_debug(v_nom_obj || ' UEE:' || p_no_uee || ' Type:' || p_typ_uee);
        su_bas_put_debug(v_nom_obj || ' MagPic:' || p_cod_mag_pic || ' PSS:' || p_cod_pss_afc);
    END IF;

    v_ctx.DELETE;

    -- Recherche du mode de calcul de l'unité de picking
    v_etape := 'rch mode_cal_unite_pic';
    v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss => p_cod_pss_afc,
                                  p_typ_atv => 'PIC',
                                  p_cod_cfg => 'MODE_CAL_UNITE_PIC',
                                  p_val     => v_mode_cal_unite_pic);
    IF v_ret <> 'OK' THEN
        v_etape := 'Erreur lors du mode de calcul de l''unité de picking';
        v_cod_err_su_ano := 'PC-ORDO016';
        RAISE err_except;
    END IF;

    -- Recherche de la valeur de la clef 'COD_VR'
    v_etape := 'rch cle COD_VR';
    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,
                                    'ORD', -- type activité
                                    'COD_VR',
                                     v_cod_vr);
    -- Recherche des clefs de la variante de réservation
    v_etape := 'calcul liste cle res';
    v_ret := pc_bas_calcul_lst_cle_res (v_cod_vr, vt_list_cle_res);

    v_etape := 'maj liste_cle res';
    v_elm := vt_list_cle_res.FIRST;
    WHILE v_elm IS NOT NULL LOOP
        IF vt_list_cle_res(v_elm).etat_obl = '0' THEN
            IF v_elm = 'COD_VA' THEN
                vr_stk.cod_va := NULL;
            ELSIF v_elm = 'COD_VL' THEN
                vr_stk.cod_vl := NULL;
            ELSIF v_elm = 'COD_PRK' THEN
                vr_stk.cod_prk := NULL;
            ELSIF v_elm = 'COD_UT' THEN
                vr_stk.cod_ut := NULL;
            ELSIF v_elm = 'TYP_UT' THEN
                vr_stk.typ_ut := NULL;
            ELSIF v_elm = 'COD_LOT_STK' THEN
                vr_stk.cod_lot_stk := NULL;
            ELSIF v_elm = 'COD_SS_LOT_STK' THEN
                vr_stk.cod_ss_lot_stk := NULL;
            ELSIF v_elm = 'DAT_DLC' THEN
                vr_stk.dat_dlc := NULL;
            ELSIF v_elm = 'DAT_STK' THEN
                vr_stk.dat_stk := NULL;
            ELSIF v_elm = 'COD_SOC_PROPRIO' THEN
                vr_stk.cod_soc_proprio := NULL;
            ELSIF v_elm = 'CAR_STK_1' THEN
                vr_stk.car_stk_1 := NULL;
            ELSIF v_elm = 'CAR_STK_2' THEN
                vr_stk.car_stk_2 := NULL;
            ELSIF v_elm = 'CAR_STK_3' THEN
                vr_stk.car_stk_3 := NULL;
            ELSIF v_elm = 'CAR_STK_4' THEN
                vr_stk.car_stk_4 := NULL;
            ELSIF v_elm = 'CAR_STK_5' THEN
                vr_stk.car_stk_5 := NULL;
            ELSIF v_elm = 'CAR_STK_6' THEN
                vr_stk.car_stk_6 := NULL;
            ELSIF v_elm = 'CAR_STK_7' THEN
                vr_stk.car_stk_7 := NULL;
            ELSIF v_elm = 'CAR_STK_8' THEN
                vr_stk.car_stk_8 := NULL;
            ELSIF v_elm = 'CAR_STK_9' THEN
                vr_stk.car_stk_9 := NULL;
            ELSIF v_elm = 'CAR_STK_10' THEN
                vr_stk.car_stk_10 := NULL;
            ELSIF v_elm = 'CAR_STK_11' THEN
                vr_stk.car_stk_11 := NULL;
            ELSIF v_elm = 'CAR_STK_12' THEN
                vr_stk.car_stk_12 := NULL;
            ELSIF v_elm = 'CAR_STK_13' THEN
                vr_stk.car_stk_13 := NULL;
            ELSIF v_elm = 'CAR_STK_14' THEN
                vr_stk.car_stk_14 := NULL;
            ELSIF v_elm = 'CAR_STK_15' THEN
                vr_stk.car_stk_15 := NULL;
            ELSIF v_elm = 'CAR_STK_16' THEN
                vr_stk.car_stk_16 := NULL;
            ELSIF v_elm = 'CAR_STK_17' THEN
                vr_stk.car_stk_17 := NULL;
            ELSIF v_elm = 'CAR_STK_18' THEN
                vr_stk.car_stk_18 := NULL;
            ELSIF v_elm = 'CAR_STK_19' THEN
                vr_stk.car_stk_19 := NULL;
            ELSIF v_elm = 'CAR_STK_20' THEN
                vr_stk.car_stk_20 := NULL;
            END IF;
        END IF;
        v_elm := vt_list_cle_res.NEXT(v_elm);
    END LOOP;

    -- Test si la quantité a picker est en colis et dont la quantité n'est pas modulo 1 ,
    -- (ex 0,5 colis)
    -- Dans ce cas, on essaie de rattacher cette Qte a picker
    -- sur un ordre existant dont la Qte n'est pas modulo de l'unité de picking (colis)
    v_rgp := '0';
    IF p_unite_pic = 'C' AND MOD(p_qte_a_pic, 1) <> 0 THEN
       v_rgp := '1';
    END IF;

    v_etat_atv_pic := su_bas_rch_etat_atv('CREATION','PC_PIC');

    -- Récupère le row du colis
    r_uee := su_bas_grw_pc_uee (p_no_uee);

    -- Récupère les dates et la priorite
    v_etape := 'rch info cde';
    OPEN c_prp (p_no_com, p_no_lig_com);
    FETCH c_prp INTO r_prp;
    CLOSE c_prp;
    --
    -- Test si égalité entre magasin de résa et magasin de picking
    -- Si OUI, le code emp est bon,  si NON forcé le code emp à NULL
    -- Il sera recalculer par l'affectation (si NULL)
    --
    v_etape := 'cal emplacement';
    IF pr_stk.cod_mag = NVL(p_cod_mag_pic, '$') THEN
       v_cod_emp := vr_stk.cod_emp;
       v_cod_abc_emp := su_bas_gcl_se_emp (v_cod_emp, 'COD_ABC');
    ELSE
       v_cod_emp := NULL;
       v_cod_abc_emp := NULL;
    END IF;
    --
    -- Recherche si ordre de picking compatible
    --
    v_etape := 'Rch PIC';
    OPEN c_pic (p_no_com, p_no_lig_com, p_no_uee, p_cod_pss_afc, v_rgp, p_unite_pic, p_unite_pic_2, v_etat_atv_pic, v_cod_emp);
    FETCH c_pic INTO r_pic;
    found_pic := c_pic%FOUND;
    CLOSE c_pic;

    IF found_pic THEN
        -- --------------------------
        -- Ajout sur un PIC existant.
        -- --------------------------
        v_etape := 'Modification d'' PIC existant cod_pic: ' || r_pic.cod_pic;
        v_mode := 'OLD';
        UPDATE pc_pic pic SET
              pic.qte_a_pic   = pic.qte_a_pic + p_qte_a_pic,
              pic.qte_a_pic_2 = pic.qte_a_pic_2 + p_qte_a_pic_2,
              pic.chg_prp     = pic.chg_prp + p_chg_prp
        WHERE pic.rowid = r_pic.rowid_pic;

        v_cod_pic := r_pic.cod_pic;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' *** Ajout sur ordre pic : ' || v_cod_pic);
        END IF;


    ELSE
        -- --------------------------------------------------
        -- Si pas trouve de PIC compatible ou pas trouve la VS
        -- Creation d'un nouvel orde de picking PIC
        -- --------------------------------------------------
        -- calcul de la cle de picking
        pc_bas_calcul_cle_pic (vr_stk, p_cod_mag_pic, v_cle_pic);

        -- Recherche les différentes clefs nécessaire a la construction de PC_PIC
        -- dans l'activité PIC
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','MODE_PIC', v_mode_pic);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','MODE_RGP_ASV', v_mode_rgp_asv);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','MODE_ASV_PIC', v_mode_asv_pic);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','MODE_RGP_OPS', v_mode_rgp_ops);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','MODE_VAL_OPS', v_mode_val_ops);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','MODE_TRF_OPS_POS_PIC', v_mode_trf_ops_pos_pic);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','MODE_RCH_POS_PIC', v_mode_rch_pos_pic);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','TRF_OTR_AUT_VAL', v_trf_otr_aut_val);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','TRF_POS_PRP_VAL_PIC', v_trf_pos_prp_val_pic);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','CC_CLE_OTR', v_cc_cle_otr);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','CC_COD_TRF', v_cc_cod_trf);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','AUTOR_SUSPENSION', v_autor_suspension);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','TYP_OTR', v_typ_otr);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','CNT_PIC', v_cnt_pss_pic);
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss_afc,'PIC','NO_POS_LCT', v_no_pos_lct);

        -- Recherche de l'état d'activité de PC_PIC
        v_etat_atv_pic := su_bas_rch_etat_atv('CREATION','PC_PIC');

         -- Génération du cod_pic
        v_etape := 'Génération du cod_pic';
        v_cod_pic := su_bas_seq_nextval ('SEQ_PC_PIC');

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' *** Nouvel ordre pic : ' || v_cod_pic);
        END IF;

        -- calcul des champs cod_asv et cod_trf_pic
        -- Recherche s'il existe une fiche dans pic_UEE pour le même colis UEE
        -- SI OUI alors
        --    si colis typ_uee = 'CD' alors
        --      on prend cod_asv et cod_trf_pic de la fiche
        --    si colis typ_uee = 'CC' alors
        --    on prend cod_asv de la fiche  et une nouvelle seq pour cod_trf_pic
        -- SI NON, on crée 2 nouvelles séquences

        v_etape := 'open c_pic_uee';
        OPEN c_pic_uee (p_no_uee, NULL, NULL, NULL);
        FETCH c_pic_uee INTO r_pic_uee;
        found_pic_uee := c_pic_uee%FOUND;
        CLOSE c_pic_uee;

        IF found_pic_uee THEN

            IF p_typ_uee = 'CD' THEN
                v_etape := 'constitution code de transfert (CD)';
                v_cod_asv     := r_pic_uee.cod_asv;
                v_cod_trf_pic := r_pic_uee.cod_trf_pic;
                v_ret         := 'OK';

            ELSE -- 'CC'
                v_etape := 'constitution code de transfert (CC)';
                v_cod_asv := r_pic_uee.cod_asv;

                -- constitution du champs cod_trf_pic
                IF v_cc_cod_trf IS NOT NULL THEN
                    v_etape := 'positionnement contexte';
                    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_USN', r_uee.cod_usn);
                    v_etape := 'make cc';
                    v_ret     := su_cc_pkg.su_bas_make_cc (v_cc_cod_trf, v_ctx, v_cod_trf_pic);
                ELSE
                    v_etape := 'lecture seq_cod_trf_pic';
                    SELECT seq_cod_trf_pic.NEXTVAL INTO v_no_seq FROM DUAL;
                    v_cod_trf_pic := r_uee.cod_usn || v_no_seq;
                END IF;
            END IF;

        ELSE

            v_etape := 'constitution code de transfert';
            v_cod_asv     := su_bas_seq_nextval ('SEQ_COD_ASV');

            -- constitution du champs cod_trf_pic
            IF v_cc_cod_trf IS NOT NULL THEN
                v_etape := 'positionnement contexte';
                v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_USN', r_uee.cod_usn);
                v_etape := 'make cc';
                v_ret     := su_cc_pkg.su_bas_make_cc (v_cc_cod_trf, v_ctx, v_cod_trf_pic);
            ELSE
                v_etape := 'lecture seq_cod_trf_pic';
                SELECT seq_cod_trf_pic.NEXTVAL INTO v_no_seq FROM DUAL;
                v_cod_trf_pic := r_uee.cod_usn || v_no_seq;
            END IF;

        END IF;

        IF v_ret <> 'OK' THEN
            RAISE err_except;
        END IF;

        v_etape := 'rch cnt pic';
        -- Recherche du contenant de stock
        IF p_typ_uee = 'CD' THEN
            IF v_cnt_pss_pic = '$EXP' OR v_cnt_pss_pic = '$STK' THEN
                -- C'est le contenant du colis d'expédition
                v_cod_cnt_pic := r_uee.cod_cnt;
            ELSE
                -- Le contenant est forcé par la clef de process
                v_cod_cnt_pic := v_cnt_pss_pic;
            END IF;
        ELSE
            IF v_cnt_pss_pic = '$STK' THEN
                -- Recherche du contenant de stock
                v_cod_cnt_pic := su_bas_gcl_su_ul(pr_stk.cod_pro, pr_stk.cod_vl, 'COD_CNT_STK');

            ELSIF v_cnt_pss_pic = '$EXP' THEN
                -- C'est le contenant du colis d'expédition
                v_cod_cnt_pic := r_uee.cod_cnt;
            ELSE
                -- Le contenant est forcé par la clef de process
                v_cod_cnt_pic := v_cnt_pss_pic;
            END IF;
        END IF;

        --
        -- determiner l'article de prélèvement et la qte associée
        --
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' v_cod_cnt_pic:' || v_cod_cnt_pic);
            su_bas_put_debug(v_nom_obj || ' mode_cal_unite_pic:' || v_mode_cal_unite_pic);
        END IF;

        v_etape := 'calcul VL + UNITE pic';
        IF NVL(v_mode_cal_unite_pic,'S') = 'S' THEN
            -- Picking sur article de stock
            v_cod_pro_pic:=vr_stk.cod_pro;
            v_cod_va_pic :=vr_stk.cod_va;
            v_cod_vl_pic :=vr_stk.cod_vl;

        ELSIF NVL(v_mode_cal_unite_pic,'S') = 'C' THEN
            -- Picking sur article commandé
            v_cod_pro_pic:=r_prp.cod_pro;
            v_cod_va_pic :=r_prp.cod_va;
            v_cod_vl_pic :=r_prp.cod_vl;

            -- rechercher l'unite de l'article commandé dans le magasin de picking
            v_etape := 'rch unite pic';
            v_unite_cible := se_bas_rch_unit_stk (p_cod_pro => v_cod_pro_pic,
                                                  p_cod_va  => v_cod_va_pic,
                                                  p_cod_vl  => v_cod_vl_pic,
                                                  p_cod_mag => p_cod_mag_pic);
            IF v_unite_cible IS NULL THEN
                RAISE err_except;
            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || ' v_unite_cible:' || v_unite_cible);
            END IF;

            -- SI article réellement reservé <> article commandé ALORS
            -- faire une conversion
            IF v_cod_pro_pic <> pr_stk.cod_pro OR v_cod_va_pic  <> pr_stk.cod_va OR
               v_cod_vl_pic  <> pr_stk.cod_vl OR v_unite_pic <> v_unite_cible THEN

                -- traduire la qte initiale en UB
                v_etape:='convertir la qte du produit réservé en UB';
                v_ret := su_bas_conv_unite_to_one ( p_cod_pro      =>pr_stk.cod_pro,
                                                    p_cod_vl       =>pr_stk.cod_vl,
                                                    p_qte_orig     =>v_qte_a_pic,
                                                    p_unite_orig   =>v_unite_pic,
                                                    p_unite_dest   =>'UB',
                                                    p_qte_dest     =>v_qte_a_pic_ub);
                IF v_ret <> 'OK' THEN
                    RAISE err_except;
                END IF;

                --
                -- On impose que les UB de base de l'article réservé
                -- sont équivalentes à celles de l'article commandé
                --
                v_etape:='convertir les UB en article commandé et unité picking';
                v_ret := su_bas_conv_unite_to_one ( p_cod_pro      =>r_prp.cod_pro,
                                                    p_cod_vl       =>r_prp.cod_vl,
                                                    p_qte_orig     =>v_qte_a_pic_ub,
                                                    p_unite_orig   =>'UB',
                                                    p_unite_dest   =>v_unite_cible,
                                                    p_qte_dest     =>v_qte_a_pic);
                IF v_ret <> 'OK' THEN
                    RAISE err_except;
                END IF;

                v_unite_pic := v_unite_cible;

                IF vr_stk.cod_va IS NULL THEN
                    v_cod_va_pic := NULL;
                END IF;
                IF vr_stk.cod_vl IS NULL THEN
                    v_cod_vl_pic := NULL;
                END IF;

            END IF;

        ELSE
            -- cas par defaut si PB de config ...
            v_cod_pro_pic:=vr_stk.cod_pro;
            v_cod_va_pic :=vr_stk.cod_va;
            v_cod_vl_pic :=vr_stk.cod_vl;

        END IF;

        -- lecture classe ABC du produit dans le magasin
        v_etape := 'rch classe abc produit mag';
        v_cod_abc_pro := se_bas_get_abc (p_cod_pro => v_cod_pro_pic,
                                         p_cod_va  => v_cod_va_pic,
                                         p_cod_usn => vr_stk.cod_usn,
                                         p_cod_mag => p_cod_mag_pic);

        IF v_cod_abc_pro IS NULL THEN
            v_etape := 'rch classe abc produit usn';
            v_cod_abc_pro := se_bas_get_abc (p_cod_pro => v_cod_pro_pic,
                                             p_cod_va  => v_cod_va_pic,
                                             p_cod_usn => vr_stk.cod_usn);
        END IF;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' v_cod_pro_pic:' || v_cod_pro_pic ||
                                          ' v_cod_va_pic:' || v_cod_va_pic ||
                                          ' v_cod_vl_pic:' || v_cod_vl_pic);
            su_bas_put_debug(v_nom_obj || ' v_qte_a_pic:' || TO_CHAR(v_qte_a_pic) || ' ' || v_unite_pic);
        END IF;

        -- Création de l'ordre de picking
        v_mode := 'NEW';
        v_etape := 'Création ordre de picking n° ' || v_cod_pic;
        v_ret := su_bas_ins_pc_pic(
                        p_cod_pic               =>v_cod_pic,
                        p_cle_pic               =>v_cle_pic,
                        p_typ_zone_pic          =>'P',                  -- toujours 'P' (zone 'P'icking)
                        p_qte_a_pic             =>v_qte_a_pic,          -- qte dans l'unité de stock
                        p_unite_qte             =>v_unite_pic,          -- unité de stock
                        p_qte_a_pic_2           =>p_qte_a_pic_2,        -- qte dans 2ème unité
                        p_unite_qte_2           =>p_unite_pic_2,        -- 2ème unité
                        p_qte_pic               =>0,
                        p_mode_pic              =>v_mode_pic,
                        p_mode_trait_dlc        =>'0',                  -- ** A voir dans la lig_com
                        p_mode_trait_lot        =>'0',                  -- ** A voir dans la lig_com
                        p_consig_prelev         =>NULL,                 -- ** A voir dans la lig_com
                        p_cod_pro               =>v_cod_pro_pic,
                        p_cod_va                =>v_cod_va_pic,
                        p_cod_vl                =>v_cod_vl_pic,
                        p_cod_prk               =>vr_stk.cod_prk,
                        p_cod_emp               =>v_cod_emp,
                        p_cod_usn               =>vr_stk.cod_usn,
                        p_cod_mag               =>p_cod_mag_pic,
                        p_cod_lot_stk           =>vr_stk.cod_lot_stk,
                        p_cod_ss_lot_stk        =>vr_stk.cod_ss_lot_stk,
                        p_dat_dlc               =>vr_stk.dat_dlc,
                        p_dat_stk               =>vr_stk.dat_stk,
                        p_cod_ut_stk            =>vr_stk.cod_ut,
                        p_typ_ut_stk            =>vr_stk.typ_ut,
                        p_cod_soc_proprio       =>vr_stk.cod_soc_proprio,
                        p_car_stk_1             =>vr_stk.car_stk_1,
                        p_car_stk_2             =>vr_stk.car_stk_2,
                        p_car_stk_3             =>vr_stk.car_stk_3,
                        p_car_stk_4             =>vr_stk.car_stk_4,
                        p_car_stk_5             =>vr_stk.car_stk_5,
                        p_car_stk_6             =>vr_stk.car_stk_6,
                        p_car_stk_7             =>vr_stk.car_stk_7,
                        p_car_stk_8             =>vr_stk.car_stk_8,
                        p_car_stk_9             =>vr_stk.car_stk_9,
                        p_car_stk_10            =>vr_stk.car_stk_10,
                        p_car_stk_11            =>vr_stk.car_stk_11,
                        p_car_stk_12            =>vr_stk.car_stk_12,
                        p_car_stk_13            =>vr_stk.car_stk_13,
                        p_car_stk_14            =>vr_stk.car_stk_14,
                        p_car_stk_15            =>vr_stk.car_stk_15,
                        p_car_stk_16            =>vr_stk.car_stk_16,
                        p_car_stk_17            =>vr_stk.car_stk_17,
                        p_car_stk_18            =>vr_stk.car_stk_18,
                        p_car_stk_19            =>vr_stk.car_stk_19,
                        p_car_stk_20            =>vr_stk.car_stk_20,
                        p_etat_atv_pc_pic       =>v_etat_atv_pic,
                        p_cod_pss_afc           =>p_cod_pss_afc,
                        p_typ_pic               =>'0',
                        p_qte_liv               =>0,
                        p_cod_asv               =>v_cod_asv,
                        p_cod_trf_pic           =>v_cod_trf_pic,
                        p_mode_rgp_asv          =>v_mode_rgp_asv,
                        p_mode_asv_pic          =>v_mode_asv_pic,
                        p_mode_rgp_ops          =>v_mode_rgp_ops,
                        p_mode_val_ops          =>v_mode_val_ops,
                        p_mode_trf_ops_pos_pic  =>v_mode_trf_ops_pos_pic,
                        p_mode_rch_pos_pic      =>v_mode_rch_pos_pic,
                        p_trf_otr_aut_val       =>v_trf_otr_aut_val,
                        p_trf_pos_prp_val_pic   =>v_trf_pos_prp_val_pic,
                        p_cc_cle_otr            =>v_cc_cle_otr,
                        p_cc_cod_trf            =>v_cc_cod_trf,
                        p_autor_suspension      =>v_autor_suspension,
                        p_typ_otr               =>v_typ_otr,
                        p_niv_prio              =>r_prp.niv_prio,   --100,
                        p_cod_cnt_trf           =>v_cod_cnt_pic,
                        p_chg_prp               =>p_chg_prp,
                        p_dat_sel               =>r_uee.dat_sel,
                        p_dat_prep              =>r_prp.dat_prep,
                        p_dlc_min               =>LEAST(r_prp.dlc_min, NVL(vr_stk.dat_dlc, r_prp.dlc_min)), --$MODGQUI 06052008 cas du contrat date forcé
                        p_dlc_max               =>GREATEST(r_prp.dlc_max,NVL(vr_stk.dat_dlc,r_prp.dlc_max)),
                        p_no_pos_lct            =>v_no_pos_lct,
                        p_cod_ops               =>NULL,
                        p_no_ord_tri_ops        =>NULL,
                        p_no_pos_pic            =>NULL,
                        p_no_pos_prp            =>NULL,
                        p_no_bor_pic            =>NULL,
                        p_typ_bor_pic           =>NULL,
                        p_dat_reg               =>NULL,
                        p_tps_trajet_1          =>NULL,
                        p_tps_trajet_2          =>NULL,
                        p_tps_trajet_tot        =>NULL,
                        p_qte_atv               =>NULL,
                        p_qte_ref_atv           =>NULL,
                        p_cod_err_pc_pic        =>NULL,
                        p_cod_abc_pro           =>v_cod_abc_pro,
                        p_cod_abc_emp           =>v_cod_abc_emp
                        );
        IF v_ret <> 'OK' THEN
            RAISE err_except;
        END IF;

    END IF;

    IF v_mode <> 'NEW' THEN
        -- Test si la fiche PIC_UEE existe déjà ?
        v_etape := 'open c_pic_uee';
        OPEN c_pic_uee (p_no_uee, v_cod_pic, p_no_com, p_no_lig_com);
        FETCH c_pic_uee INTO r_pic_uee;
        found_pic_uee := c_pic_uee%FOUND;
        CLOSE c_pic_uee;
    END IF;

    IF v_ret = 'OK' THEN
        IF v_mode = 'NEW' OR NOT found_pic_uee THEN
            -- Création d'un record dans PIC_UEE
            v_etape := 'Création d''un record dans PIC_UEE' ||
                         ' Cod_pic: '    || v_cod_pic ||
                         ' No_Uee: '     || p_no_uee  ||
                         ' No_com: '     || p_no_com  ||
                         ' No_lig_com: ' || p_no_lig_com;

            v_ret := su_bas_ins_pc_pic_uee(
                            p_cod_pic           =>v_cod_pic,
                            p_no_uee            =>p_no_uee,
                            p_no_com            =>p_no_com,
                            p_no_lig_com        =>p_no_lig_com,
                            p_cod_asv           =>v_cod_asv,
                            p_cod_trf_pic       =>v_cod_trf_pic,
                            p_chg_prp_ini       =>p_chg_prp);

            IF v_ret <> 'OK' THEN
                RAISE err_except;
            END IF;

        ELSE
            -- Ajout charge de preparation sur pic_uee
            v_etape := 'Ajout charge dans PIC_UEE';
            UPDATE pc_pic_uee SET
                chg_prp_ini = chg_prp_ini + p_chg_prp
            WHERE cod_pic = v_cod_pic AND no_uee = p_no_uee AND
                  no_com = p_no_com AND no_lig_com = p_no_lig_com;
        END IF;
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN

        ROLLBACK TO my_pc_bas_crea_pic_sp;

        IF c_pic%ISOPEN THEN
            CLOSE c_pic;
        END IF;

        IF c_pic_uee%ISOPEN THEN
            CLOSE c_pic_uee;
        END IF;
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'No_lig',
                        p_par_ano_2       => p_no_lig_com,
                        p_lib_ano_3       => 'No_UEE',
                        p_par_ano_3       => p_no_uee,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;



/****************************************************************************
*   pc_bas_calcul_clef_pic -
*/
-- DESCRIPTION :
-- -------------
-- Cette procedure permet de calculer une clef de picking
--
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03a,09.09.10,mnev    ajout systematiquement cod_mag_pic dans la cle
-- 02a,02.04.08,mnev    réécriture complete avec curseur et paramètre MODE_CAL_CLE_PIC
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  pr_stk     IN    : Record de réservation
--  p_cle_pic IN OUT : Clef de picking
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_calcul_cle_pic
(
    pr_stk              se_stk%ROWTYPE,
    p_cod_mag_pic       se_stk.cod_mag%TYPE,
    p_cle_pic   IN OUT  pc_pic.cle_pic%TYPE
)
IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_cle_pic:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    CURSOR c_mod IS
        SELECT par, action_lig_par_1
        FROM su_lig_par
        WHERE nom_par = 'MODE_CAL_CLE_PIC' AND etat_actif = '1'
        ORDER BY no_ord;

    r_mod c_mod%ROWTYPE;

    v_mode_cal_cle_pic  VARCHAR2(1000);
    v_ctx               su_ctx_pkg.tt_ctx;
    v_val               VARCHAR2(500);

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || ' ' || v_etape );
    END IF;

    v_etape   := 'Formate la cle';
    p_cle_pic := NULL;

    -- Recherche de la valeur de la clef 'MODE_CAL_CLE_PIC'
    v_etape := 'Rch clef atv : MODE_CAL_CLE_PIC';
    v_ret := su_bas_rch_cle_atv_pss(su_bas_get_pss_defaut (pr_stk.cod_usn),
                                    'PIC',          -- type activité
                                    'MODE_CAL_CLE_PIC',
                                    v_mode_cal_cle_pic);

    v_etape := 'mise en contexte du record se_stk';
    IF su_bas_ctx_se_stk (p_ctx => v_ctx,
                          rec   => pr_stk) THEN

        -- clef minimale.
        p_cle_pic := 'USN:' || pr_stk.cod_usn || ';';
        p_cle_pic := p_cle_pic || 'MPIC:' || p_cod_mag_pic || ';';
        p_cle_pic := p_cle_pic || 'PRO:' || pr_stk.cod_pro || ';';
        p_cle_pic := p_cle_pic || 'VA:' || pr_stk.cod_va || ';';
        p_cle_pic := p_cle_pic || 'VL:' || pr_stk.cod_vl || ';';

        -- ajout des clefs demandees dans la configuration
        v_etape := 'open c_mod';
        OPEN c_mod;
        LOOP
            FETCH c_mod INTO r_mod;
            EXIT WHEN c_mod%NOTFOUND;

            v_etape := 'Lecture ctx';
            v_val := su_ctx_pkg.su_bas_get (p_ctx =>v_ctx,
                                            p_name=>r_mod.action_lig_par_1);

            IF INSTR(v_mode_cal_cle_pic, ';'||r_mod.par||';') > 0 THEN
                IF v_val IS NOT NULL THEN
                    p_cle_pic := p_cle_pic || r_mod.par || ':' ||v_val || ';';
                END IF;
            END IF;

        END LOOP;
        CLOSE c_mod;

    END IF;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || 'Cle_pic:' || p_cle_pic);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

END;

/****************************************************************************
*   pc_bas_calcul_lst_mag -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de calculer une liste des magasins de réservation
--
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03g,07.05.10,mnev    corrige traitement sur liste picking vide
-- 03f,18.02.10,alfl    mettre au moins un mag de picking dans lst_mag_pic
-- 03e,15.12.09,mnev    gestion de la regle $CDE
-- 03d,24.09.09,mnev    p_cod_mag_dem peut être une liste de magasins
-- 03c,15.09.09,rbel    Ajout trace du résultat
-- 03b,11.02.09,mnev    Ajout de INSTR pour eviter les doublons.
-- 03a,30.01.09,mnev    Ajout paramètre p_mode_res et p_typ_prk_dem
-- 02a,06.11.08,mnev    Gere une nouvelle liste : magasin de recherche
-- 01a,23.04.07,gqui    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
-- p_mode_res       : AUTO pour automatique et MANU pour manuel
-- p_cod_vr  IN     : Code variante de réservation
-- p_lst_prk IN OUT : liste des clefs de réservations
--
-- RETOUR :
-- --------
-- OK ou ERROR
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_calcul_lst_mag (p_mode_res               VARCHAR2 DEFAULT 'AUTO',
                                p_cod_pss                pc_uee.cod_pss_afc%TYPE,
                                p_cod_mag_dem            su_pss_mag.cod_mag%TYPE DEFAULT NULL,
                                p_typ_prk_dem            su_pss_mag.typ_prk%TYPE DEFAULT NULL,
                                p_etat_autor_prk         pc_lig_com.etat_autor_prk%TYPE,
                                p_list_mag IN OUT NOCOPY pc_ordo_pkg.tt_lst_mag)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03g $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_lst_mag:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- déclarations de variables
    v_i                 NUMBER :=0;
    v_j                 NUMBER :=0;
    v_no_grp            su_pss_mag.no_grp%TYPE;
    v_cod_mag           su_pss_mag.cod_mag%TYPE;
    v_typ_prk           su_pss_mag.typ_prk%TYPE;

    -- déclarations des curseurs
    -- Curseur sur le process/magasin

    -- Rch de tous les magasins rch
    CURSOR c_all_mag (x_cod_pss     su_pss_mag.cod_pss%TYPE,
                      x_autor_prk   VARCHAR2) IS
    SELECT pm.*, p.typ_pss, p.ss_typ_pss
    FROM su_pss_mag pm, su_pss p
    WHERE p.cod_pss = x_cod_pss     AND
          p.cod_pss = pm.cod_pss    AND
          --(pm.cod_mag = p_cod_mag_dem OR p_lst_cod_dem IS NULL) AND
          --(pm.typ_prk = p_typ_prk_dem OR p_typ_prk_dem IS NULL) AND
          (pm.autor_res_auto = '1' OR p_mode_res = 'MANU')  AND
          ((pm.typ_prk > '0' AND x_autor_prk = '1') OR pm.typ_prk = '$CDE' OR -- Autorisation de prendre des PRKs
           pm.typ_prk = '0' )
    ORDER BY pm.no_grp ASC, pm.no_ord_grp ASC;

    r_all_mag      c_all_mag%ROWTYPE;
    found_all_mag  BOOLEAN;

    -- Rch des magasins pic/res
    CURSOR c_pss_mag (x_cod_pss     su_pss_mag.cod_pss%TYPE,
                      x_autor_prk   VARCHAR2) IS
    SELECT pm.*, p.typ_pss, p.ss_typ_pss
    FROM su_pss_mag pm, su_pss p
    WHERE p.cod_pss = x_cod_pss     AND
          p.cod_pss = pm.cod_pss    AND
          pm.etat_cfg_stk_pic IN ('0','1') AND
          (INSTR(p_cod_mag_dem,pm.cod_mag) > 0 OR p_cod_mag_dem IS NULL) AND
          (pm.typ_prk = p_typ_prk_dem OR p_typ_prk_dem IS NULL) AND
          (pm.autor_res_auto = '1' OR p_mode_res = 'MANU') AND
          ((pm.typ_prk > '0' AND x_autor_prk = '1') OR pm.typ_prk = '$CDE' OR -- Autorisation de prendre des PRKs
           pm.typ_prk = '0' )
    ORDER BY pm.no_grp ASC,
             pm.no_ord_grp ASC;

    r_pss_mag      c_pss_mag%ROWTYPE;
    found_pss_mag  BOOLEAN;

    v_lst_mag_rch       VARCHAR2(1000) := NULL;
    v_lst_mag_rch_prk   VARCHAR2(1000) := NULL;

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' ' || v_etape || 'p_cod_pss: ' || p_cod_pss
                                   || ' p_etat_autor_prk: '|| p_etat_autor_prk );

        su_bas_put_debug(v_nom_obj || ' ' || v_etape || 'p_mode_res: ' || p_mode_res
                                   || ' p_cod_mag_dem: '|| p_cod_mag_dem
                                   || ' p_typ_prk_dem: '|| p_typ_prk_dem);
    END IF;

    v_etape  := 'Open c_all_mag';
    OPEN c_all_mag (p_cod_pss, p_etat_autor_prk);
    LOOP
        FETCH c_all_mag INTO r_all_mag;
        EXIT WHEN c_all_mag%NOTFOUND;

        v_cod_mag :=  NVL(r_all_mag.cod_mag, '#NULL#');
        v_typ_prk :=  NVL(r_all_mag.typ_prk, '#NULL#');
        IF v_typ_prk = '$CDE' THEN
            v_typ_prk := '0';
        END IF;

        -- Liste des magasins de recherche et mag_rch + typ_prk
        IF INSTR(NVL(v_lst_mag_rch,'#NULL#'), ';' || v_cod_mag || ';') = 0 THEN
            v_lst_mag_rch     := NVL(v_lst_mag_rch,';') || v_cod_mag || ';';
        END IF;
        v_lst_mag_rch_prk := NVL(v_lst_mag_rch_prk,';') || v_cod_mag || ',' || v_typ_prk || ';';

    END LOOP;
    CLOSE c_all_mag;

    v_etape := 'Fin c_all_mag ';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || ' ' || v_etape || ' v_lst_mag_rch=' || v_lst_mag_rch);
        su_bas_put_debug(v_nom_obj || ' ' || v_etape || ' v_lst_mag_rch_prk=' || v_lst_mag_rch_prk);
    END IF;

    -------------------------------------
    -- Formate la liste
    -------------------------------------
    v_etape := 'Formate la liste p_list_mag';
    p_list_mag.DELETE;
    v_i      := 0;
    v_no_grp := NULL;

    -- init premier element
    p_list_mag(v_i+1).lst_mag_pic := ';';
    p_list_mag(v_i+1).lst_mag_res := ';';
    p_list_mag(v_i+1).lst_mag_res_prk := ';';
    p_list_mag(v_i+1).lst_mag_rch := v_lst_mag_rch;
    p_list_mag(v_i+1).lst_mag_rch_prk := v_lst_mag_rch_prk;

    -------------------------------------
    -- Recherche des magasins
    -------------------------------------
    v_etape  := 'Open c_pss_mag';
    OPEN c_pss_mag (p_cod_pss, p_etat_autor_prk);
    LOOP
        FETCH c_pss_mag INTO r_pss_mag;
        EXIT WHEN c_pss_mag%NOTFOUND;

        ------------------------------------------------------------------------------
        -- Construction des listes de magasins triées par No de groupe dans un tableau
        ------------------------------------------------------------------------------
        IF v_no_grp IS NULL OR v_no_grp <> r_pss_mag.no_grp THEN
            --
            -- changement de groupe : init element suivant
            --
            v_i      := v_i + 1;
            v_no_grp := r_pss_mag.no_grp;
            p_list_mag(v_i).lst_mag_pic := ';';
            p_list_mag(v_i).lst_mag_res := ';';
            p_list_mag(v_i).lst_mag_res_prk := ';';
            p_list_mag(v_i).lst_mag_rch := v_lst_mag_rch;
            p_list_mag(v_i).lst_mag_rch_prk := v_lst_mag_rch_prk;
        END IF;

        v_cod_mag :=  NVL(r_pss_mag.cod_mag, '#NULL#');
        v_typ_prk :=  NVL(r_pss_mag.typ_prk, '#NULL#');
        IF v_typ_prk = '$CDE' THEN
            v_typ_prk := '0';
        END IF;

        v_etape:='construit la liste des magasins de picking';
        -- Test si ce magasin est autorisé au picking pour construire
        -- la liste des magasins de picking
        IF r_pss_mag.etat_cfg_stk_pic = '1' THEN --'1' Autorisé
            IF INSTR(NVL(p_list_mag(v_i).lst_mag_pic,'#NULL#'), ';' || v_cod_mag || ';') = 0 THEN
                p_list_mag(v_i).lst_mag_pic := p_list_mag(v_i).lst_mag_pic || v_cod_mag || ';';
            END IF;
        END IF;
        v_etape:='construit la liste des magasins de resa';
        -- Liste des magasins de réservation et mag_res + typ_prk
        IF INSTR(NVL(p_list_mag(v_i).lst_mag_res,'#NULL#'), ';' || v_cod_mag || ';') = 0 THEN
            p_list_mag(v_i).lst_mag_res     := p_list_mag(v_i).lst_mag_res || v_cod_mag || ';';
        END IF;
        p_list_mag(v_i).lst_mag_res_prk := p_list_mag(v_i).lst_mag_res_prk || v_cod_mag || ',' || v_typ_prk || ';';
        IF v_lst_mag_rch IS NULL THEN
            IF INSTR(NVL(p_list_mag(v_i).lst_mag_rch,'#NULL#'), ';' || v_cod_mag || ';') = 0 THEN
                p_list_mag(v_i).lst_mag_rch     := p_list_mag(v_i).lst_mag_rch || v_cod_mag || ';';
            END IF;
            p_list_mag(v_i).lst_mag_rch_prk := p_list_mag(v_i).lst_mag_rch_prk || v_cod_mag || ',' || v_typ_prk || ';';
        END IF;

        v_etape := 'Fecth c_pss_mag mag=' || v_cod_mag || ' prk=' || v_typ_prk;
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' ' || v_etape || ' lst_mag_rch=' || p_list_mag(v_i).lst_mag_rch);
            su_bas_put_debug(v_nom_obj || ' ' || v_etape || ' lst_mag_rch_prk=' || p_list_mag(v_i).lst_mag_rch_prk);
            su_bas_put_debug(v_nom_obj || ' ' || v_etape || ' lst_mag_pic=' || p_list_mag(v_i).lst_mag_pic);
        END IF;

    END LOOP;
    CLOSE c_pss_mag;
    --
    -- controle si lst pic vide ...
    --
    IF v_i = 0 THEN
        -- controler au moins le premier element
        v_i := 1;
    END IF;

    FOR v_j IN 1 .. v_i
    LOOP
        --
        -- il faut au moins un magasin de picking ...
        --
        IF p_list_mag(v_j).lst_mag_pic =';'  THEN
            --
            -- la liste est vide on va donc chercher le premier magasin du groupe
            --
            v_etape:='rch au moins un mag pic boucle N°: ' || v_j ;
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || ' ' || v_etape );
            END IF;

            FOR r_mag_pic IN (SELECT cod_mag
                                FROM su_pss_mag
                               WHERE cod_pss=p_cod_pss AND etat_cfg_stk_pic = '1'
                               ORDER BY no_grp, no_ord_grp)
            LOOP
               p_list_mag(v_j).lst_mag_pic := p_list_mag(v_j).lst_mag_pic || r_mag_pic.cod_mag || ';';
               IF su_global_pkv.v_niv_dbg >= 6 THEN
                   su_bas_put_debug(v_nom_obj || ' ' || v_etape || ' lst_mag_pic=' || p_list_mag(v_j).lst_mag_pic);
               END IF;
               EXIT;
           END LOOP;

        END IF;

    END LOOP;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code_process',
                        p_par_ano_1       => p_cod_pss,
                        p_lib_ano_2       => 'Etat_autor_prk',
                        p_par_ano_2       => p_etat_autor_prk,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
 END;

/****************************************************************************
*   pc_bas_calcul_lst_cle_res -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de calculer une liste des clefs de réservation
--
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,09.03.09,mnev    Valeur par defaut de etat_obl à 0 au lieu de NULL.
--                      Ce qui fait que l'on autorise le regroupement s'il
--                      n'existe rien de paramétrer dans la variante.
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_vr  IN     : Code variante de réservation
--  p_lst_prk IN OUT : liste des clefs de réservations
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_calcul_lst_cle_res (p_cod_vr              pc_vr.cod_vr%TYPE,
                                    p_list_cle_res IN OUT NOCOPY pc_ordo_pkg.tt_lst_cle_res)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_lst_cle_res:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- déclarations de variables

    -- déclarations des curseurs
    CURSOR c_nom_col IS
    SELECT action_lig_par_1 nom_colonne
    FROM su_lig_par
    WHERE nom_par = 'VS_COLS'
    ORDER by par;

    r_nom_col          c_nom_col%ROWTYPE;
    found_nom_col      BOOLEAN;


    CURSOR c_vr IS
    SELECT vr.cod_vr, cl.*
    FROM pc_vr vr , su_cle_rch cl
    WHERE vr.cod_vr     = p_cod_vr   AND
          vr.cod_cle_vr = cl.cod_cle_rch;

    r_vr        c_vr%ROWTYPE;
    found_vr    BOOLEAN;


BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape || 'Code VR: ' || p_cod_vr );
    END IF;

    v_etape := 'Formate la liste p_list_cle_res';
    p_list_cle_res.DELETE;

    v_etape := 'Init par défaut'; -- pour toute les nom de colonnes existant dans
    OPEN c_nom_col;
    LOOP
        FETCH c_nom_col INTO r_nom_col;
        EXIT WHEN c_nom_col%NOTFOUND;

        -- Mise a jour de la liste
        v_etape := 'Init par défaut: ' || r_nom_col.nom_colonne;
        p_list_cle_res(r_nom_col.nom_colonne).no_ord_colonne := NULL;
        p_list_cle_res(r_nom_col.nom_colonne).mode_tri       := NULL;
        p_list_cle_res(r_nom_col.nom_colonne).etat_obl       := '0';

    END LOOP;
    CLOSE c_nom_col;

    v_etape := 'OPEN c_vr';
    OPEN c_vr;
    LOOP
        FETCH c_vr INTO r_vr;
        EXIT WHEN c_vr%NOTFOUND;

        -- Mise a jour de la liste
        v_etape := 'Mise a jour de la liste pour le nom de colonne: ' || r_vr.nom_colonne;
        p_list_cle_res(r_vr.nom_colonne).no_ord_colonne := r_vr.no_ord_colonne;
        p_list_cle_res(r_vr.nom_colonne).mode_tri       := r_vr.mode_tri;
        p_list_cle_res(r_vr.nom_colonne).etat_obl       := r_vr.etat_obl;

    END LOOP;
    CLOSE c_vr;

 RETURN 'OK';

 EXCEPTION
    WHEN OTHERS THEN

        IF c_nom_col%ISOPEN THEN
            CLOSE c_nom_col;
        END IF;

        IF c_vr%ISOPEN THEN
            CLOSE c_vr;
        END IF;
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code_vr',
                        p_par_ano_1       => p_cod_vr,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
 END;



/****************************************************************************
*   pc_bas_calcul_lst_prk -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de calculer une liste de prk possible pour une ligne
-- commande
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03a,21.01.10,mnev    passe le code process à fonction prk_rch_lst_compatible
-- 02b,28.12.09,mnev    traite le cas des ve_doc et ajotu d'un evenement
-- 02a,18.12.09,mnev    gestion de la regle $CDE
-- 01b,28.04.09,mnev    Corrige la concaténation.
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_no_com      : no de commande
--  p_no_lig      : no de lig_commande
--  p_lst_prk OUT : liste des prémarqués compatibles
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_calcul_lst_prk (p_no_com                    pc_lig_com.no_com%TYPE,
                                p_no_lig_com                pc_lig_com.no_lig_com%TYPE,
                                p_cod_prk_dem               VARCHAR2 DEFAULT NULL,
                                p_autor_rgl_prk_cpt         VARCHAR2,
                                p_lst_typ_rgl_prk           VARCHAR2,
                                p_list_cod_prk       IN OUT VARCHAR2,
                                p_list_cod_pss_prk   IN OUT VARCHAR2,
                                p_list_id_action_prk IN OUT VARCHAR2,
                                p_cod_pss                   su_pss.cod_pss%TYPE DEFAULT NULL)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_lst_prk:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- déclarations de variables
    r_don_ref           su_pro_prk%ROWTYPE;
    r_lig_cmd           pc_lig_cmd%ROWTYPE;
    r_lig_com           pc_lig_com%ROWTYPE;

    v_list_pss_prk      su_prk_pkg.tt_pss_prk;
    v_lst_typ_rgl_prk   VARCHAR2(200) := p_lst_typ_rgl_prk;

    v_liste             VARCHAR2(1000):=NULL;
    v_test              BOOLEAN;
    v_position          NUMBER:=0;
    v_chaine            VARCHAR(100);
    v_valeur            VARCHAR(1000);

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;

    --
    CURSOR c_prk IS
        SELECT *
        FROM su_prk_action
        WHERE msk_pro = '%' AND typ_rgl_prk = '$CDE';

    r_prk c_prk%ROWTYPE;

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                         ' No Lig Com: ' || p_no_com || '-' || p_no_lig_com ||
                         ' cod_prk_dem: ' || p_cod_prk_dem ||
                         ' lst_typ_rgl: ' || p_lst_typ_rgl_prk ||
                         ' Autorisation de prk compatible: ' ||  p_autor_rgl_prk_cpt);
    END IF;

    IF p_cod_prk_dem = '$CDE' THEN

        OPEN c_prk;
        FETCH c_prk INTO r_prk;
        IF c_prk%FOUND THEN

            v_liste := r_prk.lst_col_prk;

            v_position:=0;
            v_test:= TRUE;

            IF v_liste IS NOT NULL THEN
                v_etape := 'on recherche colonne par colonne';
                LOOP
                    v_position:=su_bas_extract_liste(p_pos_init  =>v_position,
                                                     p_liste     =>v_liste,
                                                     p_chaine    =>v_chaine,
                                                     p_separateur=>';' );

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj || ' ctrl colonne ' || v_chaine);
                    END IF;

                    EXIT WHEN v_chaine='';
                    EXIT WHEN v_position=0;

                    v_valeur := su_bas_gcl_pc_lig_com (p_no_com     => p_no_com,
                                                       p_no_lig_com => p_no_lig_com,
                                                       p_colonne    => v_chaine);
                    -- cas particulier des VE_DOC
                    IF v_chaine LIKE 'COD_VEDOC%' AND v_valeur = 'PC_000' THEN
                        v_valeur := NULL;
                    END IF;

                    IF su_global_pkv.vt_evt_actif.exists('ON_CTRLREFCDE') THEN
                        v_etape := 'creation ctx';
                        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COLONNE', v_chaine);
                        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'VALEUR', v_valeur);

                        v_etape := 'Appel événement ON';
                        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_CTRLREFCDE');
                        IF v_ret_evt = 'ERROR' THEN
                            RAISE err_except;
                        END IF;

                        v_valeur := v_ret_evt;

                    END IF;

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj|| ' v_chaine:' || v_chaine);
                        su_bas_put_debug(v_nom_obj|| ' v_valeur:' || v_valeur);
                    END IF;

                    IF v_valeur IS NOT NULL THEN
                        v_test := FALSE;
                    END IF;

                    EXIT WHEN v_test= FALSE;
                END LOOP;
            END IF;

            IF v_test THEN
                p_list_cod_prk       := ';0;$CDE;';
                p_list_cod_pss_prk   := ';#NULL#;' || NVL(r_prk.cod_pss,'#NULL#') || ';';      -- $MODGQUI 02032010 ajout en debut ;NULL
                p_list_id_action_prk := ';#NULL#;' || r_prk.id_action_prk || ';';              -- $MODGQUI 02032010 ajout en debut ;NULL
                v_ret := 'OK';
            ELSE
                p_list_cod_prk       := ';$CDE;$DIFF;';
                p_list_cod_pss_prk   := NULL;
                p_list_id_action_prk := NULL;
                v_ret := 'OK';
            END IF;
        ELSE
            v_etape := 'pas de config $CDE dans regle prk';
            p_list_cod_prk       := NULL;
            v_ret := 'ERROR';
        END IF;
        CLOSE c_prk;

    ELSE

        -- récupère le record de la lig_com
        r_lig_com := su_bas_grw_pc_lig_com(p_no_com, p_no_lig_com);

        -- récupère le record de la lig_cmd (commande usine)
        r_lig_cmd := su_bas_grw_pc_lig_cmd(r_lig_com.no_cmd, r_lig_com.no_lig_cmd);

        -- Initialisation du record des données de référence
        r_don_ref.COD_PRO           := r_lig_com.COD_PRO;
        r_don_ref.COD_VEDOC_OFS     := r_lig_com.COD_VEDOC_OFS;
        r_don_ref.COD_VEDOC_MQE     := r_lig_com.COD_VEDOC_MQE;
        r_don_ref.COD_VEDOC_PCE_1   := r_lig_com.COD_VEDOC_PCE_1;
        r_don_ref.COD_VEDOC_PCE_2   := r_lig_com.COD_VEDOC_PCE_2;
        r_don_ref.COD_VEDOC_COL_1   := r_lig_com.COD_VEDOC_COL_1;
        r_don_ref.COD_VEDOC_COL_2   := r_lig_com.COD_VEDOC_COL_2;
        r_don_ref.COD_LAN_1_ETQ     := r_lig_com.COD_LAN_1_ETQ;
        r_don_ref.COD_LAN_2_ETQ     := r_lig_com.COD_LAN_2_ETQ;
        r_don_ref.PRX_PCE_1         := r_lig_com.PRX_PCE_1;
        r_don_ref.PRX_PDS_1         := r_lig_com.PRX_PDS_1;
        r_don_ref.COD_DEV_1         := r_lig_com.COD_DEV_1;
        r_don_ref.PRX_PCE_2         := r_lig_com.PRX_PCE_2;
        r_don_ref.PRX_PDS_2         := r_lig_com.PRX_PDS_2;
        r_don_ref.COD_DEV_2         := r_lig_com.COD_DEV_2;
        r_don_ref.UNITE_PDS         := r_lig_com.UNITE_PDS;
        r_don_ref.MODE_ETQ_PRX      := r_lig_com.MODE_ETQ_PRX;
        r_don_ref.COD_CLI           := r_lig_com.COD_CLI_FINAL;
        r_don_ref.PCB_EXP           := r_lig_com.PCB_EXP;
        r_don_ref.COD_VED           := r_lig_com.COD_VED;
        r_don_ref.COD_VECB_PCE      := r_lig_com.COD_VECB_PCE;
        r_don_ref.COD_VECB_COL      := r_lig_com.COD_VECB_COL;
        r_don_ref.LIBRE_SU_PRO_PRK_1:= NULL;
        r_don_ref.LIBRE_SU_PRO_PRK_2:= NULL;
        r_don_ref.LIBRE_SU_PRO_PRK_3:= NULL;
        r_don_ref.LIBRE_SU_PRO_PRK_4:= NULL;
        r_don_ref.LIBRE_SU_PRO_PRK_5:= NULL;
        r_don_ref.COD_PRO_CDE       := r_lig_cmd.COD_PRO_CDE;
        r_don_ref.COD_VA_CDE        := r_lig_cmd.COD_VA_CDE;
        r_don_ref.COD_VL_CDE        := r_lig_cmd.COD_VL_CDE;

        -- Recherche des prk compatibles.
        v_etape := 'Formate la liste v_list_pss_prk';
        v_list_pss_prk.DELETE;

        v_etape := 'Appel su_bas_prk_rch_lst_compatible';
        v_ret  := su_prk_pkg.su_bas_prk_rch_lst_compatible (pr_don_ref          =>r_don_ref,
                                                            p_autor_rgl_prk_cpt =>p_autor_rgl_prk_cpt,
                                                            p_lst_typ_rgl_prk   =>v_lst_typ_rgl_prk,
                                                            p_list_prk          =>v_list_pss_prk,
                                                            p_cod_pss           =>p_cod_pss);

        -- Construction des listes des code_prk, cod_pss associé
        p_list_cod_prk        := NULL;
        p_list_cod_pss_prk    := NULL;
        p_list_id_action_prk  := NULL;
        v_etape:='Balayage des éléments de la liste p_list_prk';
        FOR i IN 1 ..  v_list_pss_prk.COUNT
        LOOP
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || ' cod_prk:<' || v_list_pss_prk(i).cod_prk || '>');
            END IF;

            IF v_list_pss_prk(i).cod_prk IS NOT NULL AND
               (p_cod_prk_dem IS NULL OR v_list_pss_prk(i).cod_prk = p_cod_prk_dem) THEN
               p_list_cod_prk       := NVL(p_list_cod_prk,';') || v_list_pss_prk(i).cod_prk || ';' ;
               p_list_cod_pss_prk   := NVL(p_list_cod_pss_prk,';') || NVL(v_list_pss_prk(i).cod_pss, '#NULL#') || ';' ;
               p_list_id_action_prk := NVL(p_list_id_action_prk, ';') || v_list_pss_prk(i).id_action_prk || ';' ;
            ELSE
               EXIT;
            END IF;
        END LOOP;

        IF v_ret <> 'OK' THEN
           RAISE err_except;
        END IF;

    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'No_lig',
                        p_par_ano_2       => p_no_lig_com,
                        p_lib_ano_3       => 'Autor_rgl_prk_cpt',
                        p_par_ano_3       => p_autor_rgl_prk_cpt,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;


/****************************************************************************
*   pc_bas_rch_contrat_date -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de récupérer les contrats dates client
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,14.12.15,pluc    Pas de calcul DLC_MAX automatique. On test le mode de calcul
--                      obligatoirement.
-- 01c,17.04.13,mnev    ajout d'un trunc dans le resultat de la date ...
--                      (sinon présence de l'heure ...)
-- 01b,03.08.11,mnev    prise en compte du client final
-- 01a,23.04.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_no_com       : no de commande
--  p_no_lig       : no de lig_commande
--  p_typ_ctt_date : Type de contrat date sur 'DLC_MIN', 'DLC_MAX', 'DAT_1'
--  p_date    OUT  : date limite du contrat ou NULL
--
--
--
-- COMMIT :
-- --------
--   NON


PROCEDURE pc_bas_rch_contrat_date (
                                p_no_com                pc_lig_com.no_com%TYPE,
                                p_no_lig_com            pc_lig_com.no_lig_com%TYPE,
                                p_typ_ctt_date          VARCHAR2,   -- 'DLC_MIN', 'DLC_MAX', 'DAT_1'
                                p_date         IN OUT   DATE
    ) IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01c $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_rch_contrat_date:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- déclarations des curseurs
    -- -----------------------------------------
    CURSOR c_rch_cd IS
       SELECT DECODE(p_typ_ctt_date, 'DLC_MIN', l.delai_ctt_dlc,
                                     'DLC_MAX', l.delai_ctt_dlc_max,
                                     'DAT_1', l.delai_dat_1) DELAI_CTT,
              DECODE(p_typ_ctt_date, 'DLC_MIN', l.mode_cal_ctt_dlc,
                                     'DLC_MAX', l.mode_cal_ctt_dlc_max,
                                     'DAT_1', l.mode_cal_ctt_dat_1) MODE_CAL_CTT,
              e.dat_liv, e.dat_exp, NVL(l.cod_cli_final,e.cod_cli) cod_cli,
              l.cod_usn, l.cod_pro, l.cod_va, l.cod_vl,
              SU_BAS_GCL_PC_LIG_CMD(l.no_cmd, l.no_lig_cmd,'COD_PRO_CDE') cod_pro_cde
       FROM   pc_ent_com e, pc_lig_com l
       WHERE  l.no_com      = p_no_com      AND
              l.no_lig_com  = p_no_lig_com  AND
              e.no_com      = l.no_com;

    r_rch_cd       c_rch_cd%ROWTYPE;
    found_rch_cd   BOOLEAN;

    -- Recherche les dernières dates livrées dans l'historisation
    --$MOD,olor,21/10/2009  Pour gerer le contrat date avec une commande en avance
    --$MOD,croc,21.01.2015 Recherche mono ou multi usines
    CURSOR c_cli_pro_his (x_cod_usn     pc_cli_pro_his.cod_usn%TYPE,
                          x_cod_cli     pc_cli_pro_his.cod_cli%TYPE,
                          x_cod_pro_cde pc_cli_pro_his.cod_pro_cde%TYPE,
                          x_cod_pro     pc_cli_pro_his.cod_pro%TYPE,
                          x_cod_va      pc_cli_pro_his.cod_va%TYPE,
                          x_cod_vl      pc_cli_pro_his.cod_vl%TYPE,
                          x_cod_prk     pc_cli_pro_his.cod_prk%TYPE) IS
       SELECT DECODE(p_typ_ctt_date, 'DAT_1', MAX(h.dat_1_liv_val), MAX(h.dlc_liv_val)) der_date_liv,
                     DECODE(p_typ_ctt_date, 'DAT_1', MAX(h.dat_1_liv_val_prec), MAX(h.dlc_liv_val_prec)) der_date_liv_prec,
                     MAX(h.dat_liv_val) HIS_DAT_LIV,
                     MAX(h.dat_liv_val_prec) HIS_DAT_LIV_PREC
       FROM   pc_cli_pro_his h
       WHERE  (h.cod_usn     = x_cod_usn   
              OR NVL(su_bas_rch_par_usn('PC_MODE_CONTRAT_DATE', x_cod_usn),'MONO_USN') = 'MULTI_USN') AND
              h.cod_cli     = x_cod_cli                  AND
              h.cod_pro_cde = x_cod_pro_cde;

    r_cli_pro_his    c_cli_pro_his%ROWTYPE;
    found_cli_pro_his     BOOLEAN;

    -- déclarations de variables
    v_date          DATE := NULL;
    v_date_his          DATE := NULL;
    v_date_min          DATE := NULL;
    v_date_max          DATE := NULL;
    v_date_format   VARCHAR2(30);
    v_typ_date      VARCHAR2(20);    

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                         ' No Lig Com: ' || p_no_com || '-' || p_no_lig_com ||
                         ' Type de contrat date: ' ||  p_typ_ctt_date);
    END IF;

    -- Si p_date NULL, on calcul sinon on ne fait rien
    IF p_date IS NULL THEN
        -- Gestion d'un contrat date ?
        -- ---------------------------
        OPEN c_rch_cd;
        FETCH c_rch_cd INTO r_rch_cd;
        found_rch_cd := c_rch_cd%FOUND;
        CLOSE c_rch_cd;

        --IF found_rch_cd AND NVL(r_rch_cd.mode_cal_ctt, '0') <> '0'  OR p_typ_ctt_date = 'DLC_MAX' THEN
        -- $MOD,02a,pluc
        IF found_rch_cd AND NVL(r_rch_cd.mode_cal_ctt, '0') <> '0'  THEN
            -- Il y a 1 contrat
            -- Recherche dans l'historisation du client
            v_etape := 'rch ds historique';
            OPEN c_cli_pro_his(r_rch_cd.cod_usn, r_rch_cd.cod_cli, r_rch_cd.cod_pro_cde,
                               r_rch_cd.cod_pro, r_rch_cd.cod_va, r_rch_cd.cod_vl, NULL);
            FETCH c_cli_pro_his INTO r_cli_pro_his;
            found_cli_pro_his := c_cli_pro_his%FOUND;
            CLOSE c_cli_pro_his;

            IF  found_cli_pro_his THEN
                --$MOD,olor,21/10/2009  Pour gerer le contrat date avec une commande en avance
                -- recherche  des 3 cas
                IF   r_cli_pro_his.his_dat_liv <= r_rch_cd.dat_liv THEN
                    v_date_min :=  r_cli_pro_his.der_date_liv;
                    v_date_max :=  null;
                ELSIF  r_cli_pro_his.his_dat_liv_prec <= r_rch_cd.dat_liv THEN
                    v_date_min :=  r_cli_pro_his.der_date_liv_prec;
                    v_date_max :=  r_cli_pro_his.der_date_liv;
                ELSE
                    v_date_min :=  null;
                    v_date_max :=  r_cli_pro_his.der_date_liv_prec;
                END IF;
                IF p_typ_ctt_date =  'DLC_MIN' THEN
                    v_date_his :=  v_date_min;
                ELSIF  p_typ_ctt_date =  'DLC_MAX'  THEN
                    v_date_his :=  v_date_max;
                ELSE -- DAT_1
                    v_date_his :=  r_cli_pro_his.der_date_liv;
                END IF;
            ELSE
                v_date_his :=  null;
            END IF;

            IF p_typ_ctt_date = 'DAT_1' THEN
               v_typ_date := 'DAT_1';
            ELSE
               v_typ_date := 'DLC';
            END IF;

            IF r_rch_cd.mode_cal_ctt = '1' THEN
                -- Contrat date -> DATE minimum = DATE calculée de la ligne
                pc_bas_calcul_date (p_no_com      =>p_no_com,
                                    p_no_lig_com  =>p_no_lig_com,
                                    p_typ_date    =>v_typ_date,
                                    p_date        =>v_date,
                                    p_date_au_format =>v_date_format);

            ELSIF r_rch_cd.mode_cal_ctt = '2' THEN
                -- Contrat date -> DATE minimum = Date calculée de la ligne
                -- avec Date minimum >= Derniere Date livrée
                pc_bas_calcul_date (p_no_com      =>p_no_com,
                                    p_no_lig_com  =>p_no_lig_com,
                                    p_typ_date    =>v_typ_date,
                                    p_date        =>v_date,
                                    p_date_au_format =>v_date_format);
                IF v_date < NVL(v_date_his, v_date) AND p_typ_ctt_date =  'DLC_MIN' THEN
                     v_date := NVL(v_date_his, v_date);
                END IF;

            ELSIF r_rch_cd.mode_cal_ctt = '3' THEN
                -- Contrat date --> Delai a assurer par rapport à la date de livraison
                v_date := TRUNC(r_rch_cd.dat_liv) + r_rch_cd.delai_ctt;

            ELSIF r_rch_cd.mode_cal_ctt = '4' THEN
                -- Contrat date -- Delai a assurer par rapport à la date de livraison
                -- + Date minimum >= Derniere date livrée
                v_date := TRUNC(r_rch_cd.dat_liv) + r_rch_cd.delai_ctt;
                IF v_date < NVL(v_date_his, v_date)  AND p_typ_ctt_date =  'DLC_MIN' THEN
                     v_date := NVL(v_date_his, v_date);
                END IF;

            ELSIF r_rch_cd.mode_cal_ctt = '5' THEN
                -- Contrat date --> Date maximum = Date expédié + délai garanti par le contrat
                -- v_date := TRUNC(r_rch_cd.dat_exp) + NVL(r_rch_cd.delai_ctt, 9999);
                -- 04c,croc :Prendre en compte une valeur pas défaut du délai
                v_date := TRUNC(r_rch_cd.dat_exp) + 
                          NVL(r_rch_cd.delai_ctt, NVL(su_bas_rch_action_det(p_nom_par => 'MODE_CAL_CTT_DLC', 
                                                                            p_par => r_rch_cd.mode_cal_ctt),0));

            ELSIF r_rch_cd.mode_cal_ctt = '6' THEN
                -- Contrat date --> Date maximum = Date liv + délai garanti par le contrat
                --v_date := TRUNC(r_rch_cd.dat_liv) + NVL(r_rch_cd.delai_ctt, 9999);
                -- 04c,croc :Prendre en compte une valeur pas défaut du délai
                v_date := TRUNC(r_rch_cd.dat_liv) + 
                          NVL(r_rch_cd.delai_ctt, NVL(su_bas_rch_action_det(p_nom_par => 'MODE_CAL_CTT_DLC', 
                                                                            p_par => r_rch_cd.mode_cal_ctt),0));
                                                                            
            ELSE
                v_date := v_date_his;
            END IF;
            p_date := TRUNC(v_date);

        ELSE
            p_date := NULL;
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'No_lig',
                        p_par_ano_2       => p_no_lig_com,
                        p_lib_ano_3       => 'Type de contrat date',
                        p_par_ano_3       => p_typ_ctt_date,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        p_date := NULL;
END;


/****************************************************************************
* pc_bas_cal_date    - Calcul des date de la ligne commande en fonction de
*                    la variante de date cod_ve
*/
-- DESCRIPTION
-- -----------
-- Cette procedure fournie la DLC mini a rechercher dans le stock.
--
--
-- HISTORIQUE DES MODIFICATIONS
-- ----------------------------
-- ---------------------------------
-- Ver,Date    ,Auteur Description
-- ---------------------------------
-- 01c,17.04.13,mnev    ajout d'un trunc dans le resultat de la date ...
--                      (sinon présence de l'heure ...)
-- 01b,03.07.09,mnev   Ajout masque de conversion sur date (YYYYMMDD)
-- 01a,28.08.07,gqui   Version initiale.
-- -----------------
--
-- PARAMETRES DE LA FONCTION
-- -------------------------
-- p_no_com             Numero de commande
-- p_no_lig             Numero de ligne
-- p_typ_date           Type de date,   -- 'DLC', 'DAT_1', 'DAT_2', 'DAT_3'
-- p_date           OUT date calculée
-- p_date_au_format OUT date formatée
--
-- COMMIT
-- ------
-- Jamais de Commit.
--
PROCEDURE pc_bas_calcul_date (
                             p_no_com              pc_lig_com.no_com%TYPE,
                             p_no_lig_com          pc_lig_com.no_lig_com%TYPE,
                             p_typ_date            VARCHAR2 DEFAULT 'DLC',  -- 'DLC', 'DAT_1', 'DAT_2', 'DAT_3'
                             p_date           OUT  DATE,
                             p_date_au_format OUT  VARCHAR2
    ) IS


    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01c $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_date';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;


    -- Déclaration des curseurs
    ----------------------------
    CURSOR c_date IS
        SELECT e.dat_prep, e.dat_liv, e.dat_exp,
               DECODE (p_typ_date, 'DLC' , l.dlc, 'DAT_1', l.delai_dat_1,
                       'DAT_2', l.delai_dat_2, 'DAT_3', l.delai_dat_3) DELAI_DATE,
               DECODE (p_typ_date, 'DLC' , vd.mode_cal_dlc, 'DAT_1', vd.mode_cal_dat_1,
                       'DAT_2', vd.mode_cal_dat_2, 'DAT_3', vd.mode_cal_dat_3) MODE_CAL_DATE,
               DECODE (p_typ_date, 'DLC' , vd.mode_imp_dlc, 'DAT_1', vd.mode_imp_dat_1,
                       'DAT_2', vd.mode_imp_dat_2, 'DAT_3', vd.mode_imp_dat_3) MODE_IMP_DATE,
               DECODE (p_typ_date, 'DLC' , 'PER', 'DAT_1', vd.typ_pro_delai_1,
                       'DAT_2', vd.typ_pro_delai_2, 'DAT_3',vd.typ_pro_delai_3) TYP_PRO_DELAI,
               l.cod_pro, l.cod_va, l.cod_vl
        FROM   pc_ent_com e, pc_lig_com l, su_ved vd
        WHERE  e.no_com  = p_no_com        AND
               l.no_com  = e.no_com        AND
               l.no_lig_com = p_no_lig_com AND
               l.cod_ved = vd.cod_ved;

    r_date        c_date%ROWTYPE;
    found_date    BOOLEAN;

    -- Déclaration de variables
    ----------------------------
    v_date        DATE;


BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape ||
                         ' No Lig Com: ' || p_no_com || '-' || p_no_lig_com ||
                         ' Type de date: ' ||  p_typ_date);
    END IF;

    v_etape := 'Open c_date';
    OPEN c_date;
    FETCH c_date INTO  r_date;
    found_date := c_date%FOUND;
    CLOSE c_date;

    IF found_date THEN
        -- ------------------
        -- Calcul d'une DATE
        -- ------------------
        v_etape := 'Calcul d''une date de type ' || p_typ_date;
        IF r_date.mode_cal_date= '0' THEN
            -- Pas de date
            v_date := NULL;
        ELSIF r_date.mode_cal_date = '1' AND NVL(r_date.delai_date, 0) != 0 THEN
            -- Date fournie par la GESCOM
            v_date := TO_DATE(r_date.delai_date,'YYYYMMDD');
        ELSIF r_date.mode_cal_date = '2' THEN
            -- Date de prepa + delai garantie client du produit 'GAR'
            v_date := r_date.dat_prep + se_bas_rch_delai_pro(p_cod_pro      =>r_date.cod_pro,
                                                            p_typ_pro_delai =>'GAR',
                                                            p_cod_va        =>r_date.cod_va,
                                                            p_cod_vl        =>r_date.cod_vl
                                                            );

        ELSIF r_date.mode_cal_date = '4' THEN
            -- Date de prepa + delai de la lig_com
            v_date := TRUNC(r_date.dat_prep) + r_date.delai_date;

        ELSIF r_date.mode_cal_date = '5' THEN
            -- Date courante + delai peremption produit 'PER'
            v_date := TRUNC(SYSDATE) + se_bas_rch_delai_pro(p_cod_pro       =>r_date.cod_pro,
                                                            p_typ_pro_delai =>'PER',
                                                            p_cod_va        =>r_date.cod_va,
                                                            p_cod_vl        =>r_date.cod_vl
                                                            );

        ELSIF r_date.mode_cal_date = '6' THEN
            -- Date courante + delai de la lig_com
            v_date := TRUNC(SYSDATE) + r_date.delai_date;

        ELSIF r_date.mode_cal_date = '7' THEN
            -- Date d'expedition + delai de la lig_com
            v_date := TRUNC(r_date.dat_exp) + r_date.delai_date;

        ELSIF r_date.mode_cal_date IN ('3', '8', '9,', 'A', 'C', 'D', 'F', 'G', 'H') THEN
            -- Date de prepa + delai peremption produit 'PER'
            v_date := TRUNC(r_date.dat_liv) + se_bas_rch_delai_pro(p_cod_pro        =>r_date.cod_pro,
                                                            p_typ_pro_delai =>'GAR',
                                                            p_cod_va        =>r_date.cod_va,
                                                            p_cod_vl        =>r_date.cod_vl
                                                            );

        ELSIF r_date.mode_cal_date IN ('B', 'E') THEN
            -- Date courante + nb de jours max de stock du produit 'MAX'
            v_date := TRUNC(SYSDATE) + se_bas_rch_delai_pro(p_cod_pro       =>r_date.cod_pro,
                                                            p_typ_pro_delai =>'MAX',
                                                            p_cod_va        =>r_date.cod_va,
                                                            p_cod_vl        =>r_date.cod_vl
                                                            );

        ELSE
            v_date := NULL;
        END IF;

        p_date := TRUNC(v_date);

        v_etape := 'Formatage de la date calculée ' || TO_CHAR(p_date, 'DDMMYYYY')
                   || ' avec le mode d''impression = ' || r_date.mode_imp_date;
        -- ---------------------
        -- Formatage de la DATE
        -- ---------------------
        IF p_date IS NULL OR NVL(r_date.mode_imp_date, '0') = '0' THEN
            -- Pas d'impression
            p_date_au_format := NULL;
        ELSIF r_date.mode_imp_date = '1' THEN
            -- Format: 'DD/MM/YY'
            p_date_au_format := TO_CHAR(v_date, 'DD/MM/YY');
        ELSIF r_date.mode_imp_date = '2' THEN
            -- Format: Quantième 'QQQ'
            p_date_au_format := TO_CHAR(v_date, 'QQQ');
        ELSIF r_date.mode_imp_date = '3' THEN
            -- Format: 'DDMONYY'  ex: 09Mar07
            p_date_au_format := TO_CHAR(v_date, 'DDMONYY', 'NLS_DATE_LANGUAGE = FRENCH');
        ELSIF r_date.mode_imp_date = '4' THEN
            -- Format: 'DDRRMM'
            p_date_au_format := TO_CHAR(v_date, 'DD') || 'RR' || TO_CHAR(v_date, 'MM');
        ELSIF r_date.mode_imp_date = '5' THEN
            -- Format: Année + Quantième 'YQQQ'
            p_date_au_format := TO_CHAR(v_date, 'YQQQ');
        ELSIF r_date.mode_imp_date = '6' THEN
            -- Format: 'MM/DD/YY'
            p_date_au_format := TO_CHAR(v_date, 'MM/DD/YY');
        ELSIF r_date.mode_imp_date = '7' THEN
            -- Format: 'DD/MM/YYYY'
            p_date_au_format := TO_CHAR(v_date, 'DDMMYYYY');
        ELSIF r_date.mode_imp_date = '8' THEN
            -- Format: 'RRIIDDMM'
            p_date_au_format := 'RRII' || TO_CHAR(v_date, 'DDMM');
        ELSE
            -- Format par défaut DD/MM/YYYY'
            p_date_au_format := TO_CHAR(v_date, 'DD/MM/YYYY');
        END IF;

    ELSE
        p_date := NULL;
        p_date_au_format := NULL;
    END IF;


EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'No_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'No_lig',
                        p_par_ano_2       => p_no_lig_com,
                        p_lib_ano_3       => 'Typ_date',
                        p_par_ano_3       => p_typ_date,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        p_date := NULL;
        p_date_au_format := NULL;
END;


/****************************************************************************
*   pc_bas_unlock_pc_uee -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de dé-verrouiller les colis de la table PC_UEE
-- --
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON
FUNCTION pc_bas_unlock_pc_uee (p_cod_usn          su_usn.cod_usn%TYPE,
                               p_cod_verrou       VARCHAR2,
                               p_where            VARCHAR2 DEFAULT NULL
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_unlock_pc_uee:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;
    v_query             VARCHAR2(4000);

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;

    v_etape := 'Construction de la query sur PC_UEE: ';
    v_query := 'UPDATE pc_uee u SET lst_fct_lock = su_bas_unlock (''' ||
                p_cod_verrou || ''', u.lst_fct_lock, u.id_session_lock) ' ||
               'WHERE u.id_session_lock = ''' || v_session_ora || ''' AND ' ||
               'INSTR(u.lst_fct_lock, ''' || p_cod_verrou || ''') > 0 ';
    IF p_where IS NOT NULL THEN
        v_query := v_query || ' AND (' || p_where  || ')';
    END IF;

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape || v_query);
    END IF;

    EXECUTE IMMEDIATE v_query;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_gen_no_uee_ut_p1 -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet générer le n° colis dans l'UT de niveau 1
-- --
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01c,03.01.11,rbel    ajout tri des colis sur no_uee
-- 01b,09.07.08,mnev    change un mode_dbg 1 vers 6
-- 01a,16.10.07,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON
FUNCTION pc_bas_gen_no_uee_ut_p1 (p_cod_usn          su_usn.cod_usn%TYPE,
                                  p_cod_verrou       VARCHAR2
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01c $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_gen_no_uee_ut_p1:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    CURSOR c_uee IS
    SELECT c.no_uee,c.cod_ut_sup,c.typ_ut_sup
     FROM  pc_uee c
    WHERE  c.id_session_lock  = v_session_ora
      AND  c.cod_ut_sup is not null
      AND  c.typ_ut_sup is not null
      AND  c.no_uee_ut_p1 is NULL
      AND  INSTR(c.lst_fct_lock, ';'||p_cod_verrou||';') > 0
    ORDER BY c.no_uee;

    r_uee   c_uee%ROWTYPE;

    CURSOR c_no_uee_ut(x_no_uee pc_uee.no_uee%TYPE,x_cod_ut_sup pc_uee.cod_ut_sup%TYPE,x_typ_ut_sup pc_uee.typ_ut_sup%TYPE) IS
     SELECT max(c.no_uee_ut_p1) cpt
       FROM pc_uee c
      WHERE c.no_uee<>x_no_uee
        AND c.cod_ut_sup=x_cod_ut_sup
        AND c.typ_ut_sup=x_typ_ut_sup
      HAVING max(c.no_uee_ut_p1)>0;

    r_no_uee_ut c_no_uee_ut%ROWTYPE;
    v_no_uee_ut_p1      NUMBER;


BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;

    v_etape :='Recherche des colis';
    OPEN c_uee;
    LOOP
        FETCH c_uee into r_uee;
        EXIT WHEN c_uee%NOTFOUND;
        v_etape := 'Recherche du n°max uee dans UT1';
        OPEN c_no_uee_ut(r_uee.no_uee,r_uee.cod_ut_sup,r_uee.typ_ut_sup);
        FETCH c_no_uee_ut into r_no_uee_ut;
        IF c_no_uee_ut%FOUND THEN
           v_no_uee_ut_p1:= r_no_uee_ut.cpt+1;
        ELSE
            v_no_uee_ut_p1:= 1;
        END IF;
        CLOSE c_no_uee_ut;

        v_etape := 'Mise à jour du n° uee dans UT1 sur pc_uee';
        UPDATE PC_UEE
        SET no_uee_ut_p1=v_no_uee_ut_p1
        WHERE no_uee= r_uee.no_uee ;
    END LOOP;
    CLOSE c_uee;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;


/****************************************************************************
*   pc_bas_unlock_pc_rstk -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de dé-verrouiller les résas dans PC_RSTK
-- --
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 03a,27.02.14,mnev    On maintient le champ qte_rdis de pc_rstk.
--                      (liée à la réservation ferme de preordo ligne qui
--                       est redisrtibuée vers une reservation d'ordo
--                       par ligne de commande ...)
-- 02a,29.10.09,rbel    Ajout paramètre p_mode
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON
FUNCTION pc_bas_unlock_pc_rstk (p_cod_usn          su_usn.cod_usn%TYPE,
                                p_cod_verrou       VARCHAR2,
                                p_mode             VARCHAR2    DEFAULT NULL
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_unlock_pc_rstk:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

     -- Déclarations des curseurs
    -- --------------------------
    -- Curseurs sur les reservation de stock en ERREUR.
    CURSOR c_pc_rstk  IS
    SELECT rs.id_res, rs.cod_pss_afc, rs.qte_res, rs.id_res_porl
    FROM pc_rstk rs
    WHERE (rs.cod_err_pc_rstk   IS NOT NULL OR p_mode = 'ALL')  AND
          rs.id_session_lock  = v_session_ora                   AND
          INSTR(rs.lst_fct_lock, ';'||p_cod_verrou||';') > 0;

    r_pc_rstk  c_pc_rstk%ROWTYPE;

    -- Lecture des ligne de reservation
    CURSOR c_det (x_id_res pc_rstk_det.id_res%TYPE) IS
        SELECT qte_res, no_lig_rstk
          FROM pc_rstk_det
         WHERE id_res = x_id_res AND NVL(qte_res, 0) > 0;

    r_det c_det%ROWTYPE;

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;

    OPEN c_pc_rstk;
    LOOP
       FETCH c_pc_rstk INTO r_pc_rstk;
       EXIT WHEN c_pc_rstk%NOTFOUND;

       --On doit supprimer la résa
       v_etape := 'Libere la resa de stock sur Id_res: ' || r_pc_rstk.id_res;
       v_ret := se_bas_libere_rstk (p_no_rstk       => r_pc_rstk.id_res);

       -- gestion de l'erreur
       IF v_ret <> 'OK' THEN
            v_niv_ano:= 2;
            v_cod_err_su_ano := 'PC-ORDO014';
            v_etape := 'Erreur sur libération du stock';
            su_bas_cre_ano (p_txt_ano         => 'ERREUR: ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Id_res',
                        p_par_ano_1       => r_pc_rstk.id_res,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

       ELSE
           --------------------------------------
           v_etape := 'Appel de pc_bas_decrea_uee_id_res';
           --------------------------------------
           v_ret := pc_bas_decrea_uee_id_res (p_id_res      => r_pc_rstk.id_res,
                                              p_cod_pss_afc => r_pc_rstk.cod_pss_afc,
                                              p_qte_libere  => r_pc_rstk.qte_res);

           IF NVL(r_pc_rstk.id_res_porl,0) > 0 THEN
               -- Corrige la resa ferme de preordo ...
               v_etape :=  'Corrige resa ferme preordo';
               OPEN c_det (r_pc_rstk.id_res);
               LOOP
                   FETCH c_det INTO r_det;
                   EXIT WHEN c_det%NOTFOUND;

                   UPDATE pc_rstk_det SET
                       qte_rdis = qte_rdis - r_det.qte_res
                   WHERE id_res = r_pc_rstk.id_res_porl AND no_lig_rstk = r_det.no_lig_rstk;

               END LOOP;
               CLOSE c_det;
           END IF;

           -- Suppression de la resa
           v_etape :=  'Suppression de la resa sur PC_RSTK_DET avec id_res= '|| r_pc_rstk.id_res;
           DELETE FROM pc_rstk_det WHERE pc_rstk_det.id_res = r_pc_rstk.id_res;

           v_etape :=  'Suppression de la resa sur PC_RSTK avec id_res= '|| r_pc_rstk.id_res;
           DELETE FROM pc_rstk WHERE pc_rstk.id_res = r_pc_rstk.id_res;

       END IF;
    END LOOP;
    CLOSE c_pc_rstk;

    v_etape := 'On enlève les verrous ' || p_cod_verrou || ' sur PC_RSTK';
    UPDATE pc_rstk p SET
         lst_fct_lock = su_bas_unlock (p_cod_verrou, p.lst_fct_lock, p.id_session_lock)
    WHERE p.id_session_lock = v_session_ora   AND
          INSTR(p.lst_fct_lock, p_cod_verrou) > 0;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;






/****************************************************************************
*   pc_bas_unlock_pc_lig_com-
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de dé-verrouiller les lignes commandes
-- --
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_cod_verrou
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_unlock_pc_lig_com (p_cod_usn          su_usn.cod_usn%TYPE,
                                   p_cod_verrou       VARCHAR2

    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_unlock_pc_lig_com:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;


BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;

    v_etape := 'On enlève le verrou ' || p_cod_verrou || ' sur PC_LIG_COM';
    UPDATE pc_lig_com l SET
         lst_fct_lock = su_bas_unlock (p_cod_verrou, l.lst_fct_lock, l.id_session_lock)
    WHERE l.id_session_lock  = v_session_ora      AND
         INSTR(l.lst_fct_lock, ';'|| p_cod_verrou||';') > 0;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_calcul_plan_pal -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet d'effectuer le calcul du plan des colis sélectionnés
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 02a,08.10.12,alfl    correction plan apres resa-> prendre que les colis réserves
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_calcul_plan_pal (p_crea_plan        VARCHAR2,
                                 p_cod_verrou       VARCHAR2,
                                 p_mode             VARCHAR2 DEFAULT 'AUTO')
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_plan_pal';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclarations de variables
    v_etat_atv_uee_avant        pc_uee.etat_atv_pc_uee%TYPE;
    v_etat_atv_uee_apres        pc_uee.etat_atv_pc_uee%TYPE;
    v_etat_atv_rstk             pc_rstk.etat_atv_pc_rstk%TYPE;
    v_rowcountuee               NUMBER(10) := 0;

BEGIN

    SAVEPOINT my_sp_pc_bas_calcul_plan_pal;

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || ' ' || v_etape);
    END IF;

    -- Recherche l'etat d'activité
    -- si calcul du plan expédition après resa
    v_etat_atv_uee_avant := su_bas_rch_etat_atv (p_cod_action_atv   => 'CREATION',
                                                 p_nom_table        => 'PC_UEE');
    v_etat_atv_uee_apres := su_bas_rch_etat_atv (p_cod_action_atv   => 'INTEGRATION_PLAN',
                                                 p_nom_table        => 'PC_UEE');

    v_etat_atv_rstk := su_bas_rch_etat_atv (p_cod_action_atv    => 'CREATION',
                                            p_nom_table         => 'PC_RSTK');

    IF su_global_pkv.v_niv_dbg >= 3 THEN
       su_bas_put_debug(v_nom_obj || ' ' || v_etape);
    END IF;

    IF p_crea_plan = pc_ordo_pkv.AVEC_CALCUL_PLAN_AVANT_RESA THEN
        UPDATE pc_uee u SET
            u.etat_atv_pc_uee = v_etat_atv_uee_apres
        WHERE u.id_session_lock = v_session_ora AND
            INSTR(u.lst_fct_lock, p_cod_verrou) > 0 AND
            u.etat_atv_pc_uee = v_etat_atv_uee_avant;
    ELSE

        IF TRUE  THEN
            -- on n'integre que les colis reserves
            v_etape := 'Update PC_UEE';
            UPDATE pc_uee u  SET
                u.etat_atv_pc_uee = v_etat_atv_uee_apres
            WHERE u.id_session_lock = v_session_ora         AND
                INSTR(u.lst_fct_lock, p_cod_verrou) > 0     AND
                u.etat_atv_pc_uee =  v_etat_atv_uee_avant   AND
                EXISTS (SELECT 1 FROM pc_uee_det d ,pc_rstk rs
                WHERE d.no_uee=u.no_uee and d.id_res is not null
                AND  rs.id_res=d.id_res
                AND rs.id_session_lock  = v_session_ora
                AND INSTR(rs.lst_fct_lock, ';'||p_cod_verrou||';') > 0
                AND rs.etat_atv_pc_rstk = v_etat_atv_rstk   );

        ELSE
            -- pour garder eventuellement compatiblité version anterieur
            -- ce cas ne marche pas car on valide le plan seulement avec les colis resrevés
            -- ce qui n'est pas le but
            -------------------------------------------------------------------
            -- On doit flaguer les colis pour lesquels des resas ont été faites
            -- en considérant que si au moins 1 colis d'une lig_com a été réservé
            -- alors l'ensemble des colis de la ligne doit être intégré dans le plan
            v_etape := 'Update PC_UEE';
            UPDATE pc_uee u SET
                u.etat_atv_pc_uee = v_etat_atv_uee_apres
            WHERE u.id_session_lock = v_session_ora         AND
                INSTR(u.lst_fct_lock, p_cod_verrou) > 0     AND
                u.etat_atv_pc_uee =  v_etat_atv_uee_avant   AND
                u.no_uee IN
                (select ud.no_uee from pc_uee_det ud
                 where exists (select 1 from pc_rstk rs
                               where rs.id_session_lock  = v_session_ora                    AND
                                     INSTR(rs.lst_fct_lock, ';'||p_cod_verrou||';') > 0     AND
                                     rs.etat_atv_pc_rstk = v_etat_atv_rstk                  AND
                                     ud.no_com     = rs.ref_rstk_1                          AND
                                     ud.no_lig_com = pc_bas_to_number(rs.ref_rstk_2))
                );
        END IF;

    END IF;
    v_rowcountuee := SQL%ROWCOUNT;

    IF v_rowcountuee > 0 THEN

        v_etape := 'Demande d''intégration dans le plan de ' || TO_CHAR(v_rowcountuee) || ' colis';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
           su_bas_put_debug(v_nom_obj || ' ' || v_etape);
        END IF;
        v_ret := pc_plan_exp_pkg.pc_bas_pal (p_fct_lock  =>p_cod_verrou,
                                             p_mode      =>p_mode);
        IF v_ret <> 'OK' THEN
            RAISE err_except;
        END IF;
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_sp_pc_bas_calcul_plan_pal;
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code verrou',
                        p_par_ano_1       => p_cod_verrou,
                        p_lib_ano_2       => 'Creation plan',
                        p_par_ano_2       => p_crea_plan,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

/* $Id$
****************************************************************************
* pc_bap_VALORDO - Evenement metier standardisé
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction correspond a un evenement metier
--
-- <BAP>
-- <NAME>VALORDO01</>
-- <TITLE>VALIDATION D'UN ORDONNANCEMENT</>
-- <CHAR>COD_USN</>
-- <CHAR>TYP_VAG</>
-- <CHAR>SS_TYP_VAG</>
-- <CHAR>COD_VERROU</>
-- </BAP>
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,28.12.09,mnev    add contexte que si evenement active ...
-- 01a,28.07.09,mnev    initiale
-- 00a,15.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
-- RETOUR
----------
-- resultat du traitement ou ERROR si probleme
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bap_VALORDO01 ( p_cod_usn          su_usn.cod_usn%TYPE,
                            p_typ_vag          pc_vag.typ_vag%TYPE,
                            p_ss_typ_vag       pc_vag.ss_typ_vag%TYPE,
                            p_cod_verrou       VARCHAR2)
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bap_VALORDO01';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_ret               VARCHAR2(1000) := 'OK';

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20) := 'VALORDO01';

BEGIN

    SAVEPOINT my_point_bap_VALORDO01;  -- Pour la gestion de l'exception on fixe un point de rollback.

    /********************
    2) PHASE TRAITEMENT
    ********************/

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN

        v_etape := 'creation ctx';
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_USN', p_cod_usn);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'TYP_VAG', p_typ_vag);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'SS_TYP_VAG', p_ss_typ_vag);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_VERROU', p_cod_verrou);

        v_etape := 'Appel événement ON';
        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_' || v_event);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    v_ret := v_ret_evt;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj|| ' v_ret:' || v_ret);
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_point_bap_VALORDO01;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_usn',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'typ_vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'ss_typ_vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;

/* $Id$
****************************************************************************
* pc_bap_ORDOLIG - Evenement metier standardisé
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction correspond a un evenement metier
--
-- <BAP>
-- <NAME>ORDOLIG01</>
-- <TITLE>ORDONNANCEMENT PARTIEL OU TOTAL LIGNE DE COMMANDE</>
-- <CHAR>COD_USN</>
-- <CHAR>TYP_VAG</>
-- <CHAR>SS_TYP_VAG</>
-- <CHAR>COD_VERROU</>
-- <CHAR>NO_COM</>
-- <NUMBER>NO_LIG_COM</>
-- <CHAR>COD_PSS</>
-- </BAP>
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01c,12.01.10,mnev    corrige le nom de l'evenement
-- 01b,28.12.09,mnev    add contexte que si evenement active ...
-- 01a,28.07.09,mnev    initiale
-- 00a,15.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
-- RETOUR
----------
-- resultat du traitement ou ERROR si probleme
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bap_ORDOLIG01 ( p_cod_usn          su_usn.cod_usn%TYPE,
                            p_typ_vag          pc_vag.typ_vag%TYPE,
                            p_ss_typ_vag       pc_vag.ss_typ_vag%TYPE,
                            p_cod_verrou       VARCHAR2,
                            p_no_com           pc_lig_com.no_com%TYPE,
                            p_no_lig_com       pc_lig_com.no_lig_com%TYPE,
                            p_cod_pss          pc_lig_com.cod_pss_afc%TYPE)
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01c $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bap_ORDOLIG01';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_ret               VARCHAR2(1000) := 'OK';

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20) := 'ORDOLIG01';

BEGIN

    SAVEPOINT my_point_bap_ORDOLIG01;  -- Pour la gestion de l'exception on fixe un point de rollback.

    /********************
    2) PHASE TRAITEMENT
    ********************/

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN

        v_etape := 'creation ctx';
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_USN', p_cod_usn);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'TYP_VAG', p_typ_vag);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'SS_TYP_VAG', p_ss_typ_vag);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_VERROU', p_cod_verrou);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'NO_COM', p_no_com);
        v_add_ctx := su_ctx_pkg.su_bas_set_number(v_ctx,'NO_LIG_COM', p_no_lig_com);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_PSS', p_cod_pss);

        v_etape := 'Appel événement ON';
        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_' || v_event);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    v_ret := v_ret_evt;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj|| ' v_ret:' || v_ret);
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_point_bap_ORDOLIG01;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_usn',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'typ_vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'ss_typ_vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;

/****************************************************************************
*   pc_bas_valid_ordo -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de confirmer l'ordo effectuer des colis
-- qui ont pu être ordonnancés.
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 06a,08.01.15,apie    gestion de la colonne NO_VAG_ORDO 
-- 05c,14.08.14,tcho    remplacement rch_action par rch_action_det dans curseur
-- 05b,26.07.11,alfl    prise en compte colis de reference
-- 05a,06.04.11,mnev    ajout sequence d'ordo dans colis
-- 04a,04.10.10,mnev    ajout controle pulse activite
-- 03a,25.03.10,mnev    gestion de la meta fiche commande
-- 02a,12.01.10,alfl    Appel a la pc_bas_rch_atl_prp (recherche un atelier)
-- 01c,12.01.10,mnev    Ajout evenement pour recherche atelier
-- 01b,17.12.08,mnev    MAJ du statut de ligne commande de ORDM vers PORD
--                      si besoin (cas d'erreur de distribution)
-- 01a,16.02.07,GQUI    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_cod_usn    : code usine
--  p_typ_vag    : type de vague
--  p_ss_typ_vag : sous type de vague
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_valid_ordo (p_cod_usn          su_usn.cod_usn%TYPE,
                            p_typ_vag          pc_vag.typ_vag%TYPE,
                            p_ss_typ_vag       pc_vag.ss_typ_vag%TYPE,
                            p_cod_verrou       VARCHAR2)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 06a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_valid_ordo:';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;

    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    -- Déclarations de variables
    v_etat_atv_uee_avant        pc_uee.etat_atv_pc_uee%TYPE;
    v_etat_atv_uee_apres        pc_uee.etat_atv_pc_uee%TYPE;
    v_etat_atv_uee_det_avant    pc_uee_det.etat_atv_pc_uee_det%TYPE;
    v_etat_atv_uee_det_apres    pc_uee_det.etat_atv_pc_uee_det%TYPE;

    v_lst_etat_atv_lig_com_avant VARCHAR2(1000);
    v_etat_atv_lig_com_apres    pc_lig_com.etat_atv_pc_lig_com%TYPE;

    v_etat_atv_resa             pc_rstk.etat_atv_pc_rstk%TYPE;
    v_no_ordre                  VARCHAR2(10);
    v_cod_atl_prp               su_pss_atl.cod_atl%TYPE;
    v_cod_atl_prp_fct           su_pss_atl.cod_atl%TYPE;
    v_cod_pss_ec                su_pss_atl.cod_pss%TYPE:=NULL;
    v_etat_pal_ut               VARCHAR2(10) := NULL;

    -- Déclarations des curseurs
    -- --------------------------
    -- Curseurs sur les colis
    CURSOR c_val (x_etat_atv_uee      pc_uee.etat_atv_pc_uee%TYPE,
                  x_etat_atv_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
    SELECT u.cod_pss_afc,
           ud.no_com, ud.no_lig_com,
           SUM(ud.nb_pce_theo) nb_pce_theo, SUM(ud.pds_theo) pds_theo,
           SUM(DECODE(u.typ_uee,'CD',ud.nb_pce_theo/u.nb_pce_theo,u.nb_col_theo)) nb_col_theo
    FROM pc_uee u, pc_uee_det ud
    WHERE u.no_uee          = ud.no_uee                        AND
          u.cod_err_pc_uee       IS NULL                       AND
          ud.cod_err_pc_uee_det  IS NULL                       AND
          u.etat_atv_pc_uee  = x_etat_atv_uee                  AND
          u.id_session_lock  = v_session_ora                   AND
          INSTR(u.lst_fct_lock, ';'||p_cod_verrou||';') > 0    AND
          ud.etat_atv_pc_uee_det = x_etat_atv_uee_det
    GROUP BY u.cod_pss_afc, ud.no_com, ud.no_lig_com;

    r_val c_val%ROWTYPE;

    -- Curseurs sur les colis
    CURSOR c_uee_det (x_etat_atv_uee      pc_uee.etat_atv_pc_uee%TYPE,
                      x_etat_atv_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE) IS
    SELECT u.no_uee,
           u.rowid  rowid_u,
           u.cod_pss_afc,
           ud.id_res, ud.no_com, ud.no_lig_com,
           ud.cod_pro_res, ud.cod_va_res, ud.cod_vl_res,
           ud.rowid rowid_ud
    FROM pc_uee u, pc_uee_det ud
    WHERE u.no_uee          = ud.no_uee                        AND
          u.cod_err_pc_uee       IS NULL                       AND
          ud.cod_err_pc_uee_det  IS NULL                       AND
          u.etat_atv_pc_uee  = x_etat_atv_uee                  AND
          u.id_session_lock  = v_session_ora                   AND
          INSTR(u.lst_fct_lock, ';'||p_cod_verrou||';') > 0    AND
          ud.etat_atv_pc_uee_det = x_etat_atv_uee_det
    ORDER BY u.cod_pss_afc ASC, u.no_uee ASC;

    r_uee_det  c_uee_det%ROWTYPE;

    -- Curseur sur les lignes commandes
    CURSOR c_lig_com ( x_lst_etat_atv_lig     pc_lig_com.etat_atv_pc_lig_com%TYPE) IS
    SELECT l.no_com, l.no_lig_com, l.etat_atv_pc_lig_com,
           MIN(su_bas_rch_action_det('ETAT_ATV_PC_UEE_DET', u.etat_atv_pc_uee_det, NULL, 1)) no_ordre_min
    FROM pc_lig_com l, pc_uee_det u  ,pc_uee e
    WHERE l.id_session_lock  = v_session_ora                   AND
          INSTR(l.lst_fct_lock, ';'||p_cod_verrou||';') > 0    AND
          INSTR(x_lst_etat_atv_lig, ';' ||  l.etat_atv_pc_lig_com || ';') > 0     AND
          l.cod_err_pc_lig_com IS NULL                         AND
          l.no_com = u.no_com                                  AND
          l.no_lig_com = u.no_lig_com
          AND u.no_uee=e.no_uee
          AND   (e.no_uee != NVL(e.no_uee_ref,'#NULL#') OR u.qte_theo > 0)
          GROUP BY l.no_com, l.no_lig_com, l.etat_atv_pc_lig_com;

    r_lig_com  c_lig_com%ROWTYPE;

    -- Curseur sur l'atelier du process
    CURSOR c_pss_atl (x_cod_pss    su_pss_atl.cod_pss%TYPE) IS
    SELECT s.cod_atl
    FROM su_pss_atl s
    WHERE s.cod_pss = x_cod_pss
    ORDER BY s.no_ord ASC;

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;


    v_dat_activite      DATE := NULL;

    v_no_vag_ordo pc_uee.no_vag_ordo%TYPE := NULL;

BEGIN

    v_etape := 'Debut trait.';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;

    -- Recherche l'etat d'activité des colis UEE avant
    v_etat_atv_uee_avant := su_bas_rch_etat_atv (p_cod_action_atv   => 'VALIDATION_PLAN',
                                                 p_nom_table        => 'PC_UEE');

    -- Recherche l'etat d'activité des colis UEE après
    v_etat_atv_uee_apres := su_bas_rch_etat_atv (p_cod_action_atv=> 'ORDO_FINALISE',
                                                 p_nom_table     => 'PC_UEE');

    -- Recherche l'etat d'activité des colis détail UEE_DET avant
    v_etat_atv_uee_det_avant := su_bas_rch_etat_atv (p_cod_action_atv   => 'RESERVATION_STOCK',
                                                     p_nom_table        => 'PC_UEE_DET');

    -- Recherche l'etat d'activité des colis détail UEE_DET après
    v_etat_atv_uee_det_apres := su_bas_rch_etat_atv (p_cod_action_atv   => 'ORDO_FINALISE',
                                                     p_nom_table        => 'PC_UEE_DET');

    -- Recherche le no d'ordre de l'etat d'activité de UEE_DET apres
    v_no_ordre := su_bas_rch_action (p_nom_par      =>'ETAT_ATV_PC_UEE_DET',
                                     p_par          =>v_etat_atv_uee_det_apres,
                                     p_cod_module   =>'SU',
                                     p_no_action    =>1);

    -- Recherche l'etat d'activité des LIG_COM avant
    v_lst_etat_atv_lig_com_avant :=  ';' ||
                                     su_bas_rch_etat_atv (p_cod_action_atv  => 'QUALIF_ORDO',
                                                          p_nom_table       => 'PC_LIG_COM') || ';';

    v_lst_etat_atv_lig_com_avant :=  v_lst_etat_atv_lig_com_avant ||
                                     su_bas_rch_etat_atv (p_cod_action_atv  => 'VALIDATION_ORDO_MAN',
                                                          p_nom_table       => 'PC_LIG_COM') || ';';

    -- Recherche l'etat d'activité des LIG_COM après
    v_etat_atv_lig_com_apres := su_bas_rch_etat_atv (p_cod_action_atv   => 'ORDO_TERM',
                                                     p_nom_table        => 'PC_LIG_COM');

    -- Recherche l'etat d'activité des resas
    v_etat_atv_resa := su_bas_rch_etat_atv (p_cod_action_atv    => 'CONFIRMATION',
                                            p_nom_table         => 'PC_RSTK');


    v_etape := 'LOOP pour evt par lig_com/pss';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;
    OPEN c_val(v_etat_atv_uee_avant, v_etat_atv_uee_det_avant);
    LOOP
        FETCH c_val INTO r_val;
        EXIT WHEN c_val%NOTFOUND;

        v_etape := 'Création enregistrement dans journal de préparation';
        v_ret := pc_bas_cre_pc_his (p_typ  => 'COM',
                                    p_cle1 => r_val.no_com,
                                    p_cle2 => r_val.no_lig_com,
                                    p1     => TO_CHAR(r_val.nb_col_theo,'99999999.990'),
                                    p2     => TO_CHAR(r_val.nb_pce_theo),
                                    p3     => TO_CHAR(r_val.pds_theo,'99999999.990'),
                                    p4     => r_val.cod_pss_afc,
                                    p5     => p_ss_typ_vag,
                                    p_act  =>'PC_HIS_ORD_LIG_COM');

        -- generation de la meta fiche commande
        v_etape := 'creation meta fiche commande';
        v_ret := pc_bas_maj_tmp_com (p_no_com => r_val.no_com,
                                     p_no_lig_com => r_val.no_lig_com);

        -- appel evenement metier
        v_etape := 'validation d''ordonnancement';
        v_ret := pc_bap_ORDOLIG01 (p_cod_usn => p_cod_usn,
                                   p_typ_vag => p_typ_vag,
                                   p_ss_typ_vag => p_ss_typ_vag,
                                   p_cod_verrou => p_cod_verrou,
                                   p_no_com     => r_val.no_com,
                                   p_no_lig_com => r_val.no_lig_com,
                                   p_cod_pss    => r_val.cod_pss_afc);

    END LOOP;
    CLOSE c_val;

    v_etape := 'LOOP sur pc_uee_det';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;
    OPEN c_uee_det(v_etat_atv_uee_avant, v_etat_atv_uee_det_avant);
    LOOP
        FETCH c_uee_det INTO r_uee_det;
        EXIT WHEN c_uee_det%NOTFOUND;

        -- $MOD APIE 6a
        IF v_no_vag_ordo IS NULL THEN
            SELECT SEQ_NO_ORDO.NEXTVAL INTO v_no_vag_ordo FROM DUAL;
        END IF;

        v_etape := 'Controle activite:' || su_global_pkv.v_cod_ope;
        su_bas_ctl_activity(su_global_pkv.v_cod_ope, v_dat_activite);

        v_etape := 'Rch atelier prépa du process afc, cod_pss= : ' ||  r_uee_det.cod_pss_afc;
        v_ret:=pc_bas_ord_rch_atl_prp (p_cod_pss    =>r_uee_det.cod_pss_afc,
                                       p_no_uee     =>r_uee_det.no_uee,
                                       p_no_com     =>r_uee_det.no_com,
                                       p_no_lig_com =>r_uee_det.no_lig_com,
                                       p_cod_pro_res=>r_uee_det.cod_pro_res,
                                       p_cod_va_res =>r_uee_det.cod_va_res,
                                       p_cod_vl_res =>r_uee_det.cod_vl_res,
                                       p_cod_atl_prp=>v_cod_atl_prp_fct);
        IF v_ret !='OK' THEN
            RAISE err_except;
        END IF;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || v_etape|| ' cod_atl fct= '|| v_cod_atl_prp_fct);
        END IF;

        IF v_cod_atl_prp_fct IS NULL THEN

            IF r_uee_det.cod_pss_afc <> NVL(v_cod_pss_ec,'$') THEN
                v_cod_pss_ec := r_uee_det.cod_pss_afc;
                v_etape := 'Rch atelier prépa du process standard, cod_pss= ' ||  v_cod_pss_ec;

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj || v_etape);
                END IF;

                OPEN c_pss_atl (r_uee_det.cod_pss_afc);
                FETCH c_pss_atl INTO v_cod_atl_prp;
                CLOSE c_pss_atl;

            END IF;

        ELSE
            v_cod_atl_prp:=v_cod_atl_prp_fct;
        END IF;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || 'atelier : ' || v_cod_atl_prp);
        END IF;

        v_etape := ' Update PC_UEE_DET ';

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || v_etape||' etat apres='||v_etat_atv_uee_det_apres);
        END IF;

        UPDATE pc_uee_det
           SET etat_atv_pc_uee_det = v_etat_atv_uee_det_apres,
               cod_atl_prp         = v_cod_atl_prp
        WHERE pc_uee_det.rowid = r_uee_det.rowid_ud;

        v_etape := 'Update PC_UEE';
        UPDATE pc_uee
           SET etat_atv_pc_uee = v_etat_atv_uee_apres,
               cod_atl_prp = v_cod_atl_prp,
               dat_ordo = SYSDATE,
               no_seq_ordo = SEQ_NO_ORDO.NEXTVAL,
               no_vag_ordo = v_no_vag_ordo -- $MOD APIE 6a 
        WHERE pc_uee.rowid = r_uee_det.rowid_u;

        IF r_uee_det.id_res IS NOT NULL THEN
            v_etape := 'On confirme la resa id_res: ' || TO_CHAR(r_uee_det.id_res) || ' sur Com-Lig: ' ||
                       r_uee_det.no_com || '-' || TO_CHAR(r_uee_det.no_lig_com);
            UPDATE pc_rstk SET
                etat_atv_pc_rstk = v_etat_atv_resa
            WHERE pc_rstk.id_res = r_uee_det.id_res;
        END IF;

        --Permet d'alerter une activité cible
        pc_ordo_pkv.ALERT_ATV_CIBLE := TRUE;

    END LOOP;
    CLOSE c_uee_det;

    -- On change l'état d'activité de la ligne si toute la ligne
    -- a été ordonnancée
    v_etape := 'LOOP sur pc_lig_com';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;
    OPEN c_lig_com (v_lst_etat_atv_lig_com_avant);
    LOOP
        FETCH c_lig_com INTO r_lig_com;
        EXIT WHEN c_lig_com%NOTFOUND;

        -- Test si tous les colis ont été ordonnancé
        IF r_lig_com.no_ordre_min >= v_no_ordre THEN
            v_etape := 'Update PC_LIG_COM Com-lig: '  || r_lig_com.no_com ||
                                                 '-' || r_lig_com.no_lig_com;
            UPDATE pc_lig_com SET
                etat_atv_pc_lig_com = v_etat_atv_lig_com_apres
            WHERE pc_lig_com.no_com     = r_lig_com.no_com AND
                  pc_lig_com.no_lig_com = r_lig_com.no_lig_com;

        ELSIF r_lig_com.etat_atv_pc_lig_com = su_bas_rch_etat_atv ('VALIDATION_ORDO_MAN','PC_LIG_COM') THEN

            v_etape := 'Mise à jour de l''état pc_lig_com';

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || v_etape);
            END IF;

            UPDATE pc_lig_com SET
                etat_atv_pc_lig_com = su_bas_rch_etat_atv ('QUALIF_ORDO','PC_LIG_COM')
            WHERE pc_lig_com.no_com     = r_lig_com.no_com AND
                  pc_lig_com.no_lig_com = r_lig_com.no_lig_com;

        END IF;

    END LOOP;
    CLOSE c_lig_com;

    -- appel evenement metier
    v_etape := 'validation d''ordonnancement';
    v_ret := pc_bap_VALORDO01 (p_cod_usn => p_cod_usn,
                               p_typ_vag => p_typ_vag,
                               p_ss_typ_vag => p_ss_typ_vag,
                               p_cod_verrou => p_cod_verrou);

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        IF c_uee_det%ISOPEN THEN
            CLOSE c_uee_det;
        END IF;

        IF c_lig_com%ISOPEN THEN
            CLOSE c_lig_com;
        END IF;
        v_cod_err_su_ano := 'PC-ORDO000';
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'Type Vag',
                        p_par_ano_2       => p_typ_vag,
                        p_lib_ano_3       => 'SS_Typ Vag',
                        p_par_ano_3       => p_ss_typ_vag,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
       RETURN 'ERROR';
END;

END; -- fin du package
/
show errors;
