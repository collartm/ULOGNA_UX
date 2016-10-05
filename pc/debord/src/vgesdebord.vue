-- $Id$
-- DESCRIPTION :
-- -------------
-- Ces vues sont utilisées dans l'écran de gestion de la préparation en mode débord
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
--
-- 01a,25.09.2014,tjaf   version initiale
-- -------------------------------------------------------------------------

-- affichage des données produits par commande ligne commande et mode implantation
CREATE OR REPLACE VIEW V_SP_DEB_COM_PRO_MAP AS
SELECT ec.cod_usn,
       ec.cod_soc,
       lc.no_com,
       lc.no_lig_com,
       lc.no_cmd,
       lc.no_lig_cmd,
       lc.cod_pro,
       p.lib_pro,
       lc.qte_cde,
       lc.unite_cde,
       ec.dat_prep,
       ec.dat_exp,
       DECODE (p.libre_su_pro_13,
               '20', DECODE ( (SELECT 1
                                 FROM se_afc_emp
                                WHERE cod_pro = lc.cod_pro
                                  AND ROWNUM = 1),
                             1, '1',
                             '0'),
               '0')
           etat_map,
       ec.etat_atv_pc_ent_com,
       lc.etat_atv_pc_lig_com,
       lc.cod_vl,
       DECODE (lc.libre_pc_lig_com_12,
               '1', 'DEB',
               '2', 'DEB',
               'MEC')
           mod_ges,
       lc.libre_pc_lig_com_12 mod_deb,
       lc.libre_pc_lig_com_13 lect_lig,
       lc.cod_pss_afc,
       ec.cod_cli,
       lc.cle_rgp_pal_1
  FROM pc_ent_com ec, pc_lig_com lc, su_pro p
 WHERE ec.cod_usn = su_global_pkg.su_bas_get_cod_usn
   AND ec.no_com = lc.no_com
   AND lc.cod_pss_afc != 'SDB01'
   AND lc.typ_lig_com = 'S'
   AND lc.cod_pro = p.cod_pro
   AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com,'PC_LIG_COM') <
                         su_bas_etat_val_num ('ORDT', 'PC_LIG_COM') -- ne retourne que des lignes avant ordo
   AND (nvl(su_bas_rch_action('FRM_SP_GES_DEBORD', 'INCL_PORD'),'0') = '1' 
        OR su_bas_etat_val_num (lc.etat_atv_pc_lig_com,'PC_LIG_COM') <
                            su_bas_etat_val_num ('PORD', 'PC_LIG_COM')) -- ne retourne que des lignes avant pré-ordo
   AND NOT EXISTS ( SELECT 1 FROM pc_uee uee, pc_uee_det det
                    WHERE  su_bas_etat_val_num (etat_atv_pc_uee,'PC_UEE') >=
                                su_bas_etat_val_num ('ORDF', 'PC_UEE')
                    AND    lc.no_lig_com = det.no_lig_com
                    AND    lc.no_com = det.no_com
                    AND    det.no_uee = uee.no_uee) -- ne retourne pas de ligne avec colis préparé 
   AND (lc.lst_fct_lock IS NULL 
        OR lc.lst_fct_lock = ';DEB;');

-- affichage des produits a préparer en debord
CREATE OR REPLACE VIEW V_SP_PRO_DEB AS  
  SELECT p.cod_pro,
         p.lib_pro,
         SUM (qte_cde) qte,
         DECODE (p.libre_su_pro_13,
                 '20', DECODE (NVL (a.no_afc_emp, 0), 0, '0', '1'),
                 '0')
             etat_map
    FROM su_pro p, pc_ent_com ec, pc_lig_com lc, se_afc_emp a
   WHERE lc.cod_usn = su_global_pkg.su_bas_get_cod_usn
     AND p.cod_pro = lc.cod_pro
     AND ec.no_com = lc.no_com
     AND p.cod_pro = a.cod_pro(+)
     AND (a.cod_vl IS NULL OR a.cod_vl = '10')
     AND (a.cod_mag IS NULL OR a.cod_mag = 'SPD')
     AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com,'PC_LIG_COM') <
                         su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
     AND lc.libre_pc_lig_com_12 IN ('1','2')
     AND lc.cod_pss_afc != 'SDB01'
GROUP BY p.cod_pro,
         p.lib_pro,
         DECODE (p.libre_su_pro_13,
                 '20', DECODE (NVL (a.no_afc_emp, 0), 0, '0', '1'),
                 '0')
ORDER BY 3 DESC;

-- affichage des données consolidées permettant la gestion du mode debord
CREATE OR REPLACE VIEW V_SP_DEB_TOT_PREP AS
SELECT  tot_ref_deb,
        nb_pal_deb,
        nb_pal_rep,
        nb_pro_deb,
        nb_pro_a_map,
        nb_pro_a_demap,
        nb_pal_impact,
        NB_PRO_A_REASS
  FROM TABLE( sp_pc_ges_debord_pkg.sp_pc_compteurs_deb());

-- affichage des produits implantés en débord
CREATE OR REPLACE VIEW V_SP_PRO_MAP AS  
  SELECT p.cod_pro,
         p.lib_pro,
         a.cod_vl,
         a.cod_mag
    FROM su_pro p, se_afc_emp a
   WHERE p.cod_pro = a.cod_pro
     AND (a.cod_vl IS NULL OR a.cod_vl = '10')
     AND a.cod_mag = 'SPD'
     AND a.typ_afc_emp = '00'
ORDER BY 1;

-- affichage des emplacements en débord
CREATE OR REPLACE VIEW V_SP_EMP_DEB AS  
  SELECT a.cod_pro,
         a.cod_vl,
         e.cod_emp,
         e.cod_mag,
         e.cod_meuble,
         e.cod_allee,
         e.cod_colonne,
         e.cod_niveau,
         e.lib_emp,
         e.cb_emp,
         SUM (s.qte_colis) qte
    FROM su_pro p, se_afc_emp a, se_stk s, se_emp e
   WHERE p.libre_su_pro_13 = '20'
     AND p.cod_pro = a.cod_pro
     AND a.cod_mag = 'SPD'
     AND a.typ_afc_emp = '00'
     AND (s.cod_mag IS NULL OR s.cod_mag = a.cod_mag)
     AND s.cod_pro(+) = p.cod_pro
     AND e.cod_emp(+) = s.cod_emp
GROUP BY e.cod_emp,
         e.cod_mag,
         e.cod_meuble,
         e.cod_allee,
         e.cod_colonne,
         e.cod_niveau,
         e.lib_emp,
         e.cb_emp,
         a.cod_pro,
         a.cod_vl;
/
show errors;

