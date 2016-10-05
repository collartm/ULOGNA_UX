/* $Id$ */
/*
****************************************************************************
* pc_integration_pkg - package d'integration
*/
-- DESCRIPTION :
-- -------------
-- ce package contient toutes les fonctions pour le mécanisme d'intégration des
-- commandes usines en commande de préparation
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03b,17.10.12,alfl    suppression de su_bas_ala_marche
-- 03a,09.02.12,alfl    gestion des filtres cadencier pour la completion
-- 02a,18.09.08,alfl    gestion mode 2 completion optionnelle 
-- 01b,17.09.08,rbel    gestion mode_afc_dpt demandant aucune notion de départ
-- 01a,05.12.06,JDRE	Initialisation..
-- -------------------------------------------------------------------------
--

CREATE OR REPLACE PACKAGE BODY pc_integration_pkg AS

/*
****************************************************************************
* pc_bap_TRFCBPRX01 - Evenement metier standardisé
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction realise la translation de variante code barres prix vers
-- une variante code barres poids.
--
-- <BAP>
-- <NAME>TRFCBPRX01</>
-- <TITLE>MODIFICATION DE VARIANTE CB PRIX EN VARIANTE CB POIDS</>
-- <CHAR>P_VECB</>
-- <CHAR>P_TYPE</>
-- <CHAR>P_CLEF_PRX</>
-- <CHAR>P_CC_PDS</>
-- </BAP>
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,16.07.08,mnev    correction recherche en fct du type
-- 01a,21.12.07,mnev    initiale
-- 00a,15.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
-- RETOUR
----------
-- La variante verifiée ou ERROR si probleme
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bap_TRFCBPRX01 (p_vecb  IN  VARCHAR2,
                            p_type  IN  VARCHAR2)
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bap_TRFCBPRX01';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_ret               VARCHAR2(1000) := 'OK';

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20)    := 'BAP_TRFCBPRX01';

    v_clef_prx          VARCHAR2(1000)  := ';PC_XXX_03;PC_XXX_04;PC_XXX_05;PC_XXX_06;PC_XXX_07;PC_XXX_08;PC_XXX_09;PC_XXX_10;';
    v_cc_pds            VARCHAR2(100)   := 'PC_XXX_12';


BEGIN

    SAVEPOINT my_point_bap_TRFCBPRX01;  -- Pour la gestion de l'exception on fixe un point de rollback.

    /************************
    1) PHASE INITIALISATION
    ************************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code pré-standard (initialisation contexte ...)
    v_etape := 'replace';
    v_clef_prx := REPLACE(v_clef_prx,'XXX',p_type);
    v_cc_pds   := REPLACE(v_cc_pds  ,'XXX',p_type);

    v_etape := 'creation ctx';
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'p_vecb', p_vecb);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'p_type', p_type);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'p_clef_prx', v_clef_prx);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'p_cc_pds', v_cc_pds);

    -- Fin du code pré-standard
    -- ---------------------------------------------------------------------

    /********************
    2) PHASE TRAITEMENT
    ********************/

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN
        v_etape := 'Appel événement ON';
        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_' || v_event);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        v_etape := 'Traitement standard';
        -- ---------------------------------------------------------------------
        -- mettre ici le code de traitement standard

        IF INSTR (v_clef_prx, ';' || p_vecb || ';') > 0 THEN
            v_ret := v_cc_pds;
        ELSE
            v_ret := p_vecb;
        END IF;

        -- Fin du code standard
        -- ---------------------------------------------------------------------
    ELSE
        v_ret := v_ret_evt;
    END IF;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj|| ' v_ret:' || v_ret);
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_point_bap_TRFCBPRX01;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_vecb',
                        p_par_ano_1       => p_vecb,
                        p_lib_ano_2       => 'p_type',
                        p_par_ano_2       => p_type,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;

/*
****************************************************************************
* pc_bap_FINCPLIG01 - Evenement metier standardisé
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction realise un traitement de finalisation de la complétion
-- d'une ligne usine.
--
-- <BAP>
-- <NAME>FINCPLIG01</>
-- <TITLE>FINALISATION COMPLETION LIGNE COMMANDE USINE</>
-- <CHAR>p_no_cmd</>
-- <CHAR>p_no_lig_cmd</>
-- <CHAR>p_typ_lig_cmd</>
-- </BAP>
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,02.07.08,mnev    initiale
-- 00a,05.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
-- RETOUR
----------
-- La variante verifiée ou ERROR si probleme
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bap_FINCPLIG01 (p_no_cmd        IN  pc_lig_cmd.no_cmd%TYPE,
                            p_no_lig_cmd    IN  pc_lig_cmd.no_lig_cmd%TYPE,
                            p_typ_lig_cmd   IN  pc_lig_cmd.typ_lig_cmd%TYPE)
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bap_FINCPLIG01';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_ret               VARCHAR2(1000) := 'OK';

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20)    := 'FINCPLIG01';

BEGIN

    SAVEPOINT my_point_bap_FINCPLIG01;  -- Pour la gestion de l'exception on fixe un point de rollback.

    /************************
    1) PHASE INITIALISATION
    ************************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code pré-standard (initialisation contexte ...)

    v_etape := 'creation ctx';
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'p_no_cmd', p_no_cmd);
    v_add_ctx := su_ctx_pkg.su_bas_set_number(v_ctx,'p_no_lig_cmd', p_no_lig_cmd);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'p_typ_lig_cmd', p_typ_lig_cmd);

    -- Fin du code pré-standard
    -- ---------------------------------------------------------------------

    /********************
    2) PHASE TRAITEMENT
    ********************/

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN
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
        ROLLBACK TO my_point_bap_FINCPLIG01;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_cmd',
                        p_par_ano_1       => p_no_cmd,
                        p_lib_ano_2       => 'no_lig_cmd',
                        p_par_ano_2       => TO_CHAR(p_no_lig_cmd),
                        p_lib_ano_3       => 'typ_lig',
                        p_par_ano_3       => p_typ_lig_cmd,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;

/*
****************************************************************************
* pc_bap_DECULMAX01 - Evenement metier standardisé
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction recherche la VL feuille avec son niveau d'arboresence 
--
-- <BAP>
-- <NAME>DECULMAX01</>
-- <TITLE>RECHERCHE DE L'UL MAX POUR L'OPERATION DE DECOUPAGE</>
-- <CHAR>p_cod_pro</>
-- <CHAR>p_cod_vl</>
-- <NUM>p_qte_cde</>
-- <NUM>p_pcb_exp</>
-- <CHAR>p_cod_usn</>
-- <CHAR>p_cod_pss</>
-- <NUM>p_last_niv</>
-- </BAP>
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,18.02.11,mnev    initiale
-- 00a,05.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
-- RETOUR
----------
-- chaine de la forme : <COD_VL_FEUILLE>valeur</> <LAST_NIV>valeur</>
-- 'ERROR' si probleme
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bap_DECULMAX01 (p_cod_pro                  PC_LIG_COM.COD_PRO%TYPE,
                            p_cod_vl                   PC_LIG_COM.COD_VL%TYPE,
                            p_qte_cde                  PC_LIG_COM.QTE_CDE%TYPE, -- en UB
                            p_pcb_exp    	  		   PC_LIG_COM.PCB_EXP%TYPE,
                            p_cod_usn                  PC_ENT_COM.COD_USN%TYPE,
                            p_cod_pss                  PC_LIG_COM.COD_PSS_AFC%TYPE,
                            p_last_niv                 NUMBER)
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bap_DECULMAX01';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret_evt           VARCHAR2(2000) := NULL;

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20)    := 'DECOUPE_UL_MAX';

BEGIN

    SAVEPOINT my_point_bap_DECULMAX01;  -- Pour la gestion de l'exception on fixe un point de rollback.

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN

        v_etape := 'creation ctx';
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_PRO' , p_cod_pro);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_VL' , p_cod_vl);
        v_add_ctx := su_ctx_pkg.su_bas_set_number(v_ctx,'QTE_CDE' , p_qte_cde);
        v_add_ctx := su_ctx_pkg.su_bas_set_number(v_ctx,'PCB_EXP' , p_pcb_exp);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_USN' , p_cod_usn);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_PSS_AFC' , p_cod_pss);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'LAST_NIV' , p_last_niv);

        v_etape := 'Appel événement ON';
        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_' || v_event);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj|| ' v_ret:' || v_ret_evt);
    END IF;

    RETURN v_ret_evt;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_point_bap_DECULMAX01;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_pro',
                        p_par_ano_1       => p_cod_pro,
                        p_lib_ano_2       => 'cod_vl',
                        p_par_ano_2       => p_cod_vl,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;

/*
****************************************************************************
* pc_bap_DECTYPCOL01 - Evenement metier standardisé
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction calcul le type de colis porté par la ligne de commande 
-- de preparation (typ_col) 
--
-- <BAP>
-- <NAME>DECULMAX01</>
-- <TITLE>RECHERCHE DU TYPE DE COLIS POUR LA LIGNE DE COMMANDE</>
-- <CHAR>p_cod_com</>
-- <NUM>p_no_lig_com</>
-- <CHAR>p_cod_pro</>
-- <CHAR>p_cod_vl_inf</>
-- <CHAR>p_lst_post_col</>
-- </BAP>
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,18.02.11,mnev    initiale
-- 00a,05.05.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
-- RETOUR
----------
-- type de colis OU NULL si pas traité OU 'ERROR' si probleme
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bap_DECTYPCOL01 (p_no_com                  PC_LIG_COM.NO_COM%TYPE,
                             p_no_lig_com              PC_LIG_COM.NO_LIG_COM%TYPE,
                             p_cod_pro                 PC_LIG_COM.COD_PRO%TYPE,
                             p_cod_vl_inf    	  	   PC_LIG_COM.COD_VL%TYPE,
                             p_lst_post_col            VARCHAR2) 
RETURN VARCHAR2 IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bap_DECTYPCOL01';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret_evt           VARCHAR2(100)  := NULL;

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20)    := 'PC_DECOUPE_TYP_COL';

BEGIN

    SAVEPOINT my_point_bap_DECTYPCOL01;  -- Pour la gestion de l'exception on fixe un point de rollback.

    /************************
    1) PHASE INITIALISATION
    ************************/

    -- ---------------------------------------------------------------------
    -- mettre ici le code pré-standard (initialisation contexte ...)

    v_etape := 'creation ctx';
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'NO_COM' , p_no_com);
    v_add_ctx := su_ctx_pkg.su_bas_set_number(v_ctx,'NO_LIG_COM' , p_no_lig_com);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_PRO' , p_cod_pro);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_VL_INF' , p_cod_vl_inf);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'LST_POST_COL' , p_lst_post_col);

    -- Fin du code pré-standard
    -- ---------------------------------------------------------------------

    /********************
    2) PHASE TRAITEMENT
    ********************/

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN
        v_etape := 'Appel événement ON';
        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_' || v_event);
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj|| ' v_ret:' || v_ret_evt);
    END IF;

    RETURN v_ret_evt;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_point_bap_DECTYPCOL01;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_com',
                        p_par_ano_1       => p_no_com,
                        p_lib_ano_2       => 'no_lig_com',
                        p_par_ano_2       => TO_CHAR(p_no_lig_com),
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        RETURN 'ERROR';
END;

/****************************************************************************
*  pc_bas_atv_gestion_prx
*/
-- DESCRIPTION :
-- -------------
-- Translation des codes a barres prix en codes a barres poids s'il manque
-- l'info prix dans la ligne commande.
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,18.02.08,mnev    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
-- p_r_lig_cmd : record ligne commande usine
--
-- RETOUR :
-- --------
-- OK ou ERROR
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_atv_gestion_prx (p_r_lig                IN OUT  NOCOPY pc_lig_cmd%ROWTYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_gestion_prx';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;

    v_ret               VARCHAR2(100) := 'OK';
    v_rt2               VARCHAR2(100);

    v_code              VARCHAR2(1000) := NULL;
    v_p1                BOOLEAN := FALSE;
    v_p2                BOOLEAN := FALSE;

BEGIN

    v_etape:='debut';

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||' Ligne Commande Usine '||p_r_lig.no_cmd|| '-'||to_char(p_r_lig.no_lig_cmd));
    END IF;

    IF p_r_lig.cfg_dev_prx IS NULL THEN
        -- controle par defaut
        v_code := NULL;
    ELSE
        -- Lecture configuration du code devise prix
        v_code := su_bas_rch_action (p_nom_par   => 'CFG_DEV_PRX',
                                     p_par       => p_r_lig.cfg_dev_prx,
                                     p_no_action => 1);
        IF v_code = 'ERROR' THEN
            -- ?
            NULL;
        END IF;
    END IF;

    IF p_r_lig.prx_pds_1 IS NOT NULL AND p_r_lig.prx_pds_2 IS NULL THEN
       p_r_lig.prx_pds_2 := p_r_lig.prx_pds_1 * 6.55957;
    END IF;


    IF (p_r_lig.prx_pds_1 IS NULL AND INSTR(v_code,'CB1') > 0) THEN
        v_p1 := TRUE;
    END IF;
    IF (p_r_lig.prx_pds_2 IS NULL AND INSTR(v_code,'CB2') > 0) THEN
        v_p2 := TRUE;
    END IF;

    IF v_p1 OR v_p2 THEN

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||' Un controle doit etre fait');
        END IF;

        -- verification CB piece
        v_ret := pc_bap_TRFCBPRX01(p_r_lig.cod_vecb_pce,'PCE');
        IF v_ret <> 'ERROR' AND v_ret <> p_r_lig.cod_vecb_pce THEN
            v_etape := 'Création enregistrement dans journal de préparation';
            v_rt2 := pc_bas_cre_pc_his (p_typ =>'CMD',
                                        p_cle1 => p_r_lig.no_cmd,
                                        p_cle2 => p_r_lig.no_lig_cmd,
                                        p1     => 'PCE',
                                        p2     => p_r_lig.cod_vecb_pce,
                                        p3     => v_ret,
                                        p_act   =>'PC_HIS_VECB_LIG_CMD');
            p_r_lig.cod_vecb_pce := v_ret;

        END IF;

        -- verification CB colis
        v_ret := pc_bap_TRFCBPRX01(p_r_lig.cod_vecb_col,'COL');
        IF v_ret <> 'ERROR' AND v_ret <> p_r_lig.cod_vecb_col THEN
            v_etape := 'Création enregistrement dans journal de préparation';
            v_rt2 := pc_bas_cre_pc_his (p_typ =>'CMD',
                                        p_cle1 => p_r_lig.no_cmd,
                                        p_cle2 => p_r_lig.no_lig_cmd,
                                        p1     => 'COL',
                                        p2     => p_r_lig.cod_vecb_col,
                                        p3     => v_ret,
                                        p_act   =>'PC_HIS_VECB_LIG_CMD');
            p_r_lig.cod_vecb_col := v_ret;

        END IF;

        -- verification CB palette
        v_ret := pc_bap_TRFCBPRX01(p_r_lig.cod_vecb_pal,'PAL');
        IF v_ret <> 'ERROR' AND v_ret <> p_r_lig.cod_vecb_pal THEN
            v_etape := 'Création enregistrement dans journal de préparation';
            v_rt2 := pc_bas_cre_pc_his (p_typ =>'CMD',
                                        p_cle1 => p_r_lig.no_cmd,
                                        p_cle2 => p_r_lig.no_lig_cmd,
                                        p1     => 'PAL',
                                        p2     => p_r_lig.cod_vecb_pal,
                                        p3     => v_ret,
                                        p_act   =>'PC_HIS_VECB_LIG_CMD');
            p_r_lig.cod_vecb_pal := v_ret;

        END IF;

    END IF;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||' cod_vecb_pce : '||p_r_lig.cod_vecb_pce);
        su_bas_put_debug(v_nom_obj||' cod_vecb_col : '||p_r_lig.cod_vecb_col);
        su_bas_put_debug(v_nom_obj||' cod_vecb_pal : '||p_r_lig.cod_vecb_pal);
    END IF;

    RETURN 'OK';

EXCEPTION
     WHEN OTHERS THEN
         su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'LigCmd usn',
                        p_par_ano_1       => p_r_lig.no_cmd,
                        p_lib_ano_2       => 'No Ligne ',
                        p_par_ano_2       => TO_CHAR(p_r_lig.no_lig_cmd),
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
      IF v_ret='OK' OR v_ret IS NULL OR v_ret = 'ERROR' THEN
          RETURN NVL(v_cod_err_su_ano,'ERROR');
      ELSE
          RETURN v_ret;
      END IF;
END;



