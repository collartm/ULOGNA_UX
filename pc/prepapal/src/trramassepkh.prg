/* $Id$
****************************************************************************
* pc_tr_ramasse_pkg -
*/
-- DESCRIPTION :
-- -------------
-- Ce package gère les menu du terminal radio des postes ramasse
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,28.07.10,rbel    Diverses corrections d'écritures
-- 01a,19.01.10,jlfa    Version initiale
-- 00a,06.12.05,GENMPD  version 2.4
-- -------------------------------------------------------------------------
--
CREATE OR REPLACE
PACKAGE pc_tr_ramasse_pkg IS
    PROCEDURE su_bas_key_f1;
    PROCEDURE su_bas_key_f4;
    PROCEDURE su_bas_init;
    PROCEDURE su_bas_exit;
    PROCEDURE pc_bas_valid_debut_bor;
    PROCEDURE pc_bas_aff_lst;
    PROCEDURE pc_bas_valid_cb_pic;
    PROCEDURE pc_bas_aff_ord_pic;
    PROCEDURE pc_bas_valid_qte_prel;
    PROCEDURE pc_bas_prevalid_qte_prel;
    PROCEDURE pc_bas_desaff_bor (p_no_bor_pic  pc_pic.no_bor_pic%TYPE DEFAULT NULL);
    PROCEDURE pc_bas_entree_stk;
    PROCEDURE pc_bas_sortie_stk;
    FUNCTION  pc_bas_bor_term RETURN VARCHAR2;
    PROCEDURE pc_bas_ramasse_colis;
    PROCEDURE pc_bas_ramasse_paquet;
    PROCEDURE pc_bas_valid_uee;
    PROCEDURE pc_bas_aff_uee_pic;
    PROCEDURE pc_bas_cloture_bor;
    PROCEDURE pc_bas_conf_abandon;
    PROCEDURE pc_bas_conf_recom;
    PROCEDURE pc_bas_recommence_bor;
    PROCEDURE pc_bas_abandonne_bor;
    PROCEDURE pc_bas_retour;
    PROCEDURE pc_bas_val_tmp;
    PROCEDURE pc_bas_del_tmp;
    PROCEDURE pc_bas_valid_bor;

    --  Variable ecran
    v_index              VARCHAR2(20);
    
    v_no_pos             su_pos.no_pos%TYPE;
    v_cod_ope            su_ope.cod_ope%TYPE;
    v_lst_pss            pc_pos.lst_pss%TYPE;
    v_lst_cod_cc_cb      pc_pos.lst_cod_cc_cb%TYPE;
    v_cod_cc_stk	     su_ent_cc.cod_cc%TYPE;
    v_lst_cod_cc_stk	 pc_pos.lst_cod_cc_cb%TYPE;
    
    v_bordereau_en_cours pc_pic.no_bor_pic%TYPE;
    v_cb_bor_pic_lu      pc_pic.no_bor_pic%TYPE;
    v_no_bor_pic         pc_pic.no_bor_pic%TYPE;
    v_cb_pic             VARCHAR(100);
    v_cod_ut             se_ut.cod_ut%TYPE;
    v_typ_ut             se_ut.typ_ut%TYPE;
    v_typ_ut_exp         se_ut.typ_ut%TYPE;
    v_cod_emp_en_cours   se_emp.cod_emp%TYPE;
    v_lib_emp_en_cours   VARCHAR2(20);
    v_no_stk_en_cours    se_stk.no_stk%TYPE;
    v_cod_pro_en_cours   se_stk.cod_pro%TYPE;
    v_cod_va_en_cours    se_stk.cod_va%TYPE;
    v_cod_vl_en_cours    se_stk.cod_vl%TYPE;
    v_no_com_en_cours    pc_lig_com.no_com%TYPE;
    v_no_cmd_en_cours    pc_lig_com.no_cmd%TYPE;
    v_no_lig_com_en_cours pc_lig_com.no_lig_com%TYPE;
    
    v_cb_uee             pc_uee.cb_complet%TYPE;
    
    v_cod_pro           PC_VAL_PC.cod_pro%TYPE; 
    v_cod_va            PC_VAL_PC.cod_va%TYPE; 
    v_cod_vl            PC_VAL_PC.cod_vl%TYPE; 
    v_cod_prk           PC_VAL_PC.cod_prk%TYPE; 
    v_cod_lot_stk       PC_VAL_PC.cod_lot_stk%TYPE; 
    v_cod_ss_lot_stk    PC_VAL_PC.cod_ss_lot_stk%TYPE; 
    v_dat_dlc           PC_VAL_PC.dat_dlc%TYPE; 
    v_dat_stk           PC_VAL_PC.dat_stk%TYPE;	
    v_pds_brut_val      PC_VAL_PC.pds_brut_val%TYPE;	
    v_pds_net_val       PC_VAL_PC.pds_net_val%TYPE;
    v_car_stk_1         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_2         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_3         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_4         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_5         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_6         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_7         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_8         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_9         se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_10        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_11        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_12        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_13        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_14        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_15        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_16        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_17        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_18        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_19        se_mvt_mat.car_stk_1%TYPE;
    v_car_stk_20        se_mvt_mat.car_stk_1%TYPE;
    v_no_stk            se_stk.no_stk%TYPE;
    v_cod_mag           se_stk.cod_mag%TYPE;
    
    v_etat_pic           VARCHAR2(100);
    v_lib_pro            VARCHAR2(30);
    v_dlc_min            VARCHAR2(10);
    
    v_qte_dem            VARCHAR2(5);
    v_qte_prop           VARCHAR2(5);
    v_qte_prel           VARCHAR2(5);
    
    v_lst_uee            VARCHAR2(4000);
    v_no_pos_etq         su_pos.no_pos%TYPE;
    v_titre              VARCHAR2(100);
    
    v_forcer             BOOLEAN;
    v_valid_par_colis    BOOLEAN;
    v_init_val           BOOLEAN:=FALSE;

    v_nb_col_ent         NUMBER(5);
    v_nb_col_sor         NUMBER(5);
    v_typ_val_pc         VARCHAR2(5);

    v_cod_ut_pal         pc_ut.cod_ut%TYPE;
    v_typ_ut_pal         pc_ut.typ_ut%TYPE;
    v_sscc_ut            VARCHAR2(50);

    CURSOR C_LST_ORD_PIC IS
        SELECT c_text, c_index
        FROM V_C_LST_ORD_PIC
        WHERE no_bor_pic = v_bordereau_en_cours;
                 
    CURSOR C_LST_UEE_PIC IS
        SELECT  c_text,c_index 
        FROM V_C_LST_UEE_PIC
        WHERE  no_bor_pic=v_bordereau_en_cours 
        AND (cod_emp = v_cod_emp_en_cours OR v_cod_emp_en_cours IS NULL)
        AND cod_pro = v_cod_pro_en_cours ;

END pc_tr_ramasse_pkg;
/
show errors;

