/* $Id$ */
CREATE OR REPLACE
PACKAGE BODY pc_aff_pkg AS

/* $Id$
****************************************************************************
* pc_bas_aff_auto_aff  - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'affecter des colis en mode auto affecté sans régulation
-- mode_aff_uee = '3' du colis
--
-- PARAMETRES :
-- ------------
--  xxx
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01d,17.10.12,alfl    suppression de su_bas_ala_marche
-- 01c,29.07.11,rbel    passage mode_rgp_ops en table
-- 01b,09.07.09,mnev    commit en fin de traitement.
-- 01a,14.05.07,rbel    creation
-- 00a,14.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
-- OK, ERROR 
--
-- COMMIT :
-- --------
-- OUI    

FUNCTION pc_bas_aff_auto_aff (    
    p_cle_rg               su_atv_rg.cle_rg%TYPE,
    p_typ_cle_rg           su_atv_rg.cod_atv%TYPE,
    p_cod_atv              su_atv.cod_atv%TYPE,
    p_cod_usn              su_usn.cod_usn%TYPE,
    p_evt                   VARCHAR2
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01d $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_aff_auto_aff';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'NONE';
    v_ret_trt           VARCHAR2(100) := NULL; 
    v_ret_evt           VARCHAR2(20)  := NULL;
    
    CURSOR c_pss (
                  x_cod_usn         pc_uee.cod_usn%TYPE,
                  x_cod_atv         su_pss_atv.cod_atv%TYPE
                 ) IS
        SELECT DISTINCT s.cod_pss, s.val_cle_atv no_pos_auto_aff
        FROM su_pss, su_pss_atv_cfg s
           WHERE su_pss.cod_usn = x_cod_usn AND
              s.cod_pss = su_pss.cod_pss AND
              s.cod_atv = x_cod_atv AND
              s.cod_cfg_atv = 'NO_POS_AUTO_AFF' AND
              s.val_cle_atv IS NOT NULL AND
              NOT EXISTS (SELECT 1 
                            FROM su_atv_rg
                           WHERE cod_usn = x_cod_usn AND
                                 cod_atv = x_cod_atv AND
                                 typ_cle_rg = 'P' AND
                                 cle_rg = s.val_cle_atv AND
                                 typ_tst_seuil <> 'sans');

    -- Recherche les colis en mode auto affecté
    CURSOR c_uee (x_etat_atv_pc_uee pc_uee.etat_atv_pc_uee%TYPE,
                  x_mode_aff_uee    pc_uee.mode_aff_uee%TYPE,
                  x_cod_usn         pc_uee.cod_usn%TYPE,
                  x_cod_pss         pc_uee.cod_pss_afc%TYPE) IS
        SELECT a.cod_pss_afc, 
               a.cod_pss_afc || DECODE(c.grp_commit_auto_aff, 'UT',NVL(NVL(b.cod_ut_sup,a.cod_ut_sup),'#NULL#'),
                                                              'COM', a.no_com,
                                                              'PSS',a.cod_pss_afc,
                                                              'FIN') cle,
               a.no_rmp, a.cod_usn, cod_grp_aff 
        FROM   pc_uee a, pc_ut b, v_pc_cfg_rgp_ops_usn c
       	WHERE  a.etat_atv_pc_uee = x_etat_atv_pc_uee --REGP
		AND    a.mode_aff_uee = x_mode_aff_uee 
		AND    a.cod_usn = x_cod_usn
	    AND    a.cod_err_pc_uee IS NULL
        AND    a.cod_pss_afc = x_cod_pss
        AND    a.cod_ut_sup = b.cod_ut AND a.typ_ut_sup = b.typ_ut
        AND    c.mode_rgp_ops = su_bas_rch_cle_atv_pss_2 (a.cod_pss_afc,'PIC','MODE_RGP_OPS')
        AND    c.cod_usn = a.cod_usn
        GROUP BY a.cod_pss_afc, 
                 a.cod_pss_afc || DECODE(c.grp_commit_auto_aff, 'UT',NVL(NVL(b.cod_ut_sup,a.cod_ut_sup),'#NULL#'),
                                                                'COM', a.no_com,
                                                                'PSS',a.cod_pss_afc,
                                                                'FIN'),
                 a.no_rmp, a.cod_usn, cod_grp_aff
        ORDER BY 1, 2;

    r_uee                       c_uee%ROWTYPE;

    v_last_cle                  VARCHAR2(20) := NULL;            
    v_etat_atv_pc_uee_sel1      pc_uee.etat_atv_pc_uee%TYPE;
    v_mode_aff_uee              pc_uee.mode_aff_uee%TYPE;
    v_cle_regul                 su_atv_cfg.val_cle_atv%TYPE;
    v_cle_regul_av              su_atv_cfg.val_cle_atv%TYPE;
    v_dum                       NUMBER;
    
    r_atv_rg                    su_atv_rg%ROWTYPE;

BEGIN

    SAVEPOINT my_pc_bas_aff_auto_aff;  -- Pour la gestion de l'exception on fixe un point de rollback.

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj
                         ||' : cle_rg = '       || p_cle_rg
                         ||' : p_cod_atv = '    || p_cod_atv
                         ||' : p_cod_usn = '    || p_cod_usn
                         ||' : p_typ_cle_rg = ' || p_typ_cle_rg
                         ||' : p_evt = '        || p_evt);
    END IF;

    /************************
    1) PHASE INITIALISATION 
    ************************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code pré-standard (initialisation de variables)


    -- Fin du code pré-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_AFF_AUTO_AFF') THEN 
        v_ret_evt := pc_evt_aff_auto_aff('PRE' , 
                                      p_cle_rg ,
                                      p_cod_atv,
                                      p_cod_usn,
                                      p_typ_cle_rg,
                                      p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT 
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_AFF_AUTO_AFF') THEN 
        v_ret_evt := pc_evt_aff_auto_aff('ON' , 
                                      p_cle_rg ,
                                      p_cod_atv,
                                      p_cod_usn,
                                      p_typ_cle_rg,
                                      p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        -- ---------------------------------------------------------------------
        v_etape := 'Début';

        -- -------------------------------------
        -- Mode 3 : auto affecté sans régulation 
        -- -------------------------------------
        v_mode_aff_uee := '3';

        v_etat_atv_pc_uee_sel1 := su_bas_rch_etat_atv (p_cod_action_atv => 'SELECTION_AFFECTATION',
                                                       p_nom_table      => 'PC_UEE');
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj || ' etat_sel1= ' || v_etat_atv_pc_uee_sel1);
        END IF;

        v_etape := 'Boucle sur les process auto_affecté';
        FOR r_pss IN c_pss (p_cod_usn, p_cod_atv) LOOP
            
            v_etape := 'Rch uee pour process ' || r_pss.cod_pss || ' poste=' || r_pss.no_pos_auto_aff;
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || v_etape);
            END IF;
            
            r_atv_rg.cle_rg := r_pss.no_pos_auto_aff;
            r_atv_rg.typ_cle_rg := 'P';
            v_last_cle := NULL;
        
            OPEN c_uee(v_etat_atv_pc_uee_sel1, v_mode_aff_uee, p_cod_usn, r_pss.cod_pss);
            LOOP
                FETCH c_uee INTO r_uee;
                IF c_uee%NOTFOUND THEN
                    v_etape := 'commit sur notfound';
                    COMMIT;
                    SAVEPOINT my_pc_bas_aff_auto_aff;  -- Pour la gestion de l'exception on fixe un point de rollback.
                    EXIT;
                END IF;

                IF v_last_cle IS NULL THEN
                    -- 1ere fois ...
                    v_last_cle := r_uee.cle;

                ELSIF NVL(r_uee.cle,'#NULL#') <> NVL(v_last_cle,'#NULL#') THEN
                    v_etape := 'commit intermediaire';
                    COMMIT;
                    SAVEPOINT my_pc_bas_aff_auto_aff;  -- Pour la gestion de l'exception on fixe un point de rollback.
                    v_last_cle  := r_uee.cle;
                END IF;

                v_etape:= 'Traitement affectation colis';
                v_ret := pc_aff_pkg.pc_bas_trait_aff_uee_pos (p_cod_grp_aff=>r_uee.cod_grp_aff,
                                                              pr_atv_rg    =>r_atv_rg);

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_etape||' v_ret '||v_ret);
                    su_bas_put_debug(v_etape||' v_cod_grp_aff '||r_uee.cod_grp_aff);
                END IF;
            
                IF v_ret <> 'OK' THEN
                    -------------------
                    -- Monte une alarme
                    -------------------
                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_niv_ano         => 2,
                        p_cod_usn         => p_cod_usn,
                        p_lib_ano_1       => 'p_cle_rg',
                        p_par_ano_1       => p_cle_rg,
                        p_lib_ano_2       => 'p_typ_cle_rg',
                        p_par_ano_2       => p_typ_cle_rg,
                        p_lib_ano_3       => 'p_cod_atv',
                        p_par_ano_3       => p_cod_atv,
                        p_lib_ano_4       => 'p_cod_usn',
                        p_par_ano_4       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_AFF_UEE_POS');
                                                
                END IF;    
                                                
            END LOOP;

            CLOSE c_uee;

        END LOOP;

        -- Fin du code standard 
        -- ---------------------------------------------------------------------
    END IF;

    /**********************
    3) PHASE FINALISATION 
    **********************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code post-standard


    -- Fin du code post-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_AFF_AUTO_AFF') THEN 
        v_ret_evt := pc_evt_aff_auto_aff('POST' , 
                                      p_cle_rg ,
                                      p_cod_atv,
                                      p_cod_usn,
                                      p_typ_cle_rg,
                                      p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    COMMIT;
    
    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_pc_bas_aff_auto_aff;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cle_rg',
                        p_par_ano_1       => p_cle_rg,
                        p_lib_ano_2       => 'p_typ_cle_rg',
                        p_par_ano_2       => p_typ_cle_rg,
                        p_lib_ano_3       => 'p_cod_atv',
                        p_par_ano_3       => p_cod_atv,
                        p_lib_ano_4       => 'p_cod_usn',
                        p_par_ano_4       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;


/* 
****************************************************************************
* pc_bas_trait_rg - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de gérer le traitement de l'affectation
--
-- PARAMETRES :
-- ------------
--  p_cle_rg
--  p_typ_cle_rg
--  p_cod_atv
--  p_cod_usn
--  p_evt
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,01.10.09,rbel    Mise en commentaire de l'analyse colis, fait directement
--                      dans le tableau de pilotage
-- 01a,24.04.07,JDRE    initialisation
-- 00a,24.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  NONE        : Rien trouvé
--  OK_CONTINUE : Trouvé mais insuffisant
--  OK_WAIT     : Trouvé et suffisant
--  ERROR       : Erreur
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_trait_rg   (p_cle_rg               su_atv_rg.cle_rg%TYPE,
                            p_typ_cle_rg           su_atv_rg.typ_cle_rg%TYPE,
                            p_cod_atv              su_atv_rg.cod_atv%TYPE,
                            p_cod_usn              su_atv_rg.cod_usn%TYPE,
                            p_par_tsk_fond_3       su_tsk_fond.par_tsk_fond_3%TYPE,
                            p_par_tsk_fond_4       su_tsk_fond.par_tsk_fond_4%TYPE,
                            p_par_tsk_fond_5       su_tsk_fond.par_tsk_fond_5%TYPE,
                            p_evt                  VARCHAR2)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_trait_rg';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;
    v_mode_aff_uee      su_atv_cfg.val_cle_atv%TYPE := NULL;
		    
BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_cle_rg = '    || p_cle_rg
                                  ||' : typ_cle_rg = '  || p_typ_cle_rg
                                  ||' : cod_atv = '     || p_cod_atv
                                  ||' : cod_usn = '     || p_cod_usn
                                  ||' : evt = '         || p_evt);
    END IF;
    
    IF p_evt='PRE' THEN
        --------------------
        -- Traitement PRE --
        --------------------
        v_etape := 'Traitement évènement PRE';
		v_ret := 'OK_WAIT';

        
    ELSIF p_evt= 'ON' THEN
        -------------------
        -- Traitement ON --
        -------------------
        v_etape := 'raz contexte';
        pc_pic_pkv.vt_cle_pic.DELETE;

        v_etape := 'evenement ON : Traitement affectation regulee';
		-- affectation colis par regulation de charge ou auto affecte
		-- affectation des colis mode = '2' ou '3'
		v_ret := pc_aff_pkg.pc_bas_aff_regul (p_cle_rg     => p_cle_rg,
                                              p_typ_cle_rg => p_typ_cle_rg,
                                              p_cod_atv    => p_cod_atv,
                                              p_cod_usn    => p_cod_usn,
             		   						  p_evt		   => p_evt); 
								   
    ELSIF p_evt='POST' THEN
        ---------------------
        -- Traitement POST --
        ---------------------
        v_etape := 'raz contexte';
        pc_pic_pkv.vt_cle_pic.DELETE;

        v_etape := 'evenement POST : Traitement affectation bordereau';
		-- affectation colis en mode bordereau (COMMIT)
		v_ret := pc_bas_aff_bord (p_cle_rg     => p_cle_rg,
                                  p_typ_cle_rg => p_typ_cle_rg,
                                  p_cod_atv    => p_cod_atv,
                                  p_cod_usn    => p_cod_usn,
		   						  p_evt		   => p_evt); 
        
        v_etape := 'evenement POST : Traitement auto affecté sans régulation';
		-- affectation colis en mode bordereau (COMMIT)
		v_ret := pc_bas_aff_auto_aff (p_cle_rg     => p_cle_rg,
                                      p_typ_cle_rg => p_typ_cle_rg,
                                      p_cod_atv    => p_cod_atv,
                                      p_cod_usn    => p_cod_usn,
		   						      p_evt		   => p_evt);

        IF su_global_pkv.vt_evt_actif.exists('ON_PC_AFF_TRT') THEN 
            v_etape := 'Evènement ON de l''évènement POST';
            v_ret_evt := pc_evt_aff_traitement ('ON' , p_cle_rg,p_typ_cle_rg,p_cod_atv,p_cod_usn);
			
            IF v_ret_evt = 'ERROR' THEN
                RAISE err_except;
            END IF;
        ELSE
            v_ret_evt := NULL;
        END IF;
	
	    IF v_ret_evt IS NULL THEN
		      NULL;
	    END IF;
    END IF;		
		
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||' retour v_ret = '   || v_ret);
    END IF;
	
    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cle_rg',
                        p_par_ano_1       => p_cle_rg,
                        p_lib_ano_2       => 'typ_cle_rg',
                        p_par_ano_2       => p_typ_cle_rg,
                        p_lib_ano_3       => 'cod_atv',
                        p_par_ano_3       => p_cod_atv,
                        p_lib_ano_4       => 'cod_usn',
                        p_par_ano_4       => p_cod_usn,
                        p_lib_ano_5       => 'evt',
                        p_par_ano_5       => p_evt,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';						        
END;

/* 
****************************************************************************
* pc_bas_trait_aff_uee_pos - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de gérer le traitement de l'affectation du colis
--
-- PARAMETRES :
-- ------------
--  p_no_uee 
--  pr_atv_rg 
--  p_no_ss_serie 
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03c,01.10.14,mnev    Force la sortie en NTO FOUND si probleme de config pic    
-- 03b,05.03.14,mnev    Exclusion des lignes interrompues
-- 03a,06.04.11,mnev    mise a jour de dat_aff dans pc_uee
-- 02f,25.02.10,alfl    ne pas modifier etat uee det si superieur ou egal a PRPO
-- 02d,23.10.09,mnev    Correction sur le NOT EXISTS de synchro process
-- 02c,16.09.09,rbel    Mémorisation du no_of en cours sur le poste dans PC_UEE
--                      Envoi au poste N1 des colis affectés suivant clef process
-- 02b,30.03.09,imaa    synchronisation des process 
-- 02a,04.03.09,croc    gestion des séries 
-- 01a,24.04.07,jdre    initialisation
-- 00a,24.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK 
--  ERROR 
--	NOTFOUND
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_trait_aff_uee_pos (p_cod_grp_aff       pc_uee.cod_grp_aff%TYPE,
                                   pr_atv_rg           su_atv_rg%ROWTYPE,								   
								   p_no_ss_serie       pc_uee.no_ss_serie%TYPE DEFAULT NULL,
								   p_no_ord_ss_serie   pc_uee.no_ss_serie%TYPE  DEFAULT NULL,
                                   p_no_of             gp_ent_of.no_of%TYPE DEFAULT NULL
)  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03c $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_trait_aff_uee_pos';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;
    
	-- curseur colis
	CURSOR c_pc_uee_aff IS
	SELECT u.no_uee, u.cod_usn, u.no_rmp
	FROM   pc_uee u
	WHERE  u.cod_grp_aff = p_cod_grp_aff
	AND    u.cod_err_pc_uee IS NULL;

    CURSOR c_pc_uee (x_etat_synchro   NUMBER) IS
    SELECT u.no_uee, u.cod_usn, u.no_rmp, u.cod_pss_afc
    FROM pc_uee u, su_pss_atv_cfg x, su_atv y
    WHERE u.cod_grp_aff = p_cod_grp_aff
    AND u.cod_err_pc_uee IS NULL
    AND x.cod_cfg_atv = 'SYNCHRO_SUR_LST_PSS' 
    AND y.typ_atv = 'AFF' 
    AND x.cod_atv = y.cod_atv
    AND x.cod_pss = u.cod_pss_afc
    AND NOT EXISTS (
          SELECT b.no_uee
            FROM pc_uee b
            WHERE b.cod_ut_sup = u.cod_ut_sup AND b.typ_ut_sup = u.typ_ut_sup 
                  AND INSTR (x.val_cle_atv, b.cod_pss_afc) > 0
                  AND su_bas_etat_val_num(b.etat_atv_pc_uee,'PC_UEE') < x_etat_synchro)
    AND NOT EXISTS ( SELECT b.no_uee
                     FROM   pc_uee b, pc_ut t2, pc_ut t1 
                     WHERE  t1.cod_ut     = u.cod_ut_sup
                     AND    t1.typ_ut     = u.typ_ut_sup
                     AND    t1.cod_ut_sup = t2.cod_ut_sup
                     AND    t1.typ_ut_sup = t2.typ_ut_sup
                     AND    t2.cod_ut     = b.cod_ut_sup
                     AND    t2.typ_ut     = b.typ_ut_sup 
                     AND    INSTR (x.val_cle_atv, b.cod_pss_afc) > 0
                     AND    su_bas_etat_val_num(b.etat_atv_pc_uee,'PC_UEE') < x_etat_synchro);
	
	r_pc_uee c_pc_uee%ROWTYPE;

    v_etat_uee_det_prp0    NUMBER;                               
	v_etat_atv_pc_uee      pc_uee.etat_atv_pc_uee%TYPE;
	v_etat_atv_pc_uee_det  pc_uee_det.etat_atv_pc_uee_det%TYPE;
	v_etat_atv_iter        pc_uee_det.etat_atv_pc_uee_det%TYPE;
	v_no_uee               pc_uee.no_uee%TYPE;
	v_dum                  NUMBER;
    v_no_rampe             pc_ut.no_rmp%TYPE;
    v_pc_uee_found         BOOLEAN;
    
    v_etat_trf_uee_pos     su_pss_atv_cfg.val_cle_atv%TYPE := '0';
	
BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : cod_grp_aff = '        || p_cod_grp_aff
                                  ||' : typ_cle_rg = '         || pr_atv_rg.typ_cle_rg 
                                  ||' : cle_rg = '             || pr_atv_rg.cle_rg);
		su_bas_put_debug(v_nom_obj||' : p_no_ss_serie = '      || p_no_ss_serie
                                  ||' : p_no_ord_ss_serie = '  || p_no_ord_ss_serie);                                  					  								  								  
    END IF;

    
    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_PC_TRAIT_AFF_UEE_POS') THEN 
        v_ret_evt := pc_evt_trait_aff_uee_pos ('PRE' ,p_cod_grp_aff,pr_atv_rg);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT 
    ********************/
    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_PC_TRAIT_AFF_UEE_POS') THEN 
        v_ret_evt := pc_evt_trait_aff_uee_pos ('ON' ,p_cod_grp_aff,pr_atv_rg);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        v_etape := 'Début';
		v_etat_atv_pc_uee     := su_bas_rch_etat_atv (p_cod_action_atv => 'AFFECTATION_POSTE',
										              p_nom_table	   => 'PC_UEE');
		v_etat_atv_pc_uee_det := su_bas_rch_etat_atv (p_cod_action_atv => 'AFFECTATION_POSTE',
										              p_nom_table	   => 'PC_UEE_DET');
	
        -- -------------------------------------------------------------
		-- Affecter toutes les lignes-colis du groupe au poste demandeur
        -- -------------------------------------------------------------
		IF su_global_pkv.v_niv_dbg >= 6 THEN
		    su_bas_put_debug(v_nom_obj ||
				 ' etat_uee = ' || v_etat_atv_pc_uee ||
				 ' etat_uee_det = ' || v_etat_atv_pc_uee_det);

		    su_bas_put_debug(v_nom_obj ||
				 ' affectation colis code regroupement = ' || p_cod_grp_aff);
		END IF;
        
        v_etape := 'open c_pc_uee';
		OPEN c_pc_uee(su_bas_etat_val_num ('SYNCHRO_PSS','PC_UEE'));
		FETCH c_pc_uee INTO r_pc_uee; -- Un seul fetch pour extraire un colis du groupe
        v_pc_uee_found := c_pc_uee%FOUND;
		IF c_pc_uee%FOUND THEN 
			IF su_global_pkv.v_niv_dbg >= 6 THEN
			   su_bas_put_debug(v_nom_obj ||' : affectation colis  = '|| 
                                r_pc_uee.no_uee || ' : p_no_pos = ' || 
                                pr_atv_rg.cle_rg);
			END IF;									
			--
			IF pc_bas_maj_pic_grp (r_pc_uee.no_uee,pr_atv_rg.cle_rg, r_pc_uee.cod_pss_afc, p_cod_grp_aff) <> 'OK' THEN
			
			    v_etape := 'PB mise à jour no_pos_pic sur colis '|| r_pc_uee.no_uee;
                -- Mettre tous les colis du groupe en erreur
			    UPDATE pc_uee SET 
			        cod_err_pc_uee  = 'PC-PIC-E00' ,
					no_ss_serie     = p_no_ss_serie,
					no_ord_ss_serie = p_no_ord_ss_serie
			    WHERE cod_grp_aff = p_cod_grp_aff;  

                -- permet la sortie en NOT FOUND 
                v_pc_uee_found := FALSE;
				
		    ELSE
			    
                -- Modifier l'etat des details colis			  
                v_etat_uee_det_prp0 := su_bas_etat_val_num('PREPARATION_NULLE','PC_UEE_DET');
                v_etat_atv_iter     := su_bas_rch_etat_atv('PREPARATION_INTERROMPUE','PC_UEE_DET');
                
			    v_etape := ' affectation detail colis  = '|| r_pc_uee.no_uee;
                IF su_global_pkv.v_niv_dbg >= 6 THEN
			        su_bas_put_debug(v_nom_obj ||v_etape);
                END IF;	
                
			    UPDATE pc_uee_det d SET
				    d.etat_atv_pc_uee_det = v_etat_atv_pc_uee_det,
			        d.no_pos              = pr_atv_rg.cle_rg
                WHERE EXISTS (SELECT u.no_uee 
				              FROM pc_uee u
					          WHERE u.no_uee = d.no_uee AND u.cod_grp_aff = p_cod_grp_aff
                             ) AND 
                      su_bas_etat_val_num(d.etat_atv_pc_uee_det,'PC_UEE_DET') < v_etat_uee_det_prp0 AND
                      d.etat_atv_pc_uee_det <> v_etat_atv_iter;
					   			   	
                IF r_pc_uee.no_rmp IS NULL THEN
                    v_etape := 'Rch rampe';
                    v_no_rampe := pc_afu_pkg.pc_bas_rch_no_rampe_non_reg (r_pc_uee.cod_usn,
                                                                          pr_atv_rg.cle_rg,
                                                                          r_pc_uee.no_uee);
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                           su_bas_put_debug(v_nom_obj || v_etape ||' : v_no_rampe = ' || TO_CHAR(v_no_rampe));
                    END IF;						

                    v_etape := 'MAJ statut et rmp sur groupe colis ' || p_cod_grp_aff;
                    UPDATE pc_uee SET 
                        no_rmp          = NVL(v_no_rampe, no_rmp),
                        etat_atv_pc_uee = v_etat_atv_pc_uee, 
						no_ss_serie     = p_no_ss_serie,
					    no_ord_ss_serie = p_no_ord_ss_serie,
                        no_of           = p_no_of,
                        dat_aff         = SYSDATE,
                        dat_tn1         = pc_bas_maj_dat_tn1 ('AFFEC',cod_pss_afc, dat_tn1, dat_sel)
			        WHERE cod_grp_aff = p_cod_grp_aff;

                ELSE
                    -- Modifier l'etat du colis
                    v_etape := 'MAJ statut sur groupe colis '|| p_cod_grp_aff;
                    UPDATE pc_uee SET 
                        etat_atv_pc_uee = v_etat_atv_pc_uee, 
						no_ss_serie     = p_no_ss_serie,
					    no_ord_ss_serie = p_no_ord_ss_serie,
                        no_of           = p_no_of,
                        dat_aff         = SYSDATE,
                        dat_tn1         = pc_bas_maj_dat_tn1 ('AFFEC',cod_pss_afc, dat_tn1, dat_sel)
                    WHERE cod_grp_aff = p_cod_grp_aff;
                END IF;
                
                IF r_pc_uee.cod_pss_afc IS NOT NULL THEN										   
                    v_etape := 'Récupération clef process TRF_POS_PREP_AFF';
                    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss    => r_pc_uee.cod_pss_afc,
                                                    p_typ_atv    => 'AFF',	        -- Type d'activité 
                                                    p_cod_cfg    => 'TRF_POS_PREP_AFF',
                                                    p_val        => v_etat_trf_uee_pos); 
	            END IF;

			END IF;	
			
			IF su_global_pkv.v_niv_dbg >= 6 THEN
			       su_bas_put_debug(v_nom_obj || v_etape ||' : p_no_pos = ' || pr_atv_rg.cle_rg);
		    END IF;						

		END IF;
		CLOSE c_pc_uee;
        
        -- Vérification si la configuration d'activité demande un transfert des 
        -- colis vers les postes de préparation à l'affectation poste
        IF v_pc_uee_found AND v_etat_trf_uee_pos = '1' THEN
            -- boucle sur les colis du groupe d'affectation
            FOR r_pc_uee_aff IN c_pc_uee_aff LOOP
                v_etape := 'Envoi UEE ' || r_pc_uee_aff.no_uee ||  ' au poste';
                v_ret := pc_bas_trf_uee_to_pn1 (r_pc_uee_aff.no_uee);
            END LOOP;
        END IF;		
		        
    END IF;
                
    /**********************
    3) PHASE FINALISATION 
    **********************/
    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_PC_TRAIT_AFF_UEE_POS') THEN 
        v_ret_evt := pc_evt_trait_aff_uee_pos ('POST' ,p_cod_grp_aff,pr_atv_rg);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;
    IF v_pc_uee_found THEN
        v_ret := 'OK';			
    ELSE
        v_ret :='NOT FOUND';
    END IF;