/****************************************************************************
*   pc_bas_atv_integration_loop -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction est appelé par la tache de fond et permet de lancer
-- le mécanisme d'intégration
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,13.10.14,croc    Maj global_pkv.v_cod_usn
-- 01a,06.12.06,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  WAIT ou EXIT
--
-- COMMIT :
-- --------
--   NON

PROCEDURE pc_bas_atv_integration_loop(p_id_tsk VARCHAR2,
                          p_par_tsk_fond_1 VARCHAR2,
                          p_par_tsk_fond_2 VARCHAR2,
                          p_par_tsk_fond_3 VARCHAR2,
                          p_par_tsk_fond_4 VARCHAR2,
                          p_par_tsk_fond_5 VARCHAR2,
                          p_cod_ope_tsk VARCHAR2,
                          p_tps_cycle NUMBER,
                          p_cmd_unix OUT VARCHAR2,
                          p_ret OUT VARCHAR2)
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_integration_loop';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;

    v_par_tsk_fond_1  VARCHAR2(2000);
    v_position        INTEGER;
    v_cod_usn 	      VARCHAR2(2000);
	v_ret             VARCHAR2(100) := NULL;
	v_id_tsk		  VARCHAR2(2000):=p_id_tsk;
    v_cod_usn_mem     su_usn.cod_usn%TYPE;--Mémorisation du code usine global

    --
	CURSOR c_usn IS
	    SELECT cod_usn
        FROM su_usn;
		

BEGIN
    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||' : p_par_tsk_fond_1 = ' || p_par_tsk_fond_1||' / Debut traitement = ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:ss'));
    END IF;

    -- Initialisation du context
    v_etape := 'Initialisation context';
    su_bas_init_context;

    v_par_tsk_fond_1:= p_par_tsk_fond_1 ;
    LOOP
        -- split du code usine
        v_position :=  instr(v_par_tsk_fond_1,';');
        IF (nvl(v_position,0) = 0) THEN
            v_cod_usn:= v_par_tsk_fond_1;
        ELSE
            v_cod_usn:=LTRIM(RTRIM(SUBSTR(v_par_tsk_fond_1,1,v_position-1)));
            v_par_tsk_fond_1 := SUBSTR(v_par_tsk_fond_1,v_position+1);
        END IF;

        IF v_cod_usn='*' THEN
            OPEN c_usn;
            LOOP
                FETCH c_usn INTO v_cod_usn;
                EXIT WHEN c_usn%NOTFOUND;
                v_etape:='Intégration usine : ' || v_cod_usn;
                
                v_cod_usn_mem:=su_global_pkg.su_bas_get_cod_usn; -- Mémoriser la variable usine                           
                su_global_pkg.su_bas_set_cod_usn(v_cod_usn); --$MOD,20141013,croc trac 25425 
                IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj||' : v_cod_usn = '|| v_cod_usn
                                          ||' su_global_pkv.v_cod_usn '||su_global_pkv.v_cod_usn 
                                          ||' v_cod_usn_mem '||v_cod_usn_mem);
                END IF;                            
                v_ret:=pc_bas_atv_integration(p_cod_usn =>v_cod_usn);
                   
                su_global_pkg.su_bas_set_cod_usn(v_cod_usn_mem);-- Reprendre la variable usine
                
                IF v_ret <> 'OK' THEN
                    v_niv_ano:= 2;
                    v_cod_err_su_ano := 'PC-INT-001';
                    RAISE err_except;
                END IF;
            END LOOP;
            CLOSE c_usn;

        ELSIF v_cod_usn IS NOT NULL THEN
            v_etape:='Intégration usine : '|| v_cod_usn;
            
            v_cod_usn_mem:=su_global_pkg.su_bas_get_cod_usn; -- Mémoriser la variable usine                           
            su_global_pkg.su_bas_set_cod_usn(v_cod_usn); --$MOD,20141013,croc trac 25425
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                    su_bas_put_debug(v_nom_obj||' : v_cod_usn = '|| v_cod_usn
                                          ||' su_global_pkv.v_cod_usn '||su_global_pkv.v_cod_usn 
                                          ||' v_cod_usn_mem '||v_cod_usn_mem);
            END IF;
            v_ret:=pc_bas_atv_integration(p_cod_usn =>v_cod_usn);
            
            su_global_pkg.su_bas_set_cod_usn(v_cod_usn_mem);-- Reprendre la variable usine
            
            IF v_ret <> 'OK' THEN
                v_niv_ano :=2;
                v_cod_err_su_ano := 'PC-INT-001';
                RAISE err_except;
            END IF;
        END IF;
        EXIT WHEN (NVL(v_position,0) = 0);
    END LOOP;

    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||' : p_par_tsk_fond_1 = ' || p_par_tsk_fond_1||' / Fin traitement = ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:ss'));
    END IF;

    p_ret := 'WAIT';

EXCEPTION
    WHEN OTHERS THEN
      IF c_usn%ISOPEN THEN
		  CLOSE c_usn;
	  END IF;

      su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_niv_ano=>v_niv_ano,
                        p_cod_usn=>v_cod_usn,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_par_tsk_fond_1,
                        p_lib_ano_2       => 'Id stk',
                        p_par_ano_2       => v_id_tsk,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_INT_ECHEC');

      p_ret := 'EXIT';
END;

/****************************************************************************
*   pc_bas_atv_integration -
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction  permet de lancer toutes les sous fonctions nécessaires pour
-- le mécanisme d'intégration (complétion,regroupement,decoupage,qvt)
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,06.12.06,JDRE    initialisation
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

FUNCTION pc_bas_atv_integration (
    p_cod_usn                  SU_USN.COD_USN%TYPE
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_integration';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||' : Usine <' || p_cod_usn || '>');
    END IF;

    /************************
    1) PHASE INITIALISATION
    ************************/
    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_INTEGRATION') THEN
        v_ret_evt := pc_evt_atv_complete('PRE' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_niv_ano:=2;
          v_cod_err_su_ano := 'PC-INT-100' ;
          RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_ATV_INTEGRATION') THEN
        v_ret_evt := pc_evt_atv_complete('ON' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
            v_niv_ano:=2;
            RAISE err_except;
            v_cod_err_su_ano := 'PC-INT-101' ;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN

        -- init des variables de comptage
        pc_integration_pkv.v_nb_cpl := 0;
        pc_integration_pkv.v_nb_rgp := 0;
        pc_integration_pkv.v_nb_dec := 0;
        pc_integration_pkv.v_nb_qvt := 0;

        v_etape := 'IDP integration';
        su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_INT002',
                                     p_cod_idp => 'INT');

        v_etape := 'Complétion';
		v_ret:=pc_integration_pkg.pc_bas_atv_complete(p_cod_usn=>p_cod_usn);
        IF v_ret<>'OK' THEN
            v_niv_ano:=2;
            v_cod_err_su_ano := 'PC-INT-002';

            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_niv_ano         => 2 ,
                            p_cod_usn         => p_cod_usn,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'Code usine',
                            p_par_ano_1       => p_cod_usn,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         =>  'PC_INT_ECHEC'   );
        END IF;

        v_etape := 'Regroupe';
		v_ret:=pc_integration_pkg.pc_bas_atv_regroupe(p_cod_usn=>p_cod_usn);
        IF v_ret<>'OK' THEN
            v_niv_ano:=2;
            v_cod_err_su_ano := 'PC-INT-003';

            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_niv_ano         =>  2 ,
                            p_cod_usn         =>  p_cod_usn,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'Code usine',
                            p_par_ano_1       => p_cod_usn,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         =>  'PC_INT_ECHEC'   );
        END IF;

        v_etape := 'Decoupe';
		v_ret:=pc_integration_pkg.pc_bas_atv_decoupe(p_cod_usn=>p_cod_usn);
        IF v_ret<>'OK' THEN
            v_niv_ano:=2;
            v_cod_err_su_ano := 'PC-INT-004';

            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_niv_ano         =>  2 ,
                            p_cod_usn         =>  p_cod_usn,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'Code usine',
                            p_par_ano_1       => p_cod_usn,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         =>  'PC_INT_ECHEC');
        END IF;

        v_etape := 'Qualification-Volume-Transport';
		v_ret:=pc_integration_pkg.pc_bas_atv_qvt(p_cod_usn=>p_cod_usn);
        IF v_ret<>'OK' THEN
            v_niv_ano:=2;
            v_cod_err_su_ano := 'PC-INT-005';

            
            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_niv_ano         =>  2 ,
                            p_cod_usn         =>  p_cod_usn,
                            p_cod_err_ora_ano => SQLCODE,
                            p_lib_ano_1       => 'Code usine',
                            p_par_ano_1       => p_cod_usn,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         =>  'PC_INT_ECHEC');
        END IF;

        IF NVL(pc_integration_pkv.v_nb_cpl,0) + NVL(pc_integration_pkv.v_nb_rgp,0) +
           NVL(pc_integration_pkv.v_nb_dec,0) + NVL(pc_integration_pkv.v_nb_qvt,0) > 0 THEN

            -- ecriture idp integration : somme des opérations sur les 4 traitements de base 
            su_perf_pkg.su_bas_write_idp(p_typ_idp => 'PC_INT002',
                                         p_cod_idp => 'INT',
                                         p_info    => TO_CHAR(NVL(pc_integration_pkv.v_nb_cpl,0) +
                                                              NVL(pc_integration_pkv.v_nb_rgp,0) +
                                                              NVL(pc_integration_pkv.v_nb_dec,0) +
                                                              NVL(pc_integration_pkv.v_nb_qvt,0)),
                                         p_cod_usn => p_cod_usn);
        END IF;

    END IF;
    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||' ' ||
                     TO_CHAR(NVL(pc_integration_pkv.v_nb_cpl,0)) || ' Completions. ' ||
                     TO_CHAR(NVL(pc_integration_pkv.v_nb_rgp,0)) || ' Regroupements. ' || 
                     TO_CHAR(NVL(pc_integration_pkv.v_nb_dec,0)) || ' Decoupages. ' ||
                     TO_CHAR(NVL(pc_integration_pkv.v_nb_qvt,0)) || ' Qualif. ');
    END IF;

    /**********************
    3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_INTEGRATION') THEN
        v_ret_evt := pc_evt_atv_complete('POST' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
            v_cod_err_su_ano := 'PC-INT-102' ;
            RAISE err_except;
        END IF;
    END IF;


    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_niv_ano         =>v_niv_ano ,
                        p_cod_usn         =>  p_cod_usn,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'N° de tache',
                        p_par_ano_2       => '',
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_INT_ECHEC');

        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;

END;

/****************************************************************************
*   pc_bas_atv_complete -
*/
-- DESCRIPTION :
-- -------------
-- Fonction de complétion des commandes usines
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 04d,14.04.11,mnev    Modif date de reference pour prise en compte des cdes
--                      a compléter.
-- 04c,30.09.10,rbel    ajout test que MOD_PAL_1 n'est pas NULL
-- 04a,02.06.10,mnev    ajout test sur etat de l'entete pour eviter une
--                      completion inutile.
--                      ajout idp. 
-- 03a,18.08.09,alfl    gestion mode completion 2 , completion optionnelle
-- 02b,02.07.09,tcho    oprimisation requete rch commande
-- 02a,11.04.07,ALFL    integration completion avec cadencier
-- 01a,06.12.06,JDRE    initialisation
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
--   OUI

FUNCTION pc_bas_atv_complete (
    p_cod_usn                  SU_USN.COD_USN%TYPE
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 04d $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_complete';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
    v_maxc_c            INTEGER;
    v_visib_cplt        VARCHAR2(20);
    v_mode_cplt         VARCHAR2(20);
    v_cpt               INTEGER:=0;
    v_cpt_lig           INTEGER:=0;
    v_etat_lig_ini      VARCHAR2(20);
    v_etat_ent_ini      NUMBER;
    v_etat_lig_fin      VARCHAR2(20);
    v_etat_ent_fin      VARCHAR2(20);
    v_tps               DATE;

     -- Recherche des commandes usine ayant soit l'entete ou la ligne à compléter
    CURSOR c_cmd_e(x_dat_min date,
                   x_dat_max date,
                   x_max INTEGER,
                   x_etat_ent_ini NUMBER,
                   x_etat_lig_ini VARCHAR2) IS
    SELECT E.*
    FROM   pc_ent_cmd E
    WHERE  NVL(E.dat_prep,NVL(E.dat_exp,NVL(E.dat_liv,E.dat_dem)))>=x_dat_min
       AND NVL(E.dat_prep,NVL(E.dat_exp,NVL(E.dat_liv,E.dat_dem)))<=x_dat_max
       AND E.cod_usn=p_cod_usn
       AND x_etat_ent_ini<=su_bas_etat_val_num(etat_atv_pc_ent_cmd,'PC_ENT_CMD')
       AND E.cod_err_pc_ent_cmd IS NULL
	   AND EXISTS(SELECT 1
                    FROM pc_lig_cmd l
                   WHERE cod_err_pc_lig_cmd IS NULL
                     AND etat_atv_pc_LIG_cmd=x_etat_lig_ini
                     AND l.no_cmd=E.no_cmd
                  )
    ORDER BY  dat_prep, dat_exp, dat_liv, dat_crea;

    r_cmd_e c_cmd_e%ROWTYPE;

     -- Recherche des lignes de commande usine  à compléter
    CURSOR c_cmd_l(x_no_cmd pc_ent_cmd.no_cmd%TYPE,x_etat_lig_ini VARCHAR2,autorisation VARCHAR2) IS
    SELECT L.*
    FROM   pc_lig_cmd L
    WHERE  L.no_cmd=x_no_cmd AND
           L.etat_atv_pc_lig_cmd=x_etat_lig_ini
           AND autorisation = 'OK';

    r_cmd_l c_cmd_l%ROWTYPE;

BEGIN


    SAVEPOINT my_sp_bas_complete;

    /************************
    1) PHASE INITIALISATION
    ************************/

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_cod_usn = ' || p_cod_usn);
    END IF;
    v_etat_ent_ini:=su_bas_etat_val_num('CREATION_FIN','PC_ENT_CMD');
    v_etat_lig_ini:=su_bas_rch_etat_atv('CREATION_FIN','PC_LIG_CMD');
    v_etat_ent_fin:=su_bas_rch_etat_atv('COMPLETION','PC_ENT_CMD');
    v_etat_lig_fin:=su_bas_rch_etat_atv('COMPLETION','PC_LIG_CMD');

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_COMPLETE') THEN
        v_ret_evt := pc_evt_atv_complete('PRE' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-100' ;
          RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_ATV_COMPLETE') THEN
        v_ret_evt := pc_evt_atv_complete('ON' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-101' ;
          RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN

        -- ooooooooooooooooooooo
        --  TRAITEMENT STANDARD
        -- ooooooooooooooooooooo

        v_etape := 'Recherche des clés de configuration MODE_CPLT';
        v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                      p_typ_atv =>pc_integration_pkv.v_cod_atv,
                                      p_cod_cfg=>'MODE_CPLT',
                                      p_val=>v_mode_cplt);
        IF v_ret<>'OK' then
            v_cod_err_su_ano := 'PC-INT-009' ;
            RAISE err_except;
        END IF;

        v_etape := 'Recherche des clés de configuration MAXC_C';
        v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                      p_typ_atv =>pc_integration_pkv.v_cod_atv,
                                      p_cod_cfg=>'MAXC_C',
                                      p_val=>v_maxc_c);
        IF v_ret<>'OK' then
            v_cod_err_su_ano := 'PC-INT-010' ;
            RAISE err_except;
        END IF;

        v_etape := 'Recherche des clés de configuration VISIB_CPLT';
        v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                      p_typ_atv =>pc_integration_pkv.v_cod_atv ,
                                      p_cod_cfg=>'VISIB_CPLT',
                                      p_val=>v_visib_cplt);
        IF v_ret<>'OK' then
            v_cod_err_su_ano := 'PC-INT-011' ;
            RAISE err_except;
        END IF;

        v_etape := 'Recherche des commandes usines à traiter';

        v_tps := sysdate+(to_number(v_maxc_c)/(86400));

        IF su_global_pkv.v_niv_dbg >= 9 THEN
            su_bas_put_debug(v_nom_obj||' : Open c_cmd_e');
        END IF;

        OPEN c_cmd_e(sysdate-TO_NUMBER(v_visib_cplt),sysdate+TO_NUMBER(v_visib_cplt),
                     TO_NUMBER(v_maxc_c),v_etat_ent_ini,v_etat_lig_ini);
        LOOP
            FETCH c_cmd_e INTO r_cmd_e;

            EXIT WHEN c_cmd_e%NOTFOUND;
            EXIT WHEN sysdate>v_tps;

            IF su_global_pkv.v_niv_dbg >= 9 THEN
                su_bas_put_debug(v_nom_obj||' : Found c_cmd_e');
            END IF;

            v_cpt:=v_cpt+1;

            IF su_bas_etat_val_num (r_cmd_e.etat_atv_pc_ent_cmd,'PC_ENT_CMD') < 
               su_bas_etat_val_num (v_etat_ent_fin,'PC_ENT_CMD') THEN

                IF v_mode_cplt IN ('1','2') THEN 
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' : completion commande cmd = ' || r_cmd_e.no_cmd);
                    END IF;

                    su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_INT001',
                                                 p_cod_idp => 'ENT');
    
                    v_etape := 'Complétion ENT';
                    v_ret := pc_bas_atv_completion_cad_ent(r_cmd_e,v_mode_cplt);
    
                    su_perf_pkg.su_bas_write_idp(p_typ_idp => 'PC_INT001',
                                                 p_cod_idp => 'ENT',
                                                 p_cod_usn => p_cod_usn);

                    IF v_ret ='OK' THEN
                        -- mise a jour table
                        v_ret:=su_bas_urw_pc_ent_cmd(p_mode => '1',
                                                     rec    => r_cmd_e);
    
                        v_etape := 'MAJ statut pc_ent_cmd mode avec completion';
                        UPDATE pc_ent_cmd SET
                            etat_atv_pc_ent_cmd=v_etat_ent_fin
                        WHERE no_cmd=r_cmd_e.no_cmd;

                    ELSE
                        -- probleme de completion
                        v_etape := 'MAJ statut pc_ent_cmd mode avec completion';
                        UPDATE pc_ent_cmd SET
                            cod_err_pc_ent_cmd= 'PC-INT-310'
                        WHERE no_cmd=r_cmd_e.no_cmd;

                                                                
                         su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_niv_ano        =>  2,
                            p_cod_usn         =>  p_cod_usn,
                            p_cod_err_ora_ano => SQLCODE,
                            p_cod_err_su_ano  => 'PC-INT-310',
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         =>  'PC_INT_ENT_CMD');
                

                    END IF;

                ELSE
                    v_etape := 'MAJ statut pc_ent_cmd mode sans completion';
                    UPDATE pc_ent_cmd SET
                        etat_atv_pc_ent_cmd=v_etat_ent_fin
                    WHERE no_cmd=r_cmd_e.no_cmd;
                END IF;

            END IF;

            IF su_global_pkv.v_niv_dbg >= 9 THEN
                su_bas_put_debug(v_nom_obj||' : Open c_cmd_l');
            END IF;

            v_etape := 'Recherche des lignes de commandes usines à traiter';
            OPEN c_cmd_l (r_cmd_e.no_cmd,v_etat_lig_ini,v_ret);
            LOOP
                FETCH c_cmd_l INTO r_cmd_l;
                EXIT WHEN c_cmd_l%NOTFOUND;

                IF su_global_pkv.v_niv_dbg >= 9 THEN
                    su_bas_put_debug(v_nom_obj||' : Fetch c_cmd_l');
                END IF;

                v_cpt_lig:=v_cpt_lig+1;

		        -- completion obligatoire ou optionnelle
                IF v_mode_cplt = '1' OR v_mode_cplt='2' THEN

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' : completion ligne cmd = ' || r_cmd_l.no_cmd || '-' || TO_CHAR(r_cmd_l.no_lig_cmd));
                    END IF;

                    su_perf_pkg.su_bas_start_idp(p_typ_idp => 'PC_INT001',
                                                 p_cod_idp => 'LIG');

                    v_etape := 'Complétion LIG';
                    v_ret := pc_bas_atv_completion_cad_lig(r_cmd_l,v_mode_cplt);

                    su_perf_pkg.su_bas_write_idp(p_typ_idp => 'PC_INT001',
                                                 p_cod_idp => 'LIG',
                                                 p_cod_usn => p_cod_usn);

                    IF v_ret ='OK' THEN

                        -- Translation des VECB prix en VECB poids
                        -- si prix absent
                        v_etape := 'Translate CBPRX';
                        IF r_cmd_l.prx_pds_1 IS NULL OR r_cmd_l.prx_pds_2 IS NULL THEN
                            -- analyse des VECB ...
                            v_ret := pc_bas_atv_gestion_prx(r_cmd_l);
                        END IF;

                        -- la completion s'est bien passée
                        -- mise a jour table
                        v_etape := 'MAJ row pc_lig_cmd';
                        v_ret:=su_bas_urw_pc_lig_cmd(p_mode =>'1',rec =>r_cmd_l);

                        -- completion ligne
                        v_etape := 'BAP FINCPLIG01';
                        v_ret := pc_bap_FINCPLIG01(r_cmd_l.no_cmd,
                                                   r_cmd_l.no_lig_cmd,
                                                   r_cmd_l.typ_lig_cmd);

                        IF v_ret = 'ERROR' THEN
                            -- probleme de completion
                            UPDATE pc_lig_cmd SET
                                cod_err_pc_lig_cmd= 'PC-INT-310'
                            WHERE no_lig_cmd=r_cmd_l.no_lig_cmd AND no_cmd=r_cmd_l.no_cmd;

                            -- anomalie
                            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_niv_ano         => 2,
                                p_cod_usn         => p_cod_usn,
                                p_lib_ano_1       => 'Lg-Cmd usn',
                                p_par_ano_1       => r_cmd_l.no_cmd,
                                p_lib_ano_2       => 'No Ligne ',
                                p_par_ano_2       => TO_CHAR(r_cmd_l.no_lig_cmd),
                                p_cod_err_su_ano  => 'PC-INT-310',
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version,
                                p_cod_ala         =>'PC_INT_LIG_CMD');
                                


                        ELSIF r_cmd_l.mode_pal_1 IS NULL THEN
                            
                            -- anomalie
                            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                                p_cod_err_ora_ano => SQLCODE,
                                p_niv_ano         => 2,
                                p_cod_usn         => p_cod_usn,
                                p_lib_ano_1       => 'Lg-Cmd usn',
                                p_par_ano_1       => r_cmd_l.no_cmd,
                                p_lib_ano_2       => 'No Ligne ',
                                p_par_ano_2       => TO_CHAR(r_cmd_l.no_lig_cmd),
                                p_lib_ano_3       => 'colonne ',
                                p_par_ano_3       => 'MODE_PAL_1',
                                p_lib_ano_4       => 'Produit',
                                p_par_ano_4       => r_cmd_l.cod_pro_cde,
                                p_lib_ano_5       => 'VA',
                                p_par_ano_5       => r_cmd_l.cod_va_cde,
                                p_lib_ano_6       => 'VL',
                                p_par_ano_6       => r_cmd_l.cod_vl_cde,
                                p_cod_err_su_ano  => 'PC-INT-301',
                                p_nom_obj         => v_nom_obj,
                                p_version         => v_version,
                                p_cod_ala         =>'PC_INT_LIG_CMD');
                                
                            -- probleme de completion
                            UPDATE pc_lig_cmd SET
                                cod_err_pc_lig_cmd= 'PC-INT-301'
                            WHERE no_lig_cmd=r_cmd_l.no_lig_cmd AND no_cmd=r_cmd_l.no_cmd;

                                                    
                        ELSE
                            v_etape := 'MAJ statut pc_lig_cmd mode avec completion';
                            UPDATE pc_lig_cmd SET
                                etat_atv_pc_lig_cmd=v_etat_lig_fin
                            WHERE no_lig_cmd=r_cmd_l.no_lig_cmd AND no_cmd=r_cmd_l.no_cmd;
                        END IF;

                    ELSE
                        -- probleme de completion
                        UPDATE pc_lig_cmd SET
                            cod_err_pc_lig_cmd= 'PC-INT-310'
                        WHERE no_lig_cmd=r_cmd_l.no_lig_cmd AND no_cmd=r_cmd_l.no_cmd;
                        
                        -- anomalie
                        su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Lg-Cmd usn',
                            p_par_ano_1       => r_cmd_l.no_cmd,
                            p_lib_ano_2       => 'No Ligne ',
                            p_par_ano_2       => TO_CHAR(r_cmd_l.no_lig_cmd),
                            p_cod_err_su_ano  => 'PC-INT-310',
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         =>'PC_INT_LIG_CMD');
                    
                    END IF;

                ELSE
                    v_etape := 'MAJ statut pc_lig_cmd mode sans completion';
                    UPDATE pc_lig_cmd SET
                        etat_atv_pc_lig_cmd=v_etat_lig_fin
                    WHERE no_lig_cmd=r_cmd_l.no_lig_cmd AND no_cmd=r_cmd_l.no_cmd;
                END IF;
            END LOOP;
            CLOSE c_cmd_l;

        END LOOP;
        CLOSE c_cmd_e;

        -- suivi du nb de traitements de completion
        pc_integration_pkv.v_nb_cpl := NVL(pc_integration_pkv.v_nb_cpl,0) + v_cpt + v_cpt_lig;

        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' : Usine = ' || p_cod_usn||' / CMD traitee(s) : ' || v_cpt||' / Ligne(s) traitee(s) : ' || v_cpt_lig||' / MAXC_C = ' || v_maxc_c);
        END IF;

    END IF;

    /**********************
    3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_COMPLETE') THEN
        v_ret_evt := pc_evt_atv_complete('POST' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-102' ;
          RAISE err_except;
        END IF;
    END IF;

    COMMIT;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK TO  my_sp_bas_complete;
      IF c_cmd_e%ISOPEN THEN
		    CLOSE c_cmd_e;
		END IF;
      IF c_cmd_l%ISOPEN THEN
		    CLOSE c_cmd_l;
	  END IF;
      su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_usn         => p_cod_usn,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_INT_ECHEC');
      IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
          RETURN NVL(v_cod_err_su_ano,'ERROR');
      ELSE
          RETURN v_ret;
      END IF;
END;

/****************************************************************************
*   pc_bas_atv_completion_cad_ent
*/
-- DESCRIPTION :
-- -------------
-- Fonction de complétion par cadencier des commandes usines
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03b,26.03.12,alfl    appel a la fct pc_bas_cad_rch_val_mtc
-- 03a,09.02.12,alfl    gestion des filtres
-- 02b,20.07.10,rbel    gestion echec que si completion obligatoire
-- 02a,18.08.09,  alfl    gestion mode  2 completion optionnellle
-- 01a,12.04.07,  ALFL    initialisation
-- 00a,06.12.06,  GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_r_ent_cmd   : record entete commande usine
--  p_mode cplt   : mode de completion
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_atv_completion_cad_ent (
    p_r_ent           IN OUT    NOCOPY pc_ent_cmd%ROWTYPE ,
    p_mode_cplt       VARCHAR2
        )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_completion_cad_ent';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';

    v_typ_trait_pyr     su_dim_app_ent.typ_trait_pyr%TYPE:=NULL;
    v_ctx               su_ctx_pkg.tt_ctx;
    v_val               su_lig_mte.val_sais%TYPE;
    v_list_dim          VARCHAR2(500);
    v_type              VARCHAR2(10);
    v_dat_ref           DATE;
    v_val1              VARCHAR2(1000);
    v_val2              VARCHAR2(1000);
    v_val3              VARCHAR2(1000);



