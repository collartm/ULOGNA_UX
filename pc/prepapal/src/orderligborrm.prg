/* $Id$
****************************************************************************
* pc_bas_order_lig_bor_rm - 
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet d'ordonner le resultat du curseur du terminal radio
-- process ramasse, comme on le souhaite.
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
-- 01a,25.03.10,rleb    Création
-- 00a,25.03.10,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE
FUNCTION pc_bas_order_lig_bor_rm (
    p_no_bor_pic              pc_pic.no_bor_pic%TYPE DEFAULT NULL,
    p_cod_emp                 se_emp.cod_emp%TYPE DEFAULT NULL,
    p_cod_pro                 su_pro.cod_pro%TYPE DEFAULT NULL,
    p_nb_col_theo             NUMBER DEFAULT NULL,
    p_nb_col_val              NUMBER DEFAULT NULL,
    p_pds_tot                 NUMBER DEFAULT NULL,
    p_vol_tot                 NUMBER DEFAULT NULL,
    p_etat                    VARCHAR2 DEFAULT NULL,
    p_etat_couche_complete    NUMBER DEFAULT NULL
    )  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_order_lig_bor_rm';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    CURSOR c_no_ord_emp IS
    SELECT no_ord_emp
    FROM  se_emp p, se_ent_zone z, se_lig_zone l
    WHERE p.cod_emp = p_cod_emp
    AND   z.typ_zone = 'S'
    AND   l.cod_zone = z.cod_zone
    AND   l.cod_emp  = p.cod_emp;
    
    r_no_ord_emp c_no_ord_emp%ROWTYPE; 

BEGIN

    --SAVEPOINT my_pc_bas_order_lig_bor_rm; <OU NON> -- Pour la gestion de l'exception on fixe un point de rollback.

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_no_bor_pic = ' || p_no_bor_pic);
    END IF;

   --order priorité 1 sur l'état
    IF p_etat='T' THEN
        v_ret:='1';
    ELSE
        v_ret:='0';
    END IF;

    OPEN c_no_ord_emp;
    FETCH c_no_ord_emp INTO r_no_ord_emp;
    CLOSE c_no_ord_emp;

    v_ret := v_ret||LPAD(NVL(r_no_ord_emp.no_ord_emp, '9999'), 4, '0');

    /*
    --order priorité 2 sur l'état_couche complete
    IF p_etat_couche_complete=0 THEN
        v_ret:=v_ret||'0';
    ELSE
        v_ret:=v_ret||'1';
    END IF;
    
   --order priorité 3 sur le poids décroissant
   v_ret:=v_ret|| to_char(round(1/p_pds_tot,2));
   v_ret:=replace(v_ret,'.','0'); --si la division est négative on remplace le . de la décimal par un 0
   */

   -- =>le tout correspond a un order by etat asc,etat_couche_complete asc, pds_tot desc
    
    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
       -- ROLLBACK TO my_pc_bas_order_lig_bor_rm;<ou non>
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_no_bor_pic',
                        p_par_ano_1       => p_no_bor_pic,
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

