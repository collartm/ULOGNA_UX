/* $Id$
****************************************************************************
* pc_bas_sqc_tri_ut - determination de l'urgence d'une UT 
*/
-- DESCRIPTION :
-- -------------
-- fonction utilisée dans les tris sur les clés de palettisation 
-- par UT palette.
--
--
-- PARAMETRES :
-- ------------
-- p_cod_ut_pal : UT palette 
-- p_typ_ut_pal : type de l'UT
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 01a,15.12.14 mnev    Creation
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
-- code de tri            
--
-- COMMIT :
-- --------
-- NON  

CREATE OR REPLACE
FUNCTION pc_bas_sqc_tri_ut (p_cod_ut_pal   pc_sqc_cle.cod_ut_pal%TYPE,
                            p_typ_ut_pal   pc_sqc_cle.typ_ut_pal%TYPE,
                            p_no_dpt       pc_ut.no_dpt%TYPE DEFAULT NULL,
                            p_dat_crea     pc_ut.dat_crea%TYPE DEFAULT NULL)
RETURN VARCHAR2 IS

    --v_version         su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_sqc_tri_ut';
    v_etape             SU_ANO_HIS.txt_ano%TYPE := 'Declare';
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(100) := NULL;
    v_ctx               su_ctx_pkg.tt_ctx;
    v_add_ctx           BOOLEAN;
    v_event             VARCHAR2(20) := 'SQCTRIUT01';


    v_no_dpt            pc_ut.no_dpt%TYPE   := p_no_dpt; 
    v_dat_crea          pc_ut.dat_crea%TYPE := p_dat_crea; 
    v_par_delai         NUMBER;
    v_dat_exp           DATE;

    --
    -- RCH info sur UT
    --
    CURSOR c_ut IS
        SELECT no_dpt, dat_crea, cod_cli, cod_usn
          FROM pc_ut 
         WHERE cod_ut = p_cod_ut_pal AND typ_ut = p_typ_ut_pal;

    r_ut c_ut%ROWTYPE;

    CURSOR c_cli ( x_cod_cli pc_ut.cod_cli%TYPE) IS
    SELECT COUNT(*) val
    FROM   pc_ut
    WHERE  cod_cli = x_cod_cli
    AND    no_rmp IS NOT NULL
    AND    su_bas_etat_val_num(etat_atv_pc_ut, 'PC_UT') < su_bas_etat_val_num('CONSOLIDE', 'PC_UT')
    AND    su_bas_etat_val_num(etat_atv_pc_ut, 'PC_UT') >= su_bas_etat_val_num('REGULATION', 'PC_UT')
    AND    etat_atv_pc_ut != 'PRP0';

    r_cli c_cli%ROWTYPE;

    CURSOR c_uee IS 
    SELECT count(no_uee) nb_uee
    FROM   pc_uee
    WHERE  cod_ut_sup = p_cod_ut_pal
    AND    typ_ut_sup = p_typ_ut_pal
    AND    etat_atv_pc_uee != 'PRP0';

    r_uee c_uee%ROWTYPE;

BEGIN

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug(v_nom_obj||' cod_ut_pal:' || p_cod_ut_pal || '-' || p_typ_ut_pal);
        su_bas_put_debug(v_nom_obj||' no_dpt:' || p_no_dpt || ' DatCrea:' || TO_CHAR(p_dat_crea,'DDMMYYYY HH24MISS'));
    END IF;

    --IF p_no_dpt IS NULL OR p_dat_crea IS NULL THEN
        -- 
        -- Complement info UT
        --
        OPEN c_ut;
        FETCH c_ut INTO r_ut;
        CLOSE c_ut;

        v_no_dpt   := r_ut.no_dpt;
        v_dat_crea := r_ut.dat_crea;

    --END IF;
    
    -- Spécifique SUO :
    /* 
    *Sydel Univers priorisera les lancements en préparation suivant les règles suivantes :
    *	-Date / heure de mise à quai (Heure arrondie heure entière supérieure si heure départ > H système + Paramètre)
    *	-Pas de palette en cours pour le client (pris en compte par la régulation des sorties de stock pour améliorer les transferts vers les quais)
    *	-Quantité à préparer par ordre décroissant
    */
    v_par_delai := NVL(TO_NUMBER(su_bas_rch_par_usn('SP_DELAI_ARR_HEU_TRI_REG', r_ut.cod_usn)), 120);
    v_dat_exp := TO_DATE(su_bas_gcl_ex_ent_dpt ( v_no_dpt, 'DAT_EXP'), su_bas_get_date_format);
    IF v_dat_exp > SYSDATE + v_par_delai/1440 THEN
        v_dat_exp := TRUNC(v_dat_exp, 'HH24') + 1/24;    -- arrondi heure entière supp.
    END IF;

    OPEN c_cli ( r_ut.cod_cli);
    FETCH c_cli INTO r_cli;
    CLOSE c_cli;

    OPEN c_uee;
    FETCH c_uee INTO r_uee;
    CLOSE c_uee;

    v_ret := TO_CHAR(v_dat_exp, 'YYYYMMDDHH24MISS')||NVL(r_cli.val, '0')||LPAD(TO_CHAR(999-r_uee.nb_uee), 3, '0');

    IF su_global_pkv.vt_evt_actif.exists('ON_' || v_event) THEN 
        v_etape := 'creation ctx';
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_UT', p_cod_ut_pal);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'TYP_UT', p_typ_ut_pal);
        v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'NO_DPT', v_no_dpt);
        v_add_ctx := su_ctx_pkg.su_bas_set_date(v_ctx,'DAT_CREA',v_dat_crea);

        v_etape := 'Appel événement ON';
        v_ret_evt := su_plsql_pkg.su_bas_exec_plsql (v_ctx,'ON_' || v_event);
        IF v_ret_evt = 'ERROR' THEN
            v_ret_evt := NULL;
        END IF;
    ELSE
        v_ret_evt := NULL;
    END IF;

    v_ret := v_ret || v_ret_evt;

    IF su_global_pkv.v_niv_dbg >= 9 THEN
        su_bas_put_debug(v_nom_obj|| ' v_ret:' || v_ret);
    END IF;

    RETURN v_ret;
            
END;   
/
show errors;

