-- $Id$
-- DESCRIPTION :
-- -------------
-- vue utilisee par le terminal radio en process ramasse par le curseur C_LST_ORD_PIC.
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur Description
-- -------------------------------------------------------------------------
-- 02a,12.11.14,tjaf   version spec sans code pro
-- 01a,30.03.12,alfl   version initiale
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW V_C_LST_ORD_PIC AS
        SELECT v.etat || ' ' ||
               LPAD(NVL(REPLACE(su_bas_gcl_se_emp(v.cod_emp,'LIB_EMP'),' ',''), 'REA '||v.cod_pro),13,' ') || ':' ||
               --LPAD(v.cod_pro,6,' ') || ':' ||
               LTRIM(TO_CHAR(v.nb_col_theo - v.nb_col_val,'009'))
         --|| '/' ||LTRIM(TO_CHAR(v.nb_col_theo, '09')) 
               c_text,
               v.cod_emp c_index ,v.no_bor_pic
          FROM v_det_bor_ramasse v   
      ORDER BY pc_bas_order_lig_bor_rm(NULL,v.cod_emp,NULL,NULL,NULL,v.pds_tot,NULL,v.etat,v.etat_couche_complete)   
/

