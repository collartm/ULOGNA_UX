/* $Id$
****************************************************************************
* sp_pc_ges_debord_pkh - 
*/
-- DESCRIPTION :
-- -------------
-- Ce package gère 
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,11.12.13,TJAF    Création
-- 00a,20.05.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--

CREATE OR REPLACE
PACKAGE sp_pc_ges_debord_pkg AS

    -- Type record pour creation de stat et graphe sur prepa debord
    TYPE tr_sp_pc_gph_deb IS RECORD
    (
        num_pal     NUMBER,
        dat_prep    DATE,  
        delai_prep  NUMBER,
        dat_maq     DATE,  
        delai_maq   NUMBER,                 
        nb_col      NUMBER,                 
        tot_col     NUMBER
    );
    
    TYPE tt_sp_pc_gph_deb IS TABLE OF tr_sp_pc_gph_deb;

    -- Type pour restitution des resa stk en selection debord
    TYPE tr_stk_deb IS RECORD 
    ( 
        cod_pro     se_lig_rstk.cod_pro%TYPE,-- Code produit
        qte         se_lig_rstk.qte_res%TYPE,-- Qte réservé
        tag_map     CHAR     
    );
							  			   							  
    TYPE tt_stk_deb IS TABLE OF tr_stk_deb INDEX BY BINARY_INTEGER; 

    -- Type pour restitution des compteurs debord
    TYPE tr_cpt_deb IS RECORD 
    ( 
        TOT_REF_DEB     NUMBER,
        NB_PAL_DEB      NUMBER,
        NB_PAL_REP      NUMBER,
        NB_PRO_DEB      NUMBER,
        NB_PRO_A_MAP    NUMBER,
        NB_PRO_A_DEMAP  NUMBER,
        NB_PAL_IMPACT   NUMBER,
        NB_PRO_A_REASS  NUMBER
    );
      
    TYPE tt_cpt_deb IS TABLE OF tr_cpt_deb; 

    -- Fonction de calcul du graphe 
    FUNCTION sp_pc_gph_deb_to_tab   (p_cod_usn      su_usn.cod_usn%TYPE,
                                     p_dat_deb      DATE, 
                                     p_dat_fin      DATE)
        RETURN tt_sp_pc_gph_deb  PIPELINED;

    -- Fonction de calcul de la date max de prépa
    FUNCTION sp_pc_dat_max_prep_deb (p_cod_usn      su_usn.cod_usn%TYPE,
                                     p_dat_deb      DATE, 
                                     p_dat_fin      DATE)
        RETURN DATE;

    -- Fonction de calcul de la date de dépassement et de la quantité
    FUNCTION sp_pc_dat_qte_dep_deb  (p_cod_usn su_usn.cod_usn%TYPE,
                                     p_dat_deb      DATE, 
                                     p_dat_fin      DATE,
                                     p_dat_dep      OUT DATE,
                                     p_nb_col_dep   OUT NUMBER)
        RETURN VARCHAR2;

    -- Fonction de calcul des lignes a passer au débord
    FUNCTION sp_pc_cal_vol_deb      (p_cod_usn      su_usn.cod_usn%TYPE,
                                     p_dat_deb      DATE, 
                                     p_dat_fin      DATE)
        RETURN VARCHAR2;

    -- Fonction de calcul de la place disponible pour implantation d'un nouveau produit en débord
    FUNCTION sp_pc_emp_disp_deb     (p_cod_usn      su_usn.cod_usn%TYPE)
        RETURN VARCHAR2;

    -- Fonction de validation de la selection de debord
    FUNCTION sp_pc_crea_mapping     (p_cod_usn      su_usn.cod_usn%TYPE,
                                     p_cod_pro      su_pro.cod_pro%TYPE)
        RETURN VARCHAR2;

    -- Fonction de validation de la selection de debord
    FUNCTION sp_pc_valid_selec_deb  (p_cod_usn      su_usn.cod_usn%TYPE)
        RETURN VARCHAR2;

    -- Fonction de purge du stock de debord
    FUNCTION sp_pc_purge_deb        (p_cod_usn      su_usn.cod_usn%TYPE,
                                     p_lst_cod_pro  VARCHAR2)
        RETURN VARCHAR2;

    -- Fonction d'alimentation des compteurs debord
    FUNCTION sp_pc_compteurs_deb
        RETURN tt_cpt_deb  PIPELINED;

END;
/
show errors;

