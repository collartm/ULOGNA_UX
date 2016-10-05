CREATE OR REPLACE FORCE VIEW V_SP_STAT_THEO AS
   SELECT s.*,
          p.nb_col_pal,
          NVL (t.debit, 901) debit_theo,
          s.dat_tir_rp_ent_sqc + (6/86400) dat_dispo_ent_sqc 
     FROM sp_stat s,
          sp_deb_theo t,
          (  SELECT cod_ut_sup, COUNT (*) nb_col_pal
               FROM sp_stat
           GROUP BY cod_ut_sup) p
    WHERE s.cod_ut_sup = p.cod_ut_sup AND t.nb_mvt_pal (+) = p.nb_col_pal;

CREATE OR REPLACE FORCE VIEW V_SP_STAT_UT_SUP AS
     SELECT v.*,
            NVL(t.debit,901) debit
       FROM (SELECT cod_ut_sup,
                    MIN (dat_ordo) dat_ordo,
                    MIN (dat_ent_sqc) dat_prem_ent_sqc,
                    MAX (dat_ent_sqc) dat_der_ent_sqc,
                    MIN (dat_sor_sqc) dat_prem_sor_sqc,
                    MAX (dat_sor_sqc) dat_der_sor_sqc,
                    MIN (no_sqc) no_sqc,
                    COUNT (*) nb_col,
                    MIN (no_sqm) no_sqm,
                    SUM (DECODE (SUBSTR (no_uee, 1, 1), 'I', 0, 1)) nb_colis,
                    SUM (DECODE (SUBSTR (no_uee, 1, 1), 'I', 1, 0)) nb_inter
               FROM sp_stat
              WHERE dat_ent_sqc IS NOT NULL
           GROUP BY cod_ut_sup) v,
            sp_deb_theo t
      WHERE t.nb_mvt_pal (+) = v.nb_col;
   
CREATE OR REPLACE FORCE VIEW V_SP_STAT_COL_SQC AS
   SELECT s.*,
          v.dat_der_ent_sqc
     FROM sp_stat s, v_sp_stat_ut_sup v
    WHERE v.cod_ut_sup = s.cod_ut_sup AND s.dat_ent_sqc IS NOT NULL;
/
show errors;