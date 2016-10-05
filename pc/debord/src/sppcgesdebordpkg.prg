/* $Id$ */
CREATE OR REPLACE 
    PACKAGE BODY sp_pc_ges_debord_pkg AS

/* 
****************************************************************************
* sp_pc_ges_deb_to_tab - 
*/
-- DESCRIPTION :
-- -------------
-- Package de  gestion du mode d�bord
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
-- 01a,29.09.14,TJAF    Cr�ation
-- 00a,20.05.13,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--   ROWTYPE?
--
-- COMMIT :
-- --------
--   NON

-- DESCRIPTION :
-- -------------
-- Cette fonction permet l'affichage de la courbe des preparations
-- 2 cas a prendre en compte dans le calcul, commandes avant pr�ordo (pas de palette) et apres avec palettes
    FUNCTION sp_pc_gph_deb_to_tab (p_cod_usn    su_usn.cod_usn%TYPE,
                                   p_dat_deb    DATE, 
                                   p_dat_fin    DATE)
         RETURN tt_sp_pc_gph_deb  PIPELINED
    IS
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_gph_prep_deb_to_tab';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
        
        v_ret               VARCHAR2(100);
        v_duree_prep        NUMBER  := 0;
        v_duree_cumul       NUMBER  := 0;
        v_colis_cumul       NUMBER  := 0;
        v_cpt               NUMBER  := 0;
        v_nb_pal            NUMBER  := 0;
        v_nb_col_pal        NUMBER  := 0;
        v_rst_col           NUMBER  := 0;
        v_no_pal            NUMBER  := 1;
        v_tag_dat_maq_min   CHAR    := '0';
        v_dat_maq_min       DATE;
    
        -- duree en heures ramen�es en secondes
        v_duree_indispo     NUMBER  := (NVL(su_bas_rch_action('FRM_SP_GES_DEBORD','DUR_INDISP','SU', 1),0)
                                       + NVL(su_bas_rch_action('FRM_SP_GES_DEBORD','DUR_INDISP','SU', 2),0))*(60*60);
        -- taux de performance de l'installation
        v_perf_debit        NUMBER  := NVL(su_bas_rch_action('FRM_SP_GES_DEBORD','PERF_DEBIT','SU', 1),100)/100;
    
        r_pc_deb            tr_sp_pc_gph_deb;
        
        CURSOR  c_prep (x_dat_fin DATE) IS
        SELECT ec.dat_exp+DECODE( TO_CHAR(ec.dat_exp,'HH24MI'),'0000',1,0) dat_exp,
                NULL cod_ut,
                NULL typ_ut,
                ec.no_com,
                SUM (lc.qte_cde) nb_col,
                0 nb_intercalaires, 
                ec.cod_usn
        FROM    pc_ent_com ec, pc_lig_com lc
        WHERE   lc.cod_pss_afc != 'SDB01'
        AND     lc.typ_lig_com = 'S'
        AND     lc.no_com  = ec.no_com
        AND     ec.cod_usn = p_cod_usn
        AND     su_bas_etat_val_num (ec.etat_atv_pc_ent_com, 'PC_ENT_COM') <
                    su_bas_etat_val_num ('PRPP', 'PC_ENT_COM')
        AND     su_bas_etat_val_num (lc.etat_atv_pc_lig_com, 'PC_LIG_COM') <
                    su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
        AND     ec.dat_exp < x_dat_fin
        /*AND     EXISTS
                     (SELECT 1
                      FROM   pc_lig_com lc2
                      WHERE  lc2.no_com = ec.no_com
                      AND    su_bas_etat_val_num (lc2.etat_atv_pc_lig_com, 'PC_LIG_COM') < su_bas_etat_val_num ('ORDT', 'PC_LIG_COM'))*/
        AND (lc.libre_pc_lig_com_12 IS NULL OR lc.libre_pc_lig_com_12 IN ('0','3'))
        GROUP BY ec.dat_exp+DECODE( TO_CHAR(ec.dat_exp,'HH24MI'),'0000',1,0), ec.no_com, ec.cod_usn
        UNION ALL
        SELECT  ec.dat_exp+DECODE( TO_CHAR(ec.dat_exp,'HH24MI'),'0000',1,0) dat_exp,
                ut.cod_ut,
                ut.typ_ut,
                ec.no_com,
                COUNT (*) nb_col,
                SUM (DECODE (NVL (uee.intercalaire, '#NULL#'), '#NULL#', 0, 1))
                    nb_intercalaires, 
                ec.cod_usn
        FROM    pc_ut ut, pc_uee uee,
                pc_ent_com ec, pc_lig_com lc,
                pc_uee_det det
        WHERE   lc.cod_pss_afc != 'SDB01'
        AND     lc.typ_lig_com = 'S'
        AND     lc.no_com  = ec.no_com
        AND     ec.no_com = ut.no_com
        AND     ec.cod_usn = p_cod_usn
        AND     su_bas_etat_val_num (ec.etat_atv_pc_ent_com, 'PC_ENT_COM') <
                    su_bas_etat_val_num ('PRPP', 'PC_ENT_COM')
        AND     uee.cod_ut_sup = ut.cod_ut
        AND     uee.typ_ut_sup = ut.typ_ut
        AND     uee.no_uee = det.no_uee
        AND     det.no_com = lc.no_com
        AND     det.no_lig_com = lc.no_lig_com
        AND     ut.dat_exp_ini < x_dat_fin
        AND     EXISTS
                     (SELECT 1
                      FROM   pc_lig_com lc2
                      WHERE  lc2.no_com = ec.no_com
                      AND    su_bas_etat_val_num (lc2.etat_atv_pc_lig_com, 'PC_LIG_COM') >= su_bas_etat_val_num ('PORD', 'PC_LIG_COM')
                      AND    su_bas_etat_val_num (lc2.etat_atv_pc_lig_com, 'PC_LIG_COM') < su_bas_etat_val_num ('ORDT', 'PC_LIG_COM'))
        AND (lc.libre_pc_lig_com_12 IS NULL OR lc.libre_pc_lig_com_12 IN ('0','3'))
        GROUP BY ec.dat_exp+DECODE( TO_CHAR(ec.dat_exp,'HH24MI'),'0000',1,0), ec.no_com, ut.cod_ut, ut.typ_ut, ec.cod_usn
        ORDER BY dat_exp;
           
        r_prep c_prep%ROWTYPE;
    
        FUNCTION local_duree_prep (p_nb_col NUMBER ) 
            RETURN NUMBER 
        IS
            v_duree NUMBER := 0;
        BEGIN
            -- on prend le d�bit de l'installation (colis/h) correspondant au nb colis de la palette en cours
            -- afin de retrouver le temps de pr�pa d'une palette de n colis que l'on divise par 2 car ce d�bit 
            -- est global a l'installation (2 pool) que l'on multipli par le taux de perf de l'install par rapport
            -- au debit nominal vendu
            v_duree := round(p_nb_col*(60*60) / 
                                (su_bas_to_number(
                                    su_bas_rch_action (
                                        p_nom_par   => 'SP_DUREE_PREP',
                                        p_par       => p_nb_col))*2)) / v_perf_debit;
            RETURN v_duree;
        END;
        
    BEGIN
        v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' - p_cod_usn : '||p_cod_usn
                                      ||' - p_dat_deb : '||to_char(p_dat_deb,'YYYYMMDD HH24:MI')
                                      ||' - p_dat_fin : '||to_char(p_dat_fin,'YYYYMMDD HH24:MI'));
        END IF;
    
        v_etape := 'Init de la dur�e d''indispo';
        v_duree_cumul := v_duree_indispo;
    
        v_etape := 'Calcul des enregistrements';
    
        OPEN c_prep(p_dat_fin);
        LOOP
            FETCH c_prep INTO r_prep;
            EXIT WHEN c_prep%NOTFOUND;
    
            v_etape := 'Initialisation de la date min maq moins 1 sec';
            IF v_tag_dat_maq_min = '0' THEN
                v_dat_maq_min     := r_prep.dat_exp-1/(24*60*60);
                v_tag_dat_maq_min := '1';
            END IF;
    
            v_etape := 'Traitement du cumul temps';    
            IF  r_prep.cod_ut IS NULL THEN
                v_etape := 'Traitement des commandes avant pr�-ordo';
                v_nb_col_pal := su_bas_rch_par_usn( p_cod_par_usn   => 'SP_NB_COL_MOY_PAL',
                                                    p_cod_usn       => p_cod_usn);
                v_nb_pal := TRUNC(r_prep.nb_col / v_nb_col_pal);
    
                v_rst_col := MOD(r_prep.nb_col, v_nb_col_pal);
    
                FOR v_cpt IN 1..v_nb_pal LOOP
                    v_duree_prep := local_duree_prep( v_nb_col_pal);
        
                    v_duree_cumul := v_duree_cumul + v_duree_prep;
                    v_colis_cumul := v_colis_cumul + v_nb_col_pal;
    
                    r_pc_deb.num_pal    := v_no_pal;
                    r_pc_deb.dat_prep   := p_dat_deb + v_duree_cumul/(24*60*60);
                    r_pc_deb.delai_prep := v_duree_cumul;
                    r_pc_deb.dat_maq    := r_prep.dat_exp;
                    r_pc_deb.delai_maq  := (r_prep.dat_exp - p_dat_deb)*(24*60*60);
                    r_pc_deb.nb_col     := v_nb_col_pal;
                    r_pc_deb.tot_col    := v_colis_cumul;
    
                    v_no_pal := v_no_pal + 1;
    
                    v_etape := 'Ajout de la ligne';
                    pipe ROW(r_pc_deb);
    
                END LOOP;
    
                IF v_rst_col > 0 THEN
                    v_duree_prep := local_duree_prep(v_rst_col);
        
                    v_duree_cumul := v_duree_cumul + v_duree_prep;
                    v_colis_cumul := v_colis_cumul + v_rst_col;
    
                    r_pc_deb.num_pal    := v_no_pal;
                    r_pc_deb.dat_prep   := p_dat_deb + v_duree_cumul/(24*60*60);
                    r_pc_deb.delai_prep := v_duree_cumul;
                    r_pc_deb.dat_maq    := r_prep.dat_exp;
                    r_pc_deb.delai_maq  := (r_prep.dat_exp - p_dat_deb)*(24*60*60);
                    r_pc_deb.nb_col     := v_rst_col;
                    r_pc_deb.tot_col    := v_colis_cumul;
    
                    v_no_pal := v_no_pal + 1;
    
                    v_etape := 'Ajout de la ligne';
                    pipe ROW(r_pc_deb);
    
                END IF;
        
            ELSE
                v_etape := 'Traitement des commandes apres pr�-ordo et avant PRP0';
                v_duree_prep := su_bas_to_number(nvl(r_prep.nb_intercalaires,0))
                                    * nvl(su_bas_to_number(su_bas_rch_action  (
                                                    p_nom_par       => 'SP_DUREE_PREP',
                                                    p_par           => 'I')),3.8) -- temps de traitement intercalaire
                                + local_duree_prep(r_prep.nb_col);
    
                v_duree_cumul := v_duree_cumul + v_duree_prep;
                v_colis_cumul := v_colis_cumul + r_prep.nb_col;
    
                r_pc_deb.num_pal    := v_no_pal;
                r_pc_deb.dat_prep   := p_dat_deb + v_duree_cumul/(24*60*60);
                r_pc_deb.delai_prep := v_duree_cumul;
                r_pc_deb.dat_maq    := r_prep.dat_exp;
                r_pc_deb.delai_maq  := (r_prep.dat_exp - p_dat_deb)*(24*60*60);
                r_pc_deb.nb_col     := r_prep.nb_col;
                r_pc_deb.tot_col    := v_colis_cumul;
        
                v_no_pal := v_no_pal + 1;
    
                v_etape := 'Ajout de la ligne';
                pipe ROW(r_pc_deb);
            END IF;        
    
            v_etape := 'Trace';
            IF su_global_pkv.v_niv_dbg >= 9 THEN
                su_bas_put_debug(v_nom_obj||' Pal : '||r_pc_deb.num_pal||
                                            ' - date prep : '||to_char(r_pc_deb.dat_prep, 'YYYYMMDD HH24:MI')||
                                            ' - delai prep : '||r_pc_deb.delai_prep||
                                            ' - date maq : '||to_char(r_pc_deb.dat_maq, 'YYYYMMDD HH24:MI')||
                                            ' - delai maq : '||r_pc_deb.delai_maq||
                                            ' - nb col : '||r_pc_deb.nb_col||
                                            ' - tot col : '||r_pc_deb.tot_col);
            END IF;
    
        END LOOP;
        CLOSE c_prep;
    
        v_etape := 'Ajout dernier point';
        IF r_pc_deb.dat_prep < r_pc_deb.dat_maq THEN
            r_pc_deb.num_pal    := v_no_pal;
            r_pc_deb.dat_prep   := r_prep.dat_exp;
            r_pc_deb.delai_prep := NULL;
            r_pc_deb.dat_maq    := NULL;
            r_pc_deb.delai_maq  := NULL;
            r_pc_deb.nb_col     := 0;
            r_pc_deb.tot_col    := v_colis_cumul;
            v_etape := 'Ajout de la ligne';
            pipe ROW(r_pc_deb);
     /*   ELSE
            r_pc_deb.num_pal    := v_no_pal;
            r_pc_deb.dat_prep   := r_prep.dat_exp;
            r_pc_deb.delai_prep := NULL;
            r_pc_deb.dat_maq    := r_prep.dat_exp;
            r_pc_deb.delai_maq  := NULL;
            r_pc_deb.nb_col     := 0;
            r_pc_deb.tot_col    := v_colis_cumul;
            v_etape := 'Ajout de la ligne';
            pipe ROW(r_pc_deb);
            */
        END IF;
    
        v_etape := 'Ajout premier point';
        r_pc_deb.num_pal    := 0;
        r_pc_deb.dat_prep   := p_dat_deb + v_duree_indispo/(24*60*60);
        r_pc_deb.delai_prep := 0;
        r_pc_deb.dat_maq    := v_dat_maq_min; 
        r_pc_deb.delai_maq  := 0;
        r_pc_deb.nb_col     := 0;
        r_pc_deb.tot_col    := 0;
        v_etape := 'Ajout de la ligne';
        pipe ROW(r_pc_deb);
    
    EXCEPTION
        WHEN NO_DATA_NEEDED THEN 
            NULL;
    END;

