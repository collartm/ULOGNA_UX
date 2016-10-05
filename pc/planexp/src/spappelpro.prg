/* $Id$
****************************************************************************
* sp_bas_appel_pro_remplacement - Appel d'un produit de remplacement
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
-- 01c,18.05.15,tjaf    Suppression des car_stk car trop restrictif
-- 01b,20.04.15,mnev    MAJ Urgence + Operateur de la demande
-- 01a,20.04.15,mnev    Creation
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
-- OK ou ERROR
--
-- COMMIT :
-- --------
-- OUI

CREATE OR REPLACE FUNCTION sp_bas_appel_pro_remplacement
    (
    p_no_uee     pc_uee.no_uee%TYPE, 
    p_cod_pro    su_pro.cod_pro%TYPE 
    )
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_appel_pro_remplacement';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := 'OK';

    v_cod_ut            se_stk.cod_ut%TYPE;
    v_typ_ut            se_stk.typ_ut%TYPE;
    v_mag_dest          se_stk.cod_mag%TYPE;
    v_emp_dest          se_stk.cod_emp%TYPE;

    CURSOR c_stk IS 
        SELECT * 
          FROM se_stk 
         WHERE cod_ut = v_cod_ut AND typ_ut = v_typ_ut;

    r_stk c_stk%ROWTYPE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_no_uee = ' || p_no_uee);
        su_bas_put_debug(v_nom_obj||' : p_cod_pro = ' || p_cod_pro);
    END IF;

    -- 
    -- il faut rechercher les caractéristiques de stock du plateau 
    -- reservé à l'origine
    -- 
    v_cod_ut := su_bas_gcl_pc_uee (p_no_uee => p_no_uee,
                                   p_colonne=> 'COD_UT');

    v_typ_ut := su_bas_gcl_pc_uee (p_no_uee => p_no_uee,
                                   p_colonne=> 'TYP_UT');

    CASE su_global_pkv.v_no_pos

        WHEN '' THEN
            v_mag_dest := 'SZC';
            v_emp_dest := 'SZC';

        WHEN '' THEN
            v_mag_dest := 'SZC';
            v_emp_dest := 'SZC';

        ELSE
            v_mag_dest := 'SZC';
            v_emp_dest := 'SZC';

    END CASE;

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : v_cod_ut = ' || v_cod_ut);
        su_bas_put_debug(v_nom_obj||' : v_typ_ut = ' || v_typ_ut);
        su_bas_put_debug(v_nom_obj||' : v_mag_dest = ' || v_mag_dest);
        su_bas_put_debug(v_nom_obj||' : v_emp_dest = ' || v_emp_dest);
    END IF;

    OPEN c_stk;
    FETCH c_stk INTO r_stk;
    IF c_stk%FOUND THEN


        IF su_global_pkv.v_niv_dbg >= 3 THEN
            su_bas_put_debug(v_nom_obj||' : Dem Trf article : ' || r_stk.cod_pro || '-' || r_stk.cod_va || '-' || r_stk.cod_vl);
            su_bas_put_debug(v_nom_obj||' : DLC : ' || TO_CHAR(r_stk.dat_dlc,'DD/MM/YYYY'));
        END IF;

        v_etape := ' demande de transfert';
        v_ret := se_bas_trf_stk (p_typ_trf                     => 'TRF',
                                 p_mode_trf                    => 'DEM',
                                 p_unit_exec_trf               => 'STK',
                                 p_dat_exec                    => SYSDATE, 
                                 p_typ_ref_trf                 => NULL,
                                 p_ref_trf_1                   => NULL,
                                 p_ref_trf_2                   => NULL,
                                 p_ref_trf_3                   => NULL,
                                 p_ref_trf_4                   => NULL,
                                 p_ref_trf_5                   => NULL,   
                                 p_cod_ope_mvt                 => 'Pool Robot ' || su_bas_gcl_pc_uee (p_no_uee, 'NO_RMP'),
                                 p_urg_trf                     => '1',
                                 p_cod_pro                     => r_stk.cod_pro,
                                 p_cod_va                      => r_stk.cod_va,
                                 p_cod_vl                      => r_stk.cod_vl,
                                 p_cod_prk                     => r_stk.cod_prk,
                                 p_cod_mag                     => 'SKC',
                                 p_cod_usn                     => 'S',
                                 p_qte_trf                     => 1,
                                 p_unit_trf                    => 'C',
                                 p_cod_soc_proprio             => r_stk.cod_soc_proprio,
                               /*p_dat_dlc                     => r_stk.dat_dlc,
                                 p_car_stk_1                   => r_stk.car_stk_1,
                                 p_car_stk_2                   => r_stk.car_stk_2,
                                 p_car_stk_3                   => r_stk.car_stk_3,
                                 p_car_stk_4                   => r_stk.car_stk_4,
                                 p_car_stk_5                   => r_stk.car_stk_5,
                                 p_car_stk_6                   => r_stk.car_stk_6,
                                 p_car_stk_7                   => r_stk.car_stk_7,
                                 p_car_stk_8                   => r_stk.car_stk_8,
                                 p_car_stk_9                   => r_stk.car_stk_9,
                                 p_car_stk_10                  => r_stk.car_stk_10,
                                 p_car_stk_11                  => r_stk.car_stk_11,
                                 p_car_stk_12                  => r_stk.car_stk_12,
                                 p_car_stk_13                  => r_stk.car_stk_13,
                                 p_car_stk_14                  => r_stk.car_stk_14,
                                 p_car_stk_15                  => r_stk.car_stk_15,
                                 p_car_stk_16                  => r_stk.car_stk_16,
                                 p_car_stk_17                  => r_stk.car_stk_17,
                                 p_car_stk_18                  => r_stk.car_stk_18,
                                 p_car_stk_19                  => r_stk.car_stk_19,
                                 p_car_stk_20                  => r_stk.car_stk_20,     */
                                 p_cod_emp_dest                => v_emp_dest,
                                 p_cod_mag_dest                => v_mag_dest); 

        IF v_ret != 'OK' THEN
            v_etape := 'erreur creation dem trf';
            v_cod_err_su_ano := 'SE_TRF-010';
            RAISE err_except;
        END IF;

        COMMIT;

    END IF;
    CLOSE c_stk;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_no_uee',
                        p_par_ano_1       => p_no_uee,
                        p_lib_ano_2       => 'p_cod_pro',
                        p_par_ano_2       => p_cod_pro,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;
/
show errors;


