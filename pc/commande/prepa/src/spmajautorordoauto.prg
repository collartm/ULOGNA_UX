/* $Id$
****************************************************************************
* sp_bas_maj_autor_ordo_auto -  Gestion autorisation d'ordonnancement automatique
*                  dans le cas de commande sans quai ou tournee = 0
*/
-- DESCRIPTION :
-- -------------
--
-- PARAMETRES :
-- ------------
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,16.07.14,pluc    Creation
-- 00a,24.10.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE FUNCTION sp_bas_maj_autor_ordo_auto 
    (
     p_chk_quai    VARCHAR2,
     p_chk_tou     VARCHAR2
    )  
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_maj_autor_ordo_auto';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';
    v_ret_evt           VARCHAR2(20)  := NULL;

    v_val_par_quai su_par_usn.val_par_usn%TYPE;
    v_val_par_tou  su_par_usn.val_par_usn%TYPE;
    v_maj          BOOLEAN := FALSE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_chk_quai = ' || p_chk_quai ||
                                    ' / p_chk_tou = '|| p_chk_tou );
    END IF;

    v_val_par_quai := su_bas_rch_par_usn('SP_AUTOR_QUAI_ORDO_AUTO', su_global_pkv.v_cod_usn);
    v_val_par_tou  := su_bas_rch_par_usn('SP_AUTOR_TOU_ORDO_AUTO', su_global_pkv.v_cod_usn);

    IF p_chk_quai != v_val_par_quai THEN
        UPDATE su_par_usn
            SET val_par_usn = p_chk_quai
            WHERE cod_par_usn = 'SP_AUTOR_QUAI_ORDO_AUTO'
            AND   su_global_pkv.v_cod_usn LIKE mask_usn;
        v_maj := TRUE;
    END IF;

    IF p_chk_tou != v_val_par_tou THEN
        UPDATE su_par_usn
            SET val_par_usn = p_chk_tou
            WHERE cod_par_usn = 'SP_AUTOR_TOU_ORDO_AUTO'
            AND   su_global_pkv.v_cod_usn LIKE mask_usn;
        v_maj := TRUE;
    END IF;

    IF v_maj AND ( p_chk_quai = '1' OR p_chk_tou = '1') THEN
     
        -- on passe les lignes à ordo auto autorise
        UPDATE pc_lig_com l
            SET l.etat_autor_ord = '1'
            WHERE l.etat_autor_ord = '2'
            AND   su_bas_etat_val_num( l.etat_atv_pc_lig_com, 'PC_LIG_COM') < su_bas_etat_val_num('ORDO_TERM', 'PC_LIG_COM')
            AND   cod_usn = su_global_pkv.v_cod_usn
            AND   EXISTS ( SELECT 1
                           FROM pc_ent_cmd d
                           WHERE d.no_cmd = l.no_cmd
                           AND ( ( d.libre_pc_ent_cmd_5 IS NULL AND p_chk_quai = '1') OR d.libre_pc_ent_cmd_5 IS NOT NULL)
                           AND ( (INSTR(d.cle_dpt, '-') > 0 AND p_chk_tou = '1') OR INSTR(d.cle_dpt, '-') = 0)
                         ); 
    END IF;


    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
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


