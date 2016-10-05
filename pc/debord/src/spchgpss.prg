/* $Id$
****************************************************************************
* sp_pc_bas_chg_pss -    
*
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'effectuer le changement de process pour 
-- la ligne de commande, les colis et les lignes de colis.
--
-- PARAMETRES :
-- ------------
--  p_cod_verrou
--  p_cod_pss
--  p_cod_atl
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 02,24.10.14,tjaf     Spec du prg pour prise en compte du mode débord
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   OUI

CREATE OR REPLACE
FUNCTION sp_pc_bas_chg_pss (p_cod_verrou        VARCHAR2,
                            p_cod_pss           su_pss.cod_pss%TYPE,
                            p_cod_atl           su_atl.cod_atl%TYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02 $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_pc_bas_chg_pss';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;

    CURSOR c_uee IS 
    SELECT d.no_uee,d.no_com,d.no_lig_com, c.cod_up, c.typ_up
      FROM pc_uee c,pc_uee_det d,pc_lig_com l
     WHERE l.no_com = d.no_com
       AND l.no_lig_com = d.no_lig_com
       AND l.libre_pc_lig_com_12 IN ('1','2') -- SPEC
       AND c.no_uee = d.no_uee
       AND INSTR(l.lst_fct_lock, p_cod_verrou) > 0 
       AND l.id_session_lock = v_session_ora;

    CURSOR c_lig_non_preco IS 
    SELECT no_lig_com, no_com, cod_qlf_trv
      FROM pc_lig_com
     WHERE INSTR(lst_fct_lock, p_cod_verrou) > 0 
       AND id_session_lock = v_session_ora
       AND libre_pc_lig_com_12 IN ('1','2') -- SPEC
       AND etat_pcl = '0' ;

    CURSOR c_up IS
    SELECT cod_up, typ_up
      FROM pc_up
     WHERE etat_atv_pc_up = 'RELA';
 
BEGIN

    SAVEPOINT my_pc_bas_chg_pss;

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : cod_verrou = '  || p_cod_verrou
                                  ||' : cod_pss = '     || p_cod_pss
                                  ||' : cod_atl = '     || p_cod_atl);
    END IF;

    v_etape := 'MAJ UEE';
    FOR r_uee IN c_uee LOOP

        v_etape := 'MAJ pc_uee :'||r_uee.no_uee;
        UPDATE pc_uee SET 
               cod_pss_afc = p_cod_pss,
               cod_atl_prp = p_cod_atl
         WHERE no_uee      = r_uee.no_uee;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape);
        END IF;

        v_etape := 'MAJ pc_uee_det';
        UPDATE pc_uee_det SET
               cod_pss_afc = p_cod_pss,
               cod_atl_prp = p_cod_atl
         WHERE no_uee      = r_uee.no_uee 
           AND no_com      = r_uee.no_com 
           AND no_lig_com  = r_uee.no_lig_com;

        v_etape := 'Flag sur les UPs :'||r_uee.cod_up;
        UPDATE pc_up
           SET etat_atv_pc_up = 'RELA'
         WHERE cod_up = r_uee.cod_up
           AND typ_up = r_uee.typ_up;

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape);
        END IF;
    END LOOP;

    v_etape := 'Mise à jour PC_LIG_COM';
    UPDATE pc_lig_com
       SET cod_pss_afc = p_cod_pss,
           cod_atl_prp = p_cod_atl
     WHERE INSTR(lst_fct_lock, p_cod_verrou) > 0 
       AND id_session_lock = v_session_ora;

    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj||v_etape);
    END IF;

    v_etape := 'Mise à jour des UEE liées aux UPs impactées(changement plan de pal)';
    FOR r_up IN c_up LOOP

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||' cod_up = '||r_up.cod_up);
        END IF;

        UPDATE pc_uee SET
               etat_atv_pc_uee = NVL(su_bas_rch_etat_atv('SET_RELANCE_2_PLA','PC_UEE'),etat_atv_pc_uee),
               cod_up          = NULL,
               typ_up          = NULL,
               cod_ut          = NULL,
               typ_ut          = NULL,
               cod_ut_sup      = NULL,
               typ_ut_sup      = NULL,
               lst_chkpt_suivi = lst_chkpt_suivi||';DEBORD-'||to_char(systimestamp,'DDD+HH24MISS,FF')||'-'||su_global_pkv.v_cod_ope||';',
               dat_reg         = NULL,
               no_reg          = 0,
               no_rmp          = NULL,
               sgn_serie       = NULL,
               sgn_ss_serie    = NULL,
               no_ss_serie     = NULL,
               cod_grp_aff     = no_uee,
               etat_cr_lvzp    = '0',
               etat_cr_cpal    = '0',
               cb_complet      = NULL,
               dat_sel         = NULL,
               dat_tn1         = NULL,
               mode_aff_uee    = NULL,
               no_uee_ut_p1    = NULL
         WHERE cod_up = r_up.cod_up
           AND typ_up = r_up.typ_up
           AND su_bas_etat_val_num (etat_atv_pc_uee, 'PC_UEE') <
                    su_bas_etat_val_num ('ORDF', 'PC_UEE');

    END LOOP;

    --
    -- On met à jour les lig_com non précolisees
    --
    v_etape := 'Mise à jour PC_LIG_COM ';
    FOR r_lig_non_preco IN c_lig_non_preco LOOP

        UPDATE pc_lig_com SET 
               cod_pss_afc = p_cod_pss,
               cod_atl_prp = p_cod_atl
         WHERE no_com      = r_lig_non_preco.no_com 
           AND no_lig_com  = r_lig_non_preco.no_lig_com;

    END LOOP;
    
    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_pc_bas_chg_pss;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'verrou',
                        p_par_ano_1       => p_cod_verrou,
                        p_lib_ano_2       => 'cod_pss',
                        p_par_ano_2       => p_cod_pss,
                        p_lib_ano_3       => 'cod_atl',
                        p_par_ano_3       => p_cod_atl,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;
/
show errors;

exit;