BEGIN

    v_etape:='debut';

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' Commande Usine '||p_r_ent.no_cmd);
    END IF;

    -- premier phase on recherche le type de traitement pyramide
    v_etape :='recherche typ traitement pyramide';
    v_typ_trait_pyr := su_bas_gcl_pc_usn(p_r_ent.cod_usn,'TYP_TRAIT_PYR_CAD_ENT');
    IF    v_typ_trait_pyr IS NULL THEN
        v_ret :='ERROR' ;

        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Cde usine',
                        p_par_ano_1       => p_r_ent.no_cmd,
                        p_cod_err_su_ano  => 'PC-INT-300',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        -- anomalie
    ELSE


        -- on charge le record dans un contexte
        v_etape := 'mise en contexte';
        IF su_bas_ctx_pc_ent_cmd(v_ctx,p_r_ent) = FALSE THEN
	      RAISE err_except;
	    END IF;
        
         v_etape:=' recherche des valeurs pour les filtres ';
        v_ret:=pc_bas_rch_val_filtre_para (                          -- gestion du v_ret
                                p_par=>'FRM_PC_CAD_ENT_SAIS',
                                p_no_cmd=>p_r_ent.no_cmd,
                                p_no_lig_cmd=>NULL,
                                p_val1=>v_val1,
                                p_val2=>v_val2,
                                p_val3=>v_val3);
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape||' retour='||v_ret||' v_val1='||v_val1||' v_val2='||v_val2||' v_val3='||v_val3);
        END IF;
        
        v_etape := ' recherche mtc cadencier' ;
        -- pour tous les mtc actif
        FOR c_cur IN ( SELECT cod_mtc FROM SU_LIG_MTT WHERE COD_MTT='PC_CAD_ENT'
            AND etat_actif = '1' ORDER BY NO_ORD)
        LOOP
        -- pour tous les mtc du cadencier on force la valeur du cadencier dans le record

            v_dat_ref :=   NVL(p_r_ent.dat_liv,NVL(p_r_ent.dat_exp,p_r_ent.dat_dem));

            IF v_dat_ref IS NULL THEN
                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                    p_cod_err_ora_ano => SQLCODE,
                    p_niv_ano         => 2,
                    p_lib_ano_1       => 'Com usine',
                    p_par_ano_1       => p_r_ent.no_cmd,
                    p_lib_ano_2       => 'date ref',
                    p_par_ano_2       => 'NULL',
                    p_cod_err_su_ano  => 'PC-INT-302',
                    p_nom_obj         => v_nom_obj,
                    p_version         => v_version);
                RAISE err_except;



            END IF;

            -- recherche la valeur dans le cadencier
            v_etape := ' recherche valeur dans cadencier' ;
            v_ret := pc_bas_cad_rch_val_mtc (
                       p_typ_trait_pyr  => v_typ_trait_pyr ,
                       p_dat_ref        => v_dat_ref,
                       p_cod_cli        => p_r_ent.cod_cli,
                       p_cod_pro        => NULL,
                       p_cod_va         => NULL,
                       p_cod_vl         => NULL,
                       p_cod_mtc        => c_cur.cod_mtc,
                       p_val            => v_val,
                       p_cod_mte        => v_list_dim ,
                       p_val1           =>v_val1,
                       p_val2           =>v_val2,
                       p_val3           =>v_val3);


            IF v_ret = 'OK' THEN
                -- on a trouve une valeur
                -- on la met dans  le contexte
                v_etape:='mise de la valeur en context ';
                v_type := su_ctx_pkg.su_bas_get_typ_val (v_ctx ,c_cur.cod_mtc);
                IF v_type = '1' THEN
                    IF su_ctx_pkg.su_bas_set_char(v_ctx,c_cur.cod_mtc,v_val) = FALSE THEN
                        RAISE err_except;
                    END IF;
                ELSIF v_type = '2' THEN
                    IF su_ctx_pkg.su_bas_set_number(v_ctx,c_cur.cod_mtc,TO_NUMBER(v_val)) = FALSE THEN
                        RAISE err_except;
                    END IF;

                ELSIF v_type = '3' THEN
                    IF su_ctx_pkg.su_bas_set_date(v_ctx,c_cur.cod_mtc,TO_DATE(v_val,'DD/MM/YYYY)')) = FALSE THEN
                        RAISE err_except;
                    END IF;
                ELSE
                    RAISE err_except;

                END IF;

            ELSE
                -- on a pas trouve de valeur -> pas normal si mode 1 
		        IF p_mode_cplt != '1' THEN
                   v_ret := 'OK';                
                
                ELSE
                    v_ret := 'ERROR'  ;

                    -- anomalie
                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_niv_ano         => 2,
                        p_lib_ano_1       => 'Cde usine',
                        p_par_ano_1       => p_r_ent.no_cmd,
                        p_lib_ano_2       => 'colonne ',
                        p_par_ano_2       => c_cur.cod_mtc,
                        p_lib_ano_3       => 'cli ',
                        p_par_ano_3       => p_r_ent.cod_cli,
                        p_lib_ano_4       => 'date ref',
                        p_par_ano_4       => TO_CHAR(v_dat_ref,'DD/MM/YYYY'),
                        p_cod_err_su_ano  => 'PC-INT-303',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
                    -- on arrrete tous
                    EXIT;
                END IF;
            END IF;

        END LOOP;

        -- il faut restituer le contexte dans le record
        v_etape := 'get contexte sur entete';
        IF su_bas_gct_pc_ent_cmd (v_ctx, p_r_ent) = FALSE   THEN
             RAISE err_except;
        END IF;

    END IF;

    RETURN v_ret;

EXCEPTION

    WHEN OTHERS THEN
	
            su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Cmd usine',
                        p_par_ano_1       => p_r_ent.no_cmd,
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
*   pc_bas_atv_completion_cad_lig
*/
-- DESCRIPTION :
-- -------------
-- Fonction de complétion par cadencier des lignes usines
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03b,26.03.12,alfl    appel a la fct pc_bas_cad_rch_val_mtc
-- 03a,09.02.12,alfl    gestion des filtres
-- 02b,20.07.10,rbel    gestion echec que si completion obligatoire
-- 02a,18.08.09,alfl    gestion mode  2 completion optionnellle
-- 01a,12.04.07,alfl    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_r_lig_cmd   : record ligne commande usine
--  p_mode cplt   : mode de completion
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_atv_completion_cad_lig (
    p_r_lig                IN OUT  NOCOPY pc_lig_cmd%ROWTYPE,
    p_mode_cplt            VARCHAR2
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_completion_cad_lig';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';

    v_typ_trait_pyr     su_dim_app_ent.typ_trait_pyr%TYPE:=NULL;
    v_ctx               su_ctx_pkg.tt_ctx;
    v_val               su_lig_mte.val_sais%TYPE;
    v_list_dim          VARCHAR2(500);
    v_dat_liv           DATE;
    v_dat_exp           DATE;
    v_dat_dem           DATE;
    v_dat_ref           DATE;
    v_cplt_lig          VARCHAR2(20);
    v_type              VARCHAR2(10);
    v_cod_cli           pc_ent_cmd.cod_cli%TYPE;
    v_cod_pro           pc_lig_cmd.cod_pro%TYPE;
    v_cod_va            pc_lig_cmd.cod_va%TYPE;
    v_cod_vl            pc_lig_cmd.cod_vl%TYPE;
    v_val1              VARCHAR2(1000);
    v_val2              VARCHAR2(1000);
    v_val3              VARCHAR2(1000);

BEGIN

    v_etape:='debut';

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' ligne commande usine '||p_r_lig.no_cmd|| '-'||to_char(p_r_lig.no_lig_cmd));
    END IF;

    -- premier phase on recherche le type de traitement pyramide
    v_etape :='recherche typ traitement pyramide';
    v_typ_trait_pyr := su_bas_gcl_pc_usn(p_r_lig.cod_usn,'TYP_TRAIT_PYR_CAD_LIG');
    IF    v_typ_trait_pyr IS NULL THEN
        v_ret :='ERROR' ;

        su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_niv_ano         => 2,
                        p_lib_ano_1       => 'Cde usine',
                        p_par_ano_1       => p_r_lig.no_cmd,
                        p_lib_ano_2       => 'No Ligne ',
                        p_par_ano_2       => TO_CHAR(p_r_lig.no_lig_cmd),
                        p_cod_err_su_ano  => 'PC-INT-300',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);

        -- anomalie
    ELSE
       -- on rechreche la date de liv
        FOR c_cur IN (SELECT dat_liv,dat_exp,dat_dem,cod_cli  FROM pc_ent_cmd WHERE no_cmd = p_r_lig.no_cmd)
        LOOP
            v_dat_liv := c_cur.dat_liv;
            v_dat_exp := c_cur.dat_exp;
            v_dat_dem := c_cur.dat_dem;
            v_cod_cli := c_cur.cod_cli;
        END LOOP;

        v_etape := 'Calcul dat ref';
        v_dat_ref := NVL(v_dat_liv,NVL(v_dat_exp,v_dat_dem));

        IF v_dat_ref is NULL THEN
            v_etape:='date ref NULL';
            RAISE err_except;
        END IF;

        -- on charge le record dans un contexte
        v_etape := 'mise en contexte';
        IF su_bas_ctx_pc_lig_cmd(v_ctx,p_r_lig) = FALSE THEN
	      RAISE err_except;
	    END IF;

        v_etape := 'Recherche des clés de configuration CPLT_LIGNE';
        v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_r_lig.cod_usn),
                                      p_typ_atv =>pc_integration_pkv.v_cod_atv,
                                      p_cod_cfg=>'CPLT_LIGNE',
                                      p_val=>v_cplt_lig);
        IF v_ret<>'OK' then
            v_cod_err_su_ano := 'PC-INT-340' ;
            RAISE err_except;
        END IF;

        v_etape:=' recherche des valeurs pour les filtres ';
        v_ret:=pc_bas_rch_val_filtre_para (                          -- gestion du v_ret
                                p_par=>'FRM_PC_CAD_LIG_SAIS',
                                p_no_cmd=>p_r_lig.no_cmd,
                                p_no_lig_cmd=>p_r_lig.no_lig_cmd,
                                p_val1=>v_val1,
                                p_val2=>v_val2,
                                p_val3=>v_val3);
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape||' retour='||v_ret||' v_val1='||v_val1||' v_val2='||v_val2||' v_val3='||v_val3);
        END IF;
        
        v_etape := ' recherche mtc cadencier' ;
        -- pour tous les mtc actif
        FOR c_cur IN (SELECT cod_mtc
                      FROM SU_LIG_MTT
                      WHERE COD_MTT='PC_CAD_LIG' AND etat_actif = '1' ORDER BY NO_ORD)
        LOOP
            -- pour tous les mtc du cadencier on force la valeur du cadencier dans le record

            -- recherche la valeur dans le cadencier
            IF v_cplt_lig = 'CDE' THEN
                v_etape := 'recherche par cde' ;
                IF p_r_lig.cod_pro_cde IS NOT NULL AND p_r_lig.cod_va_cde IS NOT NULL AND
                   p_r_lig.cod_vl_cde IS NOT NULL THEN
                    v_cod_pro := p_r_lig.cod_pro_cde;
                    v_cod_va  := p_r_lig.cod_va_cde;
                    v_cod_vl  := p_r_lig.cod_vl_cde;
                ELSE
                    v_etape := 'recherche par stk car cde null';
                    v_cod_pro := p_r_lig.cod_pro;
                    v_cod_va  := p_r_lig.cod_va;
                    v_cod_vl  := p_r_lig.cod_vl;
                END IF;

            ELSIF v_cplt_lig = 'STK' THEN
                v_etape := 'recherche par stk';
                v_cod_pro := p_r_lig.cod_pro;
                v_cod_va  := p_r_lig.cod_va;
                v_cod_vl  := p_r_lig.cod_vl;

            ELSE
                v_etape := 'recherche par stk par defaut';
                v_cod_pro := p_r_lig.cod_pro;
                v_cod_va  := p_r_lig.cod_va;
                v_cod_vl  := p_r_lig.cod_vl;

            END IF;
            v_etape := 'recherche valeur dans cadencier' ;
            v_ret := pc_bas_cad_rch_val_mtc (
                       p_typ_trait_pyr  => v_typ_trait_pyr ,
                       p_dat_ref        => v_dat_ref,
                       p_cod_cli        => NVL(p_r_lig.cod_cli_final,v_cod_cli),
                       p_cod_pro        => v_cod_pro,
                       p_cod_va         => v_cod_va,
                       p_cod_vl         => v_cod_vl,
                       p_cod_mtc        => c_cur.cod_mtc,
                       p_val            => v_val,
                       p_cod_mte        => v_list_dim,
                       p_val1           =>v_val1,
                       p_val2           =>v_val2,
                       p_val3           =>v_val3);

            IF v_ret = 'OK' THEN
                -- on a trouve une valeur
                -- on la met dans  le contexte
                v_etape:='Lecture du type de ' || c_cur.cod_mtc;
                v_type := su_ctx_pkg.su_bas_get_typ_val (v_ctx, c_cur.cod_mtc);

                v_etape:='mise en contexte de ' || c_cur.cod_mtc || 'type:' || v_type;
                IF v_type = '1' THEN
                    IF su_ctx_pkg.su_bas_set_char(v_ctx,c_cur.cod_mtc,v_val) = FALSE THEN
                        RAISE err_except;
                    END IF;
                ELSIF v_type = '2' THEN
                    IF su_ctx_pkg.su_bas_set_number(v_ctx,c_cur.cod_mtc,TO_NUMBER(v_val)) = FALSE THEN
                        RAISE err_except;
                    END IF;

                ELSIF v_type = '3' THEN
                    IF su_ctx_pkg.su_bas_set_date(v_ctx,c_cur.cod_mtc,TO_DATE(v_val,'DD/MM/YYYY)')) = FALSE THEN
                        RAISE err_except;
                    END IF;
                ELSE
                    RAISE err_except;
                END IF;

            ELSE
                -- on a pas trouve de valeur -> pas normal si mode 1
                IF p_mode_cplt != '1' THEN
                   v_ret := 'OK';                
                ELSE
                    v_ret := 'ERROR'  ;

                    -- anomalie
                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_niv_ano         => 2,
                        p_lib_ano_1       => 'Lg-Cmd usn',
                        p_par_ano_1       => p_r_lig.no_cmd,
                        p_lib_ano_2       => 'No Ligne ',
                        p_par_ano_2       => TO_CHAR(p_r_lig.no_lig_cmd),
                        p_lib_ano_3       => 'colonne ',
                        p_par_ano_3       => c_cur.cod_mtc,
                        p_lib_ano_4       => 'Produit',
                        p_par_ano_4       => p_r_lig.cod_pro_cde,
                        p_lib_ano_5       => 'Client',
                        p_par_ano_5       => NVL(p_r_lig.cod_cli_final,v_cod_cli),
                        p_lib_ano_6       => 'VA',
                        p_par_ano_6       => p_r_lig.cod_va_cde,
                        p_lib_ano_7       => 'VL',
                        p_par_ano_7       => p_r_lig.cod_vl_cde,
                        p_lib_ano_8       => 'Date ref',
                        p_par_ano_8       => TO_CHAR(v_dat_ref,'DD/MM/YYY'),
                        p_cod_err_su_ano  => 'PC-INT-301',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
                    -- on arrrete tous
                    EXIT;
                END IF;
            END IF;

        END LOOP;

        -- il faut restituer le contexte dans le record
        v_etape := 'get contexte sur ligne';
        IF su_bas_gct_pc_lig_cmd (v_ctx, p_r_lig) = FALSE   THEN
             RAISE err_except;
        END IF;

    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
	
            su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Cmd usn',
                        p_par_ano_1       => p_r_lig.no_cmd,
                        p_lib_ano_2       => 'No Ligne ',
                        p_par_ano_2       => TO_CHAR(p_r_lig.no_lig_cmd),
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
*   pc_bas_rch_val_filtre_para
*/
-- DESCRIPTION :
-- -------------
-- Fonction de recherche des valeurs de colonnes pour les comparer aux filtres des règles du cadencier
-- se base sur la configuration des parametres ecrans
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,09.02.12,alfl    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  p_par          :nom  parametre 
--  p_no_cmd       :cmd usine
--  p_no_lig_cmd   :lig_cmd usine,
--  p_val1         :valeur de la colonne
--  p_val2         :valeur de la colonne
--  p_val3         :valeur de la colonne
--
-- RETOUR :
-- --------
--  OK  ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_rch_val_filtre_para (
    p_par                   VARCHAR2,
    p_no_cmd                VARCHAR2,
    p_no_lig_cmd            NUMBER,
    p_val1                IN OUT  VARCHAR2,
    p_val2                IN OUT  VARCHAR2,
    p_val3                IN OUT  VARCHAR2
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_rch_val_filtre_para';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    
    v_col               VARCHAR2(50);
    v_table             VARCHAR2(50);
    v_fonction          BOOLEAN:=FALSE;
    
BEGIN

    v_etape:='debut';

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||
                        ' p_par '||p_par||' p_no_cmd '||p_no_cmd||' p_no_lig_cmd '||to_char(p_no_lig_cmd));
    END IF;
    v_etape:='init valeur';
    p_val1:='$*';
    p_val2:='$*';
    p_val3:='$*';
                                                       
    -- recherche de la colonne
    v_etape :='recherche colonne 1';
    v_col:=su_bas_rch_action(p_nom_par=>p_par,p_par=>'FILTRE_1',p_no_action=>2);
    IF v_col IS NULL THEN  -- pas de gestion de filtre
        RETURN 'OK';
    END IF;
    v_table:=su_bas_rch_action(p_nom_par=>p_par,p_par=>'FILTRE_1',p_no_action=>4);
    IF v_table = 'PC_ENT_CMD' THEN
        p_val1:=su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,p_colonne=>v_col);
    ELSIF v_table = 'PC_LIG_CMD' THEN
        p_val1:=su_bas_gcl_pc_lig_cmd(p_no_cmd=>p_no_cmd,p_no_lig_cmd=>p_no_lig_cmd,p_colonne=>v_col);
    ELSIF v_table='$FONCTION' THEN 
        v_fonction:= TRUE;
    ELSE
        -- anomalie
        su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_niv_ano         => 2,
                        p_cod_usn         => su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,p_colonne=>'COD_USN'),
                        p_lib_ano_1       => 'Cde usine',
                        p_par_ano_1       => p_no_cmd,
                        p_lib_ano_2       => 'No Ligne ',
                        p_par_ano_2       => TO_CHAR(p_no_lig_cmd),
                        p_lib_ano_3       => 'colonne',
                        p_par_ano_3       => v_col,
                        p_lib_ano_4       => 'table',
                        p_par_ano_4       => v_table,
                        p_cod_err_su_ano  => NULL,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_INT_ECHEC');

        RETURN 'ERROR';
    END IF;
    v_etape :='recherche colonne 2';
    v_col:=su_bas_rch_action(p_nom_par=>p_par,p_par=>'FILTRE_2',p_no_action=>2);
    IF v_col IS NULL THEN      -- pas de filtre 2
        IF v_fonction != TRUE  THEN
            RETURN 'OK'; -- pas d'appel a la fonction pc_bas_rch_val_filtre_affaire 
        END IF;   
    ELSE
        v_table:=su_bas_rch_action(p_nom_par=>p_par,p_par=>'FILTRE_2',p_no_action=>4);
        IF v_table = 'PC_ENT_CMD' THEN
            p_val2:=su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,p_colonne=>v_col);
        ELSIF v_table = 'PC_LIG_CMD' THEN
            p_val2:=su_bas_gcl_pc_lig_cmd(p_no_cmd=>p_no_cmd,p_no_lig_cmd=>p_no_lig_cmd,p_colonne=>v_col);
        ELSIF v_table='$FONCTION' THEN
            v_fonction:= TRUE;
        ELSE
            -- anomalie
            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,p_colonne=>'COD_USN'),
                            p_lib_ano_1       => 'Cde usine',
                            p_par_ano_1       => p_no_cmd,
                            p_lib_ano_2       => 'No Ligne ',
                            p_par_ano_2       => TO_CHAR(p_no_lig_cmd),
                            p_lib_ano_3       => 'colonne',
                            p_par_ano_3       => v_col,
                            p_lib_ano_4       => 'table',
                            p_par_ano_4       => v_table,
                            p_cod_err_su_ano  => NULL,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_ECHEC');
    
            RETURN 'ERROR';
        END IF;
    END IF; 
    v_etape :='recherche colonne 3';
    v_col:=su_bas_rch_action(p_nom_par=>p_par,p_par=>'FILTRE_3',p_no_action=>2);
    IF v_col IS NULL THEN -- pas de filre 3
        IF v_fonction != TRUE THEN
            RETURN 'OK'; -- pas d'appel a la fonction pc_bas_rch_val_filtre_affaire 
        END IF;   
    ELSE
        v_table:=su_bas_rch_action(p_nom_par=>p_par,p_par=>'FILTRE_3',p_no_action=>4);
        IF v_table = 'PC_ENT_CMD' THEN
            p_val3:=su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,p_colonne=>v_col);
        ELSIF v_table = 'PC_LIG_CMD' THEN
            p_val3:=su_bas_gcl_pc_lig_cmd(p_no_cmd=>p_no_cmd,p_no_lig_cmd=>p_no_lig_cmd,p_colonne=>v_col);
        ELSIF v_table='$FONCTION' THEN
            v_fonction:= TRUE;
        ELSE
            -- anomalie
            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,p_colonne=>'COD_USN'),
                            p_lib_ano_1       => 'Cde usine',
                            p_par_ano_1       => p_no_cmd,
                            p_lib_ano_2       => 'No Ligne ',
                            p_par_ano_2       => TO_CHAR(p_no_lig_cmd),
                            p_lib_ano_3       => 'colonne',
                            p_par_ano_3       => v_col,
                            p_lib_ano_4       => 'table',
                            p_par_ano_4       => v_table,
                            p_cod_err_su_ano  => NULL,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_ECHEC');
    
            RETURN 'ERROR';
        END IF;
    END IF;
    IF v_fonction=TRUE THEN
        v_etape:=' recherche des valeurs filtres par fonction ';
        v_ret:=pc_bas_rch_val_filtre_affaire (                          -- gestion du v_ret
                                p_no_cmd=>p_no_cmd,
                                p_no_lig_cmd=>p_no_lig_cmd,
                                p_val1=>p_val1,
                                p_val2=>p_val2,
                                p_val3=>p_val3);
    END IF;
       
    
    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
	
            su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_usn         => su_bas_gcl_pc_ent_cmd(p_no_cmd=>p_no_cmd,p_colonne=>'COD_USN'),
                        p_lib_ano_1       => 'Cde usn',
                        p_par_ano_1       => p_no_cmd,
                        p_lib_ano_2       => 'No Ligne ',
                        p_par_ano_2       => TO_CHAR(p_no_lig_cmd),
                        p_lib_ano_3       => 'colonne',
                        p_par_ano_3       => v_col,
                        p_lib_ano_4       => 'table',
                        p_par_ano_4       => v_table,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_INT_ECHEC');
      IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
          RETURN NVL(v_cod_err_su_ano,'ERROR');
      ELSE
          RETURN v_ret;
      END IF;
