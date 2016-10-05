/* $Id$
****************************************************************************
* sp_bas_val_prep_pic_ord_trf - 
*/
-- DESCRIPTION :
-- -------------
--
--
-- PARAMETRES :
-- ------------
--  p_cod_ord_trf : ordre de transfert
--
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 02a,07.03.16,pluc    Mise à jour emplacement du plateau avant retour de poids.
--                      Permet de décrémenter le stock au bon endroit.
-- 01a,23.10.15 pluc    Creation
-- -------------------------------------------------------------------------
--
-- COMMIT :
-- --------
-- NON 

CREATE OR REPLACE PROCEDURE sp_bas_val_prep_pic_ord_trf 
    (p_cod_ord_trf       IN VARCHAR2)
IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 04e $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'sp_bas_val_prep_pic_ord_trf';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
    v_ret_evt           VARCHAR2(20)  := NULL;
    v_lib_err           VARCHAR2(200);

    --
    -- Rch de l'UT réellement sortie par le TK 
    --
    CURSOR c_trf IS
        SELECT a.cod_ut_orig, a.typ_ut_orig, -- UT sortie par le TK
               a.cod_emp_dest,  a.position_dest,
               a.typ_ref_trf, a.ref_trf_5 cod_ops,
               NVL(b.unit_trf, a.unit_trf) unit_pic,
               a.cod_mag_dest
        FROM  se_ord_trf a, se_dem_trf b
        WHERE a.cod_ord_trf = p_cod_ord_trf AND a.cod_dem_trf = b.cod_dem_trf(+);
    
    r_trf       c_trf%ROWTYPE;
    v_found_trf BOOLEAN;

    CURSOR c_uee (x_cod_ut  pc_pic.cod_ut_stk%TYPE,
                    x_typ_ut  pc_pic.typ_ut_stk%TYPE,
                    x_cod_ops pc_pic.cod_ops%TYPE) IS
    SELECT a.no_uee, b.no_pos_prp, b.cod_pic
        FROM pc_pic_uee a, pc_pic b
        WHERE a.cod_pic = b.cod_pic AND b.cod_ut_stk = x_cod_ut AND b.typ_ut_stk = x_typ_ut AND
              b.cod_ops = x_cod_ops
        ORDER BY b.dat_crea DESC;

    r_uee        c_uee%ROWTYPE;

    v_niv_ano     su_ano_his.niv_ano%TYPE := 1;  -- Exception

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : Ordre trf:' || p_cod_ord_trf );
    END IF;
    --  
    -- recherche de l'UT réellement sortie par le TK
    --
    v_etape:='identification UT';    
    OPEN c_trf;
    FETCH c_trf INTO r_trf;
    v_found_trf := c_trf%FOUND;
    CLOSE c_trf;
    
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : UT:' || r_trf.cod_ut_orig || '-' || r_trf.typ_ut_orig);
        su_bas_put_debug(v_nom_obj||' : OPS:' || r_trf.cod_ops|| ' TypRefTrf:' || r_trf.typ_ref_trf);
        su_bas_put_debug(v_nom_obj||' : unit_pic:' || r_trf.unit_pic);
    END IF;

    IF v_found_trf THEN

        OPEN c_uee (r_trf.cod_ut_orig, r_trf.typ_ut_orig, r_trf.cod_ops);
        FETCH c_uee INTO r_uee;
        IF c_uee%FOUND THEN

            -- $MOD,02a
            UPDATE pc_pic
                SET cod_mag = r_trf.cod_mag_dest,
                    cod_emp = r_trf.cod_emp_dest
            WHERE cod_pic = r_uee.cod_pic;

            v_ret := pc_bas_val_prepa_uee_from_pic (p_no_uee  => r_uee.no_uee,
                                                    p_no_pos  => r_uee.no_pos_prp
                                                    );
            IF v_ret = 'ERROR' THEN
                v_etape := v_etape || ' v_ret:' || v_ret;
                RAISE err_except;
            END IF;
        END IF;
    ELSE
        -- 
        -- tracer le PB
        --
        v_etape:='impossible de déterminer l''UT';
        v_niv_ano := 2;
        RAISE err_except;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'codOrdTrf',
                        p_par_ano_1       => p_cod_ord_trf,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_niv_ano         => v_niv_ano,
                        p_version         => v_version);

        -- la procedure doit faire un raise pour que l'action SU passe aussi en erreur ...
        RAISE;
END;   
/
show errors;
