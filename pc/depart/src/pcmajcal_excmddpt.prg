/* $Id$
****************************************************************************
* pc_bas_maj_cal_ex_cmd_dpt
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de mettre a jour, de creer ou de supprimer 
-- les données de la table ex_cmd_cpt pour une commande donnee.
--
--
-- PARAMETRES :
-- ------------
-- p_no_com        
-- 
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01g,26.07.12,mnev    ajout etat_trait_cmd_chgt dans l'insert
-- 01f,30.03.11,mnev    ajout maj des champs _ctl dans l'update !!!
-- 01e,10.02.11,alfl    test etat pc_lig_com pour les cartons annulés
-- 01d,02.11.09,mnev    ajout NVL sur no_cde
-- 01c,06.10.09,mnev    correction sur le calcul du nombre de colis annulés
-- 01b,30.06.09,mnev    correction bug sur nb_col_cde dans le cas 
--                      d'une mise a jour.
-- 01a,24.10.08,hess    creation        
-- 00a,07.12.06,GENPRG  version 2.9
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--
-- COMMIT :
-- --------
-- NON

CREATE OR REPLACE
PROCEDURE pc_bas_maj_cal_ex_cmd_dpt (p_no_com        pc_lig_com.no_com%TYPE) 
IS

    v_version           su_ano_his.version%TYPE          := '@(#) VERSION 01g $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE          := 'pc_bas_maj_cal_ex_cmd_dpt';
    v_etape             su_ano_his.txt_ano%TYPE          := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE   := NULL;

    v_ret               VARCHAR2(100)                    := NULL;
    v_typ_tiers         su_cli.typ_tiers%TYPE:=su_bas_get_typ_tiers_cli;
    
    --recupere données
    CURSOR c_lig IS
      SELECT  E.ref_cde_cli, NVL(E.no_cde,'0') no_cde, L.cod_soc, L.cod_usn 
          FROM pc_ent_cmd E,pc_lig_com L  
          WHERE E.no_cmd(+) = L.no_cmd
            AND L.no_com = p_no_com;

    r_lig c_lig%ROWTYPE;
    
    CURSOR c_stat_theo_val IS
    SELECT SUM(qte_cde) qte_cde, SUM(nb_pce_cde) nb_pce_cde, SUM(nb_col_cde) nb_col_cde,
           SUM(pds_cde) pds_cde,
           SUM(nb_pce_val) nb_pce_val, SUM(nb_col_val) nb_col_val,
           SUM(pds_net_val) pds_net_val, SUM(pds_brut_val) pds_brut_val        
    FROM pc_lig_com
    WHERE no_com = p_no_com;
    
    /*
    CURSOR c_stat_ctl IS
    SELECT sum(nb_pce_val) nb_pce_ctl,sum(nb_col_val) nb_col_ctl,
        sum(pds_net_val) pds_net_ctl,sum(pds_brut_val) pds_brut_ctl
    FROM pc_lig_com
    WHERE no_com = p_no_com
      AND su_bas_etat_val_num (pc_lig_com.etat_atv_pc_lig_com,'PC_LIG_COM') >= su_bas_etat_val_num ('TOP_CONTROLE','PC_LIG_COM');
      */

    CURSOR c_stat_ctl IS
    SELECT sum(a.nb_pce_val) nb_pce_ctl,sum(a.nb_col_val) nb_col_ctl,
           sum(a.pds_net_val) pds_net_ctl,sum(a.pds_brut_val) pds_brut_ctl
    FROM pc_uee a, pc_ut b
    WHERE a.no_com = p_no_com and a.cod_ut_sup = b.cod_ut and a.typ_ut_sup = b.typ_ut
      AND su_bas_etat_val_num (b.etat_atv_pc_ut,'PC_UT') >= su_bas_etat_val_num ('TOP_CONTROLE','PC_UT');    

    -- controle presence entete et ligne + lecture statut entete
    CURSOR c_etat_cde IS
    SELECT pc_ent_com.etat_atv_pc_ent_com
    FROM pc_lig_com, pc_ent_com
    WHERE pc_ent_com.no_com = p_no_com AND pc_ent_com.no_com = pc_lig_com.no_com;

    r_etat_cde c_etat_cde%ROWTYPE;

      
    -- compte le nombre de colis créés et annulés 
    CURSOR c_nb_col_ann_1 IS
        SELECT NVL(SUM(nb_col_theo),0) nb_col_ann
        FROM pc_uee
        WHERE pc_uee.etat_atv_pc_uee ='PRP0' AND EXISTS (SELECT 1 
                                                         FROM pc_uee_det 
                                                         WHERE pc_uee_det.no_com=p_no_com AND pc_uee.no_uee=pc_uee_det.no_uee);

    -- compte le nombre de colis jamais créés car annulés 
    CURSOR c_nb_col_ann_2 IS
        SELECT NVL(SUM(nb_col_cde),0) nb_col_ann
        FROM pc_lig_com
        WHERE etat_pcl = '0' AND no_com = p_no_com
        AND su_bas_etat_val_num (pc_lig_com.etat_atv_pc_lig_com,'PC_LIG_COM') >= su_bas_etat_val_num ('PREPARATION_NULLE','PC_LIG_COM');
  
    
    CURSOR c_ex_cmd_dpt(x_no_com      ex_cmd_dpt.cle1%TYPE,
                         x_cod_soc     ex_cmd_dpt.cle2%TYPE,
                         x_no_cde      ex_cmd_dpt.cle3%TYPE,
                         x_cod_usn     ex_cmd_dpt.cod_usn%TYPE,
                         x_typ_tiers   ex_cmd_dpt.typ_tiers%TYPE) IS
      SELECT 1  
          FROM ex_cmd_dpt E
          WHERE typ_dpt='2'
            AND cle1=x_no_com 
            AND cle2=x_cod_soc 
            AND cle3=x_no_cde
            AND cod_usn=x_cod_usn
            AND typ_tiers=x_typ_tiers;
    
    err_except          EXCEPTION;

    -- Lecture configuration des épurations de ex_cmd_dpt de type '2'
    CURSOR c_epur IS
        SELECT TRUNC(SYSDATE - NVL(su_bas_is_number(par_epur_3),'365')) dat_max
        FROM su_epur 
        WHERE cod_epur='PC_INIT' AND actif='1';

    r_epur c_epur%ROWTYPE;
    
    v_nb_col_cde        pc_lig_com.nb_col_cde%TYPE:=0;
    v_nb_pce_cde        pc_lig_com.nb_pce_cde%TYPE:=0;
    v_pds_cde           pc_lig_com.pds_cde%TYPE:=0;
    v_qte_cde           pc_lig_com.qte_cde%TYPE:=0;
                        
    v_nb_col_val        pc_lig_com.nb_col_val%TYPE:=0;
    v_nb_pce_val        pc_lig_com.nb_pce_val%TYPE:=0;
    v_pds_net_val       pc_lig_com.pds_net_val%TYPE:=0;
    v_pds_brut_val      pc_lig_com.pds_brut_val%TYPE:=0;
    
    v_nb_col_ctl        pc_lig_com.nb_col_val%TYPE:=0;
    v_nb_pce_ctl        pc_lig_com.nb_pce_val%TYPE:=0;
    v_pds_net_ctl       pc_lig_com.pds_net_val%TYPE:=0;
    v_pds_brut_ctl      pc_lig_com.pds_brut_val%TYPE:=0;
    
    v_nb_col_exp        pc_lig_com.nb_col_val%TYPE:=0;
    v_nb_pce_exp        pc_lig_com.nb_pce_val%TYPE:=0;
    v_pds_net_exp       pc_lig_com.pds_net_val%TYPE:=0;
    v_pds_brut_exp      pc_lig_com.pds_brut_val%TYPE:=0;
    
    v_nb_col_ann1       ex_cmd_dpt.nb_col_ann%TYPE:=0;
    v_nb_col_ann2       ex_cmd_dpt.nb_col_ann%TYPE:=0;

    v_nb                NUMBER;

    v_etat_trait_cmd_dpt  ex_cmd_dpt.etat_trait_cmd_dpt%TYPE  := NULL;
    v_etat_trait_cmd_chgt ex_cmd_dpt.etat_trait_cmd_chgt%TYPE := NULL;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
         su_bas_put_debug(v_nom_obj||' : no_com=' || p_no_com );
    END IF;               
       
    v_etape := 'Existence ligne cde ?';
    OPEN c_etat_cde;
    FETCH c_etat_cde INTO r_etat_cde;
    IF c_etat_cde%FOUND THEN
       
        v_etape := 'Nb UEE annulees';
        OPEN c_nb_col_ann_1;
        FETCH c_nb_col_ann_1 INTO v_nb_col_ann1;
        CLOSE c_nb_col_ann_1;

        v_etape := 'Nb colis annules';
        OPEN c_nb_col_ann_2;
        FETCH c_nb_col_ann_2 INTO v_nb_col_ann2;
        CLOSE c_nb_col_ann_2;

       
        v_etape := 'Nb colis cdes et valides';
        OPEN c_stat_theo_val;
        FETCH c_stat_theo_val INTO v_qte_cde, v_nb_pce_cde, v_nb_col_cde, v_pds_cde,
                                   v_nb_pce_val, v_nb_col_val, v_pds_net_val,
                                   v_pds_brut_val;
        CLOSE c_stat_theo_val;
       
        v_etape := 'Nb colis controle';
        OPEN c_stat_ctl;
        FETCH c_stat_ctl INTO v_nb_pce_ctl,v_nb_col_ctl,v_pds_net_ctl,v_pds_brut_ctl;
        CLOSE c_stat_ctl;

        IF su_global_pkv.v_niv_dbg >= 3 THEN
             su_bas_put_debug(v_nom_obj||' : nb_uee_ann=' || TO_CHAR(v_nb_col_ann1) );
             su_bas_put_debug(v_nom_obj||' : nb_col_ann=' || TO_CHAR(v_nb_col_ann2) );
             su_bas_put_debug(v_nom_obj||' : nb_col_val=' || TO_CHAR(v_nb_col_val) );
             su_bas_put_debug(v_nom_obj||' : nb_col_ctl=' || TO_CHAR(v_nb_col_ctl) );
        END IF;               

        -- recupere donnees pc_lig_com
        v_etape := 'open c_lig';
        OPEN c_lig;
        FETCH c_lig INTO r_lig;
        IF c_lig%FOUND THEN
           
               IF su_bas_etat_val_num (r_etat_cde.etat_atv_pc_ent_com,'PC_ENT_COM') >= 
                  su_bas_etat_val_num ('SUIVI_DPT_QTE_EXP','PC_ENT_COM')  THEN
                   -- MAJ des etats pour ex
                   v_etat_trait_cmd_dpt  := 50;
                   v_etat_trait_cmd_chgt := 200;
                   v_nb_col_exp   :=v_nb_col_ctl;    
                   v_nb_pce_exp   :=v_nb_pce_ctl;  
                   v_pds_net_exp  :=v_pds_net_ctl; 
                   v_pds_brut_exp :=v_pds_brut_ctl;    
                   IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj||' : Etat 50-200');
                   END IF;               

               ELSIF su_bas_etat_val_num (r_etat_cde.etat_atv_pc_ent_com,'PC_ENT_COM') >=
                     su_bas_etat_val_num ('SUIVI_DPT_ETAT_COM','PC_ENT_COM') THEN
                   -- MAJ des etats pour ex
                   v_etat_trait_cmd_dpt  := 50;
                   v_etat_trait_cmd_chgt := NULL;
                   v_nb_col_exp   :=0;    
                   v_nb_pce_exp   :=0;  
                   v_pds_net_exp  :=0; 
                   v_pds_brut_exp :=0;    
                   IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj||' : Etat 50-NULL');
                   END IF;               

               ELSE
                   -- MAJ des etats pour ex
                   v_etat_trait_cmd_dpt  := NULL;
                   v_etat_trait_cmd_chgt := NULL;
                   v_nb_col_exp   :=0;    
                   v_nb_pce_exp   :=0;  
                   v_pds_net_exp  :=0; 
                   v_pds_brut_exp :=0;    
                   IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj||' : Etat NULL-NULL');
                   END IF;               

               END IF;

               OPEN c_ex_cmd_dpt(p_no_com,r_lig.cod_soc,r_lig.no_cde,
                                 r_lig.cod_usn,v_typ_tiers);
               FETCH c_ex_cmd_dpt INTO v_nb;
               IF c_ex_cmd_dpt%FOUND THEN
                  
                   IF su_global_pkv.v_niv_dbg >= 3 THEN
                        su_bas_put_debug(v_nom_obj||' : no_com=' || p_no_com );
                   END IF;               

                   v_etape:='update ex_cmd_dpt';
                   UPDATE ex_cmd_dpt SET
                        col_cde     =v_nb_col_cde,
                        pds_cde     =v_pds_cde,
                        pie_cde     =v_nb_pce_cde,
                        col_val     =CEIL(v_nb_col_val),                
                        pds_val     =v_pds_net_val,
                        pds_brut_val=v_pds_brut_val,
                        pie_val     =v_nb_pce_val,
                        col_ctl     =CEIL(v_nb_col_ctl),                
                        pds_ctl     =v_pds_net_ctl,
                        pds_brut_ctl=v_pds_brut_ctl,
                        pie_ctl     =v_nb_pce_ctl,
                        col_exp     =CEIL(v_nb_col_exp),                
                        pds_exp     =v_pds_net_exp,
                        pds_brut_exp=v_pds_brut_exp,
                        pie_exp     =v_nb_pce_exp,
                        nb_col_ann  =CEIL(NVL(v_nb_col_ann1,0)+NVL(v_nb_col_ann2,0)),
                        etat_trait_cmd_dpt  = NVL(v_etat_trait_cmd_dpt, etat_trait_cmd_dpt),
                        etat_trait_cmd_chgt = NVL(v_etat_trait_cmd_chgt, etat_trait_cmd_chgt) 
                     WHERE typ_dpt='2'
                        AND cle1=p_no_com 
                        AND cle2=r_lig.cod_soc 
                        AND cle3=r_lig.no_cde
                        AND cod_usn=r_lig.cod_usn
                        AND typ_tiers=v_typ_tiers;
                        
               ELSE
                   -- creation enregistrement avec la premiere ligne
                   v_etape:='creation ex_cmd_dpt';
                   IF su_global_pkv.v_niv_dbg >= 6 THEN
                       su_bas_put_debug(v_nom_obj ||' '||v_etape);
                   END IF;
                  
                   v_ret:=su_bas_ins_ex_cmd_dpt(p_typ_dpt  =>'2',
                                                p_cle1     =>p_no_com,
                                                p_cle2     =>r_lig.cod_soc,
                                                p_cle3     =>r_lig.no_cde,
                                                p_cod_usn  =>r_lig.cod_usn, 
                                                p_typ_tiers=>v_typ_tiers,
                                                p_ref_cde_tiers=>r_lig.ref_cde_cli,
                                                p_pds_brut_val =>v_pds_brut_val,
                                                p_pds_brut_exp =>v_pds_brut_exp,
                                                p_pds_brut_ctl =>v_pds_brut_ctl,
                                                p_pds_cde=>v_pds_cde,
                                                p_pds_exp=>v_pds_net_exp,
                                                p_pds_val=>v_pds_net_val,
                                                p_pds_ctl=>v_pds_net_ctl,
                                                p_pie_cde=>v_nb_pce_cde,
                                                p_pie_exp=>v_nb_pce_exp,
                                                p_pie_val=>v_nb_pce_val,
                                                p_pie_ctl=>v_nb_pce_ctl,
                                                p_col_cde=>v_nb_col_cde,
                                                p_col_exp=>CEIL(v_nb_col_exp),
                                                p_col_val=>CEIL(v_nb_col_val),
                                                p_col_ctl=>CEIL(v_nb_col_ctl),
                                                p_nb_col_ann=>CEIL(NVL(v_nb_col_ann1,0)+NVL(v_nb_col_ann2,0)),
                                                p_etat_trait_cmd_dpt =>19,
                                                p_etat_trait_cmd_chgt=>0);

               END IF;
               CLOSE c_ex_cmd_dpt;
           
        END IF;
        CLOSE c_lig;
            
    ELSE

        v_etape := 'epuration ex_cmd_dpt';
        OPEN c_epur;
        FETCH c_epur INTO r_epur;
        IF c_epur%FOUND THEN
            v_etape:='suppression cde dans ex_cmd_dpt';
            DELETE ex_cmd_dpt
            WHERE typ_dpt='2' AND typ_tiers=v_typ_tiers AND cle1=p_no_com AND dat_maj < r_epur.dat_max;  
        END IF;
        CLOSE c_epur;
               
    END IF;
    CLOSE c_etat_cde;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'no_com',
                        p_par_ano_1       => p_no_com,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
END;
/
show errors;