END;


/****************************************************************************
*   pc_bas_atv_regroupe -
*/
-- DESCRIPTION :
-- -------------
-- Fonction de regroupement des commandes usines dans des commandes de préparation
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01f,23.05.11,rbel    branchement calcul libellé départ
-- 01e,15.06.10,mnev    ajout cod_tra_1 à l'appel de ex_
-- 01d,01.04.10,mnev    on ne passe plus les clefs à ex_
-- 01c,17.09.08,rbel    ne pas appeler la création de départ si mode_afc_dpt demande aucune notion de départ
-- 01b,03.06.08,mnev    report dans pc_bas_rch_rgp_com des tests pour
--                      regroupement. Cela corrige un bug de creation
--                      intempestive de commande de préparation.
-- 01a,06.12.06,JDRE    initialisation
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
--   OUI

FUNCTION pc_bas_atv_regroupe (
    p_cod_usn                  SU_USN.COD_USN%TYPE
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE          := '@(#) VERSION 01f $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE          := 'pc_bas_atv_regroupe';
    v_etape             su_ano_his.txt_ano%TYPE          := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE   ;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100);
    v_ret_evt           VARCHAR2(20)                     ;
    v_ret_atv_pss       VARCHAR2(10);
    v_last_no_com       pc_ent_com.no_com%TYPE           ;
    p_val_atv_pss       su_pss_atv_cfg.val_cle_atv%TYPE;
    v_no_lig            pc_lig_com.no_lig_com%TYPE;
    v_etat_lig_ini      VARCHAR2(20);
    v_etat_ent_ini      VARCHAR2(20);
    v_etat_lig_fin      VARCHAR2(20);
    v_etat_lig_com      VARCHAR2(20);
    v_etat_lig_fin_1    VARCHAR2(20);
    v_etat_lig_fin_2    VARCHAR2(20);
    v_etat_ent_fin      VARCHAR2(20);
    v_typ_col           pc_lig_com.typ_col%TYPE;
    v_dpt               pc_ent_cmd.no_dpt%TYPE;
    v_continue          BOOLEAN:=TRUE;
    vr_pc_ent_dpt       pc_ent_dpt%ROWTYPE;
    v_mode_rgpm         su_pss_atv_cfg.val_cle_atv%TYPE  ;
    v_mode_eclat        su_pss_atv_cfg.val_cle_atv%TYPE  ;
    v_etat_no_rgp       number                           ;
    v_cle_eclat_com     pc_ent_com.cle_eclat_com%TYPE;

    -- Recherche des commandes usines à traiter
    CURSOR c_cmd_e(x_etat_ent_ini VARCHAR2,x_etat_lig_ini VARCHAR2) IS
      SELECT E.*
      FROM pc_ent_cmd E
      WHERE  E.cod_err_pc_ent_cmd IS NULL AND E.cod_usn=p_cod_usn AND
             E.etat_atv_pc_ent_cmd=x_etat_ent_ini AND
             E.no_cmd IN (SELECT no_cmd
                          FROM pc_lig_cmd
                          WHERE cod_err_pc_lig_cmd IS NULL AND
                                etat_atv_pc_lig_cmd=x_etat_lig_ini)
      ORDER  BY dat_exp,E.no_cmd
      FOR UPDATE NOWAIT;

    r_cmd_e PC_ENT_CMD%ROWTYPE;

    -- Recherche des lignes de commandes usines à traiter
    CURSOR c_cmd_l(x_etat_lig_ini VARCHAR2,x_no_cmd pc_lig_cmd.no_cmd%TYPE) IS
      SELECT L.*
      FROM pc_lig_cmd L
      WHERE  L.cod_err_pc_lig_cmd IS NULL AND L.no_cmd = x_no_cmd  AND
             L.etat_atv_pc_lig_cmd=x_etat_lig_ini
      FOR UPDATE NOWAIT;

    r_cmd_l pc_lig_cmd%ROWTYPE;

BEGIN

    SAVEPOINT my_sp_bas_regroupe;

    /************************
    1) PHASE INITIALISATION
    ************************/
    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_cod_usn = ' || p_cod_usn);
    END IF;

    v_etat_ent_ini  :=su_bas_rch_etat_atv('COMPLETION','PC_ENT_CMD');
    v_etat_lig_ini  :=su_bas_rch_etat_atv('COMPLETION','PC_LIG_CMD');
    v_etat_lig_fin  :=su_bas_rch_etat_atv('REGROUPEMENT','PC_LIG_CMD');
    v_etat_ent_fin  :=su_bas_rch_etat_atv('CREATION','PC_ENT_COM');
    v_etat_lig_fin_1:=su_bas_rch_etat_atv('CREATION','PC_LIG_COM');
    v_etat_lig_fin_2:=su_bas_rch_etat_atv('DECOUPAGE','PC_LIG_COM');
    v_etat_no_rgp   := su_bas_etat_val_num ('RGP_INTERDIT','PC_LIG_COM');

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_REGROUPE') THEN
        v_ret_evt := pc_evt_atv_regroupe('PRE' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-100' ;
          RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT
    ********************/
    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_ATV_REGROUPE') THEN
        v_ret_evt := pc_evt_atv_regroupe('ON' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-101' ;
          RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN

        v_etape := 'Ouverture du curseur des entetes de commande';
        OPEN c_cmd_e(v_etat_ent_ini,v_etat_lig_ini);
        LOOP
            FETCH c_cmd_e INTO r_cmd_e;
            EXIT WHEN c_cmd_e%NOTFOUND;

            v_continue:=TRUE;
            v_last_no_com := NULL;

            --
            -- Création du départ s'il n'existe pas
            --
            IF  r_cmd_e.no_dpt IS NULL AND r_cmd_e.mode_afc_dpt <> 'S' THEN
                --
                -- l'appel a ex permet juste de créer et récuperer un depart 
                -- pour l'occurence cle_dpt
                --
                v_etape := 'Création du départ';
                v_ret := ex_planning_depart_pkg.ex_bas_cre_ent_dep_reel (
                                p_no_dpt       =>NULL,
                                p_dat_dep_th   =>r_cmd_e.dat_exp,
                                p_cod_usn      =>r_cmd_e.cod_usn,
                                p_no_dep_th    =>NULL,
                                p_ref_dpt_ext  =>r_cmd_e.cle_dpt,
                                p_cod_tou      =>r_cmd_e.cod_tou,
                                p_cod_tra_dflt =>r_cmd_e.cod_tra_1,
                                p_typ_dpt      =>'1',
                                p_cle1         =>NULL, 
                                p_cle2         =>NULL,
                                p_typ_tiers    =>'C',
                                p_ctrl_capacite=>0,
                                p_no_dpt_attrib=>v_dpt);
						                                                                                                     															
                v_etape := 'mise a jour du planning des departs';
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' : creation dpt=' || v_dpt || ' v_ret=' || v_ret);
                END IF;

                IF v_ret <> 'OK' THEN
                    v_etape := 'Erreur. MAJ pc_ent_cmd';
                    UPDATE pc_ent_cmd SET
                       cod_err_pc_ent_cmd ='PC-INT-024'
                    WHERE no_cmd=r_cmd_e.no_cmd;

                    -- anomalie
                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Cde usine',
                            p_par_ano_1       => r_cmd_e.no_cmd,
                            p_cod_err_su_ano  => 'PC-INT-024',
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_ENT_CMD');
    


                    v_continue:=FALSE;

                ELSE
                    IF su_bas_xst_pc_ent_dpt(v_dpt) = 'NON' THEN
                        v_etape :='Création du départ dans module PC';
                        vr_pc_ent_dpt.no_dpt := v_dpt;
                        vr_pc_ent_dpt.etat_atv_pc_ent_dpt := 'CREA';
                        vr_pc_ent_dpt.lib_dpt := pc_bap_GENLIBDPT01 (v_dpt);
                        
                        v_ret := su_bas_irw_pc_ent_dpt(vr_pc_ent_dpt);

                        IF v_ret <> 'OK' THEN
                            v_etape :='Erreur création du départ dans module PC';
                            UPDATE pc_ent_cmd SET
                               cod_err_pc_ent_cmd ='PC-INT-024'
                            WHERE no_cmd=r_cmd_e.no_cmd;

                            v_cod_err_su_ano := 'PC-INT-024';
                            RAISE err_except;

                        END IF;

                    ELSE
                        v_etape := 'Maj lib_dpt (1)';
                        UPDATE pc_ent_dpt
                           SET lib_dpt = NVL(lib_dpt, pc_bap_GENLIBDPT01 (v_dpt))
                        WHERE no_dpt = v_dpt;    
                    END IF;

                    v_etape :='Mise à jour du départ sur commande usine';
                    UPDATE pc_ent_cmd SET
                        no_dpt = v_dpt
                    WHERE no_cmd=r_cmd_e.no_cmd;

                    -- Le depart est maintenant connu
                    r_cmd_e.no_dpt:= v_dpt;
                END IF;

            ELSIF r_cmd_e.no_dpt IS NOT NULL AND su_bas_gcl_pc_ent_dpt(p_no_dpt => r_cmd_e.no_dpt,
                                                                       p_colonne => 'LIB_DPT') IS NULL THEN
                v_etape := 'Maj lib_dpt (2)';
                UPDATE pc_ent_dpt SET
                    lib_dpt = pc_bap_GENLIBDPT01(r_cmd_e.no_dpt) 
                WHERE no_dpt = r_cmd_e.no_dpt;   

            END IF;

            -- Recherche si condition de regroupement
            v_etape := 'Rch du mode de regroupement';
            v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss => NVL(r_cmd_e.COD_PSS_AFC,su_bas_get_pss_defaut(r_cmd_e.cod_usn)),
                                          p_typ_atv => 'INT',
                                          p_cod_cfg => 'MODE_RGPM',
                                          p_val     => v_mode_rgpm);

            v_etape := 'Rch du mode d''éclatement';
            v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss => NVL(r_cmd_e.COD_PSS_AFC,su_bas_get_pss_defaut(r_cmd_e.cod_usn)),
                                          p_typ_atv => 'INT',
                                          p_cod_cfg => 'MODE_ECLAT',
                                          p_val     => v_mode_eclat);

            IF v_mode_eclat IS NULL THEN
                v_etape := 'Recherche commande à compléter / mode de regroupement';
                v_ret:=pc_bas_rch_rgp_com (
                            p_ent_cmd           => r_cmd_e,
                            p_no_com            => v_last_no_com,
                            p_cle_eclat_com     => null,
                            p_mode_rgpm         => v_mode_rgpm,
                            p_etat_no_rgp       => v_etat_no_rgp
                            );
                IF v_ret <> 'OK' THEN
                    UPDATE pc_ent_cmd SET
                        cod_err_pc_ent_cmd = 'PC-INT-020'
                    WHERE no_cmd=r_cmd_e.no_cmd;
                    
                    -- anomalie
                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Cde usine',
                            p_par_ano_1       => r_cmd_e.no_cmd,
                            p_cod_err_su_ano  => 'PC-INT-020',
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_ENT_CMD');

                    
                    v_continue:=FALSE;
                /* pas de remise en cause du transporteur !
                ELSIF v_last_no_com IS NOT NULL AND r_cmd_e.mode_afc_dpt='S' THEN   */
                END IF;
            END if;
            IF v_continue THEN

                v_etape := 'Ouverture du curseur des lignes de commande';
                OPEN c_cmd_l(v_etat_lig_ini,r_cmd_e.no_cmd);
                LOOP
                    FETCH c_cmd_l INTO r_cmd_l;
                    EXIT WHEN c_cmd_l%NOTFOUND;

                    -- oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
                    -- Possibilité de gérer des evnènements de regroupement spécique
                    -- oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
                    IF su_global_pkv.vt_evt_actif.exists('ON_RCH_CDT_RGMP') THEN
                        v_etape := 'Appel événement REGROUPEMENT';
                        v_ret_evt := pc_evt_atv_rch_regroupe(r_cmd_e.no_cmd,v_last_no_com);
                        IF v_ret_evt = 'ERROR' THEN
                            v_cod_err_su_ano := 'PC-INT-101' ;
                            RAISE err_except;
                        END IF;
                    ELSE
                        v_ret_evt := NULL;
                    END IF;

                    -- oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
                    -- Regroupement standard
                    -- oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
                    IF v_ret_evt IS NULL THEN
                        v_continue := TRUE;
                        IF v_mode_eclat IS NOT null THEN
                            v_last_no_com := null;
                            v_etape := 'Calcul de la clé d''éclatement';
                            v_ret := pc_bas_calc_eclat_com (pr_lig_cmd          => r_cmd_l,
                                                            p_mode_eclat        => v_mode_eclat,
                                                            p_cle_eclat_com     => v_cle_eclat_com);
                            IF v_ret='OK' THEN
                                v_etape := 'Recherche commande à compléter / mode de regroupement';
                                v_ret:=pc_bas_rch_rgp_com (p_ent_cmd           => r_cmd_e,
                                                           p_no_com            => v_last_no_com,
                                                           p_cle_eclat_com     => v_cle_eclat_com,
                                                           p_mode_rgpm         => v_mode_rgpm,
                                                           p_etat_no_rgp       => v_etat_no_rgp);
                            END IF;
                            IF v_ret <> 'OK' THEN
                                UPDATE pc_lig_cmd SET
                                    cod_err_pc_lig_cmd = 'PC-INT-020'
                                WHERE no_cmd =r_cmd_l.no_cmd AND no_lig_cmd=r_cmd_l.no_lig_cmd;
                                
                                -- anomalie
                                su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                                                p_cod_err_ora_ano => SQLCODE,
                                                p_niv_ano         => 2,
                                                p_cod_usn         => p_cod_usn,
                                                p_lib_ano_1       => 'Cde usine',
                                                p_par_ano_1       => r_cmd_l.no_cmd,
                                                p_lib_ano_2       => 'Ligne',
                                                p_par_ano_2       => r_cmd_l.no_lig_cmd,
                                                p_cod_err_su_ano  => 'PC-INT-020',
                                                p_nom_obj         => v_nom_obj,
                                                p_version         => v_version,
                                                p_cod_ala         => 'PC_INT_LIG_CMD');


                                v_continue:=FALSE;
                            /* pas de remise en cause du transporteur !
                            ELSIF v_last_no_com IS NOT NULL AND r_cmd_e.mode_afc_dpt='S' THEN   */
                            END IF;
                        END if;

                        IF v_last_no_com IS NULL AND v_continue THEN -- pas de complétion

                            v_etape := 'Création de l''entete de commande de prépa';
                            v_ret   := pc_bas_atv_cre_ent_com (pr_ent_cmd            => r_cmd_e ,
                                                               p_no_com              => v_last_no_com,
                                                               p_etat_atv_pc_ent_com => v_etat_ent_fin,
                                                               p_cle_eclat_com       => v_cle_eclat_com);

                            IF v_ret <> 'OK' THEN
                                UPDATE pc_ent_cmd SET
                                    cod_err_pc_ent_cmd ='PC-INT-021'
                                WHERE no_cmd=r_cmd_e.no_cmd;
                               
                                -- anomalie
                                su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                                                p_niv_ano         => 2,
                                                p_cod_err_ora_ano => SQLCODE,
                                                p_cod_usn         => p_cod_usn,
                                                p_lib_ano_1       => 'Cde usine',
                                                p_par_ano_1       => r_cmd_e.no_cmd,
                                                p_cod_err_su_ano  => 'PC-INT-021',
                                                p_nom_obj         => v_nom_obj,
                                                p_version         => v_version,
                                                p_cod_ala         => 'PC_INT_ENT_CMD');


                            END IF;
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj || ' Creation pc_ent_com ' || v_last_no_com);
                            END IF;
                        END IF;

                        -- si le type de colis est imposé par le N3 on recherche le type de colis
                        -- si le colis est CD alors on passe directement le statut de la ligne à découpé
                        v_etat_lig_com:=NULL;

                        IF v_continue THEN
                            IF r_cmd_l.no_uee_N3 IS NOT NULL THEN
                                v_etape:= 'N° de colis imposé par N3 / Recherche du type de colis';
                                v_ret := pc_bas_atv_typ_col_n3(pr_lig_cmd=>r_cmd_l);
                                IF v_ret = 'ERROR' THEN
                                    UPDATE pc_ent_cmd SET
                                        cod_err_pc_ent_cmd ='PC-INT-023'
                                    WHERE no_cmd=r_cmd_e.no_cmd;
                                     -- anomalie
                                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                                                    p_cod_err_ora_ano => SQLCODE,
                                                    p_niv_ano         => 2,
                                                    p_cod_usn         => p_cod_usn,
                                                    p_lib_ano_1       => 'Cde usine',
                                                    p_par_ano_1       => r_cmd_l.no_cmd,
                                                    p_lib_ano_2       => 'Ligne',
                                                    p_par_ano_2       => TO_CHAR(r_cmd_l.no_lig_cmd),
                                                    p_cod_err_su_ano  => 'PC-INT-023',
                                                    p_nom_obj         => v_nom_obj,
                                                    p_version         => v_version,
                                                    p_cod_ala         => 'PC_INT_LIG_CMD');
                                    
                                    v_continue := FALSE;
                                ELSE
                                    -- si colis détail
                                    v_etat_lig_com:= v_etat_lig_fin_2;
                                    v_typ_col:=v_ret;
                                END IF;

                            ELSE
                                v_etat_lig_com:= v_etat_lig_fin_1;
                                v_typ_col:=NULL;
                            END IF;
                        END IF;

                        IF v_continue THEN
                            v_etape := 'Création des lignes de commande de prépa';
                            v_ret := pc_bas_atv_cre_lig_com (
                                                            pr_lig_cmd            =>r_cmd_l,
                                                            p_no_com              =>v_last_no_com,
                                                            p_typ_col             =>v_typ_col,
                                                            p_etat_atv_pc_lig_com =>v_etat_lig_com
                                                            );

                            IF v_ret <> 'OK' THEN

                                UPDATE pc_lig_cmd SET
                                    cod_err_pc_lig_cmd ='PC-INT-022'
                                WHERE no_cmd=r_cmd_l.no_cmd AND no_lig_cmd=r_cmd_l.no_lig_cmd;
                                
                                 -- anomalie
                                su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                                                p_cod_err_ora_ano => SQLCODE,
                                                p_niv_ano         => 2,
                                                p_cod_usn         => p_cod_usn,
                                                p_lib_ano_1       => 'Cde usine',
                                                p_par_ano_1       => r_cmd_l.no_cmd,
                                                p_lib_ano_2       => 'Ligne',
                                                p_par_ano_2       => TO_CHAR(r_cmd_l.no_lig_cmd),
                                                p_cod_err_su_ano  => 'PC-INT-022',
                                                p_nom_obj         => v_nom_obj,
                                                p_version         => v_version,
                                                p_cod_ala         => 'PC_INT_LIG_CMD');


                            ELSE
                                v_etape := 'Mise à jour statut sur ligne de commande usine';
                                UPDATE pc_lig_cmd
                                    SET etat_atv_pc_lig_cmd=v_etat_lig_fin
                                WHERE no_lig_cmd=r_cmd_l.no_lig_cmd AND no_cmd=r_cmd_l.no_cmd;
                            END IF;

                            IF su_global_pkv.v_niv_dbg >= 4 THEN
                                su_bas_put_debug(v_nom_obj || ' Creation pc_lig_com ' || v_last_no_com ||
                                                 ' typ_col=' || v_typ_col ||' etat=' || v_etat_lig_com||' >' || v_ret);
                            END IF;

                        END IF;
                    END IF;

                    -- comptage opérations de regroupement
                    pc_integration_pkv.v_nb_rgp := NVL(pc_integration_pkv.v_nb_rgp,0) + 1;

                END LOOP;
        		CLOSE c_cmd_l;

            END IF;
        END LOOP;
        CLOSE c_cmd_e;

    END IF;

    /**********************
    3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_REGROUPE') THEN
        v_ret_evt := pc_evt_atv_regroupe('POST' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-102' ;
          RAISE err_except;
        END IF;
    END IF;

    COMMIT;
    v_ret:='OK';

    RETURN v_ret;

EXCEPTION

    WHEN OTHERS THEN
	  ROLLBACK to my_sp_bas_regroupe;
      IF c_cmd_e%ISOPEN THEN
	      CLOSE c_cmd_e;
	  END IF;
      IF c_cmd_l%ISOPEN THEN
		  CLOSE c_cmd_l;
	  END IF;

      su_bas_cre_ano (  p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'no_cmd',
                        p_par_ano_2       => r_cmd_e.no_cmd,
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
*   pc_bas_atv_decoupe_get_ul_max -
*/
-- DESCRIPTION :
-- -------------
-- Fonction permettant de rechercher la branche à utiliser pour le découpage
--
-- p_qte_cde est toujours exprimée en unite de base UB
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01g,13.02.14,mnev    Ajout controle sur VL <> piece pour prise en compte
--                      du pcb.
-- 01f,15.02.11,mnev    Corrige le choix de la VL de debut pour l'arbre  
-- 01e,09.02.11,mnev    Corrige probleme sur decoupe en mode multi pièces
-- 01d,30.09.10,rbel    ajout fonctions événements
-- 01c,04.07.08,mnev    ajout du parametre p_last_niv pour correction dans
--                      la recherche.
-- 01b,03.06.08,mnev    test pour decoupage sur VL vendables seulement ...
-- 01a,06.12.06,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--  NON