-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02a,22.09.16,MCO2    Correction sur le calcul de date de fin prep
-- 01a,29.09.14,TJAF    Cr�ation
-- -------------------------------------------------------------------------
    -- DESCRIPTION :
    -- -------------
    -- Cette fonction permet le calcul de la date max de pr�pa
    FUNCTION sp_pc_dat_max_prep_deb (p_cod_usn  su_usn.cod_usn%TYPE,
                                     p_dat_deb  DATE, 
                                     p_dat_fin  DATE)
         RETURN DATE
    IS  
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_dat_max_prep_deb';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
    
/* --mis en commentaire le 22.09.2016 mco2 02a
        CURSOR c_max_d_prep IS
        SELECT MAX (dat_prep) 
        FROM TABLE(sp_pc_gph_deb_to_tab (p_cod_usn, p_dat_deb, p_dat_fin));
*/

        --$mod mco2 02a 22.09.2016
        CURSOR c_max_d_prep IS
            SELECT MAX(dat_prep) FROM
            (
              SELECT LAG(dat_prep,1) OVER(ORDER BY dat_prep) dat_prep
                  FROM TABLE(sp_pc_gph_deb_to_tab (p_cod_usn, p_dat_deb, p_dat_fin))
            );
    
        v_dat_max           DATE;
    BEGIN
        OPEN c_max_d_prep;
        FETCH c_max_d_prep INTO v_dat_max;
        CLOSE c_max_d_prep;
    
        RETURN v_dat_max;
    
    EXCEPTION
        WHEN OTHERS THEN 
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_lib_ano_1       => 'p_cod_usn ', 
                             p_par_ano_1       => p_cod_usn, 
                             p_lib_ano_2       => 'p_dat_deb ', 
                             p_par_ano_2       => p_dat_deb, 
                             p_lib_ano_3       => 'p_dat_fin ', 
                             p_par_ano_3       => p_dat_fin,  
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
    
    END;
    
    -- DESCRIPTION :
    -- -------------
    -- Fonction de calcul de la date de d�passement de capacit� et du volume concern�
    FUNCTION sp_pc_dat_qte_dep_deb (p_cod_usn           su_usn.cod_usn%TYPE,
                                    p_dat_deb           DATE, 
                                    p_dat_fin           DATE,
                                    p_dat_dep       OUT DATE,
                                    p_nb_col_dep    OUT NUMBER)
         RETURN VARCHAR2
    IS    
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_gph_prep_deb_to_tab';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
    
        v_ret               VARCHAR2(100) := 'OK';
        v_dat_dep           DATE;
    
        CURSOR c_dat_dep_cap IS
    	SELECT MIN (dat_prep)
    	FROM TABLE(sp_pc_gph_deb_to_tab (p_cod_usn, p_dat_deb, p_dat_fin))
        WHERE delai_maq < delai_prep;
    
        v_dat_max           DATE;
    
        -- calcul de l'ecart max entre dat_deb et dat_fin de la diff entre les 2 courbes
        CURSOR c_qte_dep_cap IS
        WITH d
        AS (SELECT dat_prep, dat_maq, tot_col FROM TABLE (sp_pc_gph_deb_to_tab (p_cod_usn,p_dat_deb,p_dat_fin)))
        SELECT MAX (qte_exp - qte_prep)
          FROM (  SELECT d1.dat_prep,
                         MIN (d1.tot_col) qte_prep,
                         MAX (d2.tot_col) qte_exp
                    FROM d d1, d d2
                   WHERE d1.dat_prep >=
                               d2.dat_maq
                             - (su_bas_to_number (
                                    su_bas_rch_action ('FRM_SP_GES_DEBORD',
                                                       'DELAI_MAQ')))
                GROUP BY d1.dat_prep);
    
    BEGIN
        OPEN c_dat_dep_cap;
    	FETCH c_dat_dep_cap INTO p_dat_dep;
        CLOSE c_dat_dep_cap;
    
        OPEN c_qte_dep_cap;
    	FETCH c_qte_dep_cap INTO p_nb_col_dep;
        CLOSE c_qte_dep_cap;
    
        RETURN v_ret;
    
    EXCEPTION
        WHEN OTHERS THEN 
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_lib_ano_1       => 'p_cod_usn ', 
                             p_par_ano_1       => p_cod_usn, 
                             p_lib_ano_2       => 'p_dat_deb ', 
                             p_par_ano_2       => p_dat_deb, 
                             p_lib_ano_3       => 'p_dat_fin ', 
                             p_par_ano_3       => p_dat_fin,  
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
            IF (v_ret = 'OK' OR v_ret IS null OR v_ret = 'ERROR') THEN 
                RETURN (NVL (v_cod_err_su_ano, 'ERROR')); 
            ELSE 
                RETURN (v_ret); 
            END IF;
    END;
    
    
    -- DESCRIPTION :
    -- -------------
    -- Fonction de calcul des lignes commandes � passer en d�bord
    FUNCTION sp_pc_cal_vol_deb (p_cod_usn su_usn.cod_usn%TYPE, p_dat_deb DATE, p_dat_fin DATE)
         RETURN VARCHAR2
    IS
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_cal_vol_deb';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
    
        v_ret               VARCHAR2(100) := 'OK';
        v_cod_cli           su_tiers.cod_tiers%TYPE := NULL;
        v_cod_groupe        pc_lig_com.cle_rgp_pal_1%TYPE := NULL;
    
        v_dat_dep           DATE;
        v_dat_deb_calcul    DATE;
        v_duree_max_calcul  NUMBER;
        v_qte_pal_std       NUMBER;
        v_tag_pro_tab       CHAR;
        v_nb_col_dep        NUMBER;
        v_cpt_volume        NUMBER := 0;
        v_cpt_deb           NUMBER := 0;
        v_nb_colis_max      NUMBER := NVL(su_bas_to_number(
                                             su_bas_rch_action(
                                                p_nom_par => 'FRM_SP_GES_DEBORD',
                                                p_par     => 'NB_COLIS')),99000); -- Si param null
        v_cpt               NUMBER;
        v_stk_deb           tt_stk_deb;
        v_i                 NUMBER;
    
        -- curseur pour suppression des afc emp
        CURSOR c_afc_supp IS
            SELECT DISTINCT a.cod_pro
              FROM se_afc_emp a
             WHERE a.typ_afc_emp = '00'
               AND a.cod_vl = '10'
               AND a.cod_mag = 'SPD'
               AND NOT EXISTS
                           (SELECT 1
                              FROM se_ord_trf o
                             WHERE cod_pro_orig = a.cod_pro
                               AND typ_trf = 'REASS'
                               AND cod_trf_mag = 'SUO-SPD')
               AND NOT EXISTS
                           (SELECT 1
                              FROM pc_lig_com lc
                             WHERE lc.cod_pro = a.cod_pro
                               AND cod_pss_afc = 'SDB01'
                               AND su_bas_etat_val_num (etat_atv_pc_lig_com,
                                                        'PC_LIG_COM') <
                                       su_bas_etat_val_num ('PRPP', 'PC_LIG_COM'))
               AND NOT EXISTS
                       (SELECT 1
                          FROM se_stk s
                         WHERE s.cod_pro = a.cod_pro AND s.cod_mag = 'SPD');
    
        -- Curseur principale sur les lignes restantes � analyser
        CURSOR c_lig_deb(x_cod_cli su_tiers.cod_tiers%TYPE, 
                         x_cod_groupe pc_lig_com.cle_rgp_pal_1%TYPE) IS
            SELECT no_com, no_lig_com, cod_pro, qte_cde, cod_cli, cle_rgp_pal_1
            FROM V_SP_DEB_COM_PRO_MAP
            WHERE cod_usn = p_cod_usn
            AND cod_pss_afc != 'SDB01' -- Process d�bord
            AND nvl(mod_deb,'0') IN ('0','3') -- libre_pc_lig_com_12
            AND nvl(lect_lig,'0') = '0' -- libre_pc_lig_com_13
            AND (x_cod_cli IS NULL OR cod_cli = x_cod_cli)
            AND (x_cod_groupe IS NULL OR cle_rgp_pal_1 = x_cod_groupe)
            --AND (p_dat_deb IS NULL OR dat_exp > p_dat_deb)
            AND (p_dat_fin IS NULL OR dat_exp <= p_dat_fin)
            ORDER BY 4 DESC;
    
       r_lig_deb    c_lig_deb%ROWTYPE;
       nf_lig_deb    BOOLEAN;
    
        -- Curseur retournant si un produit est mapp� et implant�
        CURSOR c_pro_map(x_cod_pro su_pro.cod_pro%TYPE) IS
            SELECT p.cod_pro 
            FROM su_pro p
            WHERE p.cod_pro = x_cod_pro
            AND p.LIBRE_SU_PRO_13 = '20' -- etat mapping
            AND EXISTS (SELECT 1 
                        FROM se_afc_emp a
                        WHERE a.cod_pro = p.cod_pro
                        AND a.cod_mag = 'SPD') ;
    
        r_pro_map   c_pro_map%ROWTYPE;
        f_pro_map   BOOLEAN;
    
        -- Curseur retournant si un produit a une affectation emplacement
        CURSOR c_afc_emp(x_cod_pro su_pro.cod_pro%TYPE) IS
            SELECT 1
            FROM se_afc_emp
            WHERE cod_pro = x_cod_pro
            AND cod_mag = 'SPD';
    
        r_afc_emp   c_afc_emp%ROWTYPE;
        nf_afc_emp   BOOLEAN;
    
        -- Curseur testant si au moins un produit est mapp�
        CURSOR c_afc IS
            SELECT count(*)
            FROM se_afc_emp
            WHERE cod_mag = 'SPD';
    
        v_afc   NUMBER;
    
        -- Curseur produit pour mapping
        -- Dans un premier temps on regarde les ligne pr� ordonnac�es donc avec plan de pal
        -- ensuite avant pord on compte le nb commande impact�es
        -- SI ON PREND TOUJOURS LE PREMIER PRODUIT ON RISQUE DE BOUCLER ET DE NE FAIRE QU'AJOUTER DE 
        -- LA QUANTIT� SUR UNE REFERENCE QUI N'EN A PAS BESOIN
        CURSOR c_pro_pal_map IS
          SELECT p.cod_pro, 1,
                 COUNT (DISTINCT ue.cod_up) qte_pal,
                 DECODE (NVL (a.no_afc_emp, 0), 0, '0', '1') etat_map,
                 abs(ascii(p.cod_abc)-ascii(nvl(su_bas_rch_par_usn('SP_ABC_PRIO_SEL_PRO',su_global_pkg.su_bas_get_cod_usn), 'C'))) abc
            FROM su_pro p,
                 se_afc_emp a,
                 pc_lig_com lc,
                 pc_uee ue,
                 pc_uee_det ud
           WHERE lc.cod_usn = su_global_pkg.su_bas_get_cod_usn
             AND lc.typ_lig_com = 'S'
             AND lc.no_com = ud.no_com
             AND lc.no_lig_com = ud.no_lig_com
             AND ud.no_uee = ue.no_uee
             AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com, 'PC_LIG_COM') >=
                     su_bas_etat_val_num ('PORD', 'PC_LIG_COM')
             AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com, 'PC_LIG_COM') <
                     su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
             AND lc.cod_pss_afc != 'SDB01'
             AND lc.cod_pro = p.cod_pro
             AND p.cod_pro = a.cod_pro(+)
             AND p.libre_su_pro_13 = '20' -- Le produit doit �tre qualifi� et implant�
             AND lc.lst_fct_lock IS NULL
             AND ue.cod_up IN
                     (SELECT DISTINCT ue2.cod_up
                        FROM pc_lig_com lc2, pc_uee ue2, pc_uee_det ud2
                       WHERE lc2.typ_lig_com = 'S'
                         AND lc2.cod_usn = su_global_pkg.su_bas_get_cod_usn
                         AND lc2.no_com = ud2.no_com
                         AND lc2.no_lig_com = ud2.no_lig_com
                         AND (lc2.libre_pc_lig_com_12 IN ('1', '2')
                           OR (su_bas_etat_val_num (lc2.etat_atv_pc_lig_com,'PC_LIG_COM') <
                                   su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
                           AND lc2.cod_pss_afc = 'SDB01'))
                         AND ud2.no_uee = ue2.no_uee)        -- Recup des up impact�es
             AND EXISTS
                         (SELECT 1
                            FROM pc_lig_com lc3
                           WHERE lc3.typ_lig_com = 'S'
                             AND su_bas_etat_val_num (lc3.etat_atv_pc_lig_com,'PC_LIG_COM') <
                                     su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
                             AND lc3.libre_pc_lig_com_12 NOT IN ('1', '2')
                             AND lc3.cod_pss_afc != 'SDB01'
                             AND lc3.cod_pro = p.cod_pro) -- exclusion des produits sans lignes a traiter
        GROUP BY p.cod_pro, DECODE (NVL (a.no_afc_emp, 0), 0, '0', '1'), p.cod_abc
        UNION ALL    
          SELECT p.cod_pro, 2,
                 COUNT (DISTINCT LC.no_com)-1 qte_pal, -- pour ne pas compter la commande courante
                 DECODE (NVL (a.no_afc_emp, 0), 0, '0', '1') etat_map,
                 abs(ascii(p.cod_abc)-ascii(nvl(su_bas_rch_par_usn('SP_ABC_PRIO_SEL_PRO',su_global_pkg.su_bas_get_cod_usn), 'C'))) abc
            FROM su_pro p,
                 se_afc_emp a,
                 pc_lig_com lc
           WHERE lc.cod_usn = su_global_pkg.su_bas_get_cod_usn
             AND lc.typ_lig_com = 'S'
             AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com, 'PC_LIG_COM') <
                     su_bas_etat_val_num ('PORD', 'PC_LIG_COM')
             AND lc.cod_pss_afc != 'SDB01'
             AND lc.cod_pro = p.cod_pro
             AND p.cod_pro = a.cod_pro(+)
             AND p.libre_su_pro_13 = '20' -- Le produit doit �tre qualifi� et implant�
             AND lc.lst_fct_lock IS NULL
             AND lc.no_com IN
                     (SELECT DISTINCT lc2.no_com
                        FROM pc_lig_com lc2
                       WHERE lc2.typ_lig_com = 'S'
                         AND lc2.cod_usn = su_global_pkg.su_bas_get_cod_usn
                         --AND lc2.no_com = lc.no_com
                         AND (lc2.libre_pc_lig_com_12 IN ('1', '2')
                           OR (su_bas_etat_val_num (lc2.etat_atv_pc_lig_com,'PC_LIG_COM') <
                                   su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
                           AND lc2.cod_pss_afc = 'SDB01')))   -- Recup des commandes impact�es
             AND EXISTS
                         (SELECT 1
                            FROM pc_lig_com lc3
                           WHERE lc3.typ_lig_com = 'S'
                             AND su_bas_etat_val_num (lc3.etat_atv_pc_lig_com,'PC_LIG_COM') <
                                     su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
                             AND lc3.libre_pc_lig_com_12 NOT IN ('1', '2')
                             AND lc3.cod_pss_afc != 'SDB01'
                             AND lc3.cod_pro = p.cod_pro) -- exclusion des produits sans lignes a traiter
        GROUP BY p.cod_pro, DECODE (NVL (a.no_afc_emp, 0), 0, '0', '1'), p.cod_abc
        ORDER BY 2, 3 DESC, 4  DESC, 5;
    
        r_pro_pal_map   c_pro_pal_map%ROWTYPE;
    
        -- Curseur des quantit�s par produit dans le stk debord et qte th�o des reass en cours
        CURSOR c_pro_stk IS
          SELECT cod_pro, SUM (qte_dispo) qte
            FROM v_se_stk
           WHERE cod_vl = '10' AND cod_mag = 'SPD'
        GROUP BY cod_pro
        UNION ALL
        SELECT cod_pro_orig cod_pro,
               su_bas_to_number (su_bas_gcl_su_ul (cod_pro_orig, '10', 'NB_UL_PAL'))
                   qte
          FROM se_ord_trf o
         WHERE typ_trf = 'REASS'
           AND cod_trf_mag = 'SUO-SPD'
           AND etat_ord_trf = 'WAIT'
           AND typ_ref_trf = 'RBES'
           AND NOT EXISTS
                       (SELECT 1
                          FROM v_se_stk
                         WHERE cod_vl = '10'
                           AND cod_mag = 'SPD'
                           AND cod_pro = o.cod_pro_orig);
    
    BEGIN
    
        v_etape := 'D�pose du savepoint sp_pc_cal_vol_deb';
        SAVEPOINT sp_pc_cal_vol_deb;
    
        v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' - p_cod_usn : '||p_cod_usn
                                      ||' - p_dat_deb : '||to_char(p_dat_deb,'YYYYMMDD HH24:MI')
                                      ||' - p_dat_fin : '||to_char(p_dat_fin,'YYYYMMDD HH24:MI'));
        END IF;
    
        v_etape := 'Reinitialisation de la simu et mode debord';
        UPDATE pc_lig_com
        SET libre_pc_lig_com_12 = '0'
        WHERE etat_atv_pc_lig_com IN ('APSS','PORD')
        AND lst_fct_lock IS NULL;
    
        -- Boucle sur les produits mapp�s sans stock, ni commande en cours ni ordre de transert de r�appro
        FOR r_afc_supp IN c_afc_supp LOOP
            v_etape := 'Suppression des affectations produit';
            DELETE FROM se_afc_emp 
             WHERE cod_pro = r_afc_supp.cod_pro
               AND typ_afc_emp = '00'
               --AND cod_vl = '10'
               AND cod_mag = 'SPD';
        END LOOP;
    
        COMMIT;
    
        v_etape := 'Calcul du volume cible � passer en d�bord';
        v_ret := sp_pc_dat_qte_dep_deb (p_cod_usn       => p_cod_usn,
                                        p_dat_deb       => p_dat_deb,
                                        p_dat_fin       => p_dat_fin,
                                        p_dat_dep       => v_dat_dep,
                                        p_nb_col_dep    => v_nb_col_dep);
    
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||' Il y a '||v_nb_col_dep||' colis � passer en d�bord');
        END IF;
    
        IF v_ret != 'OK' THEN
            RAISE err_except;
        END IF;
    
        v_etape := 'Cr�ation d''un tableau pour r�servations dans stock d�bord';
        v_stk_deb.DELETE;
        v_i := 0;
    
        FOR r_tab_pro IN c_pro_stk LOOP
            v_stk_deb(v_i).cod_pro := r_tab_pro.cod_pro;
            v_stk_deb(v_i).qte := r_tab_pro.qte;
            v_i := v_i +1;
        END LOOP;
    
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||' Il y a '||v_i||' produits en d�bord');
        END IF;
    
        -- Init de l'amor�age (premier produit)
        OPEN c_afc;
        FETCH c_afc INTO v_afc;
        CLOSE c_afc;
    
        IF v_afc = 0 THEN
            v_etape := 'Amor�age algorithme';
    
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' - '||v_etape);
            END IF;
    
            -- Prendre le produit le plus demand� sur la p�riode
            OPEN c_lig_deb(NULL, NULL);
            FETCH c_lig_deb INTO r_lig_deb;
            CLOSE c_lig_deb;
    
            v_qte_pal_std := su_bas_gcl_su_ul(
                                        p_cod_pro => r_lig_deb.cod_pro,
                                        p_cod_vl  => '10',
                                        p_colonne => 'NB_UL_PAL');
            v_tag_pro_tab := '0';
    
            v_etape := 'Si le produit existe dans le tableau de resa, maj qte';
            IF su_global_pkv.v_niv_dbg >= 8 THEN
                su_bas_put_debug(v_nom_obj||' - '||v_etape);
            END IF;
            IF v_stk_deb.count > 0 THEN
                FOR v_i IN v_stk_deb.first..v_stk_deb.last LOOP
                    IF v_stk_deb(v_i).cod_pro = r_lig_deb.cod_pro THEN
                        v_stk_deb(v_i).qte := v_stk_deb(v_i).qte + v_qte_pal_std;
                        v_tag_pro_tab := '1';
                    END IF;
                END LOOP;
            END IF;
    
            IF v_tag_pro_tab = '0' THEN           
                v_etape := 'Ajouter produit dans tableau de resa';
                IF su_global_pkv.v_niv_dbg >= 9 THEN
                    su_bas_put_debug(v_nom_obj||' - '||v_etape);
                END IF;
                v_stk_deb(0).cod_pro := r_lig_deb.cod_pro;
                v_stk_deb(0).qte := v_qte_pal_std;
            END IF;
    
            v_etape := 'Creation de l''affectation emp';
            IF su_global_pkv.v_niv_dbg >= 9 THEN
                su_bas_put_debug(v_nom_obj||' - '||v_etape);
            END IF;
            v_ret := sp_pc_crea_mapping( p_cod_usn => p_cod_usn,
                                         p_cod_pro => r_lig_deb.cod_pro);
        END IF;
        
        -- Init de la dur�e max de calcul et de la date de d�but de calcul
        v_duree_max_calcul := su_bas_to_number(
                                  su_bas_rch_action  (
                                      p_nom_par => 'FRM_SP_GES_DEBORD',
                                      p_par     => 'DELAI_CAL'));
        v_dat_deb_calcul := SYSDATE;
    
        v_etape := 'Boucle while';
        IF su_global_pkv.v_niv_dbg >= 8 THEN
            su_bas_put_debug(v_nom_obj||' - '||v_etape);
        END IF;
        <<boucle_generale>>
        WHILE TRUE LOOP
            v_etape := 'Sortie si nb_colis atteint sur le d�bord'; -- param �cran
            IF v_cpt_volume >= v_nb_colis_max THEN
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' - '||v_etape);
                END IF;
    
                EXIT boucle_generale;
            END IF;

            v_etape := 'Sortie si le volume a �t� ventil� sur le d�bord';
            IF v_cpt_volume >= v_nb_col_dep THEN
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' - '||v_etape);
                END IF;
    
                EXIT boucle_generale;
            END IF;
    
            v_etape := 'Sortie si timer expir�';
            IF SYSDATE > v_dat_deb_calcul + (v_duree_max_calcul/86400) THEN
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' - '||v_etape);
                END IF;
        
                EXIT boucle_generale;
            END IF;
            
            v_etape := 'S�lection nouveau produit si toutes les lign�es ont �t� lues';
            OPEN c_lig_deb(NULL, NULL);
            FETCH c_lig_deb INTO r_lig_deb;
            nf_lig_deb := c_lig_deb%NOTFOUND;
            CLOSE c_lig_deb;
    
            IF nf_lig_deb THEN
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' - '||v_etape);
                END IF;
    
                v_etape := 'Choix nouveau produit � mapper';
                OPEN c_pro_pal_map;
                FETCH c_pro_pal_map INTO r_pro_pal_map;
    
                IF c_pro_pal_map%found THEN
                    v_etape := 'Init de variables pour mapping';
    
                    IF su_global_pkv.v_niv_dbg >= 8 THEN
                        su_bas_put_debug(v_nom_obj||' - '||v_etape);
                    END IF;
    
                    v_qte_pal_std := su_bas_gcl_su_ul(
                                        p_cod_pro => r_pro_pal_map.cod_pro,
                                        p_cod_vl  => '10',
                                        p_colonne => 'NB_UL_PAL');
                    v_tag_pro_tab := '0';
    
                    v_etape := 'Si le produit existe dans le tableau de resa, maj qte';
                    FOR v_i IN v_stk_deb.first..v_stk_deb.last LOOP
                        IF v_stk_deb(v_i).cod_pro = r_pro_pal_map.cod_pro THEN
                            v_stk_deb(v_i).qte := v_stk_deb(v_i).qte + v_qte_pal_std;
                            v_tag_pro_tab := '1';
                        END IF;
                    END LOOP;
    
                    v_etape := 'Creation du mapping produit'; 
                    OPEN c_afc_emp(r_pro_pal_map.cod_pro);
                    FETCH c_afc_emp INTO r_afc_emp;
                    nf_afc_emp := c_afc_emp%NOTFOUND;
                    CLOSE c_afc_emp;
    
                    IF nf_afc_emp THEN
    
                        v_etape := 'Sortie si plus d''emplacement dispo';
                        v_ret := sp_pc_emp_disp_deb(p_cod_usn);
                        IF v_ret != 'OK' THEN
                            IF su_global_pkv.v_niv_dbg >= 6 THEN
                                su_bas_put_debug(v_nom_obj||' - '||v_etape);
                            END IF;
                    
                            EXIT boucle_generale;
                        END IF;
    
                        v_etape := 'Creation de l''affectation emp';
                        v_ret := sp_pc_crea_mapping( p_cod_usn => p_cod_usn,
                                                     p_cod_pro => r_pro_pal_map.cod_pro);
                    END IF;
    
                    IF v_tag_pro_tab = '0' THEN           
                        v_etape := 'Ajouter produit dans tableau de resa';
                        v_cpt := v_stk_deb.last + 1;
                        v_stk_deb(v_cpt).cod_pro := r_pro_pal_map.cod_pro;
                        v_stk_deb(v_cpt).qte := v_qte_pal_std;
                    END IF;
    
                    IF su_global_pkv.v_niv_dbg >= 9 THEN
                        FOR v_i IN v_stk_deb.first..v_stk_deb.last LOOP
                            su_bas_put_debug(v_nom_obj||' - Tableau resa : '||v_i||' '|| v_stk_deb(v_i).cod_pro
                                                      ||' -> '||v_stk_deb(v_i).qte);
                        END LOOP;
                    END IF;
    
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' - Ajout mapping pro : '||r_pro_pal_map.cod_pro
                                                  ||' - qte pal : '||v_qte_pal_std
                                                  ||' - deja pr�sent : '||v_tag_pro_tab);
                    END IF;
                ELSE
                    v_etape := 'Sortie si produit non trouv�';
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' - '||v_etape);
                    END IF;
            
                    EXIT boucle_generale;
                END IF;
    
                CLOSE c_pro_pal_map;
    
                v_etape := 'Reinit de la lecture ligne';
                UPDATE pc_lig_com
                SET libre_pc_lig_com_13 = '0'
                WHERE libre_pc_lig_com_13 =  '1';
    
                COMMIT;
    
                -- Reinit des filtres
                v_cod_cli := NULL;
                v_cod_groupe := NULL;
    
            END IF;
    
            v_etape := 'Boucle lig com';
            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' - '||v_etape
                                          ||' - v_cod_cli: '||v_cod_cli
                                          ||' - v_cod_groupe: '||v_cod_groupe);
            END IF;
    
            OPEN c_lig_deb(v_cod_cli, v_cod_groupe);
            <<boucle_lig_com>>
            LOOP
                FETCH c_lig_deb INTO r_lig_deb;
                
                -- Reinit des filtres
                v_cod_cli := NULL;
                v_cod_groupe := NULL;
    
                v_etape := 'Sortie de la boucle lig com';
                IF c_lig_deb%NOTFOUND THEN
                    IF su_global_pkv.v_niv_dbg >= 8 THEN
                        su_bas_put_debug(v_nom_obj||' - '||v_etape);
                    END IF;
        
                    EXIT boucle_lig_com;
                END IF;
    
                v_etape := 'Toppage de la lecture de la ligne';
                IF su_global_pkv.v_niv_dbg >= 8 THEN
                    su_bas_put_debug(v_nom_obj||' - '||v_etape||' - no_com.lig : '||r_lig_deb.no_com||'.'||r_lig_deb.no_lig_com);
                END IF;
    
                UPDATE pc_lig_com
                SET libre_pc_lig_com_13 = '1'
                WHERE no_com = r_lig_deb.no_com
                AND no_lig_com = r_lig_deb.no_lig_com;
    
                COMMIT;
    
                v_etape := 'V�rification du mapping produit';
                IF su_global_pkv.v_niv_dbg >= 8 THEN
                    su_bas_put_debug(v_nom_obj||' - '||v_etape);
                END IF;
    
                OPEN c_pro_map(r_lig_deb.cod_pro);
                FETCH c_pro_map INTO r_pro_map;
                f_pro_map := c_pro_map%FOUND;
                CLOSE c_pro_map;
    
                IF f_pro_map THEN
    
                    v_etape := 'R�cup�ration de la quantit� en stock';
                    IF su_global_pkv.v_niv_dbg >= 8 THEN
                        su_bas_put_debug(v_nom_obj||' - '||v_etape||' - cod_pro : '||r_lig_deb.cod_pro);
                    END IF;
    
                    IF v_stk_deb.COUNT > 0 THEN
                        <<boucle_stk>>
                        FOR v_i IN v_stk_deb.first..v_stk_deb.last LOOP
                            IF v_stk_deb(v_i).cod_pro = r_lig_deb.cod_pro THEN
        
                                -- on parcours le tableau de qte par produit dans le d�bord
                                IF r_lig_deb.qte_cde <= nvl(v_stk_deb(v_i).qte, 0) THEN
        
                                    v_etape := 'Quantit� suffisante, toppage ligne � d�bord';
                                    IF su_global_pkv.v_niv_dbg >= 8 THEN
                                        su_bas_put_debug(v_nom_obj||' - '||v_etape||' - cod_pro : '||r_lig_deb.cod_pro);
                                    END IF;
        
                                    UPDATE pc_lig_com
                                    SET libre_pc_lig_com_12 = '1'
                                    WHERE no_com = r_lig_deb.no_com
                                    AND no_lig_com = r_lig_deb.no_lig_com;
    
                                    COMMIT;
        
                                    v_etape := 'Incr�mentation du volume total pass� en d�bord et d�cr�mentation du stock';
                                    IF su_global_pkv.v_niv_dbg >= 9 THEN
                                        su_bas_put_debug(v_nom_obj||' - '||v_etape);
                                    END IF;
                                    v_cpt_volume := v_cpt_volume + r_lig_deb.qte_cde;
                                    v_stk_deb(v_i).qte := v_stk_deb(v_i).qte - r_lig_deb.qte_cde;
        
                                    v_etape := 'On positionne les variables du curseur pour le client et la cle de rgp';
                                    IF su_global_pkv.v_niv_dbg >= 9 THEN
                                        su_bas_put_debug(v_nom_obj||' - '||v_etape);
                                    END IF;
                                    v_cod_cli := r_lig_deb.cod_cli;
                                    v_cod_groupe := r_lig_deb.cle_rgp_pal_1;
        
                                    EXIT boucle_lig_com; -- sortie de la premi�re boucle et reouverture avec nouveau param�tre
                                END IF; -- si la quantit� n'est pas suffisante on passe a la ligne suivante
                            END IF; -- si le produit n'est pas en d�bord on passe � la ligne suivante
                        END LOOP boucle_stk;
                    END IF;
                END IF; -- sinon on passe � la ligne suivante
            END LOOP boucle_lig_com;
            CLOSE c_lig_deb;
        END LOOP boucle_generale;
    
        v_etape := 'Reinit de la lecture ligne';
        UPDATE pc_lig_com
        SET libre_pc_lig_com_13 = '0'
        WHERE libre_pc_lig_com_13 =  '1';
    
        COMMIT;
    
        RETURN v_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_pc_cal_vol_deb;
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_lib_ano_1       => 'p_cod_usn ', 
                             p_par_ano_1       => p_cod_usn, 
                             p_lib_ano_2       => 'p_dat_deb ', 
                             p_par_ano_2       => p_dat_deb, 
                             p_lib_ano_3       => 'p_dat_fin ', 
                             p_par_ano_3       => p_dat_fin,  
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
            IF (v_ret = 'OK' OR v_ret IS null OR v_ret = 'ERROR') THEN 
                RETURN (NVL (v_cod_err_su_ano, 'ERROR')); 
            ELSE 
                RETURN (v_ret); 
            END IF;
    END;
    
    -- DESCRIPTION :
    -- -------------
    -- Fonction de calcul de la place disponible pour mapping d'un nouveau produit en d�bord
    FUNCTION sp_pc_emp_disp_deb (p_cod_usn     su_usn.cod_usn%TYPE)
         RETURN VARCHAR2
    IS
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_emp_disp_deb';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
    
        v_ret               VARCHAR2(100) := 'OK';
    
        CURSOR c_seuil_max IS
        SELECT   COUNT (*)
                   * su_bas_to_number (
                          su_bas_rch_par_usn ('SP_TX_OQP_MAX_DEB', 'S'))
        FROM se_emp
        WHERE cod_mag = 'SPD';
    
        v_seuil_max NUMBER:=0;
    
        CURSOR c_ref_map IS
        SELECT SUM (NVL (a.qte_max, c.qte_max))
        FROM se_afc_emp a, se_cfg_rea c
        WHERE a.cod_mag = 'SPD' AND c.COD_CFG_REA = 'SP_BES_SUO';
    
        v_nb_ref_map   NUMBER := 0;
    
        CURSOR c_ref_a_map IS
        SELECT COUNT (DISTINCT cod_pro)
        FROM pc_lig_com
        WHERE libre_pc_lig_com_12 IN ('1','2')
        AND cod_pro NOT IN (SELECT cod_pro
                            FROM se_afc_emp
                            WHERE cod_mag = 'SPD');
    
        v_nb_ref_a_map NUMBER := 0;
    
    BEGIN
    
        v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' - p_cod_usn : '||p_cod_usn);
        END IF;
    
        v_etape := 'Calcul du seuil';
        OPEN c_seuil_max;
        FETCH c_seuil_max INTO v_seuil_max;
        CLOSE c_seuil_max;
    
        v_etape := 'Calcul du nombre de r�r�rences mapp�es';
        OPEN c_ref_map;
        FETCH c_ref_map INTO v_nb_ref_map;
        CLOSE c_ref_map;
    
        v_etape := 'Calcul du nombre de r�r�rences � mapper';
        OPEN c_ref_a_map;
        FETCH c_ref_a_map INTO v_nb_ref_a_map;
        CLOSE c_ref_a_map;
    
        IF (v_seuil_max < (v_nb_ref_map + v_nb_ref_a_map + 1 )) THEN
            v_etape := 'Le seuil est d�pass�';
            v_ret := 'KO';
        END IF;
    
        RETURN v_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_lib_ano_1       => 'p_cod_usn ', 
                             p_par_ano_1       => p_cod_usn, 
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
            IF (v_ret = 'OK' OR v_ret IS null OR v_ret = 'ERROR') THEN 
                RETURN (NVL (v_cod_err_su_ano, 'ERROR')); 
            ELSE 
                RETURN (v_ret); 
            END IF;
    END;
    
    -- DESCRIPTION :
    -- -------------
    -- Fonction de creation de mapping
    FUNCTION sp_pc_crea_mapping (p_cod_usn      su_usn.cod_usn%TYPE,
                                 p_cod_pro      su_pro.cod_pro%TYPE)
         RETURN VARCHAR2
    IS
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_crea_mapping';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
    
        v_ret               VARCHAR2(100) := 'OK';
        
        v_rec               se_afc_emp%ROWTYPE;
        v_rec2              se_afc_emp%ROWTYPE;
    
    BEGIN
        v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' - p_cod_usn : '||p_cod_usn);
        END IF;
    
        -- Creation du mapping si necessaire
        v_rec.typ_afc_emp := '00';
        v_rec.cod_usn := 'S';
        v_rec.cod_mag := 'SPD';
    	v_rec.cod_va := '0';
    	v_rec.cod_prk := '%';
    	v_rec.cod_vl := '10';
    	v_rec.no_ord_afc_emp := '1';
    	v_rec.cod_cfg_rea := 'SP_BES_SUO';
    	v_rec.typ_stk := '0';
    	v_rec.lst_vl_rea := ';10;';
    	v_rec.cod_pro := p_cod_pro;
    	
    	v_ret := se_bas_cre_afc_emp (v_rec);
    
        IF v_ret = 'OK' THEN
    	   	v_rec2 := su_bas_grw_se_afc_emp (v_rec.no_afc_emp);
    		v_ret := se_bas_synchro_stk_rea (v_rec2);
    
            IF v_ret != 'OK' THEN
                RAISE err_except;
            END IF;
        ELSE
            RAISE err_except;
    	END IF;
    	
        RETURN v_ret;
    EXCEPTION
        WHEN OTHERS THEN
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_lib_ano_1       => 'p_cod_usn', 
                             p_par_ano_1       => p_cod_usn, 
                             p_lib_ano_2       => 'p_cod_pro', 
                             p_par_ano_2       => p_cod_pro, 
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
            IF (v_ret = 'OK' OR v_ret IS null OR v_ret = 'ERROR') THEN 
                RETURN (NVL (v_cod_err_su_ano, 'ERROR')); 
            ELSE 
                RETURN (v_ret); 
            END IF;
    END;
    
    -- DESCRIPTION :
    -- -------------
    -- Fonction de validation de la selection de debord
    FUNCTION sp_pc_valid_selec_deb (p_cod_usn     su_usn.cod_usn%TYPE)
         RETURN VARCHAR2
    IS
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_valid_selec_deb';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
    
        v_ret               VARCHAR2(100) := 'OK';
        
        v_rec               se_afc_emp%ROWTYPE;
        v_rec2              se_afc_emp%ROWTYPE;
    
        CURSOR c_crea_mapping IS
    	SELECT cod_pro
    	  FROM V_SP_PRO_DEB 
    	 WHERE etat_map = '0';
    		 
    	CURSOR c_xst_mapping(x_cod_pro su_pro.cod_pro%TYPE) IS
    	SELECT cod_pro
    	  FROM se_afc_emp
    	 WHERE cod_mag = 'SPD'
    	   AND cod_pro = x_cod_pro;
    
        r_xst_mapping c_xst_mapping%ROWTYPE;
    	b_xst_mapping BOOLEAN;
    
    BEGIN
        v_etape :=  'Depose d''un SAVEPOINT';
        SAVEPOINT sp_pc_valid_selec_deb;
    
        v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' - p_cod_usn : '||p_cod_usn);
        END IF;
    		   
        v_etape := 'Creation du mapping si necessaire';  
    	FOR r_crea_mapping IN c_crea_mapping LOOP
    		OPEN c_xst_mapping (r_crea_mapping.cod_pro);
    		FETCH c_xst_mapping INTO r_xst_mapping;
    		b_xst_mapping := c_xst_mapping%FOUND;
    		CLOSE c_xst_mapping;
    		
    		IF NOT b_xst_mapping THEN
                v_ret := sp_pc_crea_mapping( p_cod_usn => p_cod_usn,
                                             p_cod_pro => r_crea_mapping.cod_pro);
    		END IF;
    	END LOOP;
    
        v_etape := 'Changement de process des lignes commandes';  
        v_ret := sp_pc_bas_chg_pss( p_cod_verrou    => 'DEB',
                                    p_cod_pss		=> 'SDB01' ,
                                    p_cod_atl		=> 'SPD');
                                    --,p_no_uee		=> NULL);   
              
        IF v_ret != 'OK' THEN
            RAISE err_except;
        END IF;
    
    
        RETURN v_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_pc_valid_selec_deb;
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_lib_ano_1       => 'p_cod_usn', 
                             p_par_ano_1       => p_cod_usn, 
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
            IF (v_ret = 'OK' OR v_ret IS null OR v_ret = 'ERROR') THEN 
                RETURN (NVL (v_cod_err_su_ano, 'ERROR')); 
            ELSE 
                RETURN (v_ret); 
            END IF;
    END;
    
    -- DESCRIPTION :
    -- -------------
    -- Fonction de purge du stock de debord
    FUNCTION sp_pc_purge_deb (p_cod_usn     su_usn.cod_usn%TYPE,
                              p_lst_cod_pro VARCHAR2)
         RETURN VARCHAR2
    IS
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_purge_deb';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
    
        v_ret               VARCHAR2(100) := 'OK';
        v_ctx               su_ctx_pkg.tt_ctx;
        v_cod_vl            su_ul.cod_vl%TYPE;
        v_cod_emp_dest      se_emp.cod_emp%TYPE;
    
        CURSOR c_cod_pro IS
            SELECT column_value cod_pro
              FROM TABLE(su_bas_lst_to_tab(p_lst_cod_pro));
    
        CURSOR c_ord_trf (x_cod_pro su_pro.cod_pro%TYPE) IS
            SELECT cod_ord_trf
              FROM se_ord_trf
             WHERE cod_pro_orig = x_cod_pro
               AND cod_trf_mag = 'SUO-SPD'
               AND etat_ord_trf = 'WAIT';
    
        CURSOR c_ut_stk (x_cod_pro su_pro.cod_pro%TYPE) IS
            SELECT DISTINCT cod_ut, typ_ut, cod_emp
              FROM se_stk
             WHERE cod_pro = x_cod_pro
               AND cod_mag = 'SPD';
    
        CURSOR c_ul ( x_cod_pro su_ul.cod_pro%TYPE,
                      x_cod_vl  su_ul.cod_vl%TYPE) IS
            SELECT mode_depal_auto
              FROM su_ul 
             WHERE cod_pro = x_cod_pro
               AND cod_vl  = x_cod_vl;
    
        v_mode_depal_auto su_ul.mode_depal_auto%TYPE;
    
    	CURSOR c_com_en_cours (x_cod_pro su_pro.cod_pro%TYPE) IS
    	    SELECT 1
              FROM pc_lig_com lc
             WHERE cod_pro = x_cod_pro
               AND cod_pss_afc = 'SDB01'
               AND su_bas_etat_val_num (etat_atv_pc_lig_com,'PC_LIG_COM') <
                                su_bas_etat_val_num ('PRPP', 'PC_LIG_COM');
    
        r_com_en_cours  c_com_en_cours%ROWTYPE;
        b_com_en_cours  BOOLEAN;
    
    BEGIN
       v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' - p_cod_usn : '||p_cod_usn);
        END IF;
    
        v_etape := 'D�pose du savepoint sp_pc_purge_deb';
        SAVEPOINT sp_pc_purge_deb;
    
        FOR r_cod_pro IN c_cod_pro LOOP
    
            OPEN c_com_en_cours (r_cod_pro.cod_pro);
            FETCH c_com_en_cours INTO r_com_en_cours;
            b_com_en_cours := c_com_en_cours%NOTFOUND;
            CLOSE c_com_en_cours;
    
            -- s'il n'y a pas de commande en cours
            IF b_com_en_cours THEN
    
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' Purge produit '||r_cod_pro.cod_pro);
                END IF;
        
                v_etape := 'Suppression du mapping magasin';
                DELETE FROM se_afc_emp 
                 WHERE cod_pro = r_cod_pro.cod_pro
                   AND cod_mag = 'SPD';
     
                v_etape := 'Annulation d''ordres de transfert �ventuels du produit en r�appro';
                FOR r_ord_trf IN c_ord_trf(r_cod_pro.cod_pro) LOOP
    
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' Annul ord trf '||r_ord_trf.cod_ord_trf);
                    END IF;
    
                    v_ret := se_bas_annul_ord_trf (
                                p_cod_ord_trf       => r_ord_trf.cod_ord_trf,
                                p_mode_annul_trf    => 'CANCEL',
                                p_no_pos_annul      => su_global_pkv.v_no_pos,
                                p_cod_ope_annul     => su_global_pkv.v_cod_ope,
                                p_cod_fct_stk_annul => 'SPPURGEDEB',
                                p_cod_raison        => 'PURGE DEB',
                                p_motif_mvt         => 'PURGE DU DEBORD'
                                );
    
                    IF v_ret != 'OK' THEN
                        RAISE err_except;
                    END IF;
    
                END LOOP;
    
                v_etape := 'R�cup�ration du mode de d�pal';
                v_cod_vl := su_bas_rch_vl_typ (r_cod_pro.cod_pro, NULL, 'CC');
                OPEN c_ul(r_cod_pro.cod_pro, v_cod_vl);
                FETCH c_ul INTO v_mode_depal_auto;
                CLOSE c_ul;
    
                IF v_mode_depal_auto = '1' THEN
                    v_cod_emp_dest := 'SAAA';
                ELSE
                    v_cod_emp_dest := 'SAAM';
                END IF;
    
                v_etape := 'Cr�ation des ordre de transfert';
                FOR r_ut_stk IN c_ut_stk(r_cod_pro.cod_pro) LOOP
                    v_ret := se_bas_trf_stk (
                                p_typ_trf       => 'PURGE',
                                p_mode_trf      => 'DEM',
                                p_dat_mvt       => SYSDATE,
                                p_cod_fct_stk   => 'NEWORDTRF',
                                p_cod_raison    => 'TRANS MECA',
                                p_motif_mvt     => 'TRANSFERT VERS MECA',
                                p_cod_pro       => r_cod_pro.cod_pro,
                                p_cod_vl        => '10',
                                p_cod_va        => '0',
                                p_qte_trf       => 1,
                                p_unit_trf      => 'UT',
                                p_cod_usn       => su_global_pkv.v_cod_usn,
                                p_cod_mag       => 'SPD',
                                p_cod_emp       => r_ut_stk.cod_emp,
                                p_cod_ut        => r_ut_stk.cod_ut,
                                p_typ_ut        => r_ut_stk.typ_ut,
                                p_cod_usn_dest  => su_global_pkv.v_cod_usn,
                                p_cod_mag_dest  => 'SAA',
                                p_cod_emp_dest  => v_cod_emp_dest);
        
                    IF v_ret != 'OK' THEN
                        RAISE err_except;
                    END IF;
    
                    v_etape := 'Edition des etiquettes'; 
                    IF su_ctx_pkg.su_bas_set_char(v_ctx,'P_TYP_UT',r_ut_stk.typ_ut)
                    AND su_ctx_pkg.su_bas_set_char(v_ctx,'P_COD_UT',r_ut_stk.cod_ut) THEN
    
                        su_lst_doc_pkg.su_bas_exec_lst_doc (p_cod_ldoc  => 'SUO_ETQ_UT_PURGE',
                                                            p_lst_par   => v_ctx);
                    END IF;
        
                END LOOP;
            ELSE
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' Commande en cours sur produit '||r_cod_pro.cod_pro);
                END IF;
            END IF;
        END LOOP;
    
        su_bas_commit;
    
        RETURN v_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_pc_purge_deb;
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_lib_ano_1       => 'p_cod_usn ', 
                             p_par_ano_1       => p_cod_usn, 
                             p_lib_ano_2       => 'p_lst_cod_pro ', 
                             p_par_ano_2       => p_lst_cod_pro, 
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
            IF (v_ret = 'OK' OR v_ret IS null OR v_ret = 'ERROR') THEN 
                RETURN (NVL (v_cod_err_su_ano, 'ERROR')); 
            ELSE 
                RETURN (v_ret); 
            END IF;
    END;
    
    
    -- DESCRIPTION :
    -- -------------
    -- Fonction d'alimentation des compteurs debord
    FUNCTION sp_pc_compteurs_deb
         RETURN tt_cpt_deb  PIPELINED
    IS
        v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
        v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_purge_deb';
        v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
        v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
        err_except          EXCEPTION;
        v_ret               VARCHAR2(50);
    
        r_compteurs_deb  tr_cpt_deb;
    
    BEGIN
       v_etape := 'Trace';
        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj);
        END IF;
    
        -- r_compteurs_deb.TOT_REF_DEB := 1
        SELECT COUNT (*) INTO r_compteurs_deb.TOT_REF_DEB
              FROM su_pro p
             WHERE p.libre_su_pro_13 = '20'
               AND EXISTS
                       (SELECT 1
                          FROM se_afc_emp a
                         WHERE a.cod_pro     = p.cod_pro
                           AND a.cod_usn     = su_global_pkg.su_bas_get_cod_usn
                           AND a.typ_afc_emp = '00');
    
        -- r_compteurs_deb.NB_PAL_DEB     := 2;
         SELECT COUNT (DISTINCT e.cod_up) INTO r_compteurs_deb.NB_PAL_DEB
                FROM pc_uee e, pc_uee_det d
               WHERE d.cod_usn = su_global_pkg.su_bas_get_cod_usn
                 AND e.no_uee = d.no_uee
                 AND NOT EXISTS
                   (SELECT 1
                      FROM pc_lig_com lc, pc_uee ue, pc_uee_det ud
                     WHERE E.COD_UP = ue.cod_up
                       AND E.TYP_UP = ue.typ_up
                       AND ue.no_uee = ud.no_uee
                       AND ud.no_com = lc.no_com
                       AND ud.no_lig_com = lc.no_lig_com
                       AND NVL (lc.libre_pc_lig_com_12, '0') IN ('0', '3'));
    
        --r_compteurs_deb.NB_PAL_REP     := 3;
        SELECT count(DISTINCT e.cod_up) INTO r_compteurs_deb.NB_PAL_REP
            FROM pc_uee e
            WHERE e.cod_usn = su_global_pkg.su_bas_get_cod_usn
            AND EXISTS
                   (SELECT 1
                      FROM pc_lig_com lc, pc_uee ue, pc_uee_det ud
                     WHERE E.COD_UP = ue.cod_up
                       AND E.typ_UP = ue.typ_up
                       AND ue.no_uee = ud.no_uee
                       AND ud.no_com = lc.no_com
                       AND ud.no_lig_com = lc.no_lig_com
                       AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com, 'PC_LIG_COM') <
                                su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
                       AND NVL (lc.libre_pc_lig_com_12, '0') IN ('0', '3'))
            AND EXISTS
                   (SELECT 1
                      FROM pc_lig_com lc, pc_uee ue, pc_uee_det ud
                     WHERE E.COD_UP = ue.cod_up
                       AND E.typ_UP = ue.typ_up
                       AND ue.no_uee = ud.no_uee
                       AND ud.no_com = lc.no_com
                       AND ud.no_lig_com = lc.no_lig_com
                       AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com, 'PC_LIG_COM') <
                                su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
                       AND NVL (lc.libre_pc_lig_com_12, '0') IN ('1', '2'));
    
        -- r_compteurs_deb.NB_PRO_DEB     := 4;
        SELECT COUNT (DISTINCT cod_pro) INTO r_compteurs_deb.NB_PRO_DEB FROM v_sp_pro_deb;
    
        -- r_compteurs_deb.NB_PRO_A_MAP   := 5;
        SELECT COUNT (DISTINCT cod_pro) INTO r_compteurs_deb.NB_PRO_A_MAP
                 FROM v_sp_pro_deb
                WHERE etat_map = '1';
        r_compteurs_deb.NB_PRO_A_MAP   :=  r_compteurs_deb.NB_PRO_DEB  - r_compteurs_deb.NB_PRO_A_MAP;
    
        -- r_compteurs_deb.NB_PRO_A_DEMAP := 6;
        SELECT COUNT (DISTINCT p.cod_pro) INTO r_compteurs_deb.NB_PRO_A_DEMAP
              FROM su_pro p
             WHERE p.LIBRE_SU_PRO_13 = '20'                   -- etat implantation
               AND EXISTS
                       (SELECT 1
                          FROM se_afc_emp a
                         WHERE a.cod_pro     = p.cod_pro
                           AND a.cod_usn     = su_global_pkg.su_bas_get_cod_usn
                           AND a.typ_afc_emp = '00')
               AND NOT EXISTS
                           (SELECT 1
                              FROM pc_lig_com lc
                             WHERE lc.cod_pro = p.cod_pro
                               AND (libre_pc_lig_com_12 in ('1','2')
                                   OR cod_pss_afc = 'SDB01')
                               AND su_bas_etat_val_num (etat_atv_pc_lig_com,
                                                        'PC_LIG_COM') <
                                       su_bas_etat_val_num ('PRPP', 'PC_LIG_COM'));
    
        --r_compteurs_deb.NB_PAL_IMPACT  := 7;
        SELECT COUNT (DISTINCT ue.cod_up) INTO r_compteurs_deb.NB_PAL_IMPACT
              FROM pc_ent_com ec, pc_lig_com lc, pc_uee ue, pc_uee_det ud
             WHERE ec.cod_usn = su_global_pkg.su_bas_get_cod_usn
               AND ec.no_com = lc.no_com
               AND lc.no_com = ud.no_com
               AND lc.no_lig_com = ud.no_lig_com
               AND ud.no_uee = ue.no_uee
               AND lc.cod_pss_afc != 'SDB01'
               AND su_bas_etat_val_num (lc.etat_atv_pc_lig_com, 'PC_LIG_COM') <
                       su_bas_etat_val_num ('ORDT', 'PC_LIG_COM')
               AND NVL (lc.libre_pc_lig_com_12, '0') IN ('1', '2');
    
        --r_compteurs_deb.NB_PRO_A_REASS  := 8;
        SELECT count( DISTINCT d.cod_pro) INTO r_compteurs_deb.NB_PRO_A_REASS
            FROM v_sp_pro_deb d
            WHERE NOT EXISTS 
                (SELECT 1
                   FROM se_stk s
                  WHERE cod_mag = 'SPD'
                    AND d.cod_pro= s.cod_pro);
    
        pipe ROW(r_compteurs_deb);
    
    EXCEPTION
        WHEN NO_DATA_NEEDED THEN 
            NULL;
        WHEN OTHERS THEN
            su_bas_cre_ano ( p_txt_ano         => 'EXCEPTION : ' || v_etape, 
                             p_cod_err_ora_ano => SQLCODE, 
                             p_cod_err_su_ano  => v_cod_err_su_ano, 
                             p_nom_obj         => v_nom_obj, 
                             p_version         => v_version ); 
    END;

END; -- fin du package
/
show errors;