RETURN v_ret;
EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_uee',
                        p_par_ano_1       => p_cod_grp_aff,
                        p_lib_ano_2       => 'typ_cle_rg',
                        p_par_ano_2       => pr_atv_rg.typ_cle_rg,
                        p_lib_ano_3       => 'cle_rg',
                        p_par_ano_3       => pr_atv_rg.cle_rg,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;


/* 
****************************************************************************
* pc_bas_maj_pic_aff - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de mettre a jour les picking correspondant au colis affecte
--
-- PARAMETRES :
-- ------------
--  p_no_uee
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 04a,16.05.11,mnev    Mise a jour du cod_abc_emp sur rch emplacement
-- 03a,21.03.11,mnev    MAJ tps regulation poste
-- 02b,10.12.08,mnev    Utilisation des config stockée dans pc_pic au lieu
--                      de relire la config process.
-- 02a,26.11.08,mnev    Ajout gestion du statut ordre pic pour poste 
--                      lancement N1.
-- 01a,24.04.07,JDRE    initialisation
-- 00a,24.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK 
--  ERROR 
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_maj_pic_aff (p_no_uee     pc_uee.no_uee%TYPE,
                             p_no_pos_prp pc_pic.no_pos_prp%TYPE
)  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 04a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_maj_pic_aff';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(100) := NULL;

	-- curseur colis
	CURSOR c_pc_pic (x_no_uee pc_pic_uee.no_uee%TYPE,
					 x_etat_atv_pc_pic pc_pic.etat_atv_pc_pic%TYPE)
	IS
	SELECT p.*
	FROM   pc_pic p, pc_pic_uee u
	WHERE  u.no_uee= x_no_uee
	AND    p.cod_pic = u.cod_pic 	
	AND    p.etat_atv_pc_pic = x_etat_atv_pc_pic
	AND    cod_err_pc_pic IS NULL;
	
	r_pc_pic c_pc_pic%ROWTYPE;

	v_etat_atv_pc_pic1     pc_pic.etat_atv_pc_pic%TYPE;
	v_etat_atv_pc_pic2     pc_pic.etat_atv_pc_pic%TYPE;
	
	v_no_pos_pic           su_pos.no_pos%TYPE;
	v_zone_pic             se_lig_zone.cod_zone%TYPE;
    v_cod_err_pc_pic       pc_pic.cod_err_pc_pic%TYPE := NULL;
	
BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : no_uee = ' || p_no_uee);
		su_bas_put_debug(v_nom_obj||' : p_no_pos_prp = ' || p_no_pos_prp);
    END IF;

    v_etape := 'Recherche etat , process, ...';
	v_etat_atv_pc_pic1 := su_bas_rch_etat_atv (p_cod_action_atv => 'CREATION',
										       p_nom_table	    => 'PC_PIC');

	-- Maj de tous les picking correspondant au colis
	IF su_global_pkv.v_niv_dbg >= 6 THEN
		su_bas_put_debug(v_nom_obj || ' etat_pic intial = ' || v_etat_atv_pc_pic1);
	END IF;

	IF v_ret <> 'ERROR' THEN
		-- Maj de tous les picking correspondant au colis
		v_etape := 'Maj de tous les pickings correspondant au colis.';
		v_ret := 'OK';

		OPEN c_pc_pic(p_no_uee,v_etat_atv_pc_pic1);
		LOOP
		    FETCH c_pc_pic INTO r_pc_pic;
		    EXIT WHEN c_pc_pic%NOTFOUND;

            -- determination du statut de l'ordre en fonction du mode de rgp 
            -- et du mode d'asservissement
			IF r_pc_pic.mode_rgp_asv <> '0' THEN
                -- on passe obligatoirement par le pre-traitement picking = regroupement 1
				v_etat_atv_pc_pic2 := su_bas_rch_etat_atv (p_cod_action_atv => 'ATTENTE_RGP_1',
										                   p_nom_table	   => 'PC_PIC');
            ELSE
                -- pas de phase de regroupement => le statut depend du mode d'asservissement
				IF r_pc_pic.mode_asv_pic IN ('1','2') THEN 
                    -- asservissement standard N2
					v_etat_atv_pc_pic2 := su_bas_rch_etat_atv (p_cod_action_atv => 'ATTENTE_ASSERV',
										                       p_nom_table	   => 'PC_PIC');
                ELSE
                    -- pas d'asservissement ...
                    v_etat_atv_pc_pic2 := su_bas_rch_etat_atv (p_cod_action_atv => 'ASSERVI_TERM',
                                                               p_nom_table	   => 'PC_PIC');
				END IF;
			END IF;
			
		    IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' v_etat_atv_pc_pic2 '|| v_etat_atv_pc_pic2);
            END IF;	
			
            -- Mise à jour de l'emplacement de picking
            IF r_pc_pic.cod_emp IS NULL THEN
                v_etape := 'rch emp pic';
                r_pc_pic.cod_emp := pc_pic_pkg.pc_bas_rch_emp_pic (pr_pic => r_pc_pic,
                                                                   p_mode => 'CACHE');

                v_etape := 'MAJ pc_pic_uee';
                UPDATE pc_uee_det A SET
                    cod_emp_pic = r_pc_pic.cod_emp  
                WHERE EXISTS (SELECT 1 
                              FROM pc_pic_uee B
                              WHERE B.cod_pic = r_pc_pic.cod_pic AND
                                    B.no_uee = A.no_uee AND
                                    B.no_com = A.no_com AND
                                    B.no_lig_com = A.no_lig_com);

                r_pc_pic.cod_abc_emp := NULL;
            END IF;

            IF r_pc_pic.cod_abc_emp IS NULL AND r_pc_pic.cod_emp IS NOT NULL THEN
                r_pc_pic.cod_abc_emp := su_bas_gcl_se_emp (r_pc_pic.cod_emp, 'COD_ABC');
            END IF;

            r_pc_pic.no_pos_prp := p_no_pos_prp;
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' maj r_pic.no_pos_prp '|| r_pc_pic.no_pos_prp);
            END IF;
            
            -- Recherche du poste picking
            v_etape := 'rch pos pic';
            IF pc_pic_pkg.pc_bas_rch_pos_pic(pr_pic       => r_pc_pic,
		                                     p_no_pos_pic => v_no_pos_pic,
	                                         p_zone_pic   => v_zone_pic) <> 'ERROR' THEN
                v_etape := 'MAJ pc_pic';
			    UPDATE pc_pic 
			    SET    etat_atv_pc_pic = v_etat_atv_pc_pic2,
			           no_pos_pic = v_no_pos_pic,
					   no_pos_prp = p_no_pos_prp,  -- null dans le cas des bordereaux
                       no_pos_lct = NVL(no_pos_lct,v_no_pos_pic),
                       cod_zone_pic = v_zone_pic,
                       cod_emp      = r_pc_pic.cod_emp,
                       cod_abc_emp  = r_pc_pic.cod_abc_emp,
                       tps_regp     = ROUND(86400 * (SYSDATE - dat_crea))
			    WHERE cod_pic = r_pc_pic.cod_pic;
            ELSE 
			    v_etape := 'Erreur rch pos pic';
				IF su_global_pkv.v_niv_dbg >= 3 THEN
			         su_bas_put_debug(v_nom_obj ||' '|| v_etape);
			    END IF;	
				v_ret := 'ERROR';
				EXIT;				
			END IF;

			IF su_global_pkv.v_niv_dbg >= 6 THEN
			   su_bas_put_debug(v_nom_obj
				 ||' : maj pic  = '|| r_pc_pic.cod_pic		                 
				 ||' : etat_pic = ' || v_etat_atv_pc_pic2
				 ||' : no_pos_pic = ' || v_no_pos_pic);
			END IF;	
		END LOOP;
		CLOSE c_pc_pic;

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
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;


/****************************************************************************
* pc_bas_maj_pic_grp - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de mettre a jour les picking correspondant au 
-- groupe de colis affecte. 
-- Sur le modèle de pc_bas_maj_pic_aff, mais traitant tous les colis du 
-- groupe d'affectation.
--
-- PARAMETRES :
-- ------------
--  p_no_uee : l'un des colis du groupe
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,16.05.11,mnev    Mise a jour du cod_abc_emp sur rch emplacement
-- 01c,20.10.09,rbel    Optimisation avec passage nouveau paramètre
-- 01b,10.12.08,mnev    Utilisation des config stockée dans pc_pic au lieu
--                      de relire la config process.
--                      Ajout gestion du statut ordre pic pour poste lancement N1.
-- 01a,24.04.07,CROC    création
-- 00a,24.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK 
--  ERROR 
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_maj_pic_grp ( p_no_uee     pc_uee.no_uee%TYPE,
                              p_no_pos_prp pc_pic.no_pos_prp%TYPE,
                              p_cod_pss_afc pc_uee.cod_pss_afc%TYPE DEFAULT NULL,
                              p_cod_grp_aff pc_uee.cod_grp_aff%TYPE DEFAULT NULL
)  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_maj_pic_grp';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(100) := NULL;

	-- curseur colis
	CURSOR c_pc_pic (x_cod_grp_aff     pc_uee.cod_grp_aff%TYPE,
					 x_etat_atv_pc_pic pc_pic.etat_atv_pc_pic%TYPE)
	IS
	SELECT p.*
	FROM   pc_pic p, 
	       pc_pic_uee pu,
		   pc_uee u
	WHERE  u.cod_grp_aff     = x_cod_grp_aff
	AND    p.cod_pic         = pu.cod_pic 
	AND    u.no_uee          = pu.no_uee	
	AND    p.etat_atv_pc_pic = x_etat_atv_pc_pic
	AND    cod_err_pc_pic    IS NULL;
	
	r_pc_pic c_pc_pic%ROWTYPE;

	v_etat_atv_pc_pic1     pc_pic.etat_atv_pc_pic%TYPE;
	v_etat_atv_pc_pic2     pc_pic.etat_atv_pc_pic%TYPE;
	v_cod_pss_afc          pc_uee_det.cod_pss_afc%TYPE;
	
	v_no_pos_pic           su_pos.no_pos%TYPE;
	v_zone_pic             se_lig_zone.cod_zone%TYPE;
    v_cod_err_pc_pic       pc_pic.cod_err_pc_pic%TYPE := NULL;
	v_cod_grp_aff		   pc_uee.cod_grp_aff%TYPE;
	
BEGIN

    SAVEPOINT my_pc_bas_maj_pic_grp;  -- Pour la gestion de l'exception on fixe un point de rollback.
	
    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : no_uee = ' || p_no_uee);
		su_bas_put_debug(v_nom_obj||' : p_no_pos_prp = ' || p_no_pos_prp);
    END IF;

    v_etape := 'Recherche etat , process, ...';
	v_etat_atv_pc_pic1 := su_bas_rch_etat_atv (p_cod_action_atv => 'CREATION',
										       p_nom_table	    => 'PC_PIC');

	v_cod_pss_afc := NVL(p_cod_pss_afc, su_bas_gcl_pc_uee(p_no_uee,'COD_PSS_AFC'));
    v_cod_grp_aff := NVL(p_cod_grp_aff, su_bas_gcl_pc_uee(p_no_uee,'COD_GRP_AFF')); -- Récupération du groupe
	
	-- Maj de tous les picking correspondant au colis
	IF su_global_pkv.v_niv_dbg >= 6 THEN
		su_bas_put_debug(v_nom_obj ||
			 ' cod_pss_afc = ' || v_cod_pss_afc ||
			 ' etat_pic = ' || v_etat_atv_pc_pic1
			 );
	END IF;

	IF v_ret <> 'ERROR' THEN
		-- Maj de tous les picking correspondant au colis
		v_etape := 'Maj de tous les pickings correspondant au colis.';
		v_ret := 'OK';

		OPEN c_pc_pic(v_cod_grp_aff,v_etat_atv_pc_pic1);
		LOOP
		    FETCH c_pc_pic INTO r_pc_pic;
		    EXIT WHEN c_pc_pic%NOTFOUND;


            -- determination du statut de l'ordre en fonction du mode de rgp 
            -- et du mode d'asservissement
			IF r_pc_pic.mode_rgp_asv <> '0' THEN
                -- on passe obligatoirement par le pre-traitement picking = regroupement 1
				v_etat_atv_pc_pic2 := su_bas_rch_etat_atv (p_cod_action_atv => 'ATTENTE_RGP_1',
										                   p_nom_table	   => 'PC_PIC');
            ELSE
                -- pas de phase de regroupement => le statut depend du mode d'asservissement
				IF r_pc_pic.mode_asv_pic IN ('1','2') THEN 
                    -- asservissement standard N2
					v_etat_atv_pc_pic2 := su_bas_rch_etat_atv (p_cod_action_atv => 'ATTENTE_ASSERV',
										                       p_nom_table	   => 'PC_PIC');
                ELSE
                    -- pas d'asservissement ...
                    v_etat_atv_pc_pic2 := su_bas_rch_etat_atv (p_cod_action_atv => 'ASSERVI_TERM',
                                                               p_nom_table	   => 'PC_PIC');
				END IF;
			END IF;

		    IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' v_etat_atv_pc_pic2 '|| v_etat_atv_pc_pic2);
            END IF;	
			
            -- Mise à jour de l'emplacement de picking
            IF r_pc_pic.cod_emp IS NULL THEN
                v_etape := 'rch emp pic';
                r_pc_pic.cod_emp := pc_pic_pkg.pc_bas_rch_emp_pic (pr_pic => r_pc_pic,
                                                                   p_mode => 'CACHE');

                v_etape := 'MAJ pc_pic_uee';
                UPDATE pc_uee_det A SET
                    cod_emp_pic = r_pc_pic.cod_emp 
                WHERE EXISTS (SELECT 1 
                              FROM pc_pic_uee B
                              WHERE B.cod_pic = r_pc_pic.cod_pic AND
                                    B.no_uee = A.no_uee AND
                                    B.no_com = A.no_com AND
                                    B.no_lig_com = A.no_lig_com);

                r_pc_pic.cod_abc_emp := NULL;
            END IF;

            IF r_pc_pic.cod_abc_emp IS NULL AND r_pc_pic.cod_emp IS NOT NULL THEN
                r_pc_pic.cod_abc_emp := su_bas_gcl_se_emp (r_pc_pic.cod_emp, 'COD_ABC');
            END IF;

            r_pc_pic.no_pos_prp := p_no_pos_prp;
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' maj r_pic.no_pos_prp '|| r_pc_pic.no_pos_prp);
            END IF;
            
            -- Recherche du poste picking
            v_etape := 'rch poste picking';
            IF pc_pic_pkg.pc_bas_rch_pos_pic(pr_pic       => r_pc_pic,
		                                     p_no_pos_pic => v_no_pos_pic,
	                                         p_zone_pic   => v_zone_pic) <> 'ERROR' THEN
                v_etape := 'MAJ pc_pic';
			    UPDATE pc_pic 
			    SET    etat_atv_pc_pic = v_etat_atv_pc_pic2,
			           no_pos_pic = v_no_pos_pic,
				 	   no_pos_prp = p_no_pos_prp,  -- null dans le cas des bordereaux					
                       no_pos_lct = NVL(no_pos_lct,v_no_pos_pic),
                       cod_zone_pic = v_zone_pic,
                       cod_emp      = r_pc_pic.cod_emp,
                       cod_abc_emp  = r_pc_pic.cod_abc_emp,
                       tps_regp     = ROUND(86400 * (SYSDATE - dat_crea))
			    WHERE cod_pic = r_pc_pic.cod_pic;
            ELSE 
			    v_etape := 'Erreur rch poste de picking';
				IF su_global_pkv.v_niv_dbg >= 6 THEN
			         su_bas_put_debug(v_nom_obj ||' '|| v_etape);
			    END IF;	
				v_ret := 'ERROR';
				EXIT; -- une erreur : faire rollback de l'ensemble du groupe			
			END IF;

			IF su_global_pkv.v_niv_dbg >= 6 THEN
			   su_bas_put_debug(v_nom_obj
				 ||' : maj pic  = '|| r_pc_pic.cod_pic		                 
				 ||' : etat_pic = ' || v_etat_atv_pc_pic2
				 ||' : no_pos_pic = ' || v_no_pos_pic);
			END IF;	
		END LOOP;
		CLOSE c_pc_pic;
		
		IF v_ret = 'ERROR' THEN
		    -- erreur dans pc_bas_rch_pos_pic => ANO
			-- Annulation des update de tous le groupe de pc_pic
			-- puis 
		    ROLLBACK TO my_pc_bas_maj_pic_grp;
		END IF;

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
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;


/* $Id$
****************************************************************************
* pc_bas_aff_regul - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'affecter des colis en mode charge ou auto affecteé
-- mode_aff_uee = '2' ou '3' du colis
--
-- PARAMETRES :
-- ------------
--  xxx
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02e,07.05.10,mnev   Ajout init de v_ret à ERROR ds le c_pos%notfound
-- 02d,07.05.10,rbel   Mémorisation message alerte poste
-- 02c,22.09.09,rbel   Gestion ROLLBACK si fin de série demandée par le poste
-- 02a,20.02.09,croc   Affectation en mode série  
-- 01a,14.05.07,croc    Création
-- 00a,14.05.07,GENPRG  version 2.10 
-- ---"----------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  NONE        : Rien trouvé
--  OK_CONTINUE : Trouvé mais insuffisant
--  OK_WAIT     : Trouvé et suffisant
--  ERROR       : Erreur
--
-- COMMIT :
-- --------
--   NON


FUNCTION pc_bas_aff_regul (    
	p_cle_rg               su_atv_rg.cle_rg%TYPE,
    p_typ_cle_rg           su_atv_rg.cod_atv%TYPE,
    p_cod_atv              su_atv.cod_atv%TYPE,
    p_cod_usn              su_usn.cod_usn%TYPE,
    p_evt		           VARCHAR2
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02e $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_aff_regul';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
	
	-- Recherche du poste, dans l'usine, régulé et en marche
	CURSOR c_pos IS
        SELECT su_pos.no_pos, pc_pos.alert_trv_dispo,
               su_pos.nom_ip_pos, SU_BAS_TO_NUMBER(su_pos.port_pos) port_pos
        FROM pc_pos, su_pos, su_atv_rg
       	WHERE  su_pos.no_pos = su_atv_rg.cle_rg
		   AND su_pos.no_pos = p_cle_rg
           AND pc_pos.no_pos = su_pos.no_pos 	
	       AND su_atv_rg.cod_atv = p_cod_atv
		   AND su_atv_rg.cle_rg = p_cle_rg
		   AND su_atv_rg.etat_mar_arr = '1'
	       AND su_pos.cod_usn = p_cod_usn;
           
    r_pos         c_pos%ROWTYPE;
		   
    v_no_pos      su_pos.no_pos%TYPE;		   
	v_nb_col      NUMBER := 1; -- Nb colis a affecter au poste en fonction charge et consigne 
	v_no_uee      pc_uee.no_uee%TYPE := NULL;
	v_cod_grp_aff pc_uee.cod_grp_aff%TYPE;
	
	v_select VARCHAR2(4000); 
	v_cod_cfg_serie  su_pss_atv_cfg.val_cle_atv%TYPE;
	v_debut             TIMESTAMP;
	v_debut_tot         TIMESTAMP;
    
    v_ret_pipe                NUMBER;         -- retour de fonction receive
    v_fin_sur_serie           VARCHAR2(100);  -- recupere le contenu du pipe
    v_nom_pipe                VARCHAR2(100);
    v_cod_rgp_serie_en_cours  pc_uee.cod_rgp_serie%TYPE;
    v_cre_sous_serie          BOOLEAN := FALSE;
	
BEGIN

    SAVEPOINT my_pc_bas_aff_regul;  -- Pour la gestion de l'exception on fixe un point de rollback.

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj
		                 ||' : cle_rg = '       || p_cle_rg
		                 ||' : p_cod_atv = '    || p_cod_atv
		                 ||' : p_cod_usn = '    || p_cod_usn
		                 ||' : p_typ_cle_rg = ' || p_typ_cle_rg
		                 ||' : p_evt = '        || p_evt
		);

    END IF;

    /************************
    1) PHASE INITIALISATION 
    ************************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code pré-standard (initialisation de variables)


    -- Fin du code pré-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_AFF_REGUL') THEN 
        v_ret_evt := pc_evt_aff_regul('PRE' , 
		                              p_cle_rg ,
									  p_cod_atv,
									  p_cod_usn,
									  p_typ_cle_rg,
									  p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT 
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_AFF_REGUL') THEN 
        v_ret_evt := pc_evt_aff_regul('ON' , 
		                              p_cle_rg ,
									  p_cod_atv,
									  p_cod_usn,
									  p_typ_cle_rg,
									  p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        -- ---------------------------------------------------------------------
        -- mettre ici le code de traitement standard
        v_etape := 'Début';
			
        IF p_evt = 'POST' THEN
			    v_ret := 'ERROR';

		ELSIF p_evt = 'ON' THEN

			    v_ret_evt := 'OK';

			    v_etape := 'vérifie existence poste';
				OPEN c_pos;
			    FETCH c_pos INTO r_pos;
			    IF c_pos%NOTFOUND THEN
				    IF su_global_pkv.v_niv_dbg >= 3 THEN
					    su_bas_put_debug(v_nom_obj ||' : poste = ' || p_cle_rg ||' incorrect ' );
			        END IF;
				    v_ret_evt := 'ERROR';
                    v_ret := 'ERROR';
			    END IF;
			    CLOSE c_pos;
		
			    IF v_ret_evt = 'OK' THEN
				
				    v_cod_rgp_serie_en_cours := su_bas_gcl_pc_pos_plt(r_pos.no_pos,'COD_RGP_SERIE','VAL_PLT');
                    IF v_cod_rgp_serie_en_cours IS NOT NULL THEN
                        -- il y a une série d'active
                        SAVEPOINT my_pc_bas_aff_serie;  -- Pour la gestion des fin de séries
                        v_nom_pipe := su_bas_rch_affaire_str||'_FINSE_'||RPAD(r_pos.no_pos,10, '0');
                        
                        -- on vide le pipe FIN_SERIE du poste pour pouvoir le relire après la vague d'affectation
                        LOOP
                            v_ret_pipe := su_my_pipe.receive_message (v_nom_pipe, 0);
                            EXIT WHEN v_ret_pipe <> 0;
                            su_my_pipe.unpack_message (v_fin_sur_serie);
                        END LOOP;
                    END IF;
        
                    IF su_global_pkv.v_niv_dbg >= 2 THEN	
                        su_bas_put_debug(v_nom_obj||'*** BEGIN T=0');
                        v_debut_tot := SYSTIMESTAMP;
                        v_debut     := v_debut_tot;
                    END IF;
				
				    v_etape := 'Recherche colis affectables';
				    v_ret := pc_bas_rch_uee_pos(
								p_appel      => 'AFF', 
								p_cod_usn    => p_cod_usn,
								p_cod_atv    => p_cod_atv,
								p_typ_cle    => p_typ_cle_rg,
								p_cle_rg     => p_cle_rg,
								p_nb_col     => v_nb_col,
								p_cod_grp_aff=> v_cod_grp_aff,
								p_no_uee     => v_no_uee,
								p_select     => v_select
								);	
 		            IF su_global_pkv.v_niv_dbg >= 2 THEN
                        su_bas_put_debug(v_nom_obj||'*** RCH_UEE_POS T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                        v_debut := SYSTIMESTAMP;
                    END IF;
 				  
 		            -- Pour le mode série : constituer une sous-série à partir du 1er colis et l'affecter 
 		            IF v_ret = 'OK_SERIE' THEN
 					    v_ret := pc_bas_cre_sous_serie(p_cod_usn    => p_cod_usn,
 								                       p_cod_atv    => p_cod_atv,
 								                       p_typ_cle    => p_typ_cle_rg,
 								                       p_cle_rg     => p_cle_rg,								                       
 								                       p_cod_grp_aff=> v_cod_grp_aff);
 				       
                        IF v_ret = 'OK' THEN
                            v_cre_sous_serie := TRUE;
                        END IF;
                        
                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||'*** CRE_SS_SERIE T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
                            v_debut := SYSTIMESTAMP;
                        END IF;							   
 	                END IF;
                    
                    -- Vérification si une fin de série a eu lieu pendant l'affectation
                    IF v_cod_rgp_serie_en_cours IS NOT NULL AND v_cre_sous_serie THEN
                        LOOP
                            v_ret_pipe := su_my_pipe.receive_message (v_nom_pipe, 0);
                            EXIT WHEN v_ret_pipe <> 0;
         
                            su_my_pipe.unpack_message (v_fin_sur_serie);
         
                            -- Cette fin de série est elle sur le regroupement en cours d'affectation?
                            IF v_fin_sur_serie = v_cod_rgp_serie_en_cours THEN
                                -- oui dinc il faut annuler toute la passe d'affectation pour ce poste
                                ROLLBACK TO my_pc_bas_aff_serie;
                                EXIT;
                            END IF;
                        END LOOP;
                    END IF;
                    
                    -- Faut-il informer le poste de la disponibilité de travail
                    IF r_pos.alert_trv_dispo = '1' AND 
                       r_pos.nom_ip_pos IS NOT NULL AND
                       r_pos.port_pos IS NOT NULL AND 
                       v_ret LIKE 'OK%' THEN
                        v_etape := 'Envoi alert au poste';
                        --su_bas_env_tcp_pn1(p_host    => r_pos.nom_ip_pos,
                        --                   p_port    => r_pos.port_pos,
                        --                   p_message => chr(2)||'vienschercher'||';'||r_pos.no_pos||';'|| v_cod_rgp_serie_en_cours ||chr(3),
                        --                   p_timeout => 0);  -- on attend pas
                        v_ret := su_dial_tcp_pn1_pkg.su_bas_memo_msg_tcp (p_nom_host => r_pos.nom_ip_pos,
                                                                          p_port => r_pos.port_pos,
                                                                          p_message => CHR(2)||'vienschercher'||';'||r_pos.no_pos||';'|| v_cod_rgp_serie_en_cours ||CHR(3),
                                                                          p_tx_timeout => 0);

                        IF su_global_pkv.v_niv_dbg >= 2 THEN
                            su_bas_put_debug(v_nom_obj||' Envoi message de reveil au poste N1: '|| r_pos.no_pos
                                                                                    || ', nom_ip_pos = ' || r_pos.nom_ip_pos
                                                                                    || ', port_pos = ' || r_pos.port_pos);
                        END IF;                       
                    END IF;	
														   
			    END IF;

		ELSIF p_evt = 'PRE' THEN
			v_ret := 'ERROR';

		END IF;
									
        -- Fin du code standard 
        -- ---------------------------------------------------------------------

    END IF;

    /**********************
    3) PHASE FINALISATION 
    **********************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code post-standard


    -- Fin du code post-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_AFF_REGUL') THEN 
        v_ret_evt := pc_evt_aff_regul('POST' , 
		                              p_cle_rg ,
									  p_cod_atv,
									  p_cod_usn,
									  p_typ_cle_rg,
									  p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;
	
	IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' retour v_ret = '   || v_ret);
    END IF;
	
    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||'*** END FINAL T='|| to_char((SYSTIMESTAMP-v_debut_tot),'sssssxFF2'));
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_pc_bas_aff_regul;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cle_rg',
                        p_par_ano_1       => p_cle_rg,
						p_lib_ano_2       => 'p_typ_cle_rg',
                        p_par_ano_2       => p_typ_cle_rg,
						p_lib_ano_3       => 'p_cod_atv',
                        p_par_ano_3       => p_cod_atv,
						p_lib_ano_4       => 'p_cod_usn',
                        p_par_ano_4       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;

/* $Id$
****************************************************************************
* pc_bas_aff_bord  - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'affecter des colis en mode bordereau
-- mode_aff_uee = '1' du colis
--
-- PARAMETRES :
-- ------------
--  xxx
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 04a,22.07.11,mnev    Lock des colis dans boucle d'affectation
-- 03b,29.07.11,rbel    passage mode_rgp_ops en table
-- 03a,06.04.11,mnev    mise a jour de dat_aff dans pc_uee
-- 02a,09.09.10,mnev    ajout commit a chaque changement de cle
-- 01c,25.02.10,alfl    ne pas modifier etat uee det si superieur ou egal a PRPO
-- 01b,09.07.09,mnev    commit en fin de traitement.
-- 01a,14.05.07,croc    creation
-- 00a,14.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
-- OK, ERROR 
--
-- COMMIT :
-- --------
-- OUI   

FUNCTION pc_bas_aff_bord (    
	p_cle_rg               su_atv_rg.cle_rg%TYPE,
    p_typ_cle_rg           su_atv_rg.cod_atv%TYPE,
    p_cod_atv              su_atv.cod_atv%TYPE,
    p_cod_usn              su_usn.cod_usn%TYPE,
    p_evt		           VARCHAR2
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 04a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_aff_bord';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_trt           VARCHAR2(100) := NULL; 
    v_ret_evt           VARCHAR2(20)  := NULL;

    -- $MOD,25.11.14,pluc Spécif SUO : Synchronisation affectation mode bordereau débord
    --                    sur fin prépa process méca.
    
	-- Recherche les colis en mode bordereau
	CURSOR c_uee_bord (x_etat_atv_pc_uee pc_uee.etat_atv_pc_uee%TYPE,
                       x_mode_aff_uee    pc_uee.mode_aff_uee%TYPE,
					   x_cod_usn         pc_uee.cod_usn%TYPE) IS
        SELECT a.cod_pss_afc, 
               a.cod_pss_afc || DECODE(c.grp_commit_auto_aff,'UT',NVL(NVL(b.cod_ut_sup,a.cod_ut_sup),'#NULL#'),
                                                             'COM', a.no_com,
                                                             'PSS',a.cod_pss_afc,
                                                             'FIN') cle,
               a.no_uee, a.no_rmp, a.cod_usn  
        FROM   su_pss_atv_cfg x, su_atv y, pc_uee a, pc_ut b, v_pc_cfg_rgp_ops_usn c
       	WHERE  a.etat_atv_pc_uee = x_etat_atv_pc_uee 
		AND    a.mode_aff_uee = x_mode_aff_uee 
		AND    a.cod_usn = x_cod_usn
	    AND    a.cod_err_pc_uee IS NULL
        AND    a.cod_ut_sup = b.cod_ut 
        AND    a.typ_ut_sup = b.typ_ut
        AND    c.mode_rgp_ops = su_bas_rch_cle_atv_pss_2 (a.cod_pss_afc,'PIC','MODE_RGP_OPS')
        AND    c.cod_usn = a.cod_usn
        AND    x.cod_cfg_atv = 'SYNCHRO_SUR_LST_PSS' 
        AND    y.typ_atv = 'AFF' 
        AND    x.cod_atv = y.cod_atv
        AND    x.cod_pss = a.cod_pss_afc
        AND NOT EXISTS ( SELECT b.no_uee
                         FROM   pc_uee b, pc_ut t2, pc_ut t1 
                         WHERE  t1.cod_ut     = a.cod_ut_sup
                         AND    t1.typ_ut     = a.typ_ut_sup
                         AND    t1.cod_ut_sup = t2.cod_ut_sup
                         AND    t1.typ_ut_sup = t2.typ_ut_sup
                         AND    t2.cod_ut     = b.cod_ut_sup
                         AND    t2.typ_ut     = b.typ_ut_sup 
                         AND    INSTR (x.val_cle_atv, b.cod_pss_afc) > 0
                         AND    su_bas_etat_val_num(t2.etat_atv_pc_ut,'PC_UT') < su_bas_etat_val_num ('SYNCHRO_PSS','PC_UT')
                         --AND    su_bas_etat_val_num(b.etat_atv_pc_uee,'PC_UEE') < su_bas_etat_val_num ('SYNCHRO_PSS','PC_UEE')
                        )
        ORDER BY 1, 2;
		 	
	r_uee_bord                  c_uee_bord%ROWTYPE;

    -- pose d'un verrou sur le colis 
    CURSOR c_lock_uee (x_no_uee pc_uee.no_uee%TYPE,
                       x_etat   pc_uee.etat_atv_pc_uee%TYPE) IS
        SELECT 1
        FROM pc_uee
        WHERE no_uee = x_no_uee AND etat_atv_pc_uee = x_etat
        FOR UPDATE;

    r_lock_uee  c_lock_uee%ROWTYPE;
    v_found_uee BOOLEAN;

    v_last_cle                  VARCHAR2(20) := NULL;            
	v_etat_atv_pc_uee_sel1      pc_uee.etat_atv_pc_uee%TYPE;
    v_etat_atv_pc_uee           pc_uee.etat_atv_pc_uee%TYPE;
	v_etat_atv_pc_uee_det       pc_uee_det.etat_atv_pc_uee_det%TYPE;
	v_mode_aff_uee	            pc_uee.mode_aff_uee%TYPE;
    v_cle_regul                 su_atv_cfg.val_cle_atv%TYPE;
    v_cle_regul_av              su_atv_cfg.val_cle_atv%TYPE;
    v_no_rampe                  pc_ut.no_rmp%TYPE;
	v_dum                       NUMBER;
    v_etat_uee_det_prp0         NUMBER;  

BEGIN

    SAVEPOINT my_pc_bas_aff_bord;  -- Pour la gestion de l'exception on fixe un point de rollback.

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj
		                 ||' : cle_rg = '       || p_cle_rg
		                 ||' : p_cod_atv = '    || p_cod_atv
		                 ||' : p_cod_usn = '    || p_cod_usn
		                 ||' : p_typ_cle_rg = ' || p_typ_cle_rg
		                 ||' : p_evt = '        || p_evt);
    END IF;

    /************************
    1) PHASE INITIALISATION 
    ************************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code pré-standard (initialisation de variables)


    -- Fin du code pré-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_AFF_BORD') THEN 
        v_ret_evt := pc_evt_aff_bord('PRE' , 
		                              p_cle_rg ,
									  p_cod_atv,
									  p_cod_usn,
									  p_typ_cle_rg,
									  p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT 
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_AFF_BORD') THEN 
        v_ret_evt := pc_evt_aff_bord('ON' , 
		                              p_cle_rg ,
									  p_cod_atv,
									  p_cod_usn,
									  p_typ_cle_rg,
									  p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        -- ---------------------------------------------------------------------
        v_etape := 'Début';

        -- -------------------------------------
        -- Mode 1 : par appel poste => bordereau 
        -- -------------------------------------
		v_mode_aff_uee := '1';

		v_etat_atv_pc_uee     := su_bas_rch_etat_atv (p_cod_action_atv => 'AFFECTATION_BOR',
										              p_nom_table	   => 'PC_UEE');
		v_etat_atv_pc_uee_det := su_bas_rch_etat_atv (p_cod_action_atv => 'AFFECTATION_BOR',
										              p_nom_table	   => 'PC_UEE_DET');
        v_etat_atv_pc_uee_sel1 := su_bas_rch_etat_atv (p_cod_action_atv => 'SELECTION_AFFECTATION',
                                                       p_nom_table	  => 'PC_UEE');
		IF su_global_pkv.v_niv_dbg >= 6 THEN
		    su_bas_put_debug(v_nom_obj ||
				 ' etat_sel1= ' || v_etat_atv_pc_uee_sel1 ||
				 ' etat_uee = ' || v_etat_atv_pc_uee ||
				 ' etat_uee_det = ' || v_etat_atv_pc_uee_det);
		END IF;

        v_last_cle := NULL;

		OPEN c_uee_bord(v_etat_atv_pc_uee_sel1, v_mode_aff_uee, p_cod_usn);
		LOOP
		    FETCH c_uee_bord INTO r_uee_bord;
            IF c_uee_bord%NOTFOUND THEN
                v_etape := 'commit sur notfound';
                COMMIT;
                SAVEPOINT my_pc_bas_aff_bord;  -- Pour la gestion de l'exception on fixe un point de rollback.
                EXIT;
            END IF;

            IF v_last_cle IS NULL THEN
                -- 1ere fois ...
                v_last_cle := r_uee_bord.cle;

            ELSIF NVL(r_uee_bord.cle,'#NULL#') <> NVL(v_last_cle,'#NULL#') THEN
                v_etape := 'commit intermediaire';
                COMMIT;
                SAVEPOINT my_pc_bas_aff_bord;  -- Pour la gestion de l'exception on fixe un point de rollback.
                v_last_cle  := r_uee_bord.cle;
            END IF;

            -- pose d'un verrou sur le colis pour meilleure gestion des acces concurrents
            -- le verrou sera supprime au commit ...
            v_etape:='Lock colis';
            OPEN c_lock_uee (r_uee_bord.no_uee, v_etat_atv_pc_uee_sel1);
            FETCH c_lock_uee INTO r_lock_uee;
            v_found_uee := c_lock_uee%FOUND;
            CLOSE c_lock_uee;

            IF v_found_uee THEN

                v_etape := 'Rch rampe expe';
                IF r_uee_bord.no_rmp IS NULL THEN
                    v_no_rampe := pc_afu_pkg.pc_bas_rch_no_rampe_non_reg (p_cod_usn,
                                                                          NULL,
                                                                          r_uee_bord.no_uee);
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                           su_bas_put_debug(v_nom_obj || ' ' || v_etape ||
                                            ' : v_no_rampe = ' || TO_CHAR(v_no_rampe));
                    END IF;						

                    IF v_no_rampe IS NOT NULL THEN
                        v_etape := 'MAJ rmp sur colis ' || r_uee_bord.no_uee;
                        UPDATE pc_uee SET 
                            no_rmp = v_no_rampe 
    		            WHERE no_uee = r_uee_bord.no_uee;
                    END IF;
                END IF;

    		    v_etape := 'affectation RZ colis bordereau = '|| r_uee_bord.no_uee;
    		    IF su_global_pkv.v_niv_dbg >= 6 THEN
    		        su_bas_put_debug(v_nom_obj ||' ' || v_etape);                     
                END IF;									

    		    v_etape := 'mise a jour RZ picking colis bordereau = '|| r_uee_bord.no_uee;
    		    -- maj picking colis
    		    v_ret_trt := pc_bas_maj_pic_aff (p_no_uee     => r_uee_bord.no_uee,
    		                                     p_no_pos_prp => NULL);
    						
                IF v_ret_trt = 'OK' THEN
    			    -- Modifier l'etat du colis
    		        UPDATE pc_uee SET 
                        etat_atv_pc_uee = v_etat_atv_pc_uee,
                        dat_aff         = SYSDATE,
                        dat_tn1         = pc_bas_maj_dat_tn1 ('AFFEC',cod_pss_afc, dat_tn1, dat_sel)
    		        WHERE no_uee = r_uee_bord.no_uee;

    		        v_etape := 'affectation RZ detail colis bordereau = '|| r_uee_bord.no_uee;
    		        -- Modifier l'etat des details colis
                    
                    --$MOD,patch,21160
                    v_etat_uee_det_prp0 := su_bas_etat_val_num('PREPARATION_NULLE','PC_UEE_DET');
    		        
                    UPDATE pc_uee_det SET 
                        etat_atv_pc_uee_det = v_etat_atv_pc_uee_det
    		        WHERE no_uee = r_uee_bord.no_uee AND
                          su_bas_etat_val_num(etat_atv_pc_uee_det,'PC_UEE_DET') < v_etat_uee_det_prp0;
                    --$FIN,patch,21160
    				
                ELSE

                    UPDATE pc_uee
    				SET    cod_err_pc_uee = 'PC-PIC-E00'
    				WHERE  no_uee = r_uee_bord.no_uee;
    										   								
    				IF su_global_pkv.v_niv_dbg >= 3 THEN
    		             su_bas_put_debug(v_nom_obj ||' erreur config picking no_uee '||r_uee_bord.no_uee);
    		        END IF;
                END IF;

            END IF;
											
		END LOOP;
		CLOSE c_uee_bord;

        -- Fin du code standard 
        -- ---------------------------------------------------------------------
    END IF;

    /**********************
    3) PHASE FINALISATION 
    **********************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code post-standard


    -- Fin du code post-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_AFF_BORD') THEN 
        v_ret_evt := pc_evt_aff_bord('POST' , 
		                              p_cle_rg ,
									  p_cod_atv,
									  p_cod_usn,
									  p_typ_cle_rg,
									  p_evt);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    COMMIT;
	
    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_pc_bas_aff_bord;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cle_rg',
                        p_par_ano_1       => p_cle_rg,
						p_lib_ano_2       => 'p_typ_cle_rg',
                        p_par_ano_2       => p_typ_cle_rg,
						p_lib_ano_3       => 'p_cod_atv',
                        p_par_ano_3       => p_cod_atv,
						p_lib_ano_4       => 'p_cod_usn',
                        p_par_ano_4       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;

/* $Id$
****************************************************************************
* pc_bas_calcul_charge - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de calculer la charge d'un poste
--
-- PARAMETRES :
-- ------------
--  xxx
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01c,18.01.10,mnev    Change le calcul de la charge. La vue v_uee_charge 
--                      a été réécrite.
-- 01b,05.05.09,olda    Gestion du calcul de charge pour un poste de regroupement. 
-- 01a,15.05.07,croc    Creation
-- 00a,15.05.07,GENPRG  Version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_calcul_charge (p_cle_rg               su_atv_rg.cle_rg%TYPE,
                               p_typ_cle_rg           su_atv_rg.typ_cle_rg%TYPE,
                               p_cod_atv              su_atv_rg.cod_atv%TYPE,
                               p_cod_usn              su_atv_rg.cod_usn%TYPE,
                               p_par_tsk_fond_3       su_tsk_fond.par_tsk_fond_3%TYPE,
                               p_par_tsk_fond_4       su_tsk_fond.par_tsk_fond_4%TYPE,
                               p_par_tsk_fond_5       su_tsk_fond.par_tsk_fond_5%TYPE,
                               p_evt                  VARCHAR2)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_calcul_charge';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
    
    -- -----------------------------
    -- Recherche charge d'un poste
    -- -----------------------------
	CURSOR c_uee_aff (x_no_pos su_atv_rg.cle_rg%TYPE) IS
	    SELECT nb_col,
	           nb_pce,
		       nb_lig,
		       tps
	      FROM v_uee_charge
	     WHERE no_pos =  x_no_pos
	       AND x_no_pos IS NOT NULL;
	
	r_uee_aff           c_uee_aff%ROWTYPE;
	v_charge            NUMBER := 0; 
	v_unite_rg          su_atv_rg.unite_rg%TYPE;
   
   -- --------------------------------------------------------- 
   -- Recherche des postes regroupes + poste de regroupement;
   -- Car charge du poste de regroupement = Charge des postes regroupes + charge non affectee (donc sur poste de rgp);
   -- ---------------------------------------------------------
    CURSOR c_pos_rgp (x_no_pos su_atv_rg.cle_rg%TYPE) IS
	    SELECT no_pos
	      FROM vf_pc_pos
	     WHERE (no_pos_rgp = x_no_pos OR no_pos = x_no_pos)
	       AND x_no_pos IS NOT NULL;
   
    r_pos_rgp            c_pos_rgp%ROWTYPE;
   	
BEGIN
    -- SAVEPOINT my_pc_bas_calcul_charge; -- Pour la gestion de l'exception on fixe un point de rollback.
    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN        
        su_bas_put_debug(v_nom_obj
		                 ||' : cle_rg = '       || p_cle_rg
		                 ||' : p_cod_atv = '    || p_cod_atv
		                 ||' : p_cod_usn = '    || p_cod_usn
		                 ||' : p_typ_cle_rg = ' || p_typ_cle_rg
		                 ||' : p_evt = '        || p_evt);
    END IF;

    /************************
    1) PHASE INITIALISATION 
    ************************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code pré-standard (initialisation de variables)
    
    
    -- Fin du code pré-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel evenement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_CALCUL_CHARGE') THEN 
        v_ret_evt := pc_evt_calcul_charge('PRE', 
		                                  p_cle_rg,
                                          p_typ_cle_rg,
                                          p_cod_atv,
                                          p_cod_usn );
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT 
    ********************/

    v_etape := 'Appel evenement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_CALCUL_CHARGE') THEN 
        v_ret_evt := pc_evt_calcul_charge('ON',
		                                  p_cle_rg,
                                          p_typ_cle_rg,
                                          p_cod_atv,
                                          p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN

        -- ---------------------------------------------------------------------
        -- mettre ici le code de traitement standard
        v_unite_rg := su_bas_gcl_su_atv_rg(p_cod_usn    => p_cod_usn,
		                                   p_cod_atv    => p_cod_atv,
		                                   p_typ_cle_rg => p_typ_cle_rg,
		                                   p_cle_rg     => p_cle_rg,
		    					           p_colonne    => 'UNITE_RG');
										   
		IF su_global_pkv.v_niv_dbg >= 6 THEN        
            su_bas_put_debug(v_nom_obj || ' v_unite_rg '|| v_unite_rg);   
        END IF;
        
        -- --------------------------------
        -- Cas d'un poste de regroupement
        -- --------------------------------
        IF pc_bas_is_pos_rgp(p_cle_rg) = 1 AND su_bas_gcl_su_pos(p_cle_rg, 'CTG_POS') = '1' THEN
            v_etape := 'Rch charge du poste rgp';
            v_charge := 0;
            FOR r_pos_rgp IN c_pos_rgp(p_cle_rg)
            LOOP
                OPEN c_uee_aff(r_pos_rgp.no_pos);
                FETCH c_uee_aff INTO r_uee_aff;
                IF c_uee_aff%NOTFOUND THEN            
                    v_charge := v_charge + 0;
         		    v_etape := 'Chg nulle OU Poste ferme OU cle inconnue '|| r_pos_rgp.no_pos;
         		    IF su_global_pkv.v_niv_dbg >= 6 THEN        
                        su_bas_put_debug(v_nom_obj || ' ' || v_etape);   
                    END IF;
         	    ELSE
         	        --  Selectionner le type de charge demandé
         		    IF v_unite_rg = 'C' THEN -- Colis
         		        v_charge := v_charge + r_uee_aff.nb_col;
         		    ELSIF v_unite_rg = 'P' THEN -- Pièces
         		        v_charge := v_charge + r_uee_aff.nb_pce;
         		    ELSIF v_unite_rg = 'L' THEN -- Lignes-colis
         		        v_charge := v_charge + r_uee_aff.nb_lig;
         		    ELSIF v_unite_rg = 'T' THEN -- En temps
         		        v_charge := v_charge + r_uee_aff.tps;
         		    ELSE
         		       v_charge := v_charge + 0;
         		    END IF;
                    v_etape := 'Charge du poste '|| r_pos_rgp.no_pos || ' = ' || r_uee_aff.nb_col;
         		    IF su_global_pkv.v_niv_dbg >= 6 THEN        
                        su_bas_put_debug(v_nom_obj || ' ' || v_etape);   
                    END IF;
         		    -- NB : l'unite UT n'est pas gérée
                END IF;
                CLOSE c_uee_aff;
         		
                IF su_global_pkv.v_niv_dbg >= 6 THEN        
                    su_bas_put_debug(v_nom_obj ||' : v_charge = ' || v_charge);   
                END IF;
            END LOOP;
        
        -- ----------------------------------------
        -- Cas d'un poste de preparation classique
        -- ----------------------------------------
        ELSE  
            v_etape := 'Rch charge du poste';
            v_charge := 0;
            OPEN c_uee_aff(p_cle_rg);
            FETCH c_uee_aff INTO r_uee_aff;
            IF c_uee_aff%NOTFOUND THEN            
   			    v_etape := 'Chg nulle OU Poste ferme OU cle inconnue '|| p_cle_rg;
   			    IF su_global_pkv.v_niv_dbg >= 6 THEN        
                    su_bas_put_debug(v_nom_obj || ' ' || v_etape);   
                END IF;
   		    ELSE
   		        --  Sélectionner le type de charge demandé
   			    IF v_unite_rg = 'C' THEN -- Colis
   			        v_charge := r_uee_aff.nb_col;
   			    ELSIF v_unite_rg = 'P' THEN -- Pièces
   			        v_charge := r_uee_aff.nb_pce;
   			    ELSIF v_unite_rg = 'L' THEN -- Lignes-colis
   			        v_charge := r_uee_aff.nb_lig;
   		        ELSIF v_unite_rg = 'T' THEN -- En temps
   			        v_charge := r_uee_aff.tps;
   		        ELSE
   		            v_charge := 0;
   		        END IF;
   		        -- NB : l'unite UT n'est pas gérée
            END IF;
            CLOSE c_uee_aff;
   		
            IF su_global_pkv.v_niv_dbg >= 6 THEN        
                su_bas_put_debug(v_nom_obj ||' : v_charge = ' || v_charge);   
            END IF;		
        END IF;
    END IF;

    /**********************
    3) PHASE FINALISATION 
    **********************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code post-standard


    -- Fin du code post-standard 
    -- ---------------------------------------------------------------------

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_CALCUL_CHARGE') THEN 
        v_ret_evt := pc_evt_calcul_charge('POST' ,
		                                  p_cle_rg,
                                          p_typ_cle_rg,
                                          p_cod_atv,
                                          p_cod_usn );
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    END IF;
    
    RETURN TO_CHAR(v_charge);

EXCEPTION
    WHEN OTHERS THEN
        --ROLLBACK TO my_pc_bas_calcul_charge;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cle_rg',
                        p_par_ano_1       => p_cle_rg,
						p_lib_ano_2       => 'p_typ_cle_rg',
                        p_par_ano_2       => p_typ_cle_rg,
						p_lib_ano_3       => 'p_cod_atv',
                        p_par_ano_3       => p_cod_atv,
						p_lib_ano_4       => 'p_cod_usn',
                        p_par_ano_4       => p_cod_usn,						
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
		
		RETURN 'ERROR';				
						
END;

/* $Id$
****************************************************************************
* pc_bas_rch_cod_cfg_serie - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de rechercher le code de configuration de série 
-- à partir un colis 
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
-- 01a,10.03.09,croc    Création 
-- 00a,10.03.09,GENPRG  version 2.12
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON


FUNCTION pc_bas_rch_cod_cfg_serie (
                                   p_no_uee      pc_uee.no_uee%TYPE
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_rch_cod_cfg_serie';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
	v_cod_cfg_serie     pc_ent_cfg_serie.cod_cfg_serie%TYPE := NULL;
	v_cod_pss_afc       su_pss.cod_pss%TYPE;

BEGIN

    --SAVEPOINT my_pc_bas_rch_cod_cfg_serie; <OU NON> -- Pour la gestion de l'exception on fixe un point de rollback.

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_no_uee = ' || p_no_uee);
    END IF;

    v_etape := 'Début';
	v_cod_pss_afc := su_bas_gcl_pc_uee(p_no_uee  => p_no_uee,
		                               p_colonne => 'COD_PSS_AFC'); 
	IF v_cod_pss_afc IS NOT NULL THEN										   
	    v_ret := su_bas_rch_cle_atv_pss(p_cod_pss    => v_cod_pss_afc,
								    	p_typ_atv    => 'AFF',	        -- Type d'activité 
									    p_cod_cfg    => 'COD_CFG_SERIE',
									    p_val        => v_cod_cfg_serie); 
	END IF;

    RETURN v_cod_cfg_serie;

EXCEPTION
    WHEN OTHERS THEN
        --ROLLBACK TO my_pc_bas_rch_cod_cfg_serie;<ou non>
		-- Pas d'exception si utilisation dans un select 
        RETURN NULL;
END;



END; -- fin du package
/
show errors;