FUNCTION pc_bas_atv_decoupe_get_ul_max (
    p_cod_pro                  PC_LIG_COM.COD_PRO%TYPE,
    p_cod_vl                   PC_LIG_COM.COD_VL%TYPE,
    p_qte_cde                  PC_LIG_COM.QTE_CDE%TYPE, -- en UB
    p_cod_vl_feuille   OUT     PC_LIG_COM.COD_VL%TYPE,
    p_pcb_exp    	  		   PC_LIG_COM.PCB_EXP%TYPE,
    p_cod_usn                  PC_ENT_COM.COD_USN%TYPE,
    p_cod_pss_afc              PC_LIG_COM.COD_PSS_AFC%TYPE,
    p_last_niv         IN OUT  NUMBER
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01g $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_decoupe_get_ul_max';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;
    
    v_last_vl           VARCHAR2(100) := NULL;
    v_typ_vl            VARCHAR2(100) := NULL;
    v_nb_ub_max         NUMBER (15,6);
    v_niveau_max        NUMBER (15,6);
	v_check_vl          BOOLEAN:= FALSE;
    TYPE t_vl_exclu     IS TABLE OF pc_lig_com.cod_vl%TYPE INDEX BY BINARY_INTEGER;
    v_vl_exclu			t_vl_exclu;
    v_cpt_vl_exclu      INTEGER:=0;
    v_cod_vl_deb        su_ul.cod_vl%TYPE;

	-- Pour balayer l'arbre des VLs
    CURSOR c_vl (x_cod_pro      su_ul.cod_pro%TYPE,
                 x_cod_vl_deb   su_ul.cod_vl%TYPE) IS
        SELECT cod_vl,  cod_vl_inf, typ_ul typ,
               nb_ub,pcb, LEVEL niveau
        FROM su_ul
        WHERE cod_pro = x_cod_pro AND
              (
              su_bas_gcl_su_pro_action(cod_pro,cod_vl,'V','ETAT_PRO_ACTION') = '1' OR  -- produit vendable
              su_bas_gcl_su_pro_action(cod_pro,cod_vl,'E','ETAT_PRO_ACTION') = '1')    -- produit expédiable
        CONNECT BY cod_vl_inf = PRIOR cod_vl AND cod_pro = PRIOR cod_pro
        START WITH cod_vl = x_cod_vl_deb AND cod_pro = x_cod_pro
        ORDER BY LEVEL; -- pour la gestion de l'exclusion

    r_vl        c_vl%ROWTYPE;
    v_multi_pce VARCHAR2(10);

    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
      su_bas_put_debug(v_nom_obj||' : p_cod_pro = '         || p_cod_pro
                                ||' : p_cod_vl = '          || p_cod_vl
                                ||' : p_qte_cde = '         || p_qte_cde
                                ||' : p_last_niv= '         || TO_CHAR(p_last_niv)
                                ||' : p_pcb_exp = '         || p_pcb_exp);
    END IF;

    -- recherche UL MAX par evenement
    v_etape := 'BAP DECULMAX01';
    v_ret := pc_bap_DECULMAX01 (p_cod_pro, p_cod_vl, p_qte_cde, p_pcb_exp, 
                                p_cod_usn, p_cod_pss_afc, p_last_niv);

    IF v_ret IS NOT NULL THEN
        IF v_ret_evt = 'ERROR' THEN
            RAISE err_except;
        END IF;
        --
        -- on a traite la recherche dans l'événement ...
        --
        p_cod_vl_feuille := su_bas_get_from_string (v_ret,'COD_VL_FEUILLE');
        p_last_niv       := su_bas_get_from_string (v_ret,'LAST_NIV');
        
    ELSE
        --
        -- on n'a pas traite d'evenement ...
        --
        v_etape := 'Recherche du type de la VL du produit de stock';
        v_typ_vl:=su_bas_gcl_su_ul( p_cod_pro   =>p_cod_pro,
                                    p_cod_vl    =>p_cod_vl,
                                    p_colonne   =>'TYP_UL');
        IF v_typ_vl='PCE' THEN
            -- on demarre sur la VL pièce existante ...
            v_cod_vl_deb := p_cod_vl;
        ELSE
            v_etape := 'rch vl DEBUT';
            v_cod_vl_deb:=su_bas_rch_vl_typ (p_cod_pro   => p_cod_pro, 
                                             p_cod_vl    => p_cod_vl,
                                             p_typ_ul    => 'PCE',
                                             p_pcb       => NULL,
                                             p_typ_pro_action=>'V', -- vente
                                             p_dat_pro_action=>SYSDATE,
                                             p_rch_vl    => 1,
                                             p_rch_vl_inf=> 1,
                                             p_rch_vl_sup=> 1);

            IF v_cod_vl_deb IS NULL THEN
                -- si pas de VL pièce trouvée on demarre sur la VL donnée 
                v_cod_vl_deb := p_cod_vl;
            END IF;

        END IF;

        v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                      p_typ_atv =>pc_integration_pkv.v_cod_atv ,
                                      p_cod_cfg=>'MULTI_PCE',
                                      p_val    =>v_multi_pce);

        IF su_global_pkv.v_niv_dbg >= 7 THEN
          su_bas_put_debug(v_nom_obj||' : Typ_vl = '         || v_typ_vl
                                    ||' : cod_vl_deb = '          || v_cod_vl_deb
                                    ||' : multi pce = '         || v_multi_pce);
        END IF;
        -------------------------------------------------
        -- Recherche de la hierarchie de + haut niveau
        -------------------------------------------------
        v_etape := 'Recherche de la hierarchie de plus haut niveau';
        v_nb_ub_max  :=0;
        v_niveau_max := 0;
        v_last_vl:=p_cod_vl;

        OPEN c_vl (p_cod_pro, v_cod_vl_deb);
        LOOP
            FETCH c_vl INTO r_vl;
            EXIT WHEN c_vl%NOTFOUND;
            v_check_vl := TRUE;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
              su_bas_put_debug(v_nom_obj||' Test VL= '  || r_vl.cod_vl);
            END IF;
            --
            -- si on autorise pas le multi pièce
            -- on exclut de l'arbre toutes les branches ayant des VL de type PCE différentes
            --
            IF v_multi_pce='0' THEN
                IF v_cod_vl_deb <> r_vl.cod_vl AND r_vl.typ='PCE' THEN
                    v_cpt_vl_exclu:=v_cpt_vl_exclu+1;
                    v_vl_exclu(v_cpt_vl_exclu):= r_vl.cod_vl;
                    v_check_vl:=FALSE;
                END IF;
            END IF;

            IF v_cpt_vl_exclu > 1 THEN
                FOR i in 1 .. v_cpt_vl_exclu LOOP
                    IF  r_vl.cod_vl_inf = v_vl_exclu(i) THEN
                        v_cpt_vl_exclu:=v_cpt_vl_exclu+1;
                        v_vl_exclu(v_cpt_vl_exclu):= r_vl.cod_vl;
                        v_check_vl:=FALSE;
                    END IF;
                END LOOP;
            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 AND NOT v_check_vl THEN
                su_bas_put_debug(v_nom_obj||' exclue !');
            END IF;

            -- v_nb_ub_max et l'order by permettent de ne retenir que la plus grande VL
            IF v_check_vl AND p_qte_cde >= r_vl.nb_ub AND r_vl.nb_ub >= v_nb_ub_max THEN

                IF su_global_pkv.v_niv_dbg >= 6  THEN
                    su_bas_put_debug(v_nom_obj||' Prise ? / pcb ('||p_pcb_exp||'/'||r_vl.pcb||')');
                END IF;
                -- verifier si cette VL convient ...
                IF NVL(p_pcb_exp,0) > 0 AND r_vl.typ <> 'PCE' THEN
                    -- si le PCB est fourni par la GV
                    IF p_pcb_exp = r_vl.pcb THEN
                        v_nb_ub_max  := r_vl.nb_ub;
                        v_last_vl    := r_vl.cod_vl;
                        v_niveau_max := r_vl.niveau;
                    END IF;
                ELSE
                    -- si le PCB est libre
                    v_nb_ub_max  := r_vl.nb_ub;
                    v_last_vl    := r_vl.cod_vl;
                    v_niveau_max := r_vl.niveau;
                END IF;
            END IF;

        END LOOP;
        -- on memorise le retour ...
        p_cod_vl_feuille := v_last_vl;
        p_last_niv       := v_niveau_max;

        CLOSE c_vl;

    END IF;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||' > p_last_niv= '         || TO_CHAR(p_last_niv)
                                  ||' p_cod_vl_feuille = '  || p_cod_vl_feuille);
    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        IF c_vl%ISOPEN THEN
		    CLOSE c_vl;
		END IF;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code produit',
                        p_par_ano_1       => p_cod_pro,
                        p_lib_ano_2       => 'cod_vl',
                        p_par_ano_2       => p_cod_vl,
                        p_lib_ano_3       => 'qte_cde',
                        p_par_ano_3       => p_qte_cde,
                        p_lib_ano_4       => 'pcb_exp',
                        p_par_ano_4       => p_pcb_exp,
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
*   pc_bas_atv_decoupe -
*/
-- DESCRIPTION :
-- -------------
-- Fonction de découpe des commandes de préparation
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01j,13.02.14,mnev    Correction sur la gestion de v_pcb_org.  .
-- 01i,29.05.13,mnev    Memorisation de l'unite de commande cible.
-- 01h,16.10.12,mnev    Ajout cre_ano sur alarme
-- 01g,04.03.11,mnev    Ajout EXIT sur %NOTFOUND de c_vl. Sinon boucle sans fin
-- 01f,14.02.11,mnev    Reprise code de decoupage (verifié par plans de test)
-- 01e,07.02.11,mnev    controle VL origine expédiable ou vendable 
-- 01d,30.09.10,rbel    Modification paramètre fonction evt ON_DECOUPE_TYP_COL
-- 01c,04.07.08,mnev    Ajout securite sur bouclage et creation de ligne à 0.
-- 01b,13.02.08,mnev    Ajout savepoint intermedaire.
-- 01a,06.12.06,jdre    initialisation
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
--  OUI

