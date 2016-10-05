/* 
****************************************************************************
* sp_bas_stat_reg_sqc -  
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction gère une vue table pour statistique sur regulation/préparation palette
--
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,04.06.15,rbel    Création
-- 00a,20.01.11,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--   vue tt_exp
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE FUNCTION sp_bas_stat_reg_sqc (p_date  IN DATE DEFAULT NULL)  
    RETURN sp_stat_reg_sqc_pkv.tt_stat_reg_sqc  PIPELINED
IS
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_stat_reg_sqc';
    
    rec                 sp_stat_reg_sqc_pkv.tr_stat_reg_sqc;
    
    CURSOR c_int IS
        SELECT 'I'||u.no_uee no_uee,
                   u.no_com,
                   u.cod_ut_sup,
                   u.typ_ut_sup,
                   u.no_rmp no_sqc,
                   u.dat_lvzp dat_tir_robot                   
              FROM v_pc_uee_arc u
             WHERE etat_atv_pc_uee IN ('CPAL','TEXP')
                   AND u.cod_pss_afc = 'SCC01'
                   AND u.intercalaire IS NOT NULL
                   AND SUBSTR(SUBSTR(u.lst_chkpt_suivi, INSTR(u.lst_chkpt_suivi,'LVZP')),24,13) = 'DISIN_SIEMENS'
                   AND (p_date IS NULL OR TRUNC(u.dat_lvzp)=TRUNC(p_date));
                   
    CURSOR c_uee IS
        SELECT u.no_uee,
               (SELECT MAX(p.cod_ops)
                      FROM v_pc_pic_uee_arc pu, v_pc_pic_arc p
                     WHERE pu.no_uee = u.no_uee
                       AND p.cod_pic = pu.cod_pic
                       AND pu.etat_actif = '1'
                       AND p.etat_atv_pc_pic IN ('TERM','LIVR')) cod_ops,
               u.no_com,
               u.cod_ut_sup,
               u.typ_ut_sup,
               u.no_uee_ut_p1,
               u.dat_ordo,
               u.dat_reg_av dat_reg_ent_sqc,
               u.no_rmp no_sqc,
               u.dat_pic_val dat_sortie_flexy,
               u.dat_ent_bff dat_ent_sqc,
               u.dat_reg_ap dat_reg_sor_sqc,
               u.dat_sor_bff dat_sor_sqc,
               u.dat_lvzp dat_tir_robot,
               u.lst_chkpt_suivi
          FROM v_pc_uee_arc u
         WHERE etat_atv_pc_uee IN ('CPAL','TEXP')
           AND u.cod_pss_afc = 'SCC01'
           AND (p_date IS NULL OR TRUNC(u.dat_lvzp)=TRUNC(p_date));
               
    CURSOR c_ut (x_cod_ut pc_ut.cod_ut%TYPE,
                 x_typ_ut pc_ut.typ_ut%TYPE) IS
        SELECT dat_der_liv
          FROM v_pc_ut_arc
         WHERE cod_ut=x_cod_ut
           AND typ_ut=x_typ_ut;
           
    CURSOR c_com (x_no_com pc_ent_com.no_com%TYPe) IS
        SELECT dat_exp, dat_crea
          FROM v_pc_ent_com_arc
         WHERE no_com=x_no_com;
         
    CURSOR c_trf (x_ref_trf_1 se_ord_trf.ref_trf_1%TYPE) IS 
        SELECT o.ref_trf_1,
               o.ref_trf_2,
               o.cod_emp_orig cod_emp_flexy,
               l.cod_zone flexy,
               o.cod_emp_dest cod_emp_sqc,
               su_bas_gcl_se_emp (o.cod_emp_dest, 'COD_ALLEE') ascenseur_sqc,
               LTRIM (o.ref_trf_2, '0') no_sqm,
               LTRIM (o.ref_trf_3, '0') no_ord_sqm,
               o.dat_crea dat_crea_ord_sortie_flexy,
               1 nb_ut_utilise,
               o.cod_ut_orig, o.typ_ut_orig,
               o.dat_maj
            FROM se_ord_trf_arc o, se_lig_zone l
           WHERE o.ref_trf_1 = x_ref_trf_1
             AND o.typ_trf = 'PC_PIC'
             AND o.cod_mag_orig = 'SKC'
             AND l.cod_emp = o.cod_emp_orig
             AND l.typ_zone = 'MT'
             AND etat_ord_trf = 'TERM'
        ORDER BY o.dat_maj DESC; 
        
    r_trf       c_trf%ROWTYPE;
    
    CURSOR c_trf_ent_sqc (x_ref_trf_1 se_ord_trf.ref_trf_1%TYPE) IS 
        SELECT o.dat_crea
            FROM se_ord_trf_arc o
           WHERE o.ref_trf_1 = x_ref_trf_1
             AND o.typ_trf = 'PC_PIC'
             AND o.cod_mag_orig = 'SKSE'
             AND o.etat_ord_trf = 'TERM'
        ORDER BY o.dat_maj DESC;
        
    CURSOR c_pt_ctrl(x_cod_ut pc_ut.cod_ut%TYPE,
                     x_typ_ut pc_ut.typ_ut%TYPE,
                     x_ref_trf_1 se_ord_trf.ref_trf_1%TYPE) IS
        SELECT NVL(dat_autor_env_ut, dat_maj) dat_pt_ctrl
          FROM se_ord_trf_arc o
         WHERE o.ref_trf_1 = x_ref_trf_1
           AND o.typ_trf = 'PC_PIC'
           AND o.cod_mag_orig = 'SKCS'
           AND o.etat_ord_trf = 'TERM'
           AND cod_ut_orig = x_cod_ut AND typ_ut_orig = x_typ_ut           
         ORDER BY dat_crea DESC;
          
BEGIN    
    -- Pipe des intercalaires
    FOR r_int IN c_int LOOP
        rec := null;
        
        rec.no_uee := r_int.no_uee;
        rec.no_com := r_int.no_com;
        rec.cod_ut_sup := r_int.cod_ut_sup;
        rec.no_sqc := r_int.no_sqc;        
        rec.dat_tir_robot := r_int.dat_tir_robot;
        
        OPEN c_ut(r_int.cod_ut_sup, r_int.typ_ut_sup);
        FETCH c_ut INTO rec.dat_der_tir_robot;
        CLOSE c_ut;
        
        OPEN c_com(r_int.no_com);
        FETCH c_com INTO rec.dat_exp, rec.dat_crea_com;
        CLOSE c_com;
               
        pipe ROW(rec);
    END LOOP;
    
    -- Pipe des colis
    FOR r_uee IN c_uee LOOP
        rec := null;
        
        rec.no_uee := r_uee.no_uee;
        rec.no_com := r_uee.no_com;
        rec.cod_ut_sup := r_uee.cod_ut_sup;
        rec.no_sqc := r_uee.no_sqc;        
        
        IF SUBSTR(SUBSTR(r_uee.lst_chkpt_suivi, INSTR(r_uee.lst_chkpt_suivi,'LVZP')),24,13) = 'DISIN_SIEMENS' THEN
            rec.dat_tir_robot := r_uee.dat_tir_robot;
        END IF;
        
        OPEN c_ut(r_uee.cod_ut_sup, r_uee.typ_ut_sup);
        FETCH c_ut INTO rec.dat_der_tir_robot;
        CLOSE c_ut;
        
        OPEN c_com(r_uee.no_com);
        FETCH c_com INTO rec.dat_exp, rec.dat_crea_com;
        CLOSE c_com;
        
        rec.cod_ops := r_uee.cod_ops;
        rec.no_uee_ut_p1 := r_uee.no_uee_ut_p1;
        rec.dat_ordo := r_uee.dat_ordo;                
        rec.dat_reg_ent_sqc := r_uee.dat_reg_ent_sqc;
        rec.dat_sortie_flexy := r_uee.dat_sortie_flexy;
        rec.dat_ent_sqc := r_uee.dat_ent_sqc;        
        rec.dat_reg_sor_sqc := r_uee.dat_reg_sor_sqc;
        rec.dat_sor_sqc := r_uee.dat_sor_sqc;
        
        OPEN c_trf(r_uee.cod_ops);
        FETCH c_trf INTO r_trf;
        IF c_trf%FOUND THEN
            rec.ref_trf_1 := r_trf.ref_trf_1;
            rec.cod_emp_flexy := r_trf.cod_emp_flexy;
            rec.flexy := r_trf.flexy;
            rec.cod_emp_sqc := r_trf.cod_emp_sqc;
            rec.ascenseur_sqc := r_trf.ascenseur_sqc;
            rec.no_sqm := r_trf.no_sqm;
            rec.no_ord_sqm := r_trf.no_ord_sqm;
            rec.dat_crea_ord_sortie_flexy := r_trf.dat_crea_ord_sortie_flexy;
            rec.nb_ut_utilise := r_trf.nb_ut_utilise;
        END IF;
        CLOSE c_trf;
        
        OPEN c_trf_ent_sqc(r_uee.cod_ops);
        FETCH c_trf_ent_sqc INTO rec.dat_tir_rp_ent_sqc;
        CLOSE c_trf_ent_sqc;
        
        OPEN c_pt_ctrl(r_trf.cod_ut_orig, r_trf.typ_ut_orig, r_uee.cod_ops);
        FETCH c_pt_ctrl INTO rec.dat_exp;       --  !!! utilisation de cette date inutile pour stocker le point de contrôle sortie collecteur !!!!
        CLOSE c_pt_ctrl;
               
        pipe ROW(rec);
    END LOOP;       
       
EXCEPTION
    WHEN NO_DATA_NEEDED THEN -- ORA 6548
        null;
END;
/
show errors;