FUNCTION pc_bas_atv_decoupe (p_cod_usn       su_usn.cod_usn%TYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE          := '@(#) VERSION 01j $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE          := 'pc_bas_atv_decoupe';
    v_etape             su_ano_his.txt_ano%TYPE          := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE   := NULL;
    v_niv_ano           su_ano_his.niv_ano%TYPE DEFAULT 0;
    err_except          EXCEPTION;

    v_ret               VARCHAR2(100)                    := NULL;
    v_ret_evt           VARCHAR2(20)                     := NULL;
    v_reste             NUMBER (15,6);
    v_pcbub             NUMBER (15,6);
    v_qte         		NUMBER (15,6);
    v_qte_ucde    		NUMBER (15,6);
	v_cod_vl_inf        su_ul.cod_vl_inf%TYPE;
	v_cmpt				NUMBER (15,6);					
    v_pct_min           su_pss_atv_cfg.val_cle_atv%TYPE;
    v_pct_max           su_pss_atv_cfg.val_cle_atv%TYPE;
    v_mode_decp         su_pss_atv_cfg.val_cle_atv%TYPE;
    v_unit_stk_2		su_unite.cod_unite%TYPE:=NULL;
    v_unit_cde_cible	su_unite.cod_unite%TYPE:=NULL;
	v_qte_unit_2		NUMBER (30,6);
	v_qte_ub            NUMBER (30,6);
    v_qte_ul            NUMBER (30,6);
    v_qte_pds           NUMBER (30,6);
    v_qte_pce           NUMBER (30,6);
    v_qte_colis         NUMBER (30,6);
    v_qte_pal           NUMBER (30,6);
    v_qte_vol           NUMBER (30,6);
    v_typ_col           pc_lig_com.typ_col%TYPE          :=NULL;
    v_find_vl           BOOLEAN                          :=FALSE;
    v_etat_lig_ini      VARCHAR2(20);
    v_etat_ent_ini      VARCHAR2(20);
    v_etat_lig_fin      VARCHAR2(20);
    v_traitement        BOOLEAN;
    v_pcb_org           pc_lig_com.pcb_exp%TYPE;
    v_cod_vl_org        pc_lig_com.cod_vl%TYPE;
    v_typ_vl_org        VARCHAR2(100) := NULL;
    v_lst_post_colisage VARCHAR2(1000):= NULL;
    v_reste_en_cd       VARCHAR2(30)  := NULL;
    v_typ_sans_decoupe  VARCHAR2(100) := NULL;

    -- Recherche des commandes de préparation à découper
    CURSOR c_com(x_etat_ent_ini VARCHAR2,x_etat_lig_ini VARCHAR2)IS
    SELECT L.*
    FROM   pc_ent_com E,pc_lig_com L
    WHERE  E.cod_usn=p_cod_usn AND E.etat_atv_pc_ent_com=x_etat_ent_ini AND
           L.etat_atv_pc_lig_com=x_etat_lig_ini AND E.no_com=L.no_com AND
           L.cod_err_pc_lig_com IS NULL AND E.cod_err_pc_ent_com IS NULL
    ORDER  BY E.no_com
    FOR UPDATE NOWAIT;

    r_com pc_lig_com%ROWTYPE;

    -- pour balayer l'arbre des VLs
    CURSOR c_vl(x_cod_pro su_ul.cod_pro%TYPE,
                x_cod_vl  su_ul.cod_vl%TYPE,
                x_mode    VARCHAR2) IS
        SELECT cod_pro, cod_vl, typ_ul typ, mode_col, nb_ub ,pcb
         FROM su_ul
        WHERE cod_pro = x_cod_pro
          AND cod_vl = x_cod_vl 
          AND (x_mode ='ORIGINE' OR
               su_bas_gcl_su_pro_action(cod_pro,cod_vl,'V','ETAT_PRO_ACTION') = '1' OR  -- produit vendable
               su_bas_gcl_su_pro_action(cod_pro,cod_vl,'E','ETAT_PRO_ACTION') = '1');   -- produit expédiable

    r_vl        c_vl%ROWTYPE;
    r_vl_org    c_vl%ROWTYPE;

    v_last_niv  NUMBER := NULL;

    v_spoint    VARCHAR2(100) := NULL;

BEGIN

    SAVEPOINT my_sp_bas_decoupe;

    /************************
    1) PHASE INITIALISATION
    ************************/

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_cod_usn = ' || p_cod_usn);
    END IF;

    v_etat_ent_ini:=su_bas_rch_etat_atv('REGROUPEMENT','PC_ENT_COM');
    v_etat_lig_ini:=su_bas_rch_etat_atv('REGROUPEMENT','PC_LIG_COM');
    v_etat_lig_fin:=su_bas_rch_etat_atv('DECOUPAGE','PC_LIG_COM');

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_DECOUPE') THEN
        v_ret_evt := pc_evt_atv_decoupe('PRE' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-100' ;
          RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_ATV_DECOUPE') THEN
        v_ret_evt := pc_evt_atv_decoupe('ON' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-101' ;
          RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        v_etape := 'Recherche des commandes de préparation à découper';
        OPEN c_com(v_etat_ent_ini,v_etat_lig_ini);
        LOOP
            -- raz du niveau d'anomalie ...
            v_niv_ano        := 0;
            v_cod_err_su_ano := NULL;
            -- -----
            -- BEGIN
            -- -----
            BEGIN -- {

            v_etape := 'Fetch';
            v_spoint := NULL;
            v_traitement:=TRUE;
            v_cmpt:=0;

   		    FETCH c_com INTO r_com;
            EXIT WHEN c_com%NOTFOUND;

            v_spoint := 'my_sp_bas_dec' || r_com.no_com || '-' || TO_CHAR(r_com.no_lig_com);
            SAVEPOINT v_spoint;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' Decoupage LigCom:' || r_com.no_com || '-' ||
                                 TO_CHAR(r_com.no_lig_com));
            END IF;

            -- comptage opérations de découpage
            pc_integration_pkv.v_nb_dec := NVL(pc_integration_pkv.v_nb_dec,0) + 1;

            -- oooooooooooooooooooooooooooooooooo
            -- Evénements de decoupe spécifique
            -- oooooooooooooooooooooooooooooooooo
            v_etape := ' Recherche du MODE_DECP ; p_cod_pss:' ||NVL(r_com.COD_PSS_AFC,su_bas_get_pss_defaut(p_cod_usn))
                                             ||'; p_typ_atv:' ||pc_integration_pkv.v_cod_atv
                                             ||'; p_cod_cfg:MODE_DECP';

            v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                          p_typ_atv =>pc_integration_pkv.v_cod_atv ,
                                          p_cod_cfg=>'MODE_DECP',
                                          p_val=>v_mode_decp);
            IF v_ret<>'OK' then
                v_cod_err_su_ano := 'PC-INT-038';
                RAISE err_except;
            END IF;

            v_etape := 'Lecture typ_ul';
            v_typ_vl_org:=su_bas_gcl_su_ul( p_cod_pro   =>r_com.cod_pro,
                                            p_cod_vl    =>r_com.cod_vl,
                                            p_colonne   =>'TYP_UL');

            IF v_mode_decp <> '0' THEN
                v_etape := 'Appel événement découpe spécifique';
                v_ret := pc_evt_atv_spe_decoupe(r_com);
                IF v_ret <>'OK' THEN
                    v_cod_err_su_ano := 'PC-INT-101' ;
                    RAISE err_except;
                END IF;
            -- oooooooooooooooooooooooooooooo
            -- Evénements de decoupe standard
            -- oooooooooooooooooooooooooooooo
            ELSE
                v_etape := 'Recherche clé atv PCT_MIN_DEC';
                v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                              p_typ_atv =>pc_integration_pkv.v_cod_atv,
                                              p_cod_cfg=>'PCT_MIN_DEC',
                                              p_val=>v_pct_min);
                IF v_ret<>'OK' THEN
                    v_niv_ano:=2;
                    v_cod_err_su_ano := 'PC-INT-030';
                    RAISE err_except;
                END IF;
   	
                v_etape := 'Recherche clé atv PCT_MAX_DEC';
                v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                              p_typ_atv =>pc_integration_pkv.v_cod_atv,
                                              p_cod_cfg=>'PCT_MAX_DEC',
                                              p_val=>v_pct_max);
                IF v_ret<>'OK' THEN
                    v_niv_ano:=2;
                    v_cod_err_su_ano := 'PC-INT-031' ;
                    RAISE err_except;
                END IF;

                v_etape := 'Recherche clé atv LST_POST_COLISAGE';
                v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                              p_typ_atv =>'POR' ,
                                              p_cod_cfg =>'LST_POST_COLISAGE',
                                              p_val     =>v_lst_post_colisage);
                IF v_ret<>'OK' THEN
                    v_niv_ano:=2;
                    v_cod_err_su_ano := 'PC-INT-331' ;
                    RAISE err_except;
                END IF;

                v_etape := 'Recherche clé atv RESTE_EN_CD';
                v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                              p_typ_atv =>pc_integration_pkv.v_cod_atv,
                                              p_cod_cfg =>'RESTE_EN_CD',
                                              p_val     =>v_reste_en_cd);
                IF v_ret<>'OK' THEN
                    v_niv_ano:=2;
                    v_cod_err_su_ano := 'PC-INT-332' ;
                    RAISE err_except;
                END IF;

                v_etape := 'Recherche clé atv TYP_SANS_DECOUPE';
                v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss =>su_bas_get_pss_defaut(p_cod_usn),
                                              p_typ_atv =>pc_integration_pkv.v_cod_atv,
                                              p_cod_cfg =>'TYP_SANS_DECOUPE',
                                              p_val     =>v_typ_sans_decoupe);
                IF v_ret<>'OK' THEN
                    v_niv_ano:=2;
                    v_cod_err_su_ano := 'PC-INT-333' ;
                    RAISE err_except;
                END IF;

                v_qte_ub   := NULL;
       	        v_qte_ul   := NULL;
   		        v_qte_pds  := NULL;
   		        v_qte_pce  := NULL;
   		        v_qte_colis:= NULL;
   		        v_qte_pal  := NULL;
   		        v_qte_vol  := NULL;
   		        v_qte_unit_2:=NULL;
   		        v_unit_stk_2:=NULL;
                -- on memorise l'unite de commande cible car la finalisation pourrait (en spec) la modifier 
                -- et dans ce cas il faut pourvoir reprendre l'unite origine
                v_unit_cde_cible := r_com.unite_cde;
   		
                v_etape := 'Recherche des unités pour produit '||r_com.cod_pro;
                v_ret:=su_bas_conv_unite_to_all (p_cod_pro   => r_com.cod_pro,
                                                 p_cod_vl    => r_com.cod_vl,
                                                 p_pcb       => r_com.pcb_exp,
                                                 p_qte_unit_1=> r_com.qte_cde,
                                                 p_unit_stk_1=> v_unit_cde_cible,
                                                 p_qte_unit_2=> v_qte_unit_2,
                                                 p_unit_stk_2=> v_unit_stk_2,
                                                 p_qte_ub    => v_qte_ub,
                                                 p_qte_ul    => v_qte_ul,
                                                 p_qte_pds   => v_qte_pds,
                                                 p_qte_pce   => v_qte_pce,
                                                 p_qte_colis => v_qte_colis,
                                                 p_qte_pal   => v_qte_pal,
                                                 p_qte_vol   => v_qte_vol);

                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' Decoupage conversion:' || v_ret);
                END IF;

   		        IF v_ret <> 'OK' THEN
                    v_niv_ano:=2;
                    v_cod_err_su_ano := 'PC-INT-032' ;
                    v_traitement := FALSE;
                END IF;

                v_etape := 'calcul en UB';
                IF v_traitement THEN
                    r_com.qte_cde   :=  v_qte_ub; 	
                    v_qte           :=  r_com.qte_cde;
                    v_reste         :=  0;
                    IF (v_qte<=0 OR v_qte IS NULL) THEN
                        v_niv_ano := 2;
                        v_cod_err_su_ano := 'PC-INT-036' ;
                        v_traitement := FALSE;
                    END IF;
                END IF;

                IF NOT v_traitement THEN

                    v_etape := 'PB sur gestion de la qté';
                    UPDATE pc_lig_com SET
                        cod_err_pc_lig_com = v_cod_err_su_ano
                    WHERE no_com=r_com.no_com AND no_lig_com=r_com.no_lig_com;

                    su_bas_cre_ano (p_txt_ano         => v_etape,
                                    p_niv_ano         => '2',
                                    p_cod_usn         => p_cod_usn,
                                    p_cod_err_ora_ano => SQLCODE,
                                    p_lib_ano_1       => 'no_com',
                                    p_par_ano_1       => r_com.no_com,
                                    p_lib_ano_2       => 'no lig com',
                                    p_par_ano_2       => r_com.no_lig_com,
                                    p_lib_ano_3       => 'v_qte',
                                    p_par_ano_3       => TO_CHAR(v_qte),
                                    p_lib_ano_4       => 'v_qte_ub',
                                    p_par_ano_4       => TO_CHAR(v_qte_ub),
                                    p_lib_ano_5       => 'v_ret',
                                    p_par_ano_5       => v_ret,
                                    p_lib_ano_6       => 'pcb',
                                    p_par_ano_6       => TO_CHAR(r_com.pcb_exp),
                                    p_lib_ano_7       => 'qte_cde',
                                    p_par_ano_7       => TO_CHAR(r_com.qte_cde),
                                    p_lib_ano_8       => 'unite',
                                    p_par_ano_8       => v_unit_cde_cible,
                                    p_cod_err_su_ano  => v_cod_err_su_ano,
                                    p_nom_obj         => v_nom_obj,
                                    p_version         => v_version,
                                    p_cod_ala         => 'PC_INT_LIG_COM');
                ELSE

                    v_etape := 'init avant loop';
                    v_find_vl       :=FALSE;
                    v_cod_vl_org    :=r_com.cod_vl;
                    v_pcb_org       :=r_com.pcb_exp;

                    v_etape := 'Rch vl origine';
                    OPEN c_vl (r_com.cod_pro, r_com.cod_vl, 'ORIGINE');
                    FETCH c_vl INTO r_vl_org;
                    CLOSE c_vl;

                    -- ---------------------------------------------------------
                    -- on effectue le decoupage
                    -- et on travaille la qte en unite de base ...
                    -- Rappel : 1 Colis = N1 pièces / 1 pièce = N2 Unite de base
                    -- ---------------------------------------------------------

                    v_cod_vl_inf := NULL;
                    v_last_niv   := NULL;

                    v_etape := 'On effectue le découpage';
                    LOOP

                        v_etape := 'Loop qte=' || TO_CHAR(v_qte);
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj||' Decoupage LOOP v_qte:' || TO_CHAR(v_qte));
                        END IF;

                        EXIT WHEN v_qte <= 0;

                        -- -----------------------------------------------------------
                        -- Si PCB renseigné et que le typ de vl <> PCE et que 1er tour
                        -- -----------------------------------------------------------
	                    IF NVL(v_pcb_org,0) > 0 AND v_typ_vl_org<>'PCE' AND v_cmpt=0 THEN
                            -- Une VL colis existe : on la garde !!!
                            v_cod_vl_inf:= v_cod_vl_org;

                        ELSIF v_typ_vl_org ='PCE' AND INSTR(v_typ_sans_decoupe,';' || r_com.typ_lig_com ||';') > 0 THEN
                            -- Conserver la VL d'origine pour lignes de certains types   
                            -- On garde la VL pièce origine
                            v_cod_vl_inf:= v_cod_vl_org;       

                        ELSE
                            -- on cherche autre chose ... dans une autre VL ...
                            v_etape := 'Recherche la branche la plus haute dans l''arbre des VLs';
                            v_ret:=pc_integration_pkg.pc_bas_atv_decoupe_get_ul_max (
                                                                        p_cod_pro       =>r_com.cod_pro,
                                                                        p_cod_vl        =>v_cod_vl_org,
                                                                        p_qte_cde       =>v_qte,
                                                                        p_cod_vl_feuille=>v_cod_vl_inf,
                                                                        p_pcb_exp       =>v_pcb_org,
                                                                        p_cod_usn       =>p_cod_usn,
                                                                        p_cod_pss_afc   =>r_com.cod_pss_afc,
                                                                        p_last_niv      =>v_last_niv);
                        END IF;

                        IF v_ret <> 'OK' THEN
                            v_niv_ano:=2;
                            v_cod_err_su_ano := 'PC-INT-034' ;
                            v_traitement := FALSE;
                        END IF;

                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj||' Get UL MAX :' || v_cod_vl_inf);
                            su_bas_put_debug(v_nom_obj||' Basculer reste en CD :' || v_reste_en_cd);
                            su_bas_put_debug(v_nom_obj||' PCB origine :' || TO_CHAR(v_pcb_org));
                        END IF;
                        --
                        -- Lecture VL retenue 
                        --
                        v_etape := 'Open c_vl';
                        OPEN c_vl (r_com.cod_pro, v_cod_vl_inf, 'NEW');
                        FETCH c_vl INTO r_vl;
                        IF c_vl%FOUND THEN
                            v_etape := 'found c_vl';
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj||' LECTURE VL retenue Typ:' || r_vl.typ);
                                su_bas_put_debug(v_nom_obj||'               Mode_Col:' || r_vl.mode_col);
                                su_bas_put_debug(v_nom_obj||'                  Nb_UB:' || TO_CHAR(r_vl.nb_ub));
                                su_bas_put_debug(v_nom_obj||'                 Pcb_VL:' || TO_CHAR(r_vl.pcb));
                            END IF;

                            -- recherche TYP COL par evenement
                            v_etape := 'BAP DECTYPCOL01';
                            v_ret := pc_bap_DECTYPCOL01 (r_com.no_com, r_com.no_lig_com,
                                                         r_com.cod_pro, v_cod_vl_inf, v_lst_post_colisage);
                            IF v_ret IS NOT NULL THEN
                                IF v_ret_evt = 'ERROR' THEN
                                    RAISE err_except;
                                END IF;
                                --
                                -- on a traite la recherche dans l'événement ...
                                --
                                v_typ_col := v_ret;

                            ELSE
                                -- on détermine le type de colis
                                IF ((r_vl.typ='PCE' AND r_vl.mode_col IS NOT NULL) OR
                                    INSTR(v_lst_post_colisage,r_com.typ_lig_com) > 0) AND
                                    su_bas_gcl_pc_lig_cmd(p_no_cmd=>r_com.no_cmd,
                                                          p_no_lig_cmd=>r_com.no_lig_cmd,
                                                          p_colonne=>'PCB_EXP') IS NULL THEN
                                    -- SI VL piece ET mode de colisage connu ET pcb_exp pas renseigner 
                                    -- ALORS colis detail
                                    v_typ_col :=pc_integration_pkv.v_col_cd;
                                ELSE
                                    -- sinon COLIS COMPLET
                                    v_typ_col:=pc_integration_pkv.v_col_cc;
                                END IF;

                            END IF;
                            --
                            -- SI VL pièce + Bascule reste en CD + PCB connu 
                            -- ALORS on fractionne en fonction du PCB connu
                            --
                            v_etape := 'calcul partie non imputable sur la VL';
                            IF r_vl.typ='PCE' THEN
                                v_pcbub := NVL(v_pcb_org,1) * NVL(r_vl.nb_ub,1);
                            ELSE
                                v_pcbub := NVL(r_vl.nb_ub,1);
                            END IF;

                            v_reste := MOD(v_qte, v_pcbub);

                            IF v_qte < v_pcbub THEN
                                --
                                -- si moins d'1 UL ...
                                --
                                IF v_typ_col = pc_integration_pkv.v_col_cc THEN
                                    -- si colis complet 
                                    IF v_reste_en_cd = '1' THEN
                                        -- si reste du CC en colis detail : on bascule
                                        v_typ_col := pc_integration_pkv.v_col_cd;
                                    END IF;
                                END IF;
                                -- on prend tout sinon on s'en sortira jamais ...
                                v_reste := 0;
                            ELSE
                                --
                                -- si au moins une UL ...
                                --
                                IF v_typ_col = pc_integration_pkv.v_col_cd AND NVL(v_pcb_org,0) > 0 THEN
                                    -- si colis detail et PCB demandé  : on bascule 
                                    v_typ_col := pc_integration_pkv.v_col_cc;
                                END IF;
                            END IF;

                            -- calcul de la partie que l'on prend sur cette VL de decoupage
                            v_qte := v_qte - v_reste;   -- en UB

                            r_com.pcb_exp := NVL(v_pcb_org,NVL(r_vl.pcb,1));

                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj||' CALCULS   TypCol:' || v_typ_col);
                                su_bas_put_debug(v_nom_obj||'              Qte:' || TO_CHAR(v_qte));
                                su_bas_put_debug(v_nom_obj||'           Pcb_UB:' || TO_CHAR(v_pcbub));
                                su_bas_put_debug(v_nom_obj||'            Reste:' || TO_CHAR(v_reste));
                                su_bas_put_debug(v_nom_obj||'   PCB Expedition:' || TO_CHAR(r_com.pcb_exp));
                            END IF;

                            -- securite pour eviter bouclage sur creation de ligne à 0
                            v_etape := 'Controle coherence';
                            IF v_qte <= 0 THEN
                                v_niv_ano:=2;
                                RAISE err_except;
                            END IF;

                            -- Conversion de la qte du colis en unité de base							
                            v_etape := 'conversion';
                            v_ret := su_bas_conv_unite_to_one(p_cod_pro 	 => r_vl.cod_pro,
                                                              p_cod_vl  	 => r_vl.cod_vl,
                                                              p_qte_orig     => v_qte,
                                                              p_unite_orig   => 'UB',
                                                              p_unite_dest   => v_unit_cde_cible,
                                                              p_qte_dest     => v_qte_ucde);	

                            v_etape := 'Fois n° ' || TO_CHAR(v_cmpt);
                            IF v_cmpt=0 THEN
                                -- -----------------------------------------------------
                                -- La premiere fois on met a jour la ligne existante ...
                                -- -----------------------------------------------------
                                v_find_vl:=TRUE;
                                v_etape := 'Mise à jour des lignes de commande de prépa';
                                v_niv_ano := 2;                      -- s'il y a des erreurs
                                v_cod_err_su_ano := 'PC-INT-039' ;

                                -- MAJ record local
                                v_etape := 'MAJ record local';
                                r_com.cod_vl  := v_cod_vl_inf;
                                r_com.qte_cde := v_qte_ucde; 
                                r_com.typ_col := v_typ_col;
                                r_com.etat_atv_pc_lig_com := v_etat_lig_fin;

                                IF su_global_pkv.v_niv_dbg >= 6 THEN
                                    su_bas_put_debug(v_nom_obj||' Decoupage VL:' || r_com.cod_vl);
                                    su_bas_put_debug(v_nom_obj||' Decoupage Qte:' || r_com.qte_cde);
                                    su_bas_put_debug(v_nom_obj||' Decoupage Typ:' || r_com.typ_col);
                                    su_bas_put_debug(v_nom_obj||' Decoupage PCB:' || r_com.pcb_exp);
                                END IF;

                                -- MAJ record local
                                v_etape := 'MAJ pc_lig_com';
                                UPDATE  pc_lig_com SET
                                        cod_vl              = r_com.cod_vl,
                                        qte_cde             = r_com.qte_cde,
                                        typ_col             = r_com.typ_col,
                                        etat_atv_pc_lig_com = r_com.etat_atv_pc_lig_com,
                                        pcb_exp             = r_com.pcb_exp
                                WHERE no_lig_com=r_com.no_lig_com AND no_com=r_com.no_com;

                                v_etape := 'Finalisation lignes de commande de prépa';
                                v_ret:=pc_bas_fnl_enr_lig_com(p_mode     =>'INTEGR',
                                                              pr_lig_com => r_com);

                                IF v_ret <> 'OK' THEN
                                    v_niv_ano:=2;
                                    RAISE err_except;
                                END IF;

                            ELSE
                                -- -------------------------------------------------------------
                                -- les fois suivantes on cree une nouvelle ligne par duplication
                                -- -------------------------------------------------------------
                                v_find_vl:=TRUE;
                                v_etape  := 'Création des lignes de commande de prépa';
                                v_ret    := pc_bas_atv_dup_lig_com (
                                            pr_lig_com             => r_com,
                                            p_cod_vl               => v_cod_vl_inf,
                                            p_qte_cde              => v_qte_ucde, 
                                            p_typ_col              => v_typ_col,
                                            p_etat_atv_pc_lig_com  => v_etat_lig_fin,
                                            p_pcb_exp              => NVL(v_pcb_org,NVL(r_vl.pcb,1))
                                            ) ;

                                IF su_global_pkv.v_niv_dbg >= 6 THEN
                                    su_bas_put_debug(v_nom_obj||' Decoupage VL:' || v_cod_vl_inf);
                                    su_bas_put_debug(v_nom_obj||' Decoupage Qte:' || v_qte_ucde);
                                    su_bas_put_debug(v_nom_obj||' Decoupage VL:' || v_typ_col);
                                    su_bas_put_debug(v_nom_obj||' Decoupage PCB:' || NVL(v_pcb_org,NVL(r_vl.pcb,1)));
                                END IF;

                                IF v_ret <> 'OK' THEN
                                    v_niv_ano:=2;
                                    v_cod_err_su_ano := 'PC-INT-035' ;
                                    RAISE err_except;
                                END IF;
                            END IF;
                        ELSE
                            v_etape := 'not found c_vl';
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj||' Decoupage FIN rch');
                            END IF;
                            CLOSE c_vl; 
                            EXIT;
                        END IF;
                        CLOSE c_vl;

                        --
                        --v_etape := 'reset pcb_org';
                        --IF NVL(v_pcb_org,0) > 0 AND r_vl.typ<>'PCE' AND v_cmpt=0 THEN
                            --v_pcb_org := NULL; -- ne plus imposer de PCB dans la prochaine boucle
                        --END IF;

                        -- qte restante = au reste à traiter ...
                        v_qte:=v_reste;

                        -- boucle suivante 
                        v_cmpt:=v_cmpt+1;

      	            END LOOP;

         	        IF NOT v_find_vl THEN
                        v_etape := 'Erreur ds traitement / impossible de trouver une vl';
                        v_niv_ano:=2;
                        v_cod_err_su_ano := 'PC-INT-037' ;
                        RAISE err_except;
                    END IF;
                END IF;
            END IF;

            -- ---------
            -- EXCEPTION
            -- ---------
            EXCEPTION
                WHEN OTHERS THEN
                    IF c_vl%ISOPEN THEN
                        CLOSE c_vl;
                    END IF;

                    IF v_niv_ano = 2 THEN
                        IF v_spoint IS NOT NULL THEN
                            ROLLBACK TO v_spoint;
                        END IF;

                        UPDATE pc_lig_com SET
                            cod_err_pc_lig_com = v_cod_err_su_ano
                        WHERE no_com=r_com.no_com AND no_lig_com=r_com.no_lig_com;

                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj||' Exception catchee ' || v_cod_err_su_ano ||
                                             ' sur ligne ' || r_com.no_com || ' ' || r_com.no_lig_com);
                        END IF;

                        -- anomalie
                        su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Cde prepa',
                            p_par_ano_1       => r_com.no_com,
                            p_lib_ano_2       => 'Ligne',
                            p_par_ano_2       => TO_CHAR(r_com.no_lig_com),
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_LIG_COM');
                        
                    ELSE
                        RAISE err_except;
                    END IF;
            END; -- }

        END LOOP;
	    CLOSE c_com;
    END IF;

    COMMIT;

    /**********************
    3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_DECOUPE') THEN
      v_ret_evt := pc_evt_atv_decoupe('POST' , p_cod_usn);
      IF v_ret_evt = 'ERROR' THEN
        v_cod_err_su_ano := 'PC-INT-102' ;
        RAISE err_except;
      END IF;
    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK to my_sp_bas_decoupe;
		IF c_com%ISOPEN THEN
		    CLOSE c_com;
		END IF;
        IF c_vl%ISOPEN THEN
		    CLOSE c_vl;
		END IF;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
                        p_lib_ano_2       => 'no_com',
                        p_par_ano_2       => r_com.no_com,
                        p_lib_ano_3       => 'no_lig_com',
                        p_par_ano_3       => r_com.no_lig_com,
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
*   pc_bas_atv_decoupe_optimize -
*/
-- DESCRIPTION :
-- -------------
-- Fonction permettant d'optimiser le découpage si les paramètres %min et %max
-- sont renseignés
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,23.03.10,mnev    Corrige test sur cod_vl '00'
-- 01a,06.12.06,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_atv_decoupe_optimize (
      p_cod_pro         PC_LIG_COM.COD_PRO%TYPE,
      p_cod_vl          PC_LIG_COM.COD_VL%TYPE,
      p_pcb_exp         PC_LIG_COM.PCB_EXP%TYPE,
      p_pct_min         NUMBER,
      p_pct_max         NUMBER ,
      p_qte_cde         PC_LIG_COM.QTE_CDE%TYPE,
      p_qte_cde_new OUT PC_LIG_COM.QTE_CDE%TYPE,
      p_cod_vl_new  OUT PC_LIG_COM.COD_VL%TYPE,
      p_cod_usn         PC_ENT_COM.COD_USN%TYPE,
      p_cod_pss_afc     PC_LIG_COM.COD_PSS_AFC%TYPE
)  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_decoupe_optimize';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
    v_reste             NUMBER (15,6);
    v_qte         		NUMBER (15,6);
    v_qte_somme       	NUMBER (15,6);
	v_cod_vl            su_ul.cod_vl_inf%TYPE;
	v_cod_vl_inf        su_ul.cod_vl_inf%TYPE := NULL;
	v_nb_ul             NUMBER (15,6);
    v_nb_ul_max         NUMBER (15,6):=0;	
    v_delta             NUMBER (15,6):=0;
    v_last_niv          NUMBER := NULL;

    -- pour balayer l'arbre des VL
    CURSOR c_vl(x_cod_pro su_ul.cod_pro%TYPE,
                x_vl_ini  su_ul.cod_vl%TYPE) IS
        SELECT  cod_pro, cod_vl, cod_ul, cod_vl_inf,
                typ_ul typ,
                nb_ub,pcb, LEVEL niveau
        FROM su_ul
        WHERE cod_pro = x_cod_pro
        CONNECT BY cod_vl_inf = PRIOR cod_vl AND cod_pro = PRIOR cod_pro
        START WITH cod_vl = x_vl_ini AND cod_pro = x_cod_pro
		ORDER BY LEVEL DESC;

    r_vl c_vl%ROWTYPE;
				
BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj);
    END IF;

    FOR i in 1..3 LOOP
        IF i=1 THEN
            v_qte:=  p_qte_cde;
            v_delta:=0 ;
        ELSIF i=2 THEN
            v_qte:=  p_qte_cde-p_qte_cde* p_pct_min/100;
            v_delta:=p_qte_cde* p_pct_min/100;
        ELSE
            v_qte:=  p_qte_cde+p_qte_cde* p_pct_max/100;
            v_delta:=p_qte_cde* p_pct_max/100;
        END IF;

        v_etape := 'Rch branche la plus haute';
        v_ret:= pc_integration_pkg.pc_bas_atv_decoupe_get_ul_max (p_cod_pro=> p_cod_pro,
                                                                  p_cod_vl=>p_cod_vl ,
                                                                  p_qte_cde =>v_qte,
                                                                  p_cod_vl_feuille=>v_cod_vl_inf,
                                                                  p_pcb_exp=>p_pcb_exp,
                                                                  p_cod_usn=>p_cod_usn,
                                                                  p_cod_pss_afc=>p_cod_pss_afc,
                                                                  p_last_niv=>v_last_niv);
        IF v_ret <> 'OK' THEN
            v_cod_err_su_ano := 'PC-INT-034' ;
            RAISE err_except;
        END IF;
        v_qte_somme:=0;
        v_reste:=0;
        v_nb_ul:=0;
        v_etape := 'Balayage de l''arbre complet';
        OPEN c_vl(p_cod_pro, NVL(su_global_pkv.r_su_cfg_appli.cod_vl,'00'));
        LOOP
            FETCH c_vl INTO r_vl;
            EXIT WHEN c_vl%NOTFOUND;
            IF v_cod_vl_inf=r_vl.cod_vl THEN
                IF  v_qte>=r_vl.NB_UB THEN
                    v_reste := MOD(v_qte,r_vl.NB_UB);
                    v_qte:=v_qte-v_reste;
                    v_qte_somme:=  v_qte_somme+ v_qte;
                    v_qte:=v_reste;
                    v_nb_ul:=v_nb_ul+1;
                    v_cod_vl:= r_vl.cod_vl;
                    IF v_Qte<=v_Delta THEN
                        v_Qte:=0;
                    END IF;
                END IF;
                v_cod_vl_inf:=r_vl.cod_vl_inf;
            END IF;
        END LOOP;
        CLOSE c_vl;
        IF v_nb_ul_max>v_nb_ul or v_nb_ul_max=0 THEN
            v_nb_ul_max:=v_nb_ul;
            p_qte_cde_new:=v_qte_somme;
            p_cod_vl_new:=v_cod_vl;
        END IF;
    END LOOP;

    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
		IF c_vl%ISOPEN THEN
		    CLOSE c_vl;
		END IF;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => '',
                        p_par_ano_1       => '',
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
*   pc_bas_atv_qvt -
*/
-- DESCRIPTION :
-- -------------
-- Fonction permettant qualifier , calculer le volume et de choisir le transport
-- d'une commande de préparation
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 06a,21.01.14,mnev    repositionne etat_autor_pord et etat_autor_porl
--                      en fonction du mode "preordo ligne" actif ou non.
-- 05a,23.12.13,mnev    positionne etat_autor_pord à 0 si preordo ligne actif
-- 04b,22.10.13,rbel    ajout clef process GES_PENURIE
-- 04a,26.07.12,mnev    gestion ex_cmd_dpt en asynchrone
-- 03a,25.06.12,mnev    Ajout comptage nb lignes traitées 
-- 02c,09.11.09,rbel    Correction gestion cas d'erreur
-- 02b,02.07.09,tcho    Gestion mode estimation colis détail
--                      + fct de rch transporteur (cas messagerie)
-- 02a,03.11.08,mnev    Ajout calcul qte commandees pour ecran suivi depart.
-- 01a,06.12.06,JDRE    initialisation
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
--  OUI
--

FUNCTION pc_bas_atv_qvt (p_cod_usn     su_usn.cod_usn%TYPE)  
RETURN VARCHAR2
IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 06a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_qvt';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
    TYPE t_no_com       IS TABLE OF pc_lig_com.no_com%TYPE INDEX BY BINARY_INTEGER;
	v_no_com			t_no_com;
    v_nb_cpt            NUMBER (15,6):=0;
    v_last_no_com       pc_lig_com.no_com%TYPE:=NULL;
    v_etat_lig_ini      VARCHAR2(20);
    v_etat_ent_ini      VARCHAR2(20);
    v_etat_lig_fin      VARCHAR2(20);
    v_mode_cd           varchar2(20);
    v_mode_rch_tra      varchar2(20);
    v_mode_ges_penurie  varchar2(20);
    r_ent_com           pc_ent_com%ROWTYPE;
    v_continue          BOOLEAN;

    -- Recherche des commandes de préparation à qualifier
    CURSOR c_com(x_etat_ent_ini VARCHAR2,x_etat_lig_ini VARCHAR2) IS
    SELECT L.*
    FROM   pc_ent_com E,pc_lig_com L
    WHERE  E.cod_usn=p_cod_usn AND
           E.etat_atv_pc_ent_com= x_etat_ent_ini AND
           L.etat_atv_pc_lig_com= x_etat_lig_ini AND
           E.no_com=L.no_com AND L.cod_err_pc_lig_com IS NULL AND
           E.cod_err_pc_ent_com IS NULL
    ORDER  BY E.no_com
    FOR UPDATE NOWAIT;

    r_com  pc_lig_com%ROWTYPE;

BEGIN

    SAVEPOINT my_sp_bas_qvt;

    /************************
    1) PHASE INITIALISATION
    ************************/

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_cod_usn = ' || p_cod_usn);
    END IF;

    v_etape := 'Init des valeurs';
    v_etat_lig_ini   := su_bas_rch_etat_atv('DECOUPAGE','PC_LIG_COM');
    v_etat_ent_ini   := su_bas_rch_etat_atv('REGROUPEMENT','PC_ENT_COM');
    v_etat_lig_fin   := su_bas_rch_etat_atv('QUALIFICATION','PC_LIG_COM');
    v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss => su_bas_get_pss_defaut(p_cod_usn),
                                  p_typ_atv => pc_integration_pkv.v_cod_atv ,
                                  p_cod_cfg => 'MODE_ESM_CD',
                                  p_val     => v_mode_cd);
    v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss => su_bas_get_pss_defaut(p_cod_usn),
                                  p_typ_atv => pc_integration_pkv.v_cod_atv ,
                                  p_cod_cfg => 'MODE_RCH_TRA',
                                  p_val     => v_mode_rch_tra);
    v_ret:=su_bas_rch_cle_atv_pss(p_cod_pss => su_bas_get_pss_defaut(p_cod_usn),
                                  p_typ_atv => pc_integration_pkv.v_cod_atv ,
                                  p_cod_cfg => 'GES_PENURIE',
                                  p_val     => v_mode_ges_penurie);

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_QVT') THEN
        v_ret_evt := pc_evt_atv_qvt('PRE' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
            v_cod_err_su_ano := 'PC-INT-100' ;
            RAISE err_except;
        END IF;
    END IF;

    /********************
    2) PHASE TRAITEMENT
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.EXISTS('ON_ATV_QVT') THEN
        v_ret_evt := pc_evt_atv_qvt('ON', p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-101' ;
          RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN

	    v_etape := 'Recherche des lignes de commandes de préparation à traiter';
        OPEN c_com(v_etat_ent_ini,v_etat_lig_ini);
        LOOP
            FETCH c_com INTO r_com;
            EXIT WHEN c_com%NOTFOUND;

            -- comptage opérations de qualification
            pc_integration_pkv.v_nb_qvt := NVL(pc_integration_pkv.v_nb_qvt,0) + 1;

            -- gestion de la penurie
            IF NVL(v_mode_ges_penurie, '1') = '1' THEN
                v_etape:='gestion de la penurie';
                v_ret:=pc_bas_ret_gestion_penurie(p_no_com     => r_com.no_com,
                                                  p_no_lig_com => r_com.no_lig_com);
            END IF;

            IF v_ret != 'OK' THEN
                su_bas_cre_ano (p_txt_ano => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_com',
                        p_par_ano_1       => r_com.no_com,
                        p_lib_ano_2       => 'no lig com',
                        p_par_ano_2       => r_com.no_lig_com,
                        p_cod_err_su_ano  => 'PC-RETAILLE-12',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
            END IF;

            -- qualification
            v_etape := 'Qualification';
            v_ret:=pc_bas_atv_qvl_lig_com (pr_lig_com=>r_com) ;
            IF v_ret = 'ERROR' THEN
                v_cod_err_su_ano := 'PC-INT-040' ;
                UPDATE pc_lig_com SET
                    cod_err_pc_lig_com =v_cod_err_su_ano
                WHERE no_com=r_com.no_com and  no_lig_com=r_com.no_lig_com;

                -- anomalie
                su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Cde prepa',
                            p_par_ano_1       => r_com.no_com,
                            p_lib_ano_2       => 'Ligne',
                            p_par_ano_2       => TO_CHAR(r_com.no_lig_com),
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_LIG_COM');
                                            
            -- si v_ret ='KO' alors on pas trouvé le process ou on a pas pu qualifier le travail
            ELSIF v_ret = 'OK' THEN
                IF pc_porl_man_pkg.pc_bas_is_porl_active(p_cod_usn) = 'OUI' THEN
                    --
                    -- si preordo ligne alors obligatoirement pas d'autorisation de preordo std
                    --          
                    v_etape := 'Mise à jour statut qualification';
                    UPDATE pc_lig_com E SET
                        etat_atv_pc_lig_com=v_etat_lig_fin,
                        etat_autor_pord='0'     
                    WHERE E.no_com=r_com.no_com AND E.no_lig_com=r_com.no_lig_com ;
                ELSE
                    --
                    -- si pas de preordo ligne alors obligatoirement pas d'autorisation de preordo ligne
                    --          
                    v_etape := 'Mise à jour statut qualification';
                    UPDATE pc_lig_com E SET
                        etat_atv_pc_lig_com=v_etat_lig_fin,
                        etat_autor_porl='0'
                    WHERE E.no_com=r_com.no_com AND E.no_lig_com=r_com.no_lig_com ;
                END IF;
                
                IF v_last_no_com<>r_com.no_com THEN
                    v_nb_cpt:=v_nb_cpt+1;
                    v_no_com(v_nb_cpt):= v_last_no_com;
                END IF;
         
                v_last_no_com:=r_com.no_com;
            END IF;
                       
        END LOOP;
        CLOSE c_com;

        IF v_last_no_com IS NOT NULL THEN
            v_nb_cpt:=v_nb_cpt+1;
            v_no_com(v_nb_cpt):= v_last_no_com;
        END IF;

        -- Balayage par n° de commande
        FOR i in 1 ..v_nb_cpt
        LOOP
            v_continue := TRUE;

            v_etape := 'Recalcul du volume';
            v_ret:=pc_bas_atv_estm_vol_com(p_no_com =>v_no_com(i),p_mode_cd => v_mode_cd);
            IF v_ret <> 'OK' THEN
                v_cod_err_su_ano := 'PC-INT-041' ;
                UPDATE pc_lig_com SET 
                    cod_err_pc_lig_com = v_cod_err_su_ano
                WHERE no_com=v_no_com(i);
                -- anomalie
                su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Cde prepa',
                            p_par_ano_1       => v_no_com(i),
                            p_cod_err_su_ano  => 'PC-INT-041',
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_ENT_COM');
                
                v_continue := FALSE;
            END IF;

            IF v_mode_rch_tra>'0' AND v_continue THEN
                v_etape := 'Rch info commande';
                r_ent_com := su_bas_grw_pc_ent_com(v_no_com(i));
                IF r_ent_com.cod_tra_1 IS null THEN
                    v_etape := 'Rch du transporteur';
                    v_ret :=  ex_bas_get_tra_n2_np(
                                p_pc_ent_com => r_ent_com,
                                p_mode_rch_tra => v_mode_rch_tra
                                );
                    IF v_ret !='OK' THEN
                        v_cod_err_su_ano := 'PC-INT-043' ;
                        UPDATE pc_lig_com SET 
                            cod_err_pc_lig_com = v_cod_err_su_ano
                        WHERE no_com=v_no_com(i);
                        -- anomalie
                        su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Cde prepa',
                            p_par_ano_1       => v_no_com(i),
                            p_cod_err_su_ano  => 'PC-INT-043',
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_ENT_COM');
                        v_continue := FALSE;
                    ELSIF r_ent_com.cod_tra_1 IS NOT null THEN
                        v_etape := 'Mise à jour du transporteur';
                        UPDATE pc_ent_com
                        SET cod_tra_1=r_ent_com.cod_tra_1,
                            cod_tou=r_ent_com.cod_tou
                        WHERE no_com=v_no_com(i);
                    END IF;
                END IF;
            END IF;

            IF v_continue then
                v_etape := 'Recalcul du transport';
                v_ret:=pc_bas_atv_cal_tra(p_no_com =>v_no_com(i));
                IF v_ret <> 'OK' THEN
                    v_cod_err_su_ano := 'PC-INT-042' ;
                    UPDATE pc_lig_com SET 
                        cod_err_pc_lig_com = v_cod_err_su_ano
                    WHERE no_com=v_no_com(i);
                    -- anomalie
                    su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => 2,
                            p_cod_usn         => p_cod_usn,
                            p_lib_ano_1       => 'Cde prepa',
                            p_par_ano_1       => v_no_com(i),
                            p_cod_err_su_ano  => 'PC-INT-042',
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version,
                            p_cod_ala         => 'PC_INT_ENT_COM');
                    
                    v_continue := FALSE;
                END IF;
            END IF;

            IF v_continue THEN
                v_etape := 'calcul qte cde pour ex_cmd_dpt';
                -- maj des données dans EX_CMD_DPT
                pc_bas_dem_maj_ex_cmd_dpt (p_cle1  => v_no_com(i));
            END IF;
            
            IF v_mode_rch_tra > '0' THEN
                -- on est dans un mode recherche transport non planifié à la commande
                -- donc on a un grain à la commande
                -- Si une des lignes de la commande est en erreur
                -- on repasse toutes les lignes dans l'état initial (DECOUPAGE FINI)
                -- et on mets un code erreur aux autres lignes de commandes
                UPDATE pc_lig_com 
                   SET etat_atv_pc_lig_com= v_etat_lig_ini,
                       cod_err_pc_lig_com = NVL(cod_err_pc_lig_com, 'PC-INT-044') 
                WHERE etat_atv_pc_lig_com = v_etat_lig_fin 
                  AND no_com IN (SELECT no_com 
                                   FROM pc_lig_com 
                                  WHERE no_com=v_no_com(i) AND cod_err_pc_lig_com IS NOT NULL);
            END IF;            

        END LOOP;

    END IF;

    /**********************
    3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_QVT') THEN
        v_ret_evt := pc_evt_atv_qvt('POST' , p_cod_usn);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-102' ;
          RAISE err_except;
        END IF;
    END IF;

    COMMIT;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK to my_sp_bas_qvt;
        IF c_com%ISOPEN THEN
		    CLOSE c_com;
	    END IF;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code usine',
                        p_par_ano_1       => p_cod_usn,
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
*   pc_bas_atv_qvl_lig_com -
*/
-- DESCRIPTION :
-- -------------
-- Fonction permettant qualifier une commande de préparation
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01b,22.12.09,mnev    inverse la rech de la qualification TRV - PSS
-- 01a,06.12.06,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  Ligne commande de préparation
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
-- NON

FUNCTION pc_bas_atv_qvl_lig_com (pr_lig_com pc_lig_com%ROWTYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_qvl_lig_com';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_fnc           VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_session_ora       VARCHAR2(100);
    vr_lig_com          pc_lig_com%ROWTYPE := pr_lig_com;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||' : no_com = ' || vr_lig_com.no_com||' : no_lig_com = ' || vr_lig_com.no_lig_com);
    END IF;

    /************************
     1) PHASE INITIALISATION
    ************************/

    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_QVL_LIG_COM') THEN
        v_ret_evt := pc_evt_atv_qvl_lig_com('PRE' , vr_lig_com);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-100' ;
          RAISE err_except;
        END IF;
    END IF;

    /********************
     2) PHASE TRAITEMENT
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_ATV_QVL_LIG_COM') THEN
        v_ret_evt := pc_evt_atv_qvl_lig_com('ON' , vr_lig_com );
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-101' ;
          RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN

        -- oooooooooooooooooooooooooooooooooo
        -- Recherche qualification du travail
        -- oooooooooooooooooooooooooooooooooo
        v_etape := 'su_bas_rch qlf_pss';
        v_ret:= su_bas_rch_qlf_trv(pr_lig_com=> vr_lig_com, 
                                   p_cle_rch_qlf=>'INT');
        IF v_ret IS NULL THEN
            v_etape := 'Aucun qlt trv';
            v_ret_fnc  :='KO';
            UPDATE pc_lig_com SET
                cod_err_pc_lig_com ='PC-INT-051'
            WHERE no_lig_com=vr_lig_com.no_lig_com AND no_com=vr_lig_com.no_com;

            -- anomalie
            su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_niv_ano         => 2,
                        p_cod_usn         => vr_lig_com.cod_usn,
                        p_lib_ano_1       => 'Cde prepa',
                        p_par_ano_1       => vr_lig_com.no_com,
                        p_lib_ano_2       => 'Ligne',
                        p_par_ano_2       => TO_CHAR(vr_lig_com.no_lig_com),
                        p_cod_err_su_ano  => 'PC-INT-051',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_INT_LIG_COM');                            
        ELSE
            v_etape := 'Update qlf trv pc_lig_com';
            UPDATE  pc_lig_com SET
                cod_qlf_trv = v_ret
            WHERE no_lig_com=vr_lig_com.no_lig_com AND no_com=vr_lig_com.no_com;

            vr_lig_com.cod_qlf_trv := v_ret;

            -- ooooooooooooooooooooooooooooooooooo
            -- Recherche du process de préparation
            -- ooooooooooooooooooooooooooooooooooo

            v_ret:= su_bas_rch_qlf_pss(pr_lig_com   => vr_lig_com, 
                                       p_cle_rch_qlf=>'INT');

            IF v_ret IS NULL THEN
                v_ret_fnc  :='KO';
                v_etape := 'Aucune pss';
                UPDATE pc_lig_com SET
                    cod_err_pc_lig_com ='PC-INT-050'
                WHERE no_lig_com=vr_lig_com.no_lig_com AND no_com=vr_lig_com.no_com;

                -- anomalie
                su_bas_cre_ano (p_txt_ano         => 'ERREUR : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_niv_ano         => 2,
                        p_cod_usn         => vr_lig_com.cod_usn,
                        p_lib_ano_1       => 'Cde prepa',
                        p_par_ano_1       => vr_lig_com.no_com,
                        p_lib_ano_2       => 'Ligne',
                        p_par_ano_2       => TO_CHAR(vr_lig_com.no_lig_com),
                        p_cod_err_su_ano  => 'PC-INT-050',
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version,
                        p_cod_ala         => 'PC_INT_LIG_COM');                                           
                
            ELSE
                v_etape := 'Update pss pc_lig_com';
                UPDATE pc_lig_com SET
                    cod_pss_afc = v_ret
                WHERE no_lig_com=vr_lig_com.no_lig_com AND no_com=vr_lig_com.no_com;
            END IF;
        END IF;
    END IF;

    /**********************
     3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_QVL_LIG_COM') THEN
        v_ret_evt := pc_evt_atv_qvl_lig_com('POST' , vr_lig_com );
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-102' ;
          RAISE err_except;
        END IF;
    END IF;

    RETURN v_ret_fnc;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
		su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'n°com',
                        p_par_ano_1       => pr_lig_com.no_com,
                        p_lib_ano_2       => 'n°lig com',
                        p_par_ano_2       => pr_lig_com.no_lig_com,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN NVL(v_cod_err_su_ano,'ERROR');

END;
/****************************************************************************
*   pc_bas_atv_estm_vol_com -
*/
-- DESCRIPTION :
-- -------------
-- Fonction permettant de calculer le volume d'une commande de préparation
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,02.07.09,tcho    gestion d'un mode d'estimation pour les colis détails
-- 01a,06.12.06,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  N° de la commande
--  mode de calcul pour colis détail (1= avec précolisage)
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON
FUNCTION pc_bas_atv_estm_vol_com (
    p_no_com                  PC_LIG_COM.NO_COM%TYPE,
    p_mode_cd                 varchar2 DEFAULT '0'
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_estm_vol_com';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_vol_esm           NUMBER(15,6):=0;
    v_pds_net_esm       NUMBER(15,6):=0;
    v_pds_brut_esm      NUMBER(15,6):=0;
    v_nb_col_esm        NUMBER(15,6):=0;
    v_nb_pal_esm        NUMBER(15,6):=0;
    v_nb_pce_esm        NUMBER(15,6):=0;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||' : p_no_com = ' || p_no_com);
    END IF;

    /************************
     1) PHASE INITIALISATION
    ************************/
    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_ESTM_VOL_COM') THEN
        v_ret_evt := pc_evt_atv_estm_vol_com('PRE' , p_no_com);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-100' ;
          RAISE err_except;
        END IF;
    END IF;

    /********************
     2) PHASE TRAITEMENT
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_ESTM_VOL_COM') THEN
        v_ret_evt := pc_evt_atv_estm_vol_com('ON' , p_no_com);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-101' ;
          RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN
        v_etape := 'Recherche des quantités estimés';
        v_ret_evt := pc_bas_com_qte_esm (p_no_com        =>p_no_com,
                                         p_no_cde        =>NULL,
                                         p_mode_cd       =>p_mode_cd,
                                         p_vol_esm       =>v_vol_esm,
                                         p_pds_net_esm   =>v_pds_net_esm,
                                         p_pds_brut_esm  =>v_pds_brut_esm,
                                         p_nb_col_esm    =>v_nb_col_esm,
                                         p_nb_pal_esm    =>v_nb_pal_esm,
                                         p_nb_pce_esm    =>v_nb_pce_esm);

        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-320' ;
          RAISE err_except;
        END IF;

        v_etape := 'Maj volume pc_ent_com';
        UPDATE pc_ent_com SET
            vol_esm         = v_vol_esm,
            pds_net_esm     =v_pds_net_esm,
            pds_brut_esm    = v_pds_brut_esm,
            nb_col_esm      = v_nb_col_esm,
            nb_pal_esm    	= v_nb_pal_esm
        WHERE no_com=p_no_com;
    END IF;

    /**********************
    3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_ESTM_VOL_COM') THEN
        v_ret_evt := pc_evt_atv_estm_vol_com('POST' , p_no_com);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-102' ;
          RAISE err_except;
        END IF;
    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
		su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'N° cde',
                        p_par_ano_1       => p_no_com,
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
*   pc_bas_atv_cal_tra -
*/
-- DESCRIPTION :
-- -------------
-- Fonction permettant de choisir le transport d'une commande de préparation
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,19.01.15,pluc    Specif. SUO : ajout n° de quai.
-- 01c,27.10.08,mnev    lecture cle_dpt pour appel de ex_bas_ins_dpt_reel
-- 01b,17.09.08,rbel    exclure les commandes avec un mode_afc_dpt demandant aucune notion de départ
-- 01a,06.12.06,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  N° de la commande
--
-- RETOUR :
-- --------
--  OK ou ERROR
--
-- COMMIT :
-- --------
--   NON
FUNCTION pc_bas_atv_cal_tra (
    p_no_com                  pc_lig_com.no_com%TYPE
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_cal_tra';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
    v_no_dpt            pc_ent_dpt.no_dpt%TYPE;

    -- Lecture infos dans commande +
    -- Controle si commande de prepa deja imputee sur depart ...
    CURSOR c_com IS
        SELECT a.no_dpt, a.dat_exp, a.cod_usn, a.cod_tou, a.cod_tra_1, a.no_com, a.cod_soc,
               a.cod_zon_geo, a.dat_liv, a.cod_cli, a.cod_adr_exp_a,
               a.pds_brut_esm, a.vol_esm, a.nb_pal_esm, a.libre_pc_ent_com_5 cod_quai
        FROM pc_ent_com a
        WHERE a.no_com = p_no_com
          AND NOT EXISTS (SELECT 1                  -- déjà imputée
                          FROM ex_lig_dpt b
                          WHERE b.typ_dpt='2'
                            AND b.cle1=a.no_com
                            AND b.no_dpt=a.no_dpt)
          AND a.mode_afc_dpt <> 'S';                -- sans affectation

    r_com c_com%ROWTYPE;

    -- Recherche cle_dpt de la commande usine associee
    CURSOR c_cmd (x_no_com pc_lig_com.no_com%TYPE) IS
        SELECT A.cle_dpt
        FROM pc_ent_cmd A, pc_lig_com B
        WHERE A.no_cmd = B.no_cmd AND B.no_com = x_no_com;

    r_cmd c_cmd%ROWTYPE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_no_com = ' || p_no_com);
    END IF;

    /************************
     1) PHASE INITIALISATION
    ************************/
    v_etape := 'Appel événement PRE';
    IF su_global_pkv.vt_evt_actif.exists('PRE_ATV_CAL_TRA') THEN
        v_ret_evt := pc_evt_atv_cal_tra('PRE' , p_no_com);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-100' ;
          RAISE err_except;
        END IF;
    END IF;

    /********************
     2) PHASE TRAITEMENT
    ********************/

    v_etape := 'Appel événement ON';
    IF su_global_pkv.vt_evt_actif.exists('ON_ATV_CAL_TRA') THEN
        v_ret_evt := pc_evt_atv_cal_tra('ON' , p_no_com);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-101' ;
          RAISE err_except;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    IF v_ret_evt IS NULL THEN

      -- ----------------------------------------------------------------
      -- Declaration de la commande de preparation dans le module EX pour
      -- integration dans le plan transport.
      -- ----------------------------------------------------------------
      v_etape := 'open c_com';
      OPEN c_com;
      FETCH c_com INTO r_com;
      IF c_com%FOUND THEN
          v_etape := 'open c_cmd';
          OPEN c_cmd (p_no_com);
          FETCH c_cmd INTO r_cmd;
          CLOSE c_cmd;

          v_etape := 'Imputation ent_com sur dpt';
          v_ret:=ex_planning_depart_pkg.ex_bas_ins_dpt_reel (
                                                            p_no_dpt      =>r_com.no_dpt,
                                                            p_dat_dep_th  =>r_com.dat_exp,
                                                            p_no_dep_th   =>r_com.no_dpt,
                                                            p_ref_dpt_ext =>r_cmd.cle_dpt,
                                                            p_cod_usn     =>r_com.cod_usn,
                                                            p_cod_tou     =>r_com.cod_tou,
                                                            p_cod_tra     =>r_com.cod_tra_1,
                                                            p_cod_quai_rl =>r_com.cod_quai,         -- $MOD,19.01.14,pluc
                                                            p_typ_dpt     =>'2',
                                                            p_cle1        =>r_com.no_com,
                                                            p_cle2        =>r_com.cod_soc,
                                                            p_typ_tiers   =>'C',
                                                            p_ctrl_capacite=>0,
                                                            p_no_dpt_attrib=>v_no_dpt,
                                                            p_a_supprimer  =>'0',
                                                            p_mod_dpt      =>'0',
                                                            p_typ_tiers_lf =>'C',
                                                            p_cod_tiers_lf =>r_com.cod_cli,
                                                            p_cod_adr_lf   =>r_com.cod_adr_exp_a,
                                                            p_dat_liv_th   =>r_com.dat_liv,
                                                            p_cod_sec_geo  =>r_com.cod_zon_geo,
                                                            p_pds_cde      =>r_com.pds_brut_esm,
                                                            p_vol_cde      =>r_com.vol_esm,
                                                            p_nb_pal_cde   =>r_com.nb_pal_esm
                                                            );

          IF su_global_pkv.v_niv_dbg >= 6 THEN
              su_bas_put_debug(v_nom_obj||' : v_no_dpt=' || v_no_dpt || ' v_ret=' || v_ret);
          END IF;

          IF v_ret <> 'OK' THEN
              v_cod_err_su_ano := 'PC_ENT_COM_003';
              RAISE err_except;
          END IF;
      END IF;
      CLOSE c_com;

    END IF;

    /**********************
     3) PHASE FINALISATION
    **********************/

    v_etape := 'Appel événement POST';
    IF su_global_pkv.vt_evt_actif.exists('POST_ATV_CAL_TRA') THEN
        v_ret_evt := pc_evt_atv_cal_tra('POST' , p_no_com);
        IF v_ret_evt = 'ERROR' THEN
          v_cod_err_su_ano := 'PC-INT-102' ;
          RAISE err_except;
        END IF;
    END IF;

    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
		su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'N° cde',
                        p_par_ano_1       => p_no_com,
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
*   pc_bas_atv_typ_col_n3 -
*/
-- DESCRIPTION :
-- -------------
-- Fonction permettant de déterminer le type de colis pour une ligne de commande
-- dont le n° de colis est imposé par le N3
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,06.12.06,JDRE    initialisation
-- 00a,06.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- PARAMETRE :
-- --------
--  pr_lig_cmd   : la ligne de commande usinee
--
-- RETOUR :
-- --------
-- Le type de colis ou ERROR
--
-- COMMIT :
-- --------
--  NON
--
FUNCTION pc_bas_atv_typ_col_n3 (pr_lig_cmd      pc_lig_cmd%ROWTYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_atv_typ_col_n3';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    v_unit_stk_2		su_unite.cod_unite%TYPE:=NULL;
	v_qte_unit_2		NUMBER (15,6);
	v_qte_ub            NUMBER (15,6);
    v_qte_ul            NUMBER (15,6);
    v_qte_pds           NUMBER (15,6);
    v_qte_pce           NUMBER (15,6);
    v_qte_colis         NUMBER (15,6);
    v_qte_pal           NUMBER (15,6);
    v_qte_vol           NUMBER (15,6);

    -- Recherche des commandes de préparation à qualifier
    CURSOR c_lig_cmd(x_no_uee_n3 VARCHAR2) IS
    SELECT COUNT(1) NB
    FROM pc_lig_cmd
    WHERE no_uee_n3=x_no_uee_n3;

    r_lig_cmd            c_lig_cmd%ROWTYPE;

    CURSOR c_ul(x_cod_pro su_ul.cod_pro%TYPE,x_cod_vl su_ul.cod_vl%TYPE) IS
    SELECT nb_ub
    FROM su_ul
    WHERE cod_pro=x_cod_pro and cod_vl=x_cod_vl;

    r_ul                c_ul%ROWTYPE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || ' No Cmd:' || pr_lig_cmd.no_cmd ||
                                      ' No Lig:' || pr_lig_cmd.no_lig_cmd);
    END IF;

    v_etape := 'Recherche si plusieurs lignes avec le même n° de colis n3';
    OPEN c_lig_cmd(pr_lig_cmd.no_uee_n3);
    FETCH c_lig_cmd INTO r_lig_cmd;
    IF c_lig_cmd%NOTFOUND THEN
        RAISE err_except;
    ELSE
        -- Il y a plusieurs lignes donc on est en colis détail
        IF r_lig_cmd.nb > 1 THEN
            v_ret :=pc_integration_pkv.v_col_cd;
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || ' plusieurs lignes => typ_col=' || v_ret);
            END IF;
        ELSE
            -- Il y a 1 ligne donc on teste pour trouver le type de colis
            IF pr_lig_cmd.pcb_exp IS NOT NULL AND pr_lig_cmd.pcb_exp > 0 THEN
                v_ret :=pc_integration_pkv.v_col_cc;
            ELSE
                v_ret :=pc_integration_pkv.v_col_cd;
            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || ' 1 seule ligne => typ_col=' || v_ret);
            END IF;


        END IF;
    END IF;
    CLOSE c_lig_cmd;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        IF c_lig_cmd%ISOPEN THEN
		    CLOSE c_lig_cmd;
	    END IF;
        IF c_ul%ISOPEN THEN
		    CLOSE c_ul;
	    END IF;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;

END; -- fin du package
/
SHOW ERRORS;


